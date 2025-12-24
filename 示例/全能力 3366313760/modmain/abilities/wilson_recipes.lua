for name, data in pairs(AllRecipes) do
    if string.find(name, "transmute_") == 1 then
        data.builder_tag = nil
        data.builder_skill = nil
    end
end
