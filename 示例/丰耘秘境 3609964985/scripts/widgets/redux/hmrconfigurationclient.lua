require "util"
require "strings"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local PopupDialogScreen = require "screens/redux/popupdialog"

local HMRConfigurationClient = Class(Widget, function(self, modname)
	Widget._ctor(self, "HMRConfigurationClient")
	self.modname = modname

    self.options = {}

    local config = require("hmrmain/hmr_config_data").client

	if config and type(config) == "table" then
		for i, v in ipairs(config) do
			-- Only show the option if it matches our format exactly
            if v.name and v.options and (v.saved ~= nil or v.default ~= nil) then
                local _value = nil
                if self:IsBindingConfig(v) and HMR_CONTROLS and HMR_CONTROLS[v.name] ~= nil then
                    _value = HMR_CONTROLS[v.name]
                elseif (not self:IsBindingConfig(v)) and HMR_CLIENT_CONFIGS and HMR_CLIENT_CONFIGS[v.name] ~= nil then
                    _value = HMR_CLIENT_CONFIGS[v.name]
                elseif v.saved ~= nil then
                    _value = v.saved
                else
                    _value = v.default
                end

                table.insert(self.options, {name = v.name, label = v.label, options = v.options, default = v.default, value = _value, hover = v.hover, type = v.type})
			end
		end
	end

	self.started_default = self:IsDefaultSettings()

    self.root = self:AddChild(Widget("root"))

	local label_width = 300
    local spinner_width = 225
    local item_width, item_height = label_width + spinner_width + 30, 40

    local buttons = {
        { text = STRINGS.UI.MODSSCREEN.APPLY,        cb = function() self:Apply() end,                },
        { text = STRINGS.UI.MODSSCREEN.RESETDEFAULT, cb = function() self:ResetToDefaultValues() end, },
        -- { text = STRINGS.UI.MODSSCREEN.BACK,         cb = function() self:Cancel() end,               },
    }

    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(item_width + 20, 480, nil, buttons))

    self.option_header = self.dialog:AddChild(Widget("option_header"))
    self.option_header:SetPosition(0, 220)

    self.option_description = self.option_header:AddChild(Text(CHATFONT, 28, "配置选项"))
    self.option_description:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
    self.option_description:SetPosition(0, -10)
    self.option_description:SetRegionSize(item_width+30, 50)
    self.option_description:SetVAlign(ANCHOR_TOP) -- stop text from jumping around as we scroll
    self.option_description:EnableWordWrap(true)

    self.value_description = self.option_header:AddChild(Text(CHATFONT, 22))
    self.value_description:SetColour(UICOLOURS.GOLD)
    self.value_description:SetPosition(0, -40)
    self.value_description:SetRegionSize(item_width+30, 25)

    self.optionspanel = self.dialog:InsertWidget(Widget("optionspanel"))
    self.optionspanel:SetPosition(0, -35)

	self.dirty = false

    self.optionwidgets = {}
    self.scrollwidgets = {}

    local function ScrollWidgetsCtor(context, idx)
        local widget = Widget("option"..idx)
        widget.bg = widget:AddChild(TEMPLATES.ListItemBackground(item_width, item_height))
        widget.opt = widget:AddChild(TEMPLATES.LabelSpinner("", {}, label_width, spinner_width, item_height))

        widget.opt.spinner:EnablePendingModificationBackground()

        widget.ApplyDescription = function(_)
            local option = widget.opt.data and widget.opt.data.option.hover or ""
            local value
            local data = self.optionwidgets[idx]
            if data then
                if self:IsBindingConfig(data) then
                    local key_name = self:GetKeyText(data.selected_value)
                    value = string.format("当前绑定: %s", key_name or "")
                else
                    value = widget.opt.data and widget.opt.data.spin_options_hover[widget.opt.data.selected_value] or ""
                end
            end
            self.option_description:SetString(option)
            self.value_description:SetString(value)
        end

        widget:SetOnGainFocus(function(_)
            self.options_scroll_list:OnWidgetFocus(widget)
            widget:ApplyDescription()
        end)

        widget.real_index = idx
        widget.opt.spinner.OnChanged = function(_, data)
            self.options[widget.real_index].value = data
            self.optionwidgets[widget.real_index].selected_value = data
            widget.opt.data.selected_value = data

            widget.opt.spinner:SetHasModification(widget.opt.data.selected_value ~= widget.opt.data.initial_value)
            widget:ApplyDescription()
            self:MakeDirty()
        end

        widget.controlName = ""

        local x_offset = 38
		widget.label = widget:AddChild(Text(CHATFONT, 28))
		widget.label:SetString("")
		widget.label:SetHAlign(ANCHOR_RIGHT)
		widget.label:SetColour(UICOLOURS.GOLD)
		widget.label:SetRegionSize(spinner_width, item_height)
		widget.label:SetPosition(-115 + x_offset, 0)
		widget.label:SetClickable(false)

        widget.changed_image = widget:AddChild(Image("images/global_redux.xml", "wardrobe_spinner_bg.tex"))
        widget.changed_image:SetTint(1, 1, 1, 0.3)
        widget.changed_image:ScaleToSize(spinner_width, item_height)
        widget.changed_image:SetPosition(115 + x_offset, 0)
        widget.changed_image:Hide()

		widget.binding_btn = widget:AddChild(ImageButton("images/global_redux.xml", "blank.tex", "spinner_focus.tex"))
		widget.binding_btn:ForceImageSize(spinner_width, item_height)
		widget.binding_btn:SetTextColour(UICOLOURS.GOLD_CLICKABLE)
		widget.binding_btn:SetFont(CHATFONT)
		widget.binding_btn:SetTextSize(30)
		widget.binding_btn:SetPosition(115 + x_offset, 0)
		widget.binding_btn.idx = idx

        widget.binding_btn:SetTextFocusColour(UICOLOURS.GOLD_CLICKABLE)
        widget.binding_btn:SetHelpTextMessage("")
        widget.binding_btn.move_on_click = false
        widget.binding_btn.stopclicksound = true
		widget.binding_btn:SetDisabledFont(CHATFONT)
		widget.binding_btn:SetText("")
        widget.binding_btn.text:SetHAlign(ANCHOR_LEFT)

        widget.focus_forward = widget.opt

        self.scrollwidgets[idx] = widget

        return widget
	end
    local function ApplyDataToWidget(context, widget, data, idx)
        widget.opt.data = data
		if data then
            widget:Show()
            widget.real_index = idx

            if self:IsBindingConfig(data) then
                widget.label:Show()
                widget.binding_btn:Show()
                widget.bg:Show()
                widget.opt:Hide()

                widget.controlName = data.option.label or data.option.name or STRINGS.UI.MODSSCREEN.UNKNOWN_MOD_CONFIG_SETTING
                widget.paramName = data.option.name

                widget.binding_btn:SetOnClick(function()
					self:MapControl(TheInput:GetControllerID(), widget)
				end)
                widget.binding_btn:SetTextFocusColour(UICOLOURS.GOLD_FOCUS)
                widget.binding_btn:SetHelpTextMessage(STRINGS.UI.CONTROLSSCREEN.CHANGEBIND)
                widget.binding_btn:SetText(self:GetKeyText(data.selected_value))
                widget.label:SetString(widget.controlName.. ":")
            else
                widget.opt:Show()
                widget.label:Hide()
                widget.binding_btn:Hide()

                widget.opt.spinner:SetOptions(data.spin_options)

                if data.is_header then
                    widget.bg:Hide()
                    widget.opt.spinner:Hide()
                    widget.opt.label:SetSize(30)
                else
                    widget.bg:Show()
                    widget.opt.spinner:Show()
                    widget.opt.label:SetSize(25) -- same as LabelSpinner's default.
                end

                widget.opt.spinner:SetSelected(data.selected_value)

                local label = (data.option.label or data.option.name or STRINGS.UI.MODSSCREEN.UNKNOWN_MOD_CONFIG_SETTING)
                if not data.is_header then
                    label =  label .. ":"
                end
                widget.opt.label:SetString(label)

                widget.opt.spinner:SetHasModification(widget.opt.data.selected_value ~= widget.opt.data.initial_value)

                if widget.focus then
                    widget:ApplyDescription()
                end
            end
        else
            -- widget.opt:Hide()
            -- widget.bg:Hide()
            widget:Hide()
		end
	end

    for idx, option_item in ipairs(self.options) do
        local spin_options = {} --{{text="default"..tostring(idx), data="default"},{text="2", data="2"}, }
        local spin_options_hover = {}
        for _,v in ipairs(option_item.options) do
            if type(v) == "table" then
                table.insert(spin_options, {text=v.description, data=v.data})
                spin_options_hover[v.data] = v.hover
            else
                table.insert(spin_options, v)
            end
        end
        local initial_value = option_item.value
        if initial_value == nil then
            initial_value = option_item.default
        end
        local data = {
            is_header = #spin_options == 1 and spin_options[1].text and spin_options[1].text:len() == 0,
            option = option_item,
            initial_value = initial_value,
            selected_value = initial_value,
            spin_options = spin_options,
            spin_options_hover = spin_options_hover,
        }

        table.insert(self.optionwidgets, data)
    end

    self.options_scroll_list = self.optionspanel:AddChild(TEMPLATES.ScrollingGrid(
        self.optionwidgets,
        {
            scroll_context = {
            },
            widget_width  = item_width,
            widget_height = item_height,
            num_visible_rows = 10,
            num_columns = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn = ApplyDataToWidget,
            scrollbar_offset = 20,
            scrollbar_height_offset = -60
        }
    ))
    self.options_scroll_list:SetPosition(0,-6)

    -- Top border of the scroll list.
	self.horizontal_line = self.optionspanel:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
    self.horizontal_line:SetPosition(0,self.options_scroll_list.visible_rows/2 * item_height)
    self.horizontal_line:SetSize(item_width+30, 5)

	if TheInput:ControllerAttached() then
        self.dialog.actions:Hide()
	end

	self.default_focus = self.options_scroll_list
	self:HookupFocusMoves()
