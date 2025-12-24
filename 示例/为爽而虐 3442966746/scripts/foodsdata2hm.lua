local foods = {
    smallcandy2hm =
    {
        test = function(cooker, names, tags)
            local berrie_count = (names.berries or 0) + (names.berries_cooked or 0) + (names.berries_juicy or 0) + (names.berries_juicy_cooked or 0)
            return berrie_count >= 1 and not tags.inedible and not tags.monster and tags.sweetener and tags.fruit >= 1
        end,
        priority = 15,
        foodtype = FOODTYPE.GOODIES,
        health = 1,
        hunger = 5,
        perishtime = nil, --TUNING.PERISH_SUPERSLOW, -- not perishable
        sanity = 1,
        cooktime = .5,
        potlevel = "high",
        tags = {"honeyed"},
        stacksize = 3,
        prefabs = { "healthregenbuff2hm" },
        displayname_ch = "小糖豆",
        displayname_en = "small candy",
        description_ch = "来自反抗军蓝盒研发的新兵食品",
        description_en = "food made by LanHe from resistance army",
        oneat_desc_ch = "美味小糖豆~",
        oneat_desc_en = "delicious~",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("healthregenbuff2hm", "healthregenbuff2hm", {
                healthTick = 2 / 8, healthTimer = 16 / 8, healthTime = 120, sanityTick = 2 / 8, sanityTimer = 16 / 8, sanityTime = 120,
                removeOnHit = true, removeWords = TUNING.isCh2hm and "我会想你的,小糖豆" or "i will miss you, candy"
            })
        end,
        floater = {"small", nil, 0.85},
        warlyOnly = false,
    },

    nightberrymosse2hm =
    {
        test = function(cooker, names, tags)
            return (names.ancientfruit_nightvision or 0) >= 2 and (tags.fruit and tags.fruit >= 2) and not tags.meat and not tags.inedible
        end,
        priority = 30,
        foodtype = FOODTYPE.VEGGIE,
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_FASTISH,
        sanity = TUNING.SANITY_SMALL,
        cooktime = 1,
        potlevel = "low",
        prefabs = { "nightvisionbuff2hm" },
        displayname_ch = "夜莓慕斯",
        displayname_en = "Nightberry Mousse",
        description_ch = "用夜莓制作的精致慕斯",
        description_en = "An exquisite mousse made with nightberries",
        oneat_desc_ch = "像无尽的深渊一样旋转着。",
        oneat_desc_en = "The world spins like an endless abyss.",
        oneatenfn = function(inst, eater)
            if eater.components.playervision ~= nil then
                eater:AddDebuff("nightvisionbuff2hm", "nightvisionbuff2hm")
            end
        end,
        tags = { "masterfood" },
        floater = {nil, 0.1, 0.75},
        warlyOnly = true,
    },
}

for k, v in pairs(foods) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0

    if TUNING.isCh2hm then
        STRINGS.NAMES[string.upper(k)] = v.displayname_ch
        STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper(k)] = v.description_ch
        v.oneatdesc = v.oneat_desc_ch
    else
        STRINGS.NAMES[string.upper(k)] = v.displayname_en
        STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper(k)] = v.description_en
        v.oneatdesc = v.oneat_desc_en
    end

    v.atlasname = "images/inventoryimages/" .. k .. ".xml"
    v.build = k
    v.bank = k
    v.overridebuild = k
	-- v.cookbook_category = "cookpot"
end

return foods