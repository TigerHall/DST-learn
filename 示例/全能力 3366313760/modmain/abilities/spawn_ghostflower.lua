local Shapes = require("aab_utils/shapes")

local function OnStartDay(inst)
    local pos = inst:GetPosition()
    local count = 0
    for _, v in ipairs(TheSim:FindEntities(pos.x, pos.y, pos.z, 4, nil, { "INLIMBO" })) do
        if v.prefab == "ghostflower" then
            count = count + 1
        end
    end
    if count < 6 then
        for _ = 1, math.random(1, 2) do
            local item = SpawnAt("ghostflower", Shapes.GetRandomLocation(pos, 0.5, 4))
            item:DelayedGrow()
        end
    end
end

AddPrefabPostInit("sisturn", function(inst)
    if not TheWorld.ismastersim then return end

    inst:WatchWorldState("startday", OnStartDay)
end)
