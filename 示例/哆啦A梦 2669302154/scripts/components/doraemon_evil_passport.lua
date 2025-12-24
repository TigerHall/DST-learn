--------------------------------
--[[ 恶魔护照组件]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-21]]
--[[ @updateTime: 2021-12-21]]
--[[ @email: x7430657@163.com]]
--------------------------------
-- myth-hero\scripts\components\white_bone_fog.lua:16
-- myth-hero\main\white_bone.lua:457
local EvilPassport = Class(function(self, inst)
    --self._status = net_bool(inst.GUID, "doraemon_evil_passport._status", "doraemon_evil_passport._statusdirty")
    --self._status:set(false)
    self.inst = inst
    self._status = false
    self.items = {}
end)
function EvilPassport:GetStatus()
    --return self._status:value()
    return self._status
end

function EvilPassport:RemoveItem(item)
    if item then
        self.items[item] = nil
        item.evilPassPortNear = nil
    end
end

function EvilPassport:RemoveAllItem()
    for k,v in pairs(self.items) do
        self:RemoveItem(k)
    end
end

function EvilPassport:OnUpdate(dt) -- 主客机通用 ,用于更新站立不动的情况
    if self:GetStatus() then
        local inst = self.inst
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z,32, { "_combat","_health" }, {"INLIMBO","epic"})
        local currentItems = {} -- 当前生效的item
        for _ , v in ipairs(ents) do
            -- 未保存到当前item 且不是玩家,则设置周围存在恶魔护照
            if v and not currentItems[v] and not v:HasTag("player") then
                v.evilPassPortNear = true
                if self.items[v] == nil then
                    self.items[v] = true
                end
                currentItems[v] = true
                if v.components.combat and v.components.combat.target ~= nil
                    and inst:IsValid() and inst._owner ~= nil
                    and v.components.combat.target == inst._owner -- 攻击的是持有者
                    and not (v.components.health ~= nil and v.components.health:IsDead())
                then
                    if v.hit_evil_passport_time ~= nil then
                        v.hit_evil_passport_time = v.hit_evil_passport_time + dt
                    else
                        v.hit_evil_passport_time = dt
                    end
                end
            end
        end
        for k,v in pairs(self.items) do -- 清除无用的item ,清除攻击目标(以实现带上恶魔护照后,之前已吸引仇恨的目标丢失仇恨(不会立刻,会有一定时间))
            if currentItems[k] == nil then
                k.hit_evil_passport_time = nil
                self:RemoveItem(k)
            elseif k.hit_evil_passport_time ~= nil then
                if k.hit_evil_passport_time >= math.random(6,10)
                    and k.components.combat and k.components.combat.target ~= nil
                    and inst:IsValid() and inst._owner ~= nil
                    and k.components.combat.target == inst._owner -- 攻击的是持有者
                then
                    k.hit_evil_passport_time = nil
                    k.components.combat:DropTarget()
                end
            end
        end
    end
end

function EvilPassport:SetStatus(status)
    local inst = self.inst
    --self._status:set(status)
    self._status = status
    if status then
        self.inst:StartUpdatingComponent(self)
    else
        self.inst:StopUpdatingComponent(self)
    end
end
return EvilPassport