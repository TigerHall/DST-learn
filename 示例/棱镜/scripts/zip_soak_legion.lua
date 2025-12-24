local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --为了不暴露局部变量，单独装一起

--[[
    设计思路：
        一个泉池最多能放入6种物品（极值都按3个来算，指就算是最厉害的物品也得至少3种才能达到完美）
        有的物品偏向于回复、有的物品偏向于提升buff时间、有的物品能提供新buff
        在数值设计上，不可能所有要求都能满足，要让玩家自己取舍！鱼和熊掌不可兼得。
        玩家自由搭配放入的物品，来尽量满足自己的浸泡偏好：比如完全规避某些负面buff、提升回复量、更快更好地加buff等
    数值思路：
        原本的生命、精神回复量，以及buff时间都提高到至少3倍
        添料的填写数值是-1~1之间，优劣阶梯为【0.075, 0.15, 0.225, 0.3】
        应用buff时间系数时，如果大于0，则还需再乘以10，因为buff时间正向的变化范围是(1+0)~(1+9)倍，负向的范围是(1-0)~(1-0.9)倍
]]--
local r = { 0.075, 0.15, 0.225, 0.3, 0.6 } -- r[5]是最顶级的属性，不要轻易赋予
fns.values = r --暴露出来让其他模组用的
fns.buffs = {
    buff_l_warm = { --buff的prefab名。温暖
        --泡满是指浸泡40秒
        --因为添料能使得系数0~1~10，所以2400/40秒(只需泡满一次)/10系数=6
        --6x40=240(也就是只泡满一次，只能增加4分钟buff时间。如果要达到2400秒，共需泡满10次才能达到最大buff时间)
        time = 6, --每秒浸泡能增加的buff时间
        cycle = 10, --每隔该时间，就会开始加buff
        -- noforce = true, --代表时间积累未达到cycle时，是否禁止给予buff
        -- isbad = true, --代表这个buff对玩家来说是否是坏的
        -- idx = 4, --buff序号。会自动从 fns.buffinfos 里获取
    },
    buff_l_cool = { time = 6, cycle = 10 }, --凉爽。6x40=240。最大40分钟
    buff_l_bath = { time = 0.6, cycle = 10 }, --出浴。0.6x60=36。最大6分钟
    buff_l_softskin = { time = 3, cycle = 20, noforce = true, isbad = true }, --柔软皮肤。3x80=240。最大40分钟
    buff_l_dizzy = { time = 0.6, cycle = 40, noforce = true, isbad = true }, --晕乎乎。0.6x60=36。最大6分钟
    buff_l_workup = { time = 6, cycle = 10 }, --高效工作。6x40=240。最大40分钟
    buff_l_defense = { time = 6, cycle = 10 }, --健康抵抗力。6x40=240。最大40分钟
    buff_l_attack = { time = 6, cycle = 10 }, --有劲。6x40=240。最大40分钟
    buff_l_antiacid = { time = 6, cycle = 10 }, --抗酸。6x40=240。最大40分钟
    buff_l_radiantskin = { time = 6, cycle = 10 }, --闪亮皮肤。6x40=240。最大40分钟
    buff_l_fireproof = { time = 6, cycle = 10 }, --隔火皮肤。6x40=240。最大40分钟
    buff_l_sivbloodreduce = { time = 6, cycle = 10 }, --假弱皮肤。6x40=240。最大40分钟
}
fns.buffinfos = { --用来给buff排序以及信息展示用的
    {   name = "buff_l_dizzy",
        showcycle = true, --是否需要展示 cycle 属性。常用正面buff不需要展示，因为都是默认10秒
        -- cycle = 10, --会自动从 fns.buffs 里获取
        -- time = 6, --会自动从 fns.buffs 里获取
    },
    { name = "buff_l_softskin", showcycle = true },
    { name = "buff_l_bath" },
    { name = "buff_l_warm" },
    { name = "buff_l_cool" },
    { name = "buff_l_workup" },
    { name = "buff_l_defense" },
    { name = "buff_l_attack" },
    { name = "buff_l_antiacid" },
    { name = "buff_l_radiantskin" },
    { name = "buff_l_fireproof" },
    { name = "buff_l_sivbloodreduce" }
}
fns.fish = { --数值思路：均以60条鱼为基础进行设计
    oceanfish_small_1_inv = { --小孔雀鱼
        values = { --对基础数值的改动(加法)
            -- health = 0, --一般鱼不会导致扣血，除非有毒。建议大鱼-0.06，小鱼-0.03。也就是60条大鱼-3.6点、小鱼-1.8
            sanity = -0.04, --建议大鱼-0.08，小鱼-0.04。也就是60条大鱼-4.8点、小鱼-2.4
            moisture = 0.04, --一般鱼不会导致浸水，除非是浅水层鱼类。建议大鱼0.08，小鱼0.04。也就是60条大鱼+4.8点、小鱼+2.4
            -- temperature = { 0, 0 }, --[1]对每次温度的修改、[2]对温度极值的修改
            formula = 0.03 --植物人的催长剂。建议大鱼0.06，小鱼0.03。也就是60条大鱼+3.6点，小鱼+1.8
        },
    },
    oceanfish_small_2_inv = { --针鼻喷墨鱼
        values = { sanity = -0.04, moisture = 0.04, formula = 0.03 }
    },
    oceanfish_small_3_inv = { --小饵鱼
        values = { sanity = -0.04, moisture = 0.04, formula = 0.03 }
    },
    oceanfish_small_4_inv = { --三文鱼苗
        values = { sanity = -0.04, moisture = 0.04, formula = 0.03 }
    },
    oceanfish_small_5_inv = { --爆米花鱼
        values = { sanity = 0.02, formula = -0.03 }
    },
    oceanfish_small_6_inv = { --落叶比目鱼
        values = { sanity = -0.04, formula = 0.09 }
    },
    oceanfish_small_7_inv = { --花朵金枪鱼
        values = { health = 0.03, sanity = 0.02, formula = -0.03 }
    },
    oceanfish_small_8_inv = { --炽热太阳鱼
        values = { sanity = -0.04, moisture = 0.04, temperature = { 0.1, 0.8 }, formula = 0.03 }
    },
    oceanfish_small_9_inv = { --口水鱼
        values = { sanity = -0.04, moisture = 0.12, formula = 0.03 }
    },
    oceanfish_medium_1_inv = { --泥鱼
        values = { sanity = -0.1, formula = 0.09 }
    },
    oceanfish_medium_2_inv = { --斑鱼
        values = { sanity = -0.08, formula = 0.06 }
    },
    oceanfish_medium_3_inv = { --浮夸狮子鱼
        values = { health = -0.06, sanity = 0.04, formula = 0.06 }
    },
    oceanfish_medium_4_inv = { --黑鲶鱼
        values = { sanity = -0.08, formula = 0.06 }
    },
    oceanfish_medium_5_inv = { --玉米鳕鱼
        values = { sanity = 0.04, formula = -0.06 }
    },
    oceanfish_medium_6_inv = { --花锦鲤
        values = { sanity = -0.04, moisture = 0.08, formula = 0.06 }
    },
    oceanfish_medium_7_inv = { --金锦鲤
        values = { sanity = -0.04, moisture = 0.08, formula = 0.06 }
    },
    oceanfish_medium_8_inv = { --冰鲷鱼
        values = { sanity = -0.08, temperature = { -0.1, -0.8 }, formula = 0.06 }
    },
    oceanfish_medium_9_inv = { --甜味鱼
        values = { health = 0.06, sanity = -0.08, moisture = 0.08, formula = 0.06 }
    },
    fish = { --(旧版)淡水鱼
        values = { sanity = -0.08, moisture = 0.08, formula = 0.06 }
    },
    pondfish = { --淡水鱼
        values = { sanity = -0.04, moisture = 0.04, formula = 0.03 }
    },
    pondeel = { --活鳗鱼
        values = { sanity = -0.08, formula = 0.06 }
    },
    wobster_sheller_land = { --龙虾
        values = { sanity = -0.08, formula = -0.06 }
    },
    wobster_moonglass_land = { --月光龙虾
        values = { moisture = -0.04, formula = -0.06 }
    }
}
fns.spices = {
    --[[
    royal_jelly = {
        prefab = "royal_jelly", --prefab名
        costmax = 100, --可消耗总次数(为空则代表不会消耗)
        buffs = { buff_l_xx = {r[4],true,nil} }, --[1]buff时间系数(乘法)、[2]能否主动提供buff、[3]浸泡时间修正值(加法)
        values = { --对基础数值的改动(加法)
            health = 0.5, sanity = 0.25, moisture = 1,
            temperature = { 0.1, 15 }, --[1]对每次温度的修改、[2]对温度极值的修改
            formula = 0.2 --植物人的催长剂
        },
        costs = { --消耗数据。每有一个符合就会消耗对应的值。一般只给生命、精神、催长剂、buff设置消耗数据
            health = 1, sanity = 0.5, formula = 1, buff_l_xx = 1 --为了便于计算和理解，主消耗值一般都是1
        },
        fn_value = function(pondcpt, spicesdata, spicekey, newbuffs)end, --自定义的数值改动函数
        fn_tick = function(pondcpt, soakercpt, costs, item)end, --自定义的浸泡周期函数
        fn_cost = function(pondcpt, spicedd, costcount, costs)end, --自定义的消耗函数
    },]]--
    -- xxx = {
    --     prefab = "", costmax = ,
    --     buffs = {  },
    --     values = {  },
    --     costs = {  }
    -- },
    royal_jelly = { --蜂王浆
        prefab = "royal_jelly", costmax = 252,
        buffs = { buff_l_softskin={-r[4]}, buff_l_bath={r[3]}, buff_l_warm={r[2]}, buff_l_workup={r[4],true} },
        values = { health=1, sanity=0.1 },
        costs = { health=1, sanity=1, buff_l_softskin=1, buff_l_workup=1 }
    },
    honeycomb = { --蜜脾
        prefab = "honeycomb", costmax = 500,
        buffs = { buff_l_softskin={-r[1]}, buff_l_warm={r[1]}, buff_l_workup={r[2],true} },
        values = { health=0.2 },
        costs = { health=1, buff_l_workup=1 }
    },
    honey = { --蜂蜜
        prefab = "honey", costmax = 50,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[1]}, buff_l_workup={r[2]} },
        values = { health=0.2 },
        costs = { health=1, buff_l_softskin=1, buff_l_workup=1 }
    },
    bandage = { --蜂蜜药膏
        prefab = "bandage", costmax = 140,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[1]}, buff_l_workup={r[3]} },
        values = { health=0.25 },
        costs = { health=1, buff_l_softskin=1, buff_l_workup=1 }
    },
    spidergland = { --蜘蛛腺
        prefab = "spidergland", costmax = 40,
        buffs = { buff_l_softskin={r[1]}, buff_l_cool={r[1]}, buff_l_antiacid={r[1]} },
        values = { health=0.2 },
        costs = { health=1, buff_l_antiacid=1 }
    },
    healingsalve = { --治疗药膏
        prefab = "healingsalve", costmax = 100,
        buffs = { buff_l_softskin={r[1]}, buff_l_cool={r[1]}, buff_l_antiacid={r[1]} },
        values = { health=0.25 },
        costs = { health=1, buff_l_antiacid=1 }
    },
    healingsalve_acid = { --黏糊糊的药膏
        prefab = "healingsalve_acid", costmax = 120,
        buffs = { buff_l_softskin={r[3]}, buff_l_cool={r[2]}, buff_l_antiacid={r[3],true} },
        values = { health=0.25, moisture=0.1, formula=0.2 },
        costs = { health=1, formula=1, buff_l_antiacid=1 }
    },
    slurtleslime = { --蛞蝓龟黏液
        prefab = "slurtleslime", costmax = 40,
        buffs = { buff_l_softskin={-r[2]}, buff_l_antiacid={r[4]}, buff_l_fireproof={r[4]} },
        values = { sanity=-0.1, moisture=0.1 },
        costs = { buff_l_softskin=1, buff_l_antiacid=1, buff_l_fireproof=1 }
    },
    nitre = { --硝石
        prefab = "nitre", costmax = 50,
        buffs = { buff_l_warm={-r[2]}, buff_l_cool={r[2]},
            buff_l_antiacid={r[3]}, buff_l_workup={r[2]}, buff_l_defense={r[2]}, buff_l_attack={r[2]}
        },
        values = { formula=0.2, temperature={-0.2,-2.5} },
        costs = { formula=1, buff_l_antiacid=1, buff_l_workup=1, buff_l_defense=1, buff_l_attack=1 }
    },
    pepper = { --辣椒
        prefab = "pepper", costmax = 155,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_softskin={r[2]}, buff_l_bath={-r[4]},
            buff_l_warm={r[3]}, buff_l_cool={-r[3]}, buff_l_attack={r[4]}
        },
        values = { health=-0.25, sanity=-0.2, temperature={0.2,2.5} },
        costs = { health=1, sanity=1, buff_l_warm=1, buff_l_attack=1 }
    },
    garlic = { --大蒜
        prefab = "garlic", costmax = 50,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={r[1]}, buff_l_bath={-r[2]},
            buff_l_warm={r[1]}, buff_l_cool={-r[1]}, buff_l_defense={r[4]}
        },
        values = { sanity=-0.2 },
        costs = { sanity=1, buff_l_defense=1 }
    },
    onion = { --洋葱
        prefab = "onion", costmax = 50,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_softskin={r[1]}, buff_l_bath={-r[2]} },
        values = { sanity=-0.2 },
        costs = { sanity=1 }
    },
    spice_sugar = { --蜂蜜水晶
        prefab = "spice_sugar", costmax = 60,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[2]}, buff_l_warm={r[1]}, buff_l_workup={r[3],true} },
        values = {  },
        costs = { buff_l_softskin=1, buff_l_workup=1 }
    },
    spice_garlic = { --蒜粉
        prefab = "spice_garlic", costmax = 60,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_bath={-r[2]}, buff_l_warm={r[1]}, buff_l_defense={r[3],true} },
        values = { sanity=-0.1 },
        costs = { buff_l_defense=1 }
    },
    spice_chili = { --辣椒面
        prefab = "spice_chili", costmax = 60,
        buffs = { buff_l_dizzy={-r[3]}, buff_l_softskin={r[3]}, buff_l_bath={-r[4]},
            buff_l_warm={r[3]}, buff_l_cool={-r[2]}, buff_l_attack={r[3],true}
        },
        values = { health=-0.2, sanity=-0.1, temperature={0.2,2.5} },
        costs = { buff_l_warm=1, buff_l_attack=1 }
    },
    spice_salt = { --调味盐
        prefab = "spice_salt", costmax = 60,
        buffs = { buff_l_softskin={-r[1]}, buff_l_warm={r[2]}, buff_l_cool={r[2]},
            buff_l_antiacid={r[4]}, buff_l_workup={r[3]}, buff_l_defense={r[3]}, buff_l_attack={r[3]}
        },
        values = { health=0.25 },
        costs = { health=1, buff_l_antiacid=1, buff_l_workup=1, buff_l_defense=1, buff_l_attack=1 }
    },
    saltrock = { --盐晶
        prefab = "saltrock", costmax = 50,
        buffs = { buff_l_warm={r[2]}, buff_l_cool={r[2]},
            buff_l_antiacid={r[3]}, buff_l_workup={r[2]}, buff_l_defense={r[2]}, buff_l_attack={r[2]}
        },
        values = { health=0.25 },
        costs = { health=1, buff_l_antiacid=1, buff_l_workup=1, buff_l_defense=1, buff_l_attack=1 }
    },
    petals_rose = { --蔷薇花瓣
        prefab = "petals_rose", costmax = 45,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[2]}, buff_l_bath={r[2]}, buff_l_warm={r[2]} },
        values = { health=0.2 },
        costs = { health=1 }
    },
    petals_lily = { --蹄莲花瓣
        prefab = "petals_lily", costmax = 45,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[2]}, buff_l_bath={r[2]}, buff_l_cool={r[2]} },
        values = { health=-0.05, sanity=0.25 },
        costs = { health=1, sanity=1 }
    },
    petals_orchid = { --兰草花瓣
        prefab = "petals_orchid", costmax = 45,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[2]}, buff_l_bath={r[2]},
            buff_l_warm={r[1]}, buff_l_cool={r[1]}
        },
        values = { health=0.1, formula=0.1 },
        costs = { health=1, formula=1 }
    },
    petals_nightrose = { --夜玫瑰花瓣
        prefab = "petals_nightrose", costmax = 60,
        buffs = { buff_l_dizzy={-r[3]}, buff_l_bath={r[3]}, buff_l_warm={r[2]}, buff_l_cool={-r[2]} },
        values = { health=-0.2, sanity=-0.2 },
        costs = { health=1, sanity=1, buff_l_dizzy=1 }
    },
    mint_l = { --猫薄荷
        prefab = "mint_l", costmax = 40,
        buffs = { buff_l_dizzy={-r[3]}, buff_l_softskin={-r[1]}, buff_l_bath={r[1]},
            buff_l_warm={-r[2]}, buff_l_cool={r[2]}
        },
        values = { sanity=0.25 },
        costs = { sanity=1, buff_l_dizzy=1 }
    },
    forgetmelots = { --必忘我
        prefab = "forgetmelots", costmax = 20,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[1]}, buff_l_bath={r[1]} },
        values = { sanity=0.05 },
        costs = { sanity=1 }
    },
    cactus_flower = { --仙人掌花
        prefab = "cactus_flower", costmax = 90,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[2]}, buff_l_bath={r[2]}, buff_l_cool={r[2]} },
        values = { health=0.2, sanity=0.1 },
        costs = { health=1, sanity=1 }
    },
    petals = { --花瓣
        prefab = "petals", costmax = 20,
        buffs = { buff_l_softskin={-r[1]}, buff_l_bath={r[1]} },
        values = { health=0.05 },
        costs = { health=1 }
    },
    petals_evil = { --深色花瓣
        prefab = "petals_evil", costmax = 40,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_bath={-r[1]}, buff_l_warm={r[1]}, buff_l_cool={-r[1]} },
        values = { sanity=-0.3 },
        costs = { sanity=1, buff_l_dizzy=1 }
    },
    moon_tree_blossom = { --月树花
        prefab = "moon_tree_blossom", costmax = 40,
        buffs = { buff_l_dizzy={r[2]}, buff_l_softskin={-r[2]}, buff_l_bath={r[2]},
            buff_l_warm={-r[1]}, buff_l_cool={r[1]}
        },
        values = { health=0.05, sanity=0.15 },
        costs = { health=1, buff_l_dizzy=1 }
    },
    bathbomb = { --沐浴球
        prefab = "bathbomb", costmax = 200,
        buffs = { buff_l_softskin={-r[3]}, buff_l_bath={r[4]}, buff_l_warm={-r[2]}, buff_l_cool={r[2]} },
        values = { moisture=0.25 },
        costs = { buff_l_softskin=1, buff_l_bath=1 }
    },
    ghostflower = { --哀悼荣耀
        prefab = "ghostflower", costmax = 60,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[4]}, buff_l_bath={-r[4]},
            buff_l_warm={r[2]}, buff_l_cool={-r[2]}
        },
        values = { sanity=-0.3, temperature={-0.2,-5} },
        costs = { sanity=1, temperature=1, buff_l_dizzy=1, buff_l_softskin=1 }
    },
    squamousfruit = { --鳞果
        prefab = "squamousfruit", costmax = 220,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_softskin={-r[2]}, buff_l_warm={-r[1]}, buff_l_cool={-r[1]} },
        values = { health=-0.05, sanity=-0.05, moisture=-0.5 },
        costs = { health=1, sanity=1, moisture=1, buff_l_softskin=1 }
    },
    succulent_picked = { --多肉植物
        prefab = "succulent_picked", costmax = 20,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[2]}, buff_l_cool={r[1]},
            buff_l_sivbloodreduce={r[4]}
        },
        values = { health=0.05 },
        costs = { health=1, buff_l_softskin=1, buff_l_sivbloodreduce=1 }
    },
    firenettles = { --火荨麻叶
        prefab = "firenettles", costmax = 160,
        buffs = { buff_l_dizzy={-r[4]}, buff_l_softskin={r[4]}, buff_l_bath={-r[4]},
            buff_l_warm={r[3]}, buff_l_cool={-r[3]}, buff_l_fireproof={r[4]}
        },
        values = { health=-0.05, sanity=-0.05, temperature={0.2,2.5} },
        costs = { health=1, sanity=1, buff_l_warm=1, buff_l_fireproof=1 }
    },
    tillweed = { --犁地草
        prefab = "tillweed", costmax = 20,
        buffs = { buff_l_softskin={-r[1]}, buff_l_bath={r[1]}, buff_l_warm={r[1]}, buff_l_cool={r[1]} },
        values = { health=0.05, formula=0.1 },
        costs = { health=1, formula=1 }
    },
    tillweedsalve = { --犁地草膏
        prefab = "tillweedsalve", costmax = 132,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[1]}, buff_l_cool={r[1]} },
        values = { health=0.25, formula=0.2 },
        costs = { health=1, formula=1 }
    },
    ice = { --冰
        prefab = "ice", costmax = 20,
        buffs = { buff_l_softskin={r[1]}, buff_l_warm={-r[2]}, buff_l_cool={r[2]} },
        values = { moisture=0.2, temperature={-0.5,-5} },
        costs = { temperature=1, buff_l_cool=1 }
    },
    icehat = { --冰帽
        prefab = "icehat", costmax = 200,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={r[1]}, buff_l_warm={-r[3]}, buff_l_cool={r[3]} },
        values = { moisture=1, temperature={-1,-10} },
        costs = { temperature=1, buff_l_cool=1 }
    },
    spider_healer_item = { --治疗黏团
        prefab = "spider_healer_item", costmax = 200,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_workup={r[4]} },
        values = {  },
        costs = { buff_l_softskin=1, buff_l_workup=1, fn_monster=1 },
        fn_tick = function(pondcpt, soakercpt, costs, item)
            if soakercpt.inst:HasAnyTag("monster", "playermonster") then
                local cpt = soakercpt.inst.components.health
                if cpt:IsHurt() then
                    cpt:DoDelta(0.5*pondcpt.tick, true, "debug_key", true)
                    costs.fn_monster = (costs.fn_monster or 0) + pondcpt.tick
                end
            end
        end
    },
    wortox_reviver = { --双尾心
        prefab = "wortox_reviver", costmax = 200,
        buffs = { buff_l_dizzy={r[3]}, buff_l_softskin={-r[4]}, buff_l_bath={-r[4]},
            buff_l_warm={r[3]}, buff_l_cool={r[3]}
        },
        values = { health=1 },
        costs = { health=1, buff_l_softskin=1, buff_l_warm=1, buff_l_cool=1 }
    },
    treegrowthsolution = { --树果酱
        prefab = "treegrowthsolution", costmax = 100,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[1]} },
        values = { formula=0.5 },
        costs = { formula=1, buff_l_softskin=1 },
        fn_tick = function(pondcpt, soakercpt, costs, item)
            if soakercpt.inst:HasAnyTag("plantkin", "self_fertilizable") then
                local cpt = soakercpt.inst.components.health
                if cpt:IsHurt() then
                    cpt:DoDelta(0.25*pondcpt.tick, true, "debug_key", true)
                end
            end
        end
    },
    compostwrap = { --肥料包
        prefab = "compostwrap", costmax = 120,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[1]}, buff_l_bath={-r[2]},
            buff_l_warm={r[2]}, buff_l_cool={r[2]}, buff_l_antiacid={r[3]}
        },
        values = { formula=0.75 },
        costs = { formula=1, buff_l_softskin=1, buff_l_antiacid=1 },
        fn_tick = function(pondcpt, soakercpt, costs, item)
            local cpt
            if soakercpt.inst:HasAnyTag("plantkin", "self_fertilizable") then
                cpt = soakercpt.inst.components.health
                if cpt:IsHurt() then
                    cpt:DoDelta(0.35*pondcpt.tick, true, "debug_key", true)
                end
                return
            end
            cpt = soakercpt.inst.components.sanity
            if cpt ~= nil and cpt.current > 0 then
                cpt:DoDelta(-0.4*pondcpt.tick, true)
            end
        end
    },
    redgem = { --红宝石
        prefab = "redgem", costmax = 500,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[4]},
            buff_l_cool={-r[4]}, buff_l_radiantskin={r[2]}, buff_l_fireproof={r[2]}
        },
        values = { health=0.3, moisture=-0.25, temperature={0.5,10} },
        costs = { health=1, temperature=1, buff_l_warm=1, buff_l_radiantskin=1, buff_l_fireproof=1 }
    },
    amulet = { --重生护符
        prefab = "amulet", costmax = 1000,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[4]},
            buff_l_cool={-r[2]}, buff_l_radiantskin={r[2]}, buff_l_fireproof={r[2]}
        },
        values = { health=0.5, sanity=0.3, moisture=-0.25, temperature={0.5,15} },
        costs = { health=1, sanity=1, temperature=1, buff_l_warm=1, buff_l_radiantskin=1, buff_l_fireproof=1 }
    },
    bluegem = { --蓝宝石
        prefab = "bluegem", costmax = 500,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={-r[4]},
            buff_l_cool={r[4]}
        },
        values = { sanity=0.2, moisture=0.25, temperature={-0.5,-10} },
        costs = { sanity=1, temperature=1, buff_l_cool=1 }
    },
    blueamulet = { --寒冰护符
        prefab = "blueamulet", costmax = 1000,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={-r[2]},
            buff_l_cool={r[4]}
        },
        values = { sanity=0.6, moisture=0.25, temperature={-0.5,-15} },
        costs = { sanity=1, temperature=1, buff_l_cool=1 }
    },
    purplegem = { --紫宝石
        prefab = "purplegem", costmax = 800,
        buffs = { buff_l_dizzy={-r[3]}, buff_l_softskin={r[2]}, buff_l_bath={-r[3]}, buff_l_warm={r[2]},
            buff_l_cool={r[2]}, buff_l_radiantskin={r[1]}
        },
        values = { health=-0.25, sanity=-0.2 },
        costs = { health=1, sanity=1, buff_l_dizzy=1, buff_l_radiantskin=1 }
    },
    purpleamulet = { --梦魇护符
        prefab = "purpleamulet", costmax = 1500,
        buffs = { buff_l_dizzy={-r[4]}, buff_l_softskin={r[3]}, buff_l_bath={-r[4]}, buff_l_warm={r[3]},
            buff_l_cool={r[3]}, buff_l_radiantskin={r[1]}
        },
        values = { health=-0.35, sanity=-0.3 },
        costs = { health=1, sanity=1, buff_l_dizzy=1, buff_l_radiantskin=1 }
    },
    yellowgem = { --黄宝石
        prefab = "yellowgem", costmax = 800,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[2]},
            buff_l_radiantskin={r[4]}
        },
        values = { sanity=0.2, moisture=-0.25, temperature={0.2,7.5} },
        costs = { sanity=1, temperature=1, buff_l_dizzy=1, buff_l_radiantskin=1 }
    },
    yellowamulet = { --魔光护符
        prefab = "yellowamulet", costmax = 1500,
        buffs = { buff_l_dizzy={-r[3]}, buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[2]},
            buff_l_radiantskin={r[4]}
        },
        values = { sanity=0.6, moisture=-0.25, temperature={0.2,12.5} },
        costs = { sanity=1, temperature=1, buff_l_dizzy=1, buff_l_radiantskin=1 }
    },
    refined_dust = { --尘土块
        prefab = "refined_dust", costmax = 200,
        buffs = { buff_l_cool={r[3]}, buff_l_antiacid={r[4]}, buff_l_workup={r[3]}, buff_l_defense={r[3]},
            buff_l_attack={r[3]}
        },
        values = { health=0.25, formula=0.2, temperature={-0.2,-2.5} },
        costs = { health=1, formula=1, buff_l_antiacid=1, buff_l_workup=1, buff_l_defense=1, buff_l_attack=1 }
    },
    nightmarefuel = { --噩梦燃料
        prefab = "nightmarefuel", costmax = 50,
        buffs = { buff_l_dizzy={-r[1]}, buff_l_bath={-r[2]}, buff_l_warm={r[2]}, buff_l_cool={-r[2]} },
        values = { sanity=-0.35 },
        costs = { sanity=1, buff_l_dizzy=1 }
    },
    horrorfuel = { --纯粹恐惧
        prefab = "horrorfuel", costmax = 150,
        buffs = { buff_l_dizzy={-r[3]}, buff_l_softskin={r[3]}, buff_l_bath={-r[3]}, buff_l_warm={r[3]},
            buff_l_cool={-r[3]}
        },
        values = { sanity=-0.5 },
        costs = { sanity=1, buff_l_dizzy=1 }
    },
    glommerfuel = { --格罗姆的黏液
        prefab = "glommerfuel", costmax = 530,
        buffs = { buff_l_dizzy={-r[2]}, buff_l_softskin={-r[3]}, buff_l_warm={r[2]} },
        values = { health=0.25, sanity=-0.2, formula=0.2 },
        costs = { health=1, sanity=1, formula=1, buff_l_dizzy=1, buff_l_softskin=1 }
    },
    phlegm = { --脓鼻涕
        prefab = "phlegm", costmax = 75,
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={-r[1]},  },
        values = { sanity=-0.2, moisture=0.1 },
        costs = { sanity=1, buff_l_softskin=1 }
    },
    siving_rocks = { --子圭石
        prefab = "siving_rocks", costmax = 200,
        buffs = { buff_l_softskin={-r[2]}, buff_l_sivbloodreduce={r[1]} },
        values = { health=0.05 },
        costs = { health=1, buff_l_softskin=1, buff_l_sivbloodreduce=1 }
    },
    siving_derivant_item = { --子圭奇型岩
        prefab = "siving_derivant_item",
        buffs = { buff_l_softskin={-r[2]}, buff_l_sivbloodreduce={r[3]} },
        values = { health=0.05 }
    },
    wormlight_lesser = { --小发光浆果
        prefab = "wormlight_lesser", costmax = 160,
        buffs = { buff_l_softskin={-r[1]}, buff_l_radiantskin={r[4]} },
        values = { health=0.05, sanity=-0.1 },
        costs = { health=1, sanity=1, buff_l_radiantskin=1 }
    },
    wormlight = { --发光浆果
        prefab = "wormlight", costmax = 320,
        buffs = { buff_l_softskin={-r[1]}, buff_l_radiantskin={r[4]} },
        values = { health=0.05, sanity=-0.1 },
        costs = { health=1, sanity=1, buff_l_radiantskin=1 }
    },
    lavae_egg = { --岩浆虫卵
        prefab = "lavae_egg", costmax = 1500,
        buffs = { buff_l_warm={r[3]}, buff_l_cool={-r[3]}, buff_l_fireproof={r[4]} },
        values = { temperature={0.2,7.5} },
        costs = { temperature=1, buff_l_warm=1, buff_l_fireproof=1 }
    },
    lavae_egg_cracked = { --岩浆虫卵(孵化中)
        prefab = "lavae_egg_cracked", costmax = 1500,
        buffs = { buff_l_warm={r[3]}, buff_l_cool={-r[3]}, buff_l_fireproof={r[4]} },
        values = { temperature={0.2,7.5} },
        costs = { temperature=1, buff_l_warm=1, buff_l_fireproof=1 }
    },
    hermit_pearl = { --珍珠的珍珠
        prefab = "hermit_pearl",
        buffs = { buff_l_softskin={-r[2]}, buff_l_bath={r[1]}, buff_l_warm={r[1]}, buff_l_cool={r[1]},
            buff_l_radiantskin={r[2]}
        },
        values = { sanity=0.2, moisture=-1.25 }
    },
    hermit_cracked_pearl = { --珍珠的珍珠(碎)
        prefab = "hermit_cracked_pearl",
        buffs = { buff_l_dizzy={-r[1]}, buff_l_softskin={-r[2]}, buff_l_bath={r[2]}, buff_l_warm={r[2]},
            buff_l_cool={r[2]}, buff_l_radiantskin={r[1]}
        },
        values = { sanity=-0.5, moisture=-1.25 }
    },
    moonrockseed = { --天体宝球
        prefab = "moonrockseed",
        buffs = { buff_l_dizzy={r[4]}, buff_l_bath={r[2]}, buff_l_warm={-r[3]}, buff_l_cool={r[3]},
            buff_l_radiantskin={r[2]}
        },
        values = { sanity=0.2, formula=0.1 }
    },
}

