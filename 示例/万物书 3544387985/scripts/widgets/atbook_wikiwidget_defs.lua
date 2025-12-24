local CONTENT = {
    CREATURE = {
        A = {
            {
                prefab = "tbat_animal_maple_squirrel",
                name = "枫叶松鼠",
                type = "生物",
                ys = {
                    sc = "跟随野外的秋枫树屋绑定一只枫叶松鼠",
                    sd = "280血量，15攻击，白天出现，击杀后掉落留影枫叶，枫液，概率掉落秋枫树苗，秋枫树屋蓝图，枫叶鼠鼠蓝图",
                    tx = "死亡三天后重生，可用陷阱捕捉，野生的枫叶松鼠会偷偷的把周围掉落物全部藏进嘴巴里，注意！带着贵重物品的冒险家，靠近松鼠时，请格外小心！"
                },
                jy = {
                    sc = "跟随玩家自建的秋枫树屋生成",
                    sd = "280血量，15攻击，95%减伤，右键宠物可跟随，右键房屋可寄养，死亡无掉落",
                    tx = "跟随会为主人提供免疫火焰类型的伤害，枫叶松鼠非常胆小且狗腿，主人打架时，只会摇旗呐喊，只有自己在遭受攻击时才会还手！"
                },
            },
            {
                prefab = "tbat_animal_osmanthus_cat",
                name = "桂花猫猫",
                type = "生物",
                ys = {
                    sc = "跟随野外的桂猫石屋绑定一只桂花猫猫",
                    sd = "900血量，36攻击，白天出现，击杀掉落桂花酒，概率掉落桂花球，桂猫石屋蓝图，猫猫花环蓝图",
                    tx = "死亡三天后重生"
                },
                jy = {
                    sc = "跟随玩家自建的桂猫石屋生成",
                    sd = "900血量，36攻击，90%减伤，右键宠物可跟随，右键房屋可寄养，死亡无掉落",
                    tx = "跟随会为主人提供大量的理智恢复，会帮助主人一起战斗"
                },
            },
            {
                prefab = "tbat_animal_snow_plum_chieftain",
                name = "梅雪族长",
                type = "生物",
                ys = {
                    sc = "冬天黄昏夜晚翻脚印有概率出现",
                    sd = "1200血量，60攻击，击杀掉落狼毛，概率掉落狼心，梅雪木屋蓝图，梅雪小狼蓝图",
                    tx = "梅雪族长非常贪吃，会主动吃掉地上的任何可食用食物，击杀它或许不一定非要战斗奥"
                },
                jy = {
                    sc = "跟随玩家自建的梅雪木屋生成",
                    sd = "800血量，45攻击，90%减伤，右键宠物可跟随，右键房屋可寄养，死亡无掉落",
                    tx = "会帮主人一起战斗，梅雪族长进食一块新鲜的肉，可增加梅雪族长50%的攻击力，跟随会为自己和主人共同提供冰冻抵抗，梅雪族长非常贪吃，可以通过小手段，让其发光或带电"
                },
            },
            {
                prefab = "tbat_eq_ray_fish_hat",
                name = "帽子鳐鱼",
                type = "生物",
                ys = {
                    sc = "跟随野外的礁石灯塔绑定一只帽子鳐鱼",
                    sd = "360血量，20攻击，击杀掉落水晶气泡，概率掉落礁石灯塔蓝图，鳐鱼帽子蓝图",
                    tx = "被攻击时会给敌方附加中毒，每秒持续掉血，帽子鳐鱼会主动攻击盐矿附近的饼干切割机，海洋的敌对生物岩石鲨鱼和鱿鱼，死亡三天后重生"
                },
                jy = {
                    sc = "跟随玩家自建的礁石灯塔生成",
                    sd = "360血量，20攻击，95%位面伤害防御，右键宠物可跟随，右键房屋可寄养，死亡无掉落",
                    tx = "会帮主人一起战斗，给敌方目标附加中毒效果，跟随会为主人恢复理智，自动采集藤壶"
                },
            },
            {
                prefab = "tbat_pet_lavender_kitty",
                name = "薰衣草猫猫",
                type = "生物",
                ys = {
                    sc = "跟随野外的薰衣草花房绑定一只薰衣草猫猫",
                    sd = "360血量，不会攻击，也不会被攻击，击杀无掉落物",
                    tx = "给予薰衣草猫猫六个薰衣草花穗，会返还玩家一瓶薰衣草洗衣液。"
                },
                jy = {
                    sc = "跟随玩家自建的薰衣草花房生成",
                    sd = "360血量，右键宠物可跟随，右键房屋可寄养，不会被攻击，无掉落物",
                    tx = "跟随主人不会增加潮湿度，屏幕会出现拾取按钮，开启状态下，会自动拾取附近掉落物到主人身上"
                },
            },
            {
                prefab = "tbat_animal_mushroom_snail",
                name = "蘑埚蜗牛",
                type = "生物",
                ys = {
                    sc = "跟随野外的森林蘑菇小窝绑定一只蘑埚蜗牛",
                    sd = "300血量，35伤害，龟速爬行，击杀掉落发光蘑菇，荧光苔藓，概率掉落森伞小菇",
                    tx = "蘑埚蜗牛会在家附近种植荧光苔藓和发光蘑菇，注意：社恐的蜗牛会记住揍它的坏人"
                },
                jy = {
                    sc = "跟随玩家自建的森林蘑菇小窝生成",
                    sd = "300血量，35伤害，龟速爬行，死亡无掉落",
                    tx = "蜗牛会在家附近种植苔藓和蘑菇；跟随主人炼制药剂时双倍收获"
                },
            }
        },
        B = {
            {
                prefab = "tbat_npc_emerald_feather_bird",
                name = "翠羽鸟",
                type = "生物",
                base = {
                    sc = "跟随万物之树生成",
                    sd = "万物书的百事通，和万物书所有生物都很熟络，如果你在万物书里有什么问题大可以找它帮忙",
                    tx = "一只碎嘴子绿色大鸟，如果你有冒险家笔记，记得交给它！"
                }
            },
            {
                prefab = "tbat_plant_jellyfish",
                name = "风铃水母",
                type = "生物",
                base = {
                    sc = "跟随野生的蒲公英猫猫生成",
                    sd = "600血量，不会攻击，死亡后三天重生，击杀掉落祈愿牌，死亡的风铃水母",
                    tx = "风铃水母可与玩家兑换各种万物书的稀有物资，每次兑换有概率失败，请冒险家做好心里准备，可通过伴生水母素，移植到家中"
                }
            },
            {
                prefab = "tbat_animal_ephemeral_butterfly",
                name = "昙花蝴蝶",
                type = "生物",
                base = {
                    sc = "跟随识之昙花周围生成",
                    sd = "击杀掉落昙花蝴蝶翅膀，识之昙花",
                    tx = "黄昏晚上出没，可用捕虫网捕获，可右键种植成识之昙花"
                }
            },
            {
                prefab = "tbat_animal_four_leaves_clover_crane",
                name = "四叶草鹤",
                type = "生物",
                base = {
                    sc = "跟随二阶段四叶草鹤雕像附近生成",
                    sd = "生命值666，不会攻击，也不会被攻击",
                    tx = "四叶草鹤会给你带来非常好的运气，在没有四叶草鹤跟随的情况下，触摸雕像会绑定一只并随机获得好运buff，给予四叶草鹤记忆水晶，四叶草鹤会带着运气一起消失"
                }
            }
        },
    },
    PLANT = {
        A = {
            {
                prefab = "tbat_plant_wild_hedgehog_cactus",
                name = "刺猬小仙",
                type = "植物",
                ys = {
                    sc = "沙漠绿洲处生成",
                    sd = "共三个生长阶段，采集掉落小仙肉",
                    tx = "不能被移植和破坏"
                },
                yz = {
                    sc = "用小仙肉和风铃水母兑换成小仙种子，给予万物盆栽后变成刺猬小仙盆栽",
                    sd = "共三个生长阶段，三阶段采集掉落小仙肉",
                    tx = "放置后，附近的植物会被照顾，不会让其枯萎和自燃"
                }
            },
            {
                prefab = "tbat_plant_dandycat",
                name = "蒲公英猫猫",
                type = "植物",
                ys = {
                    sc = "巨大蜂窝处生成",
                    sd = "共三个生长阶段，第二阶段，周围漂浮蒲公英花伞，可捕捉，第三阶段采集掉落蒲公英猫花朵",
                    tx = "不能被移植和破坏。蒲公英花伞在你前期探图会提供有力的帮助哦~"
                },
                yz = {
                    sc = "用蒲公英猫花朵和风铃水母兑换成蒲公英猫植株",
                    sd = "共三个生长阶段，二阶段，周围漂浮蒲公英花伞，可捕捉，三阶段采集掉落蒲公英猫花朵",
                    tx = "蒲公英猫猫和风铃水母是好朋友！一个蒲公英猫猫只会要一个伴生水母素哦~"
                }
            },
            {
                prefab = "tbat_turf_water_lily_cat",
                name = "睡莲猫猫",
                type = "植物",
                ys = {
                    sc = "水中木处生成",
                    sd = "共两个生长阶段，一阶段需要清甜椰子激活生长，二阶段可采集掉落睡莲猫猫莲叶",
                    tx = "睡莲猫猫很喜欢冒险家踩到它的身上，不要害怕，它皱眉的样子是在享受哦~"
                },
                yz = {
                    sc = "用睡莲猫猫莲叶和风铃水母兑换成睡莲猫猫植株",
                    sd = "共两个生长阶段，一阶段给予睡莲猫猫莲叶可升级成二阶段",
                    tx = "移植的睡莲猫猫二阶段无采集，为功能性植物，铺在任意水域，人物可行走"
                }
            },
            {
                prefab = "tbat_plant_coconut_tree",
                name = "清甜椰子树",
                type = "植物",
                ys = {
                    sc = "猴岛沙滩处生成",
                    sd = "共三个生长阶段，采集掉落清甜椰子，椰子肉",
                    tx = "不能被移植。悄悄话：树下那只小黑猫，听说是查理大人的小猫哦"
                },
                yz = {
                    sc = "用清甜椰子和风铃水母兑换成发芽的清甜椰子",
                    sd = "共三个生长阶段，采集掉落清甜椰子，椰子肉",
                    tx = "把清甜椰子在冷火处烤八分钟有惊喜哦~"
                }
            },
            {
                prefab = "tbat_sensangu",
                name = "森伞菇",
                type = "植物",
                base = {
                    sc = "蘑语林间地形生成",
                    sd = "共三个生长阶段，每个阶段需要给予水晶气泡使其生长",
                    tx = "一阶段拥有小范围发光，二阶段拥有范围防雷效果；三阶段拥有范围防雨，防月亮碎片雨，防酸雨效果"
                }
            },
            {
                prefab = "tbat_farm_plant_fantasy_potato_mutated",
                name = "土豆鸡",
                type = "农作物",
                base = {
                    sc = "种植幻想土豆种子长成，种子需要薰衣草猫猫的物资转换",
                    sd = "共五个生长阶段，采集掉落幻想土豆种子，幻想土豆",
                    tx = "巨大时状态会有30%概率异化成幻想土豆鸡，敲开幻想土豆鸡概率获得变异的土豆鸡种子，可直接种在地上，变为循环生长植物"
                }
            },
            {
                prefab = "tbat_farm_plant_fantasy_peach_mutated",
                name = "小桃兔",
                type = "农作物",
                base = {
                    sc = "种植幻想小兔种子长成，种子需要薰衣草猫猫的物资转换",
                    sd = "共五个生长阶段，采集掉落幻想小桃种子，幻想小桃",
                    tx = "巨大时状态会有30%概率异化成幻想小桃兔，敲开幻想小桃兔概率获得变异的小桃兔种子，可直接种在地上，变为循环生长植物"
                }
            },
            {
                prefab = "tbat_farm_plant_fantasy_apple_mutated",
                name = "苹果狗",
                type = "农作物",
                base = {
                    sc = "种植幻想苹果种子长成，种子需要薰衣草猫猫的物资转换",
                    sd = "共五个生长阶段，采集掉落幻想苹果种子，幻想苹果",
                    tx = "巨大时状态会有30%概率异化成幻想苹果狗，敲开幻想苹果狗概率获得变异的苹果狗种子，可直接种在地上，变为循环生长植物"
                }
            }
        },
        B = {
            {
                prefab = "tbat_plant_cherry_blossom_tree",
                name = "樱花树",
                type = "植物",
                base = {
                    sc = "幻想岛屿处生成",
                    sd = "两个生长阶段，二阶段砍伐掉落幻源木，樱花瓣，概率掉落樱花树苗",
                    tx = "树根可通过催熟成长为一阶段"
                }
            },
            {
                prefab = "tbat_plant_pear_blossom_tree",
                name = "梨花树",
                type = "植物",
                base = {
                    sc = "幻想岛屿处生成",
                    sd = "两个生长阶段，二阶段砍伐掉落幻源木，梨花瓣，概率掉落梨花树苗",
                    tx = "树根可通过催熟成长为一阶段"
                }
            },
            {
                prefab = "tbat_plant_crimson_maple_tree",
                name = "秋枫树",
                type = "植物",
                base = {
                    sc = "猪王桦树林处生成",
                    sd = "两个生长阶段，二阶段砍伐掉落幻源木，留影枫叶，概率掉落秋枫树苗",
                    tx = "树根可通过催熟成长为一阶段"
                }
            },
            {
                prefab = "tbat_plant_crimson_bramblefruit",
                name = "绯露莓刺藤",
                type = "植物",
                base = {
                    sc = "幻想岛屿处生成",
                    sd = "两个生长阶段，二阶段采集掉落绯露莓，概率掉落刺藤植株",
                    tx = "可移植"
                }
            },
            {
                prefab = "tbat_plant_valorbush",
                name = "勇者玫瑰灌木",
                type = "植物",
                base = {
                    sc = "幻想岛屿处生成",
                    sd = "两个生长阶段，二阶段采集掉落勇者玫瑰，概率掉落玫瑰植株",
                    tx = "可移植"
                }
            },
            {
                prefab = "tbat_eco_memory_crystal_vein",
                name = "记忆水晶矿源",
                type = "生态",
                base = {
                    sc = "矿区，蜘蛛矿区，幻想岛屿上生成",
                    sd = "三个生长阶段，一阶段铲除掉落记忆水晶矿心，二阶段开采掉落记忆水晶，石头，三阶开采掉落记忆水晶，石头，月岩",
                    tx = "可用记忆水晶矿心种植记忆水晶矿源"
                }
            },
            {
                prefab = "tbat_plant_ephemeral_flower",
                name = "识之昙花",
                type = "植物",
                base = {
                    sc = "跟随初始记忆水晶矿源生成",
                    sd = "采集获得识之昙花并且回复理智和血量",
                    tx = "夜晚识之昙花附近会出现昙花蝴蝶，右键种植昙花蝴蝶变成识之昙花"
                }
            },
            {
                prefab = "tbat_plant_osmanthus_bush",
                name = "桂花矮树",
                type = "植物",
                base = {
                    sc = "跟随野外的桂猫石屋生成",
                    sd = "三个生长阶段，采集掉落桂花球，蜂蜜，概率掉落挖起的桂花矮树、蜂蜡",
                    tx = "可移植"
                }
            },
            {
                prefab = "tbat_plant_lavender_bush",
                name = "薰衣草草丛",
                type = "植物",
                base = {
                    sc = "完成野外的薰衣草花房任务随机出现在薰衣草花房周边",
                    sd = "三个生长阶段，采集掉落薰衣草花穗",
                    tx = "可移植"
                }
            }
        }
    },
    STRUCTURE = {
        A = {
            {
                prefab = "tbat_building_osmanthus_cat_pet_house",
                name = "桂猫石屋",
                type = "房屋",
                ys = {
                    sc = "墓地地形生成",
                    sd = "每个桂猫石屋会绑定一只桂花猫猫",
                    tx = "人物靠近会提供大量的理智恢复"
                },
                zj = {
                    sc = "击杀桂花猫猫概率掉落蓝图",
                    pf = "桂花酒，桂花球，留影枫叶，幻源木",
                    tx = "建造后会出现一只驯养的桂花猫猫，右键宠物可领养，右键房屋可寄养，在万物之树附近建造会长出桂猫树藤，在树藤里放入桂花酒*1，桂花球*1，每天天亮增加物品数"
                }
            },
            {
                prefab = "tbat_building_wintersnow_tree_house",
                name = "梅雪树屋",
                type = "房屋",
                base = {
                    sc = "击杀梅雪族长概率掉落蓝图",
                    pf = "狼毛，狼心，白梅花，留影枫叶，幻源木",
                    tx =
                    "建造后会出现一只驯养的梅雪族长，右键宠物可领养，右键房屋可寄养。梅雪族长很贪吃，珍贵食材请不要随地乱放哦，在万物之树附近建造会长出梅雪树藤，在树藤里放入狼毛*1，白梅花*1，每天天亮添加物品数"
                }
            },
            {
                prefab = "tbat_building_maple_squirrel_pet_house",
                name = "秋枫树屋",
                type = "房屋",
                ys = {
                    sc = "桦树林处生成",
                    sd = "每个秋枫树屋会绑定一只枫叶松鼠",
                    tx = "白天可用葵瓜子和树屋交互，概率获得留影枫叶，松鼠牙，秋枫树苗，注意：黄昏和夜晚来交互会狠狠被枫叶松鼠挠的！"
                },
                zj = {
                    sc = "击杀枫叶松鼠概率掉落蓝图",
                    pf = "枫液，留影枫叶，松鼠牙，幻源木",
                    tx = "建造后会出现一只驯养的枫叶松鼠，右键宠物可领养，右键房屋可寄养。在万物之树附近建造会长出秋枫树藤，在树藤里放入枫液*1，留影枫叶*1，每天天亮增加物品数"
                }
            },
            {
                prefab = "tbat_building_fourleaf_statue",
                name = "四叶草雕像",
                type = "房屋",
                ys = {
                    sc = "初始在月台森林地区生成",
                    sd = "在月圆之夜给予四叶草鹤雕像五个翠羽鸟羽毛可使其复苏",
                    tx = "复苏后的四叶草鹤雕像附近会出现四叶草鹤，触摸雕像可以抽取一只带有好运buff的鹤跟随，当已有鹤跟随时触摸雕像，则会获得四叶草鹤的羽毛"
                },
                zj = {
                    sc = "触摸四叶草鹤雕像时有概率掉落蓝图",
                    pf = "四叶草鹤羽毛，祈愿牌",
                    tx = "与野生版特性一样，不过，你可以把神奇的好运雕像带回家了。"
                }
            },
            {
                prefab = "tbat_building_lavender_flower_house",
                name = "薰衣草花房",
                type = "房屋",
                ys = {
                    sc = "月岛固定生成",
                    sd = "每个薰衣草花房房子绑定一只薰衣草猫猫",
                    tx = "小屋拥有五格ui和一个装饰按键，可以进行五个装饰任务，每提交成功一次任务，薰衣草花房周围会生成两株薰衣草草丛，任务完成时，小屋会掉落薰衣草花房蓝图，薰衣草小猫蓝图"
                },
                zj = {
                    sc = "完成薰衣草花房任务掉落蓝图",
                    pf = "薰衣草花穗，薰衣草洗衣液，留影枫叶，幻源木",
                    tx =
                    "薰衣草花房会生成一只驯养的薰衣草猫猫，右键小猫可领养，右键房屋可寄养，花房存在薰衣草猫猫时，薰衣草猫猫会收集附近的掉落物，在万物之树附近建造会长出薰衣草树藤，在树藤里放入薰衣草洗衣液*1，薰衣草花穗*1，每天天亮增加物品数"
                }
            },
            {
                prefab = "tbat_building_reef_lighthouse",
                name = "礁石灯塔",
                type = "房屋",
                ys = {
                    sc = "海上的随机三个盐矿海域生成",
                    sd = "每个鳐鱼房子绑定一只帽子鳐鱼",
                    tx = "不可被破坏"
                },
                zj = {
                    sc = "击杀帽子鳐鱼概率掉落蓝图",
                    pf = "水晶气泡，识之昙花，留影枫叶，记忆水晶",
                    tx =
                    "每个鳐鱼房子会生成一只驯养的帽子鳐鱼，礁石灯塔可以建造在海洋或者陆地上，小屋自带20格ui，无限堆叠且自带返鲜；在万物之树附近海域建造会长出礁石树藤，在树藤里放入水晶气泡*1，每天天亮增加物品数"
                }
            },
            {
                prefab = "tbat_building_forest_mushroom_cottage",
                name = "蘑菇小窝",
                type = "房屋",
                ys = {
                    sc = "月台森林附近的蘑语林间地形生成",
                    sd = "每个森林蘑菇小窝绑定一只蘑埚蜗牛",
                    tx = "小窝附近会有一座建造好的森林小蜗埚；玩家给予蘑菇小窝一个森伞小菇，勇气之誓，知识之纱，愿望之笺，幸运之语后获取不同知识点和物品"
                },
                zj = {
                    sc = "玩家将药剂【愿望之笺】给予野生蘑菇小窝后掉落蓝图",
                    pf = "荧光苔藓，发光蘑菇，留影枫叶，幻源木",
                    tx = "每个森林蘑菇小窝绑定一只蘑埚蜗牛，在万物之树附近建造会长出蘑菇树藤，在树藤里放入荧光苔藓*1，发光蘑菇*1，每天天亮增加物品数"
                }
            }
        },
        B = {
            {
                prefab = "tbat_container_cherry_blossom_rabbit_mini",
                name = "樱花兔兔",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "幻源木，樱花瓣",
                    gn = "一阶段随身携带的返鲜的箱子，右键放置地面，月圆之夜给予一个蒲公英猫花朵可升级为二阶段，可全图收集箱子内已拥有的物品，UI中间可拖拽，右上角的小樱花拥有整理功能，樱花兔兔可快速烹饪料理。"
                }
            },
            {
                prefab = "tbat_container_pear_cat",
                name = "梨花猫猫",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "幻源木，梨花瓣",
                    gn = "一阶段在月黑之夜给予一个蒲公英猫花朵可升级为二阶段，可全图收集箱子内已拥有的物品，UI中间可拖拽，右上角的小猫头拥有整理功能。注：可在配置中开启关闭该功能或者更改范围以及收集频率。"
                }
            },
            {
                prefab = "tbat_building_piano_rabbit",
                name = "星琴小兔",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "祈愿牌，星之碎屑",
                    gn = "自带二本，通过给予不同物品可解锁不同的科技，左键点击，弹出指定科技物品栏，右键点击，切换指定科技"
                }
            },
            {
                prefab = "tbat_container_emerald_feathered_bird_collection_chest",
                name = "翠羽鸟收集箱",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "翠羽鸟的羽毛，祈愿牌",
                    gn = "可回收地图的掉落物，可删除箱子内任何物品，删除一个物品累计一点经验，满一万点经验可升级二阶段，拥有一键拆解的能力。注：可在配置里开启或关闭"
                }
            },
            {
                prefab = "tbat_building_sunflower_hamster",
                name = "向日葵仓鼠灯",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "葵瓜子，昙花蝴蝶",
                    gn = "拥有两个阶段，给予一个松鼠牙可升级，发光范围增加"
                }
            },
            {
                prefab = "atbook_chefwolf",
                name = "小狼大厨",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "狼心，白梅花，祈愿牌",
                    gn = "小狼大厨制作完的料理会直接进入返鲜格子，中间两个格子，左边放置料理，右边放置调味品，可对料理一键调味"
                }
            },
            {
                prefab = "atbook_ordermachine",
                name = "自助点菜机",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "狼心，狼毛，幻源木",
                    gn = "需要搭配小狼大厨使用，自动检测附近五格地皮储物箱子内的食材，所需食材齐全，可制作的料理会亮起。点击可制作料理，右侧界面选择料理配方，确定选择后点击“点菜”，附近的小狼大厨会开始制作。"
                }
            },
            {
                prefab = "tbat_container_squirrel_stash_box",
                name = "鼠鼠囤货箱",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "幻源木",
                    gn = "在枫叶树屋附近建造，枫叶松鼠会自动采集附近的可采集的植物，农作物放进鼠鼠囤货箱"
                }
            },
            {
                prefab = "tbat_container_little_crane_bird",
                name = "小小鹤草箱",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "四叶草鹤羽毛，幻源木",
                    gn = "储物型箱子建筑，仅可以放入各类蓝图，雕像图纸，冒险家笔记等，可擦除箱子内所有物品变成成对应数量的莎草纸，点击感应按键可将所有蓝图收集到草箱内"
                }
            },
            {
                prefab = "tbat_container_lavender_kitty",
                name = "薰衣草小猫",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "薰衣草花穗，薰衣草洗衣液，记忆水晶，幻源木",
                    gn = "放在农田中心，放置后可以防止农田生长出杂草，左键点击薰衣草小猫，可范围种植和收获农作物，切换自动模式，会自动收获及种植范围内的农田，拿起薰衣草洗衣液对着薰衣草小猫建筑右键可以施肥"
                }
            },
            {
                prefab = "tbat_container_mushroom_snail_cauldron",
                name = "蘑菇小蜗埚",
                type = "建筑",
                base = {
                    kj = "靠近万物之树，在幻想建筑栏解锁",
                    pf = "发光蘑菇，荧光苔藓，幻源木",
                    gn = "四格炼制格子和炼制按键以及储物空间，格子内自带返鲜和无限堆叠功能，炼制格子内可以消耗对应数量材料炼制出对应药剂。注意！要去蘑埚蜗牛处学习配方哦~"
                }
            }
        },
        C = {
            {
                prefab = "tbat_building_cherry_blossom_rabbit_swing",
                name = "樱兔秋千",
                type = "装饰建筑",
                base = {
                    kj = "靠近万物之树，在幻想装饰栏解锁",
                    pf = "幻源木，樱花花瓣",
                    gn = "每秒回复1点血量，饱食度不会下降。挂机神器~"
                }
            },
            {
                prefab = "tbat_building_red_spider_lily_rocking_chair",
                name = "彼岸花摇椅",
                type = "装饰建筑",
                base = {
                    kj = "靠近万物之树，在幻想装饰栏解锁",
                    pf = "许愿牌，桂花球",
                    gn = "人物坐上去每秒回复1点血量，3点精神值。"
                }
            }
        }
    },
    DECOR = {
        { name = "彼岸花摇椅", child = { "1" } },
        { name = "翠羽树叶地皮", child = { "1" } },
        { name = "岛屿落樱地皮", child = { "1" } },
        { name = "梅花餐桌", child = { "1" } },
        { name = "梅花萌宠木桩", child = { "1" } },
        { name = "梅花木墙", child = { "1" } },
        { name = "梅花灶台", child = { "1" } },
        { name = "萌宠小石雕", child = { "1" } },
        { name = "萌宠装饰雕像", child = { "1" } },
        { name = "梦境物语集", child = { "1" } },
        { name = "魔法药剂柜", child = { "1" } },
        { name = "软木餐桌", child = { "1" } },
        { name = "软木沙发", child = { "1" } },
        { name = "石雕石阶", child = { "1" } },
        { name = "棠梨煎雪地皮", child = { "1" } },
        { name = "围边海螺贝壳装饰", child = { "1" } },
        { name = "围边星星云朵装饰", child = { "1" } },
        { name = "围边雪花雪人装饰", child = { "1" } },
        { name = "樱兔秋千", child = { "1" } },
    },
    INVENTORY = {
        A = {
            {
                prefab = "tbat_item_snow_plum_wolf_kit",
                name = "梅雪小狼",
                type = "道具",
                base = {
                    kj = "击杀梅雪族长概率掉落蓝图",
                    pf = "狼毛，狼心，白梅花",
                    gn = "放入物品栏，人物不会过热，右键可放置在地上，拥有吸热火坑的能力"
                }
            },
            {
                prefab = "tbat_item_maple_squirrel_kit",
                name = "枫叶鼠鼠",
                type = "道具",
                base = {
                    kj = "击杀枫叶松鼠概率掉落蓝图",
                    pf = "松鼠牙，枫液",
                    gn = "放入物品栏，人物不会过冷，右键可放置在地上，拥有石头火坑的能力"
                }
            },
            {
                prefab = "tbat_item_butterfly_wrapping_paper",
                name = "蝴蝶打包纸",
                type = "道具",
                base = {
                    kj = "靠近万物之树，在幻想道具栏解锁",
                    pf = "蒲公英花伞，留影枫叶",
                    gn = "一次性打包纸，拿起可对物品，建筑，生物等进行打包。可在配置开启安全模式和不安全模式，不安全模式有崩档风险，请冒险家谨慎操作"
                }
            },
            {
                prefab = "tbat_item_holo_maple_leaf",
                name = "留影枫叶",
                type = "道具",
                base = {
                    kj = "砍伐秋枫树掉落或者击杀枫叶松鼠获得",
                    pf = "无",
                    gn = "拿起留影枫叶对准目标可将目标此阶段状态动画进行复制，种植后会成为无功能的留影版植物及建筑，建家，整活必备！"
                }
            },
            {
                prefab = "tbat_item_trans_core",
                name = "传送核心",
                type = "道具",
                base = {
                    kj = "靠近万物之树，在幻想道具栏解锁",
                    pf = "蒲公英花伞，星之碎屑",
                    gn = "右键传送核心将会传送到万物之树附近"
                }
            },
            {
                prefab = "tbat_eq_world_skipper",
                name = "万物穿梭",
                type = "道具",
                base = {
                    kj = "靠近万物之树，在幻想道具栏解锁",
                    pf = "翠羽鸟的羽毛，星之碎屑",
                    gn = "右键可开启或关闭，开启状态下，打开地图可传送已解锁的任意点位【配置可开启或关闭该功能】"
                }
            },
            {
                prefab = "tbat_item_notes_of_adventurer",
                name = "冒险家笔记",
                type = "道具",
                base = {
                    kj = "击杀各类boss可获得",
                    pf = "不可制作",
                    gn = "给予翠羽鸟可获得特殊物品"
                }
            },
            {
                prefab = "tbat_plant_hedgehog_cactus_pot",
                name = "万物盆栽",
                type = "道具",
                base = {
                    kj = "靠近万物之树，在幻想道具栏解锁",
                    pf = "幻源木",
                    gn = "给与小仙种子后开始生长，种植后变成刺猬小仙"
                }
            },
            {
                prefab = "tbat_plant_coconut_cat_kit",
                name = "椰子猫猫",
                type = "道具",
                base = {
                    kj = "清甜椰子放置在冷火处八分钟后变成椰子猫猫",
                    pf = "不可制作",
                    gn = "右键消耗一个椰子猫猫召唤一场椰子雨，可大范围灭火，植物浇水。放置状态下的椰子猫猫会为附近的农田浇水和对话"
                }
            },
            {
                prefab = "tbat_item_crystal_bubble",
                name = "水晶气泡",
                type = "道具",
                base = {
                    kj = "帽子鳐鱼的掉落物",
                    pf = "不可制作",
                    gn = "右键水晶气泡后可以不受潮湿度影响，可在水面上行走，拿起水晶气泡右键可种植，放置状态的水晶气泡可放入物品展示"
                }
            }
        },
        B = {
            {
                prefab = "tbat_eq_shake_cup",
                name = "摇摇杯",
                type = "装备",
                base = {
                    kj = "给予翠羽鸟冒险家笔记1获得",
                    pf = "不可制作",
                    gn = "给予食材，料理增加耐久，上限600，手持每秒恢复一点饱食度，满饱食度则不消耗"
                }
            },
            {
                prefab = "tbat_eq_jumbo_ice_cream_tub",
                name = "吨吨桶",
                type = "装备",
                base = {
                    kj = "给予摇摇杯三个四叶草鹤的羽毛可升级",
                    pf = "不可制作",
                    gn = "给予食材或料理增加耐久，上限1200，手持会减缓人物饥饿（配置里可设置），每秒恢复饱食度。给予松鼠牙可获得移速加成"
                }
            },
            {
                prefab = "tbat_eq_universal_baton",
                name = "万物指挥棒",
                type = "装备",
                base = {
                    kj = "靠近万物之树，在幻想道具栏解锁",
                    pf = "幻源木，樱花瓣",
                    gn = "右键选取目标，目标下方会出现六个功能切换【旋转，镜像，变大，缩小，还原，换肤】，注意：转向功能只适用于地毯和多面贴图目标。"
                }
            },
            {
                prefab = "tbat_eq_furrycat_circlet",
                name = "猫猫花环",
                type = "装备",
                base = {
                    kj = "击杀桂花猫猫概率掉落蓝图",
                    pf = "桂花球",
                    gn = "照明头部装备，装备后快速恢复理智"
                }
            },
            {
                prefab = "tbat_eq_fantasy_tool",
                name = "幻想工具",
                type = "装备",
                base = {
                    kj = "靠近万物之树，在幻想道具栏解锁",
                    pf = "祈愿牌",
                    gn = "可砍，锤，捕，钓，锄，装备时右键可开启或关闭开启锤，铲，强力开采。给予松鼠牙可获得移速加成"
                }
            },
            {
                prefab = "tbat_eq_ray_fish_hat",
                name = "鳐鱼帽子",
                type = "装备",
                base = {
                    kj = "击杀帽子鳐鱼概率掉落蓝图",
                    pf = "水晶气泡，记忆水晶",
                    gn = "头盔型装备，装备后可踏水，可回复精神值，提供照明。装备帽子后可在屏幕左下方UI切换填海造陆功能"
                }
            },
            {
                prefab = "tbat_eq_snail_shell_of_mushroom",
                name = "小蜗护甲",
                type = "装备",
                base = {
                    kj = "玩家将药剂【知识之纱】给予蘑菇小窝后掉落蓝图",
                    pf = "发光蘑菇，荧光苔藓，森伞小菇",
                    gn = "初始60%防御型护甲，穿戴时右键护甲，玩家可以缩进蜗牛壳内，免疫一切伤害，给予松鼠牙，森伞小菇，发光蘑菇，荧光苔藓后解锁不同能力"
                }
            }
        },
    },
    FOOD = {
        A = {
            {
                prefab = "tbat_item_wish_note_potion",
                name = "愿望之笺",
                hasimg = true,
                recipe = {
                    {"tbat_material_starshard_dust", 20},
                    {"tbat_material_wish_token", 20},
                    {"tbat_food_fantasy_apple", 10},
                    {"tbat_material_snow_plum_wolf_heart", 2},
                },
                sd = "小蜗埚炼制药剂，喝下解锁非专属科技，制作一件物品后药效消失"
            },
            {
                prefab = "tbat_item_veil_of_knowledge_potion",
                name = "知识之纱",
                hasimg = true,
                recipe = {
                    {"tbat_material_memory_crystal", 10},
                    {"tbat_food_ephemeral_flower", 6},
                    {"tbat_food_ephemeral_flower_butterfly_wings", 6},
                    {"tbat_item_crystal_bubble", 4},
                },
                sd = "小蜗埚炼制药剂，喝下后一天内拥有制作 书籍，书架，阅读书籍能力"
            },
            {
                prefab = "tbat_item_oath_of_courage_potion",
                name = "勇气之誓",
                hasimg = true,
                recipe = {
                    {"tbat_food_crimson_bramblefruit", 10},
                    {"tbat_food_valorbush", 10},
                    {"tbat_plant_fluorescent_moss_item", 10},
                    {"tbat_food_fantasy_potato", 10},
                },
                sd = "小蜗埚炼制药剂，喝下后一天内拥有攻击翻倍和0.5%吸血能力"
            },
            {
                prefab = "tbat_item_lucky_words_potion",
                name = "幸运之语",
                hasimg = true,
                recipe = {
                    {"tbat_material_four_leaves_clover_feather", 2},
                    {"tbat_material_osmanthus_wine", 10},
                    {"tbat_food_lavender_flower_spike", 10},
                    {"tbat_material_emerald_feather", 1},
                },
                sd = "小蜗埚炼制药剂，喝下后随机抽取一个四叶草鹤的好运buff"
            },
            {
                prefab = "tbat_item_peach_blossom_pact_potion",
                name = "桃花之约",
                hasimg = true,
                recipe = {
                    {"tbat_food_fantasy_peach", 10},
                    {"tbat_food_cherry_blossom_petals", 10},
                    {"tbat_food_pear_blossom_petals", 10},
                    {"tbat_plant_fluorescent_mushroom_item", 10},
                },
                sd = "小蜗埚炼制药剂，玩家使用可缓慢回血，共60秒，给驯养生物使用立刻回复100血"
            },
            {
                prefab = "tbat_item_failed_potion",
                name = "失败的药剂",
                hasimg = true,
                sd = "没有学习知识点做正确配方则会成为失败药剂。喝下后玩家每三秒扣除一点血量，拉出一个粑粑，持续一分钟"
            },
        },
        B = {
            {
                prefab = "tbat_food_cooked_butterfly_dance_rice",
                name = "花间蝶舞糯米饭",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_blossom_roll",
                name = "樱花可颂卷",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_fairy_hug",
                name = "抱抱小仙卷",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_rose_whisper_tea",
                name = "玫瑰花语茶",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_apple_snow_sundae",
                name = "苹果雪山圣代",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_berry_rabbit_jelly",
                name = "莓果兔兔冻",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_garden_table_cake",
                name = "花园物语蛋糕",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_peach_pudding_rabbit",
                name = "蜜桃布丁兔",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_potato_fantasy_pie",
                name = "土豆奇幻派",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_peach_rabbit_mousse",
                name = "桃兔花椰慕斯",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_rainbow_rabbit_milkshake",
                name = "彩虹兔兔奶昔",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_forest_garden_roll",
                name = "花境森林卷",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_flower_bunny_cake",
                name = "花兔彩绮蛋糕",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_star_sea_jelly_cup",
                name = "星海水母冰杯",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_snow_sheep_sushi",
                name = "雪顶绵羊寿司",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_forest_dream_bento",
                name = "森林梦境便当",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_bear_sun_platter",
                name = "小熊阳光拼盘",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_bamboo_cat_bbq_skewers",
                name = "竹香小咪烤串",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_flower_whisper_ramen",
                name = "花香耳语拉面",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_cloud_rabbit_steamed_bun",
                name = "软绵云兔馒头",
                haspage = true,
            },
            {
                prefab = "tbat_food_cooked_pink_butterfly_steamed_bun",
                name = "粉蝶嘟嘟馍饼",
                haspage = true,
            },
        },
    },
    SKIN = {
        -- 建筑
        {
            {
                skincode = "tbat_lamp_starwish",
                name = "星愿心灯柱",
                type = "暖居温馨系列",
                scale = 0.4,
                quality = "PURPLE",
                desc = "每一颗闪烁的灯光，都是心愿的回声，星星替你收藏，直到梦成真"
            },
            {
                skincode = "tbat_lamp_moon_starwish",
                name = "荧星彩云灯",
                type = "暖居温馨系列",
                scale = 0.35,
                quality = "PURPLE",
                desc = "云在睡，星在唱，光在悄悄流淌。若你靠近一点，就能听见梦的心跳"
            },
            {
                skincode = "tbat_lamp_moon_sleeping_kitty",
                name = "月眠喵梦灯",
                type = "暖居温馨系列",
                scale = 0.35,
                quality = "PURPLE",
                desc = "梦在光里流淌，月亮摇着尾巴。若你轻轻许愿，喵咪会把它叼进星空里"
            },
            {
                skincode = "tbat_wood_sofa_magic_broom",
                name = "喵咪魔法扫帚",
                type = "暖居温馨系列",
                quality = "PINK",
                desc = "勿忘我猫猫站在藤蔓缠绕的魔法扫帚上，在梦幻天空中滑过，带着花香与魔力，轻轻唤醒童话里的奇妙魔法"
            },
            {
                skincode = "tbat_wood_sofa_sunbloom",
                name = "向阳绒布沙发",
                type = "暖居温馨系列",
                scale = 0.25,
                quality = "PINK",
                desc = "向日葵点亮了灯光，沙发柔软得像阳光的怀抱------连风都想靠一靠"
            },
            {
                skincode = "tbat_wood_sofa_lemon_cookie",
                name = "香柠甜筒沙发",
                type = "蜜语甜品系列",
                quality = "PINK",
                desc = "跌进清甜的柠檬冰淇淋里，张开双手拥抱你的软绵小确幸"
            },
            {
                skincode = "tbat_sunbloom_side_table",
                name = "向阳茶点桌",
                type = "暖居温馨系列",
                scale = 0.25,
                quality = "PINK",
                desc = "茶香缭绕，花影轻晃。向日葵悄悄收起阳光，藏进每一口温柔的甜"
            },
            -- {
            --     skincode = "tbat_whisper_tome_swirl_vanity",
            --     name = "芙蕾雅の小兔梳妆台",
            --     type = "私人定制",
            --     scale = 0.25,
            --     quality = "RED",
            --     desc = "无需展示"
            -- },
            -- {
            --     skincode = "tbat_mpc_tree_ring_counter",
            --     name = "森语奇境",
            --     type = "浮梦幻想系列",
            --     scale = 0.1,
            --     height = 40,
            --     quality = "PINK",
            --     desc = "走进森语奇境，你会发现，每一片叶子都轻声低语，每一个树桩都藏着蒲公英猫猫的小秘密。蘑菇屋闪烁着微光，花香与微风轻轻环绕，你仿佛踏入了一个温暖而奇幻的童话世界。"
            -- },
            -- {
            --     skincode = "tbat_mpc_ferris_wheel",
            --     name = "云朵乐园烘培屋",
            --     type = "浮梦幻想系列",
            --     scale = 0.08,
            --     quality = "PINK",
            --     desc = "摩天轮上的萌云轻轻摇曳，甜品屋的小梯子和彩色糖果像画笔点缀童话画卷。云朵烘焙屋，是每一个热爱甜蜜与梦幻心灵的乐园"
            -- },
            {
                skincode = "tbat_mpc_gift_display_rack",
                name = "星琴礼品架",
                type = "浮梦幻想系列",
                scale = 0.2,
                quality = "PURPLE",
                desc = "水晶礼品架在星琴小兔的守护下微微闪动，每一件都藏着温暖又神秘的小魔法"
            },
            {
                skincode = "tbat_mpc_accordion",
                name = "乐琴旋转展厅",
                type = "浮梦幻想系列",
                anim = "test",
                scale = 0.2,
                quality = "PURPLE",
                desc = "梦幻的旋律在琴上回荡，藤蔓与花朵环绕，小精灵们悄悄跳动，耳旁奏响温柔的乐章"
            },
            {
                skincode = "tbat_mpc_dreampkin_hut",
                name = "南瓜梦境屋",
                type = "浮梦幻想系列",
                height = 50,
                scale = 0.2,
                quality = "PURPLE",
                desc = "小梯子通向南瓜柜的秘密层，绿叶缠绕，幽灵在其中守护魔法配方，让每次调制都充满惊喜"
            },
            {
                skincode = "tbat_mpc_grid_cabinet",
                name = "花木跳趣格",
                type = "浮梦幻想系列",
                quality = "PURPLE",
                desc = "木质格子像小时候的跳房子，每一步都踩着花香和绿意。萌趣向日葵小伙伴微笑守护，绿植和花卉环绕，让你在跳跃中感受森林的奇趣"
            },
            {
                skincode = "tbat_mpc_puffcap_stand",
                name = "蘑菇萌趣台",
                type = "浮梦幻想系列",
                scale = 0.25,
                quality = "PURPLE",
                desc = "顶上小兔偷偷眨眼，猫耳和兔耳的蘑菇伞下藏着满满的小秘密，每一层都等你去发现萌趣小惊喜"
            },
            {
                skincode = "tbat_pbt_sweetwhim_stand",
                name = "童话甜品台",
                type = "浮梦幻想系列",
                height = 40,
                quality = "PURPLE",
                desc = "彩虹拱起，小兔子轻舞，精致吊坠闪烁，童话的甜蜜魔法在每一角落闪耀。"
            },
            {
                skincode = "tbat_pbh_abysshell_stand",
                name = "深海贝壳甜品台",
                type = "浮梦幻想系列",
                height = 40,
                quality = "PURPLE",
                desc = "浪花轻拍台面，珊瑚和小章鱼环绕，珍珠闪烁，每一件甜品都像海底的小奇迹。"
            },
            {
                skincode = "tbat_hamster_gumball_machine",
                name = "幻羽藤蔓灯",
                type = "暖居温馨系列",
                anim = "idle_2",
                scale = 0.1,
                quality = "PINK",
                desc = "轻触亮起的瞬间，羽翼般的星光在藤蔓间悄然苏醒，为你把夜晚点成一场温柔的星空"
            },
            {
                skincode = "tbat_pc_strawberry_jam",
                name = "草莓比熊",
                type = "蜜语甜品系列",
                anim = "idle_2",
                quality = "BLUE",
                desc = "小小比熊抱住满满的草莓罐子，毛茸茸的身体蹦蹦跳跳，红彤彤的果香随风飘散，每一步都像在把甜蜜撒向整个世界"
            },
            {
                skincode = "tbat_pc_pudding",
                name = "喵喵布丁",
                type = "蜜语甜品系列",
                anim = "idle_1",
                quality = "PINK",
                desc = "喵～我是喵喵布丁，把宝贝轻轻收进香甜的布丁里，每一次开启都是甜蜜温暖的时光"
            },
            {
                skincode = "cb_rabbit_mini_icecream",
                name = "樱花甜筒",
                type = "蜜语甜品系列",
                anim = "idle_1",
                quality = "PINK",
                desc = "樱花兔兔悄悄藏在甜筒里，粉嫩的身体伴着冰淇淋轻轻晃动，甜香融化在花香里，探出的小脑袋仿佛在找寻春天里的小惊喜"
            },
            {
                skincode = "cbr_mini_labubu_pink_strawberry",
                name = "拉布布 : 粉莓",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "甜美的粉红小花狐"
            },
            {
                skincode = "cbr_mini_labubu_white_cherry",
                name = "拉布布 : 棉樱",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "像樱花云朵般的柔软气息"
            },
            {
                skincode = "cbr_mini_labubu_moon_white",
                name = "拉布布 : 月白",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "纯净的月光下轻舞的花狐"
            },
            {
                skincode = "cbr_mini_labubu_purple_wind",
                name = "拉布布 : 紫岚",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "紫色晨雾里盛开的花语"
            },
            {
                skincode = "cbr_mini_labubu_skyblue",
                name = "拉布布 : 碧蓝",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "蓝色湖畔边的花精灵"
            },
            {
                skincode = "cbr_mini_labubu_lemon_yellow",
                name = "拉布布 : 柠光",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "清新活泼，像柠檬般明亮"
            },
            {
                skincode = "cbr_mini_labubu_orange",
                name = "拉布布 : 橘暖",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "带着橙色余晖的温暖守护者"
            },
            {
                skincode = "cbr_mini_labubu_flower_bud",
                name = "拉布布 : 花苞",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "像森林里初绽的小花"
            },
            {
                skincode = "cbr_mini_labubu_colourful_feather",
                name = "拉布布 : 彩羽",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "头顶花环五彩斑斓，像小鸟羽毛般灵动"
            },
            {
                skincode = "cbr_mini_labubu_dream_blue",
                name = "拉布布 : 蔚梦",
                type = "拉布布盲盒系列",
                anim = "base",
                scale = 0.2,
                quality = "BLUE",
                desc = "天空与花朵交织出的梦境之色"
            },
        },
        -- 生态
        {

        },
        -- 装饰
        {
            {
                skincode = "tbat_wall_strawberry_cream_cake",
                name = "草莓奶芙蛋糕",
                type = "蜜语甜品系列",
                anim = "fullA",
                height = 40,
                quality = "PINK",
                desc = "奶油与草莓的约定，让幸福在墙角悄悄融化"
            },
            {
                skincode = "tbat_wall_coral_reef",
                name = "星贝珊瑚礁柱",
                type = "浮梦幻想系列",
                anim = "fullA",
                height = 40,
                quality = "PINK",
                desc = "灰岩在潮音中沉睡，珊瑚与海藻悄悄爬上褶纹，粉蓝气泡沿着岩柱升腾------在深海里，连静止也有了温柔的呼吸"
            },
            {
                skincode = "tbat_whisper_tome_spellwisp_desk",
                name = "幽蓝巫术桌",
                type = "暖居温馨系列",
                scale = 0.16,
                quality = "PINK",
                desc =
                "木质魔法桌上，倒挂金蝠静静守护着巫师的魔药与书卷。枯枝上挂满魔法饰物，桌面散落着魔法瓶和神秘道具。奇趣诡谲的魔法世界中会召唤出无限可能，金蝠的眨眼提醒你：魔法从不孤单"
            },
            {
                skincode = "tbat_whisper_tome_chirpwell",
                name = "童趣水井亭",
                type = "暖居温馨系列",
                scale = 0.2,
                quality = "PINK",
                desc = "木质井架上长满蘑菇，一只土豆鸡躲在了水桶里，井沿边的土豆鸡活泼可爱。花丛环绕，阳光洒落，井水清甜仿佛带着花草的香气和乡间的温暖气息。每一次汲水，都像和小鸡们一起分享田园的宁静与童话般的乐趣。"
            },
            {
                skincode = "tbat_whisper_tome_purr_oven",
                name = "猫咪烘焙炉",
                type = "暖居温馨系列",
                scale = 0.2,
                quality = "PINK",
                desc =
                "萌系厨房里，石砌火炉散发温暖，迷迭香猫猫慵懒趴在炉台，勿忘我猫猫躲在木筐旁探头。炉火下木柴轻微噼啪，空气中弥漫香甜。猫咪们的陪伴，让家的温馨和甜蜜在厨房里溢满。"
            },
            {
                skincode = "tbat_whisper_tome_birdchime_clock",
                name = "鸟语时钟",
                type = "馈赠系列",
                scale = 0.4,
                quality = "GREEN",
                desc = "每一次钟声响起，鸟儿的低语在空气中舞动。时间像羽毛般轻盈，带你穿越晨光与黄昏"
            },
            {
                skincode = "tbat_pb_bush_dreambloom",
                name = "绮梦花丛",
                type = "绿野繁花系列",
                anim = "dreambloom",
                height = 40,
                quality = "PURPLE",
                desc = "花瓣轻摇，如梦似绮，带来一阵软绵春意"
            },
            {
                skincode = "tbat_pb_bush_mistbloom",
                name = "云雾花丛",
                type = "绿野繁花系列",
                anim = "mistbloom",
                height = 40,
                quality = "PURPLE",
                desc = "像晨雾中浮起的极光，云色包裹着花香"
            },
            {
                skincode = "tbat_pb_bush_mosswhisper",
                name = "绿语苔丛",
                type = "绿野繁花系列",
                anim = "mosswhisper",
                height = 50,
                quality = "PURPLE",
                desc = "花朵在苔丛间跳跃摇曳，每一片绿叶都在回应你的脚步，带来满满生机与希望"
            },
            {
                skincode = "tbat_pb_bush_bunnysleep_orchid",
                name = "兔眠花丛",
                type = "馈赠系列",
                height = 40,
                anim = "bunnysleep_orchid",
                quality = "GREEN",
                desc = "兔兔钻进蝴蝶兰的花海，香香的梦里全是花瓣飘落的声音"
            },
            {
                skincode = "tbat_pb_bush_warm_rose",
                name = "暖樱玫瑰丛",
                type = "绿野繁花系列",
                anim = "warm_rose",
                scale = 0.25,
                quality = "PURPLE",
                desc = "花色如春日初樱，轻粉中带着治愈的甜。它会在微风里轻轻摇头，仿佛在说：别难过，我在这里。带来柔软、安心与一点点害羞的温暖。"
            },
            {
                skincode = "tbat_pb_bush_spark_rose",
                name = "星火玫瑰丛",
                type = "绿野繁花系列",
                anim = "spark_rose",
                scale = 0.25,
                quality = "PURPLE",
                desc = "鲜红如跳动的心脏，光在花瓣上燃烧。夜里，有星子躲在花心里偷偷发亮：喜欢是会发光的。适合放在人来人往的地方，让勇气也盛开。"
            },
            {
                skincode = "tbat_pb_bush_luminmist_rose",
                name = "云光玫瑰丛",
                type = "绿野繁花系列",
                anim = "luminmist_rose",
                scale = 0.25,
                quality = "PURPLE",
                desc = "清澈的蓝仿佛春天的天空，透着平静与自由。它守护那些不善言语的愿望：请把想说的交给我。靠近它，会闻到一丝像云一样凉凉的甜。"
            },
            {
                skincode = "tbat_pb_bush_frostberry_rose",
                name = "莓霜玫瑰丛",
                type = "绿野繁花系列",
                anim = "frostberry_rose",
                scale = 0.25,
                quality = "PURPLE",
                desc = "粉融着莓果甜香，如梦般柔软。花瓣轻轻碰一下就会害羞：嘿...你也是喜欢我吗？是梦想与少女心交织成的秘密花园。"
            },
            {
                skincode = "tbat_pb_bush_stellar_rose",
                name = "星辰玫瑰丛",
                type = "绿野繁花系列",
                anim = "stellar_rose",
                scale = 0.25,
                quality = "PURPLE",
                desc = "深紫如夜，光点如星。静谧而神秘。它不说话，却在守望：愿你抬头就能看到希望。据说，离他最近的愿望最先被实现"
            },
            {
                skincode = "tbat_pot_verdant_grove",
                name = "翠意绿植",
                type = "绿野繁花系列",
                anim = "verdant_grove",
                quality = "PURPLE",
                desc = "宽大绿叶在金属花盆里舒展，清新的气息让家中充满生机与治愈。"
            },
            {
                skincode = "tbat_pot_bunny_cart",
                name = "花车萌趣",
                type = "绿野繁花系列",
                anim = "bunny_cart",
                quality = "PURPLE",
                desc = "缤纷花束堆满复古小推车，猫咪和小鸡探出头，仿佛花园里的小小奇迹。"
            },
            {
                skincode = "tbat_pot_dreambloom_vase",
                name = "紫梦花瓶",
                type = "绿野繁花系列",
                anim = "dreambloom_vase",
                quality = "PURPLE",
                desc = "浪漫紫花插在蓝色花瓶中，阳光洒落窗台，文艺气息温柔蔓延。"
            },
            {
                skincode = "tbat_pot_foxglean_basket",
                name = "狐趣果篮",
                type = "馈赠系列",
                anim = "foxglean_basket",
                quality = "GREEN",
                desc = "编织篮里藏着狐狸玩偶和红色果实，粉色蝴蝶结点缀，可爱俏皮又治愈。"
            },
            {
                skincode = "tbat_pot_lavendream",
                name = "紫韵小花",
                type = "绿野繁花系列",
                anim = "lavendream",
                quality = "PURPLE",
                desc = "复古花盆里盛开清新小花，岁月的温柔在每一片花瓣间流淌"
            },
            {
                skincode = "tbat_pot_cloudlamb_vase",
                name = "羊咩云花",
                type = "绿野繁花系列",
                anim = "cloudlamb_vase",
                quality = "PURPLE",
                desc = "小羊咩坐在柔软云朵上，花束在它身上轻轻盛开，童话般的梦幻气息满溢每一角落"
            },
            {
                skincode = "tbat_carpet_cream_puff_bread",
                name = "奶黄包拼接地垫",
                type = "馈赠系列",
                anim = "idle1",
                height = 90,
                quality = "BLUE",
                desc = "甜甜香气悄悄蔓延，脚尖一踏，像揉进奶黄包的温柔"
            },
            {
                skincode = "tbat_carpet_taro_bread",
                name = "香芋包拼接地垫",
                type = "馈赠系列",
                anim = "idle2",
                height = 70,
                quality = "BLUE",
                desc = "软糯香气悄悄蔓延，脚尖一踏，像揉进香芋的温柔"
            },
            {
                skincode = "tbat_carpet_taro_bread_with_bell",
                name = "香芋铃铛拼接地垫",
                type = "馈赠系列",
                anim = "idle3",
                height = 90,
                quality = "BLUE",
                desc = "软糯香气悄悄蔓延，脚尖一踏，像揉进香芋的温柔"
            },
            {
                skincode = "tbat_carpet_hello_kitty",
                name = "kitty 小猫垫",
                type = "馈赠系列",
                anim = "kitty",
                scale = 0.25,
                height = 80,
                quality = "BLUE",
                desc = "小猫咪在柔软的地毯上撒着娇，午后的阳光里全是笑意"
            },
            {
                skincode = "carpet_claw_dreamweave_rug",
                name = "捕梦织羽地毯",
                type = "浮梦幻想系列",
                anim = "idle1",
                scale = 0.15,
                height = 90,
                quality = "PURPLE",
                desc = "铺开捕梦的羽翼，让柔软承载你的思绪与幻想"
            },
            {
                skincode = "carpet_claw_petglyph_platform",
                name = "萌宠石刻地台",
                type = "浮梦幻想系列",
                anim = "idle1",
                scale = 0.15,
                height = 90,
                quality = "PURPLE",
                desc = "每一块石板都是萌宠的小小乐园，踩上去，轻轻的脚步声就能唤出它们的欢笑与好奇"
            },
        },
        -- 装备
        {
            {
                skincode = "tbat_baton_rabbit_ice_cream",
                name = "雪顶兔兔冰淇淋",
                type = "蜜语甜品系列",
                quality = "PINK",
                desc = "甜甜的魔法，准备好融化你啦\n警告!前方即将爆发------兔兔的甜蜜暴击 嘭------奶油在跳舞\n不许偷舔冰淇淋哦...我看见啦 撒点糖！再加点爱\n小兔兔 专属冰淇霜魔法，启动"
            },
            {
                skincode = "tbat_baton_bunny_scepter",
                name = "芙蕾雅的小兔权杖",
                type = "馈赠系列",
                scale = 0.4,
                quality = "BLUE",
                desc = "小兔的魔法，准备好被萌化啦------嘭------星光蹦跳中\n轻轻一挥，小兔的魔法就要爆发啦，咚咚响\n不许偷看魔法秘诀哦，我可在这里 撒点爱，再撒点勇气\n小兔专属魔法权杖，启动"
            },
            -- {
            --     skincode = "tbat_baton_jade_sword_immortal",
            --     name = "玉剑仙",
            --     type = "私人定制",
            --     scale = 0.4,
            --     quality = "RED",
            --     desc = "不需要展示"
            -- },
            {
                skincode = "tbat_eq_fantasy_tool_cheese_fork",
                name = "芝心幻蝶餐叉",
                type = "蜜语甜品系列",
                quality = "PINK",
                desc = "芝士的力量，比你想象的更梦幻\n光翼起航，美味魔法登场\n幻蝶展开，芝香蔓延。切开夜色，点亮奇迹\n来点浓郁的胜利滋味，芝士会拉丝，想试试吗？ 悄悄告诉你...蝴蝶在听"
            },
            {
                skincode = "tbat_eq_fantasy_tool_freya_s_wand",
                name = "芙蕾雅的魔法棒",
                type = "馈赠系列",
                scale = 0.4,
                height = 10,
                quality = "BLUE",
                desc = "万能棒轻晃，奇趣的小光点四处飞舞\n每一次挥动，都是一段梦幻冒险开始\n轻轻一挥，奇迹启动，咚咚响\n不许偷偷用哦，我看着呢\n叮------连难题都乖乖听话啦"
            },
            {
                skincode = "tbat_wreath_strawberry_bunny",
                name = "莓语兔兔花冠",
                type = "蜜语甜品系列",
                anim = "item",
                height = 40,
                quality = "PINK",
                desc = "两只软软的兔耳竖在花冠上，就像在说：\"别害怕，有我在！\"草莓的香气悄悄落在耳尖，把你的可爱值和幸运值一起拉满"
            },
            {
                skincode = "tbat_rayfish_hat_sweet_cocoa",
                name = "甜心可可花环",
                type = "蜜语甜品系列",
                anim = "item",
                height = 40,
                quality = "PINK",
                desc = "香浓可可与温柔花瓣缠绕，苦涩都被悄悄融化成柔软的甜。戴在头顶，就像给心脏披上巧克力味的拥抱"
            },
            {
                skincode = "tbat_eq_universal_baton_2",
                name = "爱心指挥官",
                type = "蜜语甜品系列",
                height = 40,
                quality = "BLUE",
                desc = "粉润爱心自带柔光 buff～ 指挥甜蜜因子集结，把温暖打包，送到每个需要治愈的角落～"
            },
            {
                skincode = "tbat_eq_universal_baton_3",
                name = "萌兔指挥杖",
                type = "蜜语甜品系列",
                height = 40,
                quality = "BLUE",
                desc = "毛茸茸兔耳缀着粉白绒球，挥动时指挥温柔魔法，让快乐扎堆、美好常驻，做生活里的甜蜜领航员～"
            },
            {
                skincode = "tbat_eq_fantasy_tool2",
                name = "蝴蝶糖法杖",
                type = "馈赠系列",
                height = 40,
                quality = "GREEN",
                desc = "彩蝶停在果味糖杖上，甜香漫溢～ 挥动时落下彩虹糖屑，把日子变成甜甜的梦幻冒险～"
            },
        },
        -- 道具
        {

        },
        -- 其他
        {

        },
    },
    NOTICE = {
        url = "https://www.alan.plus:9091/mod?type=wws",
        title_left = "更新公告",
        content_left =
        [[万物书第二期已成功上线，更多生物植物建筑装饰来袭，新增药剂炼制和全新料理。更为详细的内容介绍可点击上方小蝴蝶按钮查看。
更新预告：交易系统正在制作中，全新坐骑生物正在赶来，设计屋装修大队已经就位。
下期不见不散
]],
        title_right = "作者的一封信",
        content_right =
        [[欢迎大家订阅万物书模组，本模组是以新生物为拓展方向带来全新科技与建筑装饰的模组。感谢万物书老师的授权，也感谢每一位帮助万物书前行的玩家及制作人员。制作模组不易，希望大家多一些理解与包容，在游玩过程中有任何问题都可以进群咨询（二群群号1061978324）
最后，祝大家玩的开心--童瑶、悉茗茗
]],
    },
}

return CONTENT
