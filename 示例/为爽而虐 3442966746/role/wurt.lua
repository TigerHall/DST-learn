if CONSTRUCTION_PLANS and CONSTRUCTION_PLANS["mermthrone_construction"] then
    table.insert(CONSTRUCTION_PLANS["mermthrone_construction"], Ingredient("trident", 1))
else
    AddRecipePostInit("mermthrone_construction", function(inst) table.insert(inst.ingredients, Ingredient("trident", 1)) end)
end

TUNING.PUNY_MERM_HEALTH = TUNING.MERM_HEALTH
TUNING.PUNY_MERM_DAMAGE = TUNING.MERM_DAMAGE

local function StartSpawning(inst)
    if not inst:HasTag("burnt") and TheWorld.components.mermkingmanager and not TheWorld.components.mermkingmanager:HasKing() and inst.components.childspawner ~=
        nil then inst.components.childspawner:StartSpawning() end
end

AddPrefabPostInit("mermwatchtower", function(inst)
    if not TheWorld.ismastersim then return end
    if not (TheWorld.components.mermkingmanager and TheWorld.components.mermkingmanager:HasKing()) then StartSpawning(inst) end
    inst:ListenForEvent("onmermkingdestroyed", StartSpawning, TheWorld)
end)

local merms = {"merm", "mermguard"}
local newloot = {"pondfish", "frog"}
for index, merm in ipairs(merms) do
    AddPrefabPostInit(merm, function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.lootdropper and math.random() < 0.1 then inst.components.lootdropper:SetLoot(newloot) end
    end)
end