local TOOLS_L = require("tools_legion")
local priority_low = 61
local priority_med = 91
local priority_hig = 121
local times = {
    m3 = TUNING.SEG_TIME*6,
    m6 = TUNING.SEG_TIME*12,
    m8 = TUNING.SEG_TIME*16,
    m12 = TUNING.SEG_TIME*24,
    m15 = TUNING.SEG_TIME*30 --通过食物获取的buff最多只有15分钟
}

------

local function OnIgniteFn_snail(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_fuse_LP", "hiss")
    DefaultBurnFn(inst)
end
local function OnExtinguishFn_snail(inst)
    inst.SoundEmitter:KillSound("hiss")
    DefaultExtinguishFn(inst)
end
local function OnExplodeFn_snail(inst)
    inst.SoundEmitter:KillSound("hiss")
    SpawnPrefab("explode_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function Desc_effortluck(inst, viewer)
    if viewer:HasAnyTag("playerghost", "mime") then --鬼魂或哑巴就不做操作了
        return
    end
    local res2 = GetString(viewer, "ANNOUNCE_BUFF_L_EFFORTLUCK", "CHECK")
    if res2 ~= nil then
        local res = GetDescription(viewer, inst, inst.components.inspectable:GetStatus(viewer))
        local luckvalue = viewer.legion_numeffortluck
        if luckvalue ~= nil then
            luckvalue = TOOLS_L.ODPoint(luckvalue, 100) --唉，数值计算总是会有奇怪小数点，没办法的事
        else
            luckvalue = 0
        end
        res2 = subfmt(res2, {luck = tostring(luckvalue)})
        return res.."\n"..res2
    end
end
local function FnServer_effortluck(inst)
    inst.components.inspectable.descriptionfn = Desc_effortluck
end
local function FnOnEaten_effortluck(inst, eater)
    eater:AddDebuff("buff_l_effortluck", "buff_l_effortluck")
end

local function BeCool(eater, temp) --直接降低体温，但不会过冷
    if eater.components.temperature ~= nil then
        local current = eater.components.temperature:GetCurrent()
        if current ~= nil and current > 5.1 then
            eater.components.temperature:SetTemperature(math.max(5.1, current-temp))
        end
    end
end

------

local foods_legion = {
    dish_duriantartare = { --怪味鞑靼
        test = function(cooker, names, tags) --烹饪配方函数
            return (names.durian or names.durian_cooked) and tags.meat and (tags.monster and tags.monster > 2)
        end,
        card_def = { ingredients = { {"durian",1}, {"monstermeat",2}, {"twigs",1} } }, --食谱卡的配方。为空时则无对应卡片产生
        priority = priority_med, --烹饪优先级。在烹饪条件都满足时，选择优先级最高的为结果。如果都一样按 weight 权重随机得到结果
        foodtype = FOODTYPE.MEAT, --食物类型
        secondaryfoodtype = FOODTYPE.MONSTER, --第二食物类型
        hunger = 62.5, sanity = 0, health = 0, --食用回复属性
        perishtime = TUNING.PERISH_FAST, --新鲜度。为空时代表无新鲜度
        -- temperature = TUNING.HOT_FOOD_BONUS_TEMP, --食用影响体温。大于0为升温，反之为降温。比较复杂最好借鉴官方数据
		-- temperatureduration = TUNING.FOOD_TEMP_AVERAGE, --食用后影响体温的时间。比较复杂最好借鉴官方数据
        -- cookpot_perishtime = 0, --在烹饪锅上的新鲜度时间，为空时则会使用 perishtime
        cooktime = 0.5, --烹饪时间。最终用时= cooktime*20，单位秒
        -- stacksize = 3, --一次烹饪出的料理数量。默认为1
        potlevel = "low", --在烹饪锅上所用的通道类型。用来控制料理与锅的相对高度。"high"(高)、空值(中)、"low"(低)
        float = { nil, "small", 0.2, 1.05 }, --(本mod专属)漂浮数据。底部切割比例、特效类型、特效高度、特效大小
        -- prefabs = { "buff_xxx" }, --所需要引用的预制物名
        -- tags = { "honeyed" }, --该料理额外添加的标签
        -- wet_prefix = STRINGS.WET_PREFIX.WETGOOP, --用来替换潮湿时的前缀
        -- fireproof = true, --(本mod专属)该料理是否防火
        -- oneat_desc = STRINGS.UI.COOKBOOK.DISH_FRENCHSNAILSBAKED, --食谱界面的食用效果的简述
        oneatenfn = function(inst, eater) --食用时会触发的特殊效果
            if eater:HasAnyTag("monster", "playermonster") then
                if eater.components.health ~= nil then
                    eater.components.health:DoDelta(30, nil, inst.prefab)
                end
                if eater.components.sanity ~= nil then
                    eater.components.sanity:DoDelta(10)
                end
            end
        end,
        -- fn_common = function(inst)end, --(本mod专属)预制物：服务器和客户端都会触发的函数
        -- fn_server = function(inst)end, --(本mod专属)预制物：仅服务器会触发的函数
        -- notinitprefab = true, --兼容勋章的机制。此配方，不以勋章的通用方式生成调料后预制物

        --以下参数为棱镜兼容所需。不写则不兼容
        cook_need = "(烤)榴莲 肉度 怪物度>2", --中文语言的料理配方，所需描述
        cook_cant = nil, --中文语言的料理配方，禁用描述
        recipe_count = 4 --需要使用多少种配方搭配才能完全解锁料理配方的描述。最多6，最少1。有的配方不一定有6种，所以不要乱写

        --以下参数，本mod不需要
        -- floater = { "med", 0.05, 0.65 }, --官方所用的漂浮数据
        -- OnPutInInventory = function(inst, owner)end, --放入物品栏时触发的函数。官方用来让玩家解锁一些无法食用料理的食谱数据
    },
    dish_merrychristmassalad = { --圣诞快乐沙拉
        test = function(cooker, names, tags)
            return names.twiggy_nut and names.corn and names.carrot and (tags.veggie and tags.veggie >= 3)
                    -- and (
                    --     tags.winterfeast or --一定要用or
                    --     CONFIGS_LEGION.FESTIVALRECIPES or IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) --冬季盛宴专属
                    -- )
        end,
        card_def = { ingredients = { {"twiggy_nut",1}, {"corn",1}, {"carrot",2} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 120, sanity = 5, health = 3,
        perishtime = TUNING.PERISH_SUPERFAST, --3天
        cooktime = 1,
        potlevel = "low",
        float = { nil, "small", 0.2, 1 },
        oneatenfn = function(inst, eater) --食用时，有33%几率获得一个小礼物
            if not TheWorld.state.iswinter and math.random() >= 0.33 then
                return
            end
            local items = {
                --普通
                "flint", "moonrocknugget", "silk", "nitre", "gears", "ice", "twigs", "rocks", "goldnugget",
                "cutgrass", "cutreeds", "beefalowool", "steelwool", "cattenball",
                "glommerfuel", "carrot", "corn", "twiggy_nut", "livinglog", "walrus_tusk", "honeycomb", "tentaclespots",
                "petals_rose", "petals_lily", "petals_orchid", "mint_l", "albicans_cap", "ahandfulofwings",
                "red_cap", "green_cap", "blue_cap", "spore_tall", "spore_medium", "spore_small", "insectshell_l",
                "merm_scales", "tourmalineshard", "cutted_rosebush", "cutted_lilybush", "cutted_orchidbush",
                "cutted_lumpyevergreen", "dug_monstrain", "pineananas",
                --贵重
                "redgem", "bluegem", "greengem", "orangegem", "yellowgem", "opalpreciousgem", "ancienttree_seed",
                "shyerry", "foliageath", "siving_derivant_item", "cutted_nightrosebush", "gnarwail_horn",
                --小生物
                "mole", "rabbit", "bee", "butterfly", "robin", "robin_winter", "canary", "oceanfish_medium_9_inv",
                "oceanfish_medium_8_inv", "fireflies", "oceanfish_small_6_inv", "oceanfish_small_7_inv",
                "oceanfish_small_8_inv", "lightcrab", "lightflier"
            }
            local oneofitems = SpawnPrefab(GetRandomItem(items))
            local item = {}
            table.insert(item, oneofitems)
            local gift = SpawnPrefab("gift")
            gift.components.unwrappable:WrapItems(item)
            oneofitems:Remove() --礼物包装完成，删除原本物品

            --选定食用者周围位置
            local pos = eater:GetPosition()
            local x, y, z = TOOLS_L.GetCalculatedPos(pos.x, 0, pos.z,
                eater:GetPhysicsRadius(0) + 0.7 + math.random()*0.5, math.random()*2*PI)
            if eater.SoundEmitter ~= nil then
                eater.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell")
                eater.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/chain")
                eater.SoundEmitter:PlaySound("dontstarve/common/dropGeneric")
            end

            --生成特效与礼物
            local fx = SpawnPrefab("sanity_lower")
            if TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) then --只在有效地面上生成
                fx.Transform:SetPosition(x, 0, z)
                gift.Transform:SetPosition(x, 0, z)
            else
                fx.Transform:SetPosition(pos:Get())
                gift.Transform:SetPosition(pos:Get())
            end
        end,

        cook_need = "多枝树种 玉米 萝卜 菜度≥3",
        cook_cant = nil,
        recipe_count = 4
    },
    dish_sugarlesstrickmakercupcakes = { --无糖捣蛋鬼纸杯蛋糕
        test = function(cooker, names, tags)
            return names.pumpkin and tags.egg and tags.magic and tags.monster and not tags.meat
                    -- and (
                    --     tags.hallowednights or --一定要用or
                    --     CONFIGS_LEGION.FESTIVALRECIPES or IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) --万圣节专属
                    -- )
        end,
        card_def = { ingredients = { {"pumpkin",1}, {"bird_egg",1}, {"nightmarefuel",1}, {"monstrain_leaf",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 62.5, sanity = 20, health = 0,
        perishtime = TUNING.PERISH_PRESERVED, --20天
        cooktime = 2.5,
        -- potlevel = nil,
        float = { nil, "small", 0.08, 1 },
        prefabs = { "buff_l_panicvolcano" },
        oneatenfn = function(inst, eater) --食用时，吸收周围没有携带糖的玩家的精神值加给自己，否则就偷走糖
            if eater.components.inventory == nil then
                return
            end

            local x1, y1, z1 = eater.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x1, y1, z1, 25, { "player" }, TOOLS_L.TagsCombat1())
            local sanitycount = 0
            for _, ent in ipairs(ents) do
                if
                    ent ~= eater and ent.entity:IsVisible() and
                    ent.components.health ~= nil and not ent.components.health:IsDead() and
                    ent.components.inventory ~= nil and ent.components.sanity ~= nil
                then
                    local sugar = ent.components.inventory:FindItem(function(item)
                        return item.components.edible ~= nil and item.components.edible.foodtype == FOODTYPE.GOODIES
                    end)
                    if sugar ~= nil then
                        local smallsugar = ent.components.inventory:DropItem(sugar, false)
                        if smallsugar ~= nil then
                            eater.components.inventory:GiveItem(smallsugar)
                        end
                        if ent.components.talker ~= nil then
                            ent.components.talker:Say(GetString(ent, "DESCRIBE", { "DISH_SUGARLESSTRICKMAKERCUPCAKES", "TREAT" }))
                        end
                    elseif ent.components.debuffable ~= nil and not ent.components.debuffable:HasDebuff("halloweenpotion_bravery_buff") then
                        if ent.components.sanity:GetPercent() <= 0 then
                            ent.components.health:DoDelta(-10, nil, inst.prefab)
                        else
                            ent.components.sanity:DoDelta(-30)
                        end
                        sanitycount = sanitycount + 1
                        ent:AddDebuff("buff_l_panicvolcano", "buff_l_panicvolcano")
                    end
                end
            end
            if sanitycount > 0 and eater.components.sanity ~= nil then
                eater.components.sanity:DoDelta(25 * sanitycount)
            end
        end,

        cook_need = "南瓜 蛋度 魔法度 怪物度",
        cook_cant = "肉度",
        recipe_count = 4
    },
    dish_l_mooncake = { --月饼
        test = function(cooker, names, tags)
            return
                tags.petals_legion and tags.petals_legion >= 2
                and tags.decoration and tags.sweetener
                and ( --秋季满月那天才能做出来
                    tags.fallfullmoon_l or --一定要用or
                    TheWorld and TheWorld.state and
                    TheWorld.state.moonphase == "full" and TheWorld.state.isautumn
                )
        end,
        -- card_def = { ingredients = { {"petals_rose",4} } },
        priority = priority_hig,
        foodtype = FOODTYPE.GOODIES,
        hunger = 52.5, sanity = 33, health = 0,
        -- perishtime = nil, --不会腐烂
        cooktime = 2,
        potlevel = "low",
        float = { 0.03, "small", 0.15, 0.6 },
        prefabs = { "buff_l_planardefense", "buff_l_lunarresist" },
        oneatenfn = function(inst, eater)
            eater:AddDebuff("buff_l_planardefense", "buff_l_planardefense", { value2 = 15 })
            eater:AddDebuff("buff_l_lunarresist", "buff_l_lunarresist", { value2 = 0.8 })
        end,

        cook_need = "花度≥2 装饰度 甜度",
        cook_cant = "秋季满月天专属",
        recipe_count = 6
    },
    dish_l_flowerbun = { --花儿粑
        test = function(cooker, names, tags)
            return
                tags.petals_legion and tags.petals_legion >= 2
                and tags.decoration and tags.sweetener
                and ( --满月那天才能做出来
                    tags.fullmoon_l or --一定要用or
                    TheWorld and TheWorld.state and TheWorld.state.moonphase == "full"
                )
        end,
        -- card_def = { ingredients = { {"petals_rose",4} } },
        priority = priority_hig - 1, --优先级比月饼低1点
        foodtype = FOODTYPE.GOODIES,
        hunger = 37.5, sanity = 15, health = 0,
        -- perishtime = nil, --不会腐烂
        cooktime = 1.5,
        -- potlevel = nil,
        float = { 0.03, "small", 0.2, 1.2 },
        prefabs = { "buff_l_planardefense", "buff_l_lunarresist" },
        oneatenfn = function(inst, eater)
            eater:AddDebuff("buff_l_planardefense", "buff_l_planardefense")
            eater:AddDebuff("buff_l_lunarresist", "buff_l_lunarresist")
        end,

        cook_need = "花度≥2 装饰度 甜度",
        cook_cant = "满月天专属",
        recipe_count = 6
    },
    -- dish_l_moonwine --月酿
    -- dish_l_flowerdop --花儿酒
    -- dish_l_shadowcake --暗糕
    -- dish_l_leafbun --叶儿粑
    -- dish_l_shadowwine --暗饮
    -- dish_l_leafdop --叶儿酒
    dish_farewellcupcake = { --临别的纸杯蛋糕
        test = function(cooker, names, tags)
            return (names.red_cap or names.red_cap_cooked) and tags.monster and tags.decoration
                and ( --新月那天才能做出来
                    tags.newmoon_l or --一定要用or
                    TheWorld and TheWorld.state and not TheWorld:HasTag("cave") --洞穴永远是新月，这里得多加个洞穴判定
                    and TheWorld.state.moonphase == "new"
                )
        end,
        -- card_def = { ingredients = { {"red_cap",1}, {"monstermeat",1}, {"butterflywings",1}, {"twigs",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 37.5, sanity = 72, health = 0,
        perishtime = TUNING.PERISH_PRESERVED, --20天
        cooktime = 1,
        potlevel = "low",
        float = { nil, "small", 0.12, 0.7 },
        oneatenfn = function(inst, eater) --食用者受到1000点的攻击伤害
            if eater.components.combat ~= nil then
                local damage = 1000
                --如果是一次性吃完类型的对象，伤害应该是整组算的
                if eater.components.eater and eater.components.eater.eatwholestack then
                    damage = damage * inst.components.stackable:StackSize()
                end
                eater.components.combat:GetAttacked(inst, damage)
            end
        end,

        cook_need = "(烤)红蘑菇 怪物度 装饰度",
        cook_cant = "新月天专属",
        recipe_count = 6
    },
    dish_braisedmeatwithfoliages = { --蕨叶扣肉
        test = function(cooker, names, tags)
            return (names.foliage and names.foliage >= 2) and (tags.meat and tags.meat >= 1)
                and not tags.inedible and not tags.sweetener
        end,
        card_def = { ingredients = { {"monstermeat",1}, {"foliage",3} } },
        priority = priority_med, --和【永不妥协】里的 simpsalad(优先级20、权重20) 冲突，这里调高优先级
        foodtype = FOODTYPE.MEAT,
        hunger = 62.5, sanity = 8, health = 10,
        perishtime = TUNING.PERISH_MED, --10天
        cooktime = 1,
        potlevel = "low",
        float = { 0.02, "small", 0.2, 1.1 },

        cook_need = "蕨叶≥2 肉度≥1",
        cook_cant = "非食 甜度",
        recipe_count = 6
    },
    dish_fleshnapoleon = { --真果拿破仑
        test = function(cooker, names, tags)
            return ((names.wormlight_lesser and names.wormlight_lesser >= 2) or names.wormlight) and names.foliage
                and not tags.meat
        end,
        card_def = { ingredients = { {"wormlight_lesser",2}, {"foliage",1}, {"twigs",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.GOODIES,
        hunger = 25, sanity = 10, health = 12,
        perishtime = TUNING.PERISH_SLOW, --15天
        cooktime = 2.5,
        -- potlevel = "low",
        float = { 0.02, "small", 0.2, 1.2 },
        prefabs = { "buff_l_radiantskin" },
        oneatenfn = function(inst, eater)
            eater:AddDebuff("buff_l_radiantskin", "buff_l_radiantskin", { value = times.m8, max = times.m15 })
        end,

        cook_need = "小发光浆果≥2/发光浆果 蕨叶",
        cook_cant = "肉度",
        recipe_count = 6
    },
    dish_beggingmeat = { --叫花焖肉
        test = function(cooker, names, tags)
            return names.ash and tags.meat and
                (not tags.monster or tags.monster <= 1) and not tags.sweetener and not tags.frozen
        end,
        card_def = { ingredients = { {"ash",1}, {"smallmeat",1}, {"twigs",2} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 37.5, sanity = 5, health = 0,
        perishtime = TUNING.PERISH_FAST, --6天
        cooktime = 0.75,
        potlevel = "low",
        float = { nil, "small", 0.2, 1 },
        oneatenfn = function(inst, eater) --角色低饱食吃下去时会有额外回复属性
            if eater:HasTag("player") then
                local hunger = eater.components.hunger
                if hunger ~= nil and (hunger.current - 37.5)/hunger.max <= 0.06 then --吃之前低饱食的话，增加回复属性
                    hunger:DoDelta(25)
                    if eater.components.health ~= nil then
                        eater.components.health:DoDelta(3, nil, inst.prefab)
                    end
                    if eater.components.sanity ~= nil then
                        eater.components.sanity:DoDelta(5)
                    end
                end
            end
        end,

        cook_need = "肉度 灰烬",
        cook_cant = "怪物度≤1 甜度 冰度",
        recipe_count = 6
    },
    dish_frenchsnailsbaked = { --法式焗蜗牛
        test = function(cooker, names, tags)
            return names.slurtleslime and names.cutlichen and tags.meat and (not tags.monster or tags.monster <= 1)
        end,
        card_def = { ingredients = { {"slurtleslime",1}, {"cutlichen",1}, {"smallmeat",1}, {"twigs",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 37.5, sanity = 33, health = 30,
        perishtime = TUNING.PERISH_SUPERFAST, --3天
        cooktime = 0.5,
        -- potlevel = nil,
        float = { nil, "small", 0.2, 1.05 },
        prefabs = { "explode_small" },
        fireproof = true,
        oneat_desc = STRINGS.UI.COOKBOOK.DISH_FRENCHSNAILSBAKED,
        fn_common = function(inst)
            inst.entity:AddSoundEmitter()
            inst:AddTag("explosive")
        end,
        fn_server = function(inst)
            MakeSmallBurnable(inst, 3 + math.random() * 3) --延时着火
            inst.components.burnable:SetOnBurntFn(nil)
            inst.components.burnable:SetOnIgniteFn(OnIgniteFn_snail)
            inst.components.burnable:SetOnExtinguishFn(OnExtinguishFn_snail)

            inst:AddComponent("explosive")
            inst.components.explosive:SetOnExplodeFn(OnExplodeFn_snail)
            inst.components.explosive.explosivedamage = TUNING.SLURTLESLIME_EXPLODE_DAMAGE
            inst.components.explosive.buildingdamage = 1
            inst.components.explosive.lightonexplode = false
        end,

        cook_need = "蛞蝓龟黏液 苔藓 肉度",
        cook_cant = "怪物度≤1",
        recipe_count = 6
    },
    dish_neworleanswings = { --新奥尔良烤翅
        test = function(cooker, names, tags)
            return (names.batwing or names.batwing_cooked) and (tags.meat and tags.meat >= 2) and
                (not tags.monster or tags.monster <= 2) and not names.horn --禁止牛角是为了兼容永不妥协的牛角派
        end,
        card_def = { ingredients = { {"batwing",1}, {"monstermeat",2}, {"twigs",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 120, sanity = 5, health = 3,
        perishtime = TUNING.PERISH_MED, --10天
        cooktime = 2,
        -- potlevel = nil,
        float = { nil, "small", 0.2, 1.05 },
        prefabs = { "buff_l_batdisguise" },
        oneatenfn = function(inst, eater)
            if eater.prefab ~= "bat" and eater.prefab ~= "molebat" then
                eater:AddDebuff("buff_l_batdisguise", "buff_l_batdisguise")
            end
        end,

        cook_need = "(烤)蝙蝠翅膀 肉度≥2",
        cook_cant = "怪物度≤2 牛角",
        recipe_count = 6
    },
    dish_fishjoyramen = { --鱼乐拉面
        test = function(cooker, names, tags)
            return (names.plantmeat or names.plantmeat_cooked) and tags.fish and
                (not tags.monster or tags.monster <= 1) and not tags.inedible and not tags.sweetener
        end,
        card_def = { ingredients = { {"plantmeat",1}, {"fishmeat_small",1}, {"berries",2} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 62.5, sanity = 15, health = 3,
        perishtime = TUNING.PERISH_MED, --10天
        cooktime = 0.5,
        potlevel = "low",
        float = { nil, "small", 0.2, 1 },
        prefabs = { "sand_puff" },
        oneatenfn = function(inst, eater) --玩家食用后拾取周围一组物品
            if eater == nil or eater.components.inventory == nil then
                return
            end
            local item = FindPickupableItem(eater, TUNING.ORANGEAMULET_RANGE, false)
            if item == nil then
                return
            end

            local didpickup = false
            if item.components.trap ~= nil then
                item.components.trap:Harvest(eater)
                didpickup = true
            end

            if eater.components.minigame_participator ~= nil then
                local minigame = eater.components.minigame_participator:GetMinigame()
                if minigame ~= nil then
                    minigame:PushEvent("pickupcheat", { cheater = eater, item = item })
                end
            end

            SpawnPrefab("sand_puff").Transform:SetPosition(item.Transform:GetWorldPosition())
            if not didpickup then
                eater.components.inventory:GiveItem(item, nil, item:GetPosition())
            end
        end,

        cook_need = "(烤)叶肉 鱼度",
        cook_cant = "怪物度≤1 非食 甜度",
        recipe_count = 6
    },
    dish_roastedmarshmallows = { --烤棉花糖
        test = function(cooker, names, tags)
            return names.glommerfuel and tags.sweetener and names.twigs and
                not tags.meat and not tags.frozen and not tags.egg
        end,
        card_def = { ingredients = { {"glommerfuel",1}, {"honey",1}, {"twigs",2} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 18.75, sanity = 5, health = 60,
        perishtime = TUNING.PERISH_MED * 3, --30天
        cooktime = 0.5,
        potlevel = "low",
        float = { nil, "small", 0.2, 0.7 },
        tags = { "honeyed" },

        cook_need = "格罗姆黏液 甜度 树枝",
        cook_cant = "肉度 冰度 蛋度",
        recipe_count = 6
    },
    dish_pomegranatejelly = { --石榴子果冻
        test = function(cooker, names, tags)
            return (names.pomegranate or names.pomegranate_cooked) and
                (tags.gel or names.slurtleslime or names.glommerfuel or names.phlegm) and
                not tags.veggie and not tags.meat and not tags.egg
        end,
        card_def = { ingredients = { {"pomegranate",1}, {"phlegm",1}, {"twigs",2} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 37.5, sanity = 50, health = 3,
        perishtime = TUNING.PERISH_SLOW, --15天
        cooktime = 3,
        potlevel = "low",
        float = { nil, "small", 0.2, 1.05 },

        cook_need = "(烤)石榴 黏液度",
        cook_cant = "菜度 肉度 蛋度",
        recipe_count = 6
    },
    dish_medicinalliquor = { --药酒
        test = function(cooker, names, tags)
            return names.furtuft and tags.frozen and not tags.meat and not tags.sweetener
                and not tags.egg and (not tags.inedible or tags.inedible <= 1)
        end,
        card_def = { ingredients = { {"furtuft",1}, {"ice",3} } },
        priority = priority_med,
        foodtype = FOODTYPE.GOODIES,
        hunger = 9.375, sanity = 10, health = 8,
        -- perishtime = nil, --不会腐烂
        cooktime = 3,
        potlevel = "low",
        float = { nil, "small", 0.2, 0.85 },
        prefabs = { "buff_l_strengthenhancer" },
        oneatenfn = function(inst, eater)
            --加强攻击力
            if eater.components.combat ~= nil then --这个buff需要攻击组件
                eater:AddDebuff("buff_l_strengthenhancer", "buff_l_strengthenhancer")
            end
            --醉酒
            if eater:HasTag("player") then
                if eater.components.talker ~= nil then --说醉酒话
                    eater.components.talker:Say(GetString(eater, "DESCRIBE", { "DISH_MEDICINALLIQUOR", "DRUNK" }))
                end
                local drunkmap = {
                    wathgrithr = 0, wolfgang = 0, warly = 0, --酒量好
                    wormwood = 0, wx78 = 0, --身体结构不一样
                    wendy = 1, webber = 1, willow = 1, wes = 1, wurt = 1, walter = 1, --酒量差
                    yangjian = 0, yama_commissioners = 0, myth_yutu = 1 --mod人物
                }
                if drunkmap[eater.prefab] == 0 then --没有任何事
                    return
                elseif drunkmap[eater.prefab] == 1 then --直接睡着8-12秒
                    eater:PushEvent("yawn", { grogginess = 5, knockoutduration = 8+math.random()*4 })
                else --晕乎乎15秒
                    eater:AddDebuff("buff_l_dizzy", "buff_l_dizzy")
                end
            elseif eater.components.sleeper ~= nil then
                eater.components.sleeper:AddSleepiness(5, 12+math.random()*4)
            elseif eater.components.grogginess ~= nil then
                eater.components.grogginess:AddGrogginess(5, 12+math.random()*4)
            else
                eater:PushEvent("knockedout")
            end
        end,

        cook_need = "毛丛 冰度",
        cook_cant = "肉度 甜度 蛋度 非食≤1",
        recipe_count = 6
    },
    dish_bananamousse = { --香蕉慕斯
        test = function(cooker, names, tags)
            return (names.cave_banana or names.cave_banana_cooked) and (tags.fruit and tags.fruit > 1) and tags.egg
                and not tags.meat and not tags.inedible and not tags.monster
        end,
        card_def = { ingredients = { {"cave_banana",1}, {"berries",2}, {"bird_egg",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.GOODIES,
        hunger = 9.375, sanity = 5, health = 8,
        perishtime = TUNING.PERISH_MED, --10天
        cooktime = 0.75,
        stacksize = 2,
        potlevel = "low",
        float = { nil, "small", 0.2, 0.9 },
        prefabs = { "buff_l_bestappetite" },
        oneatenfn = function(inst, eater)
            eater:AddDebuff("buff_l_bestappetite", "buff_l_bestappetite")
        end,

        cook_need = "(烤)香蕉 果度>1 蛋度",
        cook_cant = "肉度 非食 怪物度",
        recipe_count = 6
    },
    dish_friedfishwithpuree = { --果泥香煎鱼
        test = function(cooker, names, tags)
            return names.fig and (names.oceanfish_small_3_inv or names.oceanfish_medium_9_inv)
                and not names.twigs
        end,
        card_def = { ingredients = { {"oceanfish_medium_9_inv",1}, {"fig",1}, {"butterflywings",2} } },
        priority = 666,
        foodtype = FOODTYPE.MEAT,
        secondaryfoodtype = FOODTYPE.ROUGHAGE,
        hunger = 66, sanity = 6, health = 6,
        perishtime = TUNING.PERISH_SUPERFAST, --3天
        cooktime = 0.75,
        -- potlevel = nil,
        float = { 0.02, "small", 0.2, 1.1 },
        prefabs = { "buff_l_oilflow" },
        oneatenfn = function(inst, eater)
            eater:AddDebuff("buff_l_oilflow", "buff_l_oilflow")
        end,

        cook_need = "无花果 小饵鱼/甜味鱼",
        cook_cant = "树枝",
        recipe_count = 6
    },
    dish_lovingrosecake = { --倾心玫瑰酥
        test = function(cooker, names, tags)
            return names.petals_rose and names.reviver and not tags.monster
        end,
        card_def = { ingredients = { {"reviver",1}, {"petals_rose",1}, {"twigs",2} } },
        priority = priority_med,
        foodtype = FOODTYPE.GOODIES,
        secondaryfoodtype = FOODTYPE.ROUGHAGE,
        hunger = 13, sanity = 14, health = 20,
        perishtime = 10000*TUNING.TOTAL_DAY_TIME,
        cooktime = 1,
        -- potlevel = nil,
        float = { nil, "small", 0.12, 1 },
        oneat_desc = STRINGS.UI.COOKBOOK.DISH_LOVINGROSECAKE,
        fn_common = function(inst)
            inst.lovepoint_l = 1
        end,

        cook_need = "蔷薇花瓣 告密的心",
        cook_cant = "怪物度",
        recipe_count = 6
    },
    dish_mushedeggs = { --双菇烩蛋
        test = function(cooker, names, tags)
            local nn = {}
            for k, v in pairs(names) do --Tip: 对于工艺锅（Craft Pot）模组，换个变量来判定，才能不用被展示
                nn[k] = v
            end
            local mush = ((nn.red_cap or nn.red_cap_cooked) and 1 or 0) +
                ((nn.green_cap or nn.green_cap_cooked) and 1 or 0) +
                ((nn.blue_cap or nn.blue_cap_cooked) and 1 or 0) +
                ((nn.moon_cap or nn.moon_cap_cooked) and 1 or 0) +
                ((nn.albicans_cap or nn.albicans_cap_cooked) and 1 or 0)
            local egg = (nn.tallbirdegg or 0) + (nn.tallbirdegg_cooked or 0)
            return ( --实在没办法了，就这样吧，将就用，反正我不想为了兼容料理展示模组而修改这个配方
                    tags.tallbirdegg_legion and tags.tallbirdegg_legion >= 2 and
                    tags.mushroom_legion and tags.mushroom_legion >= 2
                ) or (mush >= 2 and egg >= 2)
        end,
        card_def = { ingredients = { {"tallbirdegg",2}, {"red_cap",1}, {"blue_cap",1} } },
        priority = priority_hig,
        foodtype = FOODTYPE.GOODIES,
        hunger = 60, sanity = 10, health = 0,
        perishtime = 3*TUNING.PERISH_MED, --30天
        cooktime = 0.5,
        potlevel = "low",
        float = { 0.02, "small", 0.2, 1.1 },
        prefabs = { "buff_l_effortluck" },
        oneatenfn = FnOnEaten_effortluck,
        fn_server = FnServer_effortluck,

        cook_need = "(烤)高脚鸟蛋≥2 蘑菇种类≥2",
        cook_cant = nil,
        recipe_count = 5
    },
    dish_mushedkoi = { --菌鱼双鲜堡
        test = function(cooker, names, tags)
            local nn = {}
            for k, v in pairs(names) do --Tip: 对于工艺锅（Craft Pot）模组，换个变量来判定，才能不用被展示
                nn[k] = v
            end
            local mush = ((nn.red_cap or nn.red_cap_cooked) and 1 or 0) +
                ((nn.green_cap or nn.green_cap_cooked) and 1 or 0) +
                ((nn.blue_cap or nn.blue_cap_cooked) and 1 or 0) +
                ((nn.moon_cap or nn.moon_cap_cooked) and 1 or 0) +
                ((nn.albicans_cap or nn.albicans_cap_cooked) and 1 or 0)
            return names.oceanfish_medium_7_inv and names.oceanfish_medium_6_inv and
                ((tags.mushroom_legion and tags.mushroom_legion >= 2) or mush >= 2)
        end,
        card_def = { ingredients = { {"oceanfish_medium_7_inv",1}, {"oceanfish_medium_6_inv",1}, {"green_cap",1}, {"blue_cap",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.GOODIES,
        hunger = 30, sanity = 0, health = 40,
        perishtime = 3*TUNING.PERISH_MED, --30天
        cooktime = 1,
        -- potlevel = "low",
        float = { nil, "small", 0.1, 1.1 },
        prefabs = { "buff_l_effortluck" },
        oneat_desc = STRINGS.UI.COOKBOOK.DISH_MUSHEDEGGS,
        oneatenfn = FnOnEaten_effortluck,
        fn_server = FnServer_effortluck,

        cook_need = "金锦鲤 花锦鲤 蘑菇种类≥2",
        cook_cant = nil,
        recipe_count = 5
    },
    dish_mushedmilk = { --香蕈双峰
        test = function(cooker, names, tags)
            local nn = {}
            for k, v in pairs(names) do --Tip: 对于工艺锅（Craft Pot）模组，换个变量来判定，才能不用被展示
                nn[k] = v
            end
            local mush = ((nn.red_cap or nn.red_cap_cooked) and 1 or 0) +
                ((nn.green_cap or nn.green_cap_cooked) and 1 or 0) +
                ((nn.blue_cap or nn.blue_cap_cooked) and 1 or 0) +
                ((nn.moon_cap or nn.moon_cap_cooked) and 1 or 0) +
                ((nn.albicans_cap or nn.albicans_cap_cooked) and 1 or 0)
            return tags.dairy and tags.dairy >= 2 and
                ((tags.mushroom_legion and tags.mushroom_legion >= 2) or mush >= 2)
        end,
        card_def = { ingredients = { {"goatmilk",2}, {"red_cap",1}, {"green_cap",1} } },
        priority = priority_hig,
        foodtype = FOODTYPE.GOODIES,
        hunger = 12, sanity = 50, health = 8,
        perishtime = 3*TUNING.PERISH_MED, --30天
        cooktime = 0.5,
        -- potlevel = "low",
        float = { 0.02, "small", 0.2, 1.2 },
        prefabs = { "buff_l_effortluck" },
        oneat_desc = STRINGS.UI.COOKBOOK.DISH_MUSHEDEGGS,
        oneatenfn = FnOnEaten_effortluck,
        fn_server = FnServer_effortluck,

        cook_need = "乳度≥2 蘑菇种类≥2",
        cook_cant = nil,
        recipe_count = 5
    },
    ------花香四溢
    dish_chilledrosejuice = { --蔷薇冰果汁
        test = function(cooker, names, tags)
            return (names.petals_rose and names.petals_rose > 1) and tags.frozen and (tags.fruit and tags.fruit >= 1)
                and not tags.meat and not tags.monster
        end,
        card_def = { ingredients = { {"petals_rose",2}, {"ice",1}, {"pineananas",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 12.5, sanity = 25, health = 45,
        perishtime = TUNING.PERISH_SUPERFAST, --3天
        temperature = TUNING.COLD_FOOD_BONUS_TEMP,
        temperatureduration = TUNING.FOOD_TEMP_AVERAGE,
        cooktime = 0.5,
        potlevel = "low",
        float = { nil, "small", 0.2, 0.7 },
        prefabs = { "flower_rose", "flower" },
        oneatenfn = function(inst, eater) --食用后产生花朵
            local pos = eater:GetPosition()
            local flower = nil
            local ran = math.random()

            if ran <= 0.11 then
                flower = SpawnPrefab("flower_rose")
            elseif ran <= 0.33 then
                flower = SpawnPrefab("flower")
            end
            if flower ~= nil and pos ~= nil then
                flower.Transform:SetPosition(pos:Get())
                flower.planted = true
            end
        end,

        cook_need = "蔷薇花瓣>1 冰度 果度≥1",
        cook_cant = "肉度 怪物度",
        recipe_count = 4
    },
    dish_twistedrolllily = { --蹄莲花卷
        test = function(cooker, names, tags)
            return (names.petals_lily and names.petals_lily > 1) and (tags.meat and tags.meat >= 1) and
                (tags.veggie and tags.veggie >= 2)
        end,
        card_def = { ingredients = { {"petals_lily",2}, {"monstermeat",1}, {"corn",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 62.5, sanity = 35, health = -3,
        perishtime = TUNING.PERISH_MED, --10天
        cooktime = 1,
        potlevel = "low",
        float = { nil, "small", 0.2, 1.05 },
        prefabs = { "butterfly", "moonbutterfly" },
        oneatenfn = function(inst, eater) --食用产生蝴蝶
            local pos = eater:GetPosition()
            local fly = nil
            local ran = math.random()

            if ran <= 0.1 then
                fly = SpawnPrefab("moonbutterfly")
            elseif ran <= 0.5 then
                fly = SpawnPrefab("butterfly")
            end
            if fly ~= nil and pos ~= nil then
                fly.Transform:SetPosition(pos:Get())
                fly.sg:GoToState("idle")
            end
        end,

        cook_need = "蹄莲花瓣>1 肉度≥1 菜度≥2",
        cook_cant = nil,
        recipe_count = 6
    },
    dish_orchidcake = { --兰花糕
        test = function(cooker, names, tags)
            return (names.petals_orchid and names.petals_orchid > 1) and (tags.veggie and tags.veggie >= 1.5) and
                tags.fruit and not tags.meat and not tags.monster
        end,
        card_def = { ingredients = { {"petals_orchid",2}, {"red_cap",1}, {"berries",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 75, sanity = 0, health = 10,
        perishtime = TUNING.PERISH_PRESERVED, --20天
        cooktime = 2,
        potlevel = "low",
        float = { nil, "small", 0.2, 1.05 },
        oneatenfn = function(inst, eater) --食用改变玩家体温
            if eater.components.temperature ~= nil then
                local current = eater.components.temperature:GetCurrent()
                if current == nil then return end

                if TheWorld.state.iswinter and current < 60 then
                    eater.components.temperature:SetTemperature(60) --冬季加体温
                elseif TheWorld.state.issummer and current > 10 then
                    eater.components.temperature:SetTemperature(10) --夏季降体温
                elseif not TheWorld.state.iswinter and not TheWorld.state.issummer then
                    eater.components.temperature:SetTemperature(35) --春秋平体温
                end
            end
        end,

        cook_need = "兰草花瓣>1 菜度≥1.5 果度",
        cook_cant = "肉度 怪物度",
        recipe_count = 6
    },
    ------祈雨祭
    dish_ricedumpling = { --金黄香粽
        test = function(cooker, names, tags)
            return names.monstrain_leaf and (tags.veggie and tags.veggie >= 2.5) and tags.egg and not tags.meat
        end,
        card_def = { ingredients = { {"monstrain_leaf",1}, {"corn",2}, {"bird_egg",1} } },
        priority = priority_med, --和【永不妥协】里的 um_deviled_eggs(优先级52) 冲突，这里调高优先级
        foodtype = FOODTYPE.VEGGIE,
        hunger = 62.5, sanity = 5, health = 3,
        perishtime = TUNING.PERISH_SLOW, --15天
        cooktime = 2.5,
        potlevel = "low",
        float = { nil, "small", 0.2, 1.05 },
        prefabs = { "buff_l_hungerretarder", "buff_l_holdbackpoop" },
        oneatenfn = function(inst, eater)
            if eater.components.hunger ~= nil then
                eater:AddDebuff("buff_l_hungerretarder", "buff_l_hungerretarder")
            end
            if eater.components.periodicspawner ~= nil then
                eater:AddDebuff("buff_l_holdbackpoop", "buff_l_holdbackpoop")
            end
        end,

        cook_need = "雨竹叶 菜度≥2.5 蛋度",
        cook_cant = "肉度",
        recipe_count = 6
    },
    dish_beancongee = { --清豆粥
        test = function(cooker, names, tags)
            return (names.bean_l_ice and names.bean_l_ice > 1) and (tags.frozen and tags.frozen >= 3) and
                not tags.meat
        end,
        card_def = { ingredients = { {"bean_l_ice",2}, {"ice", 2} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 20, sanity = 0, health = 40,
        perishtime = TUNING.PERISH_FAST, --6天
        cooktime = 1,
        potlevel = "low",
        float = { nil, "small", 0.2, 0.95 },
        oneatenfn = function(inst, eater)
            BeCool(eater, 35)
            if eater:HasDebuff("buff_l_cool") then --能给凉爽buff续3分钟，但不会超过15分钟
                eater:AddDebuff("buff_l_cool", "buff_l_cool", { value = times.m3, max = times.m15 })
            end
        end,
        fn_common = function(inst)
            inst:AddTag("frozen") --放入冰冷容器后就会保鲜
        end,

        cook_need = "冰皂豆>1 冰度≥3",
        cook_cant = "肉度",
        recipe_count = 6
    },
    dish_seedscongee = { --春来多喜粥
        test = function(cooker, names, tags)
            return names.bean_l_ice and names.twiggy_nut and names.squamousfruit and (names.acorn or names.acorn_cooked)
        end,
        card_def = { ingredients = { {"bean_l_ice",1}, {"twiggy_nut",1}, {"squamousfruit",1}, {"acorn",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.VEGGIE,
        hunger = 37.5, sanity = 33, health = 60,
        perishtime = TUNING.PERISH_MED, --10天
        cooktime = 2,
        potlevel = "low",
        float = { nil, "small", 0.15, 0.95 },
        oneatenfn = function(inst, eater)
            if eater.components.health ~= nil and eater.components.eater ~= nil and
                (eater.components.eater.healthabsorption or 1) <= 0.1 and eater.components.health:IsHurt()
            then --食物血量吸收效率极低的，就能额外恢复血量
                eater.components.health:DoDelta(30, nil, inst.prefab)
            end
            local cpt = eater.components.bloomness
            if cpt ~= nil then --给植物人增加2天开花状态。植物人一个阶段就是一天，最终是默认基础3天持续时间
                local time = cpt.stage_duration * 2
                if eater.components.skilltreeupdater ~= nil and
                    eater.components.skilltreeupdater:IsActivated("wormwood_blooming_max_upgrade")
                then
                    time = time * TUNING.WORMWOOD_BLOOM_MAX_UPGRADE_MULT --1.3
                end
                if cpt.level <= 0 then
                    time = time - cpt.stage_duration*2
                elseif cpt.level == 1 then
                    time = time - cpt.timer - cpt.stage_duration
                elseif cpt.level == 2 then
                    time = time - cpt.timer
                end
                if cpt.level < cpt.max then
                    cpt.timer = time --之前的时间全部不要了，满级时的阶段和前面的，代表的含义不一样
                    cpt:SetLevel(cpt.max)
                else
                    cpt.timer = cpt.timer + time
                    if cpt.calcfullbloomdurationfn ~= nil then --这里运行一遍，是为了限制 cpt.timer 的大小
                        cpt.timer = cpt.calcfullbloomdurationfn(eater, 0, cpt.timer, cpt.full_bloom_duration) or cpt.timer
                    end
                end
            end
        end,
        fn_common = function(inst)
            inst:AddTag("frozen") --放入冰冷容器后就会保鲜
        end,

        cook_need = "冰皂豆 多枝树种 鳞果 (烤)桦栗果",
        cook_cant = nil,
        recipe_count = 1
    },
    ------丰饶传说
    dish_murmurananas = { --松萝咕咾肉
        test = function(cooker, names, tags)
            return (names.pineananas or names.pineananas_cooked) and (tags.meat and tags.meat >= 2) and
                (not tags.monster or tags.monster <= 1)
        end,
        card_def = { ingredients = { {"pineananas",1}, {"meat",1}, {"monstermeat",1}, {"twigs",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 150, sanity = 12.5, health = 18,
        perishtime = TUNING.PERISH_MED,
        cooktime = 1,
        potlevel = "low",
        float = { nil, "small", 0.2, 1.05 },

        cook_need = "(烤)松萝 肉度≥2",
        cook_cant = "怪物度≤1",
        recipe_count = 6
    },
    dish_sosweetjarkfruit = { --甜到裂开的松萝蜜
        test = function(cooker, names, tags)
            return names.pineananas and tags.frozen and (tags.sweetener and tags.sweetener >= 2)
                and not tags.monster and not tags.meat
        end,
        card_def = { ingredients = { {"pineananas",1}, {"ice",1}, {"honey",2} } },
        priority = priority_med, --得比太真mod的奇异甜食优先级高，防止被顶替
        foodtype = FOODTYPE.VEGGIE,
        hunger = 18, sanity = 24, health = 0,
        perishtime = TUNING.PERISH_MED * 3,
        cooktime = 0.5,
        stacksize = 2,
        potlevel = "low",
        float = { 0.02, "small", 0.2, 0.9 },
        tags = { "honeyed" },

        cook_need = "松萝 冰度 甜度≥2",
        cook_cant = "怪物度 肉度",
        recipe_count = 2
    },
    ------电闪雷鸣
    dish_wrappedshrimppaste = { --白菇虾滑卷
        test = function(cooker, names, tags)
            return names.wobster_sheller_land and names.albicans_cap and (tags.decoration and tags.decoration >= 1)
                and not tags.fruit and not tags.monster
        end,
        card_def = { ingredients = { {"albicans_cap",1}, {"wobster_sheller_land",1}, {"butterflywings",1}, {"twigs",1} } },
        priority = priority_med,
        foodtype = FOODTYPE.MEAT,
        hunger = 37.5, sanity = 40, health = 45,
        perishtime = TUNING.PERISH_FASTISH, --8天
        cooktime = 0.75,
        stacksize = 2,
        -- potlevel = nil,
        float = { 0.01, "small", 0.2, 1.2 },
        prefabs = { "buff_l_sporeresistance" },
        oneatenfn = function(inst, eater)
            eater:AddDebuff("buff_l_sporeresistance", "buff_l_sporeresistance", { value = TUNING.SEG_TIME*24 })
        end,

        cook_need = "龙虾 素白菇 装饰度≥1",
        cook_cant = "果度 怪物度",
        recipe_count = 4
    },
    ------尘世蜃楼
    dish_shyerryjam = { --颤栗果酱
        test = function(cooker, names, tags)
            return names.shyerry and not tags.veggie and not tags.monster
                and not tags.egg and not tags.meat and not tags.inedible and not tags.frozen
        end,
        card_def = { ingredients = { {"shyerry",1}, {"honey",3} } },
        priority = priority_med,
        foodtype = FOODTYPE.GOODIES,
        hunger = 12.5, sanity = 5, health = 0,
        -- perishtime = nil, --不会腐烂
        cooktime = 3,
        stacksize = 2,
        potlevel = "low",
        float = { nil, "small", 0.25, 0.8 },
        prefabs = { "buff_l_healthstorage" },
        oneatenfn = function(inst, eater)
            if eater.components.oldager == nil and eater.components.health ~= nil then
                eater:AddDebuff("buff_l_healthstorage", "buff_l_healthstorage")
            end
        end,

        cook_need = "颤栗果",
        cook_cant = "菜/怪物/蛋/肉/冰度 非食",
        recipe_count = 4
    }

	--[[
        CALORIES_TINY = calories_per_day/8, -- berries --9.375
        CALORIES_SMALL = calories_per_day/6, -- veggies --12.5
        CALORIES_MEDSMALL = calories_per_day/4, --18.75
        CALORIES_MED = calories_per_day/3, -- meat --25
        CALORIES_LARGE = calories_per_day/2, -- cooked meat --37.5
        CALORIES_HUGE = calories_per_day, -- crockpot foods? --75
        CALORIES_SUPERHUGE = calories_per_day*2, -- crockpot foods? --150

        HEALING_TINY = 1,
        HEALING_SMALL = 3,
        HEALING_MEDSMALL = 8,
        HEALING_MED = 20,
        HEALING_MEDLARGE = 30,
        HEALING_LARGE = 40,
        HEALING_HUGE = 60,
        HEALING_SUPERHUGE = 100,

        SANITY_SUPERTINY = 1,
        SANITY_TINY = 5,
        SANITY_SMALL = 10,
        SANITY_MED = 15,
        SANITY_MEDLARGE = 20,
        SANITY_LARGE = 33,
        SANITY_HUGE = 50,

        PERISH_ONE_DAY = 1*total_day_time*perish_warp, --1天
        PERISH_TWO_DAY = 2*total_day_time*perish_warp, --2天
        PERISH_SUPERFAST = 3*total_day_time*perish_warp,
        PERISH_FAST = 6*total_day_time*perish_warp,
        PERISH_FASTISH = 8*total_day_time*perish_warp,
        PERISH_MED = 10*total_day_time*perish_warp,
        PERISH_SLOW = 15*total_day_time*perish_warp,
        PERISH_PRESERVED = 20*total_day_time*perish_warp,
        PERISH_SUPERSLOW = 40*total_day_time*perish_warp, --40天
	]]--
}

------
------

for k, v in pairs(foods_legion) do
    v.name = k
    if v.weight == nil then
        v.weight = 1
    end
    if v.priority == nil then
        v.priority = priority_low
    end
    if v.overridebuild == nil then --替换料理build。这样所有料理都可以共享一个build了，默认与料理名同名
        --[[ Tip：由于官方烹饪锅、香料站的prefab定义时会直接往Assets中加入 overridebuild 对应的文件，
                但由于 overridebuild 是模组才有的文件，加载时间在官方烹饪锅、香料站之后！就会因为
                此时模组文件还未加载，直接在日志中报错 Error: Could not find file: anim/文件名.zip
                不过此报错只是警告，不会对游戏有大的影响，唯一可能的影响是会增加日志的内容，某些服务器可能得更频繁地清理日志
        ]]--
        v.overridebuild = "dishes_legion"
    end
    -- v.overridesymbolname = nil, --替换烹饪锅的料理贴图的symbol。默认与料理名同名
    if v.oneatenfn ~= nil and v.oneat_desc == nil then
        v.oneat_desc = STRINGS.UI.COOKBOOK[string.upper(k)] --食谱中的食用效果的介绍语句
    end
    if v.cookbook_tex == nil then --食谱大图所用的image
        v.cookbook_tex = k..".tex"
    end
    if v.cookbook_atlas == nil then --食谱大图所用的atlas
        v.cookbook_atlas = "images/cookbookimages/"..k..".xml"
    end
    -- v.cookbook_category = "mod" --官方在AddCookerRecipe时就设置了，所以，cookbook_category 不需要自己写
end

return foods_legion
