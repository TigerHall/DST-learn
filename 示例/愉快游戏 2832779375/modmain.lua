GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

--[[
    local x,y,z = GetPlayer().Transform:GetWorldPosition() local ents = TheSim:FindEntities(x,y,z, 4) for i,v in ipairs(ents) do print(v.prefab) end
    print(DebugSpawn"我的物品":GetDebugString())
    TheWorld > sim > game > player
    ThePlayer.Physics:Teleport(0,0,0)
]]

PrefabFiles = {
    "py_place",
    "py_herds",
}

-- local IS_SERVER = TheNet:GetIsServer()

modimport("postinit/ability")
modimport("postinit/breed")
modimport("postinit/celestial")
modimport("postinit/cool")
modimport("postinit/craft")
modimport("postinit/efficiency")
modimport("postinit/farm")
modimport("postinit/ocean")
modimport("postinit/unlimit_uses")
















