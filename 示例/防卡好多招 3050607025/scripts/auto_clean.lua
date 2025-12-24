GLOBAL.setmetatable(env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end,
})

local TheNet = GLOBAL.TheNet
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()
local TUNING = GLOBAL.TUNING
local TheWorld = GLOBAL.TheWorld

local clean_cycle = GetModConfigData("CLEAN_DAYS")
local need_clean = GetModConfigData("AUTO_CLEAN")

local Unit_tentaclespike = GetModConfigData("tentaclespike")
local Unit_grassgekko = GetModConfigData("grassgekko")
local Unit_armor_sanity = GetModConfigData("armor_sanity")
local Unit_shadowheart = GetModConfigData("shadowheart")
local Unit_hound = GetModConfigData("hound")
local Unit_firehound= GetModConfigData("firehound")
local Unit_spider = GetModConfigData("spider")
local Unit_flies = GetModConfigData("flies")
local Unit_bee = GetModConfigData("bee")
local Unit_frog = GetModConfigData("frog")
local Unit_beefalo = GetModConfigData("beefalo")
local Unit_deer = GetModConfigData("deer")
local Unit_slurtle = GetModConfigData("slurtle")
local Unit_rocky = GetModConfigData("rocky")
local Unit_evergreen_sparse = GetModConfigData("evergreen_sparse")
local Unit_twiggytree = GetModConfigData("twiggytree")
local Unit_marsh_tree = GetModConfigData("marsh_tree")
local Unit_rock_petrified_tree = GetModConfigData("rock_petrified_tree")
local Unit_skeleton_player = GetModConfigData("skeleton_player")
local Unit_spiderden = GetModConfigData("spiderden")
local Unit_burntground = GetModConfigData("burntground")
local Unit_seeds = GetModConfigData("seeds")
local Unit_log = GetModConfigData("log")
local Unit_pinecone = GetModConfigData("pinecone")
local Unit_cutgrass = GetModConfigData("cutgrass")
local Unit_twigs = GetModConfigData("twigs")
local Unit_rocks = GetModConfigData("rocks")
local Unit_nitre = GetModConfigData("nitre")
local Unit_flint = GetModConfigData("flint")
local Unit_poop = GetModConfigData("poop")
local Unit_guano = GetModConfigData("guano")
local Unit_manrabbit_tail = GetModConfigData("manrabbit_tail")
local Unit_silk = GetModConfigData("silk")
local Unit_spidergland = GetModConfigData("spidergland")
local Unit_stinger = GetModConfigData("stinger")
local Unit_houndstooth = GetModConfigData("houndstooth")
local Unit_mosquitosack = GetModConfigData("mosquitosack")
local Unit_glommerfuel = GetModConfigData("glommerfuel")
local Unit_slurtleslime = GetModConfigData("slurtleslime")
local Unit_spoiled_food = GetModConfigData("spoiled_food")
local Unit_blueprint = GetModConfigData("blueprint")
local Unit_axe = GetModConfigData("axe")
local Unit_torch = GetModConfigData("torch")
local Unit_pickaxe = GetModConfigData("pickaxe")
local Unit_hammer = GetModConfigData("hammer")
local Unit_shovel = GetModConfigData("shovel")
local Unit_razor = GetModConfigData("razor")
local Unit_pitchfork = GetModConfigData("pitchfork")
local Unit_bugnet = GetModConfigData("bugnet")
local Unit_fishingrod = GetModConfigData("fishingrod")
local Unit_spear = GetModConfigData("spear")
local Unit_earmuffshat = GetModConfigData("earmuffshat")
local Unit_winterhat = GetModConfigData("winterhat")
local Unit_heatrock = GetModConfigData("heatrock")
local Unit_trap = GetModConfigData("trap")
local Unit_birdtrap = GetModConfigData("birdtrap")
local Unit_compass = GetModConfigData("compass")
local Unit_driftwood_log = GetModConfigData("driftwood_log")
local Unit_spoiled_fish = GetModConfigData("spoiled_fish")
local Unit_rottenegg = GetModConfigData("rottenegg")
local Unit_feather = GetModConfigData("feather")
local Unit_pocket_scale = GetModConfigData("pocket_scale")
local Unit_oceanfishingrod = GetModConfigData("oceanfishingrod")
local Unit_sketch = GetModConfigData("sketch")
local Unit_tacklesketch = GetModConfigData("tacklesketch")
local Unit_food_candy = GetModConfigData("food_candy")
local Unit_winter_ornament = GetModConfigData("winter_ornament")
local Unit_halloween_ornament = GetModConfigData("halloween_ornament")
local Unit_trinket = GetModConfigData("trinket")

