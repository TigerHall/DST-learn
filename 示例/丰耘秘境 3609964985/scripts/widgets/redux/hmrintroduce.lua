local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local Spinner = require "widgets/spinner"
local TEMPLATES = require "widgets/redux/templates"
local TrueScrollArea = require "widgets/truescrollarea"
local ScrollableList = require "widgets/scrollablelist"

local INTRODUCE_DATA = require "hmrmain/hmr_introduce_data"

require("util")

local FILTER_ALL = "ALL"

local FILLER = "zzzzzzz"
local UNKNOWN = "unknown"

local ICON_SIZE = 40
local BADGE_SIZE = 35
local INGREDIENT_SIZE = 40

-- parts图标
local PART_ICONBG_COLORS = {
	default = {1, 1, 1, 1},
	honor = {173/255, 216/255, 223/255, 1},
	terror = {173/255, 216/255, 230/255, 1},
	hmr = {255/255, 255/255, 240/255, 1},
	tech = {220/255, 220/255, 220/255, 1},
	cooking = {255/255, 182/255, 193/255, 1},
	food = {244/255, 224/255, 214/255, 1},
	tool = {222/255, 184/255, 135/255, 1},
	weapon = {255/255, 165/255, 0/255, 1},
	structure = {211/255, 211/255, 211/255, 1},
	armor = {240/255, 230/255, 140/255, 1},
	waterproofer = {173/255, 216/255, 223/255, 1},
	watersource = {173/255, 216/255, 223/255, 1},
	icebox = {200/255, 200/255, 211/255, 1},
	heater = {255/255, 204/255, 153/255, 1},
	container = {245/255, 245/255, 230/255, 1},
	gift = {255/255, 204/255, 153/255, 1},
	repair = {250/255, 218/255, 94/255, 1},
	setbonus = {230/255, 230/255, 250/255, 1},
	skill = {230/255, 230/255, 230/255, 1},
	buff = {238/255, 130/255, 238/255, 1},
}
local PART_ICON_MAP = {
	default = "hmr",
	honor = "honor",
	terror = "terror",
	hmr = "hmr",
	tech = "tech",
	cooking = "cooking",
	food = "food",
	tool = "tool",
	weapon = "weapon",
	structure = "structure",
	armor = "armor",
	waterproofer = "waterproofer",
	watersource = "watersource",
	icebox = "icebox",
	heater = "heater",
	container = "container",
	gift = "gift",
	repair = "repair",
	setbonus = "setbonus",
	skill = "skill",
	buff = "buff",
}
local PART_ICON_ATLAS = "images/widgetimages/hmr_introduce_icons.xml"
local PART_ICON_DATA = {}
for k, v in pairs(PART_ICON_MAP) do
	PART_ICON_DATA[k] = {
		atlas = PART_ICON_ATLAS,
		tex = v..".tex",
		color = PART_ICONBG_COLORS[v],
	}
end

local DESC_TEXT_COLOR = {205/255, 170/255, 125/255, 1}
-- UICOLOURS.GOLD_FOCUS
-- UICOLOURS.EGGSHELL

local PANEL_WIDTH = 1000
local PANEL_HEIGHT = 530
local SEARCH_BOX_HEIGHT = 40
local SEARCH_BOX_WIDTH = 300

local TECH_ICONS = {
	SCIENCE1 = {atlas = "images/crafting_menu_icons.xml", tex = "station_science.tex"},-- 科学1
	SCIENCE2 = {atlas = "images/crafting_menu_icons.xml", tex = "station_science.tex"},-- 科学2
	MAGIC2 = {atlas = "images/crafting_menu_icons.xml", tex = "station_arcane.tex"},	-- 魔法1
	MAGIC3 = {atlas = "images/crafting_menu_icons.xml", tex = "station_arcane.tex"},	-- 魔法2
	TERROR_TECH1 = {atlas = "images/crafting_menu_icons.xml", tex = "station_madscience_lab.tex"},-- 凶险科技
	HONOR_TECH1 = {atlas = "images/crafting_menu_icons.xml", tex = "station_madscience_lab.tex"},-- 辉煌科技
	HMR_TECH1 = {atlas = "images/crafting_menu_icons.xml", tex = "station_madscience_lab.tex"},-- 丰耘科技
}

local BADGE_ICONS = {
	health = {atlas = "images/crafting_menu_icons.xml", tex = "station_science.tex"},
	sanity = {atlas = "images/crafting_menu_icons.xml", tex = "station_science.tex"},
	hunger = {atlas = "images/crafting_menu_icons.xml", tex = "station_science.tex"},
}

local FILTERS = {
	"all",
	"equipment",
	"structure",
	"material",
	"farmplant",
	"spice",
	"food",
	"plant",
	"creature",
	"boss",
	"character",
	"terrain",
	"buff",
	"event",
	"bonus",
}

-- 装饰
local function Decor(x, y, scaledata, imagedata)
	local decor = Image(imagedata and imagedata.atlas or "images/quagmire_recipebook.xml", imagedata and imagedata.tex or "quagmire_recipe_line.tex")
	if scaledata and type(scaledata) == "table" then
		if scaledata.x and scaledata.y then
			decor:SetScale(scaledata.x, scaledata.y)
		elseif scaledata.w and scaledata.h then
			decor:ScaleToSize(scaledata.w, scaledata.h)
		end
	end
	decor:SetPosition(x, y)
	return decor
end

-------------------------------------------------------------------------------------------------------

local HMRIntroduce = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "HMRIntroduce")

    self.root = self:AddChild(Widget("HMRIntroduceRoot"))

	self:MakeFrame()
end)

function HMRIntroduce:MakeFrame()
	local left_x, left_y = - 250, - 100
	self.gridroot = self.root:AddChild(Widget("HMRIntroduceGridRoot"))
    self.gridroot:SetPosition(left_x, left_y)

    self.current_view_data = self:CollectType(INTRODUCE_DATA)

    self.item_grid = self.gridroot:AddChild( self:BuildRecipeGrid() )
    self.item_grid:SetPosition(0, 0)
    self.item_grid:SetItemsData(self.current_view_data)

	-- 左侧网格内容上下的两个line
	local grid_w, grid_h = self.item_grid:GetScrollRegionSize()
	local boarder_scale = 0.75
	local grid_boarder = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line.tex"))
	grid_boarder:SetScale(boarder_scale, boarder_scale)
	grid_boarder:SetPosition(left_x, grid_h/2 + 7 + left_y)
	grid_boarder = self.root:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_line.tex"))
	grid_boarder:SetScale(boarder_scale, -boarder_scale)
	grid_boarder:SetPosition(left_x, -grid_h/2 - 7 + left_y)


	self:BuildTopBar()

	-- 右侧详情内容
    self.detailsroot = self:AddChild(Widget("detailsroot"))
    self.detailsroot:SetPosition(40, -320)
    self.details = self.detailsroot:AddChild(self:PopulateInfoPanel("honor_machine"))
