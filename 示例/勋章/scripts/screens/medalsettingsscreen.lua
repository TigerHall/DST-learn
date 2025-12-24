local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"

local TEMPLATES = require "widgets/redux/templates"
local ScrollableList = require "widgets/scrollablelist"

local PANELHEIGHT = 400

local MedalSettingsScreen =
    Class(
    Screen,
    function(self, owner, attach)
        Screen._ctor(self, "MedalSettingsScreens")

        self.owner = owner
        self.attach = attach

        self.isopen = false

        self._scrnw, self._scrnh = TheSim:GetScreenSize()--屏幕宽高

        self:SetScaleMode(SCALEMODE_PROPORTIONAL)--等比缩放模式
        self:SetMaxPropUpscale(MAX_HUD_SCALE)--设置界面最大比例上限
        self:SetPosition(0, 0, 0)--设置坐标
        self:SetVAnchor(ANCHOR_MIDDLE)
        self:SetHAnchor(ANCHOR_MIDDLE)

        self.scalingroot = self:AddChild(Widget("medaldeliveryscalingroot"))
        self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
		--监听从暂停状态恢复到继续状态，更新尺寸
        self.inst:ListenForEvent(
            "continuefrompause",
            function()
                if self.isopen then
                    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
                end
            end,
            TheWorld
        )
		--监听界面尺寸变化，更新尺寸
        self.inst:ListenForEvent(
            "refreshhudsize",
            function(hud, scale)
                if self.isopen then
                    self.scalingroot:SetScale(scale)
                end
            end,
            owner.HUD.inst
        )

        self.root = self.scalingroot:AddChild(TEMPLATES.ScreenRoot("root"))

        -- secretly this thing is a modal Screen, it just LOOKS like a widget
        --全屏全透明背景板，点了直接关闭界面
		self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
        self.black:SetVRegPoint(ANCHOR_MIDDLE)
        self.black:SetHRegPoint(ANCHOR_MIDDLE)
        self.black:SetVAnchor(ANCHOR_MIDDLE)
        self.black:SetHAnchor(ANCHOR_MIDDLE)
        self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
        self.black:SetTint(0, 0, 0, 0)
        self.black.OnMouseButton = function()
            self:OnCancel()
        end
		--总界面
        self.destspanel = self.root:AddChild(TEMPLATES.CurlyWindow(200, PANELHEIGHT))
        self.destspanel:SetPosition(0, 25)
		--标题
        self.current = self.destspanel:AddChild(Text(BODYTEXTFONT, 35))
        self.current:SetPosition(0, PANELHEIGHT - 150, 0)--坐标
        self.current:SetRegionSize(250, 50)--设置区域大小
        self.current:SetHAlign(ANCHOR_MIDDLE)
		self.current:SetString(STRINGS.MEDAL_SETTING_UI.TITLE)
        self.current:SetColour(1, 1, 1, 1)--默认颜色

        -- self:LoadButton()
        self:LoadSettingButton()

        self:Show()--显示
        self.isopen = true--开启

        SetAutopaused(true)
        --打开时默认选中层级(手柄用)
        if TheInput:ControllerAttached() and self.dests_scroll_list then
            self.dests_scroll_list:SetFocus()
        end
    end
)
--按钮信息
local button_data={
    {--显示物品代码
        text=STRINGS.MEDAL_SETTING_UI.LOOK_PREFAB,
        spinner_data={
            spinnerdata={
                {text=STRINGS.MEDAL_SETTING_UI.CLOSE,data=false},
                {text=STRINGS.MEDAL_SETTING_UI.OPEN,data=true},
            },
            onchanged_fn=function(spinner_data)
                TUNING.MEDAL_TEST_SWITCH=spinner_data
                SaveMedalSettingData()
            end,
            selected_fn=function(spinner)
                spinner:SetSelected(TUNING.MEDAL_TEST_SWITCH)
            end,
        },
    },
    {--调整坎普斯宝匣容器优先级
        text=STRINGS.MEDAL_SETTING_UI.KRAMPUS_CHEST,
        spinner_data={
            spinnerdata={
                {text=STRINGS.MEDAL_SETTING_UI.HIGHER,data=0},
                {text=STRINGS.MEDAL_SETTING_UI.MEDIUM,data=1},
                {text=STRINGS.MEDAL_SETTING_UI.LOWEST,data=2},
            },
            onchanged_fn=function(spinner_data)
                TUNING.MEDAL_KRAMPUS_CHEST_PRIORITY=spinner_data
                SaveMedalSettingData()
            end,
            selected_fn=function(spinner)
                spinner:SetSelected(TUNING.MEDAL_KRAMPUS_CHEST_PRIORITY)
            end,
        },
    },
    {--BUFF倒计时面板
        text=STRINGS.MEDAL_SETTING_UI.SHOW_BUFF,
        spinner_data={
            spinnerdata={
                {text=STRINGS.MEDAL_SETTING_UI.CLOSE,data=0},
                {text=STRINGS.MEDAL_SETTING_UI.OPEN,data=1},
                {text=STRINGS.MEDAL_SETTING_UI.SHOWALL,data=2},
            },
            onchanged_fn=function(spinner_data)
                TUNING.MEDAL_BUFF_SETTING=spinner_data
                SendModRPCToServer(MOD_RPC.functional_medal.ToggleBuffTask, TUNING.MEDAL_BUFF_SETTING)--同步下Buff面板设置
                SaveMedalSettingData()
            end,
            selected_fn=function(spinner)
                spinner:SetSelected(TUNING.MEDAL_BUFF_SETTING)
            end,
        },
    },
    {--调整勋章tips信息显示
        text=STRINGS.MEDAL_SETTING_UI.SHOW_MEDAL_INFO,
        spinner_data={
            spinnerdata={
                {text=STRINGS.MEDAL_SETTING_UI.CLOSE,data=0},
                {text=STRINGS.MEDAL_SETTING_UI.MUST,data=1},
                {text=STRINGS.MEDAL_SETTING_UI.SHOWALL,data=2},
            },
            onchanged_fn=function(spinner_data)
                TUNING.MEDAL_SHOW_INFO=spinner_data
                SaveMedalSettingData()
            end,
            selected_fn=function(spinner)
                spinner:SetSelected(TUNING.MEDAL_SHOW_INFO)
            end,
        },
    },
    {--容器拖拽
        text=STRINGS.MEDAL_SETTING_UI.CONTAINER_DRAG,
        spinner_data={
            spinnerdata={
                {text=STRINGS.MEDAL_SETTING_UI.CLOSE,data=false},
                {text=STRINGS.MEDAL_SETTING_UI.OPEN,data=true},
            },
            onchanged_fn=function(spinner_data)
                TUNING.MEDAL_CLIENT_DRAG_SWITCH=spinner_data
                SaveMedalSettingData()
            end,
            selected_fn=function(spinner)
                spinner:SetSelected(TUNING.MEDAL_CLIENT_DRAG_SWITCH)
            end,
        },
    },
    {--弹弓锁敌
        text=STRINGS.MEDAL_SETTING_UI.SLINGSHOT_LOCK,
        spinner_data={
            spinnerdata={
                {text=STRINGS.MEDAL_SETTING_UI.CLOSE,data=0},
                {text=1,data=1},
                {text=1.25,data=1.25},
                {text=1.5,data=1.5},
                {text=1.75,data=1.75},
                {text=2,data=2},
                {text=2.25,data=2.25},
                {text=2.5,data=2.5},
            },
            onchanged_fn=function(spinner_data)
                TUNING.MEDAL_LOCK_TARGET_RANGE_MULT=spinner_data
                SaveMedalSettingData()
            end,
            selected_fn=function(spinner)
                spinner:SetSelected(TUNING.MEDAL_LOCK_TARGET_RANGE_MULT)
            end,
        },
    },
    {--访问介绍页
        text=STRINGS.MEDAL_SETTING_UI.MEDAL_PAGE,
        fn=function()
            VisitURL("https://www.guanziheng.com/", false)
        end
    },
    {--重置拖拽坐标
        text=STRINGS.MEDAL_SETTING_UI.RESET_UI,
        fn=function()
            ResetMedalUIPos()
        end
    },
    {--宣告标签
        text=STRINGS.MEDAL_SETTING_UI.SHOWTAGSNUM,
        fn=function()
            dm_counttags()
            if ThePlayer and ThePlayer.HUD then
                ThePlayer.HUD:CloseMedalSettingsScreen()
            end
        end
    },
    {--使用兑换码
        text=STRINGS.MEDAL_SETTING_UI.USECKD,
        fn=function()
            if ThePlayer and ThePlayer.HUD then
                ThePlayer.HUD:ShowMedalUsecdkScreen()
                ThePlayer.HUD:CloseMedalSettingsScreen()
            end
        end
    },
    {--关闭按钮
        text=STRINGS.MEDAL_SETTING_UI.CLOSE,
        fn=function()
            if ThePlayer and ThePlayer.HUD then
                ThePlayer.HUD:CloseMedalSettingsScreen()
            end
        end
    },
}

