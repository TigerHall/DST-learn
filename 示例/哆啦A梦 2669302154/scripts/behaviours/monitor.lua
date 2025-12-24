--------------------------------
--[[ Monitor: 监视]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-06]]
--[[ @updateTime: 2022-01-06]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local function Teleport(inst,pos)
    inst.Physics:Teleport(pos:Get())
end

Monitor = Class(BehaviourNode, function(self, inst, min_dist, max_dist)
    BehaviourNode._ctor(self, "Monitor")
    self.inst = inst
    if type(min_dist) == "function" then
        self.min_dist_fn = min_dist
        self.min_dist = nil
    else
        self.min_dist = min_dist
    end
    if type(max_dist) == "function" then
        self.max_dist_fn = max_dist
        self.max_dist = nil
    else
        self.max_dist = max_dist
    end
    self.currenttarget = nil
    self.action = "STAND"
end)

function Monitor:EvaluateDistances() -- this is run once per follow target
    if self.min_dist_fn ~= nil then
        self.min_dist = self.min_dist_fn(self.inst)
    end
    if self.max_dist_fn ~= nil then
        self.max_dist = self.max_dist_fn(self.inst)
    end
end
function Monitor:GetTarget()
    return TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst]
end


function Monitor:DBString()
    local dist =
    self.currenttarget ~= nil and
            self.currenttarget:IsValid() and
            math.sqrt(self.currenttarget:GetDistanceSqToInst(self.inst)) or 0
    return string.format("%s %s, (%2.2f) ", tostring(self.currenttarget), self.action, dist)
end

local function _distsq(inst, targ)
    if targ and  targ:IsValid() then
        local x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = targ.Transform:GetWorldPosition()
        local dx = x1 - x
        local dy = y1 - y
        local dz = z1 - z
        --Note: Currently, this is 3D including y-component
        --这里相乘，不考虑y轴
        return dx * dx + dz * dz , Vector3(x1, y1, z1)
    end
end

function Monitor:AreDifferentPlatforms(inst, target)
    if self.inst.components.locomotor.allow_platform_hopping then
        return inst:GetCurrentPlatform() ~= target:GetCurrentPlatform()
    end
    return false
end

function Monitor:Visit()
    --cached in case we need to use this multiple times
    local dist_sq, target_pos
    Logger:Debug({"Monitor:Visit",self.inst,TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst],self.status},1)
    if self.status == READY then
        local prev_target = self.currenttarget
        self.currenttarget = self:GetTarget()
        Logger:Debug({"Monitor:Visit",self.currenttarget},1)
        if self.currenttarget ~= nil and self.currenttarget:IsValid()  then
            dist_sq, target_pos = _distsq(self.inst, self.currenttarget)
            if dist_sq == nil then
                self.status = FAILED
            else
                if prev_target ~= self.currenttarget then
                    self:EvaluateDistances()
                end
                --local on_different_platforms = self:AreDifferentPlatforms(self.inst, self.currenttarget)
                local x,y,z = self.inst.Transform:GetWorldPosition()
                Logger:Debug({"位置1",x,y,z})
                x,y,z = self.currenttarget.Transform:GetWorldPosition()
                Logger:Debug({"位置2",x,y,z})
                --ThePlayer.Transform:GetWorldPosition()
                Logger:Debug({"行为",dist_sq,self.min_dist * self.min_dist,self.max_dist * self.max_dist})
                if  dist_sq <= self.min_dist * self.min_dist then -- 到达最小距离
                    self.status = FAILED
                elseif  dist_sq <= self.max_dist * self.max_dist then -- 未超过最远距离
                    self.status = RUNNING
                    self.action = "APPROACH" -- 靠近
                else
                    self.status = RUNNING
                    self.action = "TELEPORT" -- 太远了，传过去
                end
            end
        else
            self.status = FAILED
        end
    end
    Logger:Debug({"Monitor:Visit",self.currenttarget,self.status,self.action},1)
    if self.status == RUNNING then
        if self.currenttarget == nil or not self.currenttarget:IsValid() then
            self.status = FAILED
            self.inst.components.locomotor:Stop()
            return
        end
        if dist_sq == nil then
            dist_sq, target_pos = _distsq(self.inst, self.currenttarget)
        end
        Logger:Debug({"Monitor动作",self.action,dist_sq,self.max_dist * self.max_dist})
        if self.action == "APPROACH" then
            if  dist_sq <= self.min_dist * self.min_dist then
                self.status = SUCCESS
                return
            end
            if  (dist_sq <= self.max_dist * self.max_dist or self.inst.sg:HasStateTag("running")) then
                self.inst.components.locomotor:GoToPoint(target_pos, nil, true)
            else
                self.status = FAILED
            end
        elseif self.action == "TELEPORT" then
            if  dist_sq <= self.min_dist * self.min_dist then
                self.status = SUCCESS
                return
            end
            if  dist_sq > self.max_dist * self.max_dist then
                Teleport(self.inst, target_pos)
               -- self.inst:DoTaskInTime(0, Teleport, target_pos)
                --self.inst.Physics:Teleport(target_pos:Get())
                --self.inst.Transform:SetPosition(target_pos:Get())
                self.status = SUCCESS
            end
        end
    end
end