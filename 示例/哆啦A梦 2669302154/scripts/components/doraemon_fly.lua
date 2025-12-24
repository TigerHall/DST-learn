--------------------------------
--[[ 飞行组件]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-10]]
--[[ @updateTime: 2021-12-10]]
--[[ @email: x7430657@163.com]]
--------------------------------

require("constants")
require("util/logger")
-- 飞行参数
local flyConfig = {
    runspeed = TUNING.DORAEMON_TECH.DORAEMON_FLY_SPEED,
    hungerrate_modifier = TUNING.DORAEMON_TECH.DORAEMON_FLY_HUNGER_MODIFIER,--饥饿速率(额外倍数)
    height =  TUNING.DORAEMON_TECH.DORAEMON_FLY_HEIGHT
}


local function FlyActionFilter(inst, action)
    -- 飞行过程只能做 着落 动作
    return  action.id == "DORAEMON_FLY_LAND"
end


-- 删除碰撞
local function changephysics(inst, data)
    if inst.Physics then
        if inst.Physics:GetCollisionMask() ~= COLLISION.GROUND then
            RemovePhysicsColliders(inst)--碰撞
        end
    end
end

--------------------================================================
local Flyer = Class(function(self, inst)
    self.inst = inst
    self.runspeed = flyConfig.runspeed
    -- 速度因子,用来更改移动速度
    self.externalspeedmultiplier = net_float(inst.GUID, "doraemon_fly.externalspeedmultiplier")
    self.externalspeedmultiplier:set(1)
    self.height = flyConfig.height
    --标识当前状态是否飞行中
    self._isflying = net_bool(inst.GUID, "doraemon_fly._isflying", "doraemon_fly._isflyingdirty")
    self._isflying:set(false)
    --百分比,主要用于上升和下降,不管更改玩家的高度直至0或1
    self._percent = net_float(inst.GUID, "doraemon_fly._percent")
    self._percent:set(0)
    inst:ListenForEvent("doraemon_fly._isflyingdirty", function()
        if not TheWorld.ismastersim then
            local p = self._isflying:value()
            self:SetFlying(p, TheSim:GetTick() <= 1+4) -- 5帧内的起飞视为读档
        end
    end)
end)


function Flyer:GetPercent()
    return self._percent:value()
end

function Flyer:GetRunSpeed()
    return self.runspeed * self:GetSpeedMultiplier()
end

function Flyer:GetSpeedMultiplier()
    return self.externalspeedmultiplier:value()
end


function Flyer:GetHeight()
    return self.height
end

function Flyer:UpdateHeight() -- 更新玩家高度,主要用于升空和降落,行走
    local height = self:GetFlyTargetHeight()
    local a,b,c = self.inst.Physics:GetMotorVel()
    local y = self.inst:GetPosition().y
    -- 目标高度 - 人物目标高度
    self.inst.Physics:SetMotorVel(a, (height - y) * COLLISION.GROUND , c)
end

function Flyer:putOnGround() -- 更新玩家高度,主要用于升空和降落,行走
    local pos = self.inst:GetPosition()
    self.inst.Transform:SetPosition(pos.x,0,pos.z)
end


function Flyer:OnUpdate(dt) -- 主客机通用 ,用于更新站立不动的情况
    if self:IsFlying()
            and self.inst.components.locomotor -- 客机需要存在延迟补偿
            and not self.inst.components.locomotor.wantstomoveforward --不想移动
    then
        Logger:Debug("Flyer:OnUpdate")
        self:UpdateHeight()
    end
end

local function Empty()
end



