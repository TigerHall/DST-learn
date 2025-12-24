--------------------------------
--[[ SensoryMonitorWidget: 监视widget]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-09]]
--[[ @updateTime: 2022-01-09]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local ImageButton = require "widgets/imagebutton"
local Screen = require "widgets/screen"
local PlayerUtil = require("util/player_util")
local SensoryMonitorFn = require("function/sensory_monitor_fn")

-- 定义每一项内的控件布局
local function InitDestItem()
    local dest = Widget("destination")
    local width, height = 380, 50
    -- 移动
    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(width, height, function() end))
    dest.backing.move_on_click = true -- 点击背景略微移动

    -- 名字文件控件
    dest.name = dest:AddChild(Text(BODYTEXTFONT, 35))
    dest.name:SetColour(255, 255, 255, 1)
    dest.name:SetVAlign(ANCHOR_MIDDLE)
    dest.name:SetHAlign(ANCHOR_MIDDLE)
    dest.name:SetRegionSize(380, 40)
    -- 将定义好的组件返回
    return dest
end

-- 初始化每一项的方法
local function DestItemCtor(context, index)
    local widget = Widget("widget-"..index)

    widget:SetOnGainFocus(function()
        local scrollpanel = context.playerScrollPanel.shown and context.playerScrollPanel  or context.cameraScrollPanel
        if scrollpanel ~= nil then
            scrollpanel:OnWidgetFocus(widget)
        end
    end)
    -- self:InitDestItem() 每一项里的控件布局
    widget.destitem = widget:AddChild(InitDestItem())

    return widget
end

-- 给每一项赋值，添加事件的方法
local function DestApply(context, widget, data, index)
    widget.destitem:Hide()
    if data then
        local width = widget.destitem.name:GetRegionSize()
        local maxChars = 36
        widget.destitem.name:SetTruncatedString(data.name, width, maxChars, true)
        widget.destitem.name.type = data.type
        widget.destitem.name.index = data.index
        widget.destitem.name.userid = data.userid
        widget.destitem.name.guid = data.guid
        widget.destitem.backing:SetOnClick(function()
            -- 发送服务器进行切换
            -- 不能直接发送items 客户端拿到的items 并没有
            Logger:Debug({"切换监控目标",TUNING.DORAEMON_TECH.MODNAME,data})
            SendModRPCToServer(MOD_RPC[TUNING.DORAEMON_TECH.MODNAME]["senory_monitor.change"], widget.destitem.name.type,widget.destitem.name.userid,widget.destitem.name.guid)
            -- 关闭监控面板
            TheFrontEnd:PopScreen(context)
        end)
        widget.destitem:Show()
    end
end

--[[切换面板]]
local SensoryMonitorPanel = Class(Screen, function(self, owner)
    Screen._ctor(self, "SensoryMonitorPanel")
    self.owner = owner
    -- 面板
    self.panel = self:AddChild(TEMPLATES.RectangleWindow(400, 550, STRINGS.DORAEMON_TECH.DORAEMON_SENSORY_MONITOR_PANEL, {
        {
            text = STRINGS.DORAEMON_TECH.DORAEMON_SENSORY_MONITOR_PANEL_CLOSE,
            cb = function()
                TheFrontEnd:PopScreen(self)
                -- self:Hide()
            end,
            offset = nil
        },
    }))
    self.panel:SetVAnchor(ANCHOR_MIDDLE)
    self.panel:SetHAnchor(ANCHOR_MIDDLE)
    self.panel:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.panel:SetMaxPropUpscale(MAX_HUD_SCALE)
    -- 玩家按钮
    local normalColor = {1,1,1,1}
    local unSelectedColor = {119/255,136/255,153/255,1}
    self.panel.playerBtn = self.panel:AddChild(TEMPLATES.StandardButton(nil, STRINGS.DORAEMON_TECH.DORAEMON_SENSORY_MONITOR_PANEL_PLAYER_BTN, {100, 50}))
    --self.panel.playerBtn:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.panel.playerBtn:SetPosition(-100, 190)
    self.panel.playerBtn:SetImageNormalColour(unpack(normalColor))
    self.panel.playerBtn:SetImageFocusColour(unpack(normalColor))
    self.panel.playerBtn:SetImageSelectedColour(unpack(normalColor))
    self.panel.playerBtn:SetOnClick(function ()
        if self.playerScrollPanel ~= nil and self.cameraScrollPanel ~= nil then
            if not  self.playerScrollPanel.shown then
                -- 选中
                self.panel.playerBtn:SetImageNormalColour(unpack(normalColor))
                self.panel.playerBtn:SetImageFocusColour(unpack(normalColor))
                self.panel.playerBtn:SetImageSelectedColour(unpack(normalColor))
                self.panel.cameraBtn:SetImageNormalColour(unpack(unSelectedColor))
                self.panel.cameraBtn:SetImageFocusColour(unpack(unSelectedColor))
                self.panel.cameraBtn:SetImageSelectedColour(unpack(unSelectedColor))
                self:UpdatePlayerScrollPanel()
                self.playerScrollPanel:Show()
                self.cameraScrollPanel:Hide()
            end
        end
    end)
    -- 摄像头按钮
    self.panel.cameraBtn = self.panel:AddChild(TEMPLATES.StandardButton(nil, STRINGS.DORAEMON_TECH.DORAEMON_SENSORY_MONITOR_PANEL_CAMERA_BTN, {100, 50}))
    --self.panel.cameraBtn:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.panel.cameraBtn:SetPosition(100, 190)
    self.panel.cameraBtn:SetImageNormalColour(unpack(unSelectedColor))
    self.panel.cameraBtn:SetImageFocusColour(unpack(unSelectedColor))
    self.panel.cameraBtn:SetImageSelectedColour(unpack(unSelectedColor))
    self.panel.cameraBtn:SetOnClick(function ()
        if self.playerScrollPanel ~= nil and self.cameraScrollPanel ~= nil then
            if not  self.cameraScrollPanel.shown then
                -- 选中
                self.panel.playerBtn:SetImageNormalColour(unpack(unSelectedColor))
                self.panel.playerBtn:SetImageFocusColour(unpack(unSelectedColor))
                self.panel.playerBtn:SetImageSelectedColour(unpack(unSelectedColor))
                self.panel.cameraBtn:SetImageNormalColour(unpack(normalColor))
                self.panel.cameraBtn:SetImageFocusColour(unpack(normalColor))
                self.panel.cameraBtn:SetImageSelectedColour(unpack(normalColor))
                self:UpdateCameraScrollPanel()
                self.playerScrollPanel:Hide()
                self.cameraScrollPanel:Show()
            end
        end
    end)

    ------------------------------------scroll-----------------------------------------
    self:UpdateAllPanel()
    -----------------------------------------------------------------------------------
    -- 最后要把滚动条挂到父组件上的 self.default_focus 对象上去
    self.default_focus = self.playerScrollPanel
end)



