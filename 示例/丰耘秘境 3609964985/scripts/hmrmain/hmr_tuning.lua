local total_day_time = TUNING.TOTAL_DAY_TIME
local seg_time = TUNING.SEG_TIME


-- 椰树守卫
TUNING.PALMTREEGUARD_MELEE = 5                              -- 设置椰子树守卫的近战伤害
TUNING.PALMTREEGUARD_HEALTH = 750                           -- 设置椰子树守卫的生命值
TUNING.PALMTREEGUARD_DAMAGE = 150                           -- 设置椰子树守卫的攻击伤害
TUNING.PALMTREEGUARD_ATTACK_PERIOD = 3                      -- 设置椰子树守卫的攻击周期（秒）
TUNING.PALMTREEGUARD_FLAMMABILITY = .333                    -- 设置椰子树守卫的易燃性系数
TUNING.PALMTREEGUARD_MIN_DAY = 3                            -- 设置椰子树守卫生成的最小天数
TUNING.PALMTREEGUARD_PERCENT_CHANCE = 1/75                  -- 设置椰子树守卫生成的概率
TUNING.PALMTREEGUARD_MAXSPAWNDIST = 30                      -- 设置椰子树守卫生成的最大距离
TUNING.PALMTREEGUARD_PINECONE_CHILL_CHANCE_CLOSE = 1        -- 设置近距离落松果的冷却概率
TUNING.PALMTREEGUARD_PINECONE_CHILL_CHANCE_FAR = 1          -- 设置远距离落松果的冷却概率
TUNING.PALMTREEGUARD_PINECONE_CHILL_CLOSE_RADIUS = 5        -- 设置近距离冷却落松果的半径
TUNING.PALMTREEGUARD_PINECONE_CHILL_RADIUS = 16             -- 设置冷却落松果的最大半径
TUNING.PALMTREEGUARD_REAWAKEN_RADIUS = 20                   -- 设置椰子树守卫重新唤醒的半径
TUNING.PALMTREEGUARD_BURN_TIME = 10                         -- 设置椰子树守卫燃烧的时间（秒）
TUNING.PALMTREEGUARD_BURN_DAMAGE_PERCENT = 1/8              -- 设置椰子树守卫燃烧造成的伤害百分比

TUNING.HMR_COCONUT_WORKNUM = 3                              -- 设置椰子的每次工作数量

-- 辉煌护甲数值
TUNING.HMR_HONOR_ARMOR_MAXCONDITION = 800                   -- 辉煌护甲最大耐久度
TUNING.HMR_HONOR_ARMOR_NORMAL_ABSORPTION_PRECENT = 0.85     -- 辉煌护甲普通护甲吸收百分比
TUNING.HMR_HONOR_ARMOR_SKILLED_ABSORPTION_PERCENT = 0.98    -- 辉煌护甲开启技能护甲吸收百分比
TUNING.HMR_HONOR_ARMOR_PLANAR_DEFENSE = 10                  -- 辉煌护甲位面防御力
TUNING.HMR_HONOR_ARMOR_HUNGER_RATE_SLOWDOWN = 0.8           -- 辉煌护甲饥饿减速系数
TUNING.HMR_HONOR_ARMOR_HUNGER_RATE_SKILLED = 2.0            -- 辉煌护甲开启技能饥饿下降速度（2.0/s）
TUNING.HMR_HONOR_ARMOR_HEALTH_REGEN_RATE = 0.2              -- 辉煌护甲生命恢复速度(0.2/s)
TUNING.HMR_HONOR_ARMOR_SKILLED_CONDITION_LOSS_NULT = 2      -- 辉煌护甲开启技能耐久度损失倍率
TUNING.HMR_HONOR_ARMOR_WALKSPEED_MULT = 0.8                 -- 辉煌护甲行走速度

