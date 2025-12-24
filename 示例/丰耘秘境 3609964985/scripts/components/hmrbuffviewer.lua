local BUFF_DATA_LIST = require("hmrmain/hmr_lists").BUFF_DATA_LIST

local function OnDebuffChanged(inst, data)
    inst.components.hmrbuffviewer:RefreshBuffData()
end

local function Init(inst)
    inst.components.hmrbuffviewer:RefreshBuffData()
end

local BuffViewer = Class(function(self, inst)
    self.inst = inst

    self.buff_data = {}

    self.last_refresh_time = nil

    self.inst:ListenForEvent("add_debuff", OnDebuffChanged)
    self.inst:ListenForEvent("remove_debuff", OnDebuffChanged)
    self.inst:DoTaskInTime(0, Init)
end)

function BuffViewer:GetTimeLeft(buff_name, buff_ent, data)
    if data ~= nil and data.gettimeleftfn ~= nil then
        return data.gettimeleftfn(self.inst, buff_ent, buff_name) or -1
    end

    if buff_ent.components.timer ~= nil then
        return buff_ent.components.timer:GetTimeLeft("buffover") or
            buff_ent.components.timer:GetTimeLeft("regenover") or -- 彩虹糖豆
            -1
    end

    if buff_ent.task ~= nil then
        return math.floor(GetTaskRemaining(buff_ent.task)) or -1
    end

    return -1
end

function BuffViewer:GetBuffName(buff_name, buff_ent, data)
    if data ~= nil and data.name ~= nil then
        if type(data.name) == "string" then
            return data.name
        elseif type(data.name) == "function" then
            return data.name(self.inst, buff_ent, buff_name)
        end
    end

    return buff_name
end

function BuffViewer:GetBuffIcon(buff_name, buff_ent, data)
    if data ~= nil and data.icon ~= nil then
        if type(data.icon) == "table" then
            if data.icon.tex == nil then
                return nil
            elseif data.icon.atlas == nil and GetInventoryItemAtlas ~= nil then
                return {atlas = GetInventoryItemAtlas(data.icon.tex), tex = data.icon.tex}
            else
                return data.icon
            end
        elseif type(data.icon) == "function" then
            return data.icon(self.inst, buff_ent, buff_name)
        end
    end
    -- return {atlas = "images/icons/".. buff_name..".xml", tex = buff_name}
end

function BuffViewer:RefreshBuffData()
    local debuffable = self.inst.components.debuffable
    if debuffable and debuffable.debuffs then
        self.buff_data = {}
        for buff_name, buff_data in pairs(debuffable.debuffs) do
            local buff_ent = buff_data.inst
            if buff_ent ~= nil then
                local data = BUFF_DATA_LIST[buff_name] or BUFF_DATA_LIST[buff_ent.prefab]

                local time_left = self:GetTimeLeft(buff_name, buff_ent, data)
                local name = self:GetBuffName(buff_name, buff_ent, data)
                local icon = self:GetBuffIcon(buff_name, buff_ent, data)

                if time_left >= 1 then
                    table.insert(self.buff_data, {
                        name = name,
                        icon = icon,
                        time_left = time_left,
                        -- start_time = GetTime(), -- 消除主客机发送数据时延(已弃用，现在消耗流量换取准确度)
                    })
                end
            end
        end
    end

    self.inst.replica.hmrbuffviewer:SetBuffData(self.buff_data)

    self.last_refresh_time = GetTime()
    if self.buff_data == nil or #self.buff_data == 0 then
        self.inst:StopUpdatingComponent(self)
    else
        self.inst:StartUpdatingComponent(self)
    end
end

function BuffViewer:GetBuffData()
    self:RefreshBuffData()
    return self.buff_data
end

function BuffViewer:OnUpdate()
    if self.last_refresh_time == nil or GetTime() - self.last_refresh_time >= 1 then
        self.last_refresh_time = GetTime()
        self:RefreshBuffData()
    end
end

return BuffViewer