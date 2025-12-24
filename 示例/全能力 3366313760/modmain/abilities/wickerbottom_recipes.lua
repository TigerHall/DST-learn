AddGamePostInit(function()
    AAB_ReplaceCharacterLines("wickerbottom")
end)

local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
local function OnReadFn(inst, book)
    if inst.components.sanity:IsInsane() then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)

        if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
            TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
        end
    end
end

AddPlayerPostInit(function(inst)
    if inst.prefab == "wickerbottom" then return end

    inst:AddTag("bookbuilder")
    inst:AddTag("reader")

    if not TheWorld.ismastersim then return end

    inst.components.builder.science_bonus = math.max(inst.components.builder.science_bonus or 0, 1)

    if not inst.components.reader then
        inst:AddComponent("reader")
        inst.components.reader:SetOnReadFn(OnReadFn)
    end
    inst.components.reader:SetAspiringBookworm(nil) --小鱼妹也可以读书
end)
