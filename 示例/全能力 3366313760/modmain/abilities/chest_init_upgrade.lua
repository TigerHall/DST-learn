local CHEST_INIT_UPGRADE = GetModConfigData("chest_init_upgrade")

local CHESTS1 = {
    "treasurechest",
    "dragonflychest"
}

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst.components.container and inst:HasTag("structure") then
        if CHEST_INIT_UPGRADE == 1 then
            if table.contains(CHESTS1, inst.prefab) then
                inst.components.container:EnableInfiniteStackSize(true)
            end
        else
            inst.components.container:EnableInfiniteStackSize(true)
        end
    end
end)