function Flyer:SetFlying(val, force,inventoryOpen) -- 主客机: 芜湖, 起飞
    local inst = self.inst
    if TheWorld.ismastersim then
        if force then
            if val then
                self._percent:set(1)
            else
                self._percent:set(0)
            end
        end
        self._isflying:set(val)--只能主机使用这个函数,会同时更新客户端,客户端同样会调用此方法
    else
        if force then
            if val then
                self._percent:set_local(1)
            else
                self._percent:set_local(0)
            end
        end
        self._isflying:set_local(val)--这个函数只更新主机或客户端
    end
    -- 获取竹蜻蜓
    local bamboo_dragonfly = nil
    for _,tempItem in pairs(self.inst.replica.inventory:GetEquips()) do
        if tempItem ~= nil and tempItem.prefab == "bamboo_dragonfly"then
            bamboo_dragonfly = tempItem
        end
    end
    if val then -- 飞行
        self.inst:StartUpdatingComponent(self)--每一个tick更新一次
        if self.inst.Physics then
            RemovePhysicsColliders(self.inst)
        end
        self.inst:AddTag(TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_TAG) -- 飞行中禁止被蠕虫探知并攻击
        --声音
        if bamboo_dragonfly ~= nil then
            bamboo_dragonfly:PushEvent("takeEffect",{enable = true ,sound =true})
        end
        self.inst.DynamicShadow:Enable(false) -- 影子禁用
        if  self.inst.components.playerlightningtarget then -- 雷击
            self.old_lightning_hit_chance = self.inst.components.playerlightningtarget:GetHitChance()
            self.inst.components.playerlightningtarget:SetHitChance(TUNING.WX78_LIGHTNING_TARGET_CHANCE)
        end
        -- 禁止攻击
        if self.inst.components.combat then
            self.blankoutattacks_task = self.inst:DoPeriodicTask(10,function(inst) inst.components.combat:BlankOutAttacks(10) end,0)
        end
        -- 饱食度加速消耗
        if self.inst.components.hunger and flyConfig.hungerrate_modifier ~= nil then
            inst.components.hunger.burnratemodifiers:SetModifier("doraemon_fly", flyConfig.hungerrate_modifier)
        end
        if self.inst.components.inventory then
            if self.inst.components.inventory:IsHeavyLifting() then
                self.inst.components.inventory:DropItem(
                        self.inst.components.inventory:Unequip(EQUIPSLOTS.BODY),
                        true,
                        true
                )
            end
            self.inst.components.inventory:Close(true)
        end
        if self.inst.components.playercontroller ~= nil then
            self.inst.components.playercontroller.actionbuttonoverride = Empty
        end
        if self.inst.components.catcher ~= nil then
            self.inst.components.catcher:SetEnabled(false)
        end
        if self.inst.components.playeractionpicker ~= nil then
            self.inst.components.playeractionpicker:PopActionFilter(FlyActionFilter)
            self.inst.components.playeractionpicker:PushActionFilter(FlyActionFilter, 555)
        end
        -- 监听状态,以保证替换
        self.inst:ListenForEvent("newstate", changephysics)
        if self.inst.components.locomotor then
            self.inst.components.locomotor.pathcaps = { player = true, ignorecreep = true ,allowocean = true}
            self.inst.components.locomotor.fasteronroad = false
            self.old_triggerscreep = self.inst.components.locomotor.triggerscreep
            if self.old_triggerscreep ~= nil then
                self.inst.components.locomotor:SetTriggersCreep(false)
            end
            self.inst.components.locomotor:SetAllowPlatformHopping(false)--平台跳跃
        end
        if self.inst.components.drownable then
            self.inst.components.drownable.enabled = false
        end
    else
        self.inst:StopUpdatingComponent(self)
        if force then -- 强制放在地面
            self:putOnGround()
        end
        self.inst:RemoveTag(TUNING.DORAEMON_TECH.BAMBOO_DRAGONFLY_TAG)
        self.inst.DynamicShadow:Enable(true) -- 影子
        if self.old_lightning_hit_chance and self.inst.components.playerlightningtarget then -- 雷击
            self.inst.components.playerlightningtarget:SetHitChance(self.old_lightning_hit_chance)
        end
        --声音
        if bamboo_dragonfly ~= nil then
            bamboo_dragonfly:PushEvent("takeEffect",{enable = false ,sound = true})
            -- 降落后给与冷却
            if bamboo_dragonfly.components.rechargeable then
                bamboo_dragonfly.components.rechargeable:Discharge(TUNING.DORAEMON_TECH.DORAEMON_FLY_COOLDOWN)
            end
        end
        if self.blankoutattacks_task then
            self.blankoutattacks_task:Cancel()--取消定时禁止攻击
            self.inst.components.combat:BlankOutAttacks(0)--可以攻击
        end
        -- 还原饱食度加速消耗率
        if self.inst.components.hunger then
            inst.components.hunger.burnratemodifiers:RemoveModifier("doraemon_fly")
        end
        if inventoryOpen then
            if self.inst.components.inventory and not self.inst.components.health:IsDead() then
                self.inst.components.inventory:Open()
            end
        end
        if self.inst.components.playercontroller ~= nil then
            self.inst.components.playercontroller.actionbuttonoverride = nil
        end
        if self.inst.components.catcher ~= nil then
            self.inst.components.catcher:SetEnabled(true)
        end
        if self.inst.components.playeractionpicker ~= nil then
            self.inst.components.playeractionpicker:PopActionFilter(FlyActionFilter)
        end
        self.inst:RemoveEventCallback("newstate", changephysics)
        --返回人物自身高度
        if self.inst.Physics then
            ChangeToCharacterPhysics(self.inst)
        end
        if self.inst.components.locomotor then
            self.inst.components.locomotor.pathcaps = { player = true, ignorecreep = true }
            self.inst.components.locomotor.fasteronroad = true
            --可被催眠
            if self.old_triggerscreep ~= nil then
                self.inst.components.locomotor:SetTriggersCreep(self.old_triggerscreep)
            end
            -- 平台跳跃 应该跳船
            self.inst.components.locomotor:SetAllowPlatformHopping(true)
        end
        if self.inst.components.drownable then
            self.inst.components.drownable.enabled = true
        end
    end
end

function Flyer:IsFlying()
    return self._isflying:value()
end

-- 是否飞行，包括其他mod
-- 判断依据是否不存在冲突，
function Flyer:IsFlyingBesidesOtherMod()
    return self.inst.Physics:GetCollisionMask() == COLLISION.GROUND
end



function Flyer:GetFlyTargetHeight() -- 主客机通用: 获取飞行高度
    return flyConfig.height * self:GetPercent()
end


function Flyer:OnRemoveEntity()

end
--退出时保存当前状态
function Flyer:OnSave()
    return {isflying = self:IsFlying()}
end
--加载时,恢复状态
function Flyer:OnLoad(data)
    if data.isflying then
        self:SetFlying(true, true)
    end
end
Flyer.OnRemoveFromEntity = Flyer.OnRemoveEntity
return Flyer