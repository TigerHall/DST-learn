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
--- 前置准备
    local this_prefab = "tbat_item_butterfly_wrapping_paper"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_butterfly_wrapping_paper.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 目标检查
    local check_list_data = require("prefabs/01_tbat_items/01_02_special_packer_list") or {}
    local function target_test_fn(target)
        if not SAFE_MODE then
            return true
        end
        if check_list_data.prefab_whitelist[target.prefab] then
            return true
        end
        if check_list_data.prefab_blacklist[target.prefab] then
            return false
        end
        if target:HasOneOfTags(check_list_data.tags_blacklist or {}) then
            return false
        end
        for com_name, v in pairs(target.components) do
            if check_list_data.components_blacklist[com_name] then
                return false
            end
        end
        for com_name, v in pairs(target.replica._) do
            if check_list_data.components_blacklist[com_name] then
                return false
            end
        end
        if target.brainfn then
            return false
        end
        return true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function item_use_to_test_fn(inst,target,doer,right_click)
        if not right_click then
            return false
        end
        return target_test_fn(target)
    end
    local function item_use_to_active_fn(inst,target,doer)
        local debugstring = target.entity:GetDebugString()
        -----------------------------------------------------------------------------------------------------
        --- 这段逻辑大部分来自【小穹MOD】，自己修改了一部分
            local bank,build,anim = nil,nil,nil
            if target.AnimState then

                bank, build, anim = debugstring:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")
                if (not bank) or (bank:find("FROMNUM")) and target.AnimState.GetBank then
                    -- bank = target.prefab -- 抢救一下吧
                    bank = target.AnimState:GetBank()
                end
                if (not build) or (build:find("FROMNUM")) then
                    -- build = target.prefab -- 抢救一下吧
                    build = target.AnimState:GetBuild()
                end

                if target.skinname and not Prefabs[target.prefab .. "_placer"] then
                    local temp_inst = SpawnPrefab(target.prefab)
                    debugstring = temp_inst.entity:GetDebugString()
                    bank, build, anim = debugstring:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")
                    temp_inst:Remove()
                end
            end
        -----------------------------------------------------------------------------------------------------
            if target and target.components.container and target.components.container:IsOpen() then
                target.components.container:Close()
                for k, tag in pairs(check_list_data.tags_blacklist or {}) do
                    target.components.container:DropEverythingWithTag(tag)                    
                end
            end
        -----------------------------------------------------------------------------------------------------
            -- print(bank,build,anim)
            local x,y,z = target.Transform:GetWorldPosition()
            local save_record = target:GetSaveRecord()
            local name = target:GetDisplayName()
            local box = SpawnPrefab("tbat_item_butterfly_wrapped_pack")
            box:PushEvent("Set",{
                save_record = save_record,
                bank = bank,
                build = build,
                anim = anim,
                name = name,
                safe_mode = SAFE_MODE,
            })
            box.Transform:SetPosition(x, y, z)
            doer.components.inventory:GiveItem(box)
            target:Remove()
            -- inst:Remove()
            inst.components.stackable:Get():Remove()
        -----------------------------------------------------------------------------------------------------
        return true
    end
    local function item_use_to_com_replica_init(inst,replica_com)
        replica_com:SetTestFn(item_use_to_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.WRAPBUNDLE)
        replica_com:SetDistance(30)
    end
    local function item_use_to_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_item_use_to",item_use_to_com_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_item_use_to")
        inst.components.tbat_com_item_use_to:SetActiveFn(item_use_to_active_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_item_butterfly_wrapping_paper")
        inst.AnimState:SetBuild("tbat_item_butterfly_wrapping_paper")
        inst.AnimState:PlayAnimation("paper")

        MakeInventoryFloatable(inst)

        inst.entity:SetPristine()
        -----------------------------------------------
        ---
            item_use_to_com_install(inst)
        -----------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end

        -----------------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_butterfly_wrapping_paper","images/inventoryimages/tbat_item_butterfly_wrapping_paper.xml")
        -----------------------------------------------
        ---
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
            MakeHauntableLaunch(inst)
        -----------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
