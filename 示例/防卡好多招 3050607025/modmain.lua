local TheNet = GLOBAL.TheNet
local TheSim = GLOBAL.TheSim
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

local LAN_ = GetModConfigData("CH_LANG")
if LAN_ then
	require 'lang/strings_cn'
	TUNING.BYmoonlang = "cn"
else
	require 'lang/strings_en'
	TUNING.BYmoonlang = "en"
end

--检测其他mod是否启用
local function isModEnabled(modName)
    local moddir = GLOBAL.KnownModIndex:GetModsToLoad()
    for _, dir in pairs(moddir) do
        if dir == modName then
            return true
        end
    end
    return false
end

-- 是否开启了更多物品堆叠mod
local more_item_stack_enable = isModEnabled("workshop-3007715893") or isModEnabled("workshop-2199027653598544262")

-- 若开启了更多物品堆叠mod，则此项功能禁用
if not more_item_stack_enable then 
	-- 堆叠数值设置
	local stack_size = GetModConfigData("STACK_SIZE")
	if stack_size ~= 0 then
		modimport("scripts/more_stack_size.lua")
	end
end


if IsServer == false then
	return
end

-- 自动堆叠
if GetModConfigData("AUTO_STACK") then
	modimport("scripts/auto_stack.lua")
end 

-- 若开启了更多物品堆叠mod，则此项功能禁用
if not more_item_stack_enable then 
	-- 更多物品堆叠
	if GetModConfigData("STACK_OTHER_OBJECTS") ~= "OFF" then
		modimport("scripts/more_stack_item.lua")
	end
end
	
-- 自动清理
modimport("scripts/auto_clean.lua")

-- 批量交易
if GetModConfigData("BATCH_TRADE") then
	modimport("scripts/batch_trade.lua")
end 

--4月1号2024
--去除树木循环生长
-- 是否单独开启了去除树木循环生长mod
local no_regrowth_enable = isModEnabled("workshop-3210773634") or isModEnabled("workshop-2199027653598545056")
if GetModConfigData("TREES_NO_REGROWTH") and not no_regrowth_enable then
	modimport("scripts/stop_regrowth.lua")
end 

--多枝树变小树苗
if GetModConfigData("TWIGGY") then
	modimport("scripts/twiggy.lua")
end

--伐树无根
if GetModConfigData("TREES_NO_STUMP") then
	modimport("scripts/no_stump.lua")
end

--冬季盛宴
if GetModConfigData("WINTER_ORNAMENT") then
	modimport("scripts/winter_ornament.lua")
end