end

function HMRIntroduce:GetData(name)
	for _, data in pairs(INTRODUCE_DATA) do
		if data.name == name then
			return data
		end
	end
	return nil
end

local function MakeDetailPart(height, y)
	-- y 是中间的，height是高度
	height = math.abs(height)
	local width = 400
	local top_offset = 40
	local bottom_offset = 20

	local root = Widget("root")
	local top = root:AddChild(Image("images/widgetimages/hmr_introduce.xml", "details_bg_top.tex"))
	local tw, th = top:GetScaledSize()
	top:ScaleToSize(width, th)
	top:SetPosition(0, height/2 - th/2 + top_offset)

	local bottom = root:AddChild(Image("images/widgetimages/hmr_introduce.xml", "details_bg_bottom.tex"))
	local bw, bh = bottom:GetScaledSize()
	bottom:ScaleToSize(width, bh)
	bottom:SetPosition(0, - height/2 + bh/2 - bottom_offset)

	local body = root:AddChild(Image("images/widgetimages/hmr_introduce.xml", "details_bg_body.tex"))
	local mw, mh = body:GetScaledSize()
	body:SetPosition(0, bh/2 - th/2 + (top_offset - bottom_offset) / 2)
	body:ScaleToSize(width, height - th - bh + top_offset + bottom_offset)

	return root
end

