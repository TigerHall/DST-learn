TUNING.WANDERINGTRADER_SHOP_REFRESH_INTERVAL = TUNING.TOTAL_DAY_TIME * 16 -- 固定为16天刷新一次

-- 商人50%的时间在蚁狮沙漠中，累计交易次数达到200次后将会固定在玩家的基地周围


-- 配方添加和更改
AddRecipe2("wanderingtradershop_scrap_monoclehat", 
    {Ingredient("trinket_6", 3)}, 
    TECH.LOST, 
    {limitedamount = true, nounlock = true, actionstr="WANDERINGTRADERSHOP", sg_state="give", product="scrap_monoclehat"}
)
AddRecipe2("wanderingtradershop_honey", 
    {Ingredient("petals", 3)}, 
    TECH.LOST, 
    {limitedamount = true, nounlock = true, actionstr="WANDERINGTRADERSHOP", sg_state="give", product="honey"}
)
AddRecipe2("wanderingtradershop_silk", 
    {Ingredient("beardhair", 3)}, 
    TECH.LOST, 
    {limitedamount = true, nounlock = true, actionstr="WANDERINGTRADERSHOP", sg_state="give", product="silk"}
)
AddRecipePostInit("wanderingtradershop_gears",function(inst) 
    inst.ingredients = {Ingredient("wagpunk_bits", 3)} 
end)


-- 额外稀有交易，50% 概率出现，独立刷新
local RANDOM_RARES_2HM = {
    {
        ["scrap_monoclehat"] = {recipe = "wanderingtradershop_scrap_monoclehat", min = 1, max = 1,},
    },
    {
        ["honey"] = {recipe = "wanderingtradershop_honey", min = 8, max = 12, limit = 16},
    },
    {
        ["silk"] = {recipe = "wanderingtradershop_silk", min = 8, max = 12, limit = 16},
    },
}
local STARTER_2HM = {
    {
        ["scrap_monoclehat"] = {recipe = "wanderingtradershop_scrap_monoclehat", min = 2, max = 3, limit = 3,},
    },
}