-- 分隔字符串
local function split(str, separator)
    local results = {}
    local pattern = "([^" .. separator .. "]+)"
    local last_end = 1

    for start, stop in function() return string.find(str, pattern, last_end) end do
        table.insert(results, string.sub(str, last_end, start - 1))
        last_end = stop + 1
    end

    -- Add the last segment
    table.insert(results, string.sub(str, last_end))
    
    return results
end

if not IsServer then
	return
end

-- 需要清理的物品
-- @max        地图上存在的最大数量
-- @stack      标识为true时表示仅清理无堆叠的物品
-- @reclean    标识为数字,表示超过第n次清理时物品还存在则强制清理(第一次找到物品并未清理的计数为1):超过次数后即使堆叠的物品也会清理
--local function GetLevelPrefabs()
local levelPrefabs = {
    ------------------------  生物  ------------------------
    hound           = { max = Unit_hound },			-- 狗
    firehound       = { max = Unit_firehound },		-- 火狗
    spider_warrior  = { max = Unit_spider },		-- 蜘蛛战士
    spider          = { max = Unit_spider },		-- 蜘蛛
    flies           = { max = Unit_flies },			-- 苍蝇
	grassgekko      = { max = Unit_grassgekko },   	-- 草蜥蜴
    mosquito        = { max = Unit_flies },			-- 蚊子
    bee             = { max = Unit_bee },			-- 蜜蜂
    killerbee       = { max = Unit_bee },			-- 杀人蜂
    frog            = { max = Unit_frog },			-- 青蛙
    beefalo         = { max = Unit_beefalo },		-- 牛
    deer            = { max = Unit_deer },			-- 鹿
    slurtle         = { max = Unit_slurtle },		-- 鼻涕虫
    snurtle         = { max = Unit_slurtle },		-- 蜗牛
	rocky			= { max = Unit_rocky },			-- 石虾
	
	

    ------------------------  地面物体  ------------------------
    evergreen_sparse    = { max = Unit_evergreen_sparse },				  -- 常青树
    twiggytree          = { max = Unit_twiggytree },                      -- 树枝树
    marsh_tree          = { max = Unit_marsh_tree },                      -- 针刺树
    rock_petrified_tree = { max = Unit_rock_petrified_tree },             -- 石化树
    skeleton_player     = { max = Unit_skeleton_player },                 -- 玩家尸体
    spiderden           = { max = Unit_spiderden },                       -- 蜘蛛巢
    burntground         = { max = Unit_burntground },                     -- 陨石痕跡
	
	

    ------------------------  可拾取物品  ------------------------
    seeds           = { max = Unit_seeds, stack = true, reclean = 2 },        		-- 种子
    tentaclespike   = { max = Unit_tentaclespike, stack = true, reclean = 2 },      -- 触手尖刺
    log             = { max = Unit_log, stack = true, reclean = 2 },       			-- 木头
    pinecone        = { max = Unit_pinecone, stack = true, reclean = 2 },       	-- 松果
    cutgrass        = { max = Unit_cutgrass, stack = true, reclean = 2 },       	-- 草
    twigs           = { max = Unit_twigs, stack = true, reclean = 2 },       		-- 树枝
    rocks           = { max = Unit_rocks, stack = true, reclean = 2 },       		-- 石头
    nitre           = { max = Unit_nitre, stack = true, reclean = 2 },       		-- 硝石
    flint           = { max = Unit_flint, stack = true, reclean = 2 },       		-- 燧石
    poop            = { max = Unit_poop , stack = true, reclean = 2 },       		-- 屎
    guano           = { max = Unit_guano , stack = true, reclean = 2 },       		-- 鸟屎
    manrabbit_tail  = { max = Unit_manrabbit_tail , stack = true, reclean = 2 },    -- 兔毛
    silk            = { max = Unit_silk , stack = true, reclean = 2 },       		-- 蜘蛛丝
    spidergland     = { max = Unit_spidergland , stack = true, reclean = 2 },       -- 蜘蛛腺体
    stinger         = { max = Unit_stinger , stack = true, reclean = 2 },       	-- 蜂刺
    houndstooth     = { max = Unit_houndstooth , stack = true, reclean = 2 },       -- 狗牙
    mosquitosack    = { max = Unit_mosquitosack , stack = true, reclean = 2 },      -- 蚊子血袋
    glommerfuel     = { max = Unit_glommerfuel , stack = true, reclean = 2 },       -- 格罗姆粘液
    slurtleslime    = { max = Unit_slurtleslime , stack = true, reclean = 2 },      -- 鼻涕虫粘液
    slurtle_shellpieces = { max = Unit_slurtleslime, stack = true, reclean = 2 },   -- 鼻涕虫壳碎片

    spoiled_food    = { max = Unit_spoiled_food },                                  -- 腐烂食物

    blueprint   = { max = Unit_blueprint },	 	 -- 蓝图
    axe         = { max = Unit_axe }, 	 		 -- 斧子
    torch       = { max = Unit_torch },    		 -- 火炬
    pickaxe     = { max = Unit_pickaxe },  		 -- 镐子
    hammer      = { max = Unit_hammer },   		 -- 锤子
    shovel      = { max = Unit_shovel },   		 -- 铲子
    razor       = { max = Unit_razor },    		 -- 剃刀
    pitchfork   = { max = Unit_pitchfork },	     -- 草叉
    bugnet      = { max = Unit_bugnet },    	 -- 捕虫网
    fishingrod  = { max = Unit_fishingrod },     -- 鱼竿
    spear       = { max = Unit_spear },    		 -- 矛
    earmuffshat = { max = Unit_earmuffshat },    -- 兔耳罩
    winterhat   = { max = Unit_winterhat },   	 -- 冬帽
	heatrock    = { max = Unit_heatrock },   	 -- 热能石
    trap        = { max = Unit_trap },   		 -- 动物陷阱
    birdtrap    = { max = Unit_birdtrap },  	 -- 鸟陷阱
    compass     = { max = Unit_compass },   	 -- 指南針

    armor_sanity   = { max = Unit_armor_sanity },    -- 影甲
    shadowheart    = { max = Unit_shadowheart  },    -- 影心
	
	------------------------  added by yuuuuuxi  ------------------------
	driftwood_log			= { max = Unit_driftwood_log },		--浮木桩
	spoiled_fish			= { max = Unit_spoiled_fish  },		--变质的鱼
	spoiled_fish_small		= { max = Unit_spoiled_fish  },		--坏掉的小鱼
	rottenegg				= { max = Unit_rottenegg  },		--腐烂的蛋
	feather_crow			= { max = Unit_feather  },			--黑色羽毛
	feather_robin			= { max = Unit_feather  },			--红色羽毛
	feather_robin_winter	= { max = Unit_feather  },			--白色羽毛
	feather_canary			= { max = Unit_feather  },			--金色羽毛
	slurper_pelt			= { max = Unit_feather  },			--啜食兽毛皮
	pocket_scale			= { max = Unit_pocket_scale },		--弹簧秤
	oceanfishingrod			= { max = Unit_oceanfishingrod },	--海钓竿
	
	sketch					= { max = Unit_sketch },			--所有boss草图
	tacklesketch			= { max = Unit_tacklesketch },		--所有广告

}
	
