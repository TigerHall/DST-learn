--[[
type:
    honor -- 辉煌阵营
    terror -- 凶险阵营
    hmr -- 丰耘
    tech -- 科技站

    cooking -- 烹饪
    food -- 食物
    tool -- 工具
    weapon -- 武器
    structure -- 建筑
    armor -- 防具
    waterproofer -- 防水
    watersource -- 水源
    icebox -- 冰箱
    heater -- 加热器
    container -- 容器
    gift -- 礼物
    repair -- 修补
    setbonus -- 套装
    skill -- 技能
    buff -- 增益
]]


return {
    honor_machine = {
        name = "honor_machine",
        atlas = "images/inventoryimages/honor_machine.xml",
        tex = "honor_machine.tex",
        details = {
            title = "自然亲和机器",
            subtitle = "【辉煌科技】原型站",
            anim_widget = {
                build = "honor_machine",
                bank = "honor_machine",
                anim = "idle",
                -- pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "honor_machine",
                desc = "种植辉煌阵营农作物获取【自然辉煌】、【植物纤维】。\n【自然亲和机器】的制作材料需要【蜂王冠】与【蜘蛛帽】，可考虑优先击杀【蜂王】与【蜘蛛女王】。\n【自然亲和机器】可解锁全部辉煌阵营的道具，迅速提升实力。\n可在【辉煌科技】制作栏中制作【辉煌阵营】的道具。",
                -- source = "当该物品不可制作时写，指明物品的来源"
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "辉煌阵营",
                        },
                    },
                    desc = "辉煌阵营的技术来源。",
                },
                {
                    title = "原型站",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "tech",
                            value = "科技",
                            desc = "靠近解锁【辉煌科技】",
                        },
                    },
                    desc = "从植物中汲取的技术。",
                },
            },
            desc_introduce = "自然亲和机器可以解锁辉煌科技，从而制作出辉煌阵营的装备与工具。包括：辉煌法帽、辉煌护甲、辉煌法杖、辉煌多用工具、辉煌修补套件等。",
            desc_story = "那位与远古时期永恒大陆的”太阳“为伴的老者将伴随了他一生的物品悉数流传了下来，在岁月的长河中，人们只记住了这些物品的大致制作方法，而这也导致了这些物品天生就是“残次品”。某位由“太阳”墨绿灵气造化的少年除外。",
        },
        filter = {"structure", "honor"},-- 分类标签
    },
    honor_balance_maintainer = {
        name = "honor_balance_maintainer",
        atlas = "images/inventoryimages/honor_balance_maintainer.xml",
        tex = "honor_balance_maintainer.tex",
        details = {
            title = "自然平衡维持器",
            subtitle = "镇压【凶险事件】",
            anim_widget = {
                build = "honor_balance_maintainer_ground",
                bank = "honor_balance_maintainer_ground",
                anim = "scrapbook",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "honor_balance_maintainer_ground",
                desc = "除了这些建造材料外，还需要在三根基座上分别插入一颗彩虹宝石，自然平衡维持器才能生效！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "辉煌阵营",
                        },
                    },
                    desc = "相比于疯狂的凶险阵营，辉煌阵营更加稳重。通过它可以镇压凶险阵营为这个世界带来的危机。但有时这种危机未尝不是一件好事。",
                },
                {
                    title = "可交互建筑",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "structure",
                            value = "建筑",
                            desc = "可向基座上布置或摘取彩虹宝石以开启或关闭自然平衡维持器",
                            --desc_colour = {r, g, b, a},
                        },
                    },
                    desc = "我就说在地下档案馆读到的知识有用！",
                },
            },
            desc_introduce = "当自然平衡维持器的三个支柱各被插入一颗【彩虹宝石】时，可镇压【凶险事件】,防止生物被激怒从而攻击您。",
            desc_story = "当玩家采摘凶险阵营农作物时，会激怒部分生物，其中不乏一些史诗级生物。这些生物会向您发起进攻！根据史书记载，在很久之前，在某次凶险事件中，有人从被激怒的生物中发现了浑身金黄的苍蝇，还有比他体型大5倍的熊！",
        },
        filter = {"structure", "honor"},
    },
    honor_tower = {
        name = "honor_tower",
        atlas = "images/inventoryimages/honor_tower.xml",
        tex = "honor_tower.tex",
        details = {
            title = "自然亲和塔",
            subtitle = "农耕伙伴",
            anim_widget = {
                build = "honor_tower",
                bank = "honor_tower",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "honor_tower",
                desc = "装满水的木桶、会唱歌的金丝雀、形形色色的宝石……这些奇妙的物品，都被集成到了这座看似不大的塔里。",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "辉煌阵营",
                        },
                    },
                    desc = "跟植物们打交道是辉煌阵营的先辈们最擅长的一件事，就连动物界的金丝雀也乐意为他们帮忙。",
                },
                {
                    title = "可交互建筑",
                    infos = {
                        {
                            type = "structure",
                            value = "建筑",
                            desc = "可通过【自然亲和子塔】对【自然亲和塔】进行遥控。\n该建筑的生效半径为20",
                        },
                    },
                    desc = "自然亲和塔可不是无尽能源。她的能量来自于自然亲和子塔对其发射的自然能量。",
                },
                {
                    title = "容器",
                    infos = {
                        {
                            type = "container",
                            value = "6x12",
                            desc = "有左右各6x6的容器，其中左侧仅可容纳农产品，右侧只能容纳种子。",
                        },
                        {
                            type = "icebox",
                            value = "0%~-10%",
                            desc = "当塔内盛放的物品种类增加时，自然亲和塔的保鲜能力会随之上升。具体如下：【种类大于等于3】时，具有0.75的保鲜倍率；【种类大于等于8】时，具有0.5的保鲜倍率；【种类大于等于10】时，物品停止腐烂；【种类大于等于15】时，具有0.5的反鲜倍率；【种类大于等于20】时，具有1的反鲜倍率；【种类大于等于32】时，具有2的反鲜倍率；【种类大于等于50】时，具有10的反鲜倍率。",
                        },
                    },
                    desc = "自然亲和塔可不是无尽能源。她的能量来自于自然亲和子塔对其发射的自然能量。",
                },
                {
                    title = "工具",
                    infos = {
                        {
                            type = "tool",
                            value = "捶打",
                            desc = "将半径20范围内的所有巨大化作物敲碎！",
                        },
                        {
                            type = "tool",
                            value = "照料",
                            desc = "为半径20范围内的所有具有【浇水】【施肥】【对话】需求的植物提供服务！",
                        },
                        {
                            type = "tool",
                            value = "收获",
                            desc = "收获半径20范围内的所有植物！",
                        },
                        {
                            type = "tool",
                            value = "收纳",
                            desc = "将半径20范围内的所有可以放入自然亲和塔的物品收纳其中！",
                        },
                    },
                    desc = "通过自然亲和子塔的遥控，自然亲和塔才可完成上面的工作！！",
                },
            },
            desc_introduce = "【自然亲和塔】需要通过【自然亲和子塔】的遥控来工作。\n【自然亲和塔】的工作范围为20（单位：围墙占地）。\n【自然亲和塔】具有巨大的存储空间，但仅能存放他可收获的种子与蔬菜。",
            desc_story = "为纪念那位仅靠双手就创造了永恒大陆所有植物的老者，永恒大陆的居勇者们制造了这台机器，虽然他远不如那位老者勤劳的双手。",
        },
        filter = {"structure", "honor"},
    },
    honor_stower = {
        name = "honor_stower",
        atlas = "images/inventoryimages/honor_stower.xml",
        tex = "honor_stower.tex",
        details = {
            title = "自然亲和子塔",
            subtitle = "农耕伙伴的伙伴",
            anim_widget = {
                build = "honor_stower",
                bank = "honor_stower",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "honor_stower",
                desc = "谁能知道自然辉煌里还储存着能让自然亲和塔工作的能量！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "在辉煌阵营里面，有一对好搭子。",
                        },
                    },
                    desc = "跟植物们打交道是辉煌阵营的先辈们最擅长的一件事，就连动物界的金丝雀也乐意为他们帮忙。",
                },
                {
                    title = "工具",
                    infos = {
                        {
                            type = "tool",
                            value = "捶打",
                            desc = "将半径20范围内的所有巨大化作物敲碎！",
                        },
                        {
                            type = "tool",
                            value = "照料",
                            desc = "为半径20范围内的所有具有【浇水】【施肥】【对话】需求的植物提供服务！",
                        },
                        {
                            type = "tool",
                            value = "收获",
                            desc = "收获半径20范围内的所有植物！",
                        },
                        {
                            type = "tool",
                            atlas = "images/crafting_menu_icons.xml",
                            tex = "filter_containers.tex",
                            value = "收纳",
                            desc = "将半径20范围内的所有可以放入自然亲和塔的物品收纳其中！",
                        },
                    },
                    desc = "自然亲和子塔可以通过蕴藏在其中的力量，驱动自然亲和塔完成上面的工作。",
                },
            },
            desc_introduce = "【自然亲和子塔】每次遥控都会根据自然亲和塔的工作量扣除相应耐久度。\n【自然亲和子塔】可同时遥控其控制范围内的所有【自然亲和塔】，并扣除；对应数量的耐久度。",
            desc_story = "【自然亲和塔】并不是从一开始就可以将物质转换为能量的。经过永恒大陆后代勇士们的不断尝试，终于由威尔逊的能量化学教授研制出了这种可以将能量储存在固体中、并通过微波传输能量的小玩意。",
        },
        filter = {"item", "honor"},
    },
    honor_cookpot = {
        name = "honor_cookpot",
        atlas = "images/inventoryimages/honor_cookpot.xml",
        tex = "honor_cookpot.tex",
        details = {
            title = "辉煌炼化容器",
            subtitle = "万能烹饪锅",
            anim_widget = {
                build = "honor_cookpot",
                bank = "honor_cookpot",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "honor_cookpot",
                desc = "莲花竟是食人花！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "一口锅，但不仅仅是一口锅。",
                        },
                    },
                    desc = "我的祖先们在漫长的生活中，在不断总结烹饪技巧。",
                },
                {
                    title = "烹饪",
                    infos = {
                        {
                            type = "cooking",
                            value = "烹饪",
                            desc = "左侧4个格子可以烹饪各种食物。点击【开始】按钮后开始循环烹饪，直至有一格食材消耗完毕或点击【暂停】按钮停止烹饪。产品将放置于左下角的格子",
                        },
                        {
                            type = "cooking",
                            value = "研磨调料",
                            desc = "右侧格子可以研磨调料。在格子中放置食材后，点击【研磨】后立即生成对应调料。产品将放置于右下角的格子。",
                        },
                        {
                            type = "cooking",
                            value = "调味",
                            desc = "可将【烹饪】产品格与【研磨调料】产品格中的食材进行调味，点击【调味】按钮后立即生成调味品。产品将放置于下侧的格子。",
                        },
                    },
                    desc = "运用辉煌之力，将食材炼化。",
                },
                {
                    title = "保鲜",
                    infos = {
                        {
                            type = "icebox",
                            value = "0%~-100%",
                            desc = "辉煌炼化容器在每次烹饪的过程中都会成长，增加自己的保鲜能力，每次烹饪会为放置于其中的物品降低1%的新鲜度流失速率",
                        },
                    },
                    desc = "运用辉煌之力，为食材保鲜。",
                },
            },
            desc_introduce = "【辉煌炼化容器利用莲花的特殊消化系统，将放置于其中的各种食材烹饪成更加精致的料理。并且会因其独特的植物结构，让放置于其中的食材免遭氧化于细菌等的侵蚀。",
            desc_story = "这朵偷吃我们辛辛苦苦采摘来的食物的食人花，怎么到处都是！真的烦！——在一些先辈抱怨食人花的同时，另一群先辈则开始了对食人花的调教。他们发现食人花并不是真正的把它吃进去的食物立即消化掉，而是会留在身体里，对食物先进行一些特殊处理，将食材的营养价值提高，而后才会慢慢吸收其中的养分。先辈们利用这一原理，培育出只有处理食材功能的新一代食人花，并取名为“莲花”，并不断改进，最终将其制作成了烹饪锅的模样。",
        },
        filter = {"item", "honor"},
    },
    honor_hat = {
        name = "honor_hat",
        atlas = "images/inventoryimages/honor_hat.xml",
        tex = "honor_hat.tex",
        details = {
            title = "辉煌法帽",
            subtitle = "保护你的头部",
            anim_widget = {
                build = "honor_hat",
                bank = "honor_hat",
                anim = "idle",
                pos = Vector3(0, -30, 0),
            },
            recipe_widget = {
                recipe = "honor_hat",
                desc = "把植物纤维用自然辉煌弯折成穹顶的形状！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "灵感来自先辈的墨绿色帽子。",
                        },
                    },
                    desc = "人类文明与大自然工程的碰撞。",
                },
                {
                    title = "月亮亲和",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "亲和",
                            desc = "亮茄不会攻击穿戴辉煌法帽的玩家，即使玩家主动攻击它！",
                        },
                    },
                    desc = "对于同样来自域外的月亮阵营，辉煌阵营的先辈们在月亮到来之时为他们提供了很多帮助，二者建立起了稳固的友谊。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "armor",
                            value = "60%",
                            desc = "辉煌法帽的主要作用不是防护，它会依靠它强大的辉煌力场，为他的主人提供更舒适的生活质量。",
                        },
                        {
                            type = "armor",
                            value = "3%",
                            desc = "抵御3%来自月亮阵营的伤害！",
                        },
                        {
                            type = "armor",
                            value = "3%",
                            desc = "抵御7%来自暗影阵营的伤害！",
                        },
                        {
                            type = "waterproofer",
                            value = "100%",
                            desc = "雨滴会顺着那被精心设计的穹顶曲线全部滑落至永恒大陆的地面。",
                        },
                        {
                            type = "setbonus",
                            value = "辉煌套装",
                            desc = "与辉煌阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n辉煌法帽每秒恢复0.5（单位：生命值）耐久度\n辉煌法帽的穿戴者每秒恢复，0.25理智值",
                        },
                    },
                    desc = "辉煌法帽是自然与手工技艺结合的一次伟大尝试，它利用近乎完美的曲线设计，将神秘能量赋予了这顶神奇的帽子。",
                },
            },
            desc_introduce = "【辉煌法帽】可不是用来抵挡伤害的哦~当你整天为影怪和潮湿的雨季而发愁时，可以试试这顶神奇的帽子。",
            desc_story = "那两团神秘的气息降临到永恒大陆上之后的一段时间里，永恒大陆上的所有生物都在发生着不易被人察觉的细微变化。这其中就包含着，一些大叶子植物的叶面上再也不会像以往那样积水了。是一位先辈在一次夺走了无数人生命的暴雨中无意发现，这些“变异”的大叶片竟然可以将水引流到人们想要的位置！。",
        },
        filter = {"item", "honor", "equipment"},
    },
    honor_armor = {
        name = "honor_armor",
        atlas = "images/inventoryimages/honor_armor.xml",
        tex = "honor_armor.tex",
        details = {
            title = "辉煌护甲",
            subtitle = "保护你的身体",
            anim_widget = {
                build = "honor_armor",
                bank = "honor_armor",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "honor_armor",
                desc = "用精密的编织手法，加上坚固的自然辉煌做粘合剂，制作出一件厚实的护甲。",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "灵感来自先辈的墨绿色斗篷。",
                        },
                    },
                    desc = "在辉煌护甲被制作出来之前，谁都想不到自然辉煌竟能赋予大自然的纤维如此强大的力量。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "armor",
                            value = "85%~98%",
                            desc = "辉煌护甲平时的防护能力为85%，当开启辉煌护甲的技能时，护甲的防护能力提升到98%。",
                        },
                        {
                            type = "armor",
                            value = "10",
                            desc = "抵御10点位面伤害！",
                        },
                        {
                            type = "armor",
                            value = "霸体",
                            desc = "辉煌护甲能利用其超高的密度，保护穿戴者免受大部分攻击的控制！",
                        },
                        {
                            type = "armor",
                            value = "-20%",
                            desc = "辉煌护甲会对其穿戴者造成20%的减速效果，但这也不是不可避免的。",
                        },
                        {
                            type = "setbonus",
                            value = "100%",
                            desc = "与辉煌阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n当穿戴者受到致命伤害时，辉煌护甲会竭尽所能保护穿戴者，将穿戴者的生命值提升至100%，但辉煌护甲自身会直接损坏。\n解除减速的负面效果，穿戴者可以更方便地行走！",
                        },
                    },
                    desc = "经过自然辉煌的整合，用植物纤维编织出的辉煌护甲拥有了超高的密度，这能保护穿戴者，并使穿戴者免受大部分控制。",
                },
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "生命恢复",
                            desc = "穿戴者每秒恢复0.2生命值。当穿戴者生命值达到100%时，穿戴者的饱食度衰减速率会降低80%。",
                        },
                    },
                    desc = "当人们处于健康状态时，即使吃的差点也没有关系。",
                },
                {
                    title = "技能",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "skill",
                            value = "超高防御",
                            desc = "长按【Alt】键开启技能，释放【Alt】键关闭技能。可在设置界面更改按键。\n当开启辉煌护甲的技能时，护甲的防护能力提升到98%。但同时会每秒消耗2点饱食度。同时，在开启技能时受到伤害，护甲会算坏双倍耐久度。",
                        },
                    },
                    desc = "开启技能后会获得强大的防御能力，但要注意自己的饱食度和护甲的耐久度哦！",
                },
            },
            desc_introduce = "【辉煌护甲】的霸体效果是不可多得的，它可以让你免受大部分来自伤害的僵直，但要注意它也会拖慢你行进的步伐",
            desc_story = "在发现自然辉煌能够为【辉煌法帽】的完美穹顶曲线进行附魔后，天才的先辈们想到了用自然辉煌对这件用植物纤维编织而成的护甲进行附魔！",
        },
        filter = {"item", "honor", "equipment"},
    },
    honor_staff = {
        name = "honor_staff",
        atlas = "images/inventoryimages/honor_staff.xml",
        tex = "honor_staff.tex",
        details = {
            title = "辉煌法杖",
            subtitle = "多元化的攻击",
            anim_widget = {
                build = "honor_staff",
                bank = "honor_staff",
                anim = "idle",
                pos = Vector3(0, -40, 0),
            },
            recipe_widget = {
                recipe = "honor_staff",
                desc = "用自然辉煌汇集农作物的元气。",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "灵感来自先辈的八棱法杖，可惜再也没有人能还原出这出色的法杖了。",
                        },
                    },
                    desc = "用植物纤维做骨架，可以最大程度的激发镶嵌在其上的自然辉煌的力量。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "weapon",
                            value = "10",
                            desc = "辉煌法杖的攻击距离为10，属于远程武器，注意拉扯哦！",
                        },
                        {
                            type = "weapon",
                            value = "15",
                            desc = "辉煌法杖的基础伤害为15点。",
                        },
                        {
                            type = "weapon",
                            value = "5",
                            desc = "辉煌法杖具有5点位面伤害",
                        },
                        {
                            type = "finiteuses",
                            value = "400",
                            desc = "辉煌法杖可进行400次攻击，次数消耗完毕后会损坏，不再可穿戴。可使用辉煌修补套件修补！",
                        },
                        {
                            type = "setbonus",
                            value = "+100%",
                            desc = "与辉煌阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n辉煌法杖的伤害会提升至2倍。",
                        },
                    },
                    desc = "掌控辉煌的能力。",
                },
                {
                    title = "升级",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "椰子精华",
                            desc = "给予辉煌法杖一个椰子精华后，辉煌法杖的每次攻击将会有概率发射椰子法球，法球命中目标后，会在目标附近空降两枚椰子，每枚椰子对目标造成10点伤害。",
                        },
                        {
                            type = "honor",
                            value = "小麦精华",
                            desc = "给予辉煌法杖一个小麦精华后，辉煌法杖的每次攻击将会有概率发射小麦法球，法球的伤害降低为原先的0.4倍，法球命中目标后，增加目标4点冰冻值。",
                        },
                        {
                            type = "honor",
                            value = "水稻精华",
                            desc = "给予辉煌法杖一个水稻精华后，辉煌法杖的每次攻击将会有概率发射水稻法球，法球的伤害提升为原先的2倍。",
                        },
                        {
                            type = "honor",
                            value = "茶丛精华",
                            desc = "给予辉煌法杖一个水茶丛华后，辉煌法杖的每次攻击将会有概率发射茶丛法球，法球的伤害降低为原先的0.1倍，法球命中目标后，增加目标3点定身值。定身值满后，目标将被定身，无法行动。",
                        },
                    },
                    desc = "辉煌法杖由于与辉煌阵营的几种农作物有极高的亲和度而可以接受它们的献礼。",
                },
            },
            desc_introduce = "【辉煌法杖】的升级后会具有更为强大的威力，努力获取升级材料吧！",
            desc_story = "在那位老者离去后，人们不止一次地想要用现有地材料和技术还原出老者那闪着八色光芒的墨绿色法杖，可惜都以失败告终。现在，这把名为辉煌的法杖是迄今为止人们效仿的最为接近的一把，可惜他仍然无法一次性激发出全部的八色光芒。",
        },
        filter = {"item", "honor", "equipment"},
    },
    honor_multitool = {
        name = "honor_multitool",
        atlas = "images/inventoryimages/honor_multitool.xml",
        tex = "honor_multitool.tex",
        details = {
            title = "辉煌多用工具",
            subtitle = "多元一体的实用工具",
            anim_widget = {
                build = "honor_multitool",
                bank = "honor_multitool",
                anim = "idle",
                pos = Vector3(0, -40, 0),
            },
            recipe_widget = {
                recipe = "honor_multitool",
                desc = "灵活地运用材料制作一把精巧的工具。",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "先辈们在日复一日的劳作中探索出了高效的秘密。",
                        },
                    },
                    desc = "离开了自然辉煌的能量，这些纤维不会有这么强的力量。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "tool",
                            value = "800",
                            desc = "可砍伐800次，效率为120%。",
                        },
                        {
                            type = "tool",
                            value = "400",
                            desc = "可开采400次，效率为120%",
                        },
                        {
                            type = "tool",
                            value = "267",
                            desc = "可挖掘267次，效率为120%",
                        },
                        {
                            type = "tool",
                            value = "800",
                            desc = "可捶打800次，效率为120%",
                        },
                        {
                            type = "tool",
                            value = "800",
                            desc = "可耕地800次，当辉煌多用工具处于不同模式时，每耕地一个坑所消耗的次数不同。一次性耕地越多，消耗的次数越多！",
                        },
                        {
                            type = "weapon",
                            value = "21",
                            desc = "辉煌多用工具的攻击伤害为21点，每次攻击消耗一点耐久度。",
                        },
                        {
                            type = "setbonus",
                            value = "额外奖励",
                            desc = "与辉煌阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n使用者在对目标进行工作时，每次工作后目标有概率掉落该目标的随机一个掉落物。具体数值如下：\n【砍伐】2%概率掉落。\n【开采】5%概率掉落。\n【挖掘】30%概率掉落。\n【捶打】8%概率掉落。",
                        },
                    },
                    desc = "经过反复的融合实验，先辈们最终制作出了将砍伐、开采、挖掘、捶打、耕地功能能融为五位一体的工具，甚至，他还能当做临时武器使用！",
                },
                {
                    title = "技能",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "skill",
                            value = "耕地模式",
                            desc = "按下【R】键可切换【辉煌多用工具】的耕地模式，可在模组设置界面调整按键。\n耕地模式共4种，每种模式的效果与耕地消耗次数如下：\n【1坑】仅在指定位置耕地1坑，消耗1次。\n【9坑】在指定位置所在的田地刨出3x3的坑，消耗14次。\n【10坑】在指定位置所在的田地均匀刨出10坑，消耗18次。\n【16坑】在指定位置所在的田地刨出4x4的坑，消耗28次。",
                        },
                    },
                    desc = "一田十格是耕地利用效率最高的坑洞排布模式，当一个耕地内超过10个坑洞，农作物会由于拥挤而有压力。简易根据种植的农作物配比灵活选用【9坑】或【10坑】模式！",
                },
            },
            desc_introduce = "【辉煌多用工具】是一把实用的多功能工具，它兼具了砍伐、开采、捶打、耕地功能，可以满足探索者们日常的大部分工作需求。",
            desc_story = "伟大的辉煌先辈们为我们留下了很多遗产，但他们的记性并不怎么好，时常会因为外出农耕时忘记带锄头或者铁锹什么的而折返回家，这真的很让他们恼火！当然，他们已经解决了这一问题。只要拿着他们创造的多用工具，就可以完成任何的耕地工作！",
        },
        filter = {"item", "honor", "equipment"},
    },
    honor_kit = {
        name = "honor_kit",
        atlas = "images/inventoryimages/honor_kit.xml",
        tex = "honor_kit.tex",
        details = {
            title = "辉煌修补套件",
            subtitle = "缝缝补补又是一年",
            anim_widget = {
                build = "honor_kit",
                bank = "honor_kit",
                anim = "idle",
                pos = Vector3(0, -5, 0),
            },
            recipe_widget = {
                recipe = "honor_kit",
                desc = "消耗更少的材料，进行更多的工作！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "勤俭节约的先辈们可不会用完就扔。",
                        },
                    },
                    desc = "兼具植物纤维的坚韧与自然辉煌的高效。",
                },
                {
                    title = "修补",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "repair",
                            value = "修补",
                            desc = "辉煌修补套件在修复工具耐久度的同时，还会永久性提升这把工具的上限！修补后，会随机提升工具的耐久上限、工作效率、护甲保护度，具体数值如下：\n【护甲保护度】10%概率触发，提升1%护甲保护度，最高提升至99%\n【耐久上限】50%概率触发，根据目标的耐久类型不同，提升5%~15%的耐久上限（燃料型提升15%，最高提升至3000%，如火把；护甲型提升5%，最高提升至3000%，如大理石甲；使用次数型提升10%，最高提升至2000%，如锤子；新鲜度型提升10%，最高提升至2000%，如火腿棒）\n【工作效率】40%概率触发，提升10%工作效率，最高提升至初始值的1000%",
                        },
                    },
                    desc = "用植物纤维对工具进行修补，再用自然辉煌对其进行加强！",
                },
            },
            desc_introduce = "【辉煌修补套件】可以为我们节省很多成本，让我们可以进行更多工作！",
            desc_story = "在资源并不富足的时期，植物纤维只能通过采收生长在丛林中的大叶植物加工得到，而自然辉煌更是稀有，先辈们只能祈祷自己辛勤耕作的庄稼里面能有几棵可以回馈他们。",
        },
        filter = {"item", "honor"},
    },
    honor_backpack = {
        name = "honor_backpack",
        atlas = "images/inventoryimages/honor_backpack.xml",
        tex = "honor_backpack.tex",
        details = {
            title = "辉煌背包",
            subtitle = "多功能空间",
            anim_widget = {
                build = "honor_backpack",
                bank = "honor_backpack",
                anim = "idle",
                pos = Vector3(0, -15, 0),
            },
            recipe_widget = {
                recipe = "honor_backpack",
                desc = "用紧密排列的自然辉煌压缩空间！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "自然辉煌在空间层面也有不可估量的能力。",
                        },
                    },
                    desc = "植物纤维做布料，自然辉煌做空间。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "walkspeed",
                            value = "0.5~1.5",
                            desc = "【辉煌背包】参与辉煌套装的效果，移速与背包内的物品所占格子数量有关。\n背包内物品数量越多，移速降低越多，当背包内物品大于等于18个时，移速降低至最低值0.5。若触发辉煌套装效果，则以上效果反转，当背包内物品大于等于18个时，移速提升至最高值1.5。",
                        },
                        {
                            type = "waterproofer",
                            value = "20%",
                            desc = "你也曾体验过将背包举在头顶避雨的快乐嘛？",
                        },
                        {
                            type = "setbonus",
                            value = "反转移速",
                            desc = "与辉煌阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n反转辉煌背包随其容纳物品数量增多时对移速的降低效果，移速最高提升至1.5。",
                        },
                    },
                    desc = "用植物纤维对工具进行修补，再用自然辉煌对其进行加强！",
                },
                {
                    title = "容器",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "icebox",
                            value = "0.2",
                            desc = "【辉煌背包】的倒数第四行具有冰箱特性，放置于其中的物品的腐烂速度会放慢至20%，同时若物品具有温度，该物品的温度会以每秒4℃下降至最低5℃。",
                        },
                        {
                            type = "heater",
                            value = "2",
                            desc = "【辉煌背包】的倒数第三行具有火炉特性，若放置于其中的物品具有温度，该物品的温度会以每秒2℃升高至最高55℃。若放置于其中的物品可被烹饪，则会每秒烹饪一个物品为随机的灰、烹饪物、料理、沃利专属料理、调味料理。具体数值如下：\n【灰】有9.5%的概率烹饪出灰。\n【烹饪物】有70%的概率烹饪出一个该物品的烹饪物，有13%的概率烹饪出双份该物品的烹饪物。\n【料理】有2%的概率烹饪出普通料理。\n【沃利专属料理】有2.5%的概率烹饪出沃利专属料理。\n【调味料理】有3%的概率烹饪出调味料理。",
                        },
                        {
                            type = "gift",
                            value = "奖励",
                            desc = "【辉煌背包】的倒数第二行具有奖励盒特性，若倒数第二档的格子处于空闲状态超过6个小时间段（默认一个小时间段seg time为30s），则会随机刷新一个礼物包裹，每个礼物包裹内容至多4个礼物。礼物的具体内容如下：\n【高级材料包（5.88%）】自然辉煌（22.99%）；植物纤维（45.97%）；自然凶险（1.15%）；恐怖粘液（5.75%）；纯粹辉煌（5.75%）；亮茄外壳（11.49%）；纯粹恐惧（3.45%）；暗影碎布（3.45%）。\n【宝石包（5.88%）】红宝石（28.57%）；蓝宝石（38.10%）；绿宝石（4.76%）；黄宝石（7.62%）；紫宝石（9.52%）；橙宝石（5.71%）；彩虹玉石（0.95%）。\n【石材类材料包（17.64%）】黄金矿石（7.14%）；冰块（21.43%）；大理石（14.29%）；硝石（7.14%）；燧石（14.29%）；岩石（35.71%）。\n【低级材料包（29.41%）】草（31.58%）；绳子（10.53%）；木头（21.05%）；木板（10.53%）；岩石（21.05%）；石块（5.26%）。\n【发光植物包（11.76%）】厥叶（8.33%）；荧光果（41.67%）；发光浆果（16.67%）；较小发光浆果（8.33%）；绿色孢子（8.33%）；红色孢子（8.33%）；蓝色孢子（8.33%）。\n【纸（5.88%）】芦苇（25%）；莎草纸（12.5%）；蜡纸（12.5%）；蜜蜡（25%）；礼物包装纸（25%）。\n【隐士的礼物包（包含壳）（5.88%）】。\n【春节种子包（5.88%）】。\n【稀有春节种子包（5.88%）】。\n【嘉年华活动种子包（5.88%）】。\n【起皱的包裹（5.88%）】。",
                        },
                        {
                            type = "repair",
                            value = "修补",
                            desc = "【辉煌背包】的倒数第一行具有时间特性，可修复放置于其中的物品耐久度。不同类型的耐久度对应的具体数值如下：\n【新鲜度】每秒恢复2秒耐久度。\n【护甲】每秒修复5生命值单位耐久度。\n【使用次数】每秒修复2使用次数。\n【燃料】每秒恢复2.5秒燃料",
                        },
                        {
                            type = "setbonus",
                            value = "反转移速",
                            desc = "与辉煌阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n反转辉煌背包随其容纳物品数量增多时对移速的降低效果，移速最高提升至1.5。",
                        },
                    },
                    desc = "来自于大自然的馈赠！",
                },
            },
            desc_introduce = "丰收时的硕果累累不仅仅是一种开心，也是一种劳累。面对堆积成山的果实，先辈们有点手足无措了。但这并非没有办法，自然辉煌总是能给你意想不到的惊喜。",
            desc_story = "先辈们发现，当把一个东西摆放得离自然辉煌足够近时，这个东西就好像被“折叠”了一样。这可不是那种纸片一样的折叠，而是实实在在地将一个苹果折叠成了它原先体积的1/8！当把这个东西拿得离自然辉煌足够远时，它又恢复了原状。不过这种现象好像只会发生在一些足够小，小到可以装进背包的物品上，所以我们并不用担心自己会被自然辉煌变小。这可是个储物的好方法！",
        },
        filter = {"equipment", "honor"},
    },
    honor_greenjuice = {
        name = "honor_greenjuice",
        atlas = "images/inventoryimages/honor_greenjuice.xml",
        tex = "honor_greenjuice.tex",
        details = {
            title = "植物青汁",
            subtitle = "甘甜汁液",
            anim_widget = {
                build = "honor_greenjuice",
                bank = "honor_greenjuice",
                anim = "idle",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "honor_greenjuice",
                desc = "椰汁茶！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "用辉煌阵营农作物产品制作出的甘甜饮料。",
                        },
                    },
                    desc = "甘甜可口的烹饪原料。",
                },
                {
                    title = "食物",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "food",
                            value = "5",
                            badges = {
                                {
                                    type = "hunger",
                                    value = "5",
                                },
                                {
                                    type = "health",
                                    value = "1",
                                },
                                {
                                    type = "sanity",
                                    value = "30",
                                }
                            },
                            desc = "",
                        },
                    },
                    desc = "",
                },
                {
                    title = "水源",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "watersource",
                            value = "4",
                            desc = "可为浇水壶填充4次使用次数",
                        },
                    },
                    desc = "甘之如饴，小植物们也这么觉得",
                },
            },
            desc_introduce = "椰子与茶叶一同迸发出的味道可以充分的激发你的味蕾。",
            desc_story = "一个恬静的清晨，一位先辈开好了五个椰子作为早餐，等候自己的族人们享用。不知不觉地，种植在一旁的茶树飘落了两篇茶叶到开好的椰壳里。尝到椰汁泡茶叶的先辈发誓一定要在每天的清晨都喝到这样的仙品！",
        },
        filter = {"item", "honor", "food"},
    },
    honor_splendor = {
        name = "honor_splendor",
        atlas = "images/inventoryimages/honor_splendor.xml",
        tex = "honor_splendor.tex",
        details = {
            title = "自然辉煌",
            subtitle = "辉煌材料",
            anim_widget = {
                build = "hmr_naturalmaterials",
                bank = "hmr_naturalmaterials",
                anim = "honor_splendor",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                desc = "消耗更少的材料，进行更多的工作！",
                source = "种植巨大化的辉煌阵营农作物以收获自然辉煌！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "辉煌阵营的主要材料之一，可以制作多种辉煌阵营的装备。",
                        },
                    },
                    desc = "内部蕴含着无法被人类研究的能量，至今没人知道它是如何合成的。",
                },
            },
            desc_introduce = "【自然辉煌】可以制作辉煌法帽、辉煌护甲、辉煌法杖、辉煌多用工具等多种辉煌阵营的装备。\n自然辉煌可通过敲开巨大化的辉煌阵营农作物获取，其中巨大化芦荟掉落自然辉煌的改率为30%，巨大化茶丛、金灯果，巨大化椰子、水稻、小麦、甘蔗、坚果掉落自然辉煌的概率为10%",
            desc_story = "【自然辉煌】的发现其实是一个偶然。在辉煌阵营与凶险阵营刚刚降临到永恒大陆时，永恒大陆上的所有生物都发生了微妙的变化。\n某日，一位先辈在敲开自己辛苦耕耘的超大芦荟时，惊奇地发现，在这颗芦荟的底部，竟然镶嵌着三颗外壳是青铜色、内核是如同白玉一般无比纯净的小玩意。先辈将这三颗宝石一般的东西撬下拿在手里，感受到了无比充沛的精力，更神奇的是，他手中拿着的锄头、身上穿的衣服，都奇迹般的焕然一新！\n这位先辈立即决定一定要种出更多这样的发光小玩意！经过年复一年的育种、筛种，他最终发现只有8种农作物可以孕育出这种小玩意，每个农作物孕育出的概率和质量也不同。",
        },
        filter = {"item", "honor", "material"},
    },
    honor_plantfibre = {
        name = "honor_plantfibre",
        atlas = "images/inventoryimages/honor_plantfibre.xml",
        tex = "honor_plantfibre.tex",
        details = {
            title = "植物纤维",
            subtitle = "辉煌材料",
            anim_widget = {
                build = "hmr_naturalmaterials",
                bank = "hmr_naturalmaterials",
                anim = "honor_plantfibre",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "honor_plantfibre",
                desc = "坚韧的辉煌材料。",
                source = "种植巨大化的椰子、小麦、水稻以收获更多的植物纤维！",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "辉煌阵营的主要材料之一，可以制作多种辉煌阵营的装备。",
                        },
                    },
                    desc = "坚韧无比的纤维材料。",
                },
            },
            desc_introduce = "植物纤维是辉煌阵营农作物产出的一种特殊材料，它不能被普通的工具切割或塑形，只能依靠自然辉煌内蕴含的强大力量进行编织。",
            desc_story = "先辈们想把吃剩的椰子壳和庄稼杆切碎作为肥料，但直到他们将斧子的刃口砍裂，都没能将椰子壳和庄稼杆破坏一二，先辈们变放弃了这两种不可用之物。直到有一天，先辈们惊奇地发现堆放在地面的、原本是半球体的椰子壳，被压放在其上的自然辉煌塑形成了半个橄榄球状的扁椭圆体。自此，先辈们开始运用坚韧无比的椰子壳和庄稼杆，加以自然辉煌的塑形，制作出植物纤维，并应用到各种物品的制作中。",
        },
        filter = {"item", "honor", "material"},
    },
    honor_seeds = {
        name = "honor_seeds",
        atlas = "images/inventoryimages/honor_seeds.xml",
        tex = "honor_seeds.tex",
        details = {
            title = "辉煌种子",
            subtitle = "辉煌结晶",
            anim_widget = {
                build = "hmr_randomseeds",
                bank = "hmr_randomseeds",
                anim = "honor_seed",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "honor_seeds",
                desc = "辉煌作物由此而来。",
            },
            parts = {
                {
                    title = "辉煌阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "可以种植出辉煌阵营农作物的种子。\n芦荟、椰子、金灯果、小麦、水稻、哈密瓜、坚果、茶丛都由此而来。",
                        },
                    },
                    desc = "接受自然辉煌的沐浴，凝聚辉煌能量。",
                },
            },
            desc_introduce = "并不是所有的农作物都可成为辉煌阵营的一员，有些农作物因为可以凝聚出自然辉煌而被辉煌阵营所接洽，有些农作物因为可以产出与自然辉煌有高度契合的植物纤维而被先辈们归类为辉煌阵营农作物。",
            desc_story = "辉煌力量在来到永恒大陆的那一刻起，就在逐渐影响大陆上的一切生物。大陆上的花瓣也不例外。先辈们发现，生长在花丛旁边的庄稼总是能比同一块土地上，与花丛不相邻的庄稼更旺盛。于是先辈们开始将花丛与庄稼联合种植。直到上几个世纪，才有些生物学家发现，是花瓣发生了变异。变异的花瓣能产生辉煌能量场，促进庄稼的光合作用。于是人们在播种时开始用花瓣当做肥料，如此往复。如今，大家称这种花瓣与种子的复合体为“辉煌种子”。",
        },
        filter = {"item", "honor"},
    },

    terror_machine = {
        name = "terror_machine",
        atlas = "images/inventoryimages/terror_machine.xml",
        tex = "terror_machine.tex",
        details = {
            title = "凶险蔓延机器",
            subtitle = "【凶险科技】原型站",
            anim_widget = {
                build = "terror_machine",
                bank = "terror_machine",
                anim = "idle",
                -- pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "terror_machine",
                desc = "种植凶险阵营农作物获取【恐怖粘液】，击杀凶险生物获取【自然凶险】。\n【凶险蔓延机器】可解锁全部凶险阵营的道具，迅速提升实力。\n可在【凶险科技】制作栏中制作【凶险阵营】的道具。",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "凶险阵营",
                        },
                    },
                    desc = "凶险阵营的技术来源。",
                },
                {
                    title = "原型站",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "tech",
                            value = "科技",
                            desc = "靠近解锁【凶险科技】",
                        },
                    },
                    desc = "从植物中汲取的技术。",
                },
            },
            desc_introduce = "凶险蔓延机器可以解锁凶险科技，从而制作出凶险阵营的装备与工具。包括：凶险笼罩、凶险潜胄、凶险荆棘、凶险法杖、凶险修补套件等。",
            desc_story = "凶险科技充分凝结了无数先辈的智慧，以至于全套的凶险科技无法仅凭借自然介质记录完整。幸好永恒大陆的原住居民很早就发明了造纸术。但凶险科技无法被记录在普通的莎草纸上，每当先辈们写出一套完整的凶险子科技，记录这套科技的文字都会集体消失，原先记载这些文字的纸连书写痕迹都没有，仿佛这些纸从来没有被书写过。\n三步之内必有解药！先辈们用偶然发现的自然凶险作为笔墨，成功地记载下了他们所探索到的全部凶险科技！",
        },
        filter = {"structure", "terror"},
    },
    terror_tower = {
        name = "terror_tower",
        atlas = "images/inventoryimages/terror_tower.xml",
        tex = "terror_tower.tex",
        details = {
            title = "凶险威澜台",
            subtitle = "威气逼人",
            anim_widget = {
                build = "terror_tower",
                bank = "terror_tower",
                anim = "idle_loop",
                pos = Vector3(0, -80, 0),
            },
            recipe_widget = {
                recipe = "terror_tower",
                desc = "有什么事，跟我的威澜之力说去吧。",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "凶险阵营",
                        },
                    },
                    desc = "既然不能和谐共谋，那就给你点颜色瞧瞧！",
                },
                {
                    title = "建筑",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "structure",
                            value = "4",
                            desc = "锤击4次后摧毁",
                        },
                    },
                    desc = "凶险威澜台通过其蕴含的强大力量对附近的一切自然物品造成威慑。",
                },
                {
                    title = "容器",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "container",
                            value = "4x4",
                            desc = "下侧有4x4的容器，容器内仅可存储具有温度的物品，如暖石。若当前世界的温度高于40℃，凶险威澜台会冰冻4x4容器内的物体。若当前世界的温度低于10℃，凶险威澜台会加热4x4容器内的物体。",
                        },
                        {
                            type = "container",
                            value = "1x3",
                            desc = "上侧有1x3的容器，容器内仅可放置对应的精华。具体如下：\n【第一格】可装载蓝莓精华，装载后半径20范围内的所有玩家可自由调控自身潮湿度（按移动键【↑】【↓】调节，可在设置中更改按键）。\n【第二格】可装载洋姜精华，装载后半径20范围内的所有玩家获得移速150%加成。\n【第三格】可装载蛇皮果精华，装载后半径20范围内的所有玩家获得恒温效果。",
                        },
                    },
                    desc = "凶险威澜台可吸收其内放置的物品的能量，亦可对其内放置的物品释放能量。",
                },
                {
                    title = "范围",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "structure",
                            value = "20",
                            desc = "半径20范围内防止野火生成。",
                        },
                        {
                            type = "structure",
                            value = "20",
                            desc = "半径20范围内防止建筑被自然力量破坏。",
                        },
                        {
                            type = "structure",
                            value = "20",
                            desc = "半径20范围内避雷。",
                        },
                    },
                    desc = "没有什么自然力量能在这座可以威慑一切的建筑附近嚣张得起来。",
                },
            },
            desc_introduce = "【凶险威澜台】自身具有防雷、防野火、防建筑破坏的效果，它的恒温、提速、控制潮湿度效果需要向其中添加对应的物品才可获得。",
            desc_story = "先辈们在一次又一次地经受自然灾害的折磨后，发现自然灾害就像调皮的小精灵，没有哪位家长可以管教得了它。但它们调皮归调皮，在遇到比它们更具有威慑力的东西时，它们也会避而远之。于是，经过不断试验，先辈们利用凶险阵营农作物培育出的精华，逼退了部分自然灾害。",
        },
        filter = {"structure", "terror"},
    },
    terror_staff = {
        name = "terror_staff",
        atlas = "images/inventoryimages/terror_staff.xml",
        tex = "terror_staff.tex",
        details = {
            title = "凶险手杖",
            subtitle = "空间之力",
            anim_widget = {
                build = "terror_staff",
                bank = "terror_staff",
                anim = "idle",
                pos = Vector3(0, -30, 0),
            },
            recipe_widget = {
                recipe = "terror_staff",
                desc = "人们意外地发现了恐怖粘液对空间的折叠效果。",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "凶险阵营",
                        },
                    },
                    desc = "将恐怖粘液对空间的效果开发到极致。",
                },
                {
                    title = "容器",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "container",
                            value = "1x1",
                            desc = "可装填恐怖粘液作为空间跃迁的消耗品。每次空间跃迁消耗1单位恐怖粘液。",
                        },
                    },
                    desc = "只有用凶险荆棘编织成的小盒子才能完美地容纳粘稠的恐怖粘液。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "blink",
                            value = "全图",
                            desc = "其容器内装填恐怖粘液后，可每次消耗1单位恐怖粘液进行全图空间跃迁。右键单击地面或地图后即可开始选择跃迁目的地。",
                        },
                        {
                            type = "weapon",
                            value = "20",
                            desc = "凶险手杖具有20点攻击力。",
                        },
                        {
                            type = "weapon",
                            value = "5",
                            desc = "凶险手杖具有5点位面伤害。",
                        },
                        {
                            type = "finiteuses",
                            value = "400",
                            desc = "凶险法杖最大可使用400次，每次攻击或跃迁消耗1次使用次数。使用次数消耗完毕后不会消失，但无法装备。使用凶险修补套件可以恢复使用次数。",
                        },
                        {
                            type = "setbonus",
                            value = "额外奖励",
                            desc = "与凶险阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n使用者会自动照料附近半径10单位内的农作物。",
                        },
                    },
                    desc = "凶险手杖依靠其散发出的恐怖气息，以及恐怖粘液对空间的折叠效果，大大加快了我们的工作效率！",
                },
            },
            desc_introduce = "凶险手杖是一把集农耕与位移于一体的实用工具。拥有了它，我们可以在相距很远的两块农田之间灵活穿梭，并以极为高效方案耕作。",
            desc_story = "荆棘的扭曲在人们看来可能只是容易扎手的麻烦事，但在植物的眼中，这些浑身长满刺的家伙就是蛮横的恐怖分子，就连凶险阵营的那几个农作物看到也得退避三份。为了不招惹到不必要的麻烦，农作物们选择了乖乖听这些荆棘的话。于是，聪明的先辈们利用这些荆棘，狐假虎威，很轻松地将种子种到土里。\n产自凶险阵营农作物的恐怖粘液也和这些荆棘有这密不可分的关系，当人们使用荆棘将难以处理的恐怖粘液约束起来时，恐怖粘液反而会具有更为强大的力量。它们可以直接在任何人们想要的地点将空间折叠，从而开辟一条捷径。",
        },
        filter = {"equipment", "terror"},
    },
    terror_sword = {
        name = "terror_sword",
        atlas = "images/inventoryimages/terror_sword.xml",
        tex = "terror_sword.tex",
        details = {
            title = "凶险荆棘",
            subtitle = "尖刺藤蔓",
            anim_widget = {
                build = "terror_sword",
                bank = "terror_sword",
                anim = "idle",
                pos = Vector3(10, -30, 0),
            },
            recipe_widget = {
                recipe = "terror_sword",
                desc = "满是荆棘的剑身，一看就知道是用什么制成的。",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "凶险阵营",
                        },
                    },
                    desc = "将凶险发挥到极致。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "weapon",
                            value = "60",
                            desc = "凶险荆棘具有60点攻击力。",
                        },
                        {
                            type = "weapon",
                            value = "15",
                            desc = "凶险荆棘具有15点位面伤害。",
                        },
                        {
                            type = "finiteuses",
                            value = "400",
                            desc = "凶险荆棘最大可使用400次，每次攻击消耗1次使用次数。使用次数消耗完毕后不会消失，但无法装备。使用凶险修补套件可以恢复使用次数。",
                        },
                        {
                            type = "setbonus",
                            value = "荆棘助战",
                            desc = "与凶险阵营的其他装备同时穿戴，可获得额外的效果。\n当触发套装效果时：\n使用者每累计攻击3次，若此时召唤者的生命值高于50点，且生命值百分比高于40%，则会召唤一条凶险藤蔓协助战斗，同时汲取召唤者20生命值，当凶险荆棘消失或被击败时，会将这20点生命值返还给玩家。\n凶险藤蔓具有200点血量，每次攻击造成伤害120点。凶险藤蔓直至被击杀或被召唤60秒后才会消失。",
                        },
                    },
                    desc = "凶险荆棘可以掌控来自凶险阵营的神秘植物力量，并召唤他们协助战斗。",
                },
            },
            desc_introduce = "凶险荆棘是用生长于凶险阵营土地上的荆棘尸体，辅以自然凶险编织而成。在凶险植物界，植物尸体就是先辈。故而凶险荆棘可以召唤凶险阵营的帮手前来助阵。",
            desc_story = "就地取材素来是先辈们的优秀技能之一。当人们用来自凶险阵营带刺的植物尸体制作工具时，没人会想到这把浑身是刺的长剑会有这般本领，这把长剑像是被赋予了生命，帮助持有这把剑的先辈们完成了一次又一次的捕猎，让先辈们得以熬过饥荒年代。",
        },
        filter = {"equipment", "terror"},
    },
    terror_bomb = {
        name = "terror_bomb",
        atlas = "images/inventoryimages/terror_bomb.xml",
        tex = "terror_bomb.tex",
        details = {
            title = "凶险炸弹",
            subtitle = "虞子花包裹",
            anim_widget = {
                build = "terror_bomb",
                bank = "terror_bomb",
                anim = "idle",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "terror_bomb",
                desc = "把虞子花包进去了！",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "凶险阵营",
                        },
                    },
                    desc = "令人安心的炸弹包裹。",
                },
                {
                    title = "装备",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "weapon",
                            value = "10",
                            desc = "凶险炸弹会对半径3单位的范围内造成10点爆炸伤害。并在爆炸点中央生成一朵虞子花，虞子花会持续吸引半径20单位内的敌对生物的仇恨。",
                        },
                    },
                    desc = "凶险炸弹中包裹的虞子花会吸引怪物的仇恨。",
                },
            },
            desc_introduce = "凶险炸弹的伤害不高，但它解体后释放出的虞子花的作用可是伤害比不了的。",
            desc_story = "在向大自然索取材料的同时，先辈们也没有忘记可持续发展。每次收获植物的枝条与果实的同时，先辈们都会为这些植物浇水施肥，以保证下次再来的时候，这些植物仍然能为他们提供新的物资。\n一次日常收获的途中。先辈们派遣的物资小组遭到了埋伏在池塘里的变种青蛙的突袭，他们数量极其庞大，并且被它们的唾液沾染上的先辈都感觉到刺骨的体寒，被围攻的小组无计可施，只能用手中的武器恐吓青蛙们，延缓他们的逼近。青蛙们的攻势愈发凶猛。在这危急关头，青蛙们却突然停止进攻，向他们身后跑去。先辈们回头望去，却发现在他们身后不远处，有一朵巨大的花。这朵花与他们平日里采集荆棘的植物的样子十分接近，可以猜到这就是这种植物的花。这朵花用发光的、深邃的蓝色眼睛怒视着这群青蛙，而这些青蛙们好像对这一行为极其愤怒。\n多亏这朵奇怪的花，先辈们得以免受青蛙的攻击，从而有了足够的能力击杀青蛙群。先辈们不知道这朵花这是出来究竟是为了帮助他们，还是仅仅是因为这朵花与青蛙本就有仇恨。\n后来，物资小组请来了能与植物通信的老者，才知，他们平时采集荆棘的行为在这些植物看来，就是为他们打理身体，而他们的浇水和施肥也被这些植物记在心里。这些植物愿意报答物资小组，遂将这朵巨花赠与了他们。后来，先辈们为这朵花取名为虞子花，有些人笑它为愚子，但只有经历过那场战斗的先辈才明白，这朵花为了报恩可以牺牲掉自己。",
        },
        filter = {"equipment", "terror"},
    },
    terror_kit = {
        name = "terror_kit",
        atlas = "images/inventoryimages/terror_kit.xml",
        tex = "terror_kit.tex",
        details = {
            title = "凶险修补套件",
            subtitle = "缝缝补补又是一年",
            anim_widget = {
                build = "terror_kit",
                bank = "terror_kit",
                anim = "idle",
                pos = Vector3(0, -5, 0),
            },
            recipe_widget = {
                recipe = "terror_kit",
                desc = "消耗更少的材料，进行更多的工作！",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "如果伤痕会让它变得更加强大呢？",
                        },
                    },
                    desc = "兼具恐怖粘液的粘性与自然凶险的锋利。",
                },
                {
                    title = "修补",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "repair",
                            value = "修补",
                            desc = "凶险修补套件在修复工具耐久度的同时，还会永久性提升这把工具的上限！修补后，会随机提升工具的移速加成、伤害，具体数值如下：\n【移动速度】75%概率触发，提升5%移速，最高提升至180%\n【伤害】25%概率触发，提升10%伤害，最高提升至250%\n",
                        },
                    },
                    desc = "用恐怖粘液对工具进行粘合，再用自然凶险对其进行加强！",
                },
            },
            desc_introduce = "【凶险修补套件】可以为我们节省很多成本，让我们可以进行更多工作！",
            desc_story = "在资源并不富足的时期，恐怖粘液只能通过采收生长在沼泽中的多汁植物来获得，而自然凶险更是稀有，先辈们只能祈祷狩猎时会遇到几只被凶险沼泽感染的动物。",
        },
        filter = {"item", "terror"},
    },
    terror_dangerous = {
        name = "terror_dangerous",
        atlas = "images/inventoryimages/terror_dangerous.xml",
        tex = "terror_dangerous.tex",
        details = {
            title = "自然凶险",
            subtitle = "凶险材料",
            anim_widget = {
                build = "hmr_naturalmaterials",
                bank = "hmr_naturalmaterials",
                anim = "terror_dangerous",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                desc = "锋利的凶险材料！",
                source = "击杀凶险事件中的生物以获得自然凶险！",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "凶险阵营的主要材料之一，可以制作多种凶险阵营的装备。",
                        },
                    },
                    desc = "内部蕴含着无法被人类研究的能量，至今没人知道它是如何合成的。",
                },
            },
            desc_introduce = "【自然凶险】可以制作凶险笼罩、凶险潜胄、凶险手杖、凶险荆棘等多种凶险阵营的装备。\n自然凶险可通过敲开巨大化蓝莓获取，巨大蓝莓掉落自然凶险的改率为5%。自然凶险更多地来自于凶险事件中暴动的生物，击杀他们可以有更高概率获得自然凶险。",
            desc_story = "贪食了凶险植物的生物们，会觉得自己充满了力量。这是因为凶险之核在悄无声息地改变着他们体内的构造。凶险核在帮助宿主动物进行更高效的能量转换的同时，也为自己逐渐汇聚能量形成自然凶险。这个过程是不可控的。只有在少数生物体内，这种寄生才会形成双赢的局面，在生物体内成功地合成自然凶险。对于那些体内没有成功合成自然凶险的生物来说，凶险核对他们的影响完全是正面的，至少在目前看来是如此。",
        },
        filter = {"item", "terror", "material"},
    },
    terror_mucous = {
        name = "terror_mucous",
        atlas = "images/inventoryimages/terror_mucous.xml",
        tex = "terror_mucous.tex",
        details = {
            title = "恐怖粘液",
            subtitle = "凶险材料",
            anim_widget = {
                build = "hmr_naturalmaterials",
                bank = "hmr_naturalmaterials",
                anim = "terror_mucous",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                desc = "粘性极强的凶险材料。",
                source = "种植巨大化的蓝莓、荔枝、咖啡、百香果以收获更多的恐怖粘液！",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "辉煌阵营的主要材料之一，可以制作多种辉煌阵营的装备。",
                        },
                    },
                    desc = "无与伦比的粘合剂。",
                },
            },
            desc_introduce = "恐怖粘液是凶险阵营农作物产出的一种特殊材料，它不能被直接使用，否则你会像粘鼠板上的老鼠一样无助。只有自然凶险才有约束恐怖粘液的力量。",
            desc_story = "先辈们从来没有想过，有一天会被自己种下的农作物困住。但这事确实发生了。某位倒霉的先辈在收货他精心照料的巨大蛇皮果时，被其中淌出的蓝黑色液体困在了田里，以至于直到现在，仍然会有大人将由这段搞笑的经历改编的故事讲给小孩子们听，逗得小孩子们咿咿大笑。\n但见识过恐怖粘液的作用的大人们，对这位倒霉的先辈，更多的是敬重，如果没有他，恐怖粘液可能就不会现世，人们也就缺少了很重要的材料来应对棘手的问题。",
        },
        filter = {"item", "terror", "material"},
    },
    terror_seeds = {
        name = "terror_seeds",
        atlas = "images/inventoryimages/terror_seeds.xml",
        tex = "terror_seeds.tex",
        details = {
            title = "凶险种子",
            subtitle = "凶险结晶",
            anim_widget = {
                build = "hmr_randomseeds",
                bank = "hmr_randomseeds",
                anim = "terror_seed",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "terror_seeds",
                desc = "凶险作物由此而来。",
            },
            parts = {
                {
                    title = "凶险阵营",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "terror",
                            value = "凶险",
                            desc = "可以种植出凶险阵营农作物的种子。\n蓝莓、荔枝、洋姜、蛇皮果、山楂、百香果、柠檬、彩椒都由此而来。",
                        },
                    },
                    desc = "经历自然凶险的同化，凝聚凶险能量。",
                },
            },
            desc_introduce = "并不是所有的农作物都可成为凶险阵营的一员，有些农作物因为可以像动物一样在体内凝聚出自然凶险而被认为是凶险阵营的一员，有些农作物因为可以产出与自然凶险有高度契合的恐怖粘液而被先辈们归类为凶险阵营农作物。",
            desc_story = "凶险力量在来到永恒大陆的那一刻起，就在逐渐影响大陆上的一切生物。人们总结出永恒大陆上的常见花瓣可以促进庄稼生长以后，开始尝试各种被辉煌与凶险能量影响的生物对庄稼的催化效果。深色花瓣就是其中之一，用它培育出的农作物往往会在其中夹杂着许多蓝黑色粘液，这种粘液虽然看起来很恶心，但却散发着一种兰草的幽香。",
        },
        filter = {"item", "terror"},
    },

    hmr_chest_store = {
        name = "hmr_chest_store",
        atlas = "images/inventoryimages/hmr_chest_store.xml",
        tex = "hmr_chest_store.tex",
        details = {
            title = "青衢纳宝箱",
            subtitle = "空间折叠技术",
            anim_widget = {
                build = "hmr_chest_store",
                bank = "hmr_chest_store",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "hmr_chest_store",
                desc = "热胀冷缩吗？有意思。",
            },
            parts = {
                {
                    title = "丰耘科技",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "hmr",
                            value = "丰耘",
                            desc = "通过丰耘科技面板解锁，需要消耗蓝莓精华x5。",
                        },
                    },
                    desc = "记载于丰耘宝典的空间科技。",
                },
                {
                    title = "容器",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "container",
                            value = "3x1",
                            desc = "未组成阵列的青衢纳宝箱容积很小，虽然可以无限堆叠，但只能容纳3组物品。\n当半径为5的范围内同时存在9~12个青衢纳宝箱时，箱子之间会相互作用，形成复杂的空间结构。此时这些箱子会组成一个阵列，容积大幅提升。当阵列中存在9个箱子时，可以容纳9x12组物品；当阵列中存在10个箱子时，可以容纳9x14组物品；当阵列中存在11个箱子时，可以容纳9x16组物品；当阵列中存在12个箱子时，可以容纳9x18组物品。\n当摧毁处于阵列中的箱子时，这个阵列会相应地降级或解体。\n阵列降级时，若原阵列中存储的物品过多，现阵列不能完全容纳，则会掉落一个青衢纳宝箱降级包，这个包中会容纳未能容下的所有物品，并于2天后消失并弹出所有其中的物品。\n阵列解体时，若原阵列中存储的物品过多，不能完全分配给余下的8个箱子，则会掉落一个青衢纳宝箱解体包，这个包中会容纳未能容下的所有物品，并于2天后消失并弹出所有其中的物品。",
                        },
                    },
                    desc = "可以放心把所有家当装在这里。",
                },
            },
            desc_introduce = "青衢纳宝箱不会被烧毁，但因其对庞大空间的结构需求，会消耗一些强度。需要小心地震等自然灾害！",
            desc_story = "露天摆放可不是屯物资的好办法！先辈们当然知道这一点。当先辈们看到那些粮仓煤仓紧巴巴的空间时，下定决心要做出来更高效的存储工具！",
        },
        filter = {"structure", "hmr"},
    },
    hmr_chest_transmit = {
        name = "hmr_chest_transmit",
        atlas = "images/inventoryimages/hmr_chest_transmit.xml",
        tex = "hmr_chest_transmit.tex",
        details = {
            title = "云梭递运箱",
            subtitle = "时间压缩技术",
            anim_widget = {
                build = "hmr_chest_transmit",
                bank = "hmr_chest_transmit",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "hmr_chest_transmit",
                desc = "嘭！发射！！！",
            },
            parts = {
                {
                    title = "丰耘科技",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "hmr",
                            value = "丰耘",
                            desc = "通过丰耘科技面板解锁，需要消耗蛇皮果精华x5。",
                        },
                    },
                    desc = "记载于丰耘宝典的时间科技。",
                },
                {
                    title = "容器",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "container",
                            value = "3x1",
                            desc = "云梭递运箱具有传送物品的功能，但这个功能需要通过辉煌背包来触发。当玩家在辉煌背包的搜索框中输入想要的物品的中文或代码并点击“传送”按钮后，该玩家所在世界中所有的云梭递运箱都会检测箱子内是否含有玩家想要的物资。如果没有任何一个云梭递运箱拥有该玩家请求的物资，所有的云梭递运箱会开始寻找其附近半径20单位范围内的所有青衢纳宝箱，若找到玩家所需的物资，云梭递运箱会将距离玩家最近的一组物资传送给玩家，并根据距离扣除该玩家的饥饿值，每5单位距离扣除1点饥饿值，最多扣除50点。若最终没有找到玩家请求的物资，玩家会因对物资的记忆偏差扣除5点理智值。",
                        },
                    },
                    desc = "出门忘带火把了？我帮你送来！",
                },
            },
            desc_introduce = "如果不是因为丢三落四，还是不要传送物资了，毕竟这对体力的额消耗太大了！",
            desc_story = "在交通不发达的年代，先辈们是多么希望能够伸手就取到千里之外的东西呀！先辈们想到了将物资像炮弹一样发射出去，但没人喜欢暴力快递。这种困境一直持续到了人们发现恐怖粘液在空间领域的恐怖潜力之时。如果将发射的炮弹折叠到不能被普通火药摧毁的大小，这就妥了！",
        },
        filter = {"structure", "hmr"},
    },
    hmr_chest_recycle = {
        name = "hmr_chest_recycle",
        atlas = "images/inventoryimages/hmr_chest_recycle.xml",
        tex = "hmr_chest_recycle.tex",
        details = {
            title = "龙龛探秘箱",
            subtitle = "成分离析技术",
            anim_widget = {
                build = "hmr_chest_recycle",
                bank = "hmr_chest_recycle",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "hmr_chest_transmit",
                desc = "垃圾？这可不是垃圾！",
            },
            parts = {
                {
                    title = "丰耘科技",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "hmr",
                            value = "丰耘",
                            desc = "通过丰耘科技面板解锁，需要消耗椰子精华x5。",
                        },
                    },
                    desc = "记载于丰耘宝典的原子科技。",
                },
                {
                    title = "容器",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "container",
                            value = "5+4",
                            desc = "龙龛探秘箱具有凝聚空间中的原子并重新排列组合的力量。龙龛探秘箱本身就是一个聚合过的小型垃圾堆，它可以容纳5个单位的特定材料和4个单位的垃圾。存放特定材料的5个格子会随机排列，并根据其位置高低，从下到上分为1、2、3级。当存放特定材料的格子被占用后，龙龛探秘箱会周期性地在其周围生成大小不一的垃圾堆，垃圾堆的大小以及其内掩藏的“礼物”与格子的等级、被占用的格子数相关。具体如下：\n【格子级别】1级格子每隔2天生成一个垃圾堆；2级格子每隔1.5天生成一个垃圾堆；3级格子每隔0.8天生成一个垃圾堆。\n【被占用的格子数量】当被占用的格子小于或等于2个时，只会生成初级垃圾堆；当被占用的格子超过2个但小于或等于4个时，会生成中级垃圾堆；当被占用的格子超过4个时，会根据格子内的物品类型生成不同类型的大型垃圾堆：（按先后顺序）如果废料大于等于2个，会生成高级零件垃圾堆；当玩具类型的物品大于等于3个时，会生成高级玩具垃圾堆；否则会生成高级常规垃圾堆。",
                        },
                    },
                    desc = "喜欢寻宝吗？",
                },
            },
            desc_introduce = "可以选择一片空旷的地方，建造一个专属的寻宝垃圾场！",
            desc_story = "先辈们当然懂得什么事节俭！自从发现恐怖粘液对于空间的作用后，先辈们便投身于此。终于，先辈们发现了恐怖粘液控制空间的原理：依靠其极强的粘性，对原子及其内部进行改造以及传输。龙龛探秘箱就是运用恐怖粘液对原子的改造的功能，进行垃圾堆的生成。不过恐怖粘液可不知道你要把这个垃圾堆放在哪里。",
        },
        filter = {"structure", "hmr"},
    },
    hmr_chest_factory = {
        name = "hmr_chest_factory",
        atlas = "images/inventoryimages/hmr_chest_factory.xml",
        tex = "hmr_chest_factory.tex",
        details = {
            title = "灵枢织造箱",
            subtitle = "木枢机关技术",
            anim_widget = {
                build = "hmr_chest_factory",
                bank = "hmr_chest_factory",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "hmr_chest_factory",
                desc = "咔嚓咔嚓！",
            },
            parts = {
                {
                    title = "丰耘科技",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "hmr",
                            value = "丰耘",
                            desc = "通过丰耘科技面板解锁，需要消耗茶丛精华x5。",
                        },
                    },
                    desc = "记载于丰耘宝典的时间科技。",
                },
                {
                    title = "容器",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "container",
                            value = "5",
                            desc = "建造灵枢织造箱，箱子内会附赠1~5个灵枢织造箱核心。其中，获得第一个核心的概率为1，获得第2个核心的概率为0.5，获得第三个核心的概率为0.5，获得第四个核心的概率为0.05，获得第五个核心的概率为0.005。\n灵枢织造箱附赠的核心会与该箱子绑定，在核心给予绑定的箱子产品时，会有额外20%的概率多给予1个产品。\n当灵枢织造箱核心位于一个封闭空间内（如被石墙和木门围起的地方）时，灵枢织造箱核心会自动检测空间内的物品，若空间内的物品属于先辈记载的工厂的原材料，则灵枢织造箱核心会开始生产该原材料所能产出的物品（如：空间内有常青树或多枝树，则灵枢织造箱核心会开始生产木头、木板、松果等产品，并传输给附近的灵枢织造箱。更多的工厂类型请自行探索！）。\n灵枢织造箱核心产出产品的效率与封闭空间的面积大小以及空间内原材料的数量有关，请合理安排工厂的空间！",
                        },
                    },
                    desc = "重复性的工作，我才不要自己做！",
                },
            },
            desc_introduce = "灵枢织造箱自己本身不会产出物品，它依靠部署在其附近的灵枢织造箱核心为其传输物品。不过灵枢织造箱的容积可不大，如果灵枢织造箱被堆满了，灵枢织造箱核心会在一段时间后停止工作。",
            desc_story = "日出而作，日落而息；周而复始，始而复周......总会有厌倦了昨天像今天、今天像明天的枯燥生活的先辈来打破这一魔咒。从牲畜动力到水动力再到如今的核心动力，先辈们已经不再满足于传统的收获，而是利用这股不属于永恒大陆的力量，开始创造资源。先辈们设计出了一个特殊的工厂，这个工厂只需要模仿摆在它旁边的原材料，就能生产出这些原材料的产品。不过这个工厂的抗干扰能力很差。任何其他物品摆在他面前，都会干扰他的生产。",
        },
        filter = {"structure", "hmr"},
    },
    hmr_chest_factory_core = {
        name = "hmr_chest_factory_core_item",
        atlas = "images/inventoryimages/hmr_chest_factory_core_item.xml",
        tex = "hmr_chest_factory_core_item.tex",
        details = {
            title = "灵枢织造箱核心",
            subtitle = "木枢机关技术",
            anim_widget = {
                build = "hmr_chest_factory_core",
                bank = "hmr_chest_factory_core",
                anim = "pack_loop",
                pos = Vector3(0, -40, 0),
            },
            recipe_widget = {
                recipe = "hmr_chest_factory_core_item",
                desc = "咔嚓咔嚓！",
            },
            parts = {
                {
                    title = "丰耘科技",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "hmr",
                            value = "丰耘",
                            desc = "通过丰耘科技面板解锁，需要消耗茶丛精华x5。",
                        },
                    },
                    desc = "记载于丰耘宝典的时间科技。",
                },
                {
                    title = "可交互建筑",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "structure",
                            value = "部署",
                            desc = "灵枢织造箱核心可被右键部署至合适位置。部署后的灵枢织造箱核心若位于符合要求的封闭空间内，则会自动开始工作，生产原材料所对应的产品。详情见【灵枢织造箱】。",
                        },
                    },
                    desc = "重复性的工作，我才不要自己做！",
                },
            },
            desc_introduce = "灵枢织造箱自己本身不会产出物品，它依靠部署在其附近的灵枢织造箱核心为其传输物品。不过灵枢织造箱的容积可不大，如果灵枢织造箱被堆满了，灵枢织造箱核心会在一段时间后停止工作。",
            desc_story = "日出而作，日落而息；周而复始，始而复周......总会有厌倦了昨天像今天、今天像明天的枯燥生活的先辈来打破这一魔咒。从牲畜动力到水动力再到如今的核心动力，先辈们已经不再满足于传统的收获，而是利用这股不属于永恒大陆的力量，开始创造资源。先辈们设计出了一个特殊的工厂，这个工厂只需要模仿摆在它旁边的原材料，就能生产出这些原材料的产品。不过这个工厂的抗干扰能力很差。任何其他物品摆在他面前，都会干扰他的生产。",
        },
        filter = {"structure", "hmr", "item"},
    },
    hmr_chest_display = {
        name = "hmr_chest_display",
        atlas = "images/inventoryimages/hmr_chest_display.xml",
        tex = "hmr_chest_display.tex",
        details = {
            title = "华樽耀勋箱",
            subtitle = "精神汲取技术",
            anim_widget = {
                build = "hmr_chest_display",
                bank = "hmr_chest_display",
                anim = "idle",
                --pos = Vector3(0, -20, 0),
            },
            recipe_widget = {
                recipe = "hmr_chest_display",
                desc = "展示你的荣耀！",
            },
            parts = {
                {
                    title = "丰耘科技",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "hmr",
                            value = "丰耘",
                            desc = "通过丰耘科技面板解锁，需要消耗金灯果精华x5。",
                        },
                    },
                    desc = "丰耘宝典浓墨重彩的一页。",
                },
                {
                    title = "容器",
                    --title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "container",
                            value = "3",
                            desc = "华樽耀勋箱可以展示巨大化农作物以及雕像。当华樽耀勋箱中摆放了巨大化农作物或雕像后，会发光并提供一个半径为10的范围理智光环。",
                        },
                    },
                    desc = "至高无上的荣誉。",
                },
            },
            desc_introduce = "还在发愁别人看不到自己的功勋吗？建造一个华樽耀勋箱来摆放他们吧！",
            desc_story = "先辈们的部落之间没有激烈的打斗，只有能力的比试！",
        },
        filter = {"structure", "hmr"},
    },

    honor_tea_prime = {
        name = "honor_tea_prime",
        atlas = "images/inventoryimages/honor_tea_prime.xml",
        tex = "honor_tea_prime.tex",
        details = {
            title = "茶丛精华",
            subtitle = "茶酚净化",
            anim_widget = {
                build = "hmr_primes",
                bank = "hmr_primes",
                anim = "honor_tea_prime",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "honor_tea_prime",
                desc = "以大量茶叶凝聚的精华！",
            },
            parts = {
                {
                    title = "食物",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "food",
                            value = "上限",
                            badges = {
                                {
                                    type = "hunger",
                                    value = "0",
                                },
                                {
                                    type = "health",
                                    value = "0",
                                },
                                {
                                    type = "sanity",
                                    value = "9999999",
                                }
                            },
                            desc = "",
                        },
                    },
                    desc = "",
                },
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "buff",
                            desc = "吃掉茶丛精华后，玩家的理智值会立即恢复至满状态，同时玩家每次攻击有15%的概率将目标定身6秒，且期间目标不可因任何原因解除定身。效果持续240秒。",
                        },
                    },
                    desc = "茶丛精华可以在香料站被被制作成香料，效果稍差，但可以使用更多次。",
                },
                {
                    title = "辉煌法杖",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "可将茶丛精华给予辉煌法杖。获得茶丛精华的辉煌法杖将会有几率发射茶丛法球，命中敌人对敌人增加3点定身值。当敌人定身值满后，会被定身。",
                        },
                    },
                    desc = "茶丛精华因与辉煌法杖具有很高的契合度，故而可以与辉煌法杖融合。",
                },
            },
            desc_introduce = "等待揭秘",
            desc_story = "等待揭秘",
        },
        filter = {"item", "honor", "food", "prime", "buff"},
    },
    honor_coconut_prime = {
        name = "honor_coconut_prime",
        atlas = "images/inventoryimages/honor_coconut_prime.xml",
        tex = "honor_coconut_prime.tex",
        details = {
            title = "椰子精华",
            subtitle = "椰灵助势",
            anim_widget = {
                build = "hmr_primes",
                bank = "hmr_primes",
                anim = "honor_coconut_prime",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "honor_coconut_prime",
                desc = "以大量椰子凝聚的精华！",
            },
            parts = {
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "buff",
                            desc = "吃掉椰子精华后，玩家每次攻击有3%的概率召唤出树精协助自己作战。效果持续480秒。",
                        },
                    },
                    desc = "椰子精华可以在香料站被被制作成香料，效果稍差，但可以使用更多次。",
                },
                {
                    title = "辉煌法杖",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "可将椰子精华给予辉煌法杖。获得椰子精华的辉煌法杖将会有几率发射椰子法球，命中敌人后会在命中点降落两枚椰子，每枚椰子对敌人造成10点伤害。",
                        },
                    },
                    desc = "椰子精华因与辉煌法杖具有很高的契合度，故而可以与辉煌法杖融合。",
                },
            },
            desc_introduce = "等待揭秘",
            desc_story = "等待揭秘",
        },
        filter = {"item", "honor", "food", "prime", "buff"},
    },
    honor_wheat_prime = {
        name = "honor_wheat_prime",
        atlas = "images/inventoryimages/honor_wheat_prime.xml",
        tex = "honor_wheat_prime.tex",
        details = {
            title = "小麦精华",
            subtitle = "冰霜之息",
            anim_widget = {
                build = "hmr_primes",
                bank = "hmr_primes",
                anim = "honor_wheat_prime",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "honor_wheat_prime",
                desc = "以大量小麦凝聚的精华！",
            },
            parts = {
                {
                    title = "食物",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "food",
                            value = "60",
                            badges = {
                                {
                                    type = "hunger",
                                    value = "60",
                                },
                                {
                                    type = "health",
                                    value = "0",
                                },
                                {
                                    type = "sanity",
                                    value = "0",
                                }
                            },
                            desc = "",
                        },
                    },
                    desc = "",
                },
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "buff",
                            desc = "吃掉小麦精华后，玩家会立即恢复60点饱食度，同时玩家每次攻击有40%的概率增加目标4点冰冻值。效果持续240秒。",
                        },
                    },
                    desc = "小麦精华可以在香料站被被制作成香料，效果稍差，但可以使用更多次。",
                },
                {
                    title = "辉煌法杖",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "可将小麦精华给予辉煌法杖。获得小麦精华的辉煌法杖将会有几率发射小麦法球，命中敌人后会增加敌人3点冰冻值。",
                        },
                    },
                    desc = "小麦精华因与辉煌法杖具有很高的契合度，故而可以与辉煌法杖融合。",
                },
            },
            desc_introduce = "等待揭秘",
            desc_story = "等待揭秘",
        },
        filter = {"item", "honor", "food", "prime", "buff"},
    },
    honor_rice_prime = {
        name = "honor_rice_prime",
        atlas = "images/inventoryimages/honor_rice_prime.xml",
        tex = "honor_rice_prime.tex",
        details = {
            title = "水稻精华",
            subtitle = "凝聚力量",
            anim_widget = {
                build = "hmr_primes",
                bank = "hmr_primes",
                anim = "honor_rice_prime",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "honor_rice_prime",
                desc = "以大量小麦凝聚的精华！",
            },
            parts = {
                {
                    title = "食物",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "food",
                            value = "60",
                            badges = {
                                {
                                    type = "hunger",
                                    value = "60",
                                },
                                {
                                    type = "health",
                                    value = "0",
                                },
                                {
                                    type = "sanity",
                                    value = "0",
                                }
                            },
                            desc = "",
                        },
                    },
                    desc = "",
                },
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "buff",
                            desc = "吃掉水稻精华后，玩家会立即恢复60点饱食度，同时玩家会获得大量体力，工作效率增加至2倍，伤害倍率增加为1.2倍。效果持续600秒。",
                        },
                    },
                    desc = "水稻精华可以在香料站被被制作成香料，效果完全不同。",
                },
                {
                    title = "辉煌法杖",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "honor",
                            value = "辉煌",
                            desc = "可将水稻精华给予辉煌法杖。获得水稻精华的辉煌法杖将会有几率发射水稻法球，水稻法球的伤害是普通法球的1.5倍。",
                        },
                    },
                    desc = "水稻精华因与辉煌法杖具有很高的契合度，故而可以与辉煌法杖融合。",
                },
            },
            desc_introduce = "等待揭秘",
            desc_story = "等待揭秘",
        },
        filter = {"item", "honor", "food", "prime", "buff"},
    },
    terror_blueberry_prime = {
        name = "terror_blueberry_prime",
        atlas = "images/inventoryimages/terror_blueberry_prime.xml",
        tex = "terror_blueberry_prime.tex",
        details = {
            title = "蓝莓精华",
            subtitle = "雨露之息",
            anim_widget = {
                build = "hmr_primes",
                bank = "hmr_primes",
                anim = "terror_blueberry_prime",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "terror_blueberry_prime",
                desc = "以大量蓝莓凝聚的精华！",
            },
            parts = {
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "buff",
                            desc = "吃掉蓝莓精华后，玩家会获得控制自身潮湿度的能力，按键盘↑键可使潮湿度增加1%，按键盘↓键可使潮湿度减少1%，长按可连续变动自身潮湿值（可在设置界面更换按键绑定）。效果持续600秒。",
                        },
                    },
                    desc = "蓝莓精华可以在香料站被被制作成香料，效果完全不同。",
                },
            },
            desc_introduce = "等待揭秘",
            desc_story = "等待揭秘",
        },
        filter = {"item", "terror", "food", "prime", "buff"},
    },
    terror_ginger_prime = {
        name = "terror_ginger_prime",
        atlas = "images/inventoryimages/terror_ginger_prime.xml",
        tex = "terror_ginger_prime.tex",
        details = {
            title = "洋姜精华",
            subtitle = "雨露之息",
            anim_widget = {
                build = "hmr_primes",
                bank = "hmr_primes",
                anim = "terror_ginger_prime",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "terror_ginger_prime",
                desc = "以大量洋姜凝聚的精华！",
            },
            parts = {
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "buff",
                            desc = "吃掉洋姜精华后，玩家会获得食物收益增幅：若玩家对食物的吸收收益小于50%，则会提升为100%；否则提升至200%（如，沃姆伍德原先对食物提供的生命值收益为0%，食用洋姜精华后，对生命值的收益变为100%）。同时玩家会获得放置和使用厨师沃利的三种厨具的能力，并且会提升自身厨艺。效果持续600秒。",
                        },
                    },
                    desc = "洋姜精华可以在香料站被被制作成香料，效果稍差，但可以使用更多次。",
                },
            },
            desc_introduce = "等待揭秘",
            desc_story = "等待揭秘",
        },
        filter = {"item", "terror", "food", "prime", "buff"},
    },
    terror_snakeskinfruit_prime = {
        name = "terror_snakeskinfruit_prime",
        atlas = "images/inventoryimages/terror_snakeskinfruit_prime.xml",
        tex = "terror_snakeskinfruit_prime.tex",
        details = {
            title = "蛇皮果精华",
            subtitle = "烈焰之息",
            anim_widget = {
                build = "hmr_primes",
                bank = "hmr_primes",
                anim = "terror_snakeskinfruit_prime",
                pos = Vector3(0, -10, 0),
            },
            recipe_widget = {
                recipe = "terror_snakeskinfruit_prime",
                desc = "以大量蛇皮果凝聚的精华！",
            },
            parts = {
                {
                    title = "增益",
                    title_colour = {0.137, 0.237, 0.156, 1},
                    infos = {
                        {
                            type = "buff",
                            value = "buff",
                            desc = "吃掉蛇皮果精华后，玩家每次受到攻击时，会有50%的概率激怒蛇皮果精华，立即点燃攻击者，同时在攻击者附近点燃3~6团火焰，每团火焰造成5点伤害。效果持续240秒。",
                        },
                    },
                    desc = "蛇皮果精华可以在香料站被被制作成香料，效果稍差，但可以使用更多次。",
                },
            },
            desc_introduce = "等待揭秘",
            desc_story = "等待揭秘",
        },
        filter = {"item", "terror", "food", "prime", "buff"},
    },
}