-- 辉煌法帽数值
TUNING.HMR_HONOR_HAT_MAXCONDITION = 600                     -- 辉煌法帽最大耐久度
TUNING.HMR_HONOR_HAT_NORMAL_ABSORPTION_PERCENT = 0.6        -- 辉煌法帽普通护甲吸收百分比
TUNING.HMR_HONOR_HAT_WATERPROOFNESS = 1                     -- 辉煌法帽防水能力
TUNING.HMR_HONOR_HAT_LUNAR_RESIST = 0.97                    -- 辉煌法帽月亮阵营防御能力（抵御5%）
TUNING.HMR_HONOR_HAT_SHADOW_RESIST = 0.93                   -- 辉煌法帽暗影阵营防御能力（抵御5%）
TUNING.HMR_HONOR_HAT_NEG_AURA_ABSORB = 0.3                  -- 辉煌法帽负面精神光环转换能力
TUNING.HMR_HONOR_HAT_LIGHTUP_SANITY_PERCENT = 0.95          -- 辉煌法帽发光所需精神值百分比
TUNING.HMR_HONOR_HAT_SETBONUS_REPAIR_RATE = 0.5             -- 辉煌法帽套装激活耐久度修理速度（每秒）
TUNING.HMR_HONOR_HAT_SETBONUS_SANITY_RATE = 0.25            -- 辉煌法帽套装激活穿戴者精神值恢复速度（每秒）

-- 辉煌工具数值
TUNING.HMR_HONOR_MULTITOOL_MAXUSES = 800                    -- 辉煌工具最大使用次数
TUNING.HMR_HONOR_MULTITOOL_CHOP_CONSUMPTION = 1             -- 辉煌工具斧子消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_MINE_CONSUMPTION = 2             -- 辉煌工具镐子消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_DIG_CONSUMPTION = 3              -- 辉煌工具铲子消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_HAMMER_CONSUMPTION = 1           -- 辉煌工具锤子消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_TILL1_CONSUMPTION = 1            -- 辉煌工具耕地1格消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_TILL9_CONSUMPTION = 14           -- 辉煌工具耕地9格消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_TILL10_CONSUMPTION = 18          -- 辉煌工具耕地10格消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_TILL16_CONSUMPTION = 28          -- 辉煌工具耕地16格消耗耐久度
TUNING.HMR_HONOR_MULTITOOL_EFFECTIVENESS = 1.2              -- 辉煌工具效率
TUNING.HMR_HONOR_MULTITOOL_DAMAGE = 21                      -- 辉煌工具攻击伤害

-- 辉煌法杖数值
TUNING.HMR_HONOR_STAFF_BASE_DAMAGE = 15                     -- 辉煌法杖基础伤害
TUNING.HMR_HONOR_STAFF_SETBONUS_DAMAGE_MULTIPLIER = 2       -- 辉煌法杖套装激活伤害
TUNING.HMR_HONOR_STAFF_PLANAR_DAMAGE= 5                     -- 辉煌法杖位面伤害
TUNING.HMR_HONOR_STAFF_PROJECTILE_SPEED = 20                -- 辉煌法杖法球基础速度
TUNING.HMR_HONOR_RICE_PRIME_PROJ_DAMAGE_MULTIPLIER = 2      -- 水稻精华法球伤害倍率
TUNING.HMR_HONOR_WHEAT_PRIME_PROJ_DAMAGE_MULTIPLIER = 0.4   -- 小麦精华法球伤害倍率
TUNING.HMR_HONOR_WHEAT_PRIME_PROJ_ADDCOLDNESS = 3           -- 小麦精华法球增加寒冷度
TUNING.HMR_HONOR_TEA_PRIME_PROJ_DAMAGE_MULTIPLIER = 0.1     -- 茶丛精华法球伤害倍率
TUNING.HMR_HONOR_TEA_PRIME_PROJ_ADDSTUNDEGREE = 3           -- 茶丛精华法球增加定身度
TUNING.HMR_HONOR_COCONUT_DROP_DAMAGE = 10                   -- 椰子掉落伤害

