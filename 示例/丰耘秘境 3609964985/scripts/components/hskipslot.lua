local HSkipSlot = Class(function(self, inst)
    self.inst = inst
    self.skiplist = nil
end)

function HSkipSlot:SetNormalSkipSlots(from, skipnum, totalslotnum, change)
    if self.skiplist ~= nil and not change then
        return
    end

    -- 客户端设置跳过列表
    self.inst.replica.hskipslot:UpdateNormalSkipSlots(from, skipnum, totalslotnum)

    -- 服务器设置跳过列表
    local skiplist = {}
    if from == "beginning" then
        for i = 1, skipnum do
            table.insert(skiplist, i)
        end
    else
        for i = 1, skipnum do
            table.insert(skiplist, totalslotnum - i + 1)
        end
    end
    self.skiplist = skiplist
end

function HSkipSlot:SetRandomSkipSlots(totalslotnum, targetslotnum, change)
    if self.skiplist ~= nil and not change then
        self.inst.replica.hskipslot:CreateRandomSkipSlots(self.skiplist)
        return
    end

    -- 服务器设置跳过列表
    local skiplist = {}
    for i = 1, totalslotnum do
        table.insert(skiplist, i)
    end
    for i = 1, targetslotnum do
        local index = math.random(1, #skiplist)
        table.remove(skiplist, skiplist[index])
    end
    self.skiplist = skiplist

    -- 客户端设置跳过列表
    self.inst.replica.hskipslot:CreateRandomSkipSlots(skiplist)
end

-- 获取跳过列表
function HSkipSlot:GetSkipList()
    return self.skiplist
end

-- 保存状态
function HSkipSlot:OnSave()
    local data =
    {
        skiplist = self.skiplist,
    }

    return next(data) ~= nil and data or nil
end

-- 加载状态
function HSkipSlot:OnLoad(data)
    self.skiplist = data.skiplist
end

return HSkipSlot