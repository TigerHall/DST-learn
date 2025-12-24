GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })	--查值时自动查global，增加global的变量或者修改global的变量时还是需要带"GLOBAL."
local _G = GLOBAL
local containers = require("containers")
local TUNING = GLOBAL.TUNING
local FOODTYPE = GLOBAL.FOODTYPE
local cookingrf = require("cooking")
local Vector3 = GLOBAL.Vector3

--local containers_upslot = GetModConfigData("containers_up")
local icebox_upslot = GetModConfigData("icebox_up")
local saltbox_upslot = GetModConfigData("saltbox_up")
local cookpot_fr = GetModConfigData("cookpot_up")
local bfs_upslot = GetModConfigData("beargerfur_sack_up")

local itype_i = GetModConfigData("itemtype_i")
local itype_s = GetModConfigData("itemtype_s")
local itype_b = GetModConfigData("itemtype_b")
local itype_m = GetModConfigData("itemtype_m")

local fxFoodSp = GetModConfigData("FoodSp")
local fxsaltbox = GetModConfigData("slbox")
local fxmrlt = GetModConfigData("mrlt")
local fb_fx = GetModConfigData("fsbox")
local st_fx = GetModConfigData("sis_dt")
local sp_fx = GetModConfigData("seedpouch")
local bs_fx = GetModConfigData("beard_sack")
local ks_fx = GetModConfigData("krampus_sack")
local bfs_fx = GetModConfigData("beargerfur_sack")
local otherlist = GetModConfigData("other_list")
local ct_upgraded = GetModConfigData("containers_upgraded")

Assets = 
{   
    Asset("ANIM", "anim/ui_icebox_4x4.zip"),
    Asset("ANIM", "anim/ui_icebox_4x4_upgraded.zip"),
	Asset("ANIM", "anim/ui_icebox_5x5.zip"),
	Asset("ANIM", "anim/ui_icebox_5x5_upgraded.zip"),
	Asset("ANIM", "anim/ui_icebox_6x6.zip"),
	Asset("ANIM", "anim/ui_icebox_6x6_upgraded.zip"),
	
	Asset("ATLAS", "images/slotbg.xml"),
    Asset("IMAGE", "images/slotbg.tex"),
}

modimport("scripts/newupdate.lua")

translations = {	--想根据客户端的语言去显示按钮文字，但好像没有效果
	["en"] = {
		["整理"] = "Tidyin",
	},
	["zh"] = {
		["整理"] = "整理",
	},
	["zht"] = {
		["整理"] = "整理",
	},
}

language = translations[locale]
if language == nil then language = translations["zh"] end

--冰箱
--if fxFoodSp ~= false then
	TUNING.PERISH_FRIDGE_MULT = fxFoodSp	--默认强制开启吧
--end

--防流星列表
--表内可手动添加，记得加逗号，主服务器加就行，加入房间的玩家一样生效
local m_list = {
	"icebox",	--冰箱
	"saltbox",	--盐盒
	"seasack",	--海上保鲜袋(海难)
	"mushroom_light",
	"mushroom_light2",	--蘑菇灯，织菇灯
	"fish_box",		--锡鱼罐
	"sisturn",		--骨灰罐
	"seedpouch",	--种子袋
	"krampus_sack",	--坎普斯背包
	"backpack",		--普通背包
	"icepack",		--保鲜背包
	"piggyback",	--小猪包
	"spicepack",	--厨师袋
	"cookpot",		--烹饪锅
	"portablecookpot",	--厨师锅
	"portablespicer",	--香料站
	"beargerfur_sack",	--极地熊餐盒
}
for i, n in pairs(m_list) do
	AddPrefabPostInit(n, function(inst)
		inst:AddTag("meteor_protection") --防流星标签
	end)
end

--弹性空间升级容器列表
local CBOX_UPGRADE = {
	"icebox",
	"saltbox",
}

--烹饪锅永鲜表
--表内可手动添加，记得加逗号，主服务器加就行，加入房间的玩家一样生效
local addfr = {
	"cookpot",				--烹饪锅
	"archive_cookpot",		--远古锅
	"portablecookpot",		--厨师锅
	"portablespicer",		--香料站
	"medal_cookpot",		--红晶锅(勋章)
	}
