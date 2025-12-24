--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local this_prefab = "tbat_eq_universal_baton"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- target checker
    local function check_target_succeed(target)
        if target.brainfn then
            return false
        end
        return true
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- net target install
    local function SetTarget(inst,target)
        if not TheWorld.ismastersim then
            return
        end
        inst.__net_target:set(target)
    end
    local function GetTarget(inst)
        return inst.__net_target:value()
    end
    local function net_target_event(inst)
        
    end
    local function net_target_fn(inst)
        inst.__net_target = net_entity(inst.GUID,"net_target","net_target")
        inst.SetTarget = SetTarget
        inst.GetTarget = GetTarget
    end
 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- focus event
    local function origin_focus_event(inst,target)
        if inst.mark and inst.mark:IsValid() then
            inst.mark:Remove()
        end
        local mark = SpawnPrefab("tbat_eq_universal_baton_mark")
        inst.mark = mark
        mark.Transform:SetPosition(target.Transform:GetWorldPosition())
        mark:PushEvent("hud_create",inst)
        mark:ListenForEvent("onremove",function()
            mark:Remove()
        end,target)
        mark:ListenForEvent("onremove",function()
            mark:Remove()
        end,inst)
        mark.target = target
        ------------------------------------------------------
        ---
            if TheCamera then
                local offset = TheCamera:GetDownVec()
                offset = offset * 0.2
                local x,y,z = mark.Transform:GetWorldPosition()
                SpawnPrefab("reskin_tool_bouquet_explode_fx").Transform:SetPosition(x+offset.x,0,z+offset.z)
            end
        ------------------------------------------------------
    end
    local function focus_update_fn(inst)
        local target = inst:GetTarget()
        if target and target:IsValid() then
            origin_focus_event(inst,target)
            inst.__target_search_task:Cancel()
            inst.__target_search_task = nil
            TBAT.FNS:RPC_PushEvent(ThePlayer,"client_focus_succeed",nil,inst)
        end
    end
    local function focus_event(inst)
        if inst.__target_search_task then
            inst.__target_search_task:Cancel()
        end
        inst.__target_search_task = inst:DoPeriodicTask(0.3,focus_update_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 施法组件
    local function special_spell_caster_test_fn(inst,doer,target,pt,right_click)
        if right_click and target and not target:HasTag("anim_scale_block") and pt == nil then
            return true
        end
        return false
    end
    local function special_spell_caster_active_fn(inst,doer,target,pt)
        if target and target:IsValid() and pt == nil and check_target_succeed(target) then
            inst.target = target
            inst:SetTarget(target)
            TBAT.FNS:RPC_PushEvent(doer,"client_start_focus",nil,inst)
            -- SpawnPrefab("reskin_tool_bouquet_explode_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
            
        end
        return true
    end
    local function client_side_target_focus_succeed_event(inst)
        inst:SetTarget(nil)
    end
    local function special_spell_caster_replica_init(inst,replica_com)
        replica_com:SetTestFn(special_spell_caster_test_fn)
        replica_com:SetText("tbat_eq_universal_baton",STRINGS.ACTIONS.BOAT_CANNON_START_AIMING)
        replica_com:SetSGAction("quickcastspell")
        replica_com:SetDistance(10)
    end
    local function special_spell_caster_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_point_and_target_spell_caster",special_spell_caster_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_point_and_target_spell_caster")
        inst.components.tbat_com_point_and_target_spell_caster:SetSpellFn(special_spell_caster_active_fn)
        inst:ListenForEvent("client_focus_succeed",client_side_target_focus_succeed_event)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 按钮控制逻辑
    local button_logic_fns = {
        ["rotation"] = function(inst,target)
            if target.Transform == nil then
                return
            end
            local rotation = target.Transform:GetRotation()
            rotation = rotation + 10
            if rotation > 180 then
                rotation = rotation - 360
            end
            target.Transform:SetRotation(rotation)
        end,
        ["mirror"] = function(inst,target)
            if target.components.tbat_com_universal_baton_data then
                target.components.tbat_com_universal_baton_data:Mirror()
            end
        end,
        ["big"] = function(inst,target)
            if target.components.tbat_com_universal_baton_data then
                target.components.tbat_com_universal_baton_data:ScaleDelta(0.05)
            end
        end,
        ["small"] = function(inst,target)
            if target.components.tbat_com_universal_baton_data then
                target.components.tbat_com_universal_baton_data:ScaleDelta(-0.05)
            end
        end,
        ["skin"] = function(inst,target)
            local doer = inst.components.inventoryitem.owner
            if doer == nil then
                return
            end
            if target.components.tbat_com_skin_data then
                doer.components.tbat_com_skins_controller:ReskinTarget(target)
                return
            end
        end,
        ["reset"] = function(inst,target)
            if target.components.tbat_com_universal_baton_data then
                target.components.tbat_com_universal_baton_data:ResetScale()
            end
            if target.Transform then
                target.Transform:SetRotation(0)
            end
        end,
    }
    local function button_event(inst,cmd)
        -- print("button_event",inst.target,cmd.type)
        if inst.target and button_logic_fns[cmd.type] then
            button_logic_fns[cmd.type](inst,inst.target)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local speed_update_item = "tbat_material_squirrel_incisors"
    local function acceptable_test_fn(inst,item,doer,right_click)
        if right_click and item.prefab == speed_update_item then
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 
            local level = inst.components.tbat_data:Add("level",0)
            if level >= 10 then
                return false,"item_accept_fail"
            end
        --------------------------------------------------
        --
            item.components.stackable:Get():Remove()
            inst.components.tbat_data:Add("level",1)
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
    ----- speed update fn
    local function speed_com_update_fn(inst)
        local old_GetWalkSpeedMult = inst.components.equippable.GetWalkSpeedMult
        inst.components.equippable.GetWalkSpeedMult = function(self)
            local level = self.inst.components.tbat_data:Get("level") or 0
            local speed_mult = 1 + level * 0.05
            self.walkspeedmult = speed_mult
            return old_GetWalkSpeedMult(self)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    net_target_fn(inst)
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("client_start_focus",focus_event)
    end
    special_spell_caster_install(inst)
    acceptable_com_install(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("button",button_event)
    inst:DoTaskInTime(1,speed_com_update_fn)

    inst:AddComponent("tbat_com_action_fail_reason")
    inst.components.tbat_com_action_fail_reason:Add_Reason("item_accept_fail",TBAT:GetString2(this_prefab,"item_accept_fail"))
end