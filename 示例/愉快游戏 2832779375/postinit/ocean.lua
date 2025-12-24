
local FISH_DATA = require("prefabs/oceanfishdef")
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("oceanfish_no_season") then
    local SCHOOL_WEIGHTS = FISH_DATA.school

    --[[
        oceanfish_small_6: 落叶比目鱼
        oceanfish_medium_8: 冰鲷鱼
        oceanfish_small_7: 花鳍鲔鱼
        oceanfish_small_8: 炽热太阳鱼
    ]]
    SCHOOL_WEIGHTS[SEASONS.AUTUMN][GROUND.OCEAN_SWELL].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.AUTUMN][GROUND.OCEAN_WATERLOG].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.AUTUMN][GROUND.OCEAN_SWELL].oceanfish_medium_8 = 4
    SCHOOL_WEIGHTS[SEASONS.AUTUMN][GROUND.OCEAN_COASTAL].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.AUTUMN][GROUND.OCEAN_WATERLOG].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.AUTUMN][GROUND.OCEAN_SWELL].oceanfish_small_8 = 4

    SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_SWELL].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_WATERLOG].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_SWELL].oceanfish_medium_8 = 4
    SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_COASTAL].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_WATERLOG].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.WINTER][GROUND.OCEAN_SWELL].oceanfish_small_8 = 4

    SCHOOL_WEIGHTS[SEASONS.SPRING][GROUND.OCEAN_SWELL].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.SPRING][GROUND.OCEAN_WATERLOG].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.SPRING][GROUND.OCEAN_SWELL].oceanfish_medium_8 = 4
    SCHOOL_WEIGHTS[SEASONS.SPRING][GROUND.OCEAN_COASTAL].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.SPRING][GROUND.OCEAN_WATERLOG].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.SPRING][GROUND.OCEAN_SWELL].oceanfish_small_8 = 4

    SCHOOL_WEIGHTS[SEASONS.SUMMER][GROUND.OCEAN_SWELL].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.SUMMER][GROUND.OCEAN_WATERLOG].oceanfish_small_6 = 4
    SCHOOL_WEIGHTS[SEASONS.SUMMER][GROUND.OCEAN_SWELL].oceanfish_medium_8 = 4
    SCHOOL_WEIGHTS[SEASONS.SUMMER][GROUND.OCEAN_COASTAL].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.SUMMER][GROUND.OCEAN_WATERLOG].oceanfish_small_7 = 4
    SCHOOL_WEIGHTS[SEASONS.SUMMER][GROUND.OCEAN_SWELL].oceanfish_small_8 = 4

    AddPrefabPostInit("spoiled_food", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components ~= nil and inst.components.oceanfishingtackle ~= nil then
            inst.components.oceanfishingtackle:SetupLure({
                build = "oceanfishing_lure_mis",
                symbol = "hook_spoiledfood",
                single_use = false,
                lure_data = {
                    charm = 0.9,
                    reel_charm = 0.9,
                    radius = 8.0,
                    style = "rot",
                    timeofday = {
                        day = 5,
                        dusk = 5,
                        night = 5
                    },
                    dist_max = 2
                }
            })
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("oceanfish_into_inventory") then
    AddPrefabPostInit("oceanfishingrod", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.oceanfishingrod then
            local old_ondonefishing = inst.components.oceanfishingrod.ondonefishing
            inst.components.oceanfishingrod.ondonefishing = function(inst, reason, lose_tackle, fisher, target)
                old_ondonefishing(inst, reason, lose_tackle, fisher, target)

                if reason == "success" and fisher and target and target:HasTag("oceanfish") and fisher.components.inventory then
                    inst:DoTaskInTime(0.8, function(inst)
                        local _fish_inv = SpawnPrefab(target.prefab .. "_inv")
                        if _fish_inv then
                            fisher.components.inventory:GiveItem(_fish_inv, nil, target:GetPosition())
                            target:Remove()
                        end
                    end)
                end
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("fishrod_onwater") then
    AddPrefabPostInit("oceanfishingrod", function(inst)
        local function becameking(inst, owner)
            if owner.components.drownable ~= nil then
                if owner.components.drownable.enabled == false then
                    owner.Physics:ClearCollisionMask()
                    owner.Physics:CollidesWith(COLLISION.GROUND)
                    owner.Physics:CollidesWith(COLLISION.OBSTACLES)
                    owner.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
                    owner.Physics:CollidesWith(COLLISION.CHARACTERS)
                    owner.Physics:CollidesWith(COLLISION.GIANTS)
                elseif owner.components.drownable.enabled == true then
                    if not owner:HasTag("playerghost") then
                        owner.Physics:ClearCollisionMask()
                        owner.Physics:CollidesWith(COLLISION.WORLD)
                        owner.Physics:CollidesWith(COLLISION.OBSTACLES)
                        owner.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
                        owner.Physics:CollidesWith(COLLISION.CHARACTERS)
                        owner.Physics:CollidesWith(COLLISION.GIANTS)
                    end
                end
            end
        end

        if not TheWorld.ismastersim then
            return inst
        end

        if inst.components.equippable then
            local _onequip = inst.components.equippable.onequipfn
            inst.components.equippable:SetOnEquip(function(inst, owner)
                _onequip(inst, owner)

                if owner and owner.components.drownable then
                    owner.components.drownable.enabled = false
                    becameking(inst, owner)
                end
            end)

            local _onunequip = inst.components.equippable.onunequipfn
            inst.components.equippable:SetOnUnequip(function(inst, owner)
                _onunequip(inst, owner)

                if owner and owner.components.drownable then
                    owner.components.drownable.enabled = true
                    becameking(inst, owner)
                end
            end)
        end

    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("ship_auto_heal") then
    AddPrefabPostInit("boat", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.health then
            inst.components.health:StartRegen(2, 1)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------

























