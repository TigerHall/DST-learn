local MAX_REPEAT_COUNT = 100
local ISLAND_SIZE = 39 * 4

local TILE_LIMIT_LIST = {
    hmr_cherry_tree = {
        tag = "hmr_cherry_tree",
        tile = WORLD_TILES.HMR_CHERRY_FLOWER,
        radius = 5,
        max = 50,
        stages = {
            hmr_cherry_tree_s1 = math.random(15, 25),
            hmr_cherry_tree_s2 = math.random(15, 25),
            hmr_cherry_tree_s3 = math.random(10, 20),
            hmr_cherry_tree_s4 = math.random(10, 20)
        },
    },
    hmr_cherry_grass = {
        tag = "hmr_cherry_grass",
        tile = WORLD_TILES.HMR_CHERRY_GRASS,
        radius = 2,
        max = 60,
        stages = {
            hmr_cherry_grass = math.random(50, 70)
        },
    },
    hmr_cherry_rock = {
        tag = "hmr_cherry_rock",
        tile = WORLD_TILES.HMR_CHERRY_GRASS,
        radius = 4,
        max = 50,
        stages = {
            hmr_cherry_rock_short = math.random(20, 30),
            hmr_cherry_rock_med = math.random(5, 15),
            hmr_cherry_rock_tall = math.random(10, 20)
        },
    },
    hmr_cherry_flower = {
        tag = "hmr_cherry_flower",
        tile = WORLD_TILES.HMR_CHERRY_FLOWER,
        radius = 1,
        max = 40,
        stages = {
            hmr_cherry_flower = math.random(20, 30)
        }
    }
}

local HMRCherryIslandManager = Class(function(self, inst)
    self.inst = inst

    self.center_pos = nil
    self.tile_limit = TILE_LIMIT_LIST

    -- self:WatchWorldState("cycles", function()
    --     print("樱花岛管理组件周期任务")
    --     self:ReplenishItems()
    -- end)
end)

function HMRCherryIslandManager:SetCenterPos(pos)
    local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
    self.center_pos = Vector3(x, y, z)
end

function HMRCherryIslandManager:GetCenterPos()
    return self.center_pos
end

function HMRCherryIslandManager:GetTileForPrefab(prefab)
    for type, data in pairs(self.tile_limit) do
        for stage, count in pairs(data.stages) do
            if stage == prefab then
                return data.tile
            end
        end
    end
    return 0
end

function HMRCherryIslandManager:GetRadiusForPrefab(prefab)
    for type, data in pairs(self.tile_limit) do
        for stage, count in pairs(data.stages) do
            if stage == prefab then
                return data.radius
            end
        end
    end
    return 0
end

function HMRCherryIslandManager:GetRamdomPosOnIsland(prefab)
    if self.center_pos == nil then
        print("无中心坐标")
        return nil
    end
    local find_count = 0
    while find_count < MAX_REPEAT_COUNT do
        local x = 35 * 4 * (math.random() - 0.5) + self.center_pos.x
        local z = 35 * 4 * (math.random() - 0.5) + self.center_pos.z
        local space = true
        for type, data in pairs(self.tile_limit) do
            local ents = TheSim:FindEntities(x, self.center_pos.y, z, data.radius, {data.tag or type})
            if #ents > 0 then
                space = false
                break
            end
        end
        local ents = TheSim:FindEntities(x, self.center_pos.y, z, self:GetRadiusForPrefab(prefab))
        if TheWorld.Map:GetTileAtPoint(x, self.center_pos.y, z) == self:GetTileForPrefab(prefab) and #ents == 0 and space then
            return Vector3(x, self.center_pos.y, z)
        end
        find_count = find_count + 1
    end
end

function HMRCherryIslandManager:Spawn(prefab, amount)
    local tree_count = 0
    local try_count = amount * 10
    while tree_count < amount and try_count > 0 do
        local pos = self:GetRamdomPosOnIsland(prefab)
        if pos then
            local ent = SpawnPrefab(prefab)
            if ent then
                ent.Transform:SetPosition(pos:Get())
                tree_count = tree_count + 1
            end
        end
        try_count = try_count - 1
    end
end

function HMRCherryIslandManager:Init()
    for type, data in pairs(self.tile_limit) do
        for stage, count in pairs(data.stages) do
            self:Spawn(stage, count)
        end
    end
    self.init_complete = true
end

function HMRCherryIslandManager:GetTags()
    local tags = {}
    for prefab, data in pairs(self.tile_limit) do
        if not table.contains(tags, data.tag) then
            table.insert(tags, data.tag)
        end
    end
    return tags
end

function HMRCherryIslandManager:GetItems()
    local ents = TheSim:FindEntities(self.center_pos.x, self.center_pos.y, self.center_pos.z, ISLAND_SIZE, self:GetTags())
    local items = {}
    for i, ent in ipairs(ents) do
        for prefab, data in pairs(self.tile_limit) do
            if ent:HasTag(data.tag) then
                items[data.tag] = items[data.tag] or {}
                table.insert(items[data.tag], ent)
            end
        end
    end
    return items
end

function HMRCherryIslandManager:ReplenishItems()
    print("樱花岛管理组件补充任务")
    local items = self:GetItems()
    print("当前岛内物品数量", items)
    for type, data in pairs(self.tile_limit) do
        print("当前类型物品数量", items[data.tag])
        if items[data.tag] and #items[data.tag] < data.max then
            local keys = {}
            for key in pairs(data.stages) do
                table.insert(keys, key)
            end
            local random_key = keys[math.random(#keys)]
            local prefab = data.stages[random_key]
            self:Spawn(prefab, math.clamp(data.max - #items[data.tag], 0, 3))
        end
    end
end

function HMRCherryIslandManager:OnSave()
    local data = {
        center_pos = self.center_pos,
        init_complete = self.init_complete
    }
    return next(data) ~= nil and data or nil
end

function HMRCherryIslandManager:OnLoad(data)
    if data ~= nil then
        self.center_pos = data.center_pos
        self.init_complete = data.init_complete
    end
end

return HMRCherryIslandManager