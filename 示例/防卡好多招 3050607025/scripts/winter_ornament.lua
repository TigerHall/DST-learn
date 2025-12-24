--[[
冬季盛宴/万圣节物品清理
]]--

-- 所有物品的完整列表（冬季盛宴 + 万圣节）
local ALL_ITEMS = {
    -- 冬季盛宴基础零食
    "winter_food1", "winter_food2", "winter_food3", 
    "winter_food5", "winter_food6", "winter_food9",
    
    -- 冬季盛宴控温类零食
    "winter_food7", "winter_food8",
    
    -- 冬季盛宴永恒水果蛋糕
    "winter_food4",
    
    -- 冬季盛宴普通装饰（12种）
    "winter_ornament_plain1", "winter_ornament_plain2", "winter_ornament_plain3",
    "winter_ornament_plain4", "winter_ornament_plain5", "winter_ornament_plain6",
    "winter_ornament_plain7", "winter_ornament_plain8", "winter_ornament_plain9",
    "winter_ornament_plain10", "winter_ornament_plain11", "winter_ornament_plain12",
    
    -- 冬季盛宴精美装饰（8种）
    "winter_ornament_fancy1", "winter_ornament_fancy2", "winter_ornament_fancy3",
    "winter_ornament_fancy4", "winter_ornament_fancy5", "winter_ornament_fancy6",
    "winter_ornament_fancy7", "winter_ornament_fancy8",
    
    -- 冬季盛宴BOSS相关装饰
    "winter_ornament_boss_antlion",
    "winter_ornament_boss_bearger",
    "winter_ornament_boss_beequeen",
    "winter_ornament_boss_deerclops",
    "winter_ornament_boss_dragonfly",
    "winter_ornament_boss_fuelweaver",
    "winter_ornament_boss_klaus",
    "winter_ornament_boss_krampus",
    "winter_ornament_boss_moose",
    "winter_ornament_boss_noeyeblue",
    "winter_ornament_boss_noeyered",
    "winter_ornament_boss_toadstool",
    "winter_ornament_boss_toadstool_misery",
    "winter_ornament_boss_minotaur",
    "winter_ornament_boss_crabking",
    "winter_ornament_boss_crabkingpearl",
    "winter_ornament_boss_hermithouse",
    "winter_ornament_boss_pearl",
    "winter_ornament_boss_celestialchampion1",
    "winter_ornament_boss_celestialchampion2",
    "winter_ornament_boss_celestialchampion3",
    "winter_ornament_boss_celestialchampion4",
    "winter_ornament_boss_eyeofterror1",
    "winter_ornament_boss_eyeofterror2",
    "winter_ornament_boss_wagstaff",
    "winter_ornament_boss_malbatross",
    "winter_ornament_boss_wormboss",
    "winter_ornament_boss_sharkboi",
    "winter_ornament_boss_daywalker",
    "winter_ornament_boss_daywalker2",
    "winter_ornament_boss_mutateddeerclops",
    "winter_ornament_boss_mutatedbearger",
    "winter_ornament_boss_mutatedwarg",
    "winter_ornament_shadowthralls",
    "crumbs",
    
    -- 冬季盛宴灯饰（8种）
    -- "winter_ornament_light1", "winter_ornament_light2", "winter_ornament_light3",
    -- "winter_ornament_light4", "winter_ornament_light5", "winter_ornament_light6",
    -- "winter_ornament_light7", "winter_ornament_light8",
    
    -- 冬季盛宴节日装饰（5种）
    "winter_ornament_festivalevents1", "winter_ornament_festivalevents2",
    "winter_ornament_festivalevents3", "winter_ornament_festivalevents4",
    "winter_ornament_festivalevents5",
    
    -- 万圣节糖果（14种）
    "halloweencandy_1", "halloweencandy_2", "halloweencandy_3", "halloweencandy_4",
    "halloweencandy_5", "halloweencandy_6", "halloweencandy_7", "halloweencandy_8",
    "halloweencandy_9", "halloweencandy_10", "halloweencandy_11", "halloweencandy_12",
    "halloweencandy_13", "halloweencandy_14",
    
    -- 万圣节装饰（6种）
    "halloween_ornament_1", "halloween_ornament_2", "halloween_ornament_3",
    "halloween_ornament_4", "halloween_ornament_5", "halloween_ornament_6",
    
    -- 万圣节小玩具（编号32-46）
    "trinket_32", "trinket_33", "trinket_34", "trinket_35", "trinket_36",
    "trinket_37", "trinket_38", "trinket_39", "trinket_40", "trinket_41",
    "trinket_42", "trinket_43", "trinket_44", "trinket_45", "trinket_46"
}

--[[
移除指定prefab列表中的所有物品
参数：ALL_ITEMS - 需要移除的prefab名称列表
]]--
local function RemovePrefabs()
    for _, prefab in ipairs(ALL_ITEMS) do
        AddPrefabPostInit(prefab, function(inst) 
            if not TheWorld.ismastersim then
                return inst
            end
            inst:DoTaskInTime(30, function() 
                if not inst.inlimbo then 
                    inst:Remove()
                end
            end)
        end)
    end
end

-- 主逻辑：根据配置移除物品
RemovePrefabs()