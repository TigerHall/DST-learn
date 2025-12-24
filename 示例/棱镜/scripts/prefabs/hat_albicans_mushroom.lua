local TOOLS_L = require("tools_legion")
local assets = {
    Asset("ANIM", "anim/hat_albicans_mushroom.zip"),
	Asset("ATLAS", "images/inventoryimages/hat_albicans_mushroom.xml"),
    Asset("IMAGE", "images/inventoryimages/hat_albicans_mushroom.tex")
}
local prefabs = {
    "escapinggerms_fx",
    "buff_l_sporeresistance",
    "albicanscloud_fx",
    "albicans_cap",
    "spore_small",
    "spore_medium",
    "spore_tall"
}

local function onequip(inst, owner)
    TOOLS_L.hat_on(owner, "hat_albicans_mushroom", "swap_hat")

    inst.components.periodicspawner:Start()

    if owner:HasTag("equipmentmodel") then return end --假人

    if owner.components.hunger ~= nil then
        owner.components.hunger.burnratemodifiers:SetModifier(inst, TUNING.ARMORSLURPER_SLOW_HUNGER) --0.6的饥饿速度
    end
end
local function onunequip(inst, owner)
    TOOLS_L.hat_off(inst, owner)

    inst.components.periodicspawner:Stop()

    if owner.components.hunger ~= nil then
        owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
    end
end
local function onuse(inst)
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil then
    	if owner.components.hunger ~= nil and owner.components.hunger.current < 30 then
    		if owner.components.talker ~= nil then
                owner.components.talker:Say(GetString(owner, "DESCRIBE", { "HAT_ALBICANS_MUSHROOM", "HUNGER" }))
            end
            -- inst.components.useableitem:StopUsingItem() --此时已经是使用中了，需要还原使用状态
            return false --onuse()如果返回false的话，就能还原使用状态
    	end

        owner.sg:GoToState("release_spores", inst)
    end
end
local function ReleaseSporesEffect(inst, owner)
    local x, y, z = owner.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3.5,
        nil, TOOLS_L.TagsCombat1(), { "player", "lamp", "crop_legion", "crop2_legion", "trader" }
    )
    for _, ent in ipairs(ents) do
        if ent.entity:IsVisible() then
            if ent:HasTag("player") then
                ent:AddDebuff("buff_l_sporeresistance", "buff_l_sporeresistance")
            elseif ent.prefab == "mushroom_light2" or ent.prefab == "plant_lightbulb_l" then
                if not ent:HasTag("burnt") and ent.components.container ~= nil then
                    local numitems = ent.components.container:NumItems()
                    local numslots = ent.components.container:GetNumSlots()
                    if numitems < numslots then
                        local num = numslots - numitems
                        for i = 1, num do
                            local spore = SpawnPrefab(GetRandomItem({
                                "spore_small", "spore_medium", "spore_tall"
                            }))
                            if spore ~= nil then
                                ent.components.container:GiveItem(spore)
                            end
                        end
                    end
                end
                if ent.components.perennialcrop2 ~= nil then --夜盏花！
                    ent.components.perennialcrop2:Cure(owner)
                end
            elseif ent.prefab == "mushroom_farm" then
                if ent.components.trader ~= nil and ent.components.trader.enabled and ent.remainingharvests ~= 0 then
                    local item = SpawnPrefab(GetRandomItem({
                        "spore_small", "spore_medium", "spore_tall", "albicans_cap"
                    }))
                    if item ~= nil then
                        ent.components.trader:AcceptGift(owner, item)
                        if item:IsValid() then
                            item:Remove()
                        end
                    end
                end
            elseif ent.prefab == "pot_whitewood" then
                if ent.components.trader ~= nil and ent.components.trader.enabled then
                    local item = SpawnPrefab(GetRandomItem({
                        "red_mushroomhat", "green_mushroomhat", "blue_mushroomhat", "hat_albicans_mushroom"
                    }))
                    if item ~= nil then
                        ent.legiontag_nocallback = true
                        ent.components.trader:AcceptGift(owner, item)
                        ent.legiontag_nocallback = nil
                        if item:IsValid() then
                            item:Remove()
                        end
                    end
                end
            elseif ent.components.perennialcrop ~= nil then
                ent.components.perennialcrop:Cure(owner)
            elseif ent.components.perennialcrop2 ~= nil then
                ent.components.perennialcrop2:Cure(owner)
            end
    	end
    end

    if owner.components.hunger ~= nil then
        owner.components.hunger:DoDelta(-30)
    end
    if owner.components.lootdropper ~= nil then
        local num = math.random(2, 5)
        for i = 1, num do
            owner.components.lootdropper:SpawnLootPrefab(GetRandomItem({
                "spore_small", "spore_medium", "spore_tall"
            }))
        end
    end
end

local function fn(Sim)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hat_albicans_mushroom")
    inst.AnimState:SetBuild("hat_albicans_mushroom")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("show_spoilage")
    inst:AddTag("icebox_valid")
    inst:AddTag("rp_fungus_l")
    inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制
    inst:AddTag("waterproofer")

    MakeInventoryFloatable(inst, "med", 0.25, 0.8)
    local OnLandedClient_old = inst.components.floater.OnLandedClient
    inst.components.floater.OnLandedClient = function(self)
        OnLandedClient_old(self)
        self.inst.AnimState:SetFloatParams(0.045, 1, self.bob_percent)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.releasedfn = ReleaseSporesEffect --存下来，在sg中调用
    inst.fxcolour = {255/255, 255/255, 255/255}
    inst.castsound = "dontstarve/pig/mini_game/cointoss"

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hat_albicans_mushroom"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hat_albicans_mushroom.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_MED) --0.5防潮

    inst:AddComponent("tradable")

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL) --凉爽60s
    inst.components.insulator:SetSummer()

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW) --15天新鲜度
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(inst.Remove)

    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(onuse)
    -- inst.components.useableitem:SetOnStopUseFn(onstopuse)

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab(function(inst)
        local spores = { "spore_tall", "spore_medium", "spore_small" }
        return spores[math.random(1, 3)]
    end)
    inst.components.periodicspawner:SetIgnoreFlotsamGenerator(true)
    inst.components.periodicspawner:SetRandomTimes(20, 1, true)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab( "hat_albicans_mushroom", fn, assets, prefabs)
