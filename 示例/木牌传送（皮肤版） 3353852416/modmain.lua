
-- 查值时自动查global,增加global的变量或者修改global的变量时还是需要带GLOBAL.
GLOBAL.setmetatable(env,{__index = function(t, k)return GLOBAL.rawget(GLOBAL,k)end,})

local LAN_CN = GetModConfigData("CH_LANG")
if LAN_CN then
	require 'lang/nana_teleport_cn'
else
	require 'lang/nana_teleport_en'
end

-- local require = GLOBAL.require
local SkinTravelScreen = require "screens/skintravelscreen"


Assets = {}
local assets_list =  --制作栏图标和物品栏图标(含皮肤)
{
    "teleportation",        --物品名
	"t1", 	--skin name
	"t2",
	"t3",
	"t4",
	"t5",
	"t6",
	"t7",
	"t8",
	"t9",
	"t10",
   }
for k,v in pairs (assets_list) do
    table.insert(Assets, Asset( "IMAGE", "images/inventoryimages/"..v..".tex" ))
    table.insert(Assets, Asset( "ATLAS", "images/inventoryimages/"..v..".xml" ))
end

PrefabFiles = 
{
   "skintravelable_classified", --传送功能文件
   "teleportation", --传送木牌
  
}

-- 预制物声明
modimport("scripts/skin/nana_skin_list.lua")
modimport("scripts/skin/lantu.lua")

AddMinimapAtlas("images/inventoryimages/teleportation.xml")


-- 注册配方
AddRecipe2("teleportation",{Ingredient("boards", 1)},
	TECH.SCIENCE_ONE,      
	{
	   atlas = "images/inventoryimages/teleportation.xml",
	   image = "teleportation.tex",
	   placer = "teleportation_placer",    --放置虚影
	   min_spacing = 1,             --建筑最小建造间距
	},
	{"LIGHT","DECOR","STRUCTURES","MODS"}
)

local writeables = require("writeables")

local layouttable = {
    prompt = "", -- Unused
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -70, 0),

    cancelbtn = {
        text = STRINGS.BEEFALONAMING.MENU.CANCEL,
        cb = nil,
        control = CONTROL_CANCEL
    },
    acceptbtn = {
        text = STRINGS.BEEFALONAMING.MENU.ACCEPT,
        cb = nil,
        control = CONTROL_ACCEPT
    },
}

writeables.AddLayout("teleportation", layouttable)

-- mod配置参数
local ArrowsignEnable = GetModConfigData("ArrowsignEnable")
local HomesignEnable = GetModConfigData("HomesignEnable")
local Ownership = GetModConfigData("Ownership")
local LIGHT_ENABLE = GetModConfigData("LightEnable")
local RESURRECT_ENABLE = GetModConfigData("ResurrectEnable")
GLOBAL.TRAVEL_HUNGER_COST = GetModConfigData("HungerCost")
GLOBAL.TRAVEL_SANITY_COST = GetModConfigData("SanityCost")
GLOBAL.TRAVEL_COUNTDOWN_ENABLE = GetModConfigData("CountdownEnable")--延时传送
GLOBAL.TRAVEL_TEXT_ENABLE = GetModConfigData("TextEnable")--显示木牌文字

--  小木牌相关功能。添加传送、灯光、作祟复活功能等
local FT_Points = {"teleportation"}
if ArrowsignEnable then table.insert(FT_Points, "arrowsign_post") end
if HomesignEnable  then table.insert(FT_Points, "homesign")       end

AddReplicableComponent("skintravelable")