if cookpot_fr then 
	for _,v in pairs(addfr) do 
		AddPrefabPostInit(v,function(inst)
			local self = inst.components.stewer
			if self then
				function self:GetTimeToSpoil() return 1000 end
				local cookpotend = self.onharvest
				self.onharvest = function()
					self.product_spoilage = 100
					self.spoiledproduct = self.product return cookpotend ~= nil and cookpotend(self.inst)
				end
				self.onspoil = function(self)
					self.spoiledproduct = self.product self.targettime,self.spoiltime = 960
				end
			end 
		end)
	end 
end

--盐盒
if fxsaltbox ~= false then TUNING.PERISH_SALTBOX_MULT = fxsaltbox end
--蘑菇灯，织菇灯
if fxmrlt ~= false then
	TUNING.PERISH_MUSHROOM_LIGHT_MULT = fxmrlt
	TUNING.PERISH_MUSHROOM_LIGHT2_MULT = fxmrlt
end

local ctr_list = {
	"fish_box",		--锡鱼罐
	"sisturn",		--骨灰罐
	"seedpouch",	--种子袋
	"beard_sack_1",	--胡子包
	"beard_sack_2",
	"beard_sack_3",
	"krampus_sack",			--坎普斯背包
	"beargerfur_sack",		--极地熊獾桶
}
for i, v in pairs(ctr_list) do
	AddPrefabPostInit(v, function(inst)
		if not TheWorld.ismastersim then
			return inst
		end
		--给变量 d 赋上modinfo的值
		local d = v == "fish_box" and fb_fx or v == "sisturn" and st_fx or v == "seedpouch" and sp_fx or (v == "beard_sack_1" or v == "beard_sack_2" or v == "beard_sack_3") and bs_fx or v == "krampus_sack" and ks_fx or v == "beargerfur_sack" and bfs_fx
		local icebfx = GetModConfigData("FoodSp")
		local c = inst.components
		--如果v是极地熊獾桶则执行打开不掉落
		--local bfs_dropon = GetModConfigData("beargerfur_sack_dropon")
		--if v == "beargerfur_sack" and inst.components.container ~= nil and bfs_dropon then inst.components.container.droponopen = nil end
		
		if v ~= "beargerfur_sack" and d ~= false then
			if d == "cool" then
				if not c.preserver then
					inst:AddComponent("preserver")
				end
				inst:AddTag("fridge")
				c.preserver:SetPerishRateMultiplier(icebfx)
			else
				if not c.preserver then
					inst:AddComponent("preserver")
				end
				c.preserver:SetPerishRateMultiplier(d)
			end
		elseif v == "beargerfur_sack" and d ~= false then	--极地熊獾桶已经有preserver组件，直接改保鲜率就行
			if not c.preserver then	--加层保险，防止有些模组移除了preserver组件导致崩溃
				inst:AddComponent("preserver")
			end
			inst.components.preserver:SetPerishRateMultiplier(d)
		end
	end)
end

--鸟笼
if GetModConfigData("birdcage_up") then
	TUNING.PERISH_CAGE_MULT = 0
end

--其他容器保鲜率，如果加了跟上面已有的容器，这个设置会覆盖掉上面的
if otherlist ~= false then
	for k, v in pairs(otherlist) do
		AddPrefabPostInit(v, function(inst)
			if not TheWorld.ismastersim then
				return inst
			end
			local ofx = GetModConfigData("other_fx")
			local ibfx = GetModConfigData("FoodSp")
			if ofx ~= false and ofx ~= "cool" and v ~= "hiddenmoonlight" then
				if not inst.components.preserver then
					inst:AddComponent("preserver")
				end
				inst.components.preserver:SetPerishRateMultiplier(ofx)
			elseif ofx == "cool" and v ~= "hiddenmoonlight" then
				if not inst.components.preserver then
					inst:AddComponent("preserver")
				end
				inst:AddTag("fridge")
				inst.components.preserver:SetPerishRateMultiplier(ibfx)
			elseif v == "hiddenmoonlight" then	--这是月藏宝匣，有fridge Tag，直接应用冰箱设置值
				if not inst.components.preserver then
					inst:AddComponent("preserver")
				end
				inst.components.preserver:SetPerishRateMultiplier(ibfx)
			end
		end)
	end
end