-- 辉煌背包数值
TUNING.HMR_HONOR_BACKPACK_COOLING_RATE = 4                  -- 辉煌背包冷却速度
TUNING.HMR_HONOR_BACKPACK_HEATING_RATE = 2                  -- 辉煌背包加热速度
TUNING.HMR_HONOR_BACKPACK_PERISHABLE_MULTIPLIER = 0.2       -- 辉煌背包冰格腐烂倍率
TUNING.HMR_HONOR_BACKPACK_GIFTWAITTIME = seg_time * 6       -- 辉煌背包礼物刷新等待时间
TUNING.HMR_HONOR_BACKPACK_REPAIRSPEED = {                   -- 辉煌背包修理速度
    PERISHABLE =    -2,
    ARMOR =         5,
    FINITEUSES =    2,
    FUELED =        2.5,
}
TUNING.HMR_HONOR_BACKPACK_REPAIRPERCENT = {
    -- PERISHABLE =    0.01,
    ARMOR =         0.005,
    FINITEUSES =    0.002,
    FUELED =        0.01,
}

-- 辉煌吹箭
TUNING.HMR_HONOR_BLOWDART_FIRE_MAXUSES = 3                  -- 辉煌炽烈吹箭最大使用次数
TUNING.HMR_HONOR_BLOWDART_FIRE_DAMAGE = 10                  -- 辉煌炽烈吹箭伤害
TUNING.HMR_HONOR_BLOWDART_FIRE_SPEED = 30                   -- 辉煌炽烈吹箭速度
TUNING.HMR_HONOR_BLOWDART_ICE_MAXUSES = 3                   -- 辉煌寒冰吹箭最大使用次数
TUNING.HMR_HONOR_BLOWDART_ICE_DAMAGE = 1                    -- 辉煌寒冰吹箭伤害
TUNING.HMR_HONOR_BLOWDART_ICE_SPEED = 20                    -- 辉煌寒冰吹箭速度
TUNING.HMR_HONOR_BLOWDART_CURE_MAXUSES = 3                  -- 辉煌治愈吹箭最大使用次数
TUNING.HMR_HONOR_BLOWDART_CURE_DAMAGE = 100                 -- 辉煌治愈吹箭伤害
TUNING.HMR_HONOR_BLOWDART_CURE_SPEED = 15                   -- 辉煌治愈吹箭速度
TUNING.HMR_HONOR_BLOWDART_CURE_RESPAWNPLAYER_TIMES = 10     -- 辉煌治愈吹箭复活玩家所需次数
TUNING.HMR_HONOR_BLOWDART_CURE_PLAYER_MULT = 0.1            -- 辉煌治愈吹箭治愈倍数（×伤害）

-- 凶险潜胄
TUNING.HMR_TERROR_ARMOR_MAXCONDITION = 1000                 -- 凶险潜胄最大耐久度
TUNING.HMR_TERROR_ARMOR_NORMAL_ABSORPTION_PERCENT = 0.60    -- 凶险潜胄普通护甲吸收百分比
TUNING.HMR_TERROR_ARMOR_PLANAR_DEFENSE = 10                 -- 凶险潜胄位面防御力
TUNING.HMR_TERROR_ARMOR_SKILLED_ABSORPTION_PRECENT = 0.95   -- 凶险潜胄开启技能护甲吸收百分比
TUNING.HMR_TERROR_ARMOR_MINHEALTH = 0.1                     -- 凶险潜胄最小生命值百分比

-- 凶险笼罩
TUNING.HMR_TERROR_HAT_MAXCONDITION = 800                    -- 凶险笼罩最大耐久度
TUNING.HMR_TERROR_HAT_ABSORPTION_PERCENT = 0.30             -- 凶险笼罩普通护甲吸收百分比
TUNING.HMR_TERROR_HAT_DAMAGE_MULT = 2                       -- 凶险笼罩伤害倍率
TUNING.HMR_TERROR_HAT_DAMAGETAKE_MULT = 4                   -- 凶险笼罩被伤害倍率
TUNING.HMR_TERROR_HAT_WATERPROOFNESS = 1                    -- 凶险笼罩防水能力
TUNING.HMR_TERROR_HAT_LUNAR_RESIST = 0.93                   -- 凶险笼罩月亮阵营防御能力（抵御5%）
TUNING.HMR_TERROR_HAT_SHADOW_RESIST = 0.97                  -- 凶险笼罩暗影阵营防御能力（抵御5%）

