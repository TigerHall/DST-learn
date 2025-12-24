--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    鳐鱼帽子

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_ray_fish_hat"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_eq_ray_fish_hat_ui.zip"),
        Asset("ANIM", "anim/tbat_eq_ray_fish_hat.zip"),
        Asset("ANIM", "anim/tbat_eq_ray_fish_hat_sweetheart_cocoa.zip"),
        Asset("ANIM", "anim/tbat_eq_ray_fish_hat_sweetheart_cocoa_ui.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_rayfish_hat_sweet_cocoa"] = {                    --- 
            bank = "tbat_eq_ray_fish_hat_sweetheart_cocoa",
            build = "tbat_eq_ray_fish_hat_sweetheart_cocoa",
            atlas = "images/inventoryimages/tbat_eq_ray_fish_hat_sweetheart_cocoa.xml",
            image = "tbat_eq_ray_fish_hat_sweetheart_cocoa",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.sweetheart_cocoa"),        --- 切名字用的
            name_color = "pink",
            hat_fx = "tbat_eq_ray_fish_hat_sweetheart_cocoa_hat_fx",
            bubble_fx = false,
            ui_fn = require("prefabs/03_tbat_equipments/06_02_03_ray_fish_hat_ui_sweetheart_cocoa"),
            ui_slot_offset = Vector3(0, 0, 0),
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_ray_fish_hat_sweetheart_cocoa",
                build = "tbat_eq_ray_fish_hat_sweetheart_cocoa",
                anim = "item",
                scale = 0.8,
                offset = Vector3(0, 30, 0)
            },
            onequip_hair_fn = function(inst,owner)
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
            end
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_rayfish_hat_sweet_cocoa")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 海上行走
    local function ocean_walk_on_equip(inst,owner)
        if owner.components.drownable and owner.components.drownable.enabled ~= false then
            owner.components.drownable.enabled = false
        end
        owner.Physics:ClearCollisionMask()
        owner.Physics:CollidesWith(COLLISION.GROUND)
        owner.Physics:CollidesWith(COLLISION.OBSTACLES)
        owner.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        owner.Physics:CollidesWith(COLLISION.CHARACTERS)
        owner.Physics:CollidesWith(COLLISION.GIANTS)
        owner.Physics:Teleport(owner.Transform:GetWorldPosition())
        inst.___ocean_walking = true
    end
    local function ocean_walk_on_unequip(inst,owner)
        if not inst.___ocean_walking then
            return
        end
        inst.___ocean_walking = nil
        if owner.components.drownable then
            owner.components.drownable.enabled = true
        end
        owner.Physics:ClearCollisionMask()
        owner.Physics:CollidesWith(COLLISION.WORLD)
        owner.Physics:CollidesWith(COLLISION.OBSTACLES)
        owner.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        owner.Physics:CollidesWith(COLLISION.CHARACTERS)
        owner.Physics:CollidesWith(COLLISION.GIANTS)
        owner.Physics:Teleport(inst.Transform:GetWorldPosition())
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---  延迟打开UI
    local function on_equip_delay(inst)
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if owner and owner:HasTag("player") 
            and owner.userid and not TheWorld:HasTag("cave")
            and owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) == inst
            then
            inst.selected = nil
            -- TBAT.FNS:RPC_PushEvent(owner,"open_hud",nil,inst)
            inst:PushEvent("turf_task_start")
            ocean_walk_on_equip(inst,owner)
            inst.components.container.canbeopened = true
            inst.components.container:Open(owner)            
        end
    end
    local hud_event_install_fn = require("prefabs/03_tbat_equipments/06_02_01_ray_fish_hat_ui")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 主逻辑
    local main_logic_install = require("prefabs/03_tbat_equipments/06_03_ray_fish_main_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 帽子特效
    local function remove_hat_fx(inst,owner)
        if inst.hat_fx then
            inst.hat_fx:Remove()
        end
        inst.hat_fx = nil
        if inst.hat_fxfx then
            inst.hat_fxfx:Remove()
        end
        inst.hat_fxfx = nil
    end
    local function create_hat_fx(inst,owner)
        --------------------------------------------------------------------------------------------------------
        ---
            local current_skin_data = inst.components.tbat_com_skin_data:GetCurrentData()
        --------------------------------------------------------------------------------------------------------
        --- 泡泡特效
            local origin_bubble_fx_prefab = nil
            if current_skin_data and current_skin_data.bubble_fx ~= nil then
                if type(current_skin_data.bubble_fx) == "string" and PrefabExists(current_skin_data.bubble_fx) then
                    origin_bubble_fx_prefab = current_skin_data.bubble_fx
                else
                    origin_bubble_fx_prefab = nil
                end
            else
                origin_bubble_fx_prefab = this_prefab.."_bubble_fx"
            end
            if origin_bubble_fx_prefab then
                local hat_fxfx = SpawnPrefab(origin_bubble_fx_prefab)
                hat_fxfx.entity:SetParent(owner.entity)
                hat_fxfx.entity:AddFollower()
                hat_fxfx.Follower:FollowSymbol(owner.GUID, "swap_hat", 0, 0, 0, true)
                hat_fxfx.AnimState:SetBank(this_prefab)
                hat_fxfx.AnimState:SetBuild(this_prefab)
                hat_fxfx.AnimState:PlayAnimation("bubble",true)
                hat_fxfx.AnimState:HideSymbol("test")
                hat_fxfx.AnimState:HideSymbol("hat")
                inst.hat_fxfx = hat_fxfx
            end
        --------------------------------------------------------------------------------------------------------
        --- 帽子外观特效。
            local origin_hat_fx_prefab = this_prefab.."_fx"
            if current_skin_data and current_skin_data.hat_fx then
                origin_hat_fx_prefab = current_skin_data.hat_fx
            end
            inst.hat_fx = SpawnPrefab(origin_hat_fx_prefab)
            if inst.hat_fx ~= nil then 
                inst.hat_fx:AttachToOwner(owner)
            end
        --------------------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onequip / unequip
    local function onequip(inst, owner)
        ----------------------------------------------------------------
        ---
            inst:DoTaskInTime(1, on_equip_delay)
        ----------------------------------------------------------------
        --- 帽子
            create_hat_fx(inst,owner)
            owner.AnimState:ClearOverrideSymbol("swap_hat")
        ----------------------------------------------------------------
        --- 发型
            local temp_equip_hair_fn = function(inst,owner)
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
            end
            local current_skin_data = inst.components.tbat_com_skin_data:GetCurrentData()
            if current_skin_data and current_skin_data.onequip_hair_fn then
                temp_equip_hair_fn = current_skin_data.onequip_hair_fn
            end
            temp_equip_hair_fn(inst,owner)
        ----------------------------------------------------------------
        ---- 灯光
            if inst.light_inst then
                inst.light_inst:Remove()
            end
            inst.light_inst = owner:SpawnChild("minerhatlight")
        ----------------------------------------------------------------
        --- 回san
            if owner.components.sanity and inst._sanity_task == nil then
                inst._sanity_task = inst:DoPeriodicTask(1,function()
                    owner.components.sanity:DoDelta(0.2,true)
                end)
            end
        ----------------------------------------------------------------
    end

    local function onunequip(inst, owner)
        ----------------------------------------------------------------
        --- 水上行走
            ocean_walk_on_unequip(inst,owner)
        ----------------------------------------------------------------
        --- Remove hat fx
            remove_hat_fx(inst,owner)
        ----------------------------------------------------------------
        --- 花环
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
        ----------------------------------------------------------------
        ---
            inst.components.container:Close()
        ----------------------------------------------------------------        
        ---- 灯光
            if inst.light_inst then
                inst.light_inst:Remove()
                inst.light_inst = nil
            end
        ----------------------------------------------------------------
        --- 回san
            if inst._sanity_task then
                inst._sanity_task:Cancel()
                inst._sanity_task = nil
            end
        ----------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
    local function workable_test_fn(inst,doer,right_click)
        local HAT = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if HAT == inst and not inst.replica.container:IsOpenedBy(doer) then
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        -- TBAT.FNS:RPC_PushEvent(doer,"display_hud_switch",nil,inst)
        inst.components.container.canbeopened = true
        inst.components.container:Open(doer)
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.ACTIVATE.OPEN or "UI")
        replica_com:SetSGAction("tbat_sg_empty_active")
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_eq_ray_fish_hat","tbat_eq_ray_fish_hat")
        -- inst.AnimState:SetBank("tbat_eq_ray_fish_hat")
        -- inst.AnimState:SetBuild("tbat_eq_ray_fish_hat")
        inst.AnimState:PlayAnimation("item",true)

        inst:AddTag("hat")
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")

        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        --------------------------------------------------------------
        ---
            
        --------------------------------------------------------------

        inst.entity:SetPristine()
        --------------------------------------------------------------
        --- 
            hud_event_install_fn(inst)
            workable_install(inst)
        --------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end

        --------------------------------------------------------------
        ----
            main_logic_install(inst)
            inst:AddComponent("tbat_com_skin_data")
        --------------------------------------------------------------
        ----
            inst:AddComponent("inspectable")
            inst:AddComponent("waterproofer")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_eq_ray_fish_hat","images/inventoryimages/tbat_eq_ray_fish_hat.xml")
        --------------------------------------------------------------
        ---
            inst:AddComponent("equippable")
            inst.components.equippable:SetOnEquip(onequip)
            inst.components.equippable:SetOnUnequip(onunequip)
            inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
        --------------------------------------------------------------
        ---
            MakeHauntableLaunch(inst)
        --------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- FX
    local function bubble_fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst:AddTag("FX")
        inst:AddTag("fx")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst.Transform:SetFourFaced()
        inst.entity:SetPristine()
        inst.persists = false
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
    Prefab(this_prefab.."_bubble_fx", bubble_fx, assets)
