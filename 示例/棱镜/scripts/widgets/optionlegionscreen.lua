local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
-- local TEMPLATES = require "widgets/templates"
local TEMPLATES2 = require "widgets/redux/templates"
local Text = require "widgets/text"
-- local UIAnim = require "widgets/uianim"
-- local ImageButton = require "widgets/imagebutton"
local ScrollableList = require "widgets/scrollablelist"
local Image = require "widgets/image"

local function oncancel(self, doer)
    if not self.isopen then
        return
    end
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
    self:Close()
    doer.HUD.optionlegionscreen = nil
end

local label_width = 220
local spinner_width = 160
local spinner_height = 36
local narrow_field_nudge = -50
local space_between = 5

local enableDisableOptions = { { text = STRINGS.UI.OPTIONS.DISABLED, data = false }, { text = STRINGS.UI.OPTIONS.ENABLED, data = true } }
local shieldKeys = {
    {text = STRINGS.UI_L.KEYNONE, data = 1},
    {text = "A", data = KEY_A},
    {text = "B", data = KEY_B},
    {text = "C", data = KEY_C},
    {text = "D", data = KEY_D},
    {text = "E", data = KEY_E},
    {text = "F", data = KEY_F},
    {text = "G", data = KEY_G},
    {text = "H", data = KEY_H},
    {text = "I", data = KEY_I},
    {text = "J", data = KEY_J},
    {text = "K", data = KEY_K},
    {text = "L", data = KEY_L},
    {text = "M", data = KEY_M},
    {text = "N", data = KEY_N},
    {text = "O", data = KEY_O},
    {text = "P", data = KEY_P},
    {text = "Q", data = KEY_Q},
    {text = "R", data = KEY_R},
    {text = "S", data = KEY_S},
    {text = "T", data = KEY_T},
    {text = "U", data = KEY_U},
    {text = "V", data = KEY_V},
    {text = "W", data = KEY_W},
    {text = "X", data = KEY_X},
    {text = "Y", data = KEY_Y},
    {text = "Z", data = KEY_Z},
    {text = "↑", data = KEY_UP},
    {text = "↓", data = KEY_DOWN},
    {text = "←", data = KEY_LEFT},
    {text = "→", data = KEY_RIGHT},
    {text = ":", data = 59},
    {text = "\"", data = 39}
}

local function AddListItemBackground(w)
	local total_width = label_width + spinner_width + space_between
	w.bg = w:AddChild(TEMPLATES2.ListItemBackground(total_width + 15, spinner_height + 5))
	w.bg:SetPosition(-40,0)
	w.bg:MoveToBack()
end
local function CreateTextSpinner(labeltext, spinnerdata, tooltip_text)
	local w = TEMPLATES2.LabelSpinner(labeltext, spinnerdata, label_width, spinner_width, spinner_height, space_between, nil, nil, narrow_field_nudge, nil, nil, tooltip_text)
	AddListItemBackground(w)
	return w.spinner
end
local function CreateNumericSpinner(labeltext, min, max, tooltip_text)
	local w = TEMPLATES2.LabelNumericSpinner(labeltext, min, max, label_width, spinner_width, spinner_height, space_between, nil, nil, narrow_field_nudge, tooltip_text)
	AddListItemBackground(w)
	return w.spinner
end
local function CreateCheckBox(labeltext, onclicked, checked, tooltip_text)
	local w = TEMPLATES2.OptionsLabelCheckbox(onclicked, labeltext, checked, label_width, spinner_width, spinner_height, spinner_height + 15, space_between, CHATFONT, nil, narrow_field_nudge, tooltip_text)
	AddListItemBackground(w)
	return w.button
end

