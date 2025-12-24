-- -- 回家还不如跟随上下洞穴呢
-- local function OnPlayerMigrate(inst, data)
--     if data and data.player then
--         for k in pairs(data.player.components.leader.followers) do
--             local home = k.components.homeseeker and k.components.homeseeker:GetHome()
--             if home and (home.components.childspawner or home.components.spawner) --必须有家
--                 and k:GetDistanceSqToInst(home) > HOME_MAX_DIS_SQ                 --必须在允许范围外
--             then
--                 if home.components.childspawner then
--                     home.components.childspawner:GoHome(k)
--                 else
--                     home.components.spawner:GoHome(k)
--                 end
--             end
--         end
--     end
-- end

-- AddPrefabPostInit("world", function(inst)
--     if not TheWorld.ismastersim then return end
--     --上下洞穴处理
--     inst:ListenForEvent("ms_playerdespawnandmigrate", OnPlayerMigrate)
-- end)

----------------------------------------------------------------------------------------------------

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end

    inst:AddComponent("aab_followme")
end)


local function OnPlayerMigrate(inst, data)
    if data and data.player and data.player.components.aab_followme then
        data.player.components.aab_followme:SaveRecord()
    end
end

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end

    --上下洞穴处理
    inst:ListenForEvent("ms_playerdespawnandmigrate", OnPlayerMigrate)
end)
