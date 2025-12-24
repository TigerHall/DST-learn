--------------------------------
--[[ 客户端状态]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-11-29]]
--[[ @updateTime: 2021-11-29]]
--[[ @email: x7430657@163.com]]
--------------------------------

require("util/logger")
local client_states = {
    State({
        name = "doraemon_flyskill_up",
        tags ={"idle", "doraemon_flyskill","busy","doing","notalking"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            if inst.replica.hunger:GetCurrent() < TUNING.DORAEMON_TECH.DORAEMON_FLY_OFF_MIN_HUNGER  then
                -- 虽然动作里返回了false 但是这里会清除
                inst.sg:GoToState("idle")
                inst:ClearBufferedAction()
                inst.components.talker:Say(STRINGS.DORAEMON_TECH.DORAEMON_FLY_OFF_HUNGER)
                return
            end
            if  inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
                inst.sg:GoToState("idle")
                inst:ClearBufferedAction()
                inst.components.talker:Say(STRINGS.DORAEMON_TECH.DORAEMON_FLY_OFF_RIDE)
                return
            end
            inst:ForceFacePoint(inst.Transform:GetWorldPosition())
            inst.AnimState:PlayAnimation("jumpboat")
            Logger:Debug("Client 播放动画",true,true)
            inst.components.doraemon_fly._percent:set_local(0)
            if  inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            if inst.components.health then--起飞过程是无敌的
                inst.components.health:SetInvincible(true)
            end
            inst.sg:SetTimeout(2)
        end,
        timeline = {
            TimeEvent(0* FRAMES, function(inst)
                inst:PerformPreviewBufferedAction()
            end),
            --TimeEvent(4* FRAMES, function(inst)inst.sg:RemoveStateTag('busy') end),
        },
        onupdate = function(inst, dt)--每帧都会触发,dt:每次update之间的时间差
            inst.components.doraemon_fly._percent:set_local(math.min(inst.components.doraemon_fly:GetPercent() + 1.4*dt, 1))
            inst.components.doraemon_fly:UpdateHeight()
        end,
        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("idle")
            inst.sg:GoToState("idle", true)
        end,
        events = {
            EventHandler( "animqueueover", function(inst)
                Logger:Debug("Client 动画全部结束,跳转idle状态")
                inst.sg:GoToState("idle")
            end)
        },
        onexit = function(inst)
            Logger:Debug("Client 上升状态结束")
            if not inst.components.doraemon_fly:IsFlying() then --避免起飞过程下来触发bug
                inst.components.doraemon_fly._percent:set(0)
            else
                inst.components.doraemon_fly._percent:set(1)
            end
            inst.components.doraemon_fly:UpdateHeight()
            if  inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            if inst.components.health then
                inst.components.health:SetInvincible(false)
            end
        end,
    }),
    State{
        name = "doraemon_flyskill_down",
        tags ={"idle", "doraemon_flyskill","busy","doing","notalking"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ForceFacePoint(inst.Transform:GetWorldPosition())
            inst.AnimState:PlayAnimation("jumpboat")
            inst.components.doraemon_fly._percent:set_local(1)
            if  inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            if inst.components.health then
                inst.components.health:SetInvincible(true)
            end
            inst.sg:SetTimeout(2)
        end,
        timeline = {
            TimeEvent(0* FRAMES, function(inst)inst:PerformPreviewBufferedAction() end),
            --TimeEvent(4* FRAMES, function(inst)inst.sg:RemoveStateTag('busy') end),
        },
        onupdate = function(inst, dt)
            inst.components.doraemon_fly._percent:set_local(math.max(inst.components.doraemon_fly:GetPercent() - 1.4*dt, 0))
            inst.components.doraemon_fly:UpdateHeight()
        end,
        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("idle")
            inst.sg:GoToState("idle", true)
        end,
        events = {
            EventHandler( "animqueueover", function(inst) inst.sg:GoToState("idle") end)
        },
        onexit = function(inst)
            inst.components.doraemon_fly._percent:set(0)
            inst.components.doraemon_fly:UpdateHeight()
            if  inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            if inst.components.health then
                inst.components.health:SetInvincible(false)
            end
        end,
    },
}
return {
    states = client_states,
}
