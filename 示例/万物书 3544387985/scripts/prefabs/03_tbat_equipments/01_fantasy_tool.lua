--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_eq_fantasy_tool"
    local speed_update_item = "tbat_material_squirrel_incisors"
    local max_ex_speed = 0.5
    local base_speed = 1.1
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_eq_fantasy_tool.zip"),
        Asset("ANIM", "anim/tbat_eq_fantasy_tool2.zip"),
        Asset("ANIM", "anim/tbat_eq_fantasy_tool_freya_s_wand.zip"),
        Asset("ANIM", "anim/tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    --[[   数据格式
            cmd_table = {
                prefab_name = "",
                skin_name = "skin_name",
                bank = "bank",
                build = "build",
                atlas = "images/inventoryimages/npng_item_no_discounts_amulet.xml",
                image = "npng_item_no_discounts_amulet",    -- 不需要 .tex
                name = "XXX",        --- 切名字用的
                name_color = {r/255,g/255,b/255,a/255},
                OverrideSymbol = {   --- 给武器类手持切换用的
                    tar_layer = "",
                    build = "",
                    src_layer = "",
                }，
                skin_link = "",    ---连携解锁用的,一起解锁这个皮肤。
                server_fn = function(inst)end, -- 切换到这个skin调用 。服务端
                client_fn = function(inst)end, -- 切换到这个skin调用 。客户端
                placed_skin_name = "",        -- 给 inst.components.deployable.ondeploy  里生成切换用的
            }
    ]]--
    local skins_data = {
        ["tbat_eq_fantasy_tool2"] = {                    --- 
            bank = "tbat_eq_fantasy_tool2",
            build = "tbat_eq_fantasy_tool2",
            atlas = "images/inventoryimages/tbat_eq_fantasy_tool2.xml",
            image = "tbat_eq_fantasy_tool2",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.2"),        --- 切名字用的
            name_color = "green",
            -- name_color = {255/255,255/255,255/255,1},
            sfx = "tbat_sfx_effect_butterfly",
            sfx_offset = Vector3(0,-300,0),
        },
        ["tbat_eq_fantasy_tool_freya_s_wand"] = {                    --- 
            bank = "tbat_eq_fantasy_tool_freya_s_wand",
            build = "tbat_eq_fantasy_tool_freya_s_wand",
            atlas = "images/inventoryimages/tbat_eq_fantasy_tool_freya_s_wand.xml",
            image = "tbat_eq_fantasy_tool_freya_s_wand",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.freya_s_wand"),        --- 切名字用的
            name_color = "blue",
            sfx = "tbat_lizifx_bow",
            sfx_offset = Vector3(25,-150,0),
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_fantasy_tool_freya_s_wand",
                build = "tbat_eq_fantasy_tool_freya_s_wand",
                anim = "in_hand",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            }
        },
        ["tbat_eq_fantasy_tool_cheese_fork"] = {                    --- 
            bank = "tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork",
            build = "tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork",
            atlas = "images/inventoryimages/tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork.xml",
            image = "tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.cheese_heart_phantom_butterfly_dining_fork"),        --- 切名字用的
            name_color = "pink",
            sfx = "tbat_lizifx_candy",
            sfx_offset = Vector3(25,-300,0),
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork",
                build = "tbat_eq_fantasy_tool_cheese_heart_phantom_butterfly_dining_fork",
                anim = "in_hand",
                scale = 0.5,
                offset = Vector3(0, 0, 0)
            }
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN:AddForDefaultUnlock("tbat_eq_fantasy_tool2")
    -- TBAT.SKIN:AddForDefaultUnlock("tbat_eq_fantasy_tool_freya_s_wand")
    -- TBAT.SKIN:AddForDefaultUnlock("tbat_eq_fantasy_tool_cheese_fork")
    TBAT.SKIN.SKIN_PACK:Pack("pack_gifts","tbat_eq_fantasy_tool_freya_s_wand")
    TBAT.SKIN.SKIN_PACK:Pack("pack_sweet_whispers_desserts","tbat_eq_fantasy_tool_cheese_fork")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- equip / unequip
    local function onequip(inst, owner)
        -- owner.AnimState:OverrideSymbol("swap_object", "swap_cane", "swap_cane")
        owner.AnimState:ClearOverrideSymbol("swap_object")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")

        local current_skindata = inst.components.tbat_com_skin_data:GetCurrentData()
        local bank_build = current_skindata and current_skindata.bank or this_prefab

        local fx = SpawnPrefab("tbat_eq_fantasy_tool_fx")
        fx.AnimState:SetBank(bank_build)
        fx.AnimState:SetBuild(bank_build)
        fx.entity:SetParent(owner.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(owner.GUID, "swap_object",0,0,0,true)
        inst.fx = fx
        ----------------------------------------------------------------------------------------------------
        --- 蝴蝶拖尾
            local fx_prefab = current_skindata and current_skindata.sfx or nil -- "cane_rose_fx"
            if fx_prefab then
                local butterfly_fx = SpawnPrefab(fx_prefab) 
                butterfly_fx.entity:SetParent(owner.entity)
                butterfly_fx.entity:AddFollower()
                local sfx_offset = current_skindata and current_skindata.sfx_offset or Vector3(0,-300,0)
                butterfly_fx.Follower:FollowSymbol(owner.GUID, "swap_object",sfx_offset.x,sfx_offset.y,sfx_offset.z,true)
                inst.butterfly_fx = butterfly_fx
            end
        ----------------------------------------------------------------------------------------------------
    end

    local function onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_object")
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
        if inst.fx then
            inst.fx:Remove()
            inst.fx = nil
        end
        if inst.butterfly_fx then
            inst.butterfly_fx:Remove()
            inst.butterfly_fx = nil
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---  speed init
    local function speed_init(com)
        local ex_speed = com:Add("ex_speed",0,0,max_ex_speed)
        com.inst.components.equippable.walkspeedmult = base_speed + ex_speed
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受升级
    local function acceptable_test_fn(inst,item,doer,right_click)
        if right_click and item.prefab == speed_update_item then
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 
            local current_ex_speed = inst.components.tbat_data:Add("ex_speed",0)
            speed_init(inst.components.tbat_data)
            if current_ex_speed >= max_ex_speed then
                return false
            end
        --------------------------------------------------
        -- 
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            else
                item:Remove()
            end
        --------------------------------------------------
        --- 
            inst.components.tbat_data:Add("ex_speed",0.05,0,max_ex_speed)
            speed_init(inst.components.tbat_data)
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.UPGRADE.GENERIC)
        replica_com:SetSGAction("doshortaction")
        replica_com:SetTestFn(acceptable_test_fn)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- tool com install
    local function hammer_switch_event(inst)
        local owner = inst.components.inventoryitem.owner
        if owner == nil then
            return
        end
        local hammer_tag = ACTIONS.HAMMER.id .. "_tool"
        if inst:HasTag(hammer_tag) then
            --- turn off
            inst.components.tool.actions[ACTIONS.DIG] = nil
            inst.components.tool.actions[ACTIONS.HAMMER] = nil
            inst:RemoveTag(ACTIONS.HAMMER.id .. "_tool")
            inst:RemoveTag(ACTIONS.DIG.id .. "_tool")
            owner.components.talker:Say(TBAT:GetString2(inst.prefab,"hammer_off"))
        else
            --- turn on
            inst.components.tool:SetAction(ACTIONS.DIG, 10)
            inst.components.tool:SetAction(ACTIONS.HAMMER)
            inst.components.tool:EnableToughWork(true)
            owner.components.talker:Say(TBAT:GetString2(inst.prefab,"hammer_on"))
        end
    end
    local function tbat_tool_com_install(inst)
        inst:AddComponent("tool")
        inst.components.tool:SetAction(ACTIONS.CHOP, 4)
        -- inst.components.tool:SetAction(ACTIONS.DIG, 10)
        inst.components.tool:SetAction(ACTIONS.MINE,10)
        inst.components.tool:SetAction(ACTIONS.NET)
        -- inst.components.tool:SetAction(ACTIONS.HAMMER)
        inst:ListenForEvent("hammer_swtich",hammer_switch_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
    local function workable_test_fn(inst,doer,right_click)
        local weapon = doer.replica.combat:GetWeapon()
        if weapon == inst then
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        inst:PushEvent("hammer_swtich")
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.CYCLE.GENERIC)
        replica_com:SetSGAction("dolongaction")
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
--- 挖田地
    local function create_till_indicator(inst,pt)
        if inst.indicator and inst.indicator:IsValid() then
            inst.indicator.time = 0            
        else
            local indicator = SpawnPrefab("tbat_sfx_tile_outline")
            inst.indicator = indicator
            indicator:DoPeriodicTask(0.3,function()
                indicator.time = (indicator.time or 0) + 0.3
                if indicator.time > 0.5 then
                    indicator:Remove()
                end
            end)
        end
        local x,y,z = TheWorld.Map:GetTileCenterPoint(pt.x,0,pt.z)
        inst.indicator.Transform:SetPosition(x,0,z)
    end
    local function special_spell_caster_test_fn(inst,doer,target,pt,right_click)
        if right_click and pt and TheWorld.Map:IsFarmableSoilAtPoint(pt.x,0,pt.z) then
            create_till_indicator(inst,pt)
            return true
        end
        return false
    end
    local function special_spell_caster_active_fn(inst,doer,target,pt)
        if not (pt and TheWorld.Map:IsFarmableSoilAtPoint(pt.x,0,pt.z) )then
            return false
        end
        local x,y,z = TheWorld.Map:GetTileCenterPoint(pt.x,0,pt.z)
        -- SpawnPrefab("log").Transform:SetPosition(x, y, z)
        local musthavetags = nil
        local canthavetags = nil
        local musthaveoneoftags = {"plantedsoil","soil"}
        local ents = TheSim:FindEntities(x, y, z, 3, musthavetags, canthavetags, musthaveoneoftags)
        for k, temp_soil in pairs(ents) do
            local tx,ty,tz = temp_soil.Transform:GetWorldPosition()
            if math.abs(tx-x) <= 2 and math.abs(tz-z) <= 2 then
                temp_soil:Remove()
            end
        end
        local delta = 1.2
        local locations = {
            Vector3(-delta,0,-delta) , Vector3(0,0,-delta) , Vector3(delta,0,-delta) ,
            Vector3(-delta,0,   0  ) , Vector3(0,0,0) , Vector3(delta,0,0) ,
            Vector3(-delta,0,delta) , Vector3(0,0,delta) , Vector3(delta,0,delta) ,
        }
        for k, t_pt in pairs(locations) do
            SpawnPrefab("farm_soil").Transform:SetPosition(x+t_pt.x, 0, z+t_pt.z)
        end
        return true
    end
    local function special_spell_caster_replica_init(inst,replica_com)
        replica_com:SetTestFn(special_spell_caster_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.DIG)
        replica_com:SetSGAction("tbat_sg_predig")
    end
    local function special_spell_caster_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_point_and_target_spell_caster",special_spell_caster_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_point_and_target_spell_caster")
        inst.components.tbat_com_point_and_target_spell_caster:SetSpellFn(special_spell_caster_active_fn)
    end
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
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        -- inst.AnimState:SetBank("tbat_eq_fantasy_tool")
        -- inst.AnimState:SetBuild("tbat_eq_fantasy_tool")
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_eq_fantasy_tool","tbat_eq_fantasy_tool")

        inst.AnimState:PlayAnimation("idle",true)
        --weapon (from weapon component) added to pristine state for optimization
        inst:AddTag("weapon")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        acceptable_com_install(inst)
        workable_install(inst)
        special_spell_caster_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tbat_data")
        inst.components.tbat_data:AddOnLoadFn(speed_init)
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(10)
        inst.components.weapon:SetRange(8,8)
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem:TBATInit("tbat_eq_fantasy_tool","images/inventoryimages/tbat_eq_fantasy_tool.xml")
        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        inst.components.equippable.walkspeedmult = base_speed
        MakeHauntableLaunch(inst)
        tbat_tool_com_install(inst)
        inst:AddComponent("fishingrod")
        inst.components.fishingrod:SetWaitTimes(1, 1)
        inst.components.fishingrod:SetStrainTimes(0, 5)
        inst:AddComponent("tbat_com_skin_data")
        inst:ListenForEvent("on_landed", item_onland_event)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---    
    local function fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_eq_fantasy_tool")
        inst.AnimState:SetBuild("tbat_eq_fantasy_tool")
        inst.AnimState:PlayAnimation("in_hand",true)
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
    Prefab(this_prefab.."_fx", fx, assets)
