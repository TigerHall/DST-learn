local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local ScrollableList = require "widgets/scrollablelist"
local TEMPLATES = require "widgets/redux/templates"

-- 储存UI常量
local ENCYCLOPEDIA_CONSTANTS = {
    MAIN_BG_SIZE = {800, 600},
    LIST_BG_SIZE = {550, 400},
    BUTTON_SIZE = {500, 40},
    ITEM_HEIGHT = 45,
    ITEM_SPACING = 5,
    LIST_SIZE = {500, 350},
    BUTTON_OFFSET_X = 250,
    SCROLL_BAR_OFFSET = 80,
    TITLE_Y = 250,
    CLOSE_BUTTON_POS = {280, -220},
    BACK_BUTTON_POS = {-280, -220},
    LIST_BG_Y = -25
}

-- 显示百科目录的界面，统一使用两层嵌套代表百科数据表的第一级和第二级的目录内容
local EncyclopediaIndex = Class(Screen, function(self, data)
    Screen._ctor(self, "EncyclopediaIndex")
    
    -- 验证数据
    if not data or not data.sections then
        print("Warning: Invalid encyclopedia data provided")
        data = {title = "Encyclopedia", sections = {}}
    end
    
    self.data = data
    
    -- 设置界面缩放和位置
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
    
    -- 主背景
    self.bg = self:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
    self.bg:SetSize(unpack(ENCYCLOPEDIA_CONSTANTS.MAIN_BG_SIZE))
    self.bg:SetPosition(0, 0)
    
    -- 标题
    self.title = self:AddChild(Text(UIFONT, 40))
    self.title:SetString(data.title or (TUNING.isCh2hm and "模组百科" or "Mod Encyclopedia"))
    self.title:SetPosition(0, ENCYCLOPEDIA_CONSTANTS.TITLE_Y)
    self.title:SetColour(1, 1, 1, 1)
    
    -- 关闭按钮
    self.close_button = self:AddChild(TEMPLATES.StandardButton(
        function() self:Close() end, 
        TUNING.isCh2hm and "关闭百科" or "Close Encyclopedia", 
        {120, 40}
    ))
    self.close_button:SetPosition(unpack(ENCYCLOPEDIA_CONSTANTS.CLOSE_BUTTON_POS))
    
    -- 内容列表背景已移除
    
    -- 创建目录列表
    self:CreateIndexList()
    
    -- 设置默认焦点
    self.default_focus = self.close_button
end)

-- 通用的列表项按钮创建函数
function EncyclopediaIndex:CreateListItemButton(title, onclick_callback, widget_name)
    local item = Widget(widget_name or "ListItem")
    
    -- 使用官方的ListItemBackground样式创建按钮
    local button = item:AddChild(TEMPLATES.ListItemBackground(
        ENCYCLOPEDIA_CONSTANTS.BUTTON_SIZE[1],
        ENCYCLOPEDIA_CONSTANTS.BUTTON_SIZE[2],
        onclick_callback
    ))
    button:SetPosition(ENCYCLOPEDIA_CONSTANTS.BUTTON_OFFSET_X, 0)
    button.move_on_click = true
    
    -- 添加文字
    button.text = button:AddChild(Text(CHATFONT, 28))
    button.text:SetString(title or "Unknown")
    button.text:SetPosition(0, 0)
    button.text:SetColour(UICOLOURS.GOLD_CLICKABLE)
    
    -- 设置按钮状态变化时的文字颜色
    self:SetupButtonColors(button)
    
    item.focus_forward = button
    return item
end

-- 设置按钮颜色状态变化
function EncyclopediaIndex:SetupButtonColors(button)
    if not button or not button.text then return end
    
    -- 设置按钮状态变化时的文字颜色
    button.SetTextColour = function(_, r, g, b, a)
        if button.text then
            button.text:SetColour(r, g, b, a)
        end
    end
    
    -- 重写按钮的选中/取消选中方法来改变文字颜色
    local old_select = button.Select
    button.Select = function(self)
        if old_select then old_select(self) end
        if button.text then
            button.text:SetColour(UICOLOURS.GOLD_FOCUS)
        end
    end
    
    local old_unselect = button.Unselect  
    button.Unselect = function(self)
        if old_unselect then old_unselect(self) end
        if button.text then
            button.text:SetColour(UICOLOURS.GOLD_CLICKABLE)
        end
    end
    
    -- 设置悬停效果
    button:SetOnGainFocus(function()
        if button.text then
            button.text:SetColour(UICOLOURS.GOLD_FOCUS)
        end
    end)
    
    button:SetOnLoseFocus(function()
        if button.text then
            button.text:SetColour(UICOLOURS.GOLD_CLICKABLE)
        end
    end)
end

function EncyclopediaIndex:CreateIndexList()
    local list_items = {}
    
    -- 获取章节列表（使用定义的顺序或直接遍历）
    local sections_to_process = {}
    if self.data.section_order then
        for _, section_key in ipairs(self.data.section_order) do
            local section = self.data.sections[section_key]
            if section then
                table.insert(sections_to_process, section)
            end
        end
    else
        for _, section in pairs(self.data.sections) do
            table.insert(sections_to_process, section)
        end
    end
    
    -- 创建按钮项目
    for _, section in ipairs(sections_to_process) do
        local item = self:CreateListItemButton(
            section.title,
            function() self:OpenSection(section) end,
            "IndexItem"
        )
        table.insert(list_items, item)
    end
    
    -- 创建滚动列表
    self:CreateScrollList(list_items, self)
end

