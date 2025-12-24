GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

PrefabFiles = {
	"storeroom",
}

Assets =
{
	Asset("ATLAS", "minimap/storeroom.xml" ),
	Asset("ATLAS", "images/inventoryimages/storeroom.xml"),
	Asset("IMAGE", "images/inventoryimages/storeroom.tex"),
}

AddMinimapAtlas("minimap/storeroom.xml")

_G = GLOBAL
STRINGS = _G.STRINGS
RECIPETABS = _G.RECIPETABS
Recipe = _G.Recipe
Ingredient = _G.Ingredient
TECH = _G.TECH
TUNING = _G.TUNING
local Vector3 = GLOBAL.Vector3
local containers = require("containers")
local sr_fresh = GetModConfigData("srfresh")
local FreshnessUp = GetModConfigData("FreshnessUp")

local STOREROOM = {}
STOREROOM.DEBUG = true
STOREROOM.CRAFT = GetModConfigData("Craft")
STOREROOM.SLOTS = GetModConfigData("Slots")
STOREROOM.LANG = GetModConfigData("Language")

TUNING.STOREROOM_DESTROY = GetModConfigData("Destroyable")
storeroom_drag = GetModConfigData("sroom_drag")

local function updaterecipe(slots)
	if STOREROOM.CRAFT == "Easy" then

		cutstone_value = math.floor(slots / 8)
		boards_value = math.floor(slots / 8)
		pigskin_value = math.floor(slots / 20)

	elseif STOREROOM.CRAFT == "Hard" then

		cutstone_value = math.floor(slots / 2.6)
		boards_value = math.floor(slots / 2.6)
		pigskin_value = math.floor(slots / 10)

	else

		cutstone_value = math.floor(slots / 4)
		boards_value = math.floor(slots / 4)
		pigskin_value = math.floor(slots / 20)
	end
end
updaterecipe(STOREROOM.SLOTS)

if sr_fresh ~= false then
	if sr_fresh == "cool" then
		AddPrefabPostInit("storeroom", function(inst)
			inst:AddTag("fridge")	--添加冷冻效果，暖石不冻一下吗？
		end)
	else
		AddPrefabPostInit("storeroom", function(inst)
			local sr_freshup = GetModConfigData("srfresh")
			inst:AddComponent("preserver")
			inst.components.preserver:SetPerishRateMultiplier(sr_freshup);
		end)
		--突破返鲜天数
		if FreshnessUp and type(sr_fresh) == "number" and sr_fresh < 0 
			and not (KnownModIndex:IsModEnabledAny("workshop-2371484058") or KnownModIndex:IsModEnabledAny("workshop-2199027653598529121")) then
			modimport("scripts/storeroomperish.lua")
		end
	end
end

storeroom = AddRecipe2(
    "storeroom", {
        Ingredient("cutstone", cutstone_value),
        Ingredient("pigskin", pigskin_value),
		Ingredient("boards", boards_value),
    }, TECH.SCIENCE_TWO, {
		placer = "storeroom_placer",min_spacing=2.5,--min_spacing建造间距
        atlas = "images/inventoryimages/storeroom.xml", image = "storeroom.tex"
    }, { "CONTAINERS", "STRUCTURES" }
)
storeroom = AddRecipe(
	"storeroom", {
		Ingredient("cutstone", cutstone_value),
		Ingredient("pigskin", pigskin_value),
		Ingredient("boards", boards_value),
	}, RECIPETABS.TOWN, TECH.SCIENCE_TWO , "storeroom_placer", 2.5, nil, nil, nil, "images/inventoryimages/storeroom.xml", "storeroom.tex"
)

--容器默认坐标
local default_pos_sr={
	widgetpos = Vector3(0,210,0),
}

---------------------------------------------------
-- 下列物品整理代码源自 能力勋章Mod ---
local function sroomStr(str1, str2)
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
local function sroomcmp(e, f)
    if e and f then
        --尝试按照 prefab 名字排序
        local prefab_e = tostring(e.prefab)	--e.prefab == ""
        local prefab_f = tostring(f.prefab)
        return sroomStr(prefab_e, prefab_f)
    end
end
--插入法排序函数
local function sroom_sort(list, comp)
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
local function sroomslotsPX(inst)
    if inst and inst.components.container then
        -- 取出容器中的所有物品
        local items = {}
        for k, v in pairs(inst.components.container.slots) do
            local item = inst.components.container:RemoveItemBySlot(k, true)  -- 按格子移除物品
            if item and item:IsValid() then  -- 确保物品实例有效
                table.insert(items, item)  -- 在items表插入被移除出来的item
            end
        end

        -- 对物品进行排序
        sroom_sort(items, sroomcmp)

        -- 重新插入物品，处理堆叠逻辑
        for i = 1, #items do
            local item = items[i]
			if item and item:IsValid() then
				inst.components.container:GiveItem(item)
			end
        end
    end