-- 
AddPrefabPostInit("wanderingtrader", function(inst)
    if not TheWorld.ismastersim then return end
    inst.STARTER2HM = inst.WARES.STARTER -- 保存数据
    local RerollWares2hm = inst.RerollWares

    -- -- 遍历 WARES 表中的所有交易类别，增加交易次数 
    
    -- local function MultiplyEntry(entry, multiplier) -- 统一修改交易数量
    --     for _, data in pairs(entry) do
    --         if data.min then data.min = data.min * multiplier end
    --         if data.max then data.max = data.max * multiplier end
    --         if data.limit then data.limit = data.limit * multiplier end
    --     end
    -- end

    -- -- 自动处理所有交易类别（除STARTER外），兼容普通二三级结构
    -- for category, wares in pairs(inst.WARES) do
    --     if category ~= "STARTER" then
    --         -- SEASONAL和SPECIAL的实际结构也是数组（通过pairs遍历季节/条件后得到）
    --         if type(wares) == "table" then
    --             for _, entry in pairs(wares) do
    --                 if entry.min then -- 直接是物品数据（如SPECIAL）
    --                     MultiplyEntry({[1]=entry}, 4) -- 包装成统一格式
    --                 else -- 普通数组结构（ALWAYS, SEASONAL的子表等）
    --                     MultiplyEntry(entry, 4)
    --                 end
    --             end
    --         end
    --     end
    -- end
    -- 不会用for,直接覆盖
    inst.WARES = {
        STARTER = { -- NOTES(JBK): This is what is given to the shopkeep at the start of a new world in addition to a roll.
            {
                ["gears"] = {recipe = "wanderingtradershop_gears", min = 1, max = 1, limit = 1,},
            },
        },
        ALWAYS = { -- Make sure there is at least one trade that has min = 1 in this table.
            {
                ["flint"] = {recipe = "wanderingtradershop_flint", min = 4, max = 8, limit = 8,},
            }, -- This keeps code complexity down by having all of the formats the same table structure.
        },
        RANDOM_UNCOMMONS = {
            {
                ["gears"] = {recipe = "wanderingtradershop_gears", min = 1, max = 4, limit = 4,},
            },
            {
                ["pigskin"] = {recipe = "wanderingtradershop_pigskin", min = 1, max = 4,},
            },
            {
                ["livinglog"] = {recipe = "wanderingtradershop_livinglog", min = 1, max = 4,},
            },
        },
        RANDOM_RARES = {
            {
                ["redgem"] = {recipe = "wanderingtradershop_redgem", min = 1, max = 2,},
            },
            {
                ["bluegem"] = {recipe = "wanderingtradershop_bluegem", min = 1, max = 2,},
            },
        },
        SEASONAL = {
            [SEASONS.AUTUMN] = {
                ["cutgrass"] = {recipe = "wanderingtradershop_cutgrass", min = 4, max = 12, limit = 24,},
                ["twigs"] = {recipe = "wanderingtradershop_twigs", min = 4, max = 12, limit = 24,},
                ["cutreeds"] = {recipe = "wanderingtradershop_cutreeds", min = 1, max = 4, limit = 20,},
            },
            [SEASONS.WINTER] = {
                ["cutgrass"] = {recipe = "wanderingtradershop_cutgrass", min = 1, max = 4, limit = 8,},
                ["twigs"] = {recipe = "wanderingtradershop_twigs", min = 1, max = 4, limit = 8,},
            },
            [SEASONS.SPRING] = {
                ["cutgrass"] = {recipe = "wanderingtradershop_cutgrass", min = 8, max = 20, limit = 32,},
                ["twigs"] = {recipe = "wanderingtradershop_twigs", min = 8, max = 20, limit = 32,},
                ["cutreeds"] = {recipe = "wanderingtradershop_cutreeds", min = 8, max = 12, limit = 12,},
            },
            [SEASONS.SUMMER] = {
                ["cutgrass"] = {recipe = "wanderingtradershop_cutgrass", min = 2, max = 4, limit = 8,},
                ["twigs"] = {recipe = "wanderingtradershop_twigs", min = 2, max = 4, limit = 8,},
            },
        },
        SPECIAL = {
            ["islunarhailing"] = {
                ["moonglass"] = {recipe = "wanderingtradershop_moonglass", min = 8, max = 16, limit = 32,},
            },
        }
    }

    -- 添加额外的稀有交易
    inst.WARES.RANDOM_RARES_2HM = RANDOM_RARES_2HM or {}
    -- 替换初始交易
    inst.WARES.STARTER = STARTER_2HM

    -- 更新 FORGETABLE_RECIPES 列表
    for _, warebucket in pairs(inst.WARES) do
        for _, prefabdata in pairs(warebucket) do
            for prefab, waredata in pairs(prefabdata) do
                if not waredata.limit then
                    inst.FORGETABLE_RECIPES[waredata.recipe] = true
                end
            end
        end
    end

    -- 刷新时加入额外的稀有交易
    inst.RerollWares = function(inst)
        RerollWares2hm(inst)
        if math.random() < TUNING.WANDERINGTRADER_SHOP_RANDOM_UNCOMMON_ODDS then
            local rare_wares = inst.WARES.RANDOM_RARES_2HM[math.random(#inst.WARES.RANDOM_RARES_2HM)]
            if rare_wares then
                inst:AddWares(rare_wares)
            end
        end
    end
    
end)

-- 交易时将提示剩余数量
AddComponentPostInit("prototyper", function(self)
    local Activate2hm = self.Activate
    self.Activate = function(self, doer, recipe)
        if recipe and self.inst.components.craftingstation then
            self.inst.components.craftingstation.limit2hm = 
                (self.inst.components.craftingstation.recipecraftinglimit[recipe.name] or 0) - 1
        end
        Activate2hm(self, doer, recipe)
    end
end)


AddStategraphPostInit("wanderingtrader", function(sg)
    -- 覆盖商人交易后时的行为
    if sg.states.dotrade then
        sg.states.dotrade.onenter = function(inst, data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("trade_give")
            if data and data.no_stock then
                inst:DoChatter("WANDERINGTRADER_OUTOFSTOCK_FROMTRADES", math.random(#STRINGS.WANDERINGTRADER_OUTOFSTOCK_FROMTRADES), 15)
            else
                -- 告知剩余次数
                if inst.components.craftingstation and inst.components.craftingstation.limit2hm then
                    local remaining = inst.components.craftingstation.limit2hm 
                    inst.components.talker:Say(STRINGS.WANDERINGTRADER_DOTRADE[math.random(#STRINGS.WANDERINGTRADER_DOTRADE)] 
                        .. string.format("\n剩余 %d 次交易", remaining))
                else
                    inst:DoChatter("WANDERINGTRADER_DOTRADE", math.random(#STRINGS.WANDERINGTRADER_DOTRADE), 1.5)
                end
            end
            inst.SoundEmitter:PlaySound("dontstarve/characters/skincollector/ingame/trade") -- FIXME(JBK): WT: Sounds.
			inst:SetRevealed(true)
        end
    end
end)

