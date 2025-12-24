local Shapes = require("aab_utils/shapes")

-- 湖泊生成
local function InitOasislake(inst)
    local count = math.random(4, 6)
    local Map = TheWorld.Map
    local pos = inst:GetPosition()
    for i = 1, 100 do
        local spawnpos = Shapes.GetRandomLocation(pos, 4, 20)
        if Map:IsDeployPointClear(spawnpos, inst, 4) then
            count = count - 1
            SpawnAt("monkeybarrel", spawnpos)
            if count <= 0 then
                return
            end
        end
    end
end

-- 初始化猴子建筑，懒得修改地形文件了
local function SpawnMonkeies(inst)
    for i, v in pairs(Ents) do
        if v.prefab == "oasislake" then
            InitOasislake(v)
        end
    end
end

local function Init(inst, self)
    if not self.spawn_tag then
        SpawnMonkeies(inst)
        self.spawn_tag = true
    end
end

--- 猴子！源源不断的猴子！
local MonkeySpawner = Class(function(self, inst)
    self.inst = inst

    self.spawn_tag = false

    inst:DoTaskInTime(0, Init, self)
end)

function MonkeySpawner:OnSave()
    return {
        spawn_tag = self.spawn_tag
    }
end

function MonkeySpawner:OnLoad(data)
    if not data then return end

    self.spawn_tag = data.spawn_tag or self.spawn_tag
end

return MonkeySpawner