--容器更改
--if containers_upslot then
	--local function sortoutbtn(language)
-- 格子更改
local function ShouldApplySlots(upslot_setting)
    return upslot_setting ~= false and upslot_setting ~= nil
end
--储存类型更改
local function ShouldApplyItemTest(itemtype_setting)
    return itemtype_setting == true
end

local function MergeParams(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = v
        else
            -- 深度合并表
            if type(v) == "table" and type(target[k]) == "table" then
                MergeParams(target[k], v)
            else
                target[k] = v
            end
        end
    end
end
-- 修改后的参数应用逻辑
local function ApplyContainerParams(params_to_apply)
    for k, v in pairs(params_to_apply) do
        -- 只更新明确修改的部分，而不是完全覆盖
        if containers.params[k] then
            MergeParams(containers.params[k], v)
        else
            containers.params[k] = v
        end
        
        -- 更新最大格子数
        if v.widget and v.widget.slotpos then
            containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, #v.widget.slotpos)
        end
    end
end

-- 下列物品整理代码源自 能力勋章Mod --
local function iceboxStr(str1, str2)
	if (str1 == str2) then
		return 0
	end
	if (str1 < str2) then
		return -1
	end
	if (str1 > str2) then
		return 1
	end
end
--按字母排序
local function cmp(e, f)
	if e and f then
		--尝试按照 prefab 名字排序
		local prefab_e = tostring(e.prefab)
		local prefab_f = tostring(f.prefab)
		return iceboxStr(prefab_e, prefab_f)
	end
end
--插入法排序函数
local function icebox_sort(list, comp)
	for i = 2, #list do
		local v = list[i]
		local j = i - 1
		while (j>0 and (comp(list[j], v) > 0)) do
			list[j+1]=list[j]
			j=j-1
		end
		list[j+1]=v
	end
end
--容器排序
local function FxslotsPX(inst)
	if inst and inst.components.container then
		--取出容器中的所有物品
		local items = {}
		for k, v in pairs(inst.components.container.slots) do
			local item = inst.components.container:RemoveItemBySlot(k, true)
			if item and item:IsValid() then
				table.insert(items, item)
			end
		end

		icebox_sort(items, cmp)

		for i = 1, #items do
			inst.components.container:GiveItem(items[i])
		end
	end
end
--整理按钮点击函数
local function FxslotsPXFn(inst, doer)
	if inst.components.container ~= nil then --如果有 container 这个组件，也就是属性
		FxslotsPX(inst)
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		SendRPCToServer(RPC.DoWidgetButtonAction, nil, inst, nil)
	end
end
--整理按钮亮起规则
local function FxslotsPXValidFn(inst)
	return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()	-- and not inst:HasTag("fbox_upgraded")
end

local need_apply = false

-- 冰箱配置
local icebox_params = {}
if ShouldApplySlots(icebox_upslot) then
    -- 格子设置
    if icebox_upslot == 1 then	-- 16格配置
		icebox_params.icebox = {
			widget = {
				slotpos = {},
				animbank = "ui_icebox_4x4",
				animbuild = "ui_icebox_4x4",
				animbank_upgraded = "ui_icebox_4x4_upgraded",
				animbuild_upgraded = "ui_icebox_4x4_upgraded",
				pos = Vector3(0, 200, 0),
				side_align_tip = 160,
				buttoninfo = {
				text = language["整理"],
				position = Vector3(-2,-190,0),
				fn = FxslotsPXFn,
				validfn = FxslotsPXValidFn,
				},
			},
			type = "chest",
		}

		for y = 3, 0, -1 do
			for x = 0, 3 do
				table.insert(icebox_params.icebox.widget.slotpos, Vector3(80 * x - 80 * 2 + 40, 80 * y - 80 * 2 + 40, 0))
			end
		end
    elseif icebox_upslot == 2 then	-- 25格配置
		icebox_params.icebox = {
			widget = {
				slotpos = {},
				animbank = "ui_icebox_5x5",
				animbuild = "ui_icebox_5x5",
				animbank_upgraded = "ui_icebox_5x5_upgraded",
				animbuild_upgraded = "ui_icebox_5x5_upgraded",
				pos = Vector3(0, 200, 0),
				side_align_tip = 160,
				buttoninfo = {
				text = language["整理"],
				position = Vector3(-2,-230,0),
				fn = FxslotsPXFn,
				validfn = FxslotsPXValidFn,
				},
			},
			type = "chest",
		}

		for y = 3, -1, -1 do
			for x = 0, 4 do
				table.insert(icebox_params.icebox.widget.slotpos, Vector3(80 * x - 80 * 2, 80 * y - 80 * 2 + 80, 0))
			end
		end
    end
    need_apply = true
end
-- 冰箱存放类型
if ShouldApplyItemTest(itype_i) then
	icebox_params.icebox = icebox_params.icebox or {}
	icebox_params.icebox.itemtestfn = function(container, item, slot)
		if item:HasTag("icebox_valid") then
			return true
		end
		
		--参考自棱镜 Mod，是烹饪食材都能放进去
		if cookingrf.IsCookingIngredient(item.prefab) then
			return true
		end
		
		--Perishable
		if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
			return false
		end

		if item:HasTag("smallcreature") then
			return true
		end
		
		--Edible
		for k, v in pairs(FOODTYPE) do
			if item:HasTag("edible_"..v) then
				return true
			end
		end
		
		local fxvalid_items = --新鲜度的装备放入限制取消列表，可手动添加，记得加逗号，主服务器加就行，加入房间的玩家一样生效
		{
			red_mushroomhat = true,		--红色蘑菇帽
			green_mushroomhat = true,	--绿色蘑菇帽
			blue_mushroomhat = true,	--蓝色蘑菇帽
			grass_umbrella = true,		--花伞
			flowerhat = true,			--花环
			kelphat = true,				--海花冠
			hawaiianshirt = true,		--花衬衫
			mermhat = true,				--聪明的伪装
			moonstorm_spark = true,		--月熠
			moonglass_charged = true,	--注能月亮碎片
			spore_small = true,			--绿色孢子
			spore_medium = true,		--红色孢子
			spore_tall = true,			--蓝色孢子
			myth_lotusleaf = true,		--莲叶
			myth_lotusleaf_hat = true,	--莲叶帽
			myth_lotus_flower = true,	--莲花
			skeletonmeat = true,		--long pig
			palmleaf_umbrella = true,	--热带阳伞
			nubbin = true,				--珊瑚礁块
			tillweedsalve = true,		--犁地草药膏
		}
		if fxvalid_items[item.prefab] then
			return true
		end
		
		return false
	end
	need_apply = true
elseif ShouldApplySlots(icebox_upslot) then
	icebox_params.icebox = icebox_params.icebox or {}
	icebox_params.icebox.itemtestfn = function(container, item, slot)
		if item:HasTag("icebox_valid") then
			return true
		end

		if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
			return false
		end

		if item:HasTag("smallcreature") then
			return false
		end

		for k, v in pairs(FOODTYPE) do
			if item:HasTag("edible_"..v) then
				return true
			end
		end

		return false
	end
	need_apply = true
end

-- 应用冰箱参数
if need_apply then
    ApplyContainerParams(icebox_params)
end

-- 盐盒配置
local saltbox_params = {}
if ShouldApplySlots(saltbox_upslot) then
    -- 格子设置
    if saltbox_upslot == 1 then	-- 25格配置
		saltbox_params.saltbox =
		{
			widget =
			{
				slotpos = {},
				animbank = "ui_icebox_5x5",
				animbuild = "ui_icebox_5x5",
				animbank_upgraded = "ui_icebox_5x5_upgraded",
				animbuild_upgraded = "ui_icebox_5x5_upgraded",
				pos = Vector3(0, 200, 0),
				side_align_tip = 160,
				buttoninfo = {
				text = language["整理"],
				position = Vector3(-2,-230,0),
				fn = FxslotsPXFn,
				validfn = FxslotsPXValidFn,
				},
			},
			type = "chest",
		}

		for y = 3, -1, -1 do
			for x = 0, 4 do
				table.insert(saltbox_params.saltbox.widget.slotpos, Vector3(80 * x - 80 * 2, 80 * y - 80 * 2 + 80, 0))
			end
		end
    elseif saltbox_upslot == 2 then	-- 36格配置
		saltbox_params.saltbox =
		{
			widget =
			{
				slotpos = {},
				animbank = "ui_icebox_6x6",
				animbuild = "ui_icebox_6x6",
				animbank_upgraded = "ui_icebox_6x6_upgraded",
				animbuild_upgraded = "ui_icebox_6x6_upgraded",
				pos = Vector3(0, 200, 0),
				side_align_tip = 160,
				buttoninfo = {
				text = language["整理"],
				position = Vector3(-2,-270,0),
				fn = FxslotsPXFn,
				validfn = FxslotsPXValidFn,
				},
			},
			type = "chest",
		}

		for y = 4, -1, -1 do
			for x = -1, 4 do
				table.insert(saltbox_params.saltbox.widget.slotpos, Vector3(80 * x - 80 * 2 + 40, 80 * y - 80 * 2 + 80 - 40, 0))
			end
		end
    end
    need_apply = true
end
-- 盐盒存放类型
if ShouldApplyItemTest(itype_s) then
	saltbox_params.saltbox = saltbox_params.saltbox or {}
	saltbox_params.saltbox.itemtestfn = function(container, item, slot)
		if item:HasTag("saltbox_valid") then
			return true
		end
		
		if cookingrf.IsCookingIngredient(item.prefab) then
			return true
		end

		-- if item:HasTag("deployable") then	--种子类
			-- return false
		-- end
		
		if item:HasTag("smallcreature") then	--小生物，不想放进去就改为false
			return true
		end
		
		--Perishable
		if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
			return false
		end
		
		--Edible
		for k, v in pairs(FOODTYPE) do
			if item:HasTag("edible_"..v) then
				return true
			end
		end
		
		local fxvalid_items = --新鲜度的装备放入限制取消列表，可手动添加，记得加逗号，主服务器加就行，加入房间的玩家一样生效
		{
			red_mushroomhat = true,		--红色蘑菇帽
			green_mushroomhat = true,	--绿色蘑菇帽
			blue_mushroomhat = true,	--蓝色蘑菇帽
			grass_umbrella = true,		--花伞
			flowerhat = true,			--花环
			kelphat = true,				--海花冠
			hawaiianshirt = true,		--花衬衫
			mermhat = true,				--聪明的伪装
			moonstorm_spark = true,		--月熠
			moonglass_charged = true,	--注能月亮碎片
			spore_small = true,			--绿色孢子
			spore_medium = true,		--红色孢子
			spore_tall = true,			--蓝色孢子
			myth_lotusleaf = true,		--莲叶
			myth_lotusleaf_hat = true,	--莲叶帽
			myth_lotus_flower = true,	--莲花
			skeletonmeat = true,		--long pig
			palmleaf_umbrella = true,	--热带阳伞
			hat_albicans_mushroom = true,	--素白蘑菇帽
			hat_lichen = true,			--苔衣发卡
			rosorns = true,				--带刺蔷薇
			lileaves = true,			--蹄莲翠叶
			orchitwigs = true,			--兰草花穗
			dish_tomahawksteak = true,	--牛排战斧
			hambat = true,				--火腿棒
			nubbin = true,				--珊瑚礁块
			tillweedsalve = true,		--犁地草药膏
		}
		
		if fxvalid_items[item.prefab] then
			return true
		end
	end
	need_apply = true
elseif ShouldApplySlots(saltbox_upslot) then
	saltbox_params.saltbox = saltbox_params.saltbox or {}
	saltbox_params.saltbox.itemtestfn = function(container, item, slot)
		return ((item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled"))
			and item:HasTag("cookable")
			and not item:HasTag("deployable")
			and not item:HasTag("smallcreature")
			and item.replica.health == nil)
			or item:HasTag("saltbox_valid")
	end
	need_apply = true
end

-- 应用盐盒参数
if need_apply then
    ApplyContainerParams(saltbox_params)
end

--极地熊獾桶
local beargerfur_sack_params = {}
if ShouldApplySlots(bfs_upslot) then
    -- 格子设置
    if bfs_upslot == 1 then	-- 9格配置
		beargerfur_sack_params.beargerfur_sack =
		{
			widget =
			{
				slotpos = {},
				slotbg = {},
				animbank = "ui_chest_3x3",
				animbuild = "ui_chest_3x3",
				pos = Vector3(0, 200, 0),
				side_align_tip = 160,	--9格就不要整理按钮了吧
			},
			type = "chest",
		}

		for y = 2, 0, -1 do
			for x = 0, 2 do
				table.insert(beargerfur_sack_params.beargerfur_sack.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
				table.insert(beargerfur_sack_params.beargerfur_sack.widget.slotbg, { image = "slotbg.tex", atlas = "images/slotbg.xml" })
			end
		end
	elseif bfs_upslot == 2 then	--16格
		beargerfur_sack_params.beargerfur_sack =
		{
			widget =
			{
				slotpos = {},
				slotbg = {},
				animbank = "ui_icebox_4x4",
				animbuild = "ui_icebox_4x4",
				pos = Vector3(0, 200, 0),
				side_align_tip = 160,
				buttoninfo = {
				text = language["整理"],
				position = Vector3(-2,-190,0),
				fn = FxslotsPXFn,
				validfn = FxslotsPXValidFn,
				},
			},
			type = "chest",
		}

		for y = 3, 0, -1 do
			for x = 0, 3 do
				table.insert(beargerfur_sack_params.beargerfur_sack.widget.slotpos, Vector3(80 * x - 80 * 2 + 40, 80 * y - 80 * 2 + 40, 0))
				table.insert(beargerfur_sack_params.beargerfur_sack.widget.slotbg, { image = "slotbg.tex", atlas = "images/slotbg.xml" })
			end
		end
	end
	need_apply = true
end
-- 熊獾桶存放类型
if ShouldApplyItemTest(itype_b) then
	beargerfur_sack_params.beargerfur_sack = beargerfur_sack_params.beargerfur_sack or {}
	beargerfur_sack_params.beargerfur_sack.itemtestfn = function(container, item, slot)
		for k, v in pairs(FOODGROUP.OMNI.types) do
			if item:HasTag("edible_"..v) then	--取消放入限制，放入的类型跟胡子包一样
				return true
			end
		end
	end
	need_apply = true
elseif ShouldApplySlots(bfs_upslot) then
	beargerfur_sack_params.beargerfur_sack = beargerfur_sack_params.beargerfur_sack or {}
	beargerfur_sack_params.beargerfur_sack.itemtestfn = function(container, item, slot)
		return item:HasTag("beargerfur_sack_valid") or item:HasTag("preparedfood")
	end
	need_apply = true
end

if need_apply then
    ApplyContainerParams(beargerfur_sack_params)
end

--蘑菇灯存放类型
local mushroom_light_params = {}
if ShouldApplyItemTest(itype_m) then
	mushroom_light_params.mushroom_light = mushroom_light_params.mushroom_light or {}
	mushroom_light_params.mushroom_light.itemtestfn = function(container, item, slot)
		return (item:HasTag("lightbattery") or item:HasTag("spore") or item:HasTag("lightcontainer")) and not container.inst:HasTag("burnt")
	end
	need_apply = true
end
if need_apply then
    ApplyContainerParams(mushroom_light_params)
end
-------------------------------------------------------------------------

--[[ upgrade ]]
--------------------------------------------------------------------------
if ct_upgraded then
	local function NoWorked(inst, worker)
		if worker ~= nil and (worker:HasTag("player") or worker.components.walkableplatform ~= nil) then
			return false
		end
		return true
	end

	local function regular_getstatus(inst, viewer)
		return inst._chestupgrade_stacksize and "UPGRADED_STACKSIZE" or nil
	end

	local function upgrade_onhammered(inst, worker)
		if NoWorked(inst, worker) then	--不是玩家锤的则不掉出物品
			inst.components.workable:SetWorkLeft(2)
			return
		end
		
		--sunk, drops more, but will lose the remainder
		inst.components.lootdropper:DropLoot()
		if inst.components.container ~= nil then
			inst.components.container:DropEverything()
		end
		
		inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD)
		local fx = SpawnPrefab("collapse_small")
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		fx:SetMaterial("wood")
		inst:Remove()
		
		--fallback to default
		--onhammered(inst, worker)
	end

	local function upgrade_onhit(inst, worker)
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("closed", false)
		
		if inst.components.container then
			inst.components.container:Close()	--被锤击、打击时容器关闭
			if NoWorked(inst, worker) then	--不是玩家锤的则不掉出物品
				inst.components.workable:SetWorkLeft(2)
				return
			end
			if not inst.components.container:IsEmpty() then --如果箱子里还有物品，那就不能被破坏
				inst.components.workable:SetWorkLeft(2)
			end
			inst.components.container:DropEverything(nil, true)
		end
	end

	local function OnUpgrade_fbox_upgrade(inst, performer, upgraded_from_item)
		local numupgrades = inst.components.upgradeable.numupgrades
		if numupgrades == 1 then
			inst._chestupgrade_stacksize = true
			if inst.components.container ~= nil then -- NOTES(JBK): The container component goes away in the burnt load but we still want to apply builds.
				inst.components.container:Close()
				inst.components.container:EnableInfiniteStackSize(true)
				inst.components.inspectable.getstatus = regular_getstatus
			end
			
			if upgraded_from_item then
				-- Spawn FX from an item upgrade not from loads.
				local x, y, z = inst.Transform:GetWorldPosition()
				local fx = SpawnPrefab("chestupgrade_stacksize_taller_fx")
				fx.Transform:SetPosition(x, y, z)
				--对原物品进行转移整理一次
				local allitems = inst.components.container:RemoveAllItems()
				for _, v in ipairs(allitems) do
					inst.components.container:GiveItem(v)
				end
			end
		end
		inst.components.upgradeable.upgradetype = nil

		if inst.components.lootdropper ~= nil then
			inst.components.lootdropper:SetLoot({ "alterguardianhatshard" })
		end
		if inst.components.workable ~= nil then
			inst.components.workable:SetOnWorkCallback(upgrade_onhit)
			inst.components.workable:SetOnFinishCallback(upgrade_onhammered)
		end
		
		--inst:AddTag("fbox_upgraded")	--添加个升级标签，方便做其他管理
		--inst:ListenForEvent("restoredfromcollapsed", OnRestoredFromCollapsed)
		local fboxname = STRINGS.NAMES[string.upper(inst.prefab or "")] or inst.name or "MISSING NAME"	--获取物品名称
		inst.components.named:SetName(fboxname.." · "..STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS.ENDLESS)
	end

	local function OnLoad_fbox_upgrade(inst, data, newents)
		if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
			OnUpgrade_fbox_upgrade(inst)
		end
	end

	local function regular_SCStoreroom(inst)	--解构后丢出所有物品
		if inst.components.container and inst.components.container.infinitestacksize then
			--NOTE: should already have called DropEverything(nil, true) (worked or burnt or deconstructed)
			--      so everything remaining counts as an "overstack"
			local overstacks = 0
			for k, v in pairs(inst.components.container.slots) do
				local stackable = v.components.stackable
				if stackable then
					overstacks = overstacks + math.ceil(stackable:StackSize() / (stackable.originalmaxsize or stackable.maxsize))
					if overstacks >= TUNING.COLLAPSED_CHEST_EXCESS_STACKS_THRESHOLD then
						return true
					end
				end
			end
		end
		return false
	end

	local function regular_fbox_upgrade(inst, caster)	--解构
		if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
			if inst.components.lootdropper ~= nil then
				inst.components.lootdropper:SpawnLootPrefab("alterguardianhatshard")	--返还启迪碎片
			end
		end

		if regular_SCStoreroom(inst) then
			inst.components.container:DropEverythingUpToMaxStacks(TUNING.COLLAPSED_CHEST_MAX_EXCESS_STACKS_DROPS)
		end

		--fallback to default
		inst.no_delete_on_deconstruct = nil
	end

	for i, v in pairs(CBOX_UPGRADE) do
		AddPrefabPostInit(v, function(inst)
			if not TheWorld.ismastersim then
				return inst
			end
			
			if not inst.components.named then
				inst:AddComponent("named")
			end
			
			local upgradeable = inst:AddComponent("upgradeable")	--弹性升级组件
			upgradeable.upgradetype = UPGRADETYPES.CHEST
			upgradeable:SetOnUpgradeFn(OnUpgrade_fbox_upgrade)
			inst:ListenForEvent("ondeconstructstructure", regular_fbox_upgrade)	--监听解构
			
			if inst.components.container then
				inst.components.container.ignoreoverstacked = true	--添加这个可以禁用堆叠检查，这样就可以整理了
			end
			
			inst.OnLoad = OnLoad_fbox_upgrade
		end)
	end
end