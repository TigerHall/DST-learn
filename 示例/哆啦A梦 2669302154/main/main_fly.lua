--------------------------------
--[[ 飞行相关设置]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-01]]
--[[ @updateTime: 2021-12-11]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("constants")
require("util/logger")
local Upvalue = require "util/upvalue"
local Table = require "util/table"
-- 飞行不会被触手攻击
AddPrefabPostInit("tentacle",function(inst)
    if inst.components.combat then
        local  RETARGET_CANT_TAGS = Upvalue:Get(inst.components.combat.targetfn,"RETARGET_CANT_TAGS")
        if not Table:HasValue(RETARGET_CANT_TAGS,TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_TAG) then
            table.insert(RETARGET_CANT_TAGS,TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_TAG)
        end
    end
end)

-- 是否在飞行
local IsFlying = function(inst) return inst and inst.components.doraemon_fly and inst.components.doraemon_fly:IsFlying()end

-- 去除脚步声
local oldPlayFootstep=GLOBAL.PlayFootstep
GLOBAL.PlayFootstep=function(inst, ...) --去除脚步声
    if inst and IsFlying(inst) then
        return
    end
    return oldPlayFootstep(inst, ...)
end

-- 停止飞行
local function StopFlying(inst, openInventory)
    if inst and IsFlying(inst) then
        inst.components.doraemon_fly:SetFlying(false,true,openInventory)--直接关闭飞行且无着陆动画
    end
end

-- 攻击(去除地震的攻击伤害)
AddComponentPostInit("combat",function(self)
    local oldGetAttacked =self.GetAttacked
    function self:GetAttacked(...)
        if self.inst.components.doraemon_fly ~= nil and self.inst.components.doraemon_fly:IsFlying() then
            --飞行
            local attacker  = GLOBAL.select(1,...)
            if attacker.prefab == "antlion_sinkhole" then -- 地震 直接返回true 实现飞行中地震不会造成伤害
                return true
            end
        end
        return oldGetAttacked(self,...)
    end
end)

-- 飞行
AddComponentPostInit("locomotor",function(self)
    -- 额外增加设置速度的hook
    if TheWorld.ismastersim then
        local oldSetExternalSpeedMultiplier =self.SetExternalSpeedMultiplier
        function self:SetExternalSpeedMultiplier(source, key, m,...)
            oldSetExternalSpeedMultiplier(self,source, key, m,...)--旧逻辑
            if self.inst.components.doraemon_fly ~= nil and self.inst.components.doraemon_fly:IsFlying() then
                --飞行
                if key == nil then
                    return
                elseif m == nil or m == 1 then
                    return
                end
                -- 以上判断同源码旧逻辑
                if key == "sandstorm" then -- 沙尘暴
                    self.inst.components.doraemon_fly.externalspeedmultiplier:set(m)
                end
            end
        end

        local oldRemoveExternalSpeedMultiplier = self.RemoveExternalSpeedMultiplier
        function self:RemoveExternalSpeedMultiplier(source, key,...)
            oldRemoveExternalSpeedMultiplier(self,source, key,...)--旧逻辑
            if self.inst.components.doraemon_fly ~= nil and self.inst.components.doraemon_fly:IsFlying() then--飞行
                --飞行
                -- 以上判断同旧逻辑
                if key == "sandstorm" then -- 沙尘暴
                    self.inst.components.doraemon_fly.externalspeedmultiplier:set(1)
                end
            end
        end
    end



    local oldGetRunSpeed = self.GetRunSpeed
    function self:GetRunSpeed(...)
        if self.inst.components.doraemon_fly ~= nil and self.inst.components.doraemon_fly:IsFlying() then--飞行
            return self.inst.components.doraemon_fly:GetRunSpeed()
        end
        return oldGetRunSpeed(self,...)--旧逻辑
    end

    local oldRunForward=self.RunForward
    function self:RunForward(direct, ...)
        oldRunForward(self, direct, ...)
        -- 保证飞行过程不掉下去,所以需要时刻更新
        if  self.inst.components.doraemon_fly and  self.inst.components.doraemon_fly:IsFlying() then
            self.inst.components.doraemon_fly:UpdateHeight()
            Logger:Debug("RunForward:UpdateHeight")
        end
    end

end)

AddComponentPostInit("freezable",function(self)
    local oldFreeze=self.Freeze
    self.Freeze=function(self, freezetime, ...)
        StopFlying(self.inst, true) --冰冻结束飞行
        return oldFreeze(self, freezetime, ...)
    end
end)

AddComponentPostInit("grogginess",function(self)
    local oldKnockOut=self.KnockOut
    self.KnockOut=function(self, ...)
        StopFlying(self.inst, true) --睡眠结束飞行
        return oldKnockOut(self, ...)
    end
end)

AddComponentPostInit("pinnable",function(self)
    local oldStick=self.Stick
    self.Stick=function(self, ...)
        StopFlying(self.inst, true) --粘住结束飞行
        return oldStick(self, ...)
    end
end)

AddComponentPostInit("highlight",function(self)
    local oldHighlight=self.Highlight
    self.Highlight=function(self, r, g, b, ...)
        if self.inst:HasTag("NOHIGHLIGHT") then --禁止高亮
            return
        end
        return oldHighlight(self, r, g, b, ...)
    end
end)

AddPrefabPostInit("lureplant", function(inst)--食人花
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(0.1,function()
        local pt = Point(inst.Transform:GetWorldPosition())
        if inst.Physics then
            inst.Physics:Teleport(pt.x,0,pt.z)
        end
    end)
end)

AddPrefabPostInit("explosivehit", function(inst)--爆炸攻击
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(1, inst.Remove)
end)

AddPrefabPostInit("rock_ice", function(inst)--石头 冰
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(0.1,function()
        local pt = Point(inst.Transform:GetWorldPosition())
        if inst.Physics then
            inst.Physics:Teleport(pt.x,0,pt.z)
        end
    end)
end)

local function checkfly(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 15, {"player"}, {"INLIMBO","playerghost"})
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.health and not v.components.health:IsDead() and IsFlying(v) then
            if v.components.doraemon_fly:GetPercent() >= 1 then-- 停止飞行
                StopFlying(v,true)
                v.components.combat:GetAttacked(inst, 20, nil, "darkness")
                v.components.sanity:DoDelta(-10)
            end
        end
    end
end
-- 查理
AddPrefabPostInit("stalker", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:DoPeriodicTask(1, checkfly, 1)
end)


local function AddPlayerSgPostInit(fn)
    AddStategraphPostInit('wilson', fn)
    AddStategraphPostInit('wilson_client', fn)
end



AddPlayerSgPostInit(function(self)
    -- 修改停止动画,以实现旋转
    local idle = self.states.idle
    if idle then
        local old_enter = idle.onenter
        function idle.ontimeout(inst) end -- 这里源码是做dofunny动作,我们在飞,就别搞笑了
        function idle.onenter(inst, ...)
            --正常是播放idle_loop,需要注意该动画是否为循环播放
            --在源码player_idles.zip中,时间长度2200ms,有略微幅度摇晃
            if old_enter then
                old_enter(inst, ...)
            end
            -- 播放现在的动画
            if IsFlying(inst) then
                inst.AnimState:PlayAnimation("doraemon_fly_idle",true)
            end
        end
    end

    -- 修改走路动画
    local run = self.states.run
    if run then
        local old_enter = run.onenter
        function run.onenter(inst, ...)
            if old_enter then
                old_enter(inst, ...)
            end
            if IsFlying(inst) then
                if not inst.AnimState:IsCurrentAnimation("doraemon_fly_loop") then
                    inst.AnimState:PlayAnimation("doraemon_fly_loop", true)
                end
                inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() + 0.01)
            end
        end
    end

    local run_start = self.states.run_start
    if run_start then
        local old_enter = run_start.onenter
        function run_start.onenter(inst, ...)
            if old_enter then
                old_enter(inst, ...)
            end
            if IsFlying(inst) then
                inst.AnimState:PlayAnimation("doraemon_fly_pre")
            end
        end
    end

    local run_stop = self.states.run_stop
    if run_stop then
        local old_enter = run_stop.onenter
        function run_stop.onenter(inst, ...)
            if old_enter then
                old_enter(inst, ...)
            end
            if IsFlying(inst) then
                inst.AnimState:PlayAnimation("doraemon_fly_pst")
            end
        end
    end
end)