--[[
    类别：
        装备 equipment
            耐久度 durability
            防御 defense
            攻击 damage
            速度 speed
            射程 range
            工作 work
        建筑 structure

        材料 material
        作物 farmplant
        调味料 spice
        料理 preparedfood
        植物 plant
        生物 creature
        大生物 boss
        人物 character
        地形 terrain
        增益 buff

        奇遇 event
        联动 bonus

]]



--[[
    示例
    prefab = {
        name = "honor_machine",
        atlas = "images/inventoryimages/honor_machine.xml",
        tex = "honor_machine.tex",
        details = {
            *title = "自然亲和机器【辉煌科技】",
            subtitle = "解锁辉煌科技",
            anim_widget = {
                build = "honor_machine",
                bank = "honor_machine",
                anim = "idle",
                pos = Vector3(0, 0, 0),
            },
            tech = "",      -- 科技
            recipe = "",    -- 配方
            parts = {
                {
                    *title = "科技",
                    title_colour = {r, g, b, a},
                    infos = {       -- 各种数值，精神、生命、伤害、防水等都写在这里
                        {
                            atlas = "",
                            tex = "",
                            value = "",     -- 数值，可以写汉字
                            value_colour = {r, g, b, a},
                            desc = "描述"
                            desc_colour = {r, g, b, a},
                        },
                        {
                            atlas = "",
                            tex = "",
                            value = "",
                            desc = "描述"
                        },
                    },
                    desc = "描述",
                },
            },
            desc_introduce = "介绍描述",
            desc_story = "背景故事描述",
        }
    }
]]