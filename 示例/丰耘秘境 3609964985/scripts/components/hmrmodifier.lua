local function OnComponentAdded(inst, data)
    local self = inst.components.hmrmodifier
    if self ~= nil then
        if self:IsModified(data.name) then
            for key, value in pairs(self.modified_data[data.name]) do
                self:UpdateComponentData(data.name, key, value.value)
            end
        end
    end
end

local Modifier = Class(function(self, inst)
    self.inst = inst

    self.modified_data = {}
    self.inst:ListenForEvent("componentadded", OnComponentAdded)
end)

function Modifier:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("componentadded", OnComponentAdded)
end

--[[
-- 雷子的tool组件用用用表当键值呜呜呜
tool组件： -- 每次传一个需要修改的
    key = ACTIONS.id        -- 大写字符串
    value = effectiveness   -- 效率
]]
function Modifier:UpdateComponentData(component, key, value)
    if self.inst.components[component] == nil then
        return
    end

    if component == "tool" then
        local actions = self.inst.components.tool.actions
        actions[ACTIONS[string.upper(key)]] = value
    else
        self.inst.components[component][key] = self.modified_data[component][key].value
    end
end

function Modifier:AddModify(component, key, value)
    if self.inst.components[component] == nil then
        return
    end

    if not self:HasOriginalValue(component, key) then
        self:SetOriginalValue(component, key, value, true)
    else
        self.modified_data[component][key].value = value
    end

    self:UpdateComponentData(component, key, value)
end

function Modifier:RemoveModify(component, key)
    if self.modified_data[component] and self.modified_data[component][key] then
        self.inst.components[component][key] = self.modified_data[component][key].original_value
        self.modified_data[component][key] = nil
        if next(self.modified_data[component]) == nil then
            self.modified_data[component] = nil
        end
    end
end

function Modifier:HasOriginalValue(component, key)
    return self.modified_data[component] and self.modified_data[component][key] and self.modified_data[component][key].original_value ~= nil
end

function Modifier:SetOriginalValue(component, key, value, apply)
    if self:HasOriginalValue(component, key) then
        return
    end

    if self.inst.components[component] == nil then
        self.inst:AddComponent(component)
    end
    if self.modified_data[component] == nil then
        self.modified_data[component] = {}
    end
    self.modified_data[component][key] = {}
    if value ~= nil then
        if apply then
            self.inst.components[component][key] = value
        end
        self.modified_data[component][key].original_value = value
        self.modified_data[component][key].value = value
    else
        self.modified_data[component][key].original_value = self.inst.components[component][key]
        self.modified_data[component][key].value = self.inst.components[component][key]
    end
end

function Modifier:GetOriginalValue(component, key)
    local save_value = self.modified_data[component] and
        self.modified_data[component][key] and
        self.modified_data[component][key].original_value
    if save_value ~= nil then
        return save_value
    end

    local value = self.inst.components[component] and self.inst.components[component][key]
    return value
end

function Modifier:IsModified(component, key)
    return self.modified_data[component] and
        (key == nil or self.modified_data[component][key] and self.modified_data[component][key].value ~= self.modified_data[component][key].original_value)
end

function Modifier:OnSave()
    return {
        modified_data = self.modified_data
    }
end

function Modifier:OnLoad(data)
    if data ~= nil and data.modified_data ~= nil then
        self.modified_data = data.modified_data -- 必须立刻保存，等DoTaskInTime的话data就被清空了
        self.inst:DoTaskInTime(0, function()
            for component, keys in pairs(self.modified_data) do
                for key, value in pairs(keys) do
                    self:SetOriginalValue(component, key, value.original_value, false)
                    self:UpdateComponentData(component, key, value.value)
                end
            end
        end)
    end
end

return Modifier