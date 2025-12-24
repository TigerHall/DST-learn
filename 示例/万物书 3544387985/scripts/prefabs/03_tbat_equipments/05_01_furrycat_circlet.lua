--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_furrycat_circlet"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_eq_furrycat_circlet.zip"),
        Asset("ANIM", "anim/tbat_eq_furrycat_circlet_strawberry_bunny.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_wreath_strawberry_bunny"] = {                    --- 
            bank = "tbat_eq_furrycat_circlet_strawberry_bunny",
            build = "tbat_eq_furrycat_circlet_strawberry_bunny",
            atlas = "images/inventoryimages/tbat_eq_furrycat_circlet_strawberry_bunny.xml",
            image = "tbat_eq_furrycat_circlet_strawberry_bunny",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.strawberry_bunny"),        --- 切名字用的
            name_color = "pink",
            hat_fx = "tbat_eq_furrycat_circlet_strawberry_bunny_hat_fx",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_furrycat_circlet_strawberry_bunny",
                build = "tbat_eq_furrycat_circlet_strawberry_bunny",
                anim = "item",
                scale = 0.8,
                offset = Vector3(0, 30, 0)
            }
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_wreath_strawberry_bunny")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 灯光控制
    local function remove_light(inst)
        if inst.light_fx then
            inst.light_fx:Remove()
        end
        inst.light_fx = nil
    end
    local function create_light(inst,owner)
        remove_light(inst)
        local fx = owner:SpawnChild("minerhatlight")
        inst.light_fx = fx
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onequip / onunequip
    local function onequip(inst, owner)
        owner.AnimState:Show("HAT")
        owner.AnimState:Show("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
			owner.AnimState:Show("HEAD_HAT_NOHELM")
			owner.AnimState:Hide("HEAD_HAT_HELM")
        end


        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
		owner.AnimState:Hide("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")

        -- owner.AnimState:OverrideSymbol("swap_hat", "tbat_eq_furrycat_circlet", "swap_hat")
        owner.AnimState:ClearOverrideSymbol("swap_hat")
        -------------------------------------------------------------------------
        --- 特效件
            if inst._hat_fx and inst._hat_fx:IsValid() then
                inst._hat_fx:Remove()
            end
            local hat_fx_prefab = this_prefab.."_hat_fx"
            local current_skin_data = inst.components.tbat_com_skin_data:GetCurrentData()
            if current_skin_data and current_skin_data.hat_fx then
                hat_fx_prefab = current_skin_data.hat_fx
            end
            inst._hat_fx = SpawnPrefab(hat_fx_prefab)
            inst._hat_fx:AttachToOwner(owner)
        -------------------------------------------------------------------------

        create_light(inst,owner)
    end

    local function onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_hat")
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")
        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
			owner.AnimState:Hide("HEAD_HAT_NOHELM")
			owner.AnimState:Hide("HEAD_HAT_HELM")
        end
        remove_light(inst)
        -------------------------------------------------------------------------
        --- 特效件
            if inst._hat_fx and inst._hat_fx:IsValid() then
                inst._hat_fx:Remove()
                inst._hat_fx = nil
            end
        -------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 影子+落水
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:PlayAnimation("item_water")
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:Hide("shadow")
            inst.AnimState:HideSymbol("shadow")
        else                                
            inst.AnimState:PlayAnimation("item")
            inst.AnimState:Show("SHADOW")
            inst.AnimState:Show("shadow")
            inst.AnimState:ShowSymbol("shadow")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onremove
    local function on_remove(inst)
        remove_light(inst)
        inst:Remove()
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
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_eq_furrycat_circlet","tbat_eq_furrycat_circlet")
        -- inst.AnimState:SetBank("tbat_eq_furrycat_circlet")
        -- inst.AnimState:SetBuild("tbat_eq_furrycat_circlet")
        inst.AnimState:PlayAnimation("item")

        inst:AddTag("hat")
        inst:AddTag("open_top_hat")
        inst:AddTag("show_spoilage")

        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.components.floater:SetSize("med")
        inst.components.floater:SetScale(0.68)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------------
        ---
            inst:AddComponent("tbat_com_skin_data")
        -----------------------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_eq_furrycat_circlet","images/inventoryimages/tbat_eq_furrycat_circlet.xml")
        -----------------------------------------------------
        ---
            inst:AddComponent("equippable")
            inst.components.equippable:SetOnEquip(onequip)
            inst.components.equippable:SetOnUnequip(onunequip)
            inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
            inst.components.equippable.dapperness = TBAT.PARAM.ONE_SANITY_UP_PER_MIN*5 -- 光环
            inst.components.equippable.flipdapperonmerms = true
        -----------------------------------------------------
        ---
            MakeHauntableLaunch(inst)
            MakeHauntableLaunchAndPerish(inst)
            inst:ListenForEvent("on_landed",shadow_init)
        -----------------------------------------------------
        --- 腐烂
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(TBAT.PARAM.ONE_DAY*6)
            inst.components.perishable:StartPerishing()
            inst.components.perishable:SetOnPerishFn(on_remove)
        -----------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 特效件
    local hat_fx_pack = {}
    local child_hide_test_fn = function(inst,parent)
        inst.AnimState:HideSymbol("test")        
    end
    table.insert(hat_fx_pack,TBAT.MODULES:CreateAnimHat(this_prefab.."_hat_fx",{
        bank = "tbat_eq_furrycat_circlet",
        build = "tbat_eq_furrycat_circlet",
        anim_down = "down_eq",
        anim_side = "side_eq",
        anim_up = "up_eq",
        loop = true,
        child_fn = child_hide_test_fn
    },assets))
    table.insert(hat_fx_pack,TBAT.MODULES:CreateAnimHat("tbat_eq_furrycat_circlet_strawberry_bunny_hat_fx",{
        bank = "tbat_eq_furrycat_circlet_strawberry_bunny",
        build = "tbat_eq_furrycat_circlet_strawberry_bunny",
        anim_down = "down_eq",
        anim_side = "side_eq",
        anim_up = "up_eq",
        loop = true,
        child_fn = child_hide_test_fn
    },assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 打包本体
    table.insert(hat_fx_pack,Prefab(this_prefab, fn, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(hat_fx_pack)
    
