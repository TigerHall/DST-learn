table.insert(PrefabFiles, "aab_heavyblade")

STRINGS.NAMES.AAB_HEAVYBLADE = AAB_L("Great Sword", "大剑")
for k, _ in pairs(STRINGS.CHARACTERS) do
    STRINGS.CHARACTERS[k].DESCRIBE.AAB_HEAVYBLADE = STRINGS.CHARACTERS[k].DESCRIBE.LAVAARENA_HEAVYBLADE
end
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AAB_HEAVYBLADE = STRINGS.CHARACTERS.GENERIC.DESCRIBE.LAVAARENA_HEAVYBLADE
STRINGS.RECIPE_DESC.AAB_HEAVYBLADE = AAB_L("It's a huge sword. It can do a lot of things.", "巨大的剑，可以用来做很多事情。")

----------------------------------------------------------------------------------------------------

AAB_AddCharacterRecipe("aab_heavyblade", { Ig("rocks", 4), Ig("flint", 4), Ig("goldnugget", 4) }, {
    image = "lavaarena_heavyblade.tex"
})