fns.UpdateBuffNet = function() --联合 fns.buffinfos 与 fns.buffs 的数据
    local dd
    for idx, info in ipairs(fns.buffinfos) do
        dd = fns.buffs[info.name]
        if dd ~= nil then
            dd.idx = idx
            info.cycle = dd.cycle
            info.time = dd.time
        end
    end
end
fns.UpdateBuffNet()

fns.GetBuffTick = function(buffkey, can)
    local dd = fns.buffs[buffkey]
    if dd ~= nil then
        return { time = dd.time, cycle = dd.cycle, can = can, noforce = dd.noforce, idx = dd.idx, isbad = dd.isbad }
    end
end
fns.fn_value_hot = function(cpt) --设置温泉基础数值
    --设置基础数值(以1秒为周期)
    cpt.tick_health = 2 --回血回san，但不消耗饱食度。已经比帐篷强了
    cpt.tick_sanity = 1
    cpt.tick_temperature = { 2, 50, 60 } --野生温泉，温度偏高
    cpt.tick_moisture = 2.5
    cpt.tick_formula = 2 --为了160秒加到320点催长剂，每秒需要加2点
    cpt.tick_buffs = {
        buff_l_bath = fns.GetBuffTick("buff_l_bath", true),
        buff_l_softskin = fns.GetBuffTick("buff_l_softskin", true),
        buff_l_dizzy = fns.GetBuffTick("buff_l_dizzy", true)
    }