for k, v in pairs(FT_Points) do
    AddPrefabPostInit(v, function(inst)
        inst:AddComponent("talker")
        inst:AddTag("_skintravelable")
		if LIGHT_ENABLE then 
		   inst.entity:AddLight()                               --添加发光组件
		   inst.Light:Enable(false)                             --默认关
		   inst.Light:SetRadius(1*1)                            --发光范围:半径3格地皮
		   inst.Light:SetFalloff(0.6)                           --衰减
		   inst.Light:SetIntensity(0.85)                        --强度
		   --inst.Light:SetColour(0.88, 1, 1)                   --浅灰se
		   inst.Light:SetColour(255 / 255, 175 / 255, 0 / 255)  --浅灰se
		   inst.Light:EnableClientModulation(false)             --不读取客户端的本地设置
		end
		
		if not TheWorld.ismastersim then                --主客机判定:下边的代码为主机独占,上方为主客机共用
			return inst
	    end

        inst:RemoveTag("_skintravelable")
        inst:AddComponent("skintravelable")
        inst.components.skintravelable.ownership = Ownership
		if LIGHT_ENABLE then
			local function AutoLight(inst, phase)             --自动灯光
			   if phase == "night" then
				  inst.AnimState:PlayAnimation("idle")
				  inst.Light:Enable(true)                       --夜晚发光
			   else
				  inst.AnimState:PlayAnimation("idle")
				  inst.Light:Enable(false)                      --其余时间关闭
			   end
			end
			inst:WatchWorldState("phase", AutoLight)          --自动灯光
			AutoLight(inst, TheWorld.state.phase)
		end
		if RESURRECT_ENABLE then
			local function OnHaunt(inst, haunter)
				if haunter:HasTag("playerghost") then
					haunter:PushEvent("respawnfromghost")

					-- 在玩家位置生成光源
					haunter:DoTaskInTime(FRAMES * 70, function()
						local x, y, z = haunter.Transform:GetWorldPosition()
						SpawnPrefab("spawnlight_multiplayer").Transform:SetPosition(x, y, z)
					end)
					if haunter.net_travel_respawn_light then
						haunter.net_travel_respawn_light:set(true)
					end
					return true
				end
				return false
			end
			inst:AddComponent("hauntable")                       --可闹鬼的,复活用
			inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_TINY
			inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
			inst.components.hauntable:SetOnHauntFn(OnHaunt)
		end
    end)
end


-- Mod RPC ------------------------------

AddModRPCHandler("FastSkinTravel", "SkinTravel", function(player, inst, index)
    local skintravelable = inst.components.skintravelable
    if skintravelable ~= nil then skintravelable:SkinTravel(player, index) end
end)

-- PlayerHud UI -------------------------

AddClassPostConstruct("screens/playerhud", function(self, anim, owner)
    self.ShowSkinTravelScreen = function(_, attach)
        if attach == nil then
            return
        else
            self.skintravelscreen = SkinTravelScreen(self.owner, attach)
            self:OpenScreenUnderPause(self.skintravelscreen)
            return self.skintravelscreen
        end
    end

    self.CloseSkinTravelScreen = function(_)
        if self.skintravelscreen then
            self.skintravelscreen:Close()
            self.skintravelscreen = nil
        end
    end
end)

-- Actions ------------------------------

AddAction("SKIN_DESTINATION_UI", STRINGS.NANA_TELEPORT_DESTINATIONS, function(act)
    if act.doer ~= nil and act.target ~= nil and act.doer:HasTag("player") and
        act.target.components.skintravelable and not act.target:HasTag("burnt") and
        not act.target:HasTag("fire") then
        act.target.components.skintravelable:BeginSkinTravel(act.doer)
        return true
    end
end)
GLOBAL.ACTIONS.SKIN_DESTINATION_UI.priority = 1

-- Component actions ---------------------

AddComponentAction("SCENE", "skintravelable", function(inst, doer, actions, right)
    if right then
        if not inst:HasTag("burnt") and not inst:HasTag("fire") then
            table.insert(actions, GLOBAL.ACTIONS.SKIN_DESTINATION_UI)
        end
    end
end)

-- Stategraph ----------------------------

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.SKIN_DESTINATION_UI, "give"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.SKIN_DESTINATION_UI, "give"))


AddPrefabPostInit("reskin_tool", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    local oldSpellFn = inst.components.spellcaster.spell
    inst.components.spellcaster.spell = function(inst, target, pos, doer)
        oldSpellFn( inst, target, pos, doer)
        if target ~= nil then
            target:DoTaskInTime(FRAMES, function()
                target:PushEvent("reskinned")
            end)
        end
    end
end)