--加载设置列表
function MedalSettingsScreen:LoadSettingButton()
    --滚动选项卡构造函数
    local function ScrollWidgetsCtor(context, index)
        local widget = Widget("widget-" .. index)--生成选项卡，编号不同

        widget:SetOnGainFocus(
            function()
                self.dests_scroll_list:OnWidgetFocus(widget)
            end
        )
        --两种类型的设置组件都要构造,实际用到哪个就隐藏另一个
		widget.spinneritem = widget:AddChild(TEMPLATES.LabelSpinner( "default",{},120,120,nil,nil,nil,22))
		widget.spinneritem:Hide()
		widget.settingbutton = widget:AddChild(TEMPLATES.StandardButton(nil,"default button",{200,40}))
		widget.settingbutton:Hide()

        return widget
    end
    --应用选项卡数据
    local function ApplyDataToWidget(context, widget, data, index)
        if not data then
            return
        end
        --是调整按钮的话就添加对应的数据选项
        if data.spinner_data then
            widget.spinneritem:Show()
            widget.settingbutton:Hide()
            if widget.spinneritem.label then
                widget.spinneritem.label:SetString(data.text)
            end
            if widget.spinneritem.spinner then
                widget.spinneritem.spinner:SetOptions(data.spinner_data.spinnerdata)
                widget.spinneritem.spinner:SetOnChangedFn(data.spinner_data.onchanged_fn)
                if data.spinner_data.selected_fn then
                    data.spinner_data.selected_fn(widget.spinneritem.spinner)
                end
            end
            widget.focus_forward = widget.spinneritem
        else--单纯的按钮的话设置对应的触发回调
            widget.spinneritem:Hide()
            widget.settingbutton:Show()
            widget.settingbutton:SetText(data.text)
            widget.settingbutton:SetOnClick(data.fn)
            widget.focus_forward = widget.settingbutton
        end
    end
    
    --如果没有滚动选项卡列表，则创建
    if not self.dests_scroll_list then
        self.dests_scroll_list =
            self.destspanel:AddChild(
            TEMPLATES.ScrollingGrid(
                button_data,
                {
                    context = {},
                    widget_width = 220,--选项卡宽度
                    widget_height = 40,--高度
                    num_visible_rows = 11,--可见行数
                    num_columns = 1,--列数
                    item_ctor_fn = ScrollWidgetsCtor,--构造滚动选项卡
                    apply_fn = ApplyDataToWidget,--应用数据
                    scrollbar_offset = 10,--滚动条横向偏移值
                    scrollbar_height_offset = -60,--滚动条纵向偏移值
                    peek_percent = 0, --在底部可以看到多少行，相当于拉到底了还能往上拉多少
                    -- allow_bottom_empty_row = true --是否允许底部有空行
                }
            )
        )

        self.dests_scroll_list:SetPosition(0, 0)
        self.destspanel.focus_forward = self.dests_scroll_list--设置焦点
    end
end

--关闭
function MedalSettingsScreen:OnCancel()
	if not self.isopen then
        return
    end
	--关闭界面
    self.owner.HUD:CloseMedalSettingsScreen()
end

--其他控制
function MedalSettingsScreen:OnControl(control, down)
    if MedalSettingsScreen._base.OnControl(self, control, down) then
        return true
    end

    if not down and (control == CONTROL_MAP or control == CONTROL_CANCEL) then
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        TheFrontEnd:PopScreen()
        SetAutopaused(false)
        return true
    end
	return false
end
--关闭
function MedalSettingsScreen:Close()
	if self.isopen then
        self.black:Kill()
        self.isopen = false

        self.inst:DoTaskInTime(
            .2,
            function()
                TheFrontEnd:PopScreen(self)
            end
        )
    end
    SetAutopaused(false)
end

return MedalSettingsScreen