-- 每个玩家添加飞行组件
AddPlayerPostInit(function(inst)
    inst:AddComponent("doraemon_fly")
    if TheWorld.ismastersim then
        inst:ListenForEvent("hungerdelta", function(inst,data) --饱食度耗尽结束飞行
            if data and data.newpercent<=0 and IsFlying(inst)  then
                -- 需要推送一个事件,以实现着陆动画
                local bufferedaction = BufferedAction(inst, inst, GLOBAL.ACTIONS["DORAEMON_FLY_LAND"])
                inst.components.locomotor:PushAction(bufferedaction)

            end
        end)
        inst:ListenForEvent("healthdelta", function(inst,data) -- 雷击
            if data and data.cause == "lightning" and IsFlying(inst)  then
                StopFlying(inst,true)
            end
        end)
        inst:ListenForEvent("knockback", function(inst,data) -- 被击飞
            if IsFlying(inst) then
                StopFlying(inst,true)
            end
        end)
        inst:ListenForEvent("attacked", function(inst,data) -- 被攻击咱就下来吧
            if IsFlying(inst) then
                StopFlying(inst,true)
            end
        end)
        inst:ListenForEvent("death", function(inst,data) --死亡结束飞行
            if IsFlying(inst) then
                StopFlying(inst,false)
            end
        end)

        inst:ListenForEvent("transform_wereplayer", function(inst,data) --死亡结束飞行
            if IsFlying(inst) then
                StopFlying(inst,false)
            end
        end)
    end
end)