end

fns.fn_tick = function(cpt, doercpt, costs)
    ------记录玩家的总浸泡时间
    local times = doercpt.times
    local time = (times["count"] or 0) + cpt.tick
    local timenow = time
    times["count"] = time
    ------提示玩家。之后改成给池塘加了“闹闹壳”后才会提示 undo
    if doercpt.inst:HasTag("mime") then return end --哑巴就不需要后面的逻辑
    local key
    local talks = doercpt.talks
    if not talks["dizzy3"] then
        time = times["buff_l_dizzy"]
        if time ~= nil then
            local vv = cpt.tick_buffs["buff_l_dizzy"].cycle
            if doercpt.inst:HasDebuff("buff_l_dizzy") then --泡太久啦，已经晕了
                if timenow >= vv*0.375 then --(15秒)太频繁了，限制一下
                    key = "DIZZY3"
                end
                talks["dizzy3"] = true
            elseif time >= vv*0.7 then --(28秒)
                if not talks["dizzy1"] then --提醒别泡太久
                    key = "DIZZY1"
                    talks["dizzy1"] = true
                elseif not talks["dizzy2"] and time >= vv*0.875 then --(35秒)最后提醒别泡太久
                    key = "DIZZY2"
                    talks["dizzy2"] = true
                end
            end
        end
    elseif math.random() < 0.05 then --已经晕了。随机说一些觉得太晕的话
        key = "DIZZY3"
    end
    if key == nil and math.random() < 0.05 then --随机说一些觉得舒服的话
        if math.random() < 0.5 and cpt.tick_temperature[1] ~= 0 then
            key = cpt.tick_temperature[1] > 0 and "WARM" or "COOL"
        else
            key = "COSY"
        end
    end
    if key ~= nil then
        doercpt:SayIt(key)
    end
