--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
    local type_data = require("prefabs/07_tbat_buildings/01_03_piano_type_data")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- workable
    local function workable_test_fn(inst,doer,right_click)
        return right_click
    end
    local function workable_on_work_fn(inst,doer)
        TBAT.FNS:RPC_PushEvent(doer,"open_hud",nil,inst)
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("tbat_building_piano_rabbit",STRINGS.ACTIONS.CASTSPELL.MUSIC)
        replica_com:SetSGAction("give")
        replica_com:SetDistance(1.5)
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
-- 类型切换
    local function type_data_init(inst)
        -------------------------------------------------------------------
        --- 清除旧的所有tag
            for prefab, v in pairs(type_data) do
                inst:RemoveTag(prefab.."_unlocked")
            end
        -------------------------------------------------------------------
        --- 缺省解锁
            inst:AddTag("researchlab2_unlocked")
        -------------------------------------------------------------------
        --- 已经解锁的tag
            for prefab, v in pairs(type_data) do
                if inst.components.tbat_data:Get(prefab) then
                   inst:AddTag(prefab.."_unlocked")
                end
            end            
        -------------------------------------------------------------------
    end
    local function type_switch_event(inst,cmd)
        local prefab = cmd.prefab
        local userid = cmd.userid
        if not (userid and type_data[prefab]) then
            return
        end
        local player = LookupPlayerInstByUserID(userid)
        if not inst:HasTag(prefab.."_unlocked") then
            local item_prefab = type_data[prefab].item
            local str = TBAT:GetString2(inst.prefab,"unlock_cmd_info_str")
            -- 定义替换的内容
            local replacements = {
                BUILDING = STRINGS.NAMES[string.upper(prefab)],   -- BUILDING
                ITEM = STRINGS.NAMES[string.upper(item_prefab)],     -- ITEM
            }
            -- 使用 gsub 进行替换
            local result = string.gsub(str, "{(.-)}", function(key)
                return replacements[key] or "?" .. key .. "?"
            end)
            if player.components.talker then
                player.components.talker:Say(result)
            end
            return
        end
        local x,y,z = inst.Transform:GetWorldPosition()
        local saved_data = inst.components.tbat_data:OnSave()
        local scale_x,scale_y,scale_z = 1,1,1
        if inst.AnimState and inst.AnimState.GetScale then
            scale_x,scale_y,scale_z = inst.AnimState:GetScale()
        end
        inst:Remove()
        local new_inst = SpawnPrefab("tbat_building_piano_rabbit_"..prefab)
        new_inst.AnimState:SetScale(scale_x or 1,scale_y or 1,scale_z or 1)
        new_inst.components.tbat_data:OnLoad(saved_data)
        new_inst.Transform:SetPosition(x,y,z)
        -- player.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/active")
        new_inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_building_piano_rabbit/switch_"..math.random(3))

    end
    local function type_swtich_logic_install(inst)
        inst:DoTaskInTime(0,type_data_init)
        inst:ListenForEvent("type_swtich",type_switch_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function acceptable_test_fn(inst,item,doer,right_click)        
        for prefab, data in pairs(type_data) do
            if data.item == item.prefab and not inst:HasTag(prefab.."_unlocked") then
                return true
            end
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            else
                item:Remove()
            end
        --------------------------------------------------
        --- 
            for prefab, data in pairs(type_data) do
                if data.item == item.prefab and not inst:HasTag(prefab.."_unlocked") then
                    inst.components.tbat_data:Set(prefab,true)
                    type_data_init(inst)
                    -- inst.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/active")
                    inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_building_piano_rabbit/switch_"..math.random(3))
                    return true
                end
            end
        --------------------------------------------------
        return false
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText("tbat_building_piano_rabbit",STRINGS.ACTIONS.UPGRADE.GENERIC)
        replica_com:SetSGAction("dolongaction")
        replica_com:SetTestFn(acceptable_test_fn)
        replica_com:SetDistance(1.5)
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
return function(inst)
    workable_install(inst)
    acceptable_com_install(inst)
    if not TheWorld.ismastersim then
        return
    end
    type_swtich_logic_install(inst)
end

