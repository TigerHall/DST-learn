local boxkeys = {
    "cloudpine_l1", "cloudpine_l2", "cloudpine_l3", "cloudpine_l4"
}

local BoxCloudPine = Class(function(self, inst)
    self.inst = inst

    self.lvl = 0
    self.ents = {}
    self.openers = {}
    self.boxkey = nil
    self.boxkeyidx = nil
end)

function BoxCloudPine:CanBeOpened()
    return self.boxkey ~= nil
end

function BoxCloudPine:SetMaster(target)
    if self.boxkey == nil then
        if target.components.container_proxy:CanBeOpened() then
            target.components.container_proxy:SetCanBeOpened(false)
        end
	    target.components.container_proxy:SetMaster(nil)
    else
        target.components.container_proxy:SetMaster(self.inst:GetPocketDimensionContainer(self.boxkey))
        if not target.components.container_proxy:CanBeOpened() then
            target.components.container_proxy:SetCanBeOpened(true)
        end
    end
    self.openers[target] = true
end

function BoxCloudPine:ManageEnt(ent, isadd, value)
    if isadd then
        if value ~= nil then
            self.ents[ent] = value
        else
            self.ents[ent] = ent.components.perennialcrop2 and ent.components.perennialcrop2.cluster or 0
        end
    else
        self.ents[ent] = nil
    end
end

function BoxCloudPine:UpdateBox(doer)
    local noent = true
    local dropper
    local lvl = 0
    for ent, lv in pairs(self.ents) do
        if ent:IsValid() then
            if lv > lvl then
                lvl = lv
                dropper = ent
            elseif dropper == nil then
                dropper = ent
            end
            noent = false
        else
            self.ents[ent] = nil
        end
    end
    self.lvl = lvl
    if doer and doer:IsValid() then
        dropper = doer
    end

    local oldbox = self.boxkey
    if noent then
        self.boxkey = nil
        self.boxkeyidx = nil
    elseif lvl >= 80 then
        self.boxkey = boxkeys[4]
        self.boxkeyidx = 4
    elseif lvl >= 60 then
        self.boxkey = boxkeys[3]
        self.boxkeyidx = 3
    elseif lvl >= 30 then
        self.boxkey = boxkeys[2]
        self.boxkeyidx = 2
    else
        self.boxkey = boxkeys[1]
        self.boxkeyidx = 1
    end
    if oldbox ~= self.boxkey then
        --关闭所有正在打开的世界容器
        for _, name in ipairs(boxkeys) do
            local box = self.inst:GetPocketDimensionContainer(name)
            if box ~= nil then
                box.components.container:Close()
            end
        end

        --重新设置开启器
        local openers = self.openers
        self.openers = {}
        for ent, _ in pairs(openers) do
            if ent:IsValid() and ent.components.container_proxy ~= nil then
                self:SetMaster(ent)
            end
        end

        if oldbox == boxkeys[4] then --将已有时间加上去
            local box = self.inst:GetPocketDimensionContainer(boxkeys[4])
            if box ~= nil and box.SwordRecovery_l ~= nil then
                box.SwordRecovery_l(box, doer)
            end
        elseif self.boxkey == boxkeys[4] then --初始化时间
            local box = self.inst:GetPocketDimensionContainer(boxkeys[4])
            if box ~= nil and box.SwordRecovery_l ~= nil then
                box.healtime_l = GetTime()
            end
        end

        --物品装不下时的掉落坐标
        local x, y, z
        if dropper == nil then
            for _, v in pairs(AllPlayers) do
                x, y, z = v.Transform:GetWorldPosition()
                break
            end
        else
            x, y, z = dropper.Transform:GetWorldPosition()
        end
        if x == nil or z == nil or (x == 0 and z == 0) then --坐标原点就不掉落了，免得落海里
            return
        end

        --把旧容器的物品拿出来放到新容器里
        if self.boxkey == nil then
            for _, name in ipairs(boxkeys) do
                local box = self.inst:GetPocketDimensionContainer(name)
                if box ~= nil then
                    local items = box.components.container:RemoveAllItems()
                    for _, item in pairs(items) do
                        item.Transform:SetPosition(x, y, z)
                        if item.components.inventoryitem ~= nil then
                            item.components.inventoryitem:OnDropped(true)
                        end
                    end
                end
            end
        else
            local newbox = self.inst:GetPocketDimensionContainer(self.boxkey)
            if newbox ~= nil then
                local newboxcpt = newbox.components.container
                for _, name in ipairs(boxkeys) do
                    if name ~= self.boxkey then
                        local box = self.inst:GetPocketDimensionContainer(name)
                        if box ~= nil then
                            local items = box.components.container:RemoveAllItems()
                            for _, item in pairs(items) do
                                if not newboxcpt:GiveItem(item, nil, nil, false) then
                                    item.Transform:SetPosition(x, y, z)
                                    if item.components.inventoryitem ~= nil then
                                        item.components.inventoryitem:OnDropped(true)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

--Tip：对于组件，必需 OnSave 有非空表的数据返回，才能使得世界启动时对应组件的 OnLoad() 和 LoadPostPass() 能被执行
function BoxCloudPine:OnSave()
    -- local data
    -- if self.boxkeyidx ~= nil then
    --     data = { idx = self.boxkeyidx }
    -- end
    -- return data
    return { idx = 4 }
end
-- function BoxCloudPine:OnLoad(data, newents)
--     if data == nil then
--         return
--     end
--     if data.idx ~= nil and boxkeys[data.idx] ~= nil then
--         self.boxkeyidx = data.idx
--         self.boxkey = boxkeys[data.idx]
--     end
-- end
function BoxCloudPine:LoadPostPass(newents, data)
    self:UpdateBox()
end

return BoxCloudPine
