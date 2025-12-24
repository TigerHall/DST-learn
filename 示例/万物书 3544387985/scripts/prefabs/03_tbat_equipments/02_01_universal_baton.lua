--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    万物指挥棒

]] --
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_universal_baton"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_eq_universal_baton.zip"),
        Asset("ANIM", "anim/tbat_eq_universal_baton_2.zip"),
        Asset("ANIM", "anim/tbat_eq_universal_baton_3.zip"),
        Asset("ANIM", "anim/tbat_eq_universal_baton_snow_cap_rabbit_ice_cream.zip"),
        Asset("ANIM", "anim/tbat_eq_universal_baton_bunny_scepter.zip"),
        Asset("ANIM", "anim/tbat_eq_universal_baton_jade_sword_immortal.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        -- ["tbat_eq_universal_baton_2"] = {     ---
        --     bank = "tbat_eq_universal_baton_2",
        --     build = "tbat_eq_universal_baton_2",
        --     atlas = "images/inventoryimages/tbat_eq_universal_baton_2.xml",
        --     image = "tbat_eq_universal_baton_2",     -- 不需要 .tex
        --     name = "经典",                         --- 切名字用的
        --     fx = "tbat_sfx_effect_cherry_blossom_petals",
        --     name_color = { 255 / 255, 255 / 255, 255 / 255, 1 },
        -- },
        ["tbat_eq_universal_baton_3"] = {     ---
            bank = "tbat_eq_universal_baton_3",
            build = "tbat_eq_universal_baton_3",
            atlas = "images/inventoryimages/tbat_eq_universal_baton_3.xml",
            image = "tbat_eq_universal_baton_3",     -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"tbat_eq_universal_baton_3"),                         --- 切名字用的
            fx = "tbat_sfx_effect_cherry_blossom",
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_universal_baton_3",
                build = "tbat_eq_universal_baton_3",
                anim = "in_hand",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            }
        },
        ["tbat_eq_universal_baton_2"] = {     ---
            bank = "tbat_eq_universal_baton",
            build = "tbat_eq_universal_baton",
            atlas = "images/inventoryimages/tbat_eq_universal_baton.xml",
            image = "tbat_eq_universal_baton",     -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"tbat_eq_universal_baton_2"),                         --- 切名字用的
            fx = "tbat_lizifx_sakura",
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_universal_baton_2",
                build = "tbat_eq_universal_baton_2",
                anim = "in_hand",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            }
        },
        ["tbat_baton_rabbit_ice_cream"] = {     ---
            bank = "tbat_eq_universal_baton_snow_cap_rabbit_ice_cream",
            build = "tbat_eq_universal_baton_snow_cap_rabbit_ice_cream",
            atlas = "images/inventoryimages/tbat_eq_universal_baton_snow_cap_rabbit_ice_cream.xml",
            image = "tbat_eq_universal_baton_snow_cap_rabbit_ice_cream",     -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.snow_cap_rabbit_ice_cream"),                         --- 切名字用的
            fx = "tbat_lizifx_chocolate",
            fx_offset = Vector3(100, -300, 0),
            name_color = "pink",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_universal_baton_snow_cap_rabbit_ice_cream",
                build = "tbat_eq_universal_baton_snow_cap_rabbit_ice_cream",
                anim = "in_hand",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            }
        },
        ["tbat_baton_bunny_scepter"] = {     ---
            bank = "tbat_eq_universal_baton_bunny_scepter",
            build = "tbat_eq_universal_baton_bunny_scepter",
            atlas = "images/inventoryimages/tbat_eq_universal_baton_bunny_scepter.xml",
            image = "tbat_eq_universal_baton_bunny_scepter",     -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.bunny_scepter"),                         --- 切名字用的
            fx = "tbat_lizifx_rabbit",
            fx_offset = Vector3(0, -250, 0),
            name_color = "blue",
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_universal_baton_bunny_scepter",
                build = "tbat_eq_universal_baton_bunny_scepter",
                anim = "in_hand",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            }
        },
        ["tbat_baton_jade_sword_immortal"] = {     ---
            bank = "tbat_eq_universal_baton_jade_sword_immortal",
            build = "tbat_eq_universal_baton_jade_sword_immortal",
            atlas = "images/inventoryimages/tbat_eq_universal_baton_jade_sword_immortal.xml",
            image = "tbat_eq_universal_baton_jade_sword_immortal",     -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.jade_sword_immortal"),                         --- 切名字用的
            name_color = "red",
            fx = "cane_victorian_fx",
            fx_offset = Vector3(30, -300, 0),
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_universal_baton_jade_sword_immortal",
                build = "tbat_eq_universal_baton_jade_sword_immortal",
                anim = "in_hand",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            }
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data, this_prefab)
    -- TBAT.SKIN:AddForDefaultUnlock("tbat_eq_universal_baton_2")
    -- TBAT.SKIN:AddForDefaultUnlock("tbat_eq_universal_baton_3")
    -- TBAT.SKIN:AddForDefaultUnlock("tbat_baton_rabbit_ice_cream")
    -- TBAT.SKIN:AddForDefaultUnlock("tbat_baton_bunny_scepter")
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_eq_universal_baton_2")
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_eq_universal_baton_3")
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_baton_rabbit_ice_cream")
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_baton_bunny_scepter")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 环绕特效创建
    -- 用于计算目标周围随机位置
    local function TbatGetCalculatedPos(x, y, z, radius, theta)
        local rad = radius or math.random() * 3
        local the = theta or math.random() * 2 * PI
        return x + rad * math.cos(the), y, z - rad * math.sin(the)
    end
    local function AddFx(inst, owner)
        local x, y, z = owner.Transform:GetWorldPosition()
        local x2, y2, z2 = TbatGetCalculatedPos(x, y, z, 1 + math.random() * 2, nil)
        local fx = SpawnPrefab("tbat_sfx_butterflies_explode")
        if fx then
            fx.Transform:SetPosition(x2, y2, z2)
        end
    end
    local function TbatMakeFlyingCharacterPhysics(inst, mass, rad)
        local phys = inst.Physics or inst.entity:AddPhysics()
        phys:SetMass(mass)
        phys:SetFriction(0)
        phys:SetDamping(5)
        phys:SetCollisionGroup(COLLISION.FLYERS)
        phys:SetCollisionMask(
            COLLISION.WORLD,
            COLLISION.FLYERS
        )
        phys:SetCapsule(rad, 1)
        return phys
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onequip / unequip
    local function onequip(inst, owner)
        -- owner.AnimState:OverrideSymbol("swap_object", "swap_cane", "swap_cane")
        owner.AnimState:ClearOverrideSymbol("swap_object")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")

        local current_skindata = inst.components.tbat_com_skin_data:GetCurrentData()
        local bank_build = current_skindata and current_skindata.bank or "tbat_eq_universal_baton_2"

        local fx = SpawnPrefab("tbat_eq_universal_baton_fx")
        fx.AnimState:SetBank(bank_build)
        fx.AnimState:SetBuild(bank_build)
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, 0, 0, true)
        inst.fx = fx

        --------------------------------------------
        --- 拖尾
        local fx_trail_prefab = "tbat_sfx_effect_cherry_blossom_petals"
        if current_skindata then
            -- fx_trail_prefab = current_skindata.fx or fx_trail_prefab
            fx_trail_prefab = current_skindata.fx
        end
        if not inst._vfx_fx_inst and fx_trail_prefab then
            inst._vfx_fx_inst = SpawnPrefab(fx_trail_prefab)
            inst._vfx_fx_inst.entity:AddFollower()
            inst._vfx_fx_inst.entity:SetParent(owner.entity)
            local tail_offset = current_skindata and current_skindata.fx_offset or Vector3(0, -200, 0)
            inst._vfx_fx_inst.Follower:FollowSymbol(owner.GUID, 'swap_object', tail_offset.x, tail_offset.y, tail_offset.z) --偏移量每个装备先手动调吧，后面再优化
        end
        --------------------------------------------
        -- 物理引擎
        -- 我不懂为什么修改碰撞体积要做延迟任务，而且延迟任务为什么不判断有效性？
        -- if owner.components.playercontroller then
        --     -- if inst.ready then
        --     --     MakeFlyingCharacterPhysics(owner, 1, .5)
        --     -- else
        --         if inst.__physics_task then
        --             inst.__physics_task:Cancel()
        --         end
        --         inst.__physics_task = inst:DoTaskInTime(2,function()
        --             MakeFlyingCharacterPhysics(owner, 1, .5)
        --             inst.__physics_task = nil
        --         end)
        --     -- end
        -- end
        if owner and owner:IsValid() and owner.components.playercontroller then
            -- 碰撞体积
            TbatMakeFlyingCharacterPhysics(owner, 1, .5)
            -- 踏水
            -- if owner.components.drownable then
            --     owner.components.drownable.enabled = false
            -- end
        end
        --------------------------------------------
        --
        -- create_surround_effect(inst)
        if not current_skindata then
            AddFx(inst, owner)
            AddFx(inst, owner)
        end
        --------------------------------------------
    end

    local function onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_object")
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
        if inst.fx then
            inst.fx:Remove()
            inst.fx = nil
        end
        if inst._vfx_fx_inst then
            inst._vfx_fx_inst:Remove()
            inst._vfx_fx_inst = nil
        end
        --------------------------------------------
        --- 物理引擎
        --- 我不懂为什么修改碰撞体积要做延迟任务，而且延迟任务为什么不判断有效性？
        -- if owner.components.playercontroller then

        --     -- if inst.ready then
        --     --     MakeCharacterPhysics(owner, 75, .5)
        --     -- else
        --         if inst.__physics_task then
        --             inst.__physics_task:Cancel()
        --         end
        --         inst.__physics_task = inst:DoTaskInTime(2,function()
        --             inst.__physics_task = nil
        --             MakeCharacterPhysics(owner, 75, .5)
        --         end)
        --     -- end
        -- end
        if owner and owner:IsValid() and owner.components.playercontroller then
            -- 恢复碰撞体积
            ChangeToCharacterPhysics(owner, 75, .5)
            -- 取消踏水
            -- if owner.components.drownable then
            --     owner.components.drownable.enabled = true
            -- end
        end
        --------------------------------------------
        ---
        -- remove_surround_effect(inst)
        --------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主要逻辑
    local main_logic_fn = require("prefabs/03_tbat_equipments/02_02_baton_main_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 落水
    local function item_onland_event(inst)
        if inst:IsOnOcean(false) then     --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:PlayAnimation("water", true)
        else
            inst.AnimState:Show("SHADOW")
            inst.AnimState:PlayAnimation("idle", true)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- INIT
    local function init(inst)
        inst.ready = true
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

        TBAT.SKIN:SetDefaultBankBuild(inst, "tbat_eq_universal_baton_2", "tbat_eq_universal_baton_2")
        -- inst.AnimState:SetBank("tbat_eq_universal_baton")
        -- inst.AnimState:SetBuild("tbat_eq_universal_baton")
        inst.AnimState:PlayAnimation("idle")

        --weapon (from weapon component) added to pristine state for optimization
        inst:AddTag("weapon")

        MakeInventoryFloatable(inst, "med", 0.05, { 0.85, 0.45, 0.85 })
        inst.entity:SetPristine()
        -----------------------------------------------------
        --- 主要逻辑
        main_logic_fn(inst)
        -----------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("tbat_com_skin_data")
        inst:AddComponent("tbat_data")
        inst:AddComponent("named")

        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(0)

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_eq_universal_baton_2",
            "images/inventoryimages/tbat_eq_universal_baton_2.xml")

        inst:AddComponent("equippable")

        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)

        MakeHauntableLaunch(inst)

        inst:ListenForEvent("on_landed", item_onland_event)
        inst:DoTaskInTime(0, init)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- fx
    local function fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_eq_universal_baton")
        inst.AnimState:SetBuild("tbat_eq_universal_baton")
        inst.AnimState:PlayAnimation("in_hand", true)
        inst:AddTag("fx")
        inst:AddTag("FX")
        inst:AddTag("NOBLOCK")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
    Prefab(this_prefab .. "_fx", fx)
