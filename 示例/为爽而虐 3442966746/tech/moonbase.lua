local children = {"knight", "bishop", "rook"}

local function addspawnfader(inst) if not inst.components.spawnfader then inst:AddComponent("spawnfader") end end
for _, monster in ipairs(children) do AddPrefabPostInit(monster, addspawnfader) end

local function ReleaseAllChildren(inst)
    for index = 1, 3 do
        if inst.components.childspawner2hm.childreninside > 0 then inst.components.childspawner2hm:SpawnChild(nil, children[math.random(3)]) end
    end
end

local function onfullmoon(inst, isfullmoon)
    if isfullmoon then
        if inst.components.repairable and inst.components.repairable.onrepaired and inst.components.workable then
            inst.components.workable:SetWorkLeft(TUNING.MOONBASE_COMPLETE_WORK)
            inst.components.repairable.onrepaired(inst, inst)
        end
        for k, child in pairs(inst.components.childspawner2hm.childrenoutside) do
            if child and child:IsValid() and child.components.repairable then
                if child:IsNear(inst, 20) then
                    if child.components.timer and child.components.timer:TimerExists("mod_hardmode_timechange") then
                        child.components.timer:SetTimeLeft("mod_hardmode_timechange", 0)
                    end
                else
                    inst.components.childspawner2hm:OnChildKilled(child)
                    child:Remove()
                end
            end
        end
        inst.components.childspawner2hm:DoRegen()
    end
end

local function onspawnchild(inst, child) if child.components.spawnfader then child.components.spawnfader:FadeIn() end end

local changetime = GetModConfigData("chess") == -1 and TUNING.TOTAL_DAY_TIME * 35 or TUNING.TOTAL_DAY_TIME * 10
AddPrefabPostInit("moonbase", function(inst)
    if not TheWorld.ismastersim then return end
    inst.listenforprefabsawp = true
    if not inst.components.childspawner2hm then inst:AddComponent("childspawner2hm") end
    inst.components.childspawner2hm.childname = "knight"
    inst.components.childspawner2hm.spawnradius = 4
    inst.components.childspawner2hm:SetMaxChildren(3)
    inst.components.childspawner2hm:SetRegenPeriod(changetime)
    inst.components.childspawner2hm:SetSpawnPeriod(120)
    inst.components.childspawner2hm:SetOnAddChildFn(ReleaseAllChildren)
    inst.components.childspawner2hm:SetSpawnedFn(onspawnchild)
    inst.components.childspawner2hm.childreninside = 1
    inst.components.childspawner2hm.cansave = true
    if not inst.components.playerprox2hm then inst:AddComponent("playerprox2hm") end
    inst.components.playerprox2hm:SetDist(30, 30) -- set specific values
    inst.components.playerprox2hm:SetOnPlayerNear(ReleaseAllChildren)
    inst:WatchWorldState("isfullmoon", onfullmoon)
    inst:DoTaskInTime(0, ReleaseAllChildren)
end)
