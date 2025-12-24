--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_chesspiece_display_stand"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_chesspiece_display_stand.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- fx
    local function fx_create(inst)
        if inst.fx and inst.fx:IsValid() then
            inst.fx:Remove()
        end
        local fx = SpawnPrefab(this_prefab.."_fx")
        fx.entity:SetParent(inst.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(inst.GUID, "swap_body",0,-22,0,true)
        inst.fx = fx
        local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if item then
            local bank,build,anim = TBAT.FNS:GetBankBuildAnim(item)
            if bank and build and anim then
                inst.fx:Show()
                inst.fx.AnimState:SetBank(bank)
                inst.fx.AnimState:SetBuild(build)
                inst.fx.AnimState:PlayAnimation(anim,true)
                inst.__net_name:set(item:GetDisplayName())
                inst.__net_hight_light_child:set(fx)
                return
            end
        end
        inst.__net_name:set("nil")
        inst.__net_hight_light_child:set(nil)
    end
    local function net_hight_light_child_fn(inst)
        local fx = inst.__net_hight_light_child:value()
        local display_name = nil
        if fx then
            inst.highlightchildren = { fx }
            local net_name = inst.__net_name:value()
            if net_name ~= "nil" then
                display_name = TBAT:GetString2(this_prefab,"display")..net_name            
            end
        else
            inst.highlightchildren = nil
        end
        inst.name = display_name
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnUseHeavy(inst, doer, heavy_item)
        if heavy_item == nil then
            return
        end
        local old_item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if old_item then
            doer.components.inventory:Equip(old_item)
        else
            doer.components.inventory:Unequip(EQUIPSLOTS.BODY)
        end        
        inst.components.inventory:Equip(heavy_item)
        fx_create(inst)
        return true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
    local workable_cm = {
        onfinished = function(inst)
            inst.components.inventory:DropEquipped(EQUIPSLOTS.BODY)
        end
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_building_chesspiece_display_stand")
        inst.AnimState:SetBuild("tbat_building_chesspiece_display_stand")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:OverrideSymbol("swap_body","tbat_building_chesspiece_display_stand","empty")
        inst:AddTag("structure")
        inst:AddTag(this_prefab)

        inst.__net_hight_light_child = net_entity(inst.GUID,"net_hight_light_child","net_hight_light_child")
        inst.__net_name = net_string(inst.GUID,"net_name","net_name")

        inst.entity:SetPristine()
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("net_hight_light_child",net_hight_light_child_fn)
        end
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------------------------------
        ---
            inst:AddComponent("inspectable")
        ------------------------------------------------------------------------
        ---
            inst:AddComponent("inventory")
            inst.components.inventory.ignorescangoincontainer = true
	        inst.components.inventory.maxslots = 1
        ------------------------------------------------------------------------
        ---
            inst:AddComponent("heavyobstacleusetarget")
	        inst.components.heavyobstacleusetarget.on_use_fn = OnUseHeavy
        ------------------------------------------------------------------------
        ---
            inst:DoTaskInTime(0,fx_create)
        ------------------------------------------------------------------------
        --- 拆除模块
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5,workable_cm)
        ------------------------------------------------------------------------
        ---
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("FX")
        inst:AddTag("fx")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:OverrideSymbol("swap_body","tbat_building_chesspiece_display_stand","empty")        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),Prefab(this_prefab.."_fx", fx),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