local command_data = {}
TheSim:GetPersistentString("clean_world", function(load_success, data)
	if load_success and data ~= nil then
		command_data = json.decode(data)
		if next(command_data) then
			-- 遍历表格
			for key, value in pairs(command_data) do
				levelPrefabs[key] = { max = value }	
			end
		end
	end
end)

local ALL_ITEMS = {
    -- 糖果零食类
    CANDY_SNACKS = {
        "winter_food1", "winter_food2", "winter_food3", 
        "winter_food5", "winter_food6", "winter_food9",
        "winter_food7", "winter_food8",
        "winter_food4",
        "halloweencandy_1", "halloweencandy_2", "halloweencandy_3", "halloweencandy_4",
        "halloweencandy_5", "halloweencandy_6", "halloweencandy_7", "halloweencandy_8",
        "halloweencandy_9", "halloweencandy_10", "halloweencandy_11", "halloweencandy_12",
        "halloweencandy_13", "halloweencandy_14",
        "crumbs"
    },
    
    -- 冬季盛宴装饰
    WINTER_ORNAMENTS = {
        "winter_ornament_plain1", "winter_ornament_plain2", "winter_ornament_plain3",
        "winter_ornament_plain4", "winter_ornament_plain5", "winter_ornament_plain6",
        "winter_ornament_plain7", "winter_ornament_plain8", "winter_ornament_plain9",
        "winter_ornament_plain10", "winter_ornament_plain11", "winter_ornament_plain12",
        "winter_ornament_fancy1", "winter_ornament_fancy2", "winter_ornament_fancy3",
        "winter_ornament_fancy4", "winter_ornament_fancy5", "winter_ornament_fancy6",
        "winter_ornament_fancy7", "winter_ornament_fancy8",
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
        "winter_ornament_festivalevents1", "winter_ornament_festivalevents2",
        "winter_ornament_festivalevents3", "winter_ornament_festivalevents4",
        "winter_ornament_festivalevents5"
    },
    
    -- 万圣夜装饰
    HALLOWEEN_ORNAMENTS = {
        "halloween_ornament_1", "halloween_ornament_2", "halloween_ornament_3",
        "halloween_ornament_4", "halloween_ornament_5", "halloween_ornament_6"
    },
    
    -- 万圣夜小玩具
    HALLOWEEN_TOYS = {
        "trinket_32", "trinket_33", "trinket_34", "trinket_35", "trinket_36",
        "trinket_37", "trinket_38", "trinket_39", "trinket_40", "trinket_41",
        "trinket_42", "trinket_43", "trinket_44", "trinket_45", "trinket_46"
    }
}