-- 凶险手杖
TUNING.HMR_TERROR_STAFF_BASE_DAMAGE = 20                    -- 凶险手杖基础伤害
TUNING.HMR_TERROR_STAFF_PLANAR_DAMAGE = 5                   -- 凶险手杖位面伤害
TUNING.HMR_TERROR_STAFF_MAXUSES = 400                       -- 凶险手杖最大使用次数

-- 凶险荆棘
TUNING.HMR_TERROR_SWORD_MAXUSES = 400                       -- 凶险荆棘剑最大使用次数
TUNING.HMR_TERROR_SWORD_DAMAGE = 60                         -- 凶险荆棘剑伤害
TUNING.HMR_TERROR_SWORD_PLANARDAMAGE = 15                   -- 凶险荆棘剑位面伤害
TUNING.HMR_TERROR_SWORD_VINE_HEALTH_CONSUME = 20            -- 凶险荆棘剑生成藤蔓扣除的穿戴者生命值

-- 凶险藤蔓
TUNING.HMR_TERROR_VINE_HEALTH = 100                         -- 凶险藤蔓生命值
TUNING.HMR_TERROR_VINE_DAMAGE = 60                          -- 凶险藤蔓伤害
TUNING.HMR_TERROR_VINE_PLANARDAMAGE = 5                     -- 凶险藤蔓位面伤害

-- 凶险炸弹
TUNING.HMR_TERROR_BOMB_EXPLOSION_RANGE = 3                  -- 凶险炸弹爆炸范围
TUNING.HMR_TERROR_BOMB_EXPLOSION_DAMAGE = 10                -- 凶险炸弹爆炸伤害

-- 凶险虞子花
TUNING.HMR_TERROR_FLOWER_HEALTH = 500                       -- 凶险虞子花最大生命值

-- 柠檬炸弹
TUNING.TERROR_LEMON_BOMB_EXPLOSION_RANGE = 3                -- 柠檬炸弹爆炸范围
TUNING.TERROR_LEMON_BOMB_EXPLOSION_DAMAGE = 100             -- 柠檬炸弹爆炸伤害

-- 箱子
TUNING.HMR_CHEST_STORE_ARRAY_DIST = 5                       -- 青衢纳宝箱组成阵列的最大半径范围
TUNING.HMR_CHEST_STORE_BREAKPACK_TIMING = total_day_time * 2-- 青衢纳宝箱解散存储包破损时间
TUNING.HMR_CHEST_STORE_DEGRADEPACK_TIMING = total_day_time  -- 青衢纳宝箱降级存储包破损时间

TUNING.HMR_CHEST_TRANSMIT_SEARCH_DIST = 10                  -- 云梭递运箱搜索范围
TUNING.HMR_CHEST_TRANSMIT_SPEED = 100                       -- 云梭递运箱传送速度
TUNING.HMR_CHEST_TRANSMIT_CONSUME_MULT = .2                 -- 云梭递运箱三维消耗倍率

TUNING.HMR_CHEST_RECYCLE_SPAWN_DIST = 10                    -- 龙龛探秘箱垃圾堆生成范围
TUNING.HMR_CHEST_RECYCLE_ITEM_TIME = total_day_time * 1     -- 龙龛探秘箱垃圾堆生成周期
TUNING.HMR_CHEST_RECYCLE_SPAWN_DENSITY = 4                  -- 龙龛探秘箱垃圾堆生成密度

