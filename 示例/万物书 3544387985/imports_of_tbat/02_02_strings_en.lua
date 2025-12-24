---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    文本库

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

TBAT.STRINGS = TBAT.STRINGS or {}

TBAT.STRINGS["en"] = TBAT.STRINGS["en"] or {
      ---------------------------------------------------------------------------------------
      -- others 
            ["test_prefab"] = {
                  ["name"] = "测试",
                  ["inspect_str"] = "测试描述",
                  ["recipe_desc"] = "制作栏描述",
                  ["info"] = {
                        ["warning"] = "这是一个测试警告",
                        ["tip"] = {
                              [1] = "这是一个测试提示 1",
                              [2] = "这是一个测试提示 2",
                        },
                        ["error"] = {
                              ["error_1"] = "这是一个测试错误 1",
                              ["error_2"] = "这是一个测试错误 2",
                        }
                  
                  },
            },
            ["recipe_name"] = {
                  ["main"] = "万物书",
                  ["building"] = "tbat-building",
                  ["decoration"] = "tbat-decoration",
                  ["item"] = "tbat-item",
            },        
      ---------------------------------------------------------------------------------------
      -- 00_tbat_others
            -- "test_item"	, 							--- 测试物品
      ---------------------------------------------------------------------------------------
      -- 01_tbat_items
            ["tbat_item_butterfly_wrapping_paper"] = {
                  ["name"] = "butterfly wrapping paper",
                  ["inspect_str"] = "Will you take me faraway, where only love can lead?~ ",
                  ["recipe_desc"] = "Will you take me faraway, where only love can lead?~",
            },
            ["tbat_item_butterfly_wrapped_pack"] = {
                  ["name"] = "butterfly wrapped pack",
                  ["inspect_str"] = "butterly wrapped pack~",
                  ["safe_mod_error"] = "unable to pack this item, please change the setting",
            },
            ["tbat_item_holo_maple_leaf"] = {
                  ["name"] = "holo maple leaf",
                  ["inspect_str"] = "To keep the sights you long to see, just for you",
                  ["action_str"] = "record",
            },
            ["tbat_item_holo_maple_leaf_packed"] = {
                  ["name"] = "holo maple leaf packed:",
                  ["inspect_str"] = "already recorded",
            },
            ["tbat_item_holo_maple_leaf_packed_building"] = {
                  ["name"] = "holo maple leaf packed building",
                  ["inspect_str"] = "records from the holo maple leaf",
            },
            ["tbat_item_jellyfish_in_bottle"] = {
                  ["name"] = "jellyfish in bottle",
                  ["inspect_str"] = "jellyfish needs it by aside",
                  ["item_fail"] = "already have a jellyfish",
            },
            ["tbat_item_maple_squirrel_kit"] = {
                  ["name"] = "maple squirrel kit",
                  ["inspect_str"] = "Master, your baby is cold...can we cuddle",
                  ["recipe_desc"] = "cold...need a cuddle",
            },
            ["tbat_item_maple_squirrel"] = {
                  ["name"] = "maple squirrel",
                  ["inspect_str"] = "Group Hug!",
            },
            ["tbat_item_snow_plum_wolf_kit"] = {
                  ["name"] = "snow plum wolf kit",
                  ["inspect_str"] = "I'm willing to guide you through the night, my master",
                  ["recipe_desc"] = "I'm willing to guide you through the night, my master",
            },
            ["tbat_item_snow_plum_wolf"] = {
                  ["name"] = "snow plum wolf",
                  ["inspect_str"] = "I'm willing to guide you through the night, my master",
            },
            ["tbat_item_trans_core"] = {
                  ["name"] = "trans core",
                  ["inspect_str"] = "this can lead me to my home",
                  ["recipe_desc"] = "this can lead me to my home",
            },
            ["tbat_item_blueprint"] = {
                  ["name"] = "blueprint",
                  ["inspect_str"] = "tbat_item_blueprint",
                  ["recipe_desc"] = "tbat_item_blueprint",
            },
            ["tbat_item_snow_plum_wolf_kit_blueprint2"] = {
                  ["name"] = "snow plum wolf kit blueprint2",
                  ["inspect_str"] = "Will you stay with me, Clan Leader MeiXue?",
            },
            ["tbat_eq_furrycat_circlet_blueprint2"] = {
                  ["name"] = "furrycat circlet blueprint2",
                  ["inspect_str"] = "I can make a pair of cat ears",
            },
            ["tbat_item_maple_squirrel_kit_blueprint2"] = {
                  ["name"] = "maple squirrel kit blueprint2",
                  ["inspect_str"] = "I will not suffer from cold with this!",
            },
            ["tbat_building_snow_plum_pet_house_blueprint2"] = {
                  ["name"] = "snow plum pet house blueprint2",
                  ["inspect_str"] = "Finally I can build this",
            },
            ["tbat_building_osmanthus_cat_pet_house_blueprint2"] = {
                  ["name"] = "osmanthus cat pet house blueprint2",
                  ["inspect_str"] = "Finally I can build this",
            },
            ["tbat_item_notes_of_adventurer"] = {
                  ["name"] = "notes of adventurer",
                  ["inspect_str"] = "notes of adventurer",
            },
            ["tbat_item_notes_of_adventurer_1"] = {
                  ["name"] = "notes of adventurer : 1",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "Can you read it out loud for me? I have something I can give you in return",
            },
            ["tbat_item_notes_of_adventurer_2"] = {
                  ["name"] = "notes of adventurer : 2",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "I see... it's a fascinating creature, isn't it?",
            },
            ["tbat_item_notes_of_adventurer_3"] = {
                  ["name"] = "notes of adventurer : 3",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "I see... it's a fascinating creature, isn't it?",
            },
            ["tbat_item_notes_of_adventurer_4"] = {
                  ["name"] = "notes of adventurer : 4",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "I wonder if this is what she hoped for. It really is captivating",
            },
            ["tbat_item_notes_of_adventurer_5"] = {
                  ["name"] = "notes of adventurer : 5",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "I wonder if this is what she hoped for. It really is captivating.",
            },
            ["tbat_item_notes_of_adventurer_6"] = {
                  ["name"] = "notes of adventurer : 6",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "It's a cute little thing! The red leaves do hide the other colors, though.",
            },
            ["tbat_item_notes_of_adventurer_7"] = {
                  ["name"] = "notes of adventurer : 7",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "It's a cute little thing! The red leaves do hide the other colors, though.",
            },
            ["tbat_item_notes_of_adventurer_8"] = {
                  ["name"] = "notes of adventurer : 8",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "It's a cute little thing! The red leaves do hide the other colors, though",
            },
            ["tbat_item_notes_of_adventurer_9"] = {
                  ["name"] = "notes of adventurer : 9",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "A place of the dead, you mean? Is it real, though…?",
            },
            ["tbat_item_notes_of_adventurer_10"] = {
                  ["name"] = "notes of adventurer : 10",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "A place of the dead, you mean? Is it real, though…?",
            },
            ["tbat_item_notes_of_adventurer_11"] = {
                  ["name"] = "notes of adventurer : 11",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "Rebirth as an illusion, and the departed are no longer the same…",
            },
            ["tbat_item_notes_of_adventurer_12"] = {
                  ["name"] = "notes of adventurer: 12",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "Rebirth as an illusion, and the departed are no longer the same…",
            },
            ["tbat_item_notes_of_adventurer_13"] = {
                  ["name"] = "notes of adventurer : 13",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "Rebirth as an illusion, and the departed are no longer the same…",
            },
            ["tbat_item_notes_of_adventurer_14"] = {
                  ["name"] = "notes of adventurer : 14",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "Rebirth as an illusion, and the departed are no longer the same…",
            },
            ["tbat_item_notes_of_adventurer_15"] = {
                  ["name"] = "notes of adventurer : 15",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "The tenderness beneath the sharpness, it's so easy to get lost in it",
            },
            ["tbat_item_notes_of_adventurer_16"] = {
                  ["name"] = "notes of adventurer : 16",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "The tenderness beneath the sharpness, it's so easy to get lost in it",
            },
            ["tbat_item_notes_of_adventurer_17"] = {
                  ["name"] = "notes of adventurer : 17",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "like living in a sweet dream",
            },
            ["tbat_item_notes_of_adventurer_18"] = {
                  ["name"] = "notes of adventurer : 18",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "like living in a sweet dream",
            },
            ["tbat_item_notes_of_adventurer_19"] = {
                  ["name"] = "notes of adventurer : 19",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "Navigating through the mystery, illusions as absurd murmurs…",
            },
            ["tbat_item_notes_of_adventurer_20"] = {
                  ["name"] = "notes of adventurer : 20",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "Navigating through the mystery, illusions as absurd murmurs…",
            },
            ["tbat_item_notes_of_adventurer_21"] = {
                  ["name"] = "notes of adventurer : 21",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "When the soul finds its place, everything feels real",
            },
            ["tbat_item_notes_of_adventurer_22"] = {
                  ["name"] = "notes of adventurer : 22",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "When the soul finds its place, everything feels real",
            },
            ["tbat_item_notes_of_adventurer_23"] = {
                  ["name"] = "notes of adventurer : 23",
                  ["inspect_str"] = "Who left this here? Maybe I should ask that big green bird",
                  ["traded_str"] = "When the soul finds its place, everything feels real",
            },
      ---------------------------------------------------------------------------------------
      -- 02_tbat_materials
            ["tbat_material_miragewood"] = {
                  ["name"] = "miragewood",
                  ["inspect_str"] = "special wood",
            },
            ["tbat_material_dandelion_umbrella"] = {
                  ["name"] = "dandelion umbrella",
                  ["inspect_str"] = "Head towards the direction you want to go.",
                  ["no_target"] = "it goes away...",
            },
            ["tbat_material_dandycat"] = {
                  ["name"] = "dandycat",
                  ["inspect_str"] = "That soft, fuzzy feeling is always so comforting",
            },
            ["tbat_material_wish_token"] = {
                  ["name"] = "wish token",
                  ["inspect_str"] = "It's like there's some kind of psychic energy flowing through it",
            },
            ["tbat_material_white_plum_blossom"] = {
                  ["name"] = "white plum blossom",
                  ["inspect_str"] = "A symbol of king",
            },
            ["tbat_material_snow_plum_wolf_hair"] = {
                  ["name"] = "snow plum wolf hair",
                  ["inspect_str"] = "Warm fur, yet with tiny shards of frost—an odd mix of comfort and cold",
            },
            ["tbat_material_snow_plum_wolf_heart"] = {
                  ["name"] = "snow plum wolf heart",
                  ["inspect_str"] = "feels like it's still alive in your hands",
            },
            ["tbat_material_osmanthus_ball"] = {
                  ["name"] = "osmanthus ball",
                  ["inspect_str"] = "Is this a cat toy~?",
            },
            ["tbat_material_osmanthus_wine"] = {
                  ["name"] = "osmanthus wine",
                  ["inspect_str"] = "can cats drink~?",
            },
            ["tbat_material_emerald_feather"] = {
                  ["name"] = "emerald feather",
                  ["inspect_str"] = "emerald feather",
            },
            ["tbat_material_liquid_of_maple_leaves"] = {
                  ["name"] = "liquid of maple leaves",
                  ["inspect_str"] = "Like it's some sort of adhesive, binding things together in an unseen way",
            },
            ["tbat_material_squirrel_incisors"] = {
                  ["name"] = "squirrel incisors",
                  ["inspect_str"] = "this is...squirrel's big gold tooth?",
            },
            ["tbat_material_sunflower_seeds"] = {
                  ["name"] = "sunflower seeds",
                  ["inspect_str"] = "sunflower seeds, but can not be planted",
            },
            ["tbat_material_starshard_dust"] = {
                  ["name"] = "starshard dust",
                  ["inspect_str"] = "starshard dust",
            },
      ---------------------------------------------------------------------------------------
      -- 03_tbat_equipments
            ["tbat_eq_fantasy_tool"] = {
                  ["name"] = "fantasy tool",
                  ["inspect_str"] = "If the little ones could hold tools and help out, that'd be perfect!~",
                  ["recipe_desc"] = "If the little ones could hold tools and help out, that'd be perfect!~",
                  ["hammer_on"] = "hammer, on",
                  ["hammer_off"] = "hammer, off",
            },
            ["tbat_eq_universal_baton"] = {
                  ["name"] = "universal baton",
                  ["inspect_str"] = "all eyes on me~",
                  ["recipe_desc"] = "All eyes on me~",
                  ["item_accept_fail"] = "已经不能继续升级了",
            },
            ["tbat_eq_shake_cup"] = {
                  ["name"] = "shake cup",
                  ["inspect_str"] = "shake it then drink it?",
                  ["recipe_desc"] = "shake it then drink it?",
            },
            ["tbat_eq_world_skipper"] = {
                  ["name"] = "world skipper",
                  ["inspect_str"] = "It can take you to both poetry and distant horizons, the best of both worlds",
                  ["recipe_desc"] = "It can take you to both poetry and distant horizons, the best of both worlds",
                  ["action_str"] = "world skipper",
            },
            ["tbat_eq_furrycat_circlet"] = {
                  ["name"] = "furrycat criclet",
                  ["inspect_str"] = "A circlet with the scent of osmanthus—so sweet and nostalgic~",
                  ["recipe_desc"] = "A circlet with the scent of osmanthus—so sweet and nostalgic~",
            },
      ---------------------------------------------------------------------------------------
      -- 04_tbat_foods
            ["tbat_food_hedgehog_cactus_meat"] = {
                  ["name"] = "hedgehog cactus meat",
                  ["inspect_str"] = "delicious...but whose meat is this!?",
            },
            ["tbat_food_pear_blossom_petals"] = {
                  ["name"] = "pear blossome petals",
                  ["inspect_str"] = "delicious pear blossom petals",
            },
            ["tbat_food_cherry_blossom_petals"] = {
                  ["name"] = "cherry blossom petals",
                  ["inspect_str"] = "Pink clouds that pull you in, almost like floating in a dream",
            },
            ["tbat_food_valorbush"] = {
                  ["name"] = "valorbush",
                  ["inspect_str"] = "That sounds perfect—pink clouds and flower tea",
            },
            ["tbat_food_crimson_bramblefruit"] = {
                  ["name"] = "crimson bramblefruit",
                  ["inspect_str"] = "Sweet wild fruits, a tempting trap?",
            },
            ["tbat_food_jellyfish"] = {
                  ["name"] = "jellyfish",
                  ["inspect_str"] = "what? It shrinked",
            },
            ["tbat_food_jellyfish_dried"] = {
                  ["name"] = "jellyfish dried",
                  ["inspect_str"] = "like hermit crabs drying her seaweed",
            },
            ["tbat_food_raw_meat"] = {
                  ["name"] = "raw meat",
                  ["inspect_str"] = "from what kind of animal?",
            },
            ["tbat_food_raw_meat_cooked"] = {
                  ["name"] = "raw meat cooked",
                  ["inspect_str"] = "smells good~",
            },
            ["tbat_food_cocoanut"] = {
                  ["name"] = "cocoanut",
                  ["inspect_str"] = "cocoanut~",
            },
      ---------------------------------------------------------------------------------------
      -- 05_tbat_foods_cooked
      ---------------------------------------------------------------------------------------
      -- 06_tbat_containers
            ["tbat_container_pear_cat"] = {
                  ["name"] = "pear cat",
                  ["inspect_str"] = "Thousands of pear blossoms bloom, and they all come to my home",
                  ["recipe_desc"] = "Thousands of pear blossoms bloom, and they all come to my home",
                  ["onbuild_talk"] = "I need materials to level up my pear cat",
            },
            ["tbat_container_cherry_blossom_rabbit_mini"] = {
                  ["name"] = "cherry blossom rabbit mini",
                  ["inspect_str"] = "A traveler of late spring, then—perfectly in tune with the season's final bloom～！",
                  ["recipe_desc"] = "A traveler of late spring, then—perfectly in tune with the season's final bloom～！",
                  ["onbuild_talk"] = "I need materials to level up my cheery blossom rabbit mini",
            },
            ["tbat_container_cherry_blossom_rabbit"] = {
                  ["name"] = "cheery blossom rabbit",
                  ["inspect_str"] = "A traveler of late spring, then—perfectly in tune with the season's final bloom～！",
            },
            ["tbat_container_emerald_feathered_bird_collection_chest"] = {
                  ["name"] = "emerald feathered bird collection chest",
                  ["inspect_str"] = "Riding the wind, bringing everything to you—such a graceful way to travel",
                  ["recipe_desc"] = "Riding the wind, bringing everything to you—such a graceful way to travel",
                  ["onbuild_talk"] = "Delete！Delete!",
            },
            ["tbat_container_squirrel_stash_box"] = {
                  ["name"] = "squirrel stash box",
                  ["inspect_str"] = "squirrel stash box",
                  ["recipe_desc"] = "squirrel's stash box",
            },
      ---------------------------------------------------------------------------------------
      -- 07_tbat_buildings
            ["tbat_the_tree_of_all_things"] = {
                  ["name"] = "tree of all things",
                  ["inspect_str"] = "The tree of all things, the source of everything",
            },
            ["tbat_the_tree_of_all_things_kit"] = {
                  ["name"] = "tree of all things kit",
                  ["inspect_str"] = "The tree of all things, the source of everything",
                  ["recipe_desc"] = "The tree of all things, the source of everything",
            },
            ["tbat_building_piano_rabbit"] = {
                  ["name"] = "piano rabbit",
                  ["inspect_str"] = "Adventurer, I can play different melody!",
                  ["recipe_desc"] = "Adventurer, I can play different melody!",
                  ["unlock_cmd_info_str"] = "Give item to unlock building}"
            },
            ["tbat_building_sunflower_hamster"] = {
                  ["name"] = "sunflower hamster",
                  ["inspect_str"] = "Absorbing sunlight to light the dark!",
                  ["recipe_desc"] = "Absorbing sunlight to light the dark!",
                  ["onbuild_talk"] = "Need materials to upgrade"
            },
            ["tbat_building_stump_table"] = {
                  ["name"] = "stump table",
                  ["inspect_str"] = "The food always steams when it's placed down—like it's fresh from the heart of a warm meal",
                  ["recipe_desc"] = "The food always steams when it's placed down—like it's fresh from the heart of a warm meal",
            },
            ["tbat_building_magic_potion_cabinet"] = {
                  ["name"] = "magic potion cabinet",
                  ["inspect_str"] = "all the treasures are placed in here",
                  ["recipe_desc"] = "all the treasures are placed in here",
            },
            ["tbat_building_plum_blossom_table"] = {
                  ["name"] = "plum blossom table",
                  ["inspect_str"] = "Those little, sneaky eyes—definitely plotting to snatch a bite!",
                  ["recipe_desc"] = "Those little, sneaky eyes—definitely plotting to snatch a bite!",
            },
            ["tbat_building_plum_blossom_hearth"] = {
                  ["name"] = "plum blossom hearth",
                  ["inspect_str"] = "cute furniture, decorated with wolf clan runes",
                  ["recipe_desc"] = "cute furniture, decorated with wolf clan runes",
            },
            ["tbat_building_cherry_blossom_rabbit_swing"] = {
                  ["name"] = "cherry blossom rabbit swing",
                  ["inspect_str"] = "Listening closely to the wind brushing past your ears",
                  ["recipe_desc"] = "Listening closely to the wind brushing past your ears",
            },
            ["tbat_building_red_spider_lily_rocking_chair"] = {
                  ["name"] = "red spider lily rocking chair",
                  ["inspect_str"] = "Restless joy, unpredictable and lazy in its own way",
                  ["recipe_desc"] = "Restless joy, unpredictable and lazy in its own way",
            },
            ["tbat_building_rough_cut_wood_sofa"] = {
                  ["name"] = "rough cut wood sofa",
                  ["inspect_str"] = "The fairies want to sit by my side",
                  ["recipe_desc"] = "The fairies want to sit by my side",
            },
            ["tbat_building_whisper_tome_squirrel_phonograph"] = {
                  ["name"] = "squirrel phonograph",
                  ["inspect_str"] = "Can squirrels sing?",
                  ["recipe_desc"] = "Can squirrels sing?",
            },
            ["tbat_building_woodland_lamp"] = {
                  ["name"] = "woodland lamp",
                  ["inspect_str"] = "soft light, but don't stare too long",
                  ["recipe_desc"] = "soft light, but don't stare too long",
            },
            ["tbat_building_conch_shell_decoration"] = {
                  ["name"] = "conch shell decoration",
                  ["inspect_str"] = "cute shell",
                  ["recipe_desc"] = "cute shell",
            },
            ["tbat_building_conch_shell_decoration_kit"] = {
                  ["name"] = "conch shell decoration kit",
                  ["inspect_str"] = "cute shell",
                  ["recipe_desc"] = "cute shell",
            },
            ["tbat_building_star_and_cloud_decoration"] = {
                  ["name"] = "star and cloud decoration",
                  ["inspect_str"] = "Stars and the moon winking at you",
                  ["recipe_desc"] = "Stars and the moon winking at you",
            },
            ["tbat_building_star_and_cloud_decoration_kit"] = {
                  ["name"] = "star and cloud decoration kit",
                  ["inspect_str"] = "Stars and the moon winking at you",
                  ["recipe_desc"] = "Stars and the moon winking at you",
            },
            ["tbat_building_snowflake_decoration"] = {
                  ["name"] = "snowflake decoration",
                  ["inspect_str"] = "delicate snowflake",
                  ["recipe_desc"] = "delicate snowflake",
            },
            ["tbat_building_snowflake_decoration_kit"] = {
                  ["name"] = "snowflake decoration kit",
                  ["inspect_str"] = "delicate snowflake",
                  ["recipe_desc"] = "delicate snowflake",
            },
            ["tbat_building_cute_pet_stone_figurines"] = {
                  ["name"] = "cute pet stone figurines",
                  ["inspect_str"] = "This way you can always be with me, right?",
                  ["recipe_desc"] = "This way you can always be with me, right?",
            },
            ["tbat_building_cute_pet_stone_figurines_kit"] = {
                  ["name"] = "cute pet stone figurines kit",
                  ["inspect_str"] = "This way you can always be with me, right?",
                  ["recipe_desc"] = "This way you can always be with me, right?",
            },
            ["tbat_building_cute_animal_decorative_figurines"] = {
                  ["name"] = "cute animal decorative figurines",
                  ["inspect_str"] = "Last time I met it, it even greeted me",
                  ["recipe_desc"] = "Last time I met it, it even greeted me",
            },
            ["tbat_building_cute_animal_decorative_figurines_kit"] = {
                  ["name"] = "cute animal decorative figurines kit",
                  ["inspect_str"] = "Last time I met it, it even greeted me",
                  ["recipe_desc"] = "Last time I met it, it even greeted me",
            },
            ["tbat_building_cute_animal_wooden_figurines"] = {
                  ["name"] = "cute animal wooden figurines",
                  ["inspect_str"] = "With you all, I'm never lonely!",
                  ["recipe_desc"] = "With you all, I'm never lonely!",
            },
            ["tbat_building_cute_animal_wooden_figurines_kit"] = {
                  ["name"] = "cute animal wooden figurines kit",
                  ["inspect_str"] = "With you all, I'm never lonely!",
                  ["recipe_desc"] = "With you all, I'm never lonely!",
            },
            ["tbat_building_carved_stone_tiles"] = {
                  ["name"] = "craved stone tiles",
                  ["inspect_str"] = "They say they're worried that I'll stub my foot",
                  ["recipe_desc"] = "They say they're worried that I'll stub my foot",
            },
            ["tbat_building_carved_stone_tiles_kit"] = {
                  ["name"] = "craved stone tiles kit",
                  ["inspect_str"] = "They say they're worried that I'll stub my foot",
                  ["recipe_desc"] = "They say they're worried that I'll stub my foot",
            },
            ["wall_tbat_wood"] = {
                  ["name"] = "plum blossom wood wall",
                  ["inspect_str"] = "Standing in the wind, searching for the fragrance of plum blossoms",
                  ["recipe_desc"] = "Standing in the wind, searching for the fragrance of plum blossoms",
            },
            ["wall_tbat_wood_item"] = {
                  ["name"] = "plum blossom wall item",
                  ["inspect_str"] = "Standing in the wind, searching for the fragrance of plum blossoms",
                  ["recipe_desc"] = "Standing in the wind, searching for the fragrance of plum blossoms",
            },
            ["tbat_building_recruitment_notice_board"] = {
                  ["name"] = "recruitment notice board",
                  ["inspect_str"] = "Thanks for exploring this mod. Welcome to join the Q group: 1049427294",
                  ["recipe_desc"] = "debug",
            },
            ["tbat_building_trade_notice_board"] = {
                  ["name"] = "trade notice board",
                  ["inspect_str"] = "Thanks for exploring this mod. Welcome to join the Q group: 1049427294",
                  ["recipe_desc"] = "debug",
            },
            ["tbat_building_pet_house_common"] = {
                  ["start_follow_player"] = "adopt this one",
                  ["stop_follow_player"] = "give back the animal",
                  ["give_back_item_fail"] = "No pets to return",
                  ["house_full"] = "It's already full here",
            },
            ["tbat_building_snow_plum_pet_house"] = {
                  ["name"] = "snow plum pet hosue",
                  ["inspect_str"] = "A faint plum blossom scent, so subtle yet enchanting",
                  ["recipe_desc"] = "A faint plum blossom scent, so subtle yet enchanting",
            },
            ["tbat_building_osmanthus_cat_pet_house"] = {
                  ["name"] = "osmanthus cat pet house",
                  ["inspect_str"] = "The rich scent of osmanthus—it's so refreshing, like a breath of calm",
                  ["recipe_desc"] = "The rich scent of osmanthus—it's so refreshing, like a breath of calm",
            },
            ["tbat_building_osmanthus_cat_pet_house_wild"] = {
                  ["name"] = "osmanthus cat pet house wild",
                  ["inspect_str"] = "The rich scent of osmanthus—it's so refreshing, like a breath of calm",
            },
      ---------------------------------------------------------------------------------------
      -- 08_tbat_resources
      ---------------------------------------------------------------------------------------
      -- 09_tbat_plants
            ["tbat_plant_wild_hedgehog_cactus"] = {
                  ["name"] = "wild hedgehog cactus",
                  ["inspect_str"] = "Grumble grumble, rolling hedgehog cactus",
            },
            ["tbat_plant_hedgehog_cactus_seed"] = {
                  ["name"] = "hedgehog cactus seed",
                  ["inspect_str"] = "Fluffy and prickly, but... kind of cute",
            },
            ["tbat_plant_hedgehog_cactus_pot"] = {
                  ["name"] = "hedgehog cactus pot",
                  ["inspect_str"] = "this place needs a special hedgehog cactus",
                  ["recipe_desc"] = "this place needs a special hedgehog cactus",
            },
            ["tbat_plant_hedgehog_cactus"] = {
                  ["name"] = "plant hedgehog cactus",
                  ["inspect_str"] = "I can take good care of them",
            },
            ["tbat_plant_coconut_tree"] = {
                  ["name"] = "plant coconut tree",
                  ["inspect_str"] = "Ah, a cat tree",
            },
            ["tbat_plant_coconut_cat_fruit"] = {
                  ["name"] = "plant coconut cat fruit",
                  ["inspect_str"] = "How can I get her down?",
            },
            ["tbat_plant_coconut_tree_seed"] = {
                  ["name"] = "plant coconut tree seed",
                  ["inspect_str"] = "can be planted",
            },
            ["tbat_plant_coconut_cat_kit"] = {
                  ["name"] = "coconut cat kit",
                  ["inspect_str"] = "A little kitten swaying its head~~",
            },
            ["tbat_plant_coconut_cat"] = {
                  ["name"] = "coconut cat",
                  ["inspect_str"] = "A little kitten swaying its head~~",
            },
            ["tbat_plant_pear_blossom_tree"] = {
                  ["name"] = "pear blossom tree",
                  ["inspect_str"] = "Before the rain, the begonia blooms; before the snow, the pear blossoms",
            },
            ["tbat_plant_pear_blossom_tree_kit"] = {
                  ["name"] = "pear blossom tree kit",
                  ["inspect_str"] = "Before the rain, the begonia blooms; before the snow, the pear blossom",
            },
            ["tbat_plant_cherry_blossom_tree"] = {
                  ["name"] = "cherry blossom tree",
                  ["inspect_str"] = "Falling cherry blossoms, the first rain of spring",
            },
            ["tbat_plant_cherry_blossom_tree_kit"] = {
                  ["name"] = "cherry blossom tree kit",
                  ["inspect_str"] = "Falling cherry blossoms, the first rain of spring",
            },
            ["tbat_plant_crimson_maple_tree"] = {
                  ["name"] = "crimson maple tree",
                  ["inspect_str"] = "The maple leaves in autumn look so warm, like they're holding onto the last bit of summer's glow",
            },
            ["tbat_plant_crimson_maple_tree_kit"] = {
                  ["name"] = "crimson maple tree kit",
                  ["inspect_str"] = "It can grow fiery red maple leaves",
            },
            ["tbat_plant_valorbush"] = {
                  ["name"] = "valorbush",
                  ["inspect_str"] = "valorbush",
            },
            ["tbat_plant_valorbush_kit"] = {
                  ["name"] = "valorbush kit",
                  ["inspect_str"] = "beautiful creature, I'm bring it home",
            },
            ["tbat_plant_crimson_bramblefruit"] = {
                  ["name"] = "crimson bramblefruit",
                  ["inspect_str"] = "crimson bramble fruit",
            },
            ["tbat_plant_crimson_bramblefruit_kit"] = {
                  ["name"] = "crimson bramblefruit kit",
                  ["inspect_str"] = "A thorny plant, but it might fill your stomach?",
            },
            ["tbat_plant_dandycat"] = {
                  ["name"] = "dandycat",
                  ["inspect_str"] = "It's inviting you to explore the world together",
            },
            ["tbat_plant_dandycat_kit"] = {
                  ["name"] = "dandycat kit",
                  ["inspect_str"] = "A traveler of the wind, moving with the breeze",
            },
            ["tbat_projectile_dandelion_umbrella"] = {
                  ["name"] = "dandelion umbrella",
                  ["inspect_str"] = "Head in the direction you want to go",
            },
            ["tbat_plant_jellyfish"] = {
                  ["name"] = "jellyfish",
                  ["inspect_str"] = "dandycat's friend",
                  ["random_talk"] = {"Dandelion cat? You are my best friend in this world."},
                  ["player_close"] = {"Dandelion cat, look! It's an adventurer!","Adventurer, you can make a wish to me！"}
            },
      ---------------------------------------------------------------------------------------
      -- 10_tbat_minerals
      ---------------------------------------------------------------------------------------
      -- 11_tbat_animals
            ["tbat_animal_snow_plum_chieftain"] = {
                  ["name"] = "snow plum chieftain",
                  ["name_pet"] = "tamed snow plum chieftain",
                  ["inspect_str"] = "The first snow falls on the plum branches, transforming into a winter spirit",
            },
            ["tbat_animal_osmanthus_cat"] = {
                  ["name"] = "osmanthus cat",
                  ["name_pet"] = "tamed osmanthus cat",
                  ["inspect_str"] = "Osmanthus flowers carrying wine, and thoughts of an old friend",
            },
      ---------------------------------------------------------------------------------------
      -- 12_tbat_boss
      ---------------------------------------------------------------------------------------
      -- 13_tbat_pets
            ["tbat_pet_eyebone"] = {
                  ["name"] = "pet eyebone",
                  ["inspect_str"] = "The follow item for pets in this mod",
                  ["has_owner"] = "seems like this one already has another master",
                  ["owner_is_player"] = "I am this one's owner",
                  ["has_same_pet"] = "I already have a same one",
            },
      ---------------------------------------------------------------------------------------
      -- 14_tbat_turfs
            ["tbat_turf_water_lily_cat"] = {
                  ["name"] = "water lily cat",
                  ["wild_inspect_str"] = "The Dreamweaver at the heart of the lake",
                  ["inspect_str"] = "It… it seems to like being stepped on!",
                  ["grow_blocking"] = "The Dreamweaver at the heart of the lake needs activation to grow",
                  -- ["recipe_desc"] = "The Dreamweaver at the heart of the lake",
                  ["dig_faild"] = "If someone stands on it and digs, it sounds pretty dangerous",
                  ["dig_faild_cd"] = "Seems pretty sturdy, huh? Might need a few attempts to really test its limits",
            },   
            ["tbat_turf_water_lily_cat_seed"] = {
                  ["name"] = "water lily cat seed",
                  ["inspect_str"] = "It… it seems to like being stepped on!",
            },   
            ["tbat_turf_water_lily_cat_leaf"] = {
                  ["name"] = "water lily cat leaf",
                  ["inspect_str"] = "cute thing, but how do I plant it?",
            },   
            ["turf_tbat_turf_emerald_feather_leaves"] = {
                  ["name"] = "emerald feather leaves",
                  ["inspect_str"] = "Sounds like you've been at it for a while—plucking feathers until the bird's nearly bald",
                  ["recipe_desc"] = "Sounds like you've been at it for a while—plucking feathers until the bird's nearly bald",
            },
            ["turf_tbat_turf_fallen_cherry_blossoms"] = {
                  ["name"] = "fallen cherry blossom",
                  ["inspect_str"] = "The beautiful cherry blossoms make you feel like you're floating among the clouds",
                  ["recipe_desc"] = "The beautiful cherry blossoms make you feel like you're floating among the clouds",
            },
            ["turf_tbat_turf_pearblossom_brewed_with_snow"] = {
                  ["name"] = "pearblossom brewed with snow",
                  ["inspect_str"] = "pearblossom brewed with snow",
                  ["recipe_desc"] = "pearblossom brewed with snow",
            },
      ---------------------------------------------------------------------------------------
      -- 15_tbat_debuffs
      ---------------------------------------------------------------------------------------
      -- 16_tbat_spells
      ---------------------------------------------------------------------------------------
      -- 17_tbat_sfx
            ["tbat_sfx_ground_fireflies"] = {
                  ["name"] = "ground fireflies",
                  ["inspect_str"] = "ground fireflies",
                  ["recipe_desc"] = "ground fireflies",
            },
      ---------------------------------------------------------------------------------------
      -- 18_tbat_projectiles
      ---------------------------------------------------------------------------------------
      -- 19_tbat_characters
      ---------------------------------------------------------------------------------------
      -- 20_tbat_events
      ---------------------------------------------------------------------------------------
      -- 21_tbat_rooms
            ["tbat_room_anchor_fantasy_island_main"] = {
                  ["name"] = "anchor fantasy land : Main",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_room_anchor_fantasy_island_a"] = {
                  ["name"] = "anchor fantasy land : A",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_room_anchor_fantasy_island_b"] = {
                  ["name"] = "anchor fantasy land: B",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_room_anchor_fantasy_island_c"] = {
                  ["name"] = "anchor fantasy land : C",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_room_anchor_fantasy_island_d"] = {
                  ["name"] = "anchor fantasy land : D",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_room_anchor_fantasy_island_e"] = {
                  ["name"] = "anchor fantasy land : E",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_room_anchor_fantasy_island_f"] = {
                  ["name"] = "anchor fantasy land : F",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_room_anchor_fantasy_island_g"] = {
                  ["name"] = "anchor fantasy land : G",
                  ["inspect_str"] = "The anchor point of this plot",
            },
            ["tbat_eq_anchor_cane"] = {
                  ["name"] = "万物书：Anchor cane",
                  ["inspect_str"] = "Used to display the anchor point of this plot",
                  ["recipe_desc"] = "Used to gather anchor point data from the islands of this  mod",
            },
            ["tbat_room_mini_portal_door"] = {
                  ["name"] = "mini portal door",
                  ["inspect_str"] = "to exit the island",
            },
      ---------------------------------------------------------------------------------------
      -- 22_tbat_npc
            ["tbat_npc_emerald_feather_bird"] = {
                  ["name"] = "emerald feather bird",
                  ["inspect_str"] = "Its feather looks fabulous",
                  ["wander_talk"] = {
                        "The one who used my leaves to write notes seems to have disappeared... Where did she go?",
                        "What are humans really up to? Why don't they want to play with me? I… kind of miss her.",
                        "It seems like she wrote a lot—everything from autumn to spring, from the scorching heat to frost and snow. ",
                        "She won't be coming back... but will you all stay with me?",
                  },
                  ["item_accept_talk"] = {
                        "Oh，I'm looking for this!","Oh,thank you","Thanks for bringing me this！","Thanks, friend！",
                  },
            },
      ---------------------------------------------------------------------------------------
      ------mz
      ["tbat_sensangu"] = {
            ["name"] = "森伞菇",
            ["inspect_str"] = "森伞菇",
      },
      ["tbat_sensangu_item"] = {
            ["name"] = "森伞小菇",
            ["inspect_str"] = "森伞小菇",
      },
}