end
--整理按钮点击函数
local function sroomslotsPXFn(inst, doer)
    if inst.components.container ~= nil then --如果有 container 这个组件，也就是属性
        sroomslotsPX(inst)
    elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
        SendRPCToServer(RPC.DoWidgetButtonAction, nil, inst, nil)
    end
end
--整理按钮亮起规则
local function sroomslotsPXValidFn(inst)
    return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()	-- and not inst:HasTag("storeroom_upgraded")
end
if STOREROOM.LANG == "Ch" then
	STRINGS.srbtn = {zhengli = "整理"}
	STRINGS.srty = {tuoyi = "ALT+右键拖移"}
	STRINGS.srfw = {fuwei = "减号复位"}
else
	STRINGS.srbtn = {zhengli = "SortOut"}
	STRINGS.srty = {tuoyi = "Alt+RMouseDrag UI"}
	STRINGS.srfw = {fuwei = "Minus Reset UI"}
end

--------------------- function --------------------
local function widgetcreation(widgetanimbank, widgetpos, slot_x, slot_y, posslot_x, posslot_y)
	local params = {}
	params.storeroom =
	{
		widget =
		{
			slotpos = {},
			animbank = widgetanimbank,
			animbuild = widgetanimbank,
			animbank_upgraded = widgetanimbank_upgraded,
			animbuild_upgraded = widgetanimbank_upgraded,
			pos = default_pos_sr.widgetpos,
			side_align_tip = 160,
			buttoninfo = {	--整理按钮
				text = STRINGS.srbtn.zhengli,
				position = _G.Vector3(-2,-(slot_y*2+210)+posslot_y,0),
				fn = sroomslotsPXFn,
				validfn = sroomslotsPXValidFn,
			},
			dragtype_sr = "sroom_container"
		},
	type = "chest",
	}

	for y = slot_y, 0, -1 do
		for x = 0, slot_x do
			table.insert(params.storeroom.widget.slotpos, Vector3(80*x-80*2+posslot_x, 80*y-80*2+posslot_y,0))
		end
	end
	
	-------------------------------------------------------------------------
	for k, v in pairs(params) do
		containers.params[k] = v

		--更新容器格子数量的最大值
		containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
	end
	params = nil
	--------------------------------------------------------------------------
end

--------------------- position --------------------
-- local function widgetpostion(slot_x)
	-- if GetModConfigData("Position") == ("Left") then
		-- if STOREROOM.SLOTS == 20 or STOREROOM.SLOTS == 36 then
			-- widgetpos = _G.Vector3(0,210,0)
		-- else
			-- widgetpos = _G.Vector3((slot_x + 1)*-1.4,210,0)
		-- end
	-- elseif GetModConfigData("Position") == ("Center") then
		-- widgetpos = _G.Vector3(0,210,0)
	-- elseif GetModConfigData("Position") == ("Right") then
		-- if STOREROOM.SLOTS == 20 or STOREROOM.SLOTS == 36 then
			-- widgetpos = _G.Vector3(0,210,0)
		-- else
			-- widgetpos = _G.Vector3((slot_x + 1)*1.4,210,0)
		-- end
	-- end
-- end
-- widgetpostion(STOREROOM.SLOTS)

---------------- formation function ---------------
if STOREROOM.SLOTS == 20 then
	widgetanimbank = "ui_storeroom_5x5"
	widgetanimbank_upgraded = "ui_storeroom_5x5_upgraded"
	slot_x = 4
	slot_y = 4
	posslot_x = 0
	posslot_y = 0
elseif STOREROOM.SLOTS == 36 then
	widgetanimbank = "ui_storeroom_6x6"
	widgetanimbank_upgraded = "ui_storeroom_6x6_upgraded"
	slot_x = 5
	slot_y = 5
	posslot_x = -40
	posslot_y = -40
elseif STOREROOM.SLOTS == 40 then
	widgetanimbank = "ui_storeroom_5x8"
	widgetanimbank_upgraded = "ui_storeroom_5x8_upgraded"
	slot_x = 7
	slot_y = 4
	posslot_x = -117
	posslot_y = 0
