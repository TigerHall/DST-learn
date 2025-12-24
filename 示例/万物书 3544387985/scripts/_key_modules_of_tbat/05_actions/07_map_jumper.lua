----------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
----------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 注册地图监听事件
    local function ArriveAnywhere()
        return true
    end

    local TBAT_BLINK_MAP = Action({ priority = 999, customarrivecheck = ArriveAnywhere, rmb = true, mount_valid = true, map_action = true, closes_map = true })
    TBAT_BLINK_MAP.id = "TBAT_BLINK_MAP"
    TBAT_BLINK_MAP.strfn = function(act) --- 客户端检查是否通过,同时返回显示字段
        if act.doer then
            return "DEFAULT"
        end
    end

    TBAT_BLINK_MAP.fn = function(act)    --- 只在服务端执行~
        local doer = act.doer
        local act_pos = act:GetActionPoint()
        local pos = Vector3(act_pos:Get())
        if act == nil or act.doer == nil or act.pos == nil then
            return false
        end
        if act.doer.tbat_map_portal_cd then --返回false的话会说话
            return true
        end
        -- local item = doer and doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.TBAT_MAP_JUMPER)
        -- if doer and doer.sg 
        --     and item and item.replica.tbat_com_map_jumper and item.replica.tbat_com_map_jumper:Test(doer,pt)
        --     then
        --         return item.components.tbat_com_map_jumper:CastSpell(doer,pt)
        -- end

        -- 物品栏有地图跳跃就生效
        local has = doer and doer.replica.inventory:HasItemWithTag("tbat_map_blinker", 1)
        if has and doer:HasTag("player") then
                local test = 100
                local pt = nil
                while test > 0 do
                    local x = pos.x + math.random(-40,40)/10
                    local z = pos.z + math.random(-40,40)/10
                    if TheWorld.Map:IsPassableAtPoint(x,0,z,false,false) then
                        pt = Vector3(x,0,z)
                        break
                    end
                    test = test - 1
                end
                if pt then
                    doer.components.playercontroller:RemotePausePrediction(5)
                    doer.Transform:SetPosition(pt.x,0,pt.z)
                    doer.Physics:Teleport(pt.x,0,pt.z)
                    -- cd
                    act.doer.tbat_map_portal_cd = true
                    if act.doer.tbat_map_portal_cd_task == nil then
                        act.doer.tbat_map_portal_cd_task = act.doer:DoTaskInTime(1, function()
                            act.doer.tbat_map_portal_cd = false
                            act.doer.tbat_map_portal_cd_task = nil
                        end)
                    end
                end
                -- 其实关闭地图只需要给动作传一个参数就行了
                -- TBAT.FNS:RPC_PushEvent(doer,"tbat_event.ToggleMap")
            return true
        end
    end

    AddAction(TBAT_BLINK_MAP)
    STRINGS.ACTIONS.TBAT_BLINK_MAP = {
        DEFAULT = "万物穿梭",
    }
    STRINGS.TBAT_BLINK_MAP = ACTIONS.TBAT_BLINK_MAP.mod_name

    -- local BLINK_MAP_MUST = { "CLASSIFIED", "globalmapicon", "fogrevealer" }
    ACTIONS_MAP_REMAP[ACTIONS.TBAT_BLINK_MAP.code] = function(act, targetpos)
        -----------------------------------------------------
        -- 这部分代码会在地图上以 30FPS 执行
        -----------------------------------------------------
        local doer = act.doer
        -- print("map jumper doer",doer)

        if doer == nil then
            return nil
        end       
        if not TheWorld.Map:IsAboveGroundAtPoint(targetpos.x,targetpos.y,targetpos.z) then
            return nil
        end
        local inventory = doer and doer.replica.inventory
        local item = inventory and inventory:HasItemWithTag("tbat_map_blinker", 1)
        -- print("map jumper item",item)
        if item == nil then
            return nil
        end
        local act_remap = BufferedAction(doer, nil, ACTIONS.TBAT_BLINK_MAP, act.invobject, targetpos)
        return act_remap

    end

