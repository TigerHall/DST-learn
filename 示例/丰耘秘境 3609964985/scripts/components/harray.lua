local HArray = Class(function(self, inst)
    self.inst = inst

    self.mode = "hmr_chest_store"
    self.radius = TUNING.HMR_CHEST_STORE_ARRAY_DIST
    self.min_member_num = 9
    self.max_member_num = 12
    self.change_widget = true
    -- self.array = nil
end)

-- 设置阵列半径
function HArray:SetRadius(radius)
    self.radius = radius
end

-- 设置阵列模式
function HArray:SetMode(mode)
    self.mode = mode
end

-- 设置最小成员数
function HArray:SetMinMemberNum(num)
    self.min_member_num = num
end

-- 设置最大成员数
function HArray:SetMaxMemberNum(num)
    self.max_member_num = num
end

-- 设置加入阵列后是否改变容器界面
function HArray:SetChangeWidget(change)
    self.change_widget = change
end

-- 设置进入阵列后禁用燃烧
function HArray:SetDisableBurningInArray(disable)
    self.burninarray = disable
end

-- 获取是否变换容器界面
function HArray:GetChangeWidget()
    return self.change_widget
end

-- 获取当前成员数
function HArray:GetCurrentMemberNum()
    if self:IsInArray() then
        local array = self.inst.entity:GetParent()
        if array and array.components.harrayparent then
            return array.components.harrayparent:GetCurrentMemberNum()
        end
    end
    return 0
end

-- 是否已组成阵列
function HArray:IsInArray()
    return self.array ~= nil
end

-- 获取阵列
function HArray:GetArray()
    return self.array
end

-- 尝试加入附近阵列
function HArray:TryToAddToArray(tag, times)
    if self:IsInArray() then
        return false
    end

    if not tag or not type(tag) == "string" then
        tag = self.mode
    end

    local x, y, z = self.inst.Transform:GetWorldPosition()
    local store_chests = TheSim:FindEntities(x, y, z, TUNING.HMR_CHEST_STORE_ARRAY_DIST, {tag}, {"burnt"})

    if not store_chests then
        return false
    end

    local not_in_array = {}
    local arrays = {}
    for _, chest in pairs(store_chests) do
        if chest:HasTag(tag.."_array") then
            table.insert(arrays, chest)
        else
            table.insert(not_in_array, chest)
        end
    end

    local max_array = nil
    local max_array_num = 0
    -- 找到成员最多的阵列
    if arrays then
        if #arrays > 1 then
            for _, array in pairs(arrays) do
                if not array.components.harrayparent:IsFull() then
                    if array.components.harrayparent:GetCurrentMemberNum() > max_array_num then
                        max_array_num = array.components.harrayparent:GetCurrentMemberNum()
                        max_array = array
                    end
                end
            end
        else
            max_array = arrays[1]
        end
    end

    if max_array then
        -- 加入到最大阵列
        self.inst.components.harray:AddToArray(max_array)
        return true
    elseif not_in_array and #not_in_array >= self.min_member_num then
        -- 创没有符合条件的阵列，尝试建新阵列
        local new_array = self:CreatArray(not_in_array, self.mode, self.min_member_num, self.max_member_num)
        if new_array then
            for _, chest in ipairs(not_in_array) do
                chest.components.harray:AddToArray(new_array)
            end
            return true
        end
    end

    -- 到这里就代表着之前加入尝试都失败了，令其他箱子尝试加入
    if times == nil then
        times = 0
    end
    for _, chest in pairs(not_in_array) do
        if times < 1 then
            chest.components.harray:TryToAddToArray(tag, times + 1)
        end
    end
    return false
end

function HArray:CreatArray(members, mode, min_member_num, max_member_num)
    mode = mode.."_array"
    local array = SpawnPrefab(mode)
    if not array then
        return nil
    end

    array.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
    array.components.harrayparent:SetMinMemberNum(min_member_num or self.min_member_num)
    array.components.harrayparent:SetMaxMemberNum(max_member_num or self.max_member_num)
    array.components.harrayparent:SetMode(mode)

    return array
end

-- 加入阵列(传入的是要加入的阵列代理)
function HArray:AddToArray(array)
    if array == nil or array.components.harrayparent == nil or array.components.harrayparent:IsFull() then
        return
    end

    self.array = array

    self.inst:AddTag("hmr_inarray")

    -- 初始化容器内物品
    local items = self.inst.components.container:RemoveAllItems()
    if items then
        for _, item in ipairs(items) do
            if item and item:IsValid() then
                array.components.container:GiveItem(item)
            end
        end
    end
    self.inst.components.container.canbeopened = false

    -- 禁用燃烧
    if self.burninarray and self.inst.components.burnable then
        self.inst:RemoveComponent("burnable")
    end

    self.inst.components.container_proxy:SetMaster(array)
    self.inst.components.entitytracker:TrackEntity("arrayparent", array)
    array.components.harrayparent:AddMember(self.inst)
end

-- 退出阵列(箱子单独退出阵列时不会分得阵列容器物品，当阵列解散后才会分给箱子物品)
function HArray:RemoveFromArray()
    self.inst.components.container.canbeopened = true
    if self.array == nil then
        return
    end
    if self.array and self.array.components.harrayparent then
        -- 删除阵列父体的代码在harrayparent中
        self.array.components.harrayparent:RemoveMember(self.inst)
    end

    self.inst.components.container_proxy:SetMaster(nil)
    self.inst.components.entitytracker:ForgetEntity("arrayparent")
    self.array = nil
    self.inst:RemoveTag("hmr_inarray")
end

function HArray:OnSave()
    return {
        canbeopened = self.inst.components.container.canbeopened
    }
end

function HArray:OnLoad(data)
    if data.canbeopened ~= nil then
        self.inst.components.container.canbeopened = data.canbeopened
    end
end

function HArray:LoadPostPass()
    if self.inst.components.entitytracker ~= nil then
        local array = self.inst.components.entitytracker:GetEntity("arrayparent")
        if array ~= nil and array.components.harrayparent then
            array.components.harrayparent:AddMember(self.inst)
            self.inst.components.container_proxy:SetMaster(array)
        end
    end
end

return HArray