elseif STOREROOM.SLOTS == 60 then
	widgetanimbank = "ui_storeroom_5x12"
	widgetanimbank_upgraded = "ui_storeroom_5x12_upgraded"
	slot_x = 11
	slot_y = 4
	posslot_x = -280
	posslot_y = 0
elseif STOREROOM.SLOTS == 80 then
	widgetanimbank = "ui_storeroom_5x16"
	widgetanimbank_upgraded = "ui_storeroom_5x16_upgraded"
	slot_x = 15
	slot_y = 4
	posslot_x = -440
	posslot_y = 0
elseif STOREROOM.SLOTS == 120 then
	widgetanimbank = "ui_storeroom_6x20"
	widgetanimbank_upgraded = "ui_storeroom_6x20_upgraded"
	slot_x = 19
	slot_y = 5
	posslot_x = -600
	posslot_y = -40
elseif STOREROOM.SLOTS == 140 then
	widgetanimbank = "ui_storeroom_7x20"
	widgetanimbank_upgraded = "ui_storeroom_7x20_upgraded"
	slot_x = 19
	slot_y = 6
	posslot_x = -600
	posslot_y = -80
else
	widgetanimbank = "ui_storeroom_8x20"
	widgetanimbank_upgraded = "ui_storeroom_8x20_upgraded"
	slot_x = 19
	slot_y = 7
	posslot_x = -600
	posslot_y = -124
end
------------------- call function -----------------
widgetcreation(widgetanimbank, widgetpos, slot_x, slot_y, posslot_x, posslot_y)


---------------------------------------------------------------------------------------------------------
-------------------------------------------容器拖拽，源自能力勋章----------------------------------------
---------------------------------------------------------------------------------------------------------
if storeroom_drag then
local uiloot_sr={}--UI列表，方便重置
--拖拽坐标，局部变量存储，减少io操作
local dragpos_sr={}
--更新同步拖拽坐标(如果容器没打开过，那么存储的坐标信息就没被赋值到dragpos里，这时候直接去存储就会导致之前存储的数据缺失，所以要主动取一下数据存到dragpos里)
local function loadDragPos_sr()
	TheSim:GetPersistentString("sroom_drag_pos", function(load_success_sr, data)
		if load_success_sr and data ~= nil then
            local success_sr, allpos_sr = RunInSandbox(data)
		    if success_sr and allpos_sr then
				for k, v in pairs(allpos_sr) do
					if dragpos_sr[k]==nil then
						dragpos_sr[k]=_G.Vector3(v.x or 0, v.y or 0, v.z or 0)
					end
				end
			end
		end
	end)
end
--存储拖拽后坐标
local function saveDragPos_sr(dragtype_sr,pos)
	if next(dragpos_sr) then
		local str = DataDumper(dragpos_sr, nil, true)
		TheSim:SetPersistentString("sroom_drag_pos", str, false)
	end
end
--获取拖拽坐标
function GetSroomDragPos(dragtype_sr)
	if dragpos_sr[dragtype_sr]==nil then
		loadDragPos_sr()
	end
	return dragpos_sr[dragtype_sr]
end

--设置UI可拖拽
local function MakeSroomDragableUI(self,dragtarget_sr,dragtype_sr,dragdata)
	self.candrag_sr=true--可拖拽标识(防止重复添加拖拽功能)
	uiloot_sr[self]=self:GetPosition()--存储UI默认坐标
	--给拖拽目标添加拖拽提示
	if dragtarget_sr then
		dragtarget_sr:SetTooltip("\n\n"..STRINGS.srty.tuoyi.."\n"..STRINGS.srfw.fuwei)
		local oldOnControl=dragtarget_sr.OnControl
		dragtarget_sr.OnControl = function (self,control, down)
			local parentwidget=self:GetParent()--控制它爹的坐标,而不是它自己
			--按下右键可拖动
			if parentwidget and parentwidget.Passive_OnControl and Input:IsKeyDown(KEY_ALT) then
				parentwidget:Passive_OnControl(control, down)
			--elseif Input:IsKeyDown(KEY_ALT) and Input:IsMouseDown(MOUSEBUTTON_LEFT) then	--RIGHT
			--	ResetSroomUIPos()
			end
			return oldOnControl and oldOnControl(self,control,down)
		end
	end
	
	--被控制(控制状态，是否按下)
	function self:Passive_OnControl(control, down)
		if self.focus and control == CONTROL_SECONDARY then
			if down then
				self:StartDrag()
			else
				self:EndDrag()
			end
		end
	end
	--设置拖拽坐标
	function self:SetDragPosition(x, y, z)
		local pos
		if type(x) == "number" then
			pos = _G.Vector3(x, y, z)
		else
			pos = x
		end
		
		local self_scale=self:GetScale()
		local offset=dragdata and dragdata.drag_offset or 1--偏移修正(容器是0.6)
		local newpos_sr=self.p_startpos+(pos-self.m_startpos)/(self_scale.x/offset)--修正偏移值
		self:SetPosition(newpos_sr)--设定新坐标
	end
	
	--开始拖动
	function self:StartDrag()
		if not self.followhandler then
			local mousepos = TheInput:GetScreenPosition()
			self.m_startpos = mousepos--鼠标初始坐标
			self.p_startpos = self:GetPosition()--面板初始坐标
			self.followhandler = TheInput:AddMoveHandler(function(x,y)
				self:SetDragPosition(x,y,0)
				if not Input:IsKeyDown(KEY_ALT) then
				--if not Input:IsMouseDown(MOUSEBUTTON_RIGHT) then
					self:EndDrag()
				end
			end)
			self:SetDragPosition(mousepos)
		end
	end
	--停止拖动
	function self:EndDrag()
		if self.followhandler then
			self.followhandler:Remove()
		end
		self.followhandler = nil
		self.m_startpos = nil
		self.p_startpos = nil
		local newpos_sr=self:GetPosition()
		if dragtype_sr then
			dragpos_sr[dragtype_sr]=newpos_sr--记录记录拖拽后坐标
		end
		saveDragPos_sr()--存储坐标
	end