-- 遍历每个类别并设置levelPrefabs
for _, item in ipairs(ALL_ITEMS.CANDY_SNACKS) do
    levelPrefabs[item] = { max = Unit_food_candy }
end

for _, item in ipairs(ALL_ITEMS.WINTER_ORNAMENTS) do
    levelPrefabs[item] = { max = Unit_winter_ornament }
end

for _, item in ipairs(ALL_ITEMS.HALLOWEEN_ORNAMENTS) do
    levelPrefabs[item] = { max = Unit_halloween_ornament }
end

for _, item in ipairs(ALL_ITEMS.HALLOWEEN_TOYS) do
    levelPrefabs[item] = { max = Unit_trinket }
end

local function RemoveItem(inst)
    if inst.components.health ~= nil and not inst:HasTag("wall") then
        if inst.components.lootdropper ~= nil then
            inst.components.lootdropper.DropLoot = function(pt) end
        end
        inst.components.health:SetPercent(0)
    else
        inst:Remove()
    end
end

local function Clean(inst, level)
    local this_max_prefabs = levelPrefabs
    local countList = {}
    for _,v in pairs(GLOBAL.Ents) do
        if v.prefab ~= nil then
            repeat
                local thisPrefab = v.prefab
                if this_max_prefabs[thisPrefab] ~= nil then
                    if v.reclean == nil then
                        v.reclean = 2
                    else
                        v.reclean = v.reclean + 1
                    end

                    local bNotClean = true
                    if this_max_prefabs[thisPrefab].reclean ~= nil then
                        bNotClean = this_max_prefabs[thisPrefab].reclean > v.reclean
                    end
					print()

                    if this_max_prefabs[thisPrefab].stack and bNotClean and v.components and v.components.stackable and v.components.stackable:StackSize() > 1 then break end
                else break end

                -- 不可见物品(在包裹内等)
                if v.inlimbo then break end

                if countList[thisPrefab] == nil then
                    countList[thisPrefab] = { name = v.name or v:GetDisplayName(), count = 1, currentcount = 1 }
                else
                    countList[thisPrefab].count = countList[thisPrefab].count + 1
                    countList[thisPrefab].currentcount = countList[thisPrefab].currentcount + 1
                end

                if this_max_prefabs[thisPrefab].max >= countList[thisPrefab].count then break end

                if (v.components.hunger ~= nil and v.components.hunger.current > 0) or (v.components.domesticatable ~= nil and v.components.domesticatable.domestication > 0) then
                    break
                end

                RemoveItem(v)
                countList[thisPrefab].currentcount = countList[thisPrefab].currentcount - 1
            until true
        end
    end

	if GetModConfigData("ANNOUNCE_MODE") then
		for k,v in pairs(this_max_prefabs) do
			if countList[k] ~= nil and countList[k].count > v.max then
				local name = STRINGS.NAMES[string.upper(k)] or "--"
				GLOBAL.TheNet:Announce(string.format(STRINGS.CLEANINGS[2], countList[k].name.."/"..name, k, countList[k].count - countList[k].currentcount))
			end
		end
	end
end


local noticeTask = nil
local function NoticeTask()
	GLOBAL.TheNet:Announce(STRINGS.CLEAN_NOTICE)
end

