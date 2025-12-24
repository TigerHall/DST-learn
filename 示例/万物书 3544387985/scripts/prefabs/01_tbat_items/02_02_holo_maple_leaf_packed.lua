--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_item_holo_maple_leaf_packed"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_holo_maple_leaf.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 落水
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:PlayAnimation("water")
        else
            inst.AnimState:Show("SHADOW")
            inst.AnimState:PlayAnimation("idle")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 留影模块
    local function SetClientData(inst,data)
        data = data or {}
        local str = json.encode(data)
        inst.__net_data_json:set(str)
    end
    local function GetClientData(inst)
        local str = inst.__net_data_json:value()
        local flag,data = pcall(json.decode,str)
        if flag and type(data) == "table" then
            return data
        end
        return nil
    end
    local function remember_fn(inst,target)
        if not target and target.prefab then
            return
        end
        local face = target.Transform:TBAT_GetFace()
        local bank,build,anim = TBAT.FNS:GetBankBuildAnim(target)
        -- print("+++++++++",bank,build,anim,face)
        local name = STRINGS.NAMES[string.upper(target.prefab)]
        local data = {
            name = name,
            bank = bank,
            build = build,
            anim = anim,
            face = face,
        }
        inst.components.tbat_data:Set("data",data)
    end
    local function init(inst)
        local data = inst.components.tbat_data:Get("data")
        if data == nil then
            return
        end
        if data.name then
            inst.components.named:SetName(STRINGS.NAMES[string.upper(this_prefab)]..data.name)
        end
        inst:SetClientData(data)
    end
    local function holo_module_install(inst)
        inst.__net_data_json = net_string(inst.GUID,"__net_data_json")
        inst.SetClientData = SetClientData
        inst.GetClientData = GetClientData
        if not TheWorld.ismastersim then
            return
        end
        inst:ListenForEvent("Remember",remember_fn)
        inst:DoTaskInTime(0,init)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- deploy
    local function ondeploy(inst, pt, deployer)
        local data = inst.components.tbat_data:Get("data")
        local new = SpawnPrefab(this_prefab.."_building")
        -- data.name = inst:GetDisplayName()
        new.components.tbat_data:Set("data",data)
        new.Transform:SetPosition(pt.x,0,pt.z)
        inst:Remove()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_item_holo_maple_leaf")
        inst.AnimState:SetBuild("tbat_item_holo_maple_leaf")
        inst.AnimState:PlayAnimation("idle")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst:AddTag("usedeploystring")
        inst.entity:SetPristine()
        if TheWorld.ismastersim then
            inst:AddComponent("tbat_data")
        end
        holo_module_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:AddComponent("named")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_item_holo_maple_leaf","images/inventoryimages/tbat_item_holo_maple_leaf.xml")
        inst:ListenForEvent("on_landed",item_onland_event)
        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)
        inst:AddComponent("deployable")                
        inst.components.deployable.ondeploy = ondeploy
        -- inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
        inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- building
    local function hide_snow(inst)
        inst.AnimState:Hide("snow")
        inst.AnimState:Hide("SNOW")
        inst.AnimState:HideSymbol("snow")
        inst.AnimState:HideSymbol("SNOW")
    end
    local function building_init(inst)
        local data = inst.components.tbat_data:Get("data")
        hide_snow(inst)
        if type(data) ~= "table" then
            return
        end
        local bank,build,anim = data.bank,data.build,data.anim

        -- local name = TBAT:GetString2(inst.prefab,"name") .. tostring(data.name)
        -- inst.components.named:SetName(name)

        local face = data.face or 0
        if bank and build and anim then
            inst.AnimState:SetBank(bank)
            inst.AnimState:SetBuild(build)
            inst.AnimState:PlayAnimation(anim,true)
        end
        if face == 0 then
            inst.Transform:SetNoFaced()
        elseif face == 2 then
            inst.Transform:SetTwoFaced()
        elseif face == 4 then
            inst.Transform:SetFourFaced()
        elseif face == 6 then
            inst.Transform:SetSixFaced()
        elseif face == 8 then
            inst.Transform:SetEightFaced()
        end
    end

    local function building_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("tbat_item_holo_maple_leaf")
        inst.AnimState:SetBuild("tbat_item_holo_maple_leaf")
        inst.AnimState:PlayAnimation("idle")
        inst.entity:SetPristine()
        if TheWorld.ismastersim then
            inst:AddComponent("tbat_data")
        end
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("inspectable")
        inst:AddComponent("named")
        inst:DoTaskInTime(0,building_init)
        hide_snow(inst)
        TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,1)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- placer 相关的 hook    
    local function placer_postinit_fn(inst)
            local old_SetBuilder_fn = inst.components.placer.SetBuilder
            inst.components.placer.SetBuilder = function(self,builder, recipe, invobject) --- 玩家准备放置预览的时候，会执行这个
                if invobject and invobject.GetClientData then
                    local data = invobject:GetClientData() or {}
                    local bank,build,anim = data.bank,data.build,data.anim
                    if bank and build and anim then
                        inst.AnimState:SetBank(bank)
                        inst.AnimState:SetBuild(build)
                        inst.AnimState:PlayAnimation(anim,true)
                    end
                end
                return old_SetBuilder_fn(self,builder, recipe, invobject)
            end
            inst:DoTaskInTime(0,hide_snow)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, item_fn, assets),
        MakePlacer(this_prefab.."_placer", "tbat_item_holo_maple_leaf", "tbat_item_holo_maple_leaf", "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil),
        Prefab(this_prefab.."_building", building_fn, assets)