-- 支持ESC 关闭面板
function SensoryMonitorPanel:OnControl(control, down)
    -- 先调用原逻辑,含各种点击操作,如果没有这一行,该面板上的操作只有ESC
    if SensoryMonitorPanel._base.OnControl(self,control, down) then return true end
    -- 额外支持ESC关闭面板
    if control == CONTROL_CANCEL and not down then
        TheFrontEnd:PopScreen(self)
        return true
    end
end


-- 更新玩家滚动条
function SensoryMonitorPanel:UpdatePlayerScrollPanel()
    Logger:Debug({"replica",TheWorld.net.replica},2)
    self.destPlayerItems = TheWorld.net.replica.doraemon_sensory_monitor:GetPlayers()
    if self.playerScrollPanel == nil then
        self.playerScrollPanel = self.panel:AddChild(TEMPLATES.ScrollingGrid(self.destPlayerItems, {
            scroll_context = self,
            num_columns = 1,             -- 有几个滚动条
            num_visible_rows = 8,        -- 滚动条内最多显示多少行
            item_ctor_fn = DestItemCtor, -- 每一项的构造方法
            apply_fn = DestApply,        -- 给每一项赋值，添加事件等
            widget_width = 380,          -- 每一项的宽
            widget_height = 50,          -- 每一项的高
            end_offset = nil,
        }))
        self.playerScrollPanel:SetPosition(0,-30)
    else
        -- 更新即可
        self.playerScrollPanel:SetItemsData(self.destPlayerItems)
    end
end

-- 更新摄像头滚动条
function SensoryMonitorPanel:UpdateCameraScrollPanel()
    self.destCameraItems = TheWorld.net.replica.doraemon_sensory_monitor:GetCameras()
    if self.cameraScrollPanel == nil then
        self.cameraScrollPanel = self.panel:AddChild(TEMPLATES.ScrollingGrid(self.destCameraItems, {
            scroll_context = self,
            num_columns = 1,             -- 有几个滚动条
            num_visible_rows = 8,        -- 滚动条内最多显示多少行
            item_ctor_fn = DestItemCtor, -- 每一项的构造方法
            apply_fn = DestApply,        -- 给每一项赋值，添加事件等
            widget_width = 380,          -- 每一项的宽
            widget_height = 50,          -- 每一项的高
            end_offset = nil,
        }))
        self.cameraScrollPanel:SetPosition(0,-30)
        self.cameraScrollPanel:Hide()
    else
        -- 更新即可
        self.cameraScrollPanel:SetItemsData(self.destCameraItems)
    end
end

-- 更新所有滚动条
function SensoryMonitorPanel:UpdateAllPanel()
    Logger:Debug("更新SensoryMonitorPanel")
    self:UpdatePlayerScrollPanel()
    self:UpdateCameraScrollPanel()
end

return SensoryMonitorPanel