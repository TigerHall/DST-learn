--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    if TBAT.CONFIG.BUTTERFLY_WARPPING_PAPAER == 0 then
        return
    end
    local SAFE_MODE = false
    if TBAT.CONFIG.BUTTERFLY_WARPPING_PAPAER == 1 then
        SAFE_MODE = true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_item_butterfly_wrapped_pack"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function box_init(inst)
        local deploy_placer_data = inst.components.tbat_data:Get("deploy_placer_data")
        if deploy_placer_data then
            inst.__net_string_json:set(json.encode(deploy_placer_data)) --- 下发placer 用的数据
        end
    end
    local function ondeploy(inst, pt, deployer)
        local save_record = inst.components.tbat_data:Get("save_record")
        local safe_mode = inst.components.tbat_data:Get("safe_mode") or false
        if not SAFE_MODE then
            print("error : TBAT butterfly_wrapped_pack deploy without safe mode")
        end
        if save_record and (safe_mode == SAFE_MODE or safe_mode == true) then
            SpawnSaveRecord(save_record).Transform:SetPosition(pt.x, pt.y, pt.z)
        else
            print("Error : TBAT 蝴蝶打包 安全模式不匹配")
            local temp_record = inst:GetSaveRecord()
            deployer.components.inventory:GiveItem(SpawnSaveRecord(temp_record))
            if deployer.components.talker then
                deployer.components.talker:Say(TBAT:GetString2(this_prefab,"safe_mod_error"))
            end
        end        
        inst:Remove()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- custom deploy fn
    local function _custom_candeploy_fn(inst, pt, mouseover, deployer, rot)
        return true
    end
    local function inventoryitem_replica_init(inst,replica_com)
        replica_com.DeploySpacingRadius = function()
            -- print("+++ DeploySpacingRadius")
            return 30
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function box_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst.entity:AddAnimState()
        inst.AnimState:SetBank("tbat_item_butterfly_wrapping_paper")
        inst.AnimState:SetBuild("tbat_item_butterfly_wrapping_paper")
        inst.AnimState:PlayAnimation("pack")

        MakeInventoryPhysics(inst)
        MakeInventoryFloatable(inst, "med", nil, 0.77)
        inst:AddTag("usedeploystring")
        inst:AddTag("usedeployspacingasoffset")
        inst:AddTag("deploykititem")
        ----------------------------------------------------------------------
            inst._custom_candeploy_fn = _custom_candeploy_fn
        ----------------------------------------------------------------------
        inst.entity:SetPristine()
        ----------------------------------------------------------------------
        --- 给放置时候用的数据调取。
            inst.__net_string_json = net_string(inst.GUID,"tbat_item_butterfly_wrapping_paper","tbat_item_butterfly_wrapping_paper")
            inst:ListenForEvent("tbat_item_butterfly_wrapping_paper",function() --- 得到下发的数据
                inst.deploy_placer_data = {}
                pcall(function()
                    local str = inst.__net_string_json:value()
                    local temp_table = json.decode(str)
                    if temp_table.bank and temp_table.build and temp_table.anim then
                        inst.deploy_placer_data = temp_table
                    end
                end)
            end)
        ----------------------------------------------------------------------
        ---
            inst:ListenForEvent("TBAT_OnEntityReplicated.inventoryitem",inventoryitem_replica_init)
        ----------------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("named")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_item_butterfly_wrapped_pack","images/inventoryimages/tbat_item_butterfly_wrapped_pack.xml")


        MakeHauntableLaunch(inst)
        ------------------------------------------------------------------------------------------
        ---- 参数设置
            inst:AddComponent("tbat_data")
            inst:ListenForEvent("Set",function(_,_table)
                -- _table = {
                --     bank = "",  --- 
                --     build = "", ---
                --     anim = "",  ---
                --     name = "",  --- 显示名字
                --     save_record = "",  --- 储存代码
                -- }
                if _table.save_record == nil then
                    inst:Remove()
                    return
                end
                ------------------------------------------------------
                    local deploy_placer_data = {
                        bank = _table.bank,
                        build = _table.build,
                        anim = _table.anim,
                    }
                    -- inst.__net_string_json:set(json.encode(deploy_placer_data)) --- 下发placer 用的数据
                    inst.components.tbat_data:Set("deploy_placer_data",deploy_placer_data)
                ------------------------------------------------------
                inst.components.tbat_data:Set("save_record",_table.save_record)
                if _table.name then
                    inst.components.named:SetName( ( TBAT:GetString2(this_prefab,"name")  or "Pack : ").._table.name)
                end

                inst.components.tbat_data:Set("safe_mode",_table.safe_mode)
            end)
        ------------------------------------------------------------------------------------------
        ---- 重载的时候下发数据
            inst:DoTaskInTime(0,box_init)
        ------------------------------------------------------------------------------------------
        --- 种植组件
            inst:AddComponent("deployable")                
            inst.components.deployable.ondeploy = ondeploy
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
            inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
        ------------------------------------------------------------------------------------------
        return inst
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- placer 相关的 hook
    local function hide_snow(inst)
        inst.AnimState:Hide("snow")
        inst.AnimState:Hide("SNOW")
        inst.AnimState:HideSymbol("snow")
        inst.AnimState:HideSymbol("SNOW")
    end
    local function placer_postinit_fn(inst)

            local old_SetBuilder_fn = inst.components.placer.SetBuilder
            inst.components.placer.SetBuilder = function(self,builder, recipe, invobject) --- 玩家准备放置预览的时候，会执行这个
                if invobject and invobject.deploy_placer_data then
                    local temp_table = invobject.deploy_placer_data
                    if temp_table.bank and temp_table.build and temp_table.anim then
                        inst.AnimState:SetBank(temp_table.bank)
                        inst.AnimState:SetBuild(temp_table.build)
                        inst.AnimState:PlayAnimation(temp_table.anim,true)
                    end
                end
                return old_SetBuilder_fn(self,builder, recipe, invobject)
            end
            inst:DoTaskInTime(0,hide_snow)
    end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return  Prefab(this_prefab, box_fn),
        MakePlacer(this_prefab.."_placer", "tbat_item_butterfly_wrapping_paper", "tbat_item_butterfly_wrapping_paper", "pack", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