end)

function HMRConfigurationClient:GetKeyText(key)
    local deviceId = (TheInput:GetControllerID() + 1) or 1
	return STRINGS.UI.CONTROLSSCREEN.INPUTS[deviceId] and
        STRINGS.UI.CONTROLSSCREEN.INPUTS[deviceId][key] or
        "Unknown"
end

function HMRConfigurationClient:IsBindingConfig(config)
    if not config then return false end
    if config.spin_options then
        return #config.spin_options == 1 and config.spin_options[1] == "binding_common"
    elseif config.options then
        return #config.options == 1 and config.options[1] == "binding_common"
    end
end

function HMRConfigurationClient:GetDefaultOption(option)
    for i,v in pairs(self.options) do
        if v.name == option then
            return v.default
        end
    end
    return nil
end

function HMRConfigurationClient:MapControl(deviceId, widget)
	local controlName = widget.controlName
	local paramName = widget.paramName

    local loc_text = self:GetKeyText(self:GetDefaultOption(paramName))
    local default_text = string.format(STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT, loc_text)
    local body_text = STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT .. "\n\n" .. default_text
	local popup = PopupDialogScreen(controlName, body_text, {})

    popup.dialog.body:SetPosition(0, 0)

    popup.OnRawKey = function(_, key, down)
        if self.is_mapping and not down --[[and key ~= HMR_CONTROLS[paramName]] then
            widget.binding_btn:SetText(self:GetKeyText(key))

            widget.changed_image:Show()

            self.options[widget.real_index].value = key
            self.optionwidgets[widget.real_index].selected_value = key

            widget:ApplyDescription()

            self:MakeDirty()

            TheFrontEnd:PopScreen()

            self.is_mapping = false

            return true
        end
    end

    self.map_popup = popup

	TheFrontEnd:PushScreen(popup)

	self.is_mapping = true
end

function HMRConfigurationClient:CollectSettings()
	local settings = {}
    local binding_settings = {}
	for i, v in pairs(self.optionwidgets) do
        print(v.option.name, v.selected_value)
		if self:IsBindingConfig(v) then
            binding_settings[v.option.name] = v.selected_value
        else
            settings[v.option.name] = v.selected_value
        end
	end

	return settings, binding_settings
end

function HMRConfigurationClient:ResetToDefaultValues()
    -- This resets to the mod's defaults, so it's not the same as backing out.
    -- This may result in many spinners showing modification!

    local function reset()
        for i,v in pairs(self.optionwidgets) do
            self.options[i].value = self.options[i].default
            v.selected_value = self.options[i].default
        end
        self.options_scroll_list:RefreshView()
    end

	if not self:IsDefaultSettings() then
		self:ConfirmRevert(function()
			TheFrontEnd:PopScreen()
			self:MakeDirty()
			reset()
		end)
	end
end

function HMRConfigurationClient:ClearChangedImage()
    local items = self.scrollwidgets
    if items then
        for i, widget in pairs(items) do
            widget.opt.spinner:SetHasModification(false)
            widget.changed_image:Hide()
        end
    end
end

function HMRConfigurationClient:Apply()
	if self:IsDirty() then
		local settings, binding_settings = self:CollectSettings()
        for i, v in pairs(settings) do
            print("111",i, v, self.options[i])
            HMR_UTIL.PrintTable(self.options)
            for key, data in ipairs(self.options) do
                if data.name == i and data.type == "event" then
                    ThePlayer:PushEvent(i.."_dirty", {value = v})
                    settings[i] = self.options[key].default
                end
            end
        end

        HMR_CLIENT_CONFIGS = settings
        HMR_CONTROLS = binding_settings
		HMR_UTIL.SetPersistentString("HMR_CLIENT_CONFIGS", settings)
        HMR_UTIL.SetPersistentString("HMR_CONTROLS", binding_settings)

        self.options_scroll_list:RefreshView()

        for i, v in pairs(self.optionwidgets) do
            v.initial_value = v.selected_value
        end

        self:ClearChangedImage()

        ThePlayer:PushEvent("hmr_config_dirty")

        self:MakeDirty(false)
	else
		self:MakeDirty(false)
	end
end

function HMRConfigurationClient:ConfirmRevert(callback)
	TheFrontEnd:PushScreen(
		PopupDialogScreen( STRINGS.UI.MODSSCREEN.BACKTITLE, STRINGS.UI.MODSSCREEN.BACKBODY,
		  {
		  	{
		  		text = STRINGS.UI.MODSSCREEN.YES,
		  		cb = callback or function() TheFrontEnd:PopScreen() end
			},
			{
				text = STRINGS.UI.MODSSCREEN.NO,
				cb = function()
					TheFrontEnd:PopScreen()
				end
			}
		  }
		)
	)
end

function HMRConfigurationClient:Cancel()
	if self:IsDirty() and not (self.started_default and self:IsDefaultSettings()) then
		self:ConfirmRevert(function()
			self:MakeDirty(false)
			TheFrontEnd:PopScreen()
		end)

        for i, v in pairs(self.optionwidgets) do
            v.initial_value = v.selected_value
        end

        self:ClearChangedImage()
	else
		self:MakeDirty(false)
	    TheFrontEnd:PopScreen()
	end
end

function HMRConfigurationClient:MakeDirty(dirty)
	if dirty ~= nil then
		self.dirty = dirty
	else
		self.dirty = true
	end
end

function HMRConfigurationClient:IsDefaultSettings()
	local alldefault = true
	for i,v in pairs(self.options) do
		-- print(options[i].value, options[i].default)
		if self.options[i].value ~= self.options[i].default then
			alldefault = false
			break
		end
	end
	return alldefault
end

function HMRConfigurationClient:IsDirty()
	return self.dirty
end

function HMRConfigurationClient:OnControl(control, down)
    if HMRConfigurationClient._base.OnControl(self, control, down) then return true end

    if not down then
	    if control == CONTROL_CANCEL then
			self:Cancel()
            return true

	    elseif control == CONTROL_MENU_START and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
            self:Apply()
            return true

        elseif control == CONTROL_MENU_BACK and TheInput:ControllerAttached() then
			self:ResetToDefaultValues()
			return true
        end
	end
end

function HMRConfigurationClient:HookupFocusMoves()

end

function HMRConfigurationClient:GetHelpText()
	local t = {}
	local controller_id = TheInput:GetControllerID()

	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_BACK) .. " " .. STRINGS.UI.MODSSCREEN.RESETDEFAULT)
	if self:IsDirty() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_START) .. " " .. STRINGS.UI.HELP.APPLY)
	end

	return table.concat(t, "  ")
end

return HMRConfigurationClient
