

local became_winona = GetModConfigData("became_winona")
local became_wormwood = GetModConfigData("became_wormwood")
local became_wickerbottom = GetModConfigData("became_wickerbottom")
local became_wathgrithr = GetModConfigData("became_wathgrithr")
local became_wanda = GetModConfigData("became_wanda")
-- local became_wortox = GetModConfigData("became_wortox")
local became_warly = GetModConfigData("became_warly")
local became_walter = GetModConfigData("became_walter")
local became_maxwell = GetModConfigData("became_maxwell")
AddPlayerPostInit(function(inst)
    local function IsValidVictim(victim)
        return victim ~= nil
            and not ((victim:HasTag("prey") and not victim:HasTag("hostile")) or
                    victim:HasTag("veggie") or
                    victim:HasTag("structure") or
                    victim:HasTag("wall") or
                    victim:HasTag("balloon") or
                    victim:HasTag("groundspike") or
                    victim:HasTag("smashable") or
                    victim:HasTag("companion"))
            and victim.components.health ~= nil
            and victim.components.combat ~= nil
    end

    local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
    local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
    local function OnReadFn(inst, book)
        if inst.components.sanity:IsInsane() then

            local x,y,z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)

            if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
                TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
            end
        end
    end
    local function GetEquippableDapperness(owner, equippable)
        local dapperness = equippable:GetDapperness(owner, owner.components.sanity.no_moisture_penalty)
        return equippable.inst:HasTag("shadow_item")
            and dapperness * TUNING.WAXWELL_SHADOW_ITEM_RESISTANCE
            or dapperness
    end

    if became_winona then
        inst:AddTag("handyperson")
        inst:AddTag("fastbuilder")
        -- inst:AddTag("hungrybuilder")
    end
    if became_wormwood then
        inst:AddTag("plantkin")
    end
    if became_wickerbottom then
        inst:AddTag("bookbuilder")
        inst:AddTag("reader")
    end
    if became_wathgrithr then
        inst:AddTag("valkyrie")
        -- inst:AddTag("battlesinger")
    end
    if became_wanda then
        inst:AddTag("clockmaker")
        inst:AddTag("pocketwatchcaster")
    end
    if became_warly then
        inst:AddTag("masterchef")
        inst:AddTag("professionalchef")
        inst:AddTag("expertchef")
    end
    if became_walter and inst.prefab ~= "wolfgang" then
        inst:AddTag("slingshot_sharpshooter")
        inst:AddTag("efficient_sleeper")
        inst:AddTag("nowormholesanityloss")
        inst:AddTag("pebblemaker")
    end

    if became_maxwell and inst.prefab ~= "waxwell" then
        inst:AddTag("shadowmagic")
        inst:AddTag("dappereffects")
        --magician (from magician component) added to pristine state for optimization
        inst:AddTag("magician")
        --reader (from reader component) added to pristine state for optimization
        inst:AddTag("reader")
    end

    -----------------------------------------------------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
    -----------------------------------------------------------------------------------------

    if became_wickerbottom then
        if not inst.components.reader then
            inst:AddComponent("reader")
        end
        inst.components.builder.science_bonus = 1
    end
    if became_wathgrithr then
        if not inst.components.battleborn then
            inst:AddComponent("battleborn")
            inst.components.battleborn:SetBattlebornBonus(TUNING.WATHGRITHR_BATTLEBORN_BONUS)
            inst.components.battleborn:SetSanityEnabled(true)
            inst.components.battleborn:SetHealthEnabled(true)
            inst.components.battleborn:SetValidVictimFn(IsValidVictim)
        end

        inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT
        inst.components.health:SetAbsorptionAmount(TUNING.WATHGRITHR_ABSORPTION)
    end

    if became_maxwell and inst.prefab ~= "waxwell" then
        if not inst.components.magician then
            inst:AddComponent("magician")
        end

        if not inst.components.reader then
            inst:AddComponent("reader")
        end
        inst.components.reader:SetSanityPenaltyMultiplier(TUNING.MAXWELL_READING_SANITY_MULT)
        inst.components.reader:SetOnReadFn(OnReadFn)

        if not inst.components.petleash then
            inst:AddComponent("petleash")
        end
        inst.components.petleash:SetMaxPets(6)

        if inst.components.sanity then
            inst.components.sanity.dapperness = TUNING.DAPPERNESS_LARGE
            inst.components.sanity.get_equippable_dappernessfn = GetEquippableDapperness
        end
    end
end)
--------------------------------------------------------------------------------------------------------------------


