AddStategraphActionHandler('wilson', ActionHandler(ACTIONS.TBAT_BLINK_MAP))
AddStategraphActionHandler('wilson_client', ActionHandler(ACTIONS.TBAT_BLINK_MAP))
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- player controller hook
    local function player_controller_hook(self)
        

        -- local old_GetMapActions_fn = self.GetMapActions
        -- self.GetMapActions = function(self,position)
        --     local LMBaction, RMBaction = old_GetMapActions_fn(self, position)

        --     ----------------------------------------------------------------------------------------
        --             -- local inventory = self.inst.components.inventory or self.inst.replica.inventory
        --             -- if inventory and inventory:EquipHasTag("mms_scroll_blink_map") then
        --             --     local equipments = self.inst.replica.inventory and self.inst.replica.inventory:GetEquips() or {}
    
        --             --     -------- 获取装备，用于放到 act.invobject 里
        --             --         local invobject = nil
        --             --         for e_slot, e_item in pairs(equipments) do
        --             --             if e_item and e_item:HasTag("mms_scroll_blink_map") then
        --             --                 invobject = e_item
        --             --                 break
        --             --             end
        --             --         end
    
                        
        --             -- end
        --     ----------------------------------------------------------------------------------------
        --             local item = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.TBAT_MAP_JUMPER)
        --             if item then
        --                 local act = BufferedAction(self.inst, nil, ACTIONS.TBAT_BLINK_MAP)
        --                 RMBaction = self:RemapMapAction(act, position)
        --             end
        --     ----------------------------------------------------------------------------------------
    
    
        --     return LMBaction, RMBaction    
        -- end







        -- local old_OnMapAction_fn = self.OnMapAction
        -- self.OnMapAction = function(self,actioncode, position)
        --     old_OnMapAction_fn(self,actioncode, position)

        --     local item = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.TBAT_MAP_JUMPER)

        --     if item then

        --         local act = MOD_ACTIONS_BY_ACTION_CODE[STRINGS.TBAT_BLINK_MAP][actioncode]
        --         if act == nil or not act.map_action then
        --             return
        --         end
        --         if self.ismastersim then

        --                     local LMBaction, RMBaction = self:GetMapActions(position)
        --                     if act.rmb and RMBaction then ---- 右键
        --                         -- print("error rmb",position)
        --                         -- for k, v in pairs(act) do
        --                         --     print(k,v)
        --                         -- end
        --                         -- print("error rmb ++++++ ",position)
        --                         -- for k, v in pairs(RMBaction or {}) do
        --                         --     print(k,v)
        --                         -- end
        --                         -- self:DoAction(BufferedAction(self.inst, nil, ACTIONS.MMS_SCROLL_BLINK_MAP))
        --                         -- self:DoAction(BufferedAction(self.inst,nil, RMBaction))
        --                         -- self:DoAction(RMBaction)
        --                         -- self.locomotor:PushAction(RMBaction, true)
        --                         RMBaction:Do()
        --                     end

        --         else
        --             SendRPCToServer(RPC.DoActionOnMap, actioncode, position.x, position.z)                
        --         end
                
        --     end

        -- end

    local oldGetMapActions = self.GetMapActions
    function self:GetMapActions(position, maptarget, actiondef)
        local LMBaction, RMBaction = oldGetMapActions(self, position, maptarget, actiondef)
        local inventory = self.inst.replica.inventory
        if inventory and inventory:HasItemWithTag("tbat_map_blinker", 1) then
            local act = BufferedAction(self.inst, nil, ACTIONS.TBAT_BLINK_MAP)
            RMBaction = self:RemapMapAction(act, position)
        end
        return LMBaction, RMBaction
    end

    local oldOnMapAction = self.OnMapAction
    function self:OnMapAction(actioncode, position, maptarget, mod_name, ...)
        -- 因为有mod会hook这个函数，但是没有跟着官方更新，会少传一个mod_name参数导致自己的传送不能生效，所以这里做一个兼容性处理
        -- 复制一遍官方的逻辑，指定动作，保证自己的逻辑一定能执行，然后加上cd和各种检测
        local act = MOD_ACTIONS_BY_ACTION_CODE[ACTIONS.TBAT_BLINK_MAP.mod_name][actioncode]
        if act and act.map_action then
            act.target = maptarget -- Optional.
            if self.ismastersim then
                local LMBaction, RMBaction = self:GetMapActions(position, maptarget, act)
                if act.rmb then
                    if RMBaction then
                        self.locomotor:PushAction(RMBaction, true)
                    end
                else
                    if LMBaction then
                        self.locomotor:PushAction(LMBaction, true)
                    end
                end
            elseif self.locomotor == nil then
                -- TODO(JBK): Hook up pre_action_cb here.
                SendRPCToServer(RPC.DoActionOnMap, actioncode, position.x, position.z, maptarget, mod_name)
            elseif self:CanLocomote() then
                local LMBaction, RMBaction = self:GetMapActions(position, maptarget, act)
                if act.rmb then
                    RMBaction.preview_cb = function()
                        SendRPCToServer(RPC.DoActionOnMap, actioncode, position.x, position.z, maptarget, mod_name)
                    end
                    self.locomotor:PreviewAction(RMBaction, true)
                else
                    LMBaction.preview_cb = function()
                        SendRPCToServer(RPC.DoActionOnMap, actioncode, position.x, position.z, maptarget, mod_name)
                    end
                    self.locomotor:PreviewAction(LMBaction, true)
                end
            end
        end
        return oldOnMapAction(self, actioncode, position, maptarget, mod_name, ...)
    end
    end
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 地图关闭/开启 。 玩家控制器 hook
    AddPlayerPostInit(function(inst)
        inst:ListenForEvent("tbat_event.ToggleMap",function()
            if inst.HUD then
                inst.HUD.controls:ToggleMap()
            end
        end)
        inst:DoTaskInTime(0,function()
            if inst.components.playercontroller then
                player_controller_hook(inst.components.playercontroller)
            end
        end)            
    end)


local TBAT_USE = Action({ priority = 1 })
TBAT_USE.id = 'TBAT_USE'
TBAT_USE.str = '激活'
TBAT_USE.fn = function(act)
    if act.doer and act.invobject and act.invobject.components.useableitem then
        return act.invobject.components.useableitem:StartUsingItem()
    end
end
AddAction(TBAT_USE)

AddComponentAction(
    'INVENTORY',
    'useableitem',
    function(inst, doer, actions)
        if doer then
            if inst.prefab == 'tbat_eq_world_skipper' then
                table.insert(actions, ACTIONS.TBAT_USE)
            end
        end
    end
)

AddStategraphActionHandler('wilson', ActionHandler(ACTIONS.TBAT_USE, 'give'))
AddStategraphActionHandler('wilson_client', ActionHandler(ACTIONS.TBAT_USE, 'give'))
----------------------------------------------------------------------------------------------------------------------------------------------------------------