end

--以下内容待删除，已经不用了！
pas.nummax1 = 160
fns.SetAnim = function(fx, bank, build, anim, pushanim, isloop)
    fx.AnimState:SetBank(bank)
    fx.AnimState:SetBuild(build or bank)
    if pushanim ~= nil then
        fx.AnimState:PlayAnimation(anim)
        fx.AnimState:PushAnimation(pushanim, isloop)
    else
        fx.AnimState:PlayAnimation(anim or "idle", isloop)
    end
end
fns.decos = {
    royal_jelly = { --蜂王浆。生命+122、精神+15。[温暖+022、柔软肌肤-244]
        float = { -0.1, "small", nil, 0.8 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "royal_jelly", nil, nil, nil, nil) --颜色怎么调都不满意，还是用本体动画吧
        end
    },
    honey = { --蜂蜜。生命+3。[温暖+001、柔软肌肤-010]
        float = { -5 },
        fn_anim = function(cpt, fx)
            fx._animidx = "trail"..tostring(math.random(7))
            fns.SetAnim(fx, "honey_trail", nil, fx._animidx.."_pre", fx._animidx, nil)
            fx.AnimState:SetScale(0.4, 0.4)
        end,
        fn_remove = function(cpt, fx)
            fx.AnimState:PlayAnimation((fx._animidx or "trail1").."_pst")
            fx:ListenForEvent("animover", fx.Remove)
        end
    },
    bandage = { --蜂蜜药膏。生命+30。[温暖+001、柔软肌肤-011]
        float = { -0.03, "small", 0.1, 0.95 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "bandage", nil, nil, nil, nil)
        end
    },
    spidergland = { --蜘蛛腺。生命+8。[凉爽+001、柔软肌肤-010、抗酸+020]
        prefab = "spidergland", nummax = pas.nummax1, costmax = 80, --8/0.2*2=80
        buffs = { cool = {0,0,0.2}, softskin = {0,-0.1,0} },
        values = { health = 0.2 }, costs = { health = 1 },
        fxnum = 1, fxnum_big = 1, float = { -0.05, "small", nil, nil },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "spider_gland", nil, nil, nil, nil)
        end
    },
    healingsalve = { --治疗药膏。生命+20。[凉爽+001、柔软肌肤-011、抗酸+144]
        prefab = "healingsalve", nummax = pas.nummax1, costmax = 100, --20/0.4*2=100
        buffs = { cool = {0,0,0.2}, softskin = {0,-0.1,0}, antiacid = {0.1,0,0.25} },
        values = { health = 0.4 }, costs = { health = 1 },
        fxnum = 1, fxnum_big = 1, float = { -0.05, "small", 0.05, 0.95 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "spider_gland_salve", nil, nil, nil, nil)
        end
    },
    healingsalve_acid = { --黏糊糊的药膏。生命+20。[凉爽+013、柔软肌肤-031、抗酸buff]
        prefab = "healingsalve_acid", nummax = pas.nummax1, costmax = 150, --20/0.4*2+50=150
        buffs = { cool = {0,0.1,0.4}, softskin = {0,-0.1,-0.2}, antiacid = {0,0,0,true} },
        values = { health = 0.4 }, costs = { health = 1, antiacid = 50 },
        fxnum = 1, fxnum_big = 1, float = { -0.05, "small", 0.05, 0.95 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "healingsalve_acid", nil, nil, nil, nil)
        end
    },
    slurtleslime = { --蛞蝓龟黏液。精神-5。[柔软肌肤-020、抗酸+103]
        prefab = "slurtleslime", nummax = pas.nummax1, costmax = 80, --8/0.2*2=80
        buffs = { cool = {0,0,0.2}, softskin = {0,-0.1,-0.2} },
        values = { health = 0.2 }, costs = { health = 1 },
        fxnum = 1, fxnum_big = 2, float = { -5 },
        fn_anim = function(cpt, fx)
            fx._animidx = "trail"..tostring(math.random(7))
            fns.SetAnim(fx, "honey_trail", nil, fx._animidx.."_pre", fx._animidx, nil)
            fx.AnimState:SetScale(0.4, 0.4)
            fx.AnimState:SetAddColour(208/255, 99/255, 22/255, 0)
        end,
        fn_remove = function(cpt, fx)
            fx.AnimState:PlayAnimation((fx._animidx or "trail1").."_pst")
            fx:ListenForEvent("animover", fx.Remove)
        end
    },
    nitre = { --硝石。精神-10、温度-20。[凉爽+012、抗酸+033、香料buff+022]
    },
    pepper = { --辣椒。生命-20、精神-15。[温暖+303、柔软肌肤+204、晕乎乎-204]
        prefab = "pepper", nummax = pas.nummax1, costmax = 156, --(20+15)/(0.25+0.2)*2~=156
        buffs = { warm = {0.05,0,0.4}, softskin = {0.1,0,0.1}, dizzy = {-0.05,0,0} },
        values = { health = -0.25, sanity = -0.2 }, costs = { health = 1, sanity = 1 },
        fxnum = 1, fxnum_big = 1, float = { -0.05, "small", 0.1, 0.75 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "pepper", nil, nil, nil, nil)
        end
    },
    garlic = { --大蒜。精神-10。[温暖+202、晕乎乎-103]
        prefab = "garlic", nummax = pas.nummax1, costmax = 100, --10/0.2*2=100
        buffs = { warm = {0.05,0,0.2}, dizzy = {-0.05,0,0} },
        values = { sanity = -0.2 }, costs = { sanity = 1 },
        fxnum = 1, fxnum_big = 1, float = { -0.05, "small", 0.05, 0.775 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "garlic", nil, nil, nil, nil)
        end
    },
    onion = { --洋葱。精神-10。[温暖+202、晕乎乎-103]
        prefab = "onion", nummax = pas.nummax1, costmax = 100, --10/0.2*2=100
        buffs = { warm = {0.05,0,0.2}, dizzy = {-0.05,0,0} },
        values = { sanity = -0.2 }, costs = { sanity = 1 },
        fxnum = 1, fxnum_big = 1, float = { -0.05, "large", 0.15, {0.45,0.6,0.45} },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "onion", nil, nil, nil, nil)
        end
    },
    spice_sugar = { --蜂蜜水晶。[高效工作buff]
        prefab = "spice_sugar", nummax = pas.nummax1, costmax = 2,
        buffs = { workup = {0,0,0,true} },
        costs = { workup = 1 },
        fxnum = 1, fxnum_big = 1, float = { 0.07, "med", 0.25, 0.65 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "spices", nil, nil, nil, nil)
            fx.AnimState:OverrideSymbol("swap_spice", "spices", "spice_sugar")
        end
    },
    spice_garlic = { --蒜粉。[健康抵抗力buff]
        prefab = "spice_garlic", nummax = pas.nummax1, costmax = 2,
        buffs = { defense = {0,0,0,true} },
        costs = { defense = 1 },
        fxnum = 1, fxnum_big = 1, float = { 0.07, "med", 0.25, 0.65 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "spices", nil, nil, nil, nil)
            fx.AnimState:OverrideSymbol("swap_spice", "spices", "spice_garlic")
        end
    },
    spice_chili = { --辣椒面。[有劲buff]
        prefab = "spice_chili", nummax = pas.nummax1, costmax = 2,
        buffs = { attack = {0,0,0,true} },
        costs = { attack = 1 },
        fxnum = 1, fxnum_big = 1, float = { 0.07, "med", 0.25, 0.65 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "spices", nil, nil, nil, nil)
            fx.AnimState:OverrideSymbol("swap_spice", "spices", "spice_chili")
        end
    },
    spice_salt = { --调味盐。生命+20。[强化其他香料buff]
        prefab = "spice_salt", nummax = pas.nummax1, costmax = 80, --20/0.5*2=80
        buffs = { workup = {0.25,0,0.75}, defense = {0.25,0,0.75}, attack = {0.25,0,0.75} }, --40/1.25=32秒即可达到8*1.75分钟
        values = { health = 0.5 }, costs = { health = 1 },
        fxnum = 1, fxnum_big = 1, float = { 0.07, "med", 0.25, 0.65 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "spices", nil, nil, nil, nil)
            fx.AnimState:OverrideSymbol("swap_spice", "spices", "spice_salt")
        end
    },
    saltrock = { --盐晶。生命+10。[强化其他香料buff]
        prefab = "saltrock", nummax = pas.nummax1, costmax = 80, --10/0.25*2=80
        buffs = { workup = {0.1,0,0.25}, defense = {0.1,0,0.25}, attack = {0.1,0,0.25} }, --40/1.1=36.36秒即可达到8*1.25分钟
        values = { health = 0.25 }, costs = { health = 1 },
        fxnum = 1, fxnum_big = 1, float = { 0.0, "small", 0.2, 1.05 },
        fn_anim = function(cpt, fx)
            fns.SetAnim(fx, "salt", nil, nil, nil, nil)
        end
    },
}

-- local ZIP_L = require("zip_soak_legion")
return fns
