local function IsOpen(inst)
    return inst._isopen ~= nil and inst._isopen:value()
end

local function Activate(inst, player) --player不存在也不会报错把
    if inst.components.activatable and inst.components.activatable:CanActivate(player) then
        inst.components.activatable:DoActivate(player)
    end
end

local function OnPlayerNear(inst, player)
    if not IsOpen(inst) then
        Activate(inst, player)
    end
end

local function OnPlayerFar(inst)
    if IsOpen(inst) then
        Activate(inst)
    end
end

-- 自动门，需要的时候就添加组件，不需要的时候移除组件
local AutoDoor = Class(function(self, inst)
    self.inst = inst
end)

function AutoDoor:SetEnable(enable)
    local inst = self.inst
    if enable then
        inst:AddTag("aab_auto_door")

        inst:AddComponent("aab_playerprox")
        inst.components.aab_playerprox:SetDist(2, 2)
        inst.components.aab_playerprox:SetOnPlayerNear(OnPlayerNear)
        inst.components.aab_playerprox:SetOnPlayerFar(OnPlayerFar)
    else
        inst:RemoveTag("aab_auto_door")

        inst:RemoveComponent("aab_playerprox")
    end
end

function AutoDoor:OnRemoveFromEntity()
    self:SetEnable(false)
end

function AutoDoor:OnSave()
    return {
        enable = self.inst:HasTag("aab_auto_door")
    }
end

function AutoDoor:OnLoad(data)
    if data and data.enable then
        self:SetEnable(true)
    end
end

return AutoDoor
