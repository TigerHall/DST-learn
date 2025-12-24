-- 小狼大厨
TBAT.RECIPE:AddRecipe("atbook_chefwolf",
    { Ingredient("tbat_material_snow_plum_wolf_heart", 1),Ingredient("tbat_material_white_plum_blossom", 10),Ingredient("tbat_material_wish_token", 10)  },
    TBAT.RECIPE:GetTech() or TECH.NONE,
    {
        placer = "atbook_chefwolf_placer",
        atlas = "images/inventoryimages/atbook_chefwolf.xml",
        image = "atbook_chefwolf.tex"
    },
    "building"
)

-- 自助点菜机
TBAT.RECIPE:AddRecipe("atbook_ordermachine",
    { Ingredient("tbat_material_snow_plum_wolf_heart", 1),Ingredient("tbat_material_snow_plum_wolf_hair", 10),Ingredient("tbat_material_miragewood", 20) },
    TBAT.RECIPE:GetTech() or TECH.NONE,
    {
        placer = "atbook_ordermachine_placer",
        atlas = "images/inventoryimages/atbook_ordermachine.xml",
        image = "atbook_ordermachine.tex"
    },
    "building"
)

-- 万物书
TBAT.RECIPE:AddRecipe("atbook_wiki",
    { Ingredient("tbat_material_emerald_feather", 1),Ingredient("tbat_material_miragewood", 8) },
    TBAT.RECIPE:GetTech() or TECH.NONE,
    {
        atlas = "images/inventoryimages/atbook_wiki.xml",
        image = "atbook_wiki.tex"
    },
    "item"
)
