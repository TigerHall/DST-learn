local Utils = require("aab_utils/utils")

-- 要不要这么长啊
AddGamePostInit(function()
    -- for _, d in pairs(STRINGS.CHARACTERS) do
    --     if d.ANNOUNCE_CHARLIESAVE and d.ANNOUNCE_CHARLIESAVE[1] == "only_used_by_winona" then
    --         d.ANNOUNCE_CHARLIESAVE = STRINGS.CHARACTERS.WINONA.ANNOUNCE_CHARLIESAVE
    --     end
    --     if d.ANNOUNCE_CHARLIE_MISSED == "only_used_by_winona" then
    --         d.ANNOUNCE_CHARLIE_MISSED = STRINGS.CHARACTERS.WINONA.ANNOUNCE_CHARLIE_MISSED
    --     end
    --     if d.ANNOUNCE_ENGINEERING_CAN_DOWNGRADE == "only_used_by_winona" then
    --         d.ANNOUNCE_ENGINEERING_CAN_DOWNGRADE = STRINGS.CHARACTERS.WINONA.ANNOUNCE_ENGINEERING_CAN_DOWNGRADE
    --     end
    --     if d.ANNOUNCE_ENGINEERING_CAN_SIDEGRADE == "only_used_by_winona" then
    --         d.ANNOUNCE_ENGINEERING_CAN_SIDEGRADE = STRINGS.CHARACTERS.WINONA.ANNOUNCE_ENGINEERING_CAN_SIDEGRADE
    --     end
    --     if d.ANNOUNCE_ENGINEERING_CAN_UPGRADE == "only_used_by_winona" then
    --         d.ANNOUNCE_ENGINEERING_CAN_UPGRADE = STRINGS.CHARACTERS.WINONA.ANNOUNCE_ENGINEERING_CAN_UPGRADE
    --     end
    --     if d.ANNOUNCE_HUNGRY_FASTBUILD and d.ANNOUNCE_HUNGRY_FASTBUILD[1] == "only_used_by_winona" then
    --         d.ANNOUNCE_HUNGRY_FASTBUILD = STRINGS.CHARACTERS.WINONA.ANNOUNCE_HUNGRY_FASTBUILD
    --     end
    --     if d.ANNOUNCE_HUNGRY_SLOWBUILD and d.ANNOUNCE_HUNGRY_SLOWBUILD[1] == "only_used_by_winona" then
    --         d.ANNOUNCE_HUNGRY_SLOWBUILD = STRINGS.CHARACTERS.WINONA.ANNOUNCE_HUNGRY_SLOWBUILD
    --     end
    --     if d.ANNOUNCE_ROSEGLASSES and d.ANNOUNCE_ROSEGLASSES[1] == "only_used_by_winona" then
    --         d.ANNOUNCE_ROSEGLASSES = STRINGS.CHARACTERS.WINONA.ANNOUNCE_ROSEGLASSES
    --     end
    --     if d.ANNOUNCE_WORMHOLE_SAMESPOT == "only_used_by_winona" then
    --         d.ANNOUNCE_WORMHOLE_SAMESPOT = STRINGS.CHARACTERS.WINONA.ANNOUNCE_WORMHOLE_SAMESPOT
    --     end
    --     if d.DESCRIBE.CHARLIERESIDUE == "only_used_by_winona" then
    --         d.DESCRIBE.CHARLIERESIDUE = STRINGS.CHARACTERS.WINONA.DESCRIBE.CHARLIERESIDUE
    --     end
    --     if d.DESCRIBE.CHARLIEROSE == "only_used_by_winona" then
    --         d.DESCRIBE.CHARLIEROSE = STRINGS.CHARACTERS.WINONA.DESCRIBE.CHARLIEROSE
    --     end
    --     if d.DESCRIBE.INSPECTACLESBOX == "only_used_by_winona" then
    --         d.DESCRIBE.INSPECTACLESBOX = STRINGS.CHARACTERS.WINONA.DESCRIBE.INSPECTACLESBOX
    --     end
    --     if d.DESCRIBE.INSPECTACLESBOX2 == "only_used_by_winona" then
    --         d.DESCRIBE.INSPECTACLESBOX2 = STRINGS.CHARACTERS.WINONA.DESCRIBE.INSPECTACLESBOX2
    --     end
    --     if d.DESCRIBE.INSPECTACLESHAT and d.DESCRIBE.INSPECTACLESHAT.INSPECTACLESHAT == "only_used_by_winona" then
    --         d.DESCRIBE.INSPECTACLESHAT = STRINGS.CHARACTERS.WINONA.DESCRIBE.INSPECTACLESHAT
    --     end
    --     if d.DESCRIBE.ROSEGLASSESHAT and d.DESCRIBE.ROSEGLASSESHAT.MISSINGSKILL == "only_used_by_winona" then
    --         d.DESCRIBE.ROSEGLASSESHAT = STRINGS.CHARACTERS.WINONA.DESCRIBE.ROSEGLASSESHAT
    --     end
    --     if d.DESCRIBE.WINONA_HOLOTELEBRELLA == "only_used_by_winona" then
    --         d.DESCRIBE.WINONA_HOLOTELEBRELLA = STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_HOLOTELEBRELLA
    --     end
    --     if d.DESCRIBE.WINONA_HOLOTELEPAD == "only_used_by_winona" then
    --         d.DESCRIBE.WINONA_HOLOTELEPAD = STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_HOLOTELEPAD
    --     end
    --     if d.DESCRIBE.WINONA_MACHINEPARTS_1 == "only_used_by_winona" then
    --         d.DESCRIBE.WINONA_MACHINEPARTS_1 = STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_MACHINEPARTS_1
    --     end
    --     if d.DESCRIBE.WINONA_MACHINEPARTS_2 == "only_used_by_winona" then
    --         d.DESCRIBE.WINONA_MACHINEPARTS_2 = STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_MACHINEPARTS_2
    --     end
    --     if d.DESCRIBE.WINONA_RECIPESCANNER == "only_used_by_winona" then
    --         d.DESCRIBE.WINONA_RECIPESCANNER = STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_RECIPESCANNER
    --     end
    --     if d.DESCRIBE.WINONA_TELEBRELLA and d.DESCRIBE.WINONA_TELEBRELLA.MISSINGSKILL == "only_used_by_winona" then
    --         d.DESCRIBE.WINONA_TELEBRELLA = STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_TELEBRELLA
    --     end
    --     if d.DESCRIBE.WINONA_TELEPORT_PAD_ITEM and d.DESCRIBE.WINONA_TELEPORT_PAD_ITEM.MISSINGSKILL == "only_used_by_winona" then
    --         d.DESCRIBE.WINONA_TELEPORT_PAD_ITEM = STRINGS.CHARACTERS.WINONA.DESCRIBE.WINONA_TELEPORT_PAD_ITEM
    --     end

    --     for k, v in pairs(d.ACTIONFAIL.CASTAOE) do
    --         if v == "only_used_by_winona" then
    --             d.ACTIONFAIL.CASTAOE[k] = STRINGS.CHARACTERS.WINONA.ACTIONFAIL.CASTAOE[k]
    --         end
    --     end
    --     for k, v in pairs(d.ACTIONFAIL.LOOKAT) do
    --         if v == "only_used_by_winona" then
    --             d.ACTIONFAIL.LOOKAT[k] = STRINGS.CHARACTERS.WINONA.ACTIONFAIL.LOOKAT[k]
    --         end
    --     end
    --     for k, v in pairs(d.ACTIONFAIL.REMOTE_TELEPORT) do
    --         if v == "only_used_by_winona" then
    --             d.ACTIONFAIL.REMOTE_TELEPORT[k] = STRINGS.CHARACTERS.WINONA.ACTIONFAIL.REMOTE_TELEPORT[k]
    --         end
    --     end
    -- end

    AAB_ReplaceCharacterLines("winona")
end)


