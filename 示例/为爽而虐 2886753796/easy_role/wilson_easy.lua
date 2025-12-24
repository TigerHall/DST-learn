local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- 威尔逊一本
if GetModConfigData("Wilson 1 Science Bonus") then
    AddPrefabPostInit("wilson", function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.builder.science_bonus = 1
    end)
end

-- 威尔逊二本
if GetModConfigData("Wilson 2 Science Bonus") and false then
    AddPrefabPostInit("wilson", function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.builder.science_bonus = 2
    end)
end

-- 威尔逊右键冲刺且只有1秒CD
if GetModConfigData("Wilson Right Dodge") then
    local cd = GetModConfigData("Wilson Right Dodge")
    cd = cd == true and 1 or cd
    AddPrefabPostInit("wilson", function(inst)
        AddDodgeAbility(inst)
        inst.rightaction2hm_cooldown = cd
    end)
end

-- 威尔逊右键科技书
if GetModConfigData("Wilson Right Self Everything Encyclopedia") then
    local cd = GetModConfigData("Wilson Right Self Everything Encyclopedia")
    cd = cd == true and 30 or cd
    AddReadBookRightSelfAction("wilson", "book_research_station", cd, STRINGS.RECIPE_DESC.BOOK_RESEARCH_STATION)
    STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.RIGHTSELFACTION2HM = STRINGS.CHARACTERS.GENERIC.ACTIONFAIL_GENERIC
end