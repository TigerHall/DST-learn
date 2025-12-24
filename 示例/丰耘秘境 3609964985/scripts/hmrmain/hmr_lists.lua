require "hmrlanguages/hmr_ch"
----------------------------------------------------------------------------
---[[颜色]]
----------------------------------------------------------------------------
local HMR_COLORS = {
    CHEST_STORE =       RGB(135, 206, 235), -- 天蓝色
    CHEST_TRANSMIT =    RGB(255, 69,  0  ), -- 火红色
    CHEST_RECYCLE =     RGB(205, 170, 125), -- 赭石色
    CHEST_FACTORY =     RGB(46,  50,  17 ), -- 墨绿色
    CHEST_DISPLAY =     RGB(255, 215, 0  ), -- 金色

    FURNITURE_LEMON =   RGB(255, 244, 79 ), -- 柠檬黄色
    FURNITURE_BLUEBERRY = RGB(81, 92, 171), -- 蓝莓蓝色
}

----------------------------------------------------------------------------
---[[地皮信息]]
----------------------------------------------------------------------------
local TURF_LIST = {
    cherry_flower = {   -- 樱海岛樱花地皮
        id = "HMR_CHERRY_FLOWER",
        name = STRINGS.NAMES.TURF_HMR_CHERRY_FLOWER,
        tex = "hmr_cherry_flower_noise",
        edge = "hmr_cherry_grass",
        mini_tex = "hmr_cherry_flower_noise",
        item_prefab = "hmr_cherry_flower",
        -- item_anim = "cherry_flower",
        item_anim = "cherry_grass",
    },
    cherry_grass = {    -- 樱海岛樱草地皮
        id = "HMR_CHERRY_GRASS",
        name = STRINGS.NAMES.TURF_HMR_CHERRY_GRASS,
        tex = "hmr_cherry_grass_noise",
        edge = "hmr_cherry_grass",
        mini_tex = "hmr_cherry_grass_noise",
        item_prefab = "hmr_cherry_grass",
        item_anim = "cherry_grass",
    },
    cherry_mystery = {  -- 樱海秘境地皮
        id = "HMR_CHERRY_MYSTERY",
        name = STRINGS.NAMES.TURF_HMR_CHERRY_MYSTERY,
        tex = "hmr_cherry_mystery_noise",
        edge = "hmr_cherry_grass",
        mini_tex = "hmr_cherry_mystery_noise",
        item_prefab = "hmr_cherry_mystery",
        item_anim = "cherry_mystery",
    },
    cherry_road = {     -- 樱花小径地皮
        id = "HMR_CHERRY_ROAD",
        name = STRINGS.NAMES.TURF_HMR_CHERRY_ROAD,
        tex = "hmr_cherry_road_noise",
        edge = "blocky",
        runsound = "dontstarve/movement/run_dirt",
        walksound = "dontstarve/movement/walk_dirt",
        snowsound = "dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        mini_tex = "hmr_cherry_road_noise",
        roadways = true,
        item_prefab = "hmr_cherry_road",
        item_anim = "cherry_road",
        pickupsound = "rock",
        tile_over = WORLD_TILES.COTL_BRICK
    },
    cherry_xmm = {      -- 悉樱樱地皮
        id = "HMR_CHERRY_XMM",
        name = STRINGS.NAMES.TURF_HMR_CHERRY_XMM,
        tex = "hmr_cherry_xmm_noise",
        edge = "hmr_cherry_grass",
        mini_tex = "hmr_cherry_xmm_noise",
        item_prefab = "hmr_cherry_xmm",
        item_anim = "cherry_xmm",
    }
}


