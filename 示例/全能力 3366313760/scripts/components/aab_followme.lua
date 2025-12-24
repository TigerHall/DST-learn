local COMPONENTNAME = debug.getinfo(1, 'S').source:match("([^/]+)%.lua$") --当前组件名

local function LinkPet(self, pet, beefalo)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    if pet.Physics ~= nil then
        pet.Physics:Teleport(x, y, z)
    elseif pet.Transform ~= nil then
        pet.Transform:SetPosition(x, y, z)
    end

    if not beefalo and self.inst.components.leader then
        self.inst.components.leader:AddFollower(pet)
    elseif beefalo and self.inst.components.rider then
        self.inst.components.rider:Mount(pet, true)
    end
end

local function ForEachItem(comp)
    -- 使用ForEachItem进行遍历,如果其他mod操作物品栏或容器写的不规范可能遍历不到
    comp:ForEachItem(function(item)
        if item.components[COMPONENTNAME] then
            item.components[COMPONENTNAME]:SaveRecord()
        end

        if item.components.container ~= nil
        -- or item.components.inventory ~= nil --能放背包还有inventory组件的话应该是活体了，活体的物品栏不检查
        then
            ForEachItem(item.components.container)
        end
    end)
end

---一般上下洞穴会重新调用OnSave和OnLoad，但是如果是背包里的物品只会调用OnSave，但不会调用OnLoad，也许是因为container组件的问题

--- 随从跟随主人上下洞穴，来自随机生物大小模组
--- 上下洞穴跟随的逻辑：
--- 1. 玩家穿越前调用GetSaveRecord保存随从数据，该操作遍历物品栏，对有该组件的物品都会检查是否有随从
--- 2. 删除随从对象，保证对象唯一
--- 2. 如果物品栏物品含有irreplaceable标签会禁止带下洞，需要先去掉该标签
--- 3. 在onload中读取保存的随从数据，生成并重新绑定跟随关系
local FollowMe = Class(function(self, inst)
    self.inst = inst
    self.followers = nil
    self.beefalo = nil

    self.onspawnfn = nil    --生成对象时调用，玩家穿越后的处理函数
    self.followtestfn = nil --是否可以跟随下洞
end)

--- 保存数据，穿越前的准备，首先玩家会调用这个方法，然后玩家身上有该组件的对象随后调用
function FollowMe:SaveRecord()
    -- 物品可以下洞
    self.inst:RemoveTag("irreplaceable")

    -- 遍历物品栏里物品的随从
    if self.inst.components.inventory then
        ForEachItem(self.inst.components.inventory)
    end

    -- 自己的随从
    if self.inst.components.leader ~= nil then
        self.followers = {}
        for k, _ in pairs(self.inst.components.leader.followers) do
            if k.persists                                                                    --不会处理阿比盖尔
                and (not k.components.inventoryitem or not k.components.inventoryitem.owner) --已经在物品栏里了就不用管
                and (not self.followtestfn or self.followtestfn(self.inst, k))               --测试通过
            then
                local saved = k:GetSaveRecord()
                table.insert(self.followers, saved)
                k:Remove()
            end
        end
    end
end

function FollowMe:SaveBeefalo()
    if self.inst.components.rider ~= nil then
        local rider = self.inst.components.rider
        if rider.mount ~= nil and (not self.followtestfn or self.followtestfn(self.inst, rider.mount)) then
            self.beefalo = rider.mount:GetSaveRecord()
            rider.mount:Remove()
        end
    end
end

----------------------------------------------------------------------------------------------------

function FollowMe:OnSave()
    return {
        followers = self.followers,
        beefalo = self.beefalo
    }
end

function FollowMe:OnLoad(data)
    if not data then return end

    if data.followers then
        self.inst:DoTaskInTime(0, function()
            for _, v in ipairs(data.followers) do
                local pet = SpawnSaveRecord(v)
                if pet ~= nil then
                    LinkPet(self, pet, false)
                    if self.onspawnfn then
                        self.onspawnfn(pet)
                    end
                end
            end
        end)
    end
    if data.beefalo then
        self.inst:DoTaskInTime(0, function()
            local pet = SpawnSaveRecord(data.beefalo)
            if pet ~= nil then
                LinkPet(self, pet, true)
                if self.onspawnfn then
                    self.onspawnfn(pet)
                end
            end
        end)
    end
end

return FollowMe