end

--给容器添加拖拽功能
	AddClassPostConstruct("widgets/containerwidget", function(self)
		local oldOpen_sr = self.Open
		self.Open = function(self,...)
			oldOpen_sr(self,...)
			if self.container and self.container.replica.container then
				local widget = self.container.replica.container:GetWidget()
				if widget then	
					--拖拽坐标标签，有则用标签，无则用容器名
					local dragname_sr=widget.dragtype_sr
					if dragname_sr then
						--设置可拖拽
						if not self.candrag_sr then
							MakeSroomDragableUI(self,self.bganim,dragname_sr,{drag_offset=0.6})
						end
						--设置容器坐标(可装备的容器第一次打开做个延迟，不然加载游戏进来位置读不到)
						local newpos_sr=GetSroomDragPos(dragname_sr) or default_pos_sr[dragname_sr]
						if newpos_sr then
							if self.container:HasTag("_equippable") and not self.container.isopended then
								self.container:DoTaskInTime(0, function()
									self:SetPosition(newpos_sr)
								end)
								self.container.isopended=true
							else
								self:SetPosition(newpos_sr)
							end
						end
					end
				end
			end
		end
	end)
--重置拖拽坐标
function ResetSroomUIPos()
	dragpos_sr={}
	TheSim:SetPersistentString("sroom_drag_pos", "", false)
	for k, v in pairs(uiloot_sr) do
		if k.inst and k.inst:IsValid() then
			k:SetPosition(v)--重置坐标
		else
			uiloot_sr[k]=nil--失效了的就清掉吧
		end
	end
end

--重置拖拽坐标
function dm_resetui_sr()
	ResetSroomUIPos()
end

local keylist = {	--还以为要适配一下数字键盘-号
	KEY_MINUS,
}
--for h, n in pairs(keylist) do
--if _G.TheInput:IsKeyDown(KEY_RCTRL) then--if Input:IsMouseDown(MOUSEBUTTON_RIGHT) then
_G.TheInput:AddKeyUpHandler(KEY_MINUS, function(key)
	ResetSroomUIPos()
end)
--end
--end

_G.MakeSroomDragableUI=MakeSroomDragableUI--设置UI可拖拽,参数(self,拖拽目标,拖拽标签,拖拽信息)
_G.GetSroomDragPos=GetSroomDragPos--获取拖拽坐标,参数(拖拽标签)
_G.ResetSroomUIPos=ResetSroomUIPos--重置拖拽坐标
end

--------------------- Russian ---------------------
local RegisterRussianName = GLOBAL.rawget(GLOBAL,"RegisterRussianName")
if RegisterRussianName and STOREROOM.LANG == "En" then
	RegisterRussianName("STOREROOM","Кладовая","she","Кладовой")
	STRINGS.RECIPE_DESC.STOREROOM = "Нужно больше места!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Мне очень нравится это большое хранилище!"

--------------------- Finnish ---------------------
-- by NoTC
elseif STOREROOM.LANG == "Fn" then
	STRINGS.NAMES.STOREROOM = "Varasto"
	STRINGS.RECIPE_DESC.STOREROOM = "Tarvitsee enemmän tilaa!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Tykkään tää on mahtava varasto!"