TUNING.HMR_CHEST_FACTORY_RELATE_DIST = 25                   -- 灵枢织造箱与织造核心联系范围
TUNING.HMR_CHEST_FACTORY_ROOM_WATCH_INTERVAL = seg_time     -- 灵枢织造箱更新间隔
TUNING.HMR_CHEST_FACTORY_MIN_ROOM_SIZE = 10                 -- 灵枢织造箱最小房间大小
TUNING.HMR_CHEST_FACTORY_MAX_ROOM_SIZE = 400                -- 灵枢织造箱最大房间大小
TUNING.HMR_CHEST_FACTORY_PRODUCE_MULT = 0.0001              -- 灵枢织造箱产出倍率
TUNING.HMR_CHEST_FACTORY_CORE_MAX_CAPACITY = 80             -- 灵枢织造箱核心最大容纳量
TUNING.HMR_CHEST_FACTORY_CORE_EXTRA_PRODUCT_CHANCE = 0.2    -- 灵枢织造箱核心对于绑定的箱子的额外产出几率

TUNING.HMR_CHEST_DISPLAY_SANITYAURA_DIST = 10               -- 华樽耀勋箱精神光环范围

-- 樱绒草
TUNING.HMR_CHERRY_GRASS_PICK_RENGE = total_day_time * 5
TUNING.HMR_CHERRY_GRASS_MAX_CYCLES = 5
TUNING.HMR_CHERRY_GRASS_DIGS = 1

-- 粉晶石
TUNING.HMR_CHERRY_ROCK_SHORT_GROW_TIME = total_day_time * 7
TUNING.HMR_CHERRY_ROCK_MED_GROW_TIME = total_day_time * 6
TUNING.HMR_CHERRY_ROCK_TALL_GROW_TIME = total_day_time * 5
TUNING.HMR_CHERRY_ROCK_SHORT_MINES = 5
TUNING.HMR_CHERRY_ROCK_MED_MINES = 7
TUNING.HMR_CHERRY_ROCK_TALL_MINES = 10

-- 樱花树
TUNING.HMR_CHERRY_TREE_REGROWTH = {
    OFFSPRING_TIME = total_day_time * 5,
    DESOLATION_RESPAWN_TIME = total_day_time * 50,
    DEAD_DECAY_TIME = total_day_time * 30,
}
TUNING.HMR_CHERRY_TREE_S1_DIGS = 1
TUNING.HMR_CHERRY_TREE_S2_CHOPS = 11
TUNING.HMR_CHERRY_TREE_S3_CHOPS = 20
TUNING.HMR_CHERRY_TREE_S4_CHOPS = 20
TUNING.HMR_CHERRY_TREE_STUMP_DIGS = 1
TUNING.HMR_CHERRY_TREE_BURNT_CHOPS = 1
TUNING.HMR_CHERRYY_TREE_S3_PICK_RENGE = 0                   -- 樱花树3阶段采摘间隔
TUNING.HMR_CHERRYY_TREE_S4_PICK_RENGE = total_day_time * 3  -- 樱花树4阶段采摘间隔


-- 凶险事件
TUNING.HMR_TERROREVENT_COOLDOWN_PERIOD = 120                -- 凶险事件冷却时间（秒）
TUNING.HMR_TERROREVENT_GAMESTART_BUFFER_TIME = 10           -- 凶险事件开局缓冲（秒）（设置过低会导致任务丢失）
TUNING.HMR_HONORBEEGHOST_HEALTH_DELTA = 10                  -- 辉煌蜂魂魄蜂生命值恢复量
TUNING.HMR_HONORBEEGHOST_STUN_TIME = 10                     -- 辉煌蜂魂魄蜂定身时间（秒）

-- 辉煌蜂
TUNING.HONORBEE_HEALTH = 200
TUNING.HONORBEE_DAMAGE = 4
TUNING.HONORBEE_ATTACK_RANGE = .6
TUNING.HONORBEE_ATTACK_PERIOD = 2
TUNING.HONORBEE_TARGET_DIST = 8
TUNING.HONORBEE_ALLERGY_EXTRADAMAGE = 10

-- 凶险蜂
TUNING.TERRORBEE_HEALTH = 30
TUNING.TERRORBEE_DAMAGE = 85
TUNING.TERRORBEE_ATTACK_RANGE = .4
TUNING.TERRORBEE_ATTACK_PERIOD = 1.8
TUNING.TERRORBEE_TARGET_DIST = 8
TUNING.TERRORBEE_ALLERGY_EXTRADAMAGE = 10