function HMRIntroduce:PopulateInfoPanel(data)
    if data ~= nil and type(data) == "string" then
        data = self:GetData(data)
    end

    if data == nil then
        return
    end

    self.details_name = data.name

	local top = 450

	local pageroot = Widget("pageroot")

	local y = top  -- 整体长度

	local image_size = 110

	local title_font_size = 34
    local subtitle_font_size = 28
	local body_font_size = 20 	-- 16
	local value_title_font_size = 18
	local value_body_font_size = 16

    ------------------------------------------------------------------------
    ---[[标题]]
    ------------------------------------------------------------------------
	-- 标题
	y = y - title_font_size/2
    local title_text = data.details and data.details.title or data.name and STRINGS.NAMES[string.upper(data.name)] or ""
    local title_colour = data.details and data.details.title_colour or UICOLOURS.BROWN_DARK
    local title_font = data.details and data.details.title_font or HEADERFONT
	local title = pageroot:AddChild(Text(title_font, title_font_size, title_text, title_colour))
	title:SetPosition(0, y)
	y = y - title_font_size/2 - 4
    -- 副标题
    if data.details and data.details.subtitle then
        y = y - subtitle_font_size/2
        local subtitle_text = data.details.subtitle
        local subtitle_colour = data.details.subtitle_colour or UICOLOURS.BROWN_DARK
        local subtitle_font = data.details.subtitle_font or HEADERFONT
        local subtitle = pageroot:AddChild(Text(subtitle_font, subtitle_font_size, subtitle_text, subtitle_colour))
        subtitle:SetPosition(0, y)
        y = y - subtitle_font_size/2 - 4
    end
	-- 标题下的纹理
	pageroot:AddChild(Decor(0, y-10, {x = -.55, y = .55}, {tex = "quagmire_recipe_line_break.tex"}))
	y = y - 50

    ------------------------------------------------------------------------
    ---[[动画]]
    ------------------------------------------------------------------------
    if data.details and data.details.anim_widget then
        local uianim_root = pageroot:AddChild(Widget("uianim_root"))

        local build, bank, anim = data.details.anim_widget.build, data.details.anim_widget.bank, data.details.anim_widget.anim
        local uianim = uianim_root:AddChild(UIAnim())
        uianim:GetAnimState():SetBank(bank)
        uianim:GetAnimState():SetBuild(build)
        uianim:GetAnimState():PlayAnimation(anim, true)
        uianim:SetScale(0.3)

        local initfn = data.details.anim_widget.initfn
        if initfn then
            initfn(uianim)
        end

        -- 控制纵轴位置
        local anim_width, anim_height = uianim:GetBoundingBoxSize()
		anim_width = math.clamp(anim_width, 50, 400)
		anim_height = math.clamp(anim_height, 50, 400)
        local anim_pos = data.details.anim_widget.pos or Vector3(0, -anim_height/5, 0)
		if data.details.anim_widget.size then
			anim_height = anim_height * data.details.anim_widget.size.h
			anim_width = anim_width * data.details.anim_widget.size.w
		else
			anim_height = anim_height * 0.7
			anim_width = anim_width * 0.7
		end
        y = y - anim_height/2 - 10
        uianim_root:SetPosition(0 + anim_pos.x, 0 + y + anim_pos.y)
		uianim_root:AddChild(Decor(- anim_width / 2, anim_height / 2 - anim_pos.y, {x = .4, y = -.4}, {tex = "quagmire_recipe_corner_decoration.tex"}))
		uianim_root:AddChild(Decor(  anim_width / 2, - anim_height / 2 - anim_pos.y, {x = -.4, y = .4}, {tex = "quagmire_recipe_corner_decoration.tex"}))
        y = y - anim_height/2 - 50
    end

	------------------------------------------------------------------------
    ---[[配方]]
    ------------------------------------------------------------------------
	y = y - 20
	local recipe_sidedecor_size = 30
	local recipe = data.details and data.details.recipe_widget and AllRecipes[data.details.recipe_widget.recipe] or data.name and AllRecipes[data.name] or nil
	local reciperoot = pageroot:AddChild(Widget("reciperoot"))
	if recipe and IsRecipeValid(recipe.name) then
		-- 配方标题
		local recipe_title = reciperoot:AddChild(Text(HEADERFONT, 25, "配方", UICOLOURS.BROWN_DARK))
		recipe_title:SetPosition(0, y)
		y = y - 20
		reciperoot:AddChild(Decor(0, y, {}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))
		y = y - 40

		y = y - 30
		-- 制作数量
		local display_num = (recipe.numtogive and recipe.numtogive > 1) or (data.details and data.details.recipe_widget and data.details.recipe_widget.numtogive) or true
		if display_num then
			local x_offset = 100
			local numtogive = data.details and data.details.recipe_widget and data.details.recipe_widget.numtogive or recipe.numtogive

			-- 物品图片
			local inv_image_bg = reciperoot:AddChild(Image("images/plantregistry.xml", "plant_entry_focus.tex"))
			inv_image_bg:ScaleToSize(INGREDIENT_SIZE, INGREDIENT_SIZE)
			inv_image_bg:SetPosition(x_offset - 25, y)
			inv_image_bg:SetHoverText(STRINGS.HMR.HMR_INFO_PANEL.UI.CRAFT_AMOUNT.."："..numtogive, {offset_y = - INGREDIENT_SIZE/2 - 30})

			local inv_image = reciperoot:AddChild(Image(recipe:GetAtlas(), recipe.imagefn ~= nil and recipe.imagefn() or recipe.image))
			inv_image:ScaleToSize(INGREDIENT_SIZE - 5, INGREDIENT_SIZE - 5)
			inv_image:SetPosition(x_offset - 25, y)
			inv_image:SetClickable(false)

			-- 制作数量
			local inv_amount_decor_left = reciperoot:AddChild(Decor(x_offset, y - INGREDIENT_SIZE / 2 - 9, {w = 25, h = 25}, {atlas = "images/plantregistry.xml", tex = "arrow2_right_over.tex"}))
			local inv_amount_decor_right = reciperoot:AddChild(Decor(x_offset + INGREDIENT_SIZE - 25, y - INGREDIENT_SIZE / 2 - 9, {w = 25, h = 25}, {atlas = "images/plantregistry.xml", tex = "arrow2_left_over.tex"}))

			local inv_amount = reciperoot:AddChild(Text(HEADERFONT, 15, numtogive or "1", UICOLOURS.GOLD_SELECTED))
			inv_amount:SetPosition(x_offset + 25, y)
			local amount_width, amount_height = inv_amount:GetRegionSize()
			inv_amount_decor_left:SetPosition(x_offset - amount_width / 2 - 15 + 25, y)
			inv_amount_decor_right:SetPosition(x_offset + amount_width / 2 + 15 + 25, y)

			local amount_text = reciperoot:AddChild(Text(HEADERFONT, 20, STRINGS.HMR.HMR_INFO_PANEL.UI.CRAFT_AMOUNT, UICOLOURS.GOLD_SELECTED))
			amount_text:SetPosition(x_offset, y - INGREDIENT_SIZE / 2 - 20)

			reciperoot:AddChild(Decor(x_offset, y - INGREDIENT_SIZE / 2 - 9, {x = .8, y = .8}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))
		end

		-- 科技
		if recipe.level ~= nil then
			local tech = "NONE"
			for tech_name, tech_level in pairs(recipe.level) do
				if tech_level >= 1 then
					tech = tech_name..tech_level
					break
				end
			end

			local x_offset = display_num and -100 or 0

			-- 科技icon
			local tech_image = reciperoot:AddChild(ImageButton(TECH_ICONS[tech] and TECH_ICONS[tech].atlas or "images/crafting_menu_icons.xml", TECH_ICONS[tech] and TECH_ICONS[tech].tex or "station_madscience_lab.tex"))
			tech_image:ForceImageSize(ICON_SIZE, ICON_SIZE)
			tech_image.scale_on_focus = false
			tech_image:SetPosition(-30 + x_offset, y)
			tech_image:SetHoverText(tech and STRINGS.HMR.HMR_INFO_PANEL.TECHNAMES[tech] or STRINGS.HMR.HMR_INFO_PANEL.TECHNAMES.UNKNOWN, {offset_y = - ICON_SIZE/2 - 30})
			tech_image:SetFocusSound("dontstarve/HUD/click_mouseover")
			tech_image:SetOnClick(function()
				local PROTOTYPERS = {
					HONOR_TECH = "honor_machine",
					-- TERROR_TECH = "terror_machine",
					-- HMR_TECH = "hmr_machine",
				}
				if PROTOTYPERS[tech] then
					self.detailsroot:KillAllChildren()
					self.details = nil
					self.details = self.detailsroot:AddChild(self:PopulateInfoPanel(PROTOTYPERS[tech]))
				end
			end)

			-- 科技文本
			local tech_string = tech and STRINGS.HMR.HMR_INFO_PANEL.TECHNAMES[tech] or STRINGS.HMR.HMR_INFO_PANEL.TECHNAMES.UNKNOWN
			local tech_colour = data.details and data.details.recipe_widget and data.details.recipe_widget.tech_colour or DESC_TEXT_COLOR
			local tech_desc_text = reciperoot:AddChild(Text(HEADERFONT, 20, tech_string, tech_colour))
			tech_desc_text:SetPosition(30 + x_offset, y)

			local tech_text = reciperoot:AddChild(Text(HEADERFONT, 20, STRINGS.HMR.HMR_INFO_PANEL.UI.NEED_TECH, UICOLOURS.GOLD_SELECTED))
			tech_text:SetPosition(x_offset, y - INGREDIENT_SIZE / 2 - 20)

			reciperoot:AddChild(Decor(x_offset, y - INGREDIENT_SIZE / 2 - 9, {x = .8, y = .8}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))
		end
		y = y - 50

		-- 配方表
		y = y - 40
		local ingredients = recipe.ingredients or {}
		if recipe.character_ingredients ~= nil then
			for k, v in pairs(recipe.character_ingredients) do
				table.insert(ingredients, v)
			end
		end
		if recipe.tech_ingredients ~= nil then
			for k, v in pairs(recipe.tech_ingredients) do
				table.insert(ingredients, v)
			end
		end

		local ingredient_num = #ingredients
		local ingredient_interval = 5
		local ingredient_count = 0
		local total_width = (ingredient_num - 1) * (INGREDIENT_SIZE + ingredient_interval) + INGREDIENT_SIZE
		local start_offset = -total_width / 2 + INGREDIENT_SIZE / 2
		reciperoot.sidedecor1 = reciperoot:AddChild(Decor(-total_width / 2 - recipe_sidedecor_size / 2 - 10, y, {w = recipe_sidedecor_size, h = recipe_sidedecor_size}, {atlas = "images/crafting_menu_icons.xml", tex = "filter_science.tex"}))
		reciperoot.sidedecor1:SetTint(unpack(UICOLOURS.GOLD_SELECTED))
		reciperoot.sidedecor2 = reciperoot:AddChild(Decor(total_width / 2 + recipe_sidedecor_size / 2 + 10, y, {w = recipe_sidedecor_size, h = recipe_sidedecor_size}, {atlas = "images/crafting_menu_icons.xml", tex = "filter_science.tex"}))
		reciperoot.sidedecor2:SetTint(unpack(UICOLOURS.GOLD_SELECTED))
		for k, v in pairs(ingredients) do
			local x_offset = start_offset + (INGREDIENT_SIZE + ingredient_interval) * ingredient_count

			local inv_image_bg = reciperoot:AddChild(ImageButton("images/plantregistry.xml", "plant_entry_focus.tex"))
			inv_image_bg:ForceImageSize(INGREDIENT_SIZE, INGREDIENT_SIZE)
			inv_image_bg.scale_on_focus = false
			inv_image_bg:SetPosition(x_offset, y)
			inv_image_bg:SetHoverText(STRINGS.NAMES[string.upper(v.type)], {offset_y = - INGREDIENT_SIZE/2 - 30})
			inv_image_bg:SetFocusSound("dontstarve/HUD/click_mouseover")
			inv_image_bg:SetOnClick(function()
				if INTRODUCE_DATA[v.type] then
					self.detailsroot:KillAllChildren()
					self.details = nil
					self.details = self.detailsroot:AddChild(self:PopulateInfoPanel(v.type))
				end
			end)

			local inv_image = reciperoot:AddChild(Image(v:GetAtlas(), v:GetImage()))
			inv_image:ScaleToSize(INGREDIENT_SIZE - 5, INGREDIENT_SIZE - 5)
			inv_image:SetPosition(x_offset, y)
			inv_image:SetClickable(false)

			local inv_amount_bg = reciperoot:AddChild(Image("images/global_redux.xml", "value_gold.tex"))
			inv_amount_bg:ScaleToSize(INGREDIENT_SIZE, -18)
			inv_amount_bg:SetPosition(x_offset, y - INGREDIENT_SIZE/2 - 9)

			local inv_amount = reciperoot:AddChild(Text(HEADERFONT, 15, v.amount or "", UICOLOURS.BROWN_DARK))
			inv_amount:SetPosition(x_offset, y - INGREDIENT_SIZE/2 - 9)

			ingredient_count = ingredient_count + 1
		end
		y = y - 20
		local ingredient_text = reciperoot:AddChild(Text(HEADERFONT, 20, "需要材料", UICOLOURS.GOLD_SELECTED))
		ingredient_text:SetPosition(0, y - INGREDIENT_SIZE / 2 - 20)
		reciperoot:AddChild(Decor(0, y - INGREDIENT_SIZE / 2 - 9, {w = total_width, h = 16}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))
		y = y - 50

		-- 配方描述
		if data.details and data.details.recipe_widget and data.details.recipe_widget.desc then
			y = y - 20
			local recipe_desc = reciperoot:AddChild(Text(HEADERFONT, 20, "", DESC_TEXT_COLOR))
			recipe_desc:SetMultilineTruncatedString(data.details.recipe_widget.desc or "", 50, 300)
			local msg_w, msg_h = recipe_desc:GetRegionSize()
			y = y - msg_h/2
			recipe_desc:SetPosition(0, y)
			y = y - msg_h/2
		end
	else
		local recipe_title = reciperoot:AddChild(Text(HEADERFONT, 25, STRINGS.HMR.HMR_INFO_PANEL.UI.NO_RECIPE, UICOLOURS.BROWN_DARK))
		recipe_title:SetPosition(0, y)
		y = y - 20
		reciperoot:AddChild(Decor(0, y, {}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))

		y = y - 40
		local recipe_source_text = data.details and data.details.recipe_widget and data.details.recipe_widget.source or STRINGS.HMR.HMR_INFO_PANEL.UI.SOURCE_UNKNOWN
		local recipe_source = reciperoot:AddChild(Text(HEADERFONT, 20, "", DESC_TEXT_COLOR))
		recipe_source:SetMultilineTruncatedString(recipe_source_text, 50, 350)
		local msg_w, msg_h = recipe_source:GetRegionSize()
		y = y - msg_h/2
		recipe_source:SetPosition(0, y)
		y = y - msg_h/2
	end
	y = y - 40


    ------------------------------------------------------------------------
    ---[[详细信息]]
    ------------------------------------------------------------------------
	local LEFT_X = - 400/2 + 40

	if data.details and data.details.parts then
		y = y - 30
		local partsroot = pageroot:AddChild(Widget("partsroot"))

		-- 标题
		local parts_title = partsroot:AddChild(Text(HEADERFONT, 25, STRINGS.HMR.HMR_INFO_PANEL.UI.DETAILED_INFO, UICOLOURS.BROWN_DARK))
		parts_title:SetPosition(0, y)
		y = y - 20
		partsroot:AddChild(Decor(0, y, {}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))
		y = y - 20

		y = y - 40
		for i, part in pairs(data.details.parts) do
			local partroot = partsroot:AddChild(Widget("partroot"))
			local old_y = y

			-- 顶部标题
			y = y - 20
			local top_decor_left = partroot:AddChild(Image("images/plantregistry.xml", "arrow2_right.tex"))
			top_decor_left:SetScale(0.4)
			top_decor_left:SetPosition(LEFT_X, y)
			local part_title = partroot:AddChild(Text(HEADERFONT, 25, part.title or "", part.title_colour or UICOLOURS.BROWN_DARK))
			local title_w, title_h = part_title:GetRegionSize()
			part_title:SetPosition(LEFT_X + 30 + title_w/2, y)
			part_title:SetHAlign(ANCHOR_LEFT)
			y = y - 30

			-- 各种数值
			for j, info in pairs(part.infos or {}) do
				y = y - 20

				local icon_data = {
					atlas = info.atlas or (PART_ICON_DATA[info.type] or PART_ICON_DATA["default"]).atlas,
					tex = info.tex or (PART_ICON_DATA[info.type] or PART_ICON_DATA["default"]).tex,
					color = info.bgcolor or (PART_ICON_DATA[info.type] or PART_ICON_DATA["default"]).color,
				}
				local iconbg = partroot:AddChild(Image("images/avatars.xml", "avatar_bg_white.tex"))
				iconbg:ScaleToSize(ICON_SIZE, ICON_SIZE)
				iconbg:SetPosition(LEFT_X, y)
				iconbg:SetTint(unpack(icon_data.color or {1, 1, 1, 1}))
				local icon = partroot:AddChild(Image(icon_data.atlas, icon_data.tex))
				icon:ScaleToSize(ICON_SIZE - 10, ICON_SIZE - 10)
				icon:SetPosition(LEFT_X, y)
				local iconframe = partroot:AddChild(Image("images/avatars.xml", "avatar_frame.tex"))
				iconframe:ScaleToSize(ICON_SIZE, ICON_SIZE)
				iconframe:SetPosition(LEFT_X, y)

				local value = partroot:AddChild(Text(HEADERFONT, 17, info.value or "", info.value_colour or icon_data.color or UICOLOURS.GOLD_CLICKABLE))
				value:SetPosition(LEFT_X, y - ICON_SIZE / 2 - 8)

				if info.badges ~= nil then
					-- y = y - BADGE_SIZE / 2 - 5
					local badge_count = 0
					for k, badge in pairs(info.badges) do
						local x_offset = 10 + badge_count * (BADGE_SIZE + 10)
						local badgebg = partroot:AddChild(Image("images/avatars.xml", "avatar_bg_white.tex"))
						badgebg:ScaleToSize(BADGE_SIZE, BADGE_SIZE)
						badgebg:SetPosition(LEFT_X + ICON_SIZE + x_offset, y)
						badgebg:SetTint(unpack(badge.bgcolor or {1, 1, 1, 1}))

						local badgeicon = partroot:AddChild(Image(BADGE_ICONS[badge.type].atlas, BADGE_ICONS[badge.type].tex))
						badgeicon:ScaleToSize(BADGE_SIZE - 10, BADGE_SIZE - 10)
						badgeicon:SetPosition(LEFT_X + ICON_SIZE + x_offset, y)

						local badgeframe = partroot:AddChild(Image("images/avatars.xml", "avatar_frame.tex"))
						badgeframe:ScaleToSize(BADGE_SIZE, BADGE_SIZE)
						badgeframe:SetPosition(LEFT_X + ICON_SIZE + x_offset, y)

						local badgetextbg = reciperoot:AddChild(Image("images/global_redux.xml", "value_gold.tex"))
						badgetextbg:ScaleToSize(BADGE_SIZE - 5, -18)
						badgetextbg:SetPosition(LEFT_X + ICON_SIZE + x_offset, y - BADGE_SIZE/2 - 5)

						local badgetext = partroot:AddChild(Text(HEADERFONT, 17, badge.value or "", badge.value_colour or UICOLOURS.BROWN_DARK))
						badgetext:SetPosition(LEFT_X + ICON_SIZE + x_offset, y - BADGE_SIZE / 2 - 5)

						badge_count = badge_count + 1
					end
					y = y - BADGE_SIZE  - 28
				end

				local value_desc = partroot:AddChild(Text(HEADERFONT, 20, "", info.desc_colour or DESC_TEXT_COLOR))
				value_desc:SetMultilineTruncatedString(info.desc or "", 50, 300)
				local msg_w, msg_h = value_desc:GetRegionSize()
				y = y - msg_h/2
				value_desc:SetPosition(LEFT_X + 30 + msg_w / 2, y + ICON_SIZE / 2)
				value_desc:SetHAlign(ANCHOR_LEFT)
				y = y - math.max(msg_h/2, ICON_SIZE - msg_h/2)

				y = y - 10
			end

			-- 其他描述
			if part.desc then
				local desc_text = partroot:AddChild(Text(HEADERFONT, 20, "", part.desc_colour or DESC_TEXT_COLOR))
				desc_text:SetMultilineTruncatedString(part.desc or "", 50, 350)
				local _, msg_h = desc_text:GetRegionSize()
				y = y - msg_h/2 - 10
				desc_text:SetPosition(0, y)
				y = y - msg_h/2 - 10
			end

			-- 背景
			local part_height = y - old_y
			local part_bg = partroot:AddChild(MakeDetailPart(part_height, old_y))
			part_bg:SetPosition(0, old_y + part_height/2)

			y = y - 80
		end
		y = y + 30
	end

	------------------------------------------------------------------------
    ---[[描述]]
    ------------------------------------------------------------------------
	if data.details and data.details.desc_introduce then
		y = y - 50
		local introduce_title = pageroot:AddChild(Text(HEADERFONT, 25, STRINGS.HMR.HMR_INFO_PANEL.UI.INTRODUCTION, UICOLOURS.BROWN_DARK))
		introduce_title:SetPosition(0, y)
		y = y - 20
		pageroot:AddChild(Decor(0, y, {}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))
		y = y - 20

		local desc_text = pageroot:AddChild(Text(HEADERFONT, 20, "", data.details.desc_colour or DESC_TEXT_COLOR))
		desc_text:SetMultilineTruncatedString(data.details.desc_introduce or "", 50, 350)
		local _, msg_h = desc_text:GetRegionSize()
		y = y - msg_h/2 - 10
		desc_text:SetPosition(0, y)
		y = y - msg_h/2 - 10
	end

	if data.details and data.details.desc_story then
		y = y - 50
		local story_title = pageroot:AddChild(Text(HEADERFONT, 25, STRINGS.HMR.HMR_INFO_PANEL.UI.BACKGROUND_STORY, UICOLOURS.BROWN_DARK))
		story_title:SetPosition(0, y)
		y = y - 20
		pageroot:AddChild(Decor(0, y, {}, {atlas = "images/plantregistry.xml", tex = "plant_entry_seperator_active.tex"}))
		y = y - 20

		local desc_text = pageroot:AddChild(Text(HEADERFONT, 20, "", data.details.desc_colour or DESC_TEXT_COLOR))
		desc_text:SetMultilineTruncatedString(data.details.desc_story or "", 50, 350)
		local _, msg_h = desc_text:GetRegionSize()
		y = y - msg_h/2 - 10
		desc_text:SetPosition(0, y)
		y = y - msg_h/2 - 10
	end

	------------------------------------------------------------------------
    ---[[构成]]
    ------------------------------------------------------------------------
	local total_height = math.abs(y - top) + 200
	local width = 360
	local category_height = 500
	local PANEL_HEIGHT = 450
	local max_visible_height = PANEL_HEIGHT -60  -- -20
	local padding = 5
	local height = max_visible_height / 2 - padding

	-- 可见部分 x, y：位置, width， height：裁剪部分宽高
	local scissor_data = {x = 0, y = 0, width = 450, height = 500}
	local context = {widget = pageroot, offset = {x = 200, y = 0}, size = {w = 440, height = total_height} }
	local scrollbar = { scroll_per_click = 20*3, h_offset = -43 }

	local scroll_area = TrueScrollArea(context, scissor_data, scrollbar)

    scroll_area.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    scroll_area.up_button:SetScale(0.5)

	scroll_area.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    scroll_area.down_button:SetScale(-0.5)

	scroll_area.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
	scroll_area.scroll_bar_line:SetScale(1.1)

	scroll_area.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    scroll_area.position_marker:OnGainFocus()
    scroll_area.position_marker:SetScale(.6)

    return scroll_area
end

function HMRIntroduce:SetGrid()
	if self.item_grid then
		self.gridroot:KillAllChildren()
	end
	self.item_grid = nil
	self.item_grid = self.gridroot:AddChild( self:BuildRecipeGrid() )
	self.item_grid:SetPosition(0, 0)
	local griddata = deepcopy(self.current_view_data)

	local setfocus = true

	if #griddata <= 0 then
		setfocus = false

		for i=1, 6 do
			table.insert(griddata,{name=FILLER})
		end
	end

	if #griddata % 6 > 0 then
		for i=1, 6 - (#griddata % 6) do
			table.insert(griddata,{name=FILLER})
		end
	end

	self.item_grid:SetItemsData( griddata )

	self.focus_forward = self.item_grid

	TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/scrapbook_pageflip")

	if TheInput:ControllerAttached() then
		if setfocus and not self.searchbox.focus then
			self:SetFocus()
		else
			self.searchbox:SetFocus()
		end
	end
end

function HMRIntroduce:SetSearchText(search_text)
	search_text = TrimString(string.lower(search_text)):gsub(" ", "")

	-- 过滤数据
	if not search_text or search_text == "" then
		-- self:SelectSideButton(self.last_filter)
		self.current_view_data = self:CollectType(INTRODUCE_DATA, self.last_filter)
		return
	end
	local search_set = self:CollectType(INTRODUCE_DATA)

	local newset = {}
	for i, set in ipairs( search_set ) do
		local name = nil
		if set.type ~= UNKNOWN then
			-- 名称
			name = TrimString(string.lower(STRINGS.NAMES[string.upper(set.name)])):gsub(" ", "")

			-- 代码名
			name = name .. TrimString(set.name):gsub(" ", "")

			-- 过滤器
			if set.filter and type(set.filter) == "table" then
				for _, f in pairs(set.filter) do
					local f_name = STRINGS.HMR.HMR_INFO_PANEL.FILTERS[string.upper(f)]
					if f_name then
						name = name .. TrimString(string.lower(f_name)):gsub(" ", "")
					end
				end
			end

			-- 介绍
			if set.details and set.details.desc_introduce then
				name = name .. TrimString(string.lower(set.details.desc_introduce)):gsub(" ", "")
			end

			-- 背景故事
			if set.details and set.details.desc_story then
				name = name .. TrimString(string.lower(set.details.desc_story)):gsub(" ", "")
			end

			-- 判断是否符合
			local num = string.find(name, search_text, 1, true)
			if num then
				table.insert(newset, set)
			end
		end
	end

	self.current_view_data = newset

	self:SetGrid()

	self.filter_button.text:SetString(STRINGS.HMR.HMR_INFO_PANEL.UI.FILTRATE)
end

function HMRIntroduce:MakeSearchBox(box_width, box_height)
    local searchbox = Widget("search")
	searchbox:SetHoverText(STRINGS.UI.CRAFTING_MENU.SEARCH, {offset_y = 30, attach_to_parent = self })

    searchbox.textbox_root = searchbox:AddChild(TEMPLATES.StandardSingleLineTextEntry(nil, box_width, box_height))
    searchbox.textbox = searchbox.textbox_root.textbox
    searchbox.textbox:SetTextLengthLimit(200)
    searchbox.textbox:SetForceEdit(true)
    searchbox.textbox:EnableWordWrap(false)
    searchbox.textbox:EnableScrollEditWindow(true)
    searchbox.textbox:SetHelpTextEdit("")
    searchbox.textbox:SetHelpTextApply(STRINGS.UI.SERVERCREATIONSCREEN.SEARCH)
    searchbox.textbox:SetTextPrompt(STRINGS.UI.SERVERCREATIONSCREEN.SEARCH, UICOLOURS.GREY)
    searchbox.textbox.prompt:SetHAlign(ANCHOR_MIDDLE)
    searchbox.textbox.OnTextInputted = function(keydown)
		if keydown then
			self:SetSearchText(self.searchbox.textbox:GetString())
		end
    end

    searchbox:SetOnGainFocus( function() searchbox.textbox:OnGainFocus() end )
    searchbox:SetOnLoseFocus( function() searchbox.textbox:OnLoseFocus() end )

    searchbox.focus_forward = searchbox.textbox

    return searchbox
end

function HMRIntroduce:CollectType(set, filter)
	local newset = {}
	for i, data in pairs(set)do
        local accord = false
        for _, f in pairs(data.filter) do
            if f == filter or filter == "all" then
                accord = true
                break
            end
        end
		if not filter or accord then
			table.insert(newset, deepcopy(data))
		end
	end

	return newset
end

function HMRIntroduce:BuildTopBar()
	self.toproot = self.root:AddChild(Widget("toproot"))
	self.toproot:SetPosition(-280, 170)
	self.search_text = ""

	-- 搜索框
	self.searchbox = self.toproot:AddChild(self:MakeSearchBox(300, SEARCH_BOX_HEIGHT))
	self.searchbox:SetPosition(-30, 0)

	-- 筛选按钮高光
	local filter_offset_x = 180
	self.filter_button_frame = self.toproot:AddChild(Image("images/global_redux.xml", "spinner_background_hover.tex"))
	self.filter_button_frame:SetPosition(filter_offset_x + 17, 0)
	self.filter_button_frame:ScaleToSize(133, 38)
	self.filter_button_frame:Hide()

	-- 筛选按钮
	self.filter_button = self.toproot:AddChild(ImageButton("images/global_redux.xml", "spinner_background_edited.tex"))
	self.filter_button:SetPosition(filter_offset_x + 17, 0)
	self.filter_button:ForceImageSize(130, 35)
	self.filter_button.scale_on_focus = false
	self.filter_button:SetHoverText(STRINGS.HMR.HMR_INFO_PANEL.UI.FILTRATE, {offset_y = 60})
	self.filter_button:SetFocusSound("dontstarve/HUD/click_mouseover")
	self.filter_button:SetOnClick(function()
		if self.filter_box:IsVisible() then
			self.filter_box:Hide()
			self.filter_box_bg:Hide()
			self.filter_black:Hide()
		else
			self.filter_black:Show()
			self.filter_box_bg:Show()
			self.filter_box:Show()
		end
	end)
	self.filter_button:SetOnGainFocus(function()
		self.filter_button_frame:Show()
	end)
	self.filter_button:SetOnLoseFocus(function()
		self.filter_button_frame:Hide()
	end)
	self.filter_button.text:SetString(STRINGS.HMR.HMR_INFO_PANEL.UI.FILTRATE)
	self.filter_button:SetTextColour(UICOLOURS.HIGHLIGHT_GOLD)
	self.filter_button:SetTextFocusColour(UICOLOURS.HIGHLIGHT_GOLD)
	self.filter_button:SetTextDisabledColour(UICOLOURS.HIGHLIGHT_GOLD)
	self.filter_button:SetTextSelectedColour(UICOLOURS.HIGHLIGHT_GOLD)
	self.filter_button.text:SetFont(HEADERFONT)
	self.filter_button.text:SetSize(20)
	self.filter_button.text:Show()


	-- 筛选栏背景
	local filter_box_w, filter_box_h = 130, 240
	self.filter_box_bg = self.toproot:AddChild(Image("images/quagmire_recipebook.xml", "quagmire_recipe_menu_block.tex"))
    self.filter_box_bg:ScaleToSize(filter_box_w, filter_box_h)
	self.filter_box_bg:SetPosition(filter_offset_x + 17, -120)
	self.filter_box_bg:SetClickable(false)
	self.filter_box_bg:Hide()

	-- 点击就关闭
	self.filter_black = self.toproot:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.filter_black.image:SetVRegPoint(ANCHOR_MIDDLE)
    self.filter_black.image:SetHRegPoint(ANCHOR_MIDDLE)
    self.filter_black.image:SetVAnchor(ANCHOR_MIDDLE)
    self.filter_black.image:SetHAnchor(ANCHOR_MIDDLE)
    self.filter_black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.filter_black.image:SetTint(0,0,0,0)
    self.filter_black:SetOnClick(function()
		self.filter_black:Hide()
		self.filter_box:Hide()
		self.filter_box_bg:Hide()
	end)
    self.filter_black:SetHelpTextMessage("")
	self.filter_black:Hide()

	-- 定义滚动网格中的每个小部件的构造函数
	local filter_button_w, filter_button_h = 90, 30
	local filter_icon_w, filter_icon_h = 25, 25
    local function ScrollWidgetsCtor(context, index)
        local w = Widget("filter_".. index)

		----------------
		w.item_root = w:AddChild(Widget("item_root"))

		-- 添加按钮图像
		w.item_root.button = w.item_root:AddChild(ImageButton("images/quagmire_recipebook.xml", "cookbook_known_selected.tex"))
		w.item_root.button:SetImageNormalColour(1,1,1,1)
		w.item_root.button:SetImageFocusColour(1,1,1,0.8)
		w.item_root.button.scale_on_focus = false
		w.item_root.button.clickoffset = Vector3(0, -1, 0)
		w.item_root.button:ForceImageSize(filter_button_w, filter_button_h)

		-- 添加项目图像
		w.item_root.icon = w.item_root:AddChild(Image("images/quagmire_recipebook.xml", "cookbook_known_selected.tex"))
		w.item_root.icon:ScaleToSize(filter_icon_w, filter_icon_h)
		w.item_root.icon:SetPosition(-28, 0)
		w.item_root.icon:SetClickable(false)

		-- 添加文字
		w.item_root.text = w.item_root:AddChild(Text(HEADERFONT, 20, w.filter or "", UICOLOURS.BROWN_DARK))
		w.item_root.text:SetPosition(15, 0)
		w.item_root.text:SetClickable(false)

		-- 设置按钮点击事件
		w.item_root.button:SetOnClick(function()
			if w.filter ~= nil then
				self.last_filter = w.filter
				self.current_view_data = self:CollectType(INTRODUCE_DATA, w.filter)
				self:SetGrid()
				self.filter_button.text:SetString(STRINGS.HMR.HMR_INFO_PANEL.FILTERS[string.upper(w.filter)])

				self.filter_box:Hide()
				self.filter_box_bg:Hide()
				self.filter_black:Hide()
			end
		end)

		return w
    end

    -- 定义设置滚动网格中小部件数据的函数
    local function ScrollWidgetSetData(context, widget, data, index)
		widget.filter = data

		if data ~= nil then
			widget.item_root.icon:Show()
			widget.item_root.button:Show()
			widget.item_root.text:Show()
			-- 设置按钮文本
			widget.item_root.text:SetString(STRINGS.HMR.HMR_INFO_PANEL.FILTERS[string.upper(data)] or "111")

			if not widget.item_root.button:IsEnabled() then
				widget.item_root.button:Enable()
			end

            widget.item_root.icon:SetTexture("images/quagmire_recipebook.xml", "cookbook_known_selected.tex")
            widget.item_root.icon:ScaleToSize(filter_icon_w, filter_icon_h)

			-- 设置按钮点击事件
			widget.item_root.button:SetOnClick(function()
				if widget.filter ~= nil then
					self.last_filter = widget.filter
					self.current_view_data = self:CollectType(INTRODUCE_DATA, widget.filter)
					self:SetGrid()
					self.filter_button.text:SetString(STRINGS.HMR.HMR_INFO_PANEL.FILTERS[string.upper(widget.filter)])

					self.filter_box:Hide()
					self.filter_box_bg:Hide()
					self.filter_black:Hide()
				end
			end)
		else
            widget.item_root.button:SetOnClick(function()
			end)

			widget.item_root.text:Hide()
            widget.item_root.icon:Hide()

            if not TheInput:ControllerAttached() then
                widget.item_root.button:Hide()
            end
        end
    end

	local grid = TEMPLATES.ScrollingGrid(
        FILTERS,
        {
            context = {},
            widget_width  = filter_button_w, -- 设置小部件宽度
            widget_height = filter_button_h + 5, -- 设置小部件高度
			force_peek    = true, -- 强制显示部分下一个小部件
            num_visible_rows = 6, -- 设置可见行数，根据图像大小调整
            num_columns      = 1, -- 设置列数
            item_ctor_fn = ScrollWidgetsCtor, -- 设置小部件构造函数
            apply_fn     = ScrollWidgetSetData, -- 设置数据应用函数
            scrollbar_offset = 10, -- 设置滚动条偏移量
            scrollbar_height_offset = -60 -- 设置滚动条高度偏移量
        })
	-- 滚条的上箭头
	grid.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
	grid.up_button:SetScale(0.3)

	-- 滚条的下箭头
	grid.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
	grid.down_button:SetScale(-0.3)

	-- 滚条
	grid.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
	grid.scroll_bar_line:SetScale(.4)

	-- 滚轮
	grid.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
	grid.position_marker.image:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
	grid.position_marker:SetScale(.3)

	self.filter_box = self.toproot:AddChild(grid)
	self.filter_box:SetPosition(filter_offset_x + 10, -125)
	self.filter_box:Hide()

	self.filter_button:MoveToFront()
end

function HMRIntroduce:BuildRecipeGrid()
	-- 初始化缺失字符串的表
	self.MISSING_STRINGS = {}

	-- 定义普通图像大小
	local imagesize = 64
	-- 定义图像间距
	local imagebuffer = 12
	-- 计算每行宽度
	local row_w = 64
	-- 定义每行高度为图像大小
    local row_h = 64
    -- 定义行间距
    local row_spacing = 5
    -- 定义背景填充
    local bg_padding = 3

	-- 对当前视图数据进行排序，首先按名称排序，如果名称相同则按条目排序
	table.sort(self.current_view_data, function(a, b)
		local a_name = STRINGS.NAMES[string.upper(a.name)] or FILLER
		local b_name = STRINGS.NAMES[string.upper(b.name)] or FILLER
		if a.subcat then a_name = STRINGS.SCRAPBOOK.SUBCATS[string.upper(a.subcat)] .. a_name end
		if b.subcat then b_name = STRINGS.SCRAPBOOK.SUBCATS[string.upper(b.subcat)] .. b_name end

		if not a_name or not b_name then
			return false
		end

		if a_name == b_name and a.entry and b.entry then
			return a.entry < b.entry
		end

		return a_name < b_name
	end)

	-- 为每个数据项设置索引
	for i, data in ipairs(self.current_view_data) do
		data.index = i
	end

    -- 定义滚动网格中的每个小部件的构造函数
    local function ScrollWidgetsCtor(context, index)
        local w = Widget("recipe-cell-".. index)

		-- 添加一个子部件作为项目的根
		w.item_root = w:AddChild(Widget("item_root"))

		-- 添加按钮图像
		w.item_root.button = w.item_root:AddChild(ImageButton(
			"images/quagmire_recipebook.xml", 	-- atlas
			"cookbook_known.tex",				-- normal
			"cookbook_known_selected.tex",	    -- focus
			"cookbook_known.tex",				-- disabled
			"cookbook_known_selected.tex",    	-- down
			"cookbook_known_selected.tex"     	-- selected
		))
		w.item_root.button.scale_on_focus = false
		w.item_root.button.clickoffset = Vector3(0, -3, 0)
		w.item_root.button:ForceImageSize(row_w, row_h)

		-- 添加背包中的项目图像
		w.item_root.inv_image = w.item_root:AddChild(Image("images/quagmire_recipebook.xml", "cookbook_missing.tex"))
		w.item_root.inv_image:ScaleToSize(imagesize-imagebuffer, imagesize-imagebuffer)
		w.item_root.inv_image:SetPosition((-row_w/2)+imagesize/2, 0)
		w.item_root.inv_image:SetClickable(false)
		w.item_root.inv_image:Hide()

		-- 设置按钮点击事件
		w.item_root.button:SetOnClick(function()
			if w.data ~= nil and self.details_name ~= w.data.name then
				self.detailsroot:KillAllChildren()
				self.details = nil
				self.details = self.detailsroot:AddChild(self:PopulateInfoPanel(w.data.name))
				-- self:DoFocusHookups()
			end
		end)

		-- 设置部件获得焦点时的事件
		w.item_root.ongainfocusfn = function()
			self.lastselecteditem = w.item_root.button
		end

		-- 设置焦点前移
		w.focus_forward = w.item_root.button

		-- 设置按钮获得焦点时的事件
		w.item_root.button:SetOnGainFocus(function()
			self.item_grid:OnWidgetFocus(w)
		end)

		return w
    end

    -- 定义设置滚动网格中小部件数据的函数
    local function ScrollWidgetSetData(context, widget, data, index)
		widget.item_root.inv_image:SetTint(1,1,1,1)

		widget.data = data

		if data ~= nil and data.name ~= FILLER then
			widget.item_root.button:Show()
			if not widget.item_root.button:IsEnabled() then
				widget.item_root.button:Enable()
			end

            widget.item_root.inv_image:Show()
            widget.item_root.inv_image:SetTexture(data.atlas, data.tex)
            widget.item_root.inv_image:ScaleToSize(imagesize-imagebuffer, imagesize-imagebuffer)

			-- 设置按钮点击事件
			widget.item_root.button:SetOnClick(function()
				if widget.data ~= nil and self.details_name ~= widget.data.name then
					-- 如果条目不同，移除所有子部件以清除之前的内容
					self.detailsroot:KillAllChildren()
					-- 将details设置为nil，准备重新赋值
					self.details = nil
					-- 在detailsroot下添加新的子部件，显示新选择条目的信息面板
					self.details = self.detailsroot:AddChild(self:PopulateInfoPanel(widget.data.name))
					-- 播放翻页声音，以反馈用户操作
					TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/scrapbook_pageflip")
				end
			end)
		else
            widget.item_root.button:SetOnClick(function()
			end)

			widget.item_root.inv_image:Hide()

            if not TheInput:ControllerAttached() then
                widget.item_root.button:Hide()
            end
        end
    end

    -- 创建滚动网格
    local grid = TEMPLATES.ScrollingGrid(
        {},
        {
            context = {},
            widget_width  = row_w+row_spacing, -- 设置小部件宽度
            widget_height = row_h+row_spacing, -- 设置小部件高度
			force_peek    = true, -- 强制显示部分下一个小部件
            num_visible_rows = 6, -- 设置可见行数，根据图像大小调整
            num_columns      = 6, -- 设置列数
            item_ctor_fn = ScrollWidgetsCtor, -- 设置小部件构造函数
            apply_fn     = ScrollWidgetSetData, -- 设置数据应用函数
            scrollbar_offset = 20, -- 设置滚动条偏移量
            scrollbar_height_offset = -60 -- 设置滚动条高度偏移量
        })

    -- 滚条的上箭头
	grid.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    grid.up_button:SetScale(0.5)

    -- 滚条的下箭头
	grid.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    grid.down_button:SetScale(-0.5)

    -- 滚条
	grid.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
	grid.scroll_bar_line:SetScale(.8)

	-- 滚轮位置
	grid.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
	grid.position_marker.image:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    grid.position_marker:SetScale(.6)

    return grid
end

return HMRIntroduce