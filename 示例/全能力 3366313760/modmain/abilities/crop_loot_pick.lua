local function OnPicked(inst, data)
    local pos = inst:GetPosition()
    TheWorld:DoTaskInTime(0, function() --当前帧就会删除，让world来生成
        if not inst:IsValid() then
            SpawnAt(inst.prefab, pos)
        end
    end)
end

AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then return end

    if inst:HasTag("plantedsoil") and inst:HasTag("farm_plant") and inst:HasTag("plant") then
        inst:ListenForEvent("picked", OnPicked)
    end
end)