----------------------------------------------------------------------------------------------------

local function ReticuleTargetFn()
    local player = ThePlayer
    local pos = Vector3()
    for r = 2.5, 1, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if CLOSEINSPECTORUTIL.IsValidPos(player, pos) then
            return pos
        end
    end
    pos.x, pos.y, pos.z = player.Transform:GetWorldPosition()
    return pos
end

AAB_AddSpecialAction(function(inst, pos, useitem, right, bufs, usereticulepos)
    if right then
        if useitem == nil then
            local inventory = inst.replica.inventory
            if inventory ~= nil then
                useitem = inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            end
        end
        if useitem and
            useitem.prefab == "roseglasseshat" and
            useitem:HasTag("closeinspector")
        then
            --match ReticuleTargetFn
            if usereticulepos then
                local pos2 = Vector3()
                for r = 2.5, 1, -.25 do
                    pos2.x, pos2.y, pos2.z = inst.entity:LocalToWorldSpace(r, 0, 0)
                    if CLOSEINSPECTORUTIL.IsValidPos(inst, pos2) then
                        return { ACTIONS.LOOKAT }, pos2
                    end
                end
            end

            --default
            if CLOSEINSPECTORUTIL.IsValidPos(inst, pos) then
                return { ACTIONS.LOOKAT }
            end
        end
    end
    return {}
end)

----------------------------------------------------------------------------------------------------


AAB_ActivateSkills("winona")

AddPlayerPostInit(function(inst)
    if inst.prefab == "winona" then return end

    inst:AddTag("handyperson")
    inst:AddTag("basicengineer")

    if not inst.components.inspectaclesparticipant then
        inst:AddComponent("inspectaclesparticipant")
    end

    if not inst.components.reticule then
        inst:AddComponent("reticule")
    end
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    if not TheWorld.ismastersim then return end

    if not inst.components.roseinspectableuser then
        inst:AddComponent("roseinspectableuser")
    end

    inst:AddComponent("aab_winona")
end)
