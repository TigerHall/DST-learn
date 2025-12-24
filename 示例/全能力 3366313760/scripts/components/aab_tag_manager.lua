--- 标签管理器，只负责下线时保存标签
local TagManager = Class(function(self, inst)
    self.inst = inst

    self.tags = {}
end)

function TagManager:RegisterTag(tag, fn, deplay_invoke)
    self.tags[tag] = self.tags[tag] or {}
    if fn then
        table.insert(self.tags[tag], { fn = fn, deplay_invoke = deplay_invoke })
    end
end

function TagManager:OnSave()
    local tags = {}
    for k, _ in pairs(self.tags) do
        if self.inst:HasTag(k) then
            table.insert(tags, k)
        end
    end
    return {
        tags = tags
    }
end

local function InvokeFn(inst, self, tag, deplay)
    for _, d in ipairs(self.tags[tag]) do
        if d.fn and d.deplay_invoke == deplay then
            d.fn(self.inst)
        end
    end

    if not deplay then
        inst:DoTaskInTime(0, InvokeFn, self, tag, true)
    end
end

function TagManager:OnLoad(data)
    if not data then return end

    if data.tags then
        for _, v in ipairs(data.tags) do
            if self.tags[v] then
                self.inst:AddTag(v)
                InvokeFn(self.inst, self, v)
            end
        end
    end
end

return TagManager
