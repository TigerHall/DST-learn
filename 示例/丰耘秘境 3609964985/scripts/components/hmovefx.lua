local HMoveFx = Class(function(self, inst)
    self.inst = inst

    if not self.inst.components.locomotor then
        self.inst:AddComponent("locomotor")
    end
    self.locomotor = self.inst.components.locomotor
    self.locomotor.walkspeed = 1
    self.locomotor.runspeed = 1
    self.locomotor:SetTriggersCreep(false) -- 禁用在爬行时触发的机制
    self.locomotor:EnableGroundSpeedMultiplier(false) -- 禁用地面速度的倍增
    self.locomotor.pathcaps = { ignorewalls = true, allowocean = true } -- 设置路径特性：可以忽略墙壁，允许在海洋中移动

    self.movingtarget = nil
    self.min_distancesq = 0.5
    self.movecount = 0
    self.max_movecount = 100
end)

-- 设置速度
function HMoveFx:SetSpeed(walk, run)
    self.inst.components.locomotor.walkspeed = walk
    self.inst.components.locomotor.runspeed = run
end

-- 设置删除最小距离
function HMoveFx:SetMinDistance(distance)
    self.min_distancesq = distance * distance
end

-- 设置移动目标
function HMoveFx:SetMovingTarget(target)
    self.movingtarget = target
end

-- 设置移动到达时的回调函数
function HMoveFx:SetOnReachTarget(fn)
    -- onreachtarget(inst, target)
    self.onreachtarget = fn
end

-- 设置到达指定移动次数后删除
function HMoveFx:SetMAxMoveCount(count)
    self.max_movecount = count
end

local function Move(inst, self)
    if self.movingtarget == nil or not self.movingtarget:IsValid() then
        if self.movetask ~= nil then
            self.movetask:Cancel()
            self.movetask = nil
        end
        inst:Remove()
    elseif self.movecount >= self.max_movecount or self.inst:GetDistanceSqToInst(self.movingtarget) <= self.min_distancesq then
        if self.onreachtarget ~= nil then
            self.onreachtarget(self.inst, self.movingtarget)
        end
        if self.movetask ~= nil then
            self.movetask:Cancel()
            self.movetask = nil
        end
        inst:Remove()
    else --更新目标地点
        self.inst:ForceFacePoint(self.movingtarget.Transform:GetWorldPosition())
        self.movecount = self.movecount + 1
    end
end

-- 开始移动
function HMoveFx:StartMove()
    if self.movingtarget == nil or not self.movingtarget:IsValid() then
        self.inst:Remove()
    else
        self.inst:ForceFacePoint(self.movingtarget.Transform:GetWorldPosition())
        self.locomotor:WalkForward()
        self.movetask = self.inst:DoPeriodicTask(FRAMES * 2, Move, nil, self)
    end
end

-- 保存状态
function HMoveFx:OnSave()
    local data =
    {
        movingtarget = self.movingtarget,
        movecount = self.movecount,
        min_distancesq = self.min_distancesq,
        onreachtarget = self.onreachtarget,
    }
    return next(data) ~= nil and data or nil
end

-- 加载状态
function HMoveFx:OnLoad(data)
    if data then
        self.movingtarget = data.movingtarget
        self.movecount = data.movecount
        self.min_distancesq = data.min_distancesq
        self.onreachtarget = data.onreachtarget
    end

    self.inst:DoTaskInTime(0, function()
        if self.movingtarget == nil or not self.movingtarget:IsValid() then
            self.inst:Remove()
        else
            self:StartMove()
        end
    end)
end

return HMoveFx