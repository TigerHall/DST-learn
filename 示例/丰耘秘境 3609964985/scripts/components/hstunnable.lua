local MAX_BEARABLE_STUNDEGREE = 50

local Stunnable = Class(function(self, inst)
    self.inst = inst
    self.isstunned = false
    self.color = { 0.5, 0.45, 0.35, 0 }
    self.color_mult = 0.5
    self.unstun_task = nil
    self.targettime = nil

    self.stundegree_bearable = 10
    self.awakable = true
    self.awake_percent = 0.2
end)

function Stunnable:SetOnStunnedFn(fn)
    self.onstunnedfn = fn
end

-- 定身颜色
function Stunnable:SetStunnedColorMult(mult)
    self.color_mult = mult
end

function Stunnable:SetStunnedColor(r, g, b, a)
    local mul = self.color_mult or 1
    if r <= 1 and g <= 1 and b <= 1 and a <= 1 then
        self.color = { r * mul, g * mul, b * mul, a * mul }
    else
        self.color = { (r / 255) * mul, (g / 255) * mul, (b / 255) * mul, (a / 255) * mul }
    end
end

local function PushColour(inst, r, g, b, a)
    if inst.components.colouradder ~= nil then
        inst.components.colouradder:PushColour("stunable", r, g, b, a)
    else
        inst.AnimState:SetAddColour(r, g, b, a)
    end
end

local function PopColour(inst)
    if inst.components.colouradder ~= nil then
        inst.components.colouradder:PopColour("stunable")
    else
        inst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

function Stunnable:UpdateTint()
    local color = self.color
    if self.inst.AnimState ~= nil then
        if self.isstunned then
            PushColour(self.inst, color[1], color[2], color[3], color[4])
        else
            PopColour(self.inst)
        end
    end
end

local function ClearStatusAilments(inst)
    if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
        inst.components.freezable:Unfreeze()
    end
    if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
        inst.components.pinnable:Unstick()
    end
end

local function ForceStopHeavyLifting(inst)
    if inst.components.inventory ~= nil and inst.components.inventory:IsHeavyLifting() then
        inst.components.inventory:DropItem(
            inst.components.inventory:Unequip(EQUIPSLOTS.BODY),
            true,
            true
        )
    end
end

function Stunnable:SetBearableStunDegree(degree, cannot_stun)
    if cannot_stun then
        self.stundegree_bearable = MAX_BEARABLE_STUNDEGREE
    else
        self.stundegree_bearable = degree
    end
end

function Stunnable:AddStunDegree(degree, isgod, awakable)
    if self.isstunned then
        return
    end
    self.stundegree = (self.stunnum or 0) + degree
    if self.stundegree >= self.stundegree_bearable and self.stundegree_bearable < MAX_BEARABLE_STUNDEGREE then
        self:Stun(6, isgod, awakable)
    end
end

function Stunnable:SetAwakable(awakable, percent)
    self.awakable = awakable
    self.awake_percent = percent or 0.2
end

local function AwakeTask(inst)
    local self = inst.components.hstunnable
    if self.old_health_percent - inst.components.health:GetPercent() >= self.awake_percent then
        self:UnStun()
        self.old_health_percent = nil
    end
end