-- 通用的滚动列表创建函数
function EncyclopediaIndex:CreateScrollList(list_items, parent_widget)
    if not list_items or #list_items == 0 then return end
    
    local scroll_list = parent_widget:AddChild(ScrollableList(
        list_items,
        ENCYCLOPEDIA_CONSTANTS.LIST_SIZE[1],
        ENCYCLOPEDIA_CONSTANTS.LIST_SIZE[2],
        ENCYCLOPEDIA_CONSTANTS.ITEM_HEIGHT,
        ENCYCLOPEDIA_CONSTANTS.ITEM_SPACING
    ))
    scroll_list:SetPosition(0, 0)
    
    -- 如果有滚动条，调整其位置
    if scroll_list.scroll_bar_container then
        scroll_list.scroll_bar_container:SetPosition(ENCYCLOPEDIA_CONSTANTS.SCROLL_BAR_OFFSET, 0)
    end
    
    return scroll_list
end

function EncyclopediaIndex:OpenSection(section)
    if not section then 
        print("Warning: Trying to open invalid section")
        return 
    end
    
    if section.subsections and next(section.subsections) then
        -- 如果有子章节，创建子章节列表
        local subsection_screen = self:CreateSubsectionList(section)
        TheFrontEnd:PushScreen(subsection_screen)
    else
        -- 直接显示内容
        if OpenEncyclopediaContent then
            OpenEncyclopediaContent(section, section.title)
        else
            print("Warning: OpenEncyclopediaContent function not available")
        end
    end
end

-- 创建第二级目录
function EncyclopediaIndex:CreateSubsectionList(section)
    local subsection_screen = Screen("EncyclopediaSubsection")
    
    -- 设置界面属性
    subsection_screen:SetScaleMode(SCALEMODE_PROPORTIONAL)
    subsection_screen:SetHAnchor(ANCHOR_MIDDLE)
    subsection_screen:SetVAnchor(ANCHOR_MIDDLE)
    
    -- 背景
    local bg = subsection_screen:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
    bg:SetSize(unpack(ENCYCLOPEDIA_CONSTANTS.MAIN_BG_SIZE))
    bg:SetPosition(0, 0)
    
    -- 标题
    local title = subsection_screen:AddChild(Text(UIFONT, 36))
    title:SetString(section.title or "Subsection")
    title:SetPosition(0, ENCYCLOPEDIA_CONSTANTS.TITLE_Y)
    title:SetColour(1, 1, 1, 1)
    
    -- 返回按钮
    local back_button = subsection_screen:AddChild(TEMPLATES.StandardButton(
        function() TheFrontEnd:PopScreen(subsection_screen) end,
        TUNING.isCh2hm and "返回" or "Back",
        {120, 40}
    ))
    back_button:SetPosition(unpack(ENCYCLOPEDIA_CONSTANTS.BACK_BUTTON_POS))
    
    -- 关闭按钮
    local close_button = subsection_screen:AddChild(TEMPLATES.StandardButton(
        function() 
            TheFrontEnd:PopScreen(subsection_screen)
            self:Close()
        end,
        TUNING.isCh2hm and "关闭百科" or "Close Encyclopedia",
        {120, 40}
    ))
    close_button:SetPosition(unpack(ENCYCLOPEDIA_CONSTANTS.CLOSE_BUTTON_POS))
    
    -- 列表背景已移除
    
    -- 创建子章节列表项目
    local list_items = self:CreateSubsectionItems(section)
    
    -- 创建滚动列表
    self:CreateScrollList(list_items, subsection_screen)
    
    -- 设置控制处理和默认焦点
    self:SetupSubsectionScreenControls(subsection_screen, back_button)
    
    return subsection_screen
end

-- 创建子章节项目
function EncyclopediaIndex:CreateSubsectionItems(section)
    local list_items = {}
    
    if not section or not section.subsections then 
        return list_items 
    end
    
    -- 获取子章节列表（使用定义的顺序或直接遍历）
    local subsections_to_process = {}
    if section.subsection_order then
        for _, subsection_key in ipairs(section.subsection_order) do
            local subsection = section.subsections[subsection_key]
            if subsection then
                table.insert(subsections_to_process, subsection)
            end
        end
    else
        for _, subsection in pairs(section.subsections) do
            table.insert(subsections_to_process, subsection)
        end
    end
    
    -- 创建按钮项目
    for _, subsection in ipairs(subsections_to_process) do
        local item = self:CreateListItemButton(
            subsection.title,
            function() 
                if OpenEncyclopediaContent then
                    OpenEncyclopediaContent(subsection, subsection.title)
                end
            end,
            "SubsectionItem"
        )
        table.insert(list_items, item)
    end
    
    return list_items
end

-- 设置子章节界面控制
function EncyclopediaIndex:SetupSubsectionScreenControls(screen, default_focus)
    screen.OnControl = function(self, control, down)
        if Screen.OnControl(self, control, down) then 
            return true 
        end
        if not down and control == CONTROL_CANCEL then
            TheFrontEnd:PopScreen(self)
            return true
        end
    end
    
    screen.default_focus = default_focus
end

function EncyclopediaIndex:Close()
    -- 清理资源
    if self.scroll_list then
        self.scroll_list = nil
    end
    
    if CloseEncyclopedia then
        CloseEncyclopedia()
    else
        TheFrontEnd:PopScreen(self)
    end
end

function EncyclopediaIndex:OnControl(control, down)
    if EncyclopediaIndex._base.OnControl(self, control, down) then 
        return true 
    end
    
    if not down and control == CONTROL_CANCEL then
        self:Close()
        return true
    end
end

return EncyclopediaIndex