----------------------------------------------------------------------------
---[[buff相关]]
----------------------------------------------------------------------------
TUNING.HMR_HONOR_TEA_PRIME_STUN_CHANCE = 0.15               -- 茶丛精华 定身概率
TUNING.HMR_HONOR_TEA_PRIME_STUN_TIME = 6                    -- 茶丛精华 定身时间（秒）
TUNING.HMR_SPICE_HONOR_TEA_PRIME_AWAKE_HEALTHPERCENT = 0.2  -- 茶丛精华调味料 受到最大生命值20%的伤害后，唤醒受击者
TUNING.HMR_SPICE_HONOR_TEA_PRIME_AWAKE_DEGREE = 1           -- 茶丛精华调味料 每次攻击增加的定身度

TUNING.HMR_HONOR_COCONUT_PRIME_TREEGUARD_SPAWN_CHANCE = 0.03    -- 椰子精华 椰树守卫召唤概率
TUNING.HMR_HONOR_COCONUT_PRIME_TREEGUARD_DISAPPEAR_TIME = 240   -- 椰子精华 椰树守卫存活时间（秒）
TUNING.HMR_SPICE_HONOR_COCONUT_PRIME_SPAWN_COCONUT_CHANCE = 0.1 -- 椰子精华调味料 天降椰子概率
TUNING.HMR_SPICE_HONOR_COCONUT_PRIME_SPAWN_COCONUT_DAMAGE = 10  -- 椰子精华调味料 天降椰子伤害

TUNING.HMR_HONOR_WHEAT_PRIME_ADDCOLDNESS_CHANCE = 0.4           -- 小麦精华 增加冰冻度概率
TUNING.HMR_HONOR_WHEAT_PRIME_ADDCOLDNESS_DEGREE = 4             -- 小麦精华 增加冰冻度程度
TUNING.HMR_HONOR_WHEAT_PRIME_FREEZE_TIME = 5                    -- 小麦精华 冰冻时间（秒）
TUNING.HMR_SPICE_HONOR_WHEAT_PRIME_ADDIGNITIONLEVEL_DEGREE = 3  -- 小麦精华调味料 增加引燃度概率

TUNING.HMR_SPICE_HONOR_RICE_PRIME_DODGE_CHANCE = 0.12           -- 水稻精华调味料 闪避率
TUNING.HMR_SPICE_HONOR_RICE_PRIME_DODGE_DISTANCE = 2            -- 水稻精华调味料 闪避后撤距离
TUNING.HMR_SPICE_HONOR_RICE_PRIME_SPEED_MULT = 0.9              -- 水稻精华调味料 移速倍率

TUNING.HMR_TERROR_GINGER_PRIME_ABSORPTION_MULTIPLIER = 2.0      -- 洋姜精华 食物吸收率
TUNING.HMR_SPICE_TERROR_GINGER_PRIME_ABSORPTION_MULTIPLIER = 1.2 -- 洋姜精华调味料 食物吸收率

TUNING.HMR_TERROR_SNAKESKINFRUIT_PRIME_IGNITE_CHANCE = 0.5      -- 蛇果精华 点燃攻击者概率
TUNING.HMR_TERROR_SNAKESKINFRUIT_PRIME_FIRE_DAMAGE = 5          -- 蛇果精华 点燃伤害
TUNING.HMR_SPICE_TERROR_SNAKESKINFRUIT_PRIME_FIRE_DAMAGE = 5    -- 蛇果精华调味料 点燃伤害

----------------------------------------------------------------------------
---[[人物]]
----------------------------------------------------------------------------
-- 凌娜
TUNING.HMR_LINGNA_HEALTH = 150
TUNING.HMR_LINGNA_HUNGER = 150
TUNING.HMR_LINGNA_SANITY = 200
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.HMR_LINGNA = {
	"flint",
	"flint",
	"twigs",
	"twigs",
}