local OptionLegionScreen = Class(Screen, function(self, owner)
    Screen._ctor(self, "OptionsLegion")
    local OPTS = CONFIGS_LEGION
    self.owner = owner
    self.isopen = false
    self.options = { --原始设置数据
        DRAGABLEUI = OPTS.DRAGABLEUI,
        SHIELDKEY = OPTS.SHIELDKEY,
        SHIELDMOUSE = OPTS.SHIELDMOUSE,
        SIVMASKMOUSE = OPTS.SIVMASKMOUSE,
        MOUSEINFOCLIENT = OPTS.MOUSEINFOCLIENT
    }
    self.working = deepcopy(self.options)
    self.dirty = false

    local canresetuipos
    local x, y
    -- self._scrnw, self._scrnh = TheSim:GetScreenSize()
    for _, v in pairs(OPTS.DD_UIDRAG) do --说明有拖拽缓存，需要展示可清理选项
        canresetuipos = true
        break
    end

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    self.scalingroot = self:AddChild(Widget("optionlegionscreenscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
    self.inst:ListenForEvent("continuefrompause", function()
        if self.isopen then
            self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
        end
    end, TheWorld)
    self.inst:ListenForEvent("refreshhudsize", function(hud, scale)
        if self.isopen then
            self.scalingroot:SetScale(scale)
        end
    end, owner.HUD.inst)

    self.root = self.scalingroot:AddChild(Widget("optionlegionscreenroot"))
    -- self.root:SetScale(.6, .6, .6) --这样会导致给整体一个缩放，不好判定大小

    ------全屏透明背景，点击即可关闭该界面
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    self.black.OnMouseButton = function() oncancel(self, self.owner) end

    local w_half = label_width + spinner_width + space_between
    local h_all = spinner_height*10 + 200
    local h_spinners_list = spinner_height*10 + space_between*9 --10行的高度 + 9个间隔
    local y_spinners_list = (h_all-h_spinners_list)/2 - 15
    local h_keys_shieldkey = 135+6+spinner_height+5 --3个按钮大小+两个间隔+标题高度+与标题间隔

    ------熔炉风格的背景
    self.bg = self.root:AddChild(TEMPLATES2.RectangleWindow(w_half*2+30+10, h_all))
    self.bg:SetPosition(0, 0)

    ------设置介绍
    self.ttip = self.root:AddChild(Text(CHATFONT, 25, ""))
    y = y_spinners_list - h_spinners_list/2 -15 -60
	self.ttip:SetPosition(0, y-10)
	self.ttip:SetHAlign(ANCHOR_LEFT)
	self.ttip:SetVAlign(ANCHOR_TOP)
	self.ttip:SetRegionSize(w_half*1.8, 110)
	self.ttip:EnableWordWrap(true)
    ------设置介绍的分割线
	self.ttip_line = self.root:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
	self.ttip_line:SetPosition(0, y + 50)
    self.bg.OnGainFocus = function()
        self.ttip:SetString("")
        self.ttip_line:Hide()
    end

    ------左边选项区域
    local strings = STRINGS.UI_L
    x = w_half/2
    y = (h_all-h_keys_shieldkey)/2 - 10
    ------按钮集：举盾快捷键
    self.keys_shieldkey = self:CreateKeyList(w_half, h_keys_shieldkey, self.working.SHIELDKEY, function(lastbtn, btn)
        self.working.SHIELDKEY = btn._dd_l.data or 1
    end, strings.KEYBOUND, strings.SHIELDKEY.TITLE)
    self.keys_shieldkey:SetPosition(-x, y)
    self.keys_shieldkey.tooltip_text = strings.SHIELDKEY.TIP
    self:AddSpinnerTooltip(self.keys_shieldkey)

    -- self.fxVolume = CreateNumericSpinner(STRINGS.UI.OPTIONS.FX, 0, 10, STRINGS.UI.OPTIONS.TOOLTIPS.FX)
	-- self.fxVolume.OnChanged = function(_, data)
    --     print("data_"..tostring(data).."_"..tostring(type(data)))
    --     -- self:UpdateMenu()
    -- end
    -- self.root:AddChild(self.fxVolume.parent) 
    -- self.fxVolume.parent:SetPosition(-x, y)

    -- self.pp = CreateTextSpinner(STRINGS.UI.OPTIONS.SCAPBOOKHUDDISPLAY, enableDisableOptions, STRINGS.UI.OPTIONS.TOOLTIPS.SCAPBOOKHUDDISPLAY)
	-- self.pp.OnChanged = function(_, data)
    --     print("data_"..tostring(data).."_"..tostring(type(data)))
    --     -- self:UpdateMenu()
    -- end
    -- self.root:AddChild(self.pp.parent)
    -- y = y-spinner_height-5
    -- self.pp.parent:SetPosition(-x, y)

    ------右边选项区域
    self.right_spinners = {}
    ------勾选：右键触发举盾
    self.s_shieldmouse = CreateCheckBox(strings.SHIELDMOUSE.TITLE, function()
        self.working.SHIELDMOUSE = not self.working.SHIELDMOUSE
        return self.working.SHIELDMOUSE
    end, self.working.SHIELDMOUSE, strings.SHIELDMOUSE.TIP)
    table.insert(self.right_spinners, self.s_shieldmouse)
    ------勾选：ui可拖动
    self.s_dragableui = CreateCheckBox(strings.DRAGABLEUI.TITLE, function()
        self.working.DRAGABLEUI = not self.working.DRAGABLEUI
        return self.working.DRAGABLEUI
    end, self.working.DRAGABLEUI, strings.DRAGABLEUI.TIP)
    table.insert(self.right_spinners, self.s_dragableui)
    ------勾选：还原容器UI位置
    if canresetuipos then
        self.s_resetuipos = CreateCheckBox(strings.RESETUIPOS.TITLE, function()
            local now = not self.working.RESETUIPOS
            self.working.RESETUIPOS = now
            return now
        end, self.working.RESETUIPOS, strings.RESETUIPOS.TIP)
        table.insert(self.right_spinners, self.s_resetuipos)
    end
    ------勾选：右键触发子圭·歃技能
    self.s_sivmaskmouse = CreateCheckBox(strings.SIVMASKMOUSE.TITLE, function()
        self.working.SIVMASKMOUSE = not self.working.SIVMASKMOUSE
        return self.working.SIVMASKMOUSE
    end, self.working.SIVMASKMOUSE, strings.SIVMASKMOUSE.TIP)
    table.insert(self.right_spinners, self.s_sivmaskmouse)
    ------勾选：鼠标悬停展示特殊信息
    self.s_mouseinfoclient = CreateCheckBox(strings.MOUSEINFOCLIENT.TITLE, function()
        self.working.MOUSEINFOCLIENT = not self.working.MOUSEINFOCLIENT
        return self.working.MOUSEINFOCLIENT
    end, self.working.MOUSEINFOCLIENT, strings.MOUSEINFOCLIENT.TIP)
    table.insert(self.right_spinners, self.s_mouseinfoclient)

    ------将选项们生成滚动列表。这样就不怕选项太多装不下了。但我怀疑我都用不到那么多选项
    self.right_spinners_parent = {}
    for _, v in ipairs(self.right_spinners) do
        self:AddSpinnerTooltip(v.parent) --鼠标移上去会显示选项介绍
        table.insert(self.right_spinners_parent, v.parent)
    end
    self.spinners_list = self.root:AddChild(ScrollableList(
        self.right_spinners_parent, w_half, h_spinners_list, spinner_height, space_between,
        nil, nil, x+10, nil, nil, nil, nil, nil, "GOLD"))
    self.spinners_list:SetPosition(x+40, y_spinners_list)

    --准备妥当，显示！
    self.isopen = true
    self:Show()

    SetAutopaused(true)
end)

function OptionLegionScreen:CreateKeyList(w, h, vnow, fn, chosentip, title)
    local wlist = self.root:AddChild( Widget( "wlist"..tostring(math.random(100)) ) )
    ------灰黑色半透明背景。统一风格用的
    wlist.bg = wlist:AddChild(TEMPLATES2.ListItemBackground(w + 15, h))
	wlist.bg:SetPosition(-40, 0)
	-- wlist.bg:MoveToBack()

    wlist.label = wlist:AddChild( Text(CHATFONT, 25, title) )
    wlist.label:SetPosition((-w/2)+(label_width/2)-30, (h-spinner_height)/2-7.5)
    wlist.label:SetRegionSize(label_width, spinner_height)
    wlist.label:SetHAlign(ANCHOR_RIGHT)
    wlist.label:SetColour(UICOLOURS.GOLD)

    wlist.label2 = wlist:AddChild( Text(CHATFONT, 25, "") )
    wlist.label2:SetPosition((w/2)-(spinner_width/2)-10, (h-spinner_height)/2-7.5)
    wlist.label2:SetRegionSize(spinner_width, spinner_height)
    wlist.label2:SetHAlign(ANCHOR_LEFT)
    wlist.label2:SetColour(UICOLOURS.GOLD)

    local lastbtn
    local btns = {}
    local start_x = 0
    local itemcount = 0
    local x = start_x
    local item_w = nil
    local itemlist = {}
    for i, v in ipairs(shieldKeys) do
        if item_w == nil then --由于 ScrollableList 只能竖向排列，所以将每行按钮放入一个整体的横向组件来归纳整齐
            item_w = wlist:AddChild( Widget( "wlistrow"..tostring(v.text)..tostring(v.data) ) )
            table.insert(itemlist, item_w)
        end
        local a = item_w:AddChild(TEMPLATES2.StandardButton(function()
            if fn ~= nil then
                fn(lastbtn, btns[i])
            end
            if lastbtn ~= nil then --恢复之前那个按钮
                lastbtn:Enable()
                -- lastbtn:SetText(lastbtn._dd_l.text)
                lastbtn:ClearHoverText()
            end
            lastbtn = btns[i]
            lastbtn:Disable()
            -- lastbtn:SetText("·"..lastbtn._dd_l.text.."·")
            wlist.label2:SetString(lastbtn._dd_l.text)
            if chosentip ~= nil then
                lastbtn:SetHoverText(chosentip)
            end
        end, v.text, {45,45}, nil)) --按钮大小
        a.ongainfocus = function()
            if self.ttip ~= nil and wlist.tooltip_text ~= nil then
                self.ttip:SetString(wlist.tooltip_text)
                self.ttip_line:Show()
            end
        end
        btns[i] = a
        a._dd_l = v --记下自己对应的数据
        a:SetPosition(x, 0)
        if vnow == v.data then
            lastbtn = a
            a:Disable()
            -- a:SetText("·"..v.text.."·")
            wlist.label2:SetString(v.text)
            if chosentip ~= nil then
                a:SetHoverText(chosentip)
            end
        end
        itemcount = itemcount + 1
        if itemcount >= 8 then --一排最多摆n个皮肤
            item_w = nil
            x = start_x
            itemcount = 0
        else
            x = x + 45
        end
    end
    wlist.scroll_btns = wlist:AddChild(ScrollableList(itemlist, w, 110, 38, 2,
        nil, nil, 19, nil, nil, nil, nil, nil, "GOLD"))
    wlist.scroll_btns:SetPosition(-24, -5)
    return wlist
end
function OptionLegionScreen:AddSpinnerTooltip(widget)
	self.ttip_line:Hide()
	local function ongainfocus(is_enabled)
		if self.ttip ~= nil and widget.tooltip_text ~= nil then
			self.ttip:SetString(widget.tooltip_text)
			self.ttip_line:Show()
		end
	end
	local function onlosefocus(is_enabled)
		if widget.parent and not widget.parent.focus then
			self.ttip:SetString("")
			self.ttip_line:Hide()
		end
	end

	widget.bg.ongainfocus = ongainfocus

	if widget.spinner then
		widget.spinner.ongainfocusfn = ongainfocus
	elseif widget.button then -- Handles the data collection checkbox option
		widget.button.ongainfocus = ongainfocus
	end

	widget.bg.onlosefocus = onlosefocus

	if widget.spinner then
		widget.spinner.onlosefocusfn = onlosefocus
	elseif widget.button then -- Handles the data collection checkbox option
		widget.button.onlosefocus = onlosefocus
	end
end

function OptionLegionScreen:Close()
    if self.isopen then
        self.black:Kill()
        self.isopen = false
        self.inst:DoTaskInTime(0.3, function() TheFrontEnd:PopScreen(self) end)
    end
end
function OptionLegionScreen:OnControl(control, down)
    if OptionLegionScreen._base.OnControl(self,control, down) then return true end
    if not down and (control == CONTROL_MAP or control == CONTROL_CANCEL) then --地图键或取消键
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        TheFrontEnd:PopScreen()
        return true
    end
end
function OptionLegionScreen:OnDestroy()
    SetAutopaused(false)
    local OPTS = CONFIGS_LEGION

    if self.working.RESETUIPOS then --还原容器ui的位置
        self.dirty = true
        OPTS.DD_UIDRAG = {}
        for k, v in pairs(OPTS.DD_UIBASE) do
            if k.inst ~= nil and k.inst:IsValid() then --客户端容器UI还显示着时，就直接恢复位置。已经关闭的就不用管了
                k:SetPosition(v)
            end
        end
        OPTS.DD_UIBASE = {}
    end
    local nowv
    for k, v in pairs(self.options) do
        nowv = self.working[k]
        if nowv ~= nil and nowv ~= v then --数据发生了变化，就说明玩家改了设置
            OPTS[k] = nowv
            self.dirty = true
        end
    end

    local actionfix = { "SHIELDMOUSE", "SIVMASKMOUSE" }
    nowv = false
    for _, v in ipairs(actionfix) do
        if self.working[v] ~= self.options[v] then
            nowv = true
            break
        end
    end
    if nowv then
        OPTS.ActionFix(self.owner, OPTS)
        if not TheNet:GetIsServer() then --单纯的客户端。还需要通知服务器，完成数据同步
            OPTS.DoRpcActionFix()
        end
    end

    if self.dirty then
        OPTS.SaveClientData() --存储客户端数据
    end

	OptionLegionScreen._base.OnDestroy(self)
end

return OptionLegionScreen
