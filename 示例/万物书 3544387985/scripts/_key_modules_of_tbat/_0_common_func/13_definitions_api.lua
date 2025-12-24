-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    使用函数 TBAT.FNS:modimport(lua_file_addr) 来加载MOD根目录的脚本。

    这么做的原因是为了方便某些不懂代码的操作者往指定列表添加内容。

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    TBAT.DEFINITION = Class()
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 重要的物品   
    function TBAT.DEFINITION:IsImportantItem(item_or_prefab)
        local prefab = nil
        if type(item_or_prefab) == "string" then
            prefab = item_or_prefab
        elseif type(item_or_prefab) == "table" then
            prefab = item_or_prefab.prefab
            -----------------------------------------------------------------------
            --- 实体判定
                if item_or_prefab.HasOneOfTags and item_or_prefab:HasOneOfTags({
                        "irreplaceable",
                        "nonpotatable",
                        "nosteal",
                        "chester_eyebone",
                        "hutch_fishbowl",
                    }) then
                        return true
                end
            -----------------------------------------------------------------------
        end
        if self.important_item_list == nil then
            self.important_item_list = TBAT.FNS:modimport("definitions/important_item_list.lua") or {}
        end
        return self.important_item_list[prefab] == true
    end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------