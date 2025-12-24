-- 冬季玩家附近生成冷源
local function onphasechange(inst)
    if not inst:HasTag("playerghost") and TheWorld.state.iswinter and (TheWorld.state.isdusk or TheWorld.state.isnight or TheWorld:HasTag("cave")) and
        not inst.winterstafflighttask2hm then
        inst.winterstafflighttask2hm = inst:DoTaskInTime(math.random(10) + 1, function()
            inst.winterstafflighttask2hm = nil
            local x, y, z = inst.Transform:GetWorldPosition()
            local staff2 = SpawnPrefab("mod_hardmode_staffcoldlight")
            staff2.Transform:SetPosition(x + (math.random(2) - 1.5) * 40, y, z + (math.random(2) - 1.5) * 40)
        end)
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:WatchWorldState("phase", onphasechange)
    inst:WatchWorldState("cavephase", onphasechange)
end)

if GetModConfigData("winter_change") ~= -1 then
    AddPrefabPostInit("world", function(inst)
        if not inst.ismastersim then return inst end
        if not inst.components.waterstreakrain2hm then inst:AddComponent("waterstreakrain2hm") end
        inst.components.waterstreakrain2hm.enablesnow = true
    end)
    local function checkDynamicShadow(inst) if inst.DynamicShadow then inst.DynamicShadow:Enable(inst:HasTag("DynamicShadow2hm")) end end
    AddPrefabPostInit("snowball", function(inst)
        if not inst.DynamicShadow then
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(2.5, 1.5)
            inst:DoTaskInTime(0, checkDynamicShadow)
            inst.DynamicShadow:Enable(false)
        end
    end)
end