local function CleanDelay()
	local world = STRINGS.CLEANINGS[5]
	if GLOBAL.TheWorld:HasTag("forest") and noticeTask then
		noticeTask:Cancel()
		noticeTask = GLOBAL.TheWorld:DoPeriodicTask((clean_cycle - 0.5) * TUNING.TOTAL_DAY_TIME, NoticeTask)
		world = STRINGS.CLEANINGS[3]
	end
	if GLOBAL.TheWorld:HasTag("cave") then
		world = STRINGS.CLEANINGS[4]
	end
	GLOBAL.TheNet:Announce(world..STRINGS.CLEANINGS[1]..STRINGS.POETRY[math.random(1, table.getn(STRINGS.POETRY))].."』")
    GLOBAL.TheWorld:DoTaskInTime(5, Clean)
end


-- 自动清理
if need_clean then
	if GetModConfigData("TEST_MODE") then
		cleancycle_ultimate = 10
	else
		cleancycle_ultimate = clean_cycle * TUNING.TOTAL_DAY_TIME
	end	
	AddPrefabPostInit("world", function(inst)
		if GLOBAL.TheWorld:HasTag("forest") then
			noticeTask = GLOBAL.TheWorld:DoPeriodicTask(cleancycle_ultimate - 0.5 * TUNING.TOTAL_DAY_TIME, NoticeTask)
		end
		GLOBAL.TheWorld:DoPeriodicTask(cleancycle_ultimate , CleanDelay)
	end)
end

-- Get Player var userid
local function GetPlayerById(playerid)
	for _, v in ipairs(GLOBAL.AllPlayers) do
		if v ~= nil and v.userid and v.userid == playerid then
			return v
		end
	end
	return nil
end

-- 按U输入#clean_world手动清理
-- 有问题，有TheNet:Announce方法就会执行失败，不知所以。
-- 2024-01-13 问题已解决
local Old_Networking_Say = GLOBAL.Networking_Say
GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote, ...)
	Old_Networking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, ...)
	-- 自动
	-- #keep_item@hivehat:2
	-- #keep_item@spiderhat:2;hivehat:2
	local player = GetPlayerById(userid)
	local  keep_item = "#keep_item@"
	if #message > #keep_item and string.sub(message, 1, #keep_item) == keep_item then
		if not (TheNet:GetIsServerAdmin() and player.components and player.Network:IsServerAdmin()) then
            player:DoTaskInTime(0.5, function() if player.components.talker then player.components.talker:Say(player:GetDisplayName() .. ", " .. "管理员才能清理世界") end end)
            return
        end
		message = string.sub(message, #keep_item + 1)
		message = (string.gsub(message,"：",":"))
		message = (string.gsub(message,"；",";"))
		message = (string.gsub(message," ",""))
		local item_cnts = string.split(string.lower(message),";")
		for k, v in ipairs(item_cnts) do
			local item_cnt = string.split(string.lower(v),":")
			local max_temp = 2
			if #item_cnt >= 2 then
				if tonumber(item_cnt[2]) then
					max_temp = tonumber(item_cnt[2])
				end
				levelPrefabs[item_cnt[1]] = { max = max_temp }
				command_data[item_cnt[1]] = max_temp
				-- player:DoTaskInTime(0.5, function() if player.components.talker then player.components.talker:Say(STRINGS.ADD_SUCCESS..item_cnt[1].."："..item_cnt[2]) end end)
			end
		end
		TheSim:SetPersistentString("clean_world", json.encode(command_data), false) 
		player:DoTaskInTime(0.5, function() if player.components.talker then player.components.talker:Say(json.encode(command_data)) end end)
		message = "#clean_world"
	end
	
	if whisper and (string.lower(message) == "#clean_world" or
		string.lower(message) == "#clean" or
		string.lower(message) == "#cl" or
		string.lower(message) == "#清理"
	) then
		if not (TheNet:GetIsServerAdmin() and player.components and player.Network:IsServerAdmin()) then
            player:DoTaskInTime(0.5, function() if player.components.talker then player.components.talker:Say(player:GetDisplayName() .. ", " .. STRINGS.ONLY_ADMIN_CLEAN) end end)
            return
        end
        if player then
            local charactername = STRINGS.CHARACTER_NAMES[prefab] or prefab
            player.components.talker:Say(player:GetDisplayName() .. " (" .. charactername .. ") " .. STRINGS.COMMAND_CLEAN)
            player:DoTaskInTime(0.5, CleanDelay)
        end
	end
end