----------------------------------------------------------------------------
---[[农作物信息]]
----------------------------------------------------------------------------
local FARM_PLANTS_LIST = {
    -- honor_sugarcane = {
    --     hunger = 1,
    --     health = 2,
    --     sanity = 10,
    --     perishtime = TUNING.PERISH_MED,

    --     cooked_hunger = 0,
    --     cooked_health = 0,
    --     cooked_sanity = 15,
    --     cooked_perishtime = TUNING.PERISH_FAST,

    --     float_settings = {"small", 0.05, 0.9},
    --     cooker_float_settings = {"med", nil, 0.75},

    --     dryable = nil,
    --     halloweenmoonmutable_settings = nil,
    --     secondary_foodtype = FOODTYPE.VEGETABLE,
    --     lure_data = nil,

    --     oversized_special_loot = {honor_splendor = 0.1, honor_plantfibre = 0.3},
    -- },
    honor_coconut = {
        fruits = {
            -- 椰子处理后才能吃
            honor_coconut = {
                hunger = 0,
                health = 0,
                sanity = 0,
                perishtime = TUNING.PERISH_MED,
                master_postinit = function(inst)
                    if inst.components.edible then
                        inst:RemoveComponent("edible")
                    end

                    if inst.components.perishable then
                        inst:RemoveComponent("perishable")
                    end

                    if inst.components.lootdropper == nil then
                        inst:AddComponent("lootdropper")
                    end

                    local function on_hammered()
                        local workdone = TUNING.HMR_COCONUT_WORKNUM + math.random(TUNING.HMR_COCONUT_WORKNUM)
                        local num_fruits_worked = math.clamp(math.ceil(workdone / TUNING.ROCK_FRUIT_MINES), 1, inst.components.stackable:StackSize()) -- 计算处理的果实数量

                        local function makecoconutloots()
                            local loots = {math.random() < 0.6 and "honor_coconut_meat" or "honor_coconut_juice"}
                            if  math.random() < 0.2 then
                                table.insert(loots, "honor_plantfibre")
                            end
                            return loots
                        end

                        for i = 1, num_fruits_worked do
                            inst.components.lootdropper:SetLoot(makecoconutloots())
                            inst.components.lootdropper:DropLoot()
                        end
                        -- 移除实际消耗的堆叠物品
                        local top_stack_item = inst.components.stackable:Get(num_fruits_worked)
                        top_stack_item:Remove()
                    end
                    inst:AddComponent("workable")
                    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
                    inst.components.workable:SetWorkLeft(TUNING.ROCK_FRUIT_MINES * inst.components.stackable.stacksize)
                    --inst.components.workable:SetOnFinishCallback(onhammered)
                    inst.components.workable:SetOnWorkCallback(on_hammered)

                    local function stack_size_changed(inst, data)
                        if data ~= nil and data.stacksize ~= nil and inst.components.workable ~= nil then
                            inst.components.workable:SetWorkLeft(data.stacksize * TUNING.ROCK_FRUIT_MINES)
                        end
                    end
                    inst:ListenForEvent("stacksizechange", stack_size_changed)
                end
            },
            honor_coconut_meat = {
                hunger = 10,
                health = 0,
                sanity = 10,
                perishtime = TUNING.PERISH_MED,
            },
            honor_coconut_juice = {
                hunger = 0,
                health = 0,
                sanity = 20,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        cooked = {
            honor_coconut_cooked = {
                hunger = 10,
                health = 5,
                sanity = -2,
                perishtime = TUNING.PERISH_FAST,
            }
        },

        seeds = {
            honor_coconut_seeds = {},
            honor_coconut_meat_seeds = {
                common_seeds = "honor_coconut_seeds",
            },
        },

        oversized = {
            honor_coconut_oversized = {
                special_loots = {honor_splendor = 0.1, honor_coconut_hat = 0.05, honor_plantfibre = 0.3},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.MEAT,
        lure_data = nil,
    },
    honor_tea = {
        fruits = {
            honor_tea = {
                hunger = 0,
                health = 5,
                sanity = 15,
                perishtime = TUNING.PERISH_MED,
            },
            honor_dhp = {
                hunger = 2,
                health = 7,
                sanity = 17,
                perishtime = TUNING.PERISH_MED,
            },
            honor_jasmine = {
                hunger = 0,
                health = 6,
                sanity = 20,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            honor_tea_cooked = {
                hunger = 10,
                health = 10,
                sanity = 20,
                perishtime = TUNING.PERISH_FAST,
            },
            honor_dhp_cooked = {
                hunger = 15,
                health = 15,
                sanity = 30,
                perishtime = TUNING.PERISH_FAST,
            },
            honor_jasmine_cooked = {
                hunger = 10,
                health = 10,
                sanity = 50,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            honor_tea_seeds = {},
            honor_dhp_seeds = {
                common_seeds = "honor_tea_seeds",
            },
            honor_jasmine_seeds = {
                common_seeds = "honor_tea_seeds",
            },
        },

        oversized = {
            honor_tea_oversized = {
                special_loots = {honor_splendor = 0.1, honor_dhp = 0.2, honor_jasmine = 0.4},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.VEGGIE,
        lure_data = nil,
    },
    honor_rice = {
        fruits = {
            honor_rice = {
                hunger = 10,
                health = 2,
                sanity = 2,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            honor_rice_cooked = {
                hunger = 35,
                health = 5,
                sanity = 5,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            honor_rice_seeds = {},
        },

        oversized = {
            honor_rice_oversized = {
                special_loots = {honor_splendor = 0.1, honor_hybrid_rice_seed = 0.05},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.SEEDS,
        lure_data = nil,
    },
    honor_wheat = {
        fruits = {
            honor_wheat = {
                hunger = 10,
                health = 5,
                sanity = 0,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            honor_wheat_cooked = {
                hunger = 20,
                health = 10,
                sanity = 10,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            honor_wheat_seeds = {},
        },

        oversized = {
            honor_wheat_oversized = {
                special_loots = {honor_splendor = 0.1, honor_blowdart_fire = 0.05, honor_blowdart_ice = 0.05, honor_blowdart_cure = 0.025},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.SEEDS,
        lure_data = nil,
    },
    honor_goldenlanternfruit = {
        fruits = {
            honor_goldenlanternfruit = {
                hunger = 5,
                health = 0,
                sanity = 10,
                perishtime = TUNING.PERISH_MED,
                master_postinit = function(inst)
                    local light = SpawnPrefab("honor_goldenlanternfruit_light")
                    light.entity:SetParent(inst.entity)
                end,
            },
        },

        cooked = {
            honor_goldenlanternfruit_cooked = {
                hunger = 7,
                health = 10,
                sanity = 15,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            honor_goldenlanternfruit_seeds = {},
        },

        oversized = {
            honor_goldenlanternfruit_oversized = {
                special_loots = {honor_splendor = 0.1, honor_goldenlanternfruit_peel = 0.3},
                master_postinit = function(inst)
                    local light = SpawnPrefab("honor_goldenlanternfruit_light")
                    light.entity:SetParent(inst.entity)
                    light.Light:SetRadius(.8)

                    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                end
            },
        },

        oversized_waxed = {
            honor_goldenlanternfruit_oversized_waxed = {
                master_postinit = function(inst)
                    local light = SpawnPrefab("honor_goldenlanternfruit_light")
                    light.entity:SetParent(inst.entity)
                    light.Light:SetRadius(.8)

                    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                end
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,

        farm_plant_master_postinit = function(inst)
            local STAGES = deepcopy(inst.components.growable.stages)
            for _, stage in pairs(STAGES) do
                if stage.name == "med" then
                    local old_fn = stage.fn
                    stage.fn = function(inst, ...)
                        old_fn(inst, ...)
                        local light = SpawnPrefab("honor_goldenlanternfruit_light")
                        light.entity:SetParent(inst.entity)
                        light.Light:SetRadius(.3)
                        inst._light = light

                        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                        inst.AnimState:SetSymbolBloom("veg")
                        inst.AnimState:SetSymbolLightOverride("veg", .1)
                    end
                elseif stage.name == "full" then
                    local old_fn = stage.fn
                    stage.fn = function(inst, ...)
                        old_fn(inst, ...)
                        if inst._light == nil then
                            local light = SpawnPrefab("honor_goldenlanternfruit_light")
                            light.entity:SetParent(inst.entity)
                            inst._light = light
                        end
                        inst._light.Light:SetRadius(inst.is_oversized and .8 or .5)

                        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                        inst.AnimState:SetSymbolBloom("veg")
                        inst.AnimState:SetSymbolLightOverride("veg", .1)
                    end
                elseif stage.name == "rotten" then
                    local old_fn = stage.fn
                    stage.fn = function(inst, ...)
                        old_fn(inst, ...)
                        if inst._light ~= nil then
                            inst._light:Remove()
                            inst._light = nil
                        end

                        inst.AnimState:ClearSymbolBloom("veg")
                        inst.AnimState:SetSymbolLightOverride("veg", 0)
                    end
                end
            end
            inst.components.growable.stages = STAGES
        end,
    },
    honor_aloe = {
        fruits = {
            honor_aloe = {
                hunger = 2,
                health = 20,
                sanity = -10,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            honor_aloe_cooked = {
                hunger = 10,
                health = 0,
                sanity = 5,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            honor_aloe_seeds = {},
        },

        oversized = {
            honor_aloe_oversized = {
                special_loots = {honor_splendor = 0.4},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.MONSTER,
        lure_data = nil,
    },
    honor_hamimelon = {
        fruits = {
            honor_hamimelon = {
                hunger = 20,
                health = 5,
                sanity = 30,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            honor_hamimelon_cooked = {
                hunger = 30,
                health = 10,
                sanity = 5,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            honor_hamimelon_seeds = {},
        },

        oversized = {
            honor_hamimelon_oversized = {
                special_loots = {honor_splendor = 0.15},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.GOODIES,
        lure_data = nil,
    },
    honor_nut = {
        fruits = {
            honor_nut = {
                hunger = 5,
                health = 10,
                sanity = 10,
                perishtime = TUNING.PERISH_MED,
            },
            honor_almond = { -- 巴旦木
                hunger = 8,
                health = 5,
                sanity = 20,
                perishtime = TUNING.PERISH_MED,
            },
            honor_cashew = { -- 腰果
                hunger = 20,
                health = -5,
                sanity = 10,
                perishtime = TUNING.PERISH_MED,
            },
            honor_macadamia = { -- 夏威夷果
                hunger = 20,
                health = 3,
                sanity = 10,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            honor_nut_cooked = {
                hunger = 10,
                health = 15,
                sanity = 5,
                perishtime = TUNING.PERISH_FAST,
            },
            honor_almond_cooked = {
                hunger = 15,
                health = 5,
                sanity = 25,
                perishtime = TUNING.PERISH_FAST,
            },
            honor_cashew_cooked = {
                hunger = 30,
                health = 5,
                sanity = 15,
                perishtime = TUNING.PERISH_FAST,
            },
            honor_macadamia_cooked = {
                hunger = 25,
                health = 5,
                sanity = 15,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            honor_nut_seeds = {},
            honor_almond_seeds = {common_seeds = "honor_nut_seeds"},
            honor_cashew_seeds = {common_seeds = "honor_nut_seeds"},
            honor_macadamia_seeds = {common_seeds = "honor_nut_seeds"},
        },

        oversized = {
            honor_nut_oversized = {
                special_loots = {honor_splendor = 0.1, honor_almond = 0.5, honor_cashew = 0.3, honor_macadamia = 0.1},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.WOOD,
        lure_data = nil,

        farm_plant_master_postinit = function(inst)
            inst.plantregistrykey = "honor_nut"
        end,
    },

    terror_blueberry = {
        fruits = {
            terror_blueberry = {
                hunger = 5,
                health = 0,
                sanity = 8,
                perishtime = TUNING.PERISH_MED,
                master_postinit = function(inst)
                    inst.components.edible:SetOnEatenFn(function(inst, eater)
                        if eater.components.moisture then
                            eater.components.moisture:DoDelta(-20)
                        end
                    end)
                end
            },
        },

        cooked = {
            terror_blueberry_cooked = {
                hunger = 10,
                health = 2,
                sanity = 15,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_blueberry_seeds = {},
        },

        oversized = {
            terror_blueberry_oversized = {
                special_loots = {terror_blueberry_hat = 0.3, terror_mucous = 0.05, terror_dangerous = 0.05},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,
    },
    terror_ginger = {
        fruits = {
            terror_ginger = {
                hunger = 1,
                health = 5,
                sanity = -15,
                perishtime = TUNING.PERISH_MED,
                master_postinit = function(inst)
                    local REASON = "terror_ginger"
                    local function OnPutInInv(inst, owner)
                        if owner ~= nil and owner.components.locomotor ~= nil then
                            owner.components.locomotor:SetExternalSpeedMultiplier(inst, REASON, 1.05)
                        end
                    end
                    inst:ListenForEvent("onputininventory", OnPutInInv)
                    inst:ListenForEvent("onownerputininventory", OnPutInInv)

                    local function OnDroppedFromInv(inst, owner)
                        if owner ~= nil and owner.components.locomotor ~= nil then
                            owner.components.locomotor:RemoveExternalSpeedMultiplier(inst, REASON)
                        end
                    end
                    inst:ListenForEvent("ondropped", OnDroppedFromInv)
                    inst:ListenForEvent("onownerdropped", OnDroppedFromInv)
                end
            },
        },

        cooked = {
            terror_ginger_cooked = {
                hunger = 5,
                health = 10,
                sanity = 10,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_ginger_seeds = {},
        },

        oversized = {
            terror_ginger_oversized = {
                special_loots = {orangegem = 0.15},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.GOODIES,
        lure_data = nil,
    },
    terror_snakeskinfruit = {
        fruits = {
            terror_snakeskinfruit = {
                hunger = 20,
                health = 0,
                sanity = -10,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            terror_snakeskinfruit_cooked = {
                hunger = 30,
                health = 5,
                sanity = -5,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_snakeskinfruit_seeds = {},
        },

        oversized = {
            terror_snakeskinfruit_oversized = {
                special_loots = {dragon_scales = 0.1, redgem = 0.3},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,
    },
    terror_lemon = {
        fruits = {
            terror_lemon = {
                hunger = 5,
                health = -10,
                sanity = -10,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            terror_lemon_cooked = {
                hunger = 10,
                health = 0,
                sanity = 0,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_lemon_seeds = {},
        },

        oversized = {
            terror_lemon_oversized = {
                special_loots = {orangegem = 0.15, terror_lemon_bomb = 0.1},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,
    },
    terror_litchi = {
        fruits = {
            terror_litchi = {
                hunger = 5,
                health = 2,
                sanity = 15,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            terror_litchi_cooked = {
                hunger = 2,
                health = 10,
                sanity = 5,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_litchi_seeds = {},
        },

        oversized = {
            terror_litchi_oversized = {
                special_loots = {terror_mucous = 0.15},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,
    },
    terror_coffee = {
        fruits = {
            terror_coffee = {
                hunger = 2,
                health = 0,
                sanity = 5,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            terror_coffee_cooked = {
                hunger = 5,
                health = 1,
                sanity = 40,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_coffee_seeds = {},
        },

        oversized = {
            terror_coffee_oversized = {
                special_loots = {terror_mucous = 0.25},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,
    },
    terror_hawthorn = {
        fruits = {
            terror_hawthorn = {
                hunger = -5,
                health = 20,
                sanity = -5,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            terror_hawthorn_cooked = {
                hunger = -10,
                health = 30,
                sanity = 0,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_hawthorn_seeds = {},
        },

        oversized = {
            terror_hawthorn_oversized = {
                special_loots = {},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,
    },
    terror_passionfruit = {
        fruits = {
            terror_passionfruit = {
                hunger = 10,
                health = 5,
                sanity = 30,
                perishtime = TUNING.PERISH_MED,
            },
        },

        cooked = {
            terror_passionfruit_cooked = {
                hunger = 15,
                health = 5,
                sanity = 10,
                perishtime = TUNING.PERISH_FAST,
            },
        },

        seeds = {
            terror_passionfruit_seeds = {},
        },

        oversized = {
            terror_passionfruit_oversized = {
                special_loots = {terror_mucous = 0.8},
            },
        },

        float_settings = {"small", 0.05, 0.9},
        cooker_float_settings = {"med", nil, 0.75},

        dryable = nil,
        halloweenmoonmutable_settings = nil,
        secondary_foodtype = FOODTYPE.BERRY,
        lure_data = nil,
    },
}

----------------------------------------------------------------------------
---[[调味料表]]
----------------------------------------------------------------------------
local SPICE_DATA_LIST = {
    -- 原版调味料
    saltrock = {    -- 盐晶
        product = "spice_salt",
        numtogive = 3,
        source = "authority"
    },
    pepper = {      -- 辣椒
        product = "spice_chili",
        numtogive = 3,
        source = "authority"
    },
    garlic = {      -- 蒜
        product = "spice_garlic",
        numtogive = 3,
        source = "authority"
    },
    honey = {       -- 蜂蜜
        product = "spice_sugar",
        numtogive = 3,
        source = "authority"
    },
    -- 丰耘秘境调味料
    honor_tea_prime = {
        product = "spice_honor_tea_prime",
        numtogive = 10,
        source = "hmr",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("spice_honor_tea_prime_buff", "spice_honor_tea_prime_buff")
        end,
    },
    honor_wheat_prime = {
        product = "spice_honor_wheat_prime",
        numtogive = 10,
        source = "hmr",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("spice_honor_wheat_prime_buff", "spice_honor_wheat_prime_buff")
        end,
    },
    honor_rice_prime = {
        product = "spice_honor_rice_prime",
        numtogive = 10,
        source = "hmr",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("spice_honor_rice_prime_buff", "spice_honor_rice_prime_buff")
        end,
    },
    -- honor_sugarcane_prime = {
    --     product = "spice_honor_sugarcane_prime",
    --     numtogive = 10,
    --     source = "hmr",
    --     oneatenfn = function(inst, eater)
    --         eater:AddDebuff("spice_honor_sugarcane_prime_buff", "spice_honor_sugarcane_prime_buff")
    --     end,
    -- },
    honor_coconut_prime = {
        product = "spice_honor_coconut_prime",
        numtogive = 10,
        source = "hmr",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("spice_honor_coconut_prime_buff", "spice_honor_coconut_prime_buff")
        end,
    },
    terror_blueberry_prime = {
        product = "spice_terror_blueberry_prime",
        numtogive = 10,
        source = "hmr",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("spice_terror_blueberry_prime_buff", "spice_terror_blueberry_prime_buff")
        end,
    },
    terror_ginger_prime = {
        product = "spice_terror_ginger_prime",
        numtogive = 10,
        source = "hmr",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("spice_terror_ginger_prime_buff", "spice_terror_ginger_prime_buff")
        end,
    },
    terror_snakeskinfruit_prime = {
        product = "spice_terror_snakeskinfruit_prime",
        numtogive = 10,
        source = "hmr",
        oneatenfn = function(inst, eater)
            eater:AddDebuff("spice_terror_snakeskinfruit_prime_buff", "spice_terror_snakeskinfruit_prime_buff")
        end,
    },
    -- 能力勋章调味料
    medal_fishbones = {
        product = "spice_jelly",
        numtogive = 1,
        source = "medal",
    },
    moonbutterflywings = {
        product = "spice_phosphor",
        numtogive = 1,
        source = "medal",
    },
    moon_tree_blossom = {
        product = "spice_moontree_blossom",
        numtogive = 1,
        source = "medal",
    },
    moon_tree_blossom_worldgen = {
        product = "spice_moontree_blossom",
        numtogive = 1,
        source = "medal",
    },
    cactus_flower = {
        product = "spice_cactus_flower",
        numtogive = 1,
        source = "medal",
    },
    mosquitosack = {
        product = "spice_blood_sugar",
        numtogive = 1,
        source = "medal",
    },
    wortox_soul = {
        product = "spice_soul",
        numtogive = 1,
        source = "medal",
    },
    potato = {
        product = "spice_potato_starch",
        numtogive = 1,
        source = "medal",
    },
    compostwrap = {
        product = "spice_poop",
        numtogive = 3,
        source = "medal",
    },
    mandrakeberry = {
        product = "spice_mandrake_jam",
        numtogive = 1,
        source = "medal",
    },
    pomegranate = {
        product = "spice_pomegranate",
        numtogive = 1,
        source = "medal",
    },
    medal_withered_royaljelly = {
        product = "spice_withered_royal_jelly",
        numtogive = 1,
        source = "medal",
    }
}

----------------------------------------------------------------------------
---[[修补套件增益类型]]
----------------------------------------------------------------------------
local KIT_BUFF_TYPE_LIST = {
    HONOR = {
        armor = 3,
        condition = 5,
        effectiveness = 4,
    },
    TERROR = {
        damage = 4,
        speed = 5,
    }
}

----------------------------------------------------------------------------
---[[丰耘科技树]]
----------------------------------------------------------------------------
-- 获取指定数量物品
local function Tech_RequireItems(doer, require_data)
    if doer ~= nil and doer.components.inventory ~= nil then
        for _, data in pairs(require_data) do
            local prefab, num = data.prefab, data.num
            local items = doer.components.inventory:GetItemByName(prefab, num, true)

            local numget = 0
            for item, itemnum in pairs(items) do
                numget = numget + itemnum
            end

            if numget < num then
                return false
            end
        end
        for _, data in pairs(require_data) do
            local prefab, num = data.prefab, data.num
            local items = doer.components.inventory:GetItemByName(prefab, num, true)
            for item, itemnum in pairs(items) do
                if item.components.stackable ~= nil then
                    if itemnum < item.components.stackable.maxsize then
                        item.components.stackable:Get(itemnum):Remove()
                    else
                        item:Remove()
                    end
                else
                    item:Remove()
                end
            end
        end
        return true
    end
    return false
end

local HMR_TECH_LIST = {
    hmr_chest_store = {
        title = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_STORE.TITLE,
        subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_STORE.SUBTITLE,
        subtitlecolour = HMR_COLORS.CHEST_STORE,
        desc = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_STORE.DESCRIBE,
        icon = "hmr_chest_store.tex",
        atlas = "images/widgetimages/hmr_tech_icons.xml",
        pos = {-420, 50},
        root = true,
        group = "chests",
        tags = {},
        --connects = {},
        unlocktechs = {"hmr_chest_store"},
        requirefn = function(doer)
            return Tech_RequireItems(doer, {{prefab = "terror_blueberry_prime", num = 5}})
        end
    },
    hmr_chest_transmit = {
        title = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_TRANSMIT.TITLE,
        subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_TRANSMIT.SUBTITLE,
        subtitlecolour = HMR_COLORS.CHEST_TRANSMIT,
        desc = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_TRANSMIT.DESCRIBE,
        icon = "hmr_chest_transmit.tex",
        atlas = "images/widgetimages/hmr_tech_icons.xml",
        pos = {-420, 100},
        root = false,
        group = "chests",
        tags = {},
        connects = {"hmr_chest_store"},
        unlocktechs = {"hmr_chest_transmit"},
        requirefn = function(doer)
            return Tech_RequireItems(doer, {{prefab = "terror_snakeskinfruit_prime", num = 5}})
        end
    },
    hmr_chest_recycle = {
        title = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_RECYCLE.TITLE,
        subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_RECYCLE.SUBTITLE,
        subtitlecolour = HMR_COLORS.CHEST_RECYCLE,
        desc = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_RECYCLE.DESCRIBE,
        icon = "hmr_chest_recycle.tex",
        atlas = "images/widgetimages/hmr_tech_icons.xml",
        pos = {-370, 50},
        root = true,
        group = "chests",
        tags = {},
        -- connects = {""},
        unlocktechs = {"hmr_chest_recycle"},
        requirefn = function(doer)
            return Tech_RequireItems(doer, {{prefab = "honor_coconut_prime", num = 5}})
        end
    },
    hmr_chest_factory = {
        title = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_FACTORY.TITLE,
        subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_FACTORY.SUBTITLE,
        subtitlecolour = HMR_COLORS.CHEST_FACTORY,
        desc = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_FACTORY.DESCRIBE,
        icon = "hmr_chest_factory.tex",
        atlas = "images/widgetimages/hmr_tech_icons.xml",
        pos = {-370, 100},
        root = false,
        group = "chests",
        tags = {},
        connects = {"hmr_chest_recycle"},
        unlocktechs = {"hmr_chest_factory", "hmr_chest_factory_core_item"},
        requirefn = function(doer)
            return Tech_RequireItems(doer, {{prefab = "honor_tea_prime", num = 5}})
        end
    },
    hmr_chest_display = {
        title = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_DISPLAY.TITLE,
        subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_DISPLAY.SUBTITLE,
        subtitlecolour = HMR_COLORS.CHEST_DISPLAY,
        desc = STRINGS.HMR.HMR_TECHTREE.HMR_CHEST_DISPLAY.DESCRIBE,
        icon = "hmr_chest_display.tex",
        atlas = "images/widgetimages/hmr_tech_icons.xml",
        pos = {-395, 150},
        root = false,
        group = "chests",
        tags = {},
        connects = {"hmr_chest_factory", "hmr_chest_transmit"},
        unlocktechs = {"hmr_chest_display"},
        requirefn = function(doer)
            return Tech_RequireItems(doer, {{prefab = "honor_goldenlanternfruit_prime", num = 5}})
        end
    },

    -- hmr_furniture_lemon = {
    --     title = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_LEMON.TITLE,
    --     subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_LEMON.SUBTITLE,
    --     subtitlecolour = HMR_COLORS.FURNITURE_LEMON,
    --     desc = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_LEMON.DESCRIBE,
    --     icon = "button_carny_square_normal.tex",
    --     atlas = "images/global_redux.xml",
    --     pos = { 420 + 10,  110 - 180},
    --     root = true,
    --     group = "furniture",
    --     tags = {},
    --     -- connects = {""},
    --     unlocktechs = {"hmr_lemon_chair", "hmr_lemon_stool", "terror_lemon_bomb"},
    --     requirefn = function(doer)
    --         return Tech_RequireItems(doer, {{prefab = "terror_lemon", num = 60}, {prefab = "terror_lemon_seeds", num = 40}})
    --     end
    -- },
    -- hmr_furniture_blueberry = {
    --     title = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_BLUEBERRY.TITLE,
    --     subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_BLUEBERRY.SUBTITLE,
    --     subtitlecolour = HMR_COLORS.FURNITURE_BLUEBERRY,
    --     desc = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_BLUEBERRY.DESCRIBE,
    --     icon = "button_carny_square_normal.tex",
    --     atlas = "images/global_redux.xml",
    --     pos = { 420 + 10 + 90,  110 - 180},
    --     root = false,
    --     group = "furniture",
    --     tags = {},
    --     connects = {"hmr_furniture_lemon"},
    --     unlocktechs = {"hmr_blueberry_carpet_item", "terror_blueberry_hat"},
    --     requirefn = function(doer)
    --         return Tech_RequireItems(doer, {{prefab = "terror_blueberry", num = 40}, {prefab = "terror_blueberry_seeds", num = 30}})
    --     end
    -- },
    -- hmr_furniture_coconut = {
    --     title = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_COCONUT.TITLE,
    --     subtitle = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_COCONUT.SUBTITLE,
    --     subtitlecolour = HMR_COLORS.FURNITURE_COCONUT,
    --     desc = STRINGS.HMR.HMR_TECHTREE.HMR_FURNITURE_COCONUT.DESCRIBE,
    --     icon = "button_carny_square_normal.tex",
    --     atlas = "images/global_redux.xml",
    --     pos = { 420 + 10 + 45,  110 - 135},
    --     root = false,
    --     group = "furniture",
    --     tags = {},
    --     connects = {},
    --     unlocktechs = {"honor_coconut_shell"},
    --     requirefn = function(doer)
    --         return Tech_RequireItems(doer, {{prefab = "honor_coconut", num = 10}, {prefab = "honor_coconut_seeds", num = 10}})
    --     end
    -- },
}


----------------------------------------------------------------------------
---[[龙龛探秘箱回收物品清单]]
----------------------------------------------------------------------------
local RECYCLE_CHEST_LIST = {
    -- 普通
    trinket_6 = "normal",
    trinket_7 = "normal",
    trinket_8 = "normal",
    trinket_9 = "normal",
    trinket_10 = "normal",
    trinket_12 = "normal",
    trinket_14 = "normal",
    trinket_17 = "normal",
    trinket_20 = "normal",
    trinket_22 = "normal",
    trinket_23 = "normal",
    trinket_26 = "normal",
    trinket_27 = "normal",
    trinket_33 = "normal",
    trinket_34 = "normal",
    trinket_35 = "normal",
    trinket_36 = "normal",
    trinket_37 = "normal",
    trinket_40 = "normal",
    trinket_41 = "normal",
    trinket_44 = "normal",
    trinket_45 = "normal",
    trinket_46 = "normal",

    -- 玩具
    trinket_1 = "toy",
    trinket_2 = "toy",
    trinket_3 = "toy",
    trinket_4 = "toy",
    trinket_5 = "toy",
    trinket_11 = "toy",
    trinket_13 = "toy",
    trinket_18 = "toy",
    trinket_19 = "toy",
    trinket_24 = "toy",
    trinket_25 = "toy",
    trinket_15 = "toy",
    trinket_16 = "toy",
    trinket_28 = "toy",
    trinket_29 = "toy",
    trinket_30 = "toy",
    trinket_31 = "toy",
    trinket_32 = "toy",
    trinket_38 = "toy",
    trinket_39 = "toy",
    trinket_42 = "toy",
    trinket_43 = "toy",

    -- 废料
    wagpunk_bits = "wagpunk_bits",
    chestupgrade_stacksize = "wagpunk_bits",
    wagpunkhat = "wagpunk_bits",
    armorwagpunk = "wagpunk_bits",
    wagpunkbits_kit = "wagpunk_bits",
    winona_storage_robot = "wagpunk_bits"
}

----------------------------------------------------------------------------
---[[灵枢织造箱工厂物品清单]]
----------------------------------------------------------------------------
local FACTORY_CHEST_LIST = {
    twigs = {
        priority = 1,
        members = {
            -- 多枝树
            twiggytree = 2,
            twiggy_short = 1,
            twiggy_normal = 2,
            twiggy_tall = 3,
            twiggy_old = 1,
            twiggy_nut_sapling = 0.5,
            -- 树苗
            sapling = 1,
            sapling_moon = 1.5,
        },
        products = {
            twigs = 10,
            log = 3,
            boards = 2,
            dug_sapling = 1,
            dug_sapling_moon = 1,
        }
    },
    wood = {
        priority = 4,
        members = {
            -- 常青树
            evergreen = 3,
            evergreen_short = 2,
            evergreen_normal = 3,
            evergreen_tall = 4,
            evergreen_old = 2,
            pinecone_sapling = 1,
            -- 臃肿常青树
            evergreen_sparse = 1,
            evergreen_sparse_short = 1,
            evergreen_sparse_normal = 1.5,
            evergreen_sparse_tall = 2,
            lumpy_sapling = 0.25,
            -- 桦栗树
            deciduoustree = 2,
            deciduous_short = 1,
            deciduous_normal = 2,
            deciduous_tall = 3,
            acorn_sapling = 0.5,
            -- 月树
            moon_tree = 3,
            moon_short = 2,
            moon_normal = 3,
            moon_tall = 4.5,
            moonbutterfly_sapling = 1.5,
            -- 特殊树
            marsh_tree = 1,
        },
        products = {
            log = 5,
            boards = 2,
            twigs = 1,
            livinglog = 0.5,
            driftwood_log = 0.25,
        }
    },
    palm = {
        priority = 10,
        members = {
            -- 棕榈树
            palmconetree = 2,
            palmconetree_short = 1,
            palmconetree_normal = 2,
            palmconetree_tall = 3,
            palmcone_sapling = 0.5,
        },
        products = {
            log = 4,
            palmcone_scale = 3,
            cave_banana = 1,
            palmcone_seed = 1,
            twigs = 1,
        }
    },
    grass = {
        priority = 2,
        members = {
            -- 草
            grass = 1,
            reeds = 3,
            monkeytail = 4,
        },
        products = {
            cut_grass = 10,
            cutreeds = 3,
            dug_grass = 1,
            dug_monkeytail = 0.5,
            papyrus = 0.25,
        }
    },
    berry = {
        priority = 3,
        members = {
            berrybush = 1,
            berrybush2 = 1,
            berrybush_juicy = 1.5,
        },
        products = {
            berries = 10,
            berries_juicy = 7,
            berries_cooked = 2,
            berries_juicy_cooked = 1,
            fig = 1,
        }
    },
    banana = {
        priority = 5,
        members = {
            bananabush = 2,
            cave_banana_tree = 4,
        },
        products = {
            cave_banana = 10,
            cave_banana_cooked = 3,
            bananapop = 2,
            dug_bananabush = 0.5,
            hmr_dug_cavebananatree = 0.2,
        }
    },
    avocado = {
        priority = 6,
        members = {
            rock_avocado_bush = 2,
            farm_plant_avocado = 2,
        },
        products = {
            rock_avocado_fruit = 10,
            rock_avocado_fruit_ripe = 3,
            rocks = 2,
            rock_avocado_fruit_ripe_cooked = 1,
            rock_avocado_fruit_sprout = 0.2,
        }
    },
    rock = {
        priority = 6,
        members = {
            -- 普通
            rock1 = 1,
            rock2 = 2,
            rock_flintless = 2,
            rock_flintless_med = 1,
            rock_flintless_low = 0.25,
            -- 月亮
            rock_moon = 4,
            rock_moon_shell = 8,
            -- 石笋
            stalagmite = 3,
            stalagmite_full = 5,
            stalagmite_med = 3,
            stalagmite_low = 1,
            stalagmite_tall = 3,
            stalagmite_tall_full = 5,
            stalagmite_tall_med = 3,
            stalagmite_tall_low = 1,
            -- 岩石
            cavein_boulder = 2,
            -- 石虾
            rocky = 4,
        },
        products = {
            rocks = 10,
            flint = 8,
            nitre = 6,
            goldnugget = 6,
            moonrocknugget = 2,
        },
    },
    marble = {
        priority = 7,
        members = {
            -- 自然大理石
            marbletree = 2,
            marblepillar = 2.5,
            statueharp = 2.5,
            statuemaxwell = 4,
            statue_marble = 2.5,
            statue_marble_muse = 2.5,
            statue_marble_pawn = 2.5,
            sculpture_knightbody = 2.5,
            daywalker_pillar = 6,
            resurrectionstone = 7,
            -- 大理石树
            marbleshrub_tall = 1.25,
            marbleshrub_normal = 0.75,
            marbleshrub_short = 0.5,
        },
        products = {
            marble = 10,
            cutstone = 3,
            rocks = 3,
            marblebean = 2,
            ancienttree_gem_sapling_item = 0.05,
        }
    },
    ice = {
        priority = 8,
        members = {
            -- 物体
            rock_ice = 2,
            rock_ice_temperature = 3,
            sharkboi_ice_hazard = 2,
            sharkboi_icespike = 1,
            -- 生物
            mutated_penguin = 4,
            oceanfish_medium_8 = 2,
            mutateddeerclops = 20,
            sharkboi = 18,
            wx78 = 12,
        },
        products = {
            ice = 10,
            wintersfeastfuel = 3,
            watermelonicle = 1,
            bananapop = 0.5,
            gazpacho = 0.5,
        }
    },
    pigman = {
        priority = 10,
        members = {
            -- 猪人
            pigman = 1,
            pigguard = 2,
            moonpig = 1.5,
            pigking = 8,
            -- 建筑
            pighouse = 2,
            gingerbreadhouse = 4,
            pigtorch = 4,
            pighead = 2,
        },
        products = {
            pigskin = 10,
            meat = 5,
            smallmeat = 2,
            pig_token = 0.5,
            panflute = 0.05,
        }
    },
}

----------------------------------------------------------------------------
---[[樱花盆栽掉落物]]
----------------------------------------------------------------------------
-- 如果命名是"farm_plant_xxx", 且种子名字是"xxx_seeds", 则自动掉落一个种子
-- 如有种子之外的掉落物，在此添加
local FLOWERPOT_DATA_LIST = {
    -- 原版农作物
    -- farm_plant_tomato = {"tomato_seeds"},
    -- farm_plant_potato = {"potato_seeds"},
    -- farm_plant_carrot = {"carrot_seeds"},

    -- 丰耘秘境农作物
    farm_plant_honor_coconut = {
        -- loots = {"honor_coconut_seeds"},
        -- type = "farm_plant",
    },
    farm_plant_honor_tea = {"honor_tea_seeds"},
    farm_plant_honor_rice = {"honor_rice_seeds"},
    farm_plant_honor_wheat = {"honor_wheat_seeds"},
    farm_plant_honor_goldenlanternfruit = {
        loots = {"honor_goldenlanternfruit_seeds"},
        type = "farm_plant",
        init_fn = function(inst, pot_data)
            local anim = pot_data and pot_data.animdata.anim

            local function SetLight(radius)
                local light = SpawnPrefab("honor_goldenlanternfruit_light")
                light.entity:SetParent(inst.entity)
                light.Light:SetRadius(radius or .3)

                inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                inst.AnimState:SetSymbolBloom("veg")
                inst.AnimState:SetSymbolLightOverride("veg", .1)
            end

            local light_stages = {
                crop_med = .3,
                crop_full =.5,
                crop_oversized = .8,
            }
            if light_stages[anim] ~= nil then
                SetLight(light_stages[anim])
            end
        end,
    },
    farm_plant_honor_aloe = {"honor_aloe_seeds"},
    farm_plant_terror_blueberry = {"terror_blueberry_seeds"},
    farm_plant_terror_ginger = {"terror_ginger_seeds"},
    farm_plant_terror_snakeskinfruit = {"terror_snakeskinfruit_seeds"},
    farm_plant_terror_lemon = {"terror_lemon_seeds"},
    farm_plant_terror_litchi = {"terror_litchi_seeds"},

    -- 小樱世界
    sakura_flower_mudan = {
        type = "flower",
        anim_set = {anim = "mudan"},
    },
    sakura_flower_baihe = {
        type = "flower",
        anim_set = {anim = "baihe"},
    },
    sakura_flower_jianlan = {
        type = "flower",
        anim_set = {anim = "jianlan"},
    },
    sakura_flower_lanzhang = {
        type = "flower",
        anim_set = {anim = "lanzhang"},
    },
    sakura_flower_fuzi = {
        type = "flower",
        anim_set = {anim = "fuzi"},
    }
}

----------------------------------------------------------------------------
---[[buff数据]]
----------------------------------------------------------------------------
--[[
eg_buff_name = {
    name = "eg_buff_name", -- string or function(player, buff_ent, buff_name)
    icon = {atlas = "", tex = ""},
    gettimeleftfn = function(player, buff_ent, buff_name) end,
}
]]
local BUFF_DATA_LIST = {
    -- 原版buff
    buff_attack = {
        name = "orig_buff_attack",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "spice_chili.tex"}
        icon = {tex = "spice_chili.tex"}
    },
    buff_playerabsorption = {
        name = "orig_buff_playerabsorption",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "spice_garlic.tex"}
        icon = {tex = "spice_garlic.tex"}
    },
    buff_workeffectiveness = {
        name = "orig_buff_workeffectiveness",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "spice_sugar.tex"}
        icon = {tex = "spice_sugar.tex"}
    },
    buff_moistureimmunity = { -- 蓝带鱼排
        name = "orig_buff_moistureimmunity",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "frogfishbowl.tex"}
        icon = {--[[atlas = GetInventoryItemAtlas("frogfishbowl.tex"), ]]tex = "frogfishbowl.tex"}
    },
    buff_electricattack = { -- 伏特羊肉冻
        name = "orig_buff_electricattack",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "voltgoatjelly.tex"}
        icon = {--[[atlas = GetInventoryItemAtlas("voltgoatjelly.tex"), ]]tex = "voltgoatjelly.tex"}
    },
    buff_sleepresistance = { -- 蘑菇蛋糕
        name = "orig_buff_sleepresistance",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "shroomcake.tex"}
        icon = {--[[atlas = GetInventoryItemAtlas("shroomcake.tex"), ]]tex = "shroomcake.tex"}
    },
    buff_sleepimmunity = { -- 蘑菇蛋糕
        name = "orig_buff_sleepimmunity",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "shroomcake.tex"}
        icon = {--[[atlas = GetInventoryItemAtlas("shroomcake.tex"), ]]tex = "shroomcake.tex"}
    },
    healthregenbuff = { -- 彩虹糖豆
        name = "orig_healthregenbuff",
        -- icon = {atlas = "images/inventoryimages2.xml", tex = "jellybean.tex"}
        icon = {--[[atlas = GetInventoryItemAtlas("jellybean.tex"), ]]tex = "jellybean.tex"}
    },
    sweettea_buff = { -- 舒缓茶
        name = "orig_sweettea_buff",
        -- icon = {atlas = "images/inventoryimages/sweettea.xml", tex = "sweettea.tex"}
        icon = {--[[atlas = GetInventoryItemAtlas("sweettea.tex"), ]]tex = "sweettea.tex"}
    },

    -- 丰耘秘境buff
    terror_blueberry_hat_buff = {
        icon = {atlas = "images/inventoryimages/terror_blueberry_hat.xml", tex = "terror_blueberry_hat.tex"},
    },
    hmr_blueberry_carpet_buff = {
        icon = {atlas = "images/inventoryimages/hmr_blueberry_carpet_item.xml", tex = "hmr_blueberry_carpet_item.tex"},
    },
    honor_dhp_buff = {
        icon = {atlas = "images/inventoryimages/honor_dhp.xml", tex = "honor_dhp.tex"},
    },
    honor_jasmine_buff = {
        icon = {atlas = "images/inventoryimages/honor_jasmine.xml", tex = "honor_jasmine.tex"},
    },
    honor_dhp_cooked_buff = {
        icon = {atlas = "images/inventoryimages/honor_dhp_cooked.xml", tex = "honor_dhp_cooked.tex"},
    },
    honor_jasmine_cooked_buff = {
        icon = {atlas = "images/inventoryimages/honor_jasmine_cooked.xml", tex = "honor_jasmine_cooked.tex"},
    },

    -- 丰耘秘境香料buff
    honor_tea_prime_buff = {
        icon = {atlas = "images/inventoryimages/honor_tea_prime.xml", tex = "honor_tea_prime.tex"},
    },
    spice_honor_tea_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_honor_tea_prime.xml", tex = "spice_honor_tea_prime.tex"},
    },
    honor_coconut_prime_buff = {
        icon = {atlas = "images/inventoryimages/honor_coconut_prime.xml", tex = "honor_coconut_prime.tex"},
    },
    spice_honor_coconut_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_honor_coconut_prime.xml", tex = "spice_honor_coconut_prime.tex"},
    },
    honor_rice_prime_buff = {
        icon = {atlas = "images/inventoryimages/honor_rice_prime.xml", tex = "honor_rice_prime.tex"},
    },
    spice_honor_rice_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_honor_rice_prime.xml", tex = "spice_honor_rice_prime.tex"},
    },
    honor_wheat_prime_buff = {
        icon = {atlas = "images/inventoryimages/honor_wheat_prime.xml", tex = "honor_wheat_prime.tex"},
    },
    spice_honor_wheat_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_honor_wheat_prime.xml", tex = "spice_honor_wheat_prime.tex"},
    },
    honor_sugarcane_prime_buff = {
        icon = {atlas = "images/inventoryimages/honor_sugarcane_prime.xml", tex = "honor_sugarcane_prime.tex"},
    },
    spice_honor_sugarcane_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_honor_sugarcane_prime.xml", tex = "spice_honor_sugarcane_prime.tex"},
    },
    terror_snakeskinfruit_prime_buff = {
        icon = {atlas = "images/inventoryimages/terror_snakeskinfruit_prime.xml", tex = "terror_snakeskinfruit_prime.tex"},
    },
    spice_terror_snakeskinfruit_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_terror_snakeskinfruit_prime.xml", tex = "spice_terror_snakeskinfruit_prime.tex"},
    },
    terror_ginger_prime_buff = {
        icon = {atlas = "images/inventoryimages/terror_ginger_prime.xml", tex = "terror_ginger_prime.tex"},
    },
    spice_terror_ginger_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_terror_ginger_prime.xml", tex = "spice_terror_ginger_prime.tex"},
    },
    terror_blueberry_prime_buff = {
        icon = {atlas = "images/inventoryimages/terror_blueberry_prime.xml", tex = "terror_blueberry_prime.tex"},
    },
    spice_terror_blueberry_prime_buff = {
        icon = {atlas = "images/inventoryimages/spice_terror_blueberry_prime.xml", tex = "spice_terror_blueberry_prime.tex"},
    },
}

----------------------------------------------------------------------------
---[[修补黑名单]]
----------------------------------------------------------------------------
local REPAIR_BLACK_LIST = {
    ["greenstaff"] = true,
    ["greenamulet"] = true,
}

return {
    HMR_COLORS = HMR_COLORS,                            -- 颜色表
    TURF_LIST = TURF_LIST,                              -- 地皮表
    FARM_PLANTS_LIST = FARM_PLANTS_LIST,                -- 农作物表
    SPICE_DATA_LIST = SPICE_DATA_LIST,                  -- 香料数据表
    KIT_BUFF_TYPE_LIST = KIT_BUFF_TYPE_LIST,            -- 工具套装buff类型表
    HMR_TECH_LIST = HMR_TECH_LIST,                      -- 丰耘科技表
    FACTORY_CHEST_LIST = FACTORY_CHEST_LIST,            -- 工厂箱物品清单
    RECYCLE_CHEST_LIST = RECYCLE_CHEST_LIST,            -- 回收箱物品清单
    FLOWERPOT_DATA_LIST = FLOWERPOT_DATA_LIST,          -- 樱花盆栽掉落物
    BUFF_DATA_LIST = BUFF_DATA_LIST,                    -- buff数据
    REPAIR_BLACK_LIST = REPAIR_BLACK_LIST,              -- 修补黑名单
}