function Stunnable:Stun(time, isgod, awakable)
    if self.stundegree ~= nil then
        self.stundegree = 0
    end

    awakable = awakable or self.awakable

    if self.inst:IsValid() then
        if self.unstun_task ~= nil then
            self.unstun_task:Cancel()
            self.unstun_task = nil
            time = time + (self.targettime - GetTime())
        end
        self.isstunned = true

        if self.onstunnedfn ~= nil then
            self.onstunnedfn(self.inst)
        end

        self:UpdateTint() -- 更新颜色显示

        -- 停止大脑的活动
        if self.inst.brain ~= nil then
            self.inst.brain:Stop()
        end

        -- 清除目标
        if self.inst.components.combat ~= nil then
            self.inst.components.combat:SetTarget(nil)
        end

        -- 停止移动
        if self.inst.components.locomotor ~= nil then
            self.inst.components.locomotor:Stop()
        end

        -- 停止动画
        if self.inst.AnimState ~= nil then
            self.inst.AnimState:Pause()
        end

        ClearStatusAilments(self.inst)  -- 清除角色的所有状态异常
        ForceStopHeavyLifting(self.inst)  -- 强制停止角色的重物搬运
        if self.inst.Physics ~= nil then
            self.inst.Physics:Stop()  -- 停止角色的物理运动
        end
        if self.inst.components.inventory ~= nil then
            self.inst.components.inventory:Hide() -- 隐藏角色的背包
        end
        self.inst:ClearBufferedAction()
        self.inst:PushEvent("ms_closepopups") -- 关闭所有弹出窗口
        if self.inst.components.playercontroller ~= nil then
            self.inst.components.playercontroller:EnableMapControls(false) -- 禁用地图控制
            self.inst.components.playercontroller:Enable(false) -- 禁用玩家控制
        end

        if isgod and self.inst.components.health then
            self.inst.components.health:SetInvincible(true) -- 设置玩家无敌
        end

        if awakable and self.inst.components.health ~= nil then
            self.old_health_percent = self.inst.components.health:GetPercent()
            self.inst:ListenForEvent("healthdelta", AwakeTask)
        end

        self:StartUnStun(time)
    end
end

function Stunnable:UnStun()
    if self.unstun_task ~= nil then
        self.unstun_task:Cancel()
        self.unstun_task = nil
    end

    if self.isstunned then
        self.isstunned = false

        self:UpdateTint() -- 更新颜色显示

        if self.inst:IsValid() then
            if self.inst.brain ~= nil then
                self.inst.brain:Start()
            end

            if self.inst.components.combat ~= nil then
                self.inst.components.combat:BlankOutAttacks(0.3)
            end

            if self.inst.AnimState ~= nil then
                self.inst.AnimState:Resume()
            end

            if self.inst.components.inventory ~= nil then
                self.inst.components.inventory:Show() -- 显示背包
            end

            if self.inst.components.playercontroller ~= nil then
                self.inst.components.playercontroller:EnableMapControls(true) -- 启用地图控制
                self.inst.components.playercontroller:Enable(true) -- 启用玩家控制
            end

            if self.inst.components.health then
                self.inst.components.health:SetInvincible(false) -- 取消无敌
            end
        end

        self.inst:RemoveEventCallback("healthdelta", AwakeTask)
    end
    self.unstun_task = nil
    self.targettime = nil
    self.old_health_percent = nil
end

function Stunnable:StartUnStun(time)
    if time == nil then
        time = 2
    end
    self.targettime = GetTime() + time
    self.unstun_task = self.inst:DoTaskInTime(time, function()
        self:UnStun()
    end)
end

function Stunnable:IsStunned()
    return self.isstunned
end

-- 保存状态
function Stunnable:OnSave()
    local data =
    {
        isstunned = self.isstunned,
        color = self.color,
        color_mult = self.color_mult,

        stundegree = self.stundegree,
        stundegree_bearable = self.stundegree_bearable,
        awakable = self.awakable,
        awake_percent = self.awake_percent,
        old_health_percent = self.old_health_percent,
    }
    if self.targettime ~= nil and self.targettime > GetTime() then
        data.timeleft = self.targettime - GetTime()
    end

    return next(data) ~= nil and data or nil
end

-- 加载状态
function Stunnable:OnLoad(data)
    self.isstunned = data.isstunned
    self.color = data.color
    self.color_mult = data.color_mult
    if data.timeleft ~= nil then
        self.targettime = GetTime() + data.timeleft
    end

    self.stundegree = data.stundegree
    self.stundegree_bearable = data.stundegree_bearable
    self.awakable = data.awakable
    self.awake_percent = data.awake_percent
    self.old_health_percent = data.old_health_percent

    if self.targettime ~= nil and self.targettime > GetTime() then
        self.inst:DoTaskInTime(FRAMES * 8, function()
            self:Stun(self.targettime - GetTime())
        end)
    end
end

return Stunnable