--------------------- French ----------------------
-- by John2022
elseif STOREROOM.LANG == "Fr" then
	STRINGS.NAMES.STOREROOM = "Debarras"
	STRINGS.RECIPE_DESC.STOREROOM = "Besoin de plus d'espace!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "J'apprecie beaucoup le gain de place!"

--------------------- Croatian --------------------
-- by Doge
elseif STOREROOM.LANG == "Cr" then
	STRINGS.NAMES.STOREROOM = "Skladište"
	STRINGS.RECIPE_DESC.STOREROOM = "Treba više mjesta!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Sviđa mi se ovo skladište!"

--------------------- German ----------------------
-- by Ralkari
elseif STOREROOM.LANG == "Gr" then
	STRINGS.NAMES.STOREROOM = "Vorratskammer"
	STRINGS.RECIPE_DESC.STOREROOM = "Brauche mehr Platz!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Ich mag die Vorratskammer!"

--------------------- Traditional Chinese ---------
-- by Oh Deer!
elseif STOREROOM.LANG == "Ch" then
	STRINGS.NAMES.STOREROOM = "储藏室"
	STRINGS.RECIPE_DESC.STOREROOM = "更多的储存空间!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "这是 储藏室(新地窖)！"

--------------------- Polish ----------------------
-- by Hussarya
elseif STOREROOM.LANG == "Pl" then
	STRINGS.NAMES.STOREROOM = "Składzik"
	STRINGS.RECIPE_DESC.STOREROOM = "Więcej miejsca!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Naprawdę uwielbiam ten ogromny składzik!"

--------------------- Portuguese ------------------
-- by mauricioportella
elseif STOREROOM.LANG == "Pr" then
	STRINGS.NAMES.STOREROOM = "Porão"
	STRINGS.RECIPE_DESC.STOREROOM = "Preciso de mais espaço!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "¡Me encanta un montón, es una bodega estupenda!"

--------------------- Spanish ---------------------
-- by MartiniAndres
elseif STOREROOM.LANG == "Sp" then
	STRINGS.NAMES.STOREROOM = "Bodega"
	STRINGS.RECIPE_DESC.STOREROOM = "¡Se necesita más espacio!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "¡Me encanta este gran almacén!"

--------------------- Swedish ---------------------
-- by dLFN
elseif STOREROOM.LANG == "Sw" then
	STRINGS.NAMES.STOREROOM = "Förråd"
	STRINGS.RECIPE_DESC.STOREROOM = "Behöver mer utrymme!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Jag gillar verkligen detta bra föråd!"

--------------------- Turkish ---------------------
-- by DestORoyal
elseif STOREROOM.LANG == "Tr" then
	STRINGS.NAMES.STOREROOM = "Depo"
	STRINGS.RECIPE_DESC.STOREROOM = "Daha fazla alan gerek!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "Bu depoyu gercekten begendim!"

--------------------- English ---------------------
else
	STRINGS.NAMES.STOREROOM = "Storeroom"
	STRINGS.RECIPE_DESC.STOREROOM = "Need more space!"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.STOREROOM = "I really like this is a great storeroom!"
end

--使用以下代码，实现与ShowMe联动容器高亮。
--优先级高于 ShowMe
TUNING.MONITOR_CHESTS = TUNING.MONITOR_CHESTS or {}
TUNING.MONITOR_CHESTS.storeroom = true

--优先级低于 ShowMe		--来自 风铃草 —— 穹妹
for k, m in pairs(ModManager.mods) do
	if m and _G.rawget(m, "SHOWME_STRINGS") then
		if m.postinitfns and m.postinitfns.PrefabPostInit and m.postinitfns.PrefabPostInit.treasurechest then
			m.postinitfns.PrefabPostInit.storeroom = m.postinitfns.PrefabPostInit.treasurechest
		end
		break
	end
end

---------------------------------------------------
---------------------- DEBUG ----------------------
---------------------------------------------------

-- if STOREROOM.DEBUG then
	-- print("--- STOREROOM DEBUG ---")
	-- print("slots = " .. STOREROOM.SLOTS)
	-- print("recipe: cutstone = " .. cutstone_value .. " pigskin = " .. pigskin_value .. " boards = " ..  boards_value)
	-- print("widget: widgetanimbank = " .. widgetanimbank .. " widgetpos = ", widgetpos, " slot_x = " .. slot_x .. " slot_y = " .. slot_y .. " posslot_x = " .. posslot_x .. " posslot_y = " .. posslot_y)
-- end