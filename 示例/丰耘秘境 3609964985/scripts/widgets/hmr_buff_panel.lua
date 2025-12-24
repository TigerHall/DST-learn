local Widget = require "widgets/widget" 
local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"

local BuffPanel = Class(Widget, function(self, owner)
	Widget._ctor(self, "BuffPanel")

	self.owner = owner
	self.root = self:AddChild(Widget("root"))

	self.skin = HMR_UTIL.GetPersistentString("HMR_BUFF_PANEL_SKIN") or ""

    self.bg = self.root:AddChild(Image(self:GetAtlas(), "buff_bg.tex"))
    self.bg:SetPosition(0, 0, 0)
	self.bg:ScaleToSize(210, 280)

    self.panel_items = self.root:AddChild(self:BuildScrolledList())
	self.panel_items:SetPosition(0, 0, 0)

	-- self:SetPosition(200, 300, 0)

    HMR_UTIL.AddZoomableUI(self, self.bg, "buff_panel", {})
	HMR_UTIL.AddDraggableUI(self, self.bg, "buff_panel", {drag_offset = 1})

	self:Hide()

    self.owner.HMRBuffPanel = self

	self.owner:DoTaskInTime(0, function() self:SetForceHide() end)
	self.owner:ListenForEvent("buff_data_dirty", function() self:RefreshBuffs() end)
	self.owner:DoTaskInTime(0, function() self:RefreshBuffs() end)

	self.owner:ListenForEvent("hmr_config_dirty", function()
		-- 显示
		self:SetForceHide()
		if self:ShouldShow() then
			self:Show()
			print("显示buff面板")
		else
			self:Hide()
		end

		-- 皮肤
		local skin = HMR_UTIL.GetConfig("BUFF_PANEL_SKIN")
		self:SetSkin(skin)
	end)
end)

function BuffPanel:SetForceHide(hide)
	if hide ~= nil then
		self.force_hide = hide
	end
	local show_buff_panel = HMR_UTIL.GetConfig("SHOW_BUFF_PANEL")
	if show_buff_panel == nil then
		show_buff_panel = true
	end
	self.force_hide = not show_buff_panel
	self:RefreshBuffs()
end

function BuffPanel:SetSkin(skin)
	self.skin = skin
	self.bg:SetTexture(self:GetAtlas(), "buff_bg.tex")
	self:RefreshBuffs()

	HMR_UTIL.SetPersistentString("HMR_BUFF_PANEL_SKIN", self.skin)
end

function BuffPanel:GetAtlas()
    self.skin = self.skin or ""
	return "images/widgetimages/hmr_buff"..self.skin..".xml"
end

function BuffPanel:RefreshBuffs()
	-- if self.force_hide then
	-- 	self.force_hide = HMR_UTIL.GetConfig("SHOW_BUFF_PANEL")
	-- end
    if self.panel_items ~= nil then
		if self:ShouldShow() then
			self:Show()
		else
			self:Hide()
		end
		local items = self:GenerateBuffItems()
        self.panel_items:SetItemsData(items)
    end
end

function BuffPanel:ShouldShow()
	if self.force_hide then
		print("不应该展示buff面板1")
		return false
	end
	local items = self:GenerateBuffItems()
	if #items <= 0 then
		print("应该展示buff面板，但是没有buff数据")
		return false
	else
		print("应该展示buff面板")
		return true
	end
end

function BuffPanel:BuildScrolledList()
    -- 定义滚动网格中的每个小部件的构造函数
	local filter_button_w, filter_button_h = 150, 30
	local filter_icon_w, filter_icon_h = 25, 25
    local function ScrollWidgetsCtor(context, index)
        local w = Widget("filter_".. index)

		w.item_root = w:AddChild(Widget("item_root"))

		-- 添加背景图像
		w.item_root.button = w.item_root:AddChild(ImageButton(self:GetAtlas(), "buff_slot.tex"))
		w.item_root.button:SetImageNormalColour(1,1,1,1)
		w.item_root.button:SetImageFocusColour(1,1,1,0.8)
		w.item_root.button.scale_on_focus = false
		w.item_root.button.clickoffset = Vector3(0, -1, 0)
		w.item_root.button:ForceImageSize(filter_button_w, filter_button_h)
        w.item_root.button:SetOnClick(function()

		end)

		-- 添加buff图标
		w.item_root.icon = w.item_root:AddChild(Image("images/plantregistry.xml", "missing.tex"))
		w.item_root.icon:ScaleToSize(filter_icon_w, filter_icon_h)
		w.item_root.icon:SetPosition(-55, 0)
		w.item_root.icon:SetClickable(false)

		-- 添加buff名字
		w.item_root.text = w.item_root:AddChild(Text(DIALOGFONT, 20, "", UICOLOURS.GOLD_CLICKABLE))
		w.item_root.text:SetPosition(30, 0)
		w.item_root.text:SetClickable(false)

        -- 添加buff剩余时间
        w.item_root.time_left = w.item_root:AddChild(Text(CODEFONT, 20, "", UICOLOURS.WHITE))
        w.item_root.time_left:SetPosition(-25, 0)
        w.item_root.time_left:SetClickable(false)

		return w
    end

    -- 定义设置滚动网格中小部件数据的函数
    local function ScrollWidgetSetData(context, widget, data, index) -- data就是设置的items里的一项
		widget.filter = data

		if data ~= nil then
			-- buff名字
			widget.item_root.text:Show()
            local str = STRINGS.NAMES[string.upper(data.name)] or data.name
			widget.item_root.text:SetString(str or "未知buff")

            -- buff背景/按钮
			if not widget.item_root.button:IsEnabled() then
				widget.item_root.button:Enable()
			end
            widget.item_root.button:SetOnClick(function()

			end)
			widget.item_root.button:Show()
			widget.item_root.button:SetTextures(self:GetAtlas(), "buff_slot.tex")

            -- buff icon
			widget.item_root.icon:Show()
			local atlas, tex
			if data.icon ~= nil then
				atlas = data.icon.atlas
				tex = data.icon.tex
			else
				atlas = "images/plantregistry.xml"
				tex = "missing.tex"
			end
            widget.item_root.icon:SetTexture(resolvefilepath(atlas), tex)
			widget.item_root.icon:ScaleToSize(filter_icon_w, filter_icon_h)

            -- buff时间
			widget.item_root.time_left:Show()
            widget.item_root.time_left:SetString(self:FormatTime(data.time_left))
		else
            widget.item_root.button:SetOnClick(function() end)

			widget.item_root.text:Hide()
            widget.item_root.icon:Hide()
			widget.item_root.time_left:Hide()

            if not TheInput:ControllerAttached() then
                widget.item_root.button:Hide()
            end
        end
    end

	local grid = TEMPLATES.ScrollingGrid(
        {}, -- items
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

	return grid
end

function BuffPanel:FormatTime(time)
    if time == nil or time < 0 then return "--:--" end
	local min = math.floor(time/60)
    local sec = math.floor(time%60)
    if min < 10 then min = "0"..min end
    if sec < 10 then sec = "0"..sec end
    return min .. ":" .. sec
end

function BuffPanel:GenerateBuffItems()
    local items = self.owner.replica.hmrbuffviewer and self.owner.replica.hmrbuffviewer:GetBuffData() or nil

    if items ~= nil then
        table.sort(items, function(a, b)
            return a.time_left > b.time_left
        end)
    else
        items = {}
    end

    return items
end

function BuffPanel:OnUpdate(dt)
	if TheNet:IsServerPaused() then
		return
	end
end

return BuffPanel