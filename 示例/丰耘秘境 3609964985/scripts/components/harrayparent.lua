-- 监听成员数量变化
local function OnMemberNumChanged(self, membernum)
    if self.onmembernum ~= nil then
        self.onmembernum(self.inst, membernum, self.old_current_member_num)
    end
    self.old_current_member_num = self.current_member_num
end

local HArrayParent = Class(function(self, inst)
    self.inst = inst
    self.mode = "hmr_chest_store_array"
    self.breakpack = nil
    self.degradepack = nil
    self.max_member_num = 12
    self.min_member_num = 9
    self.current_member_num = 0
    self.old_current_member_num = self.current_member_num

    self.member = {}

    self.openlist = {}  -- self.openlist[doer] = member,写在harray中

    self.skip_infos = {}
end, nil, {
    current_member_num = OnMemberNumChanged
})

-- 设置模式
function HArrayParent:SetMode(mode)
    self.mode = mode
end

-- 设置最小成员数量
function HArrayParent:SetMinMemberNum(min)
    self.min_member_num = min
end

-- 设置最大成员数量
function HArrayParent:SetMaxMemberNum(max)
    self.max_member_num = max
end

-- 设置更改布局信息
function HArrayParent:SetSkipInfos(infos)
    self.skip_infos = infos
end

function HArrayParent:SetOnMemberNumChanged(fn)
    self.onmembernum = fn
end

-- 判断是否已满员
function HArrayParent:IsFull()
    return #self.member >= self.max_member_num
end

-- 获取当前成员数量
function HArrayParent:GetCurrentMemberNum()
    return self.member and #self.member or 0
end

-- 增加成员(具体操作写在harray)
function HArrayParent:AddMember(member)
    if member == nil or table.contains(self.member, member) then
        return
    end
    member.components.container:Close()
    table.insert(self.member, member)
    self.current_member_num = self:GetCurrentMemberNum()
end

-- 设置阵列解散后掉落的包裹
function HArrayParent:SetBreakPack(pack)
    self.breakpack = pack
end

-- 设置阵列降级后掉落的包裹
function HArrayParent:SetDeGradePack(pack)
    self.degradepack = pack
end

-- 移除成员(具体操作写在harray)
function HArrayParent:RemoveMember(ent)
    for num, member in ipairs(self.member) do
        if member == ent then
            table.remove(self.member, num)
            break
        end
    end

    --如果当前成员不足，则解散，删除阵列父体
    self.current_member_num = self:GetCurrentMemberNum()
    if self.current_member_num < self.min_member_num then
        local items = self.inst.components.container:GetAllItems()
        -- 优先放到箱子中
        for _, mem  in pairs(self.member) do
            if mem:IsValid() then
                while not mem.components.container:IsFull() and items ~= nil and #items > 0 do
                    mem.components.container:GiveItem(items[1])
                    table.remove(items, 1)
                end

                mem.components.container_proxy:SetMaster(nil)
                mem.components.entitytracker:ForgetEntity("arrayparent")
                mem.components.container.canbeopened = true
                mem.components.harray.array = nil
            end
        end

        -- 箱子放满后放到临时包裹中，包裹一天后消失
        if self.breakpack ~= nil and items ~= nil and #items > 0 then
            local pack = SpawnPrefab(self.breakpack)
            for _, item in pairs(items) do
                pack.components.container:GiveItem(item)
            end

            pack.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
            local speed = math.random() * 2 + 2
            local angle = math.random() * 2 * math.pi
            pack.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 4, speed * math.sin(angle))
        end

        self.inst:Remove()
    end
end

function HArrayParent:GetArrayPosition()
    local x, y, z
    for _, member in pairs(self.member) do
        if member and member:IsValid() then
            local mx, my, mz = member.Transform:GetWorldPosition()
            if mx ~= nil and my ~= nil and mz ~= nil then
                if x ~= nil and y ~= nil and z ~= nil then
                    x = (x + mx) / 2
                    y = (y + my) / 2
                    z = (z + mz) / 2
                else
                    x, y, z = mx, my, mz
                end
            end
        end
    end
    return Vector3(x, y, z)
end

function HArrayParent:Open(doer)
    for _, member in pairs(self.member) do
        member.components.container.openlist[doer] = true
        member.components.container.opencount = member.components.container.opencount + 1
    end

    self.inst.components.container:Open(doer)
end

function HArrayParent:Close(doer)
    for _, member in pairs(self.member) do
        member.components.container.openlist[doer] = nil
        member.components.container.opencount = member.components.container.opencount - 1
    end

    self.inst.components.container:Close(doer)
end

return HArrayParent