local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ScrollableList = require "widgets/scrollablelist"
local TEMPLATES = require "widgets/redux/templates"

-- 储存UI常量
local CONTENT_CONSTANTS = {
    MAIN_BG_SIZE = {900, 650},
    CONTENT_BG_SIZE = {850, 500},
    TITLE_Y = 280,
    CONTENT_Y = -25,
    CLOSE_BUTTON_POS = {300, -240},
    SCROLL_LIST_SIZE = {780, 450},
    ITEM_PADDING = 10,
    SUBTITLE_FONT_SIZE = 28,
    CONTENT_FONT_SIZE = 22,
    MAIN_CONTENT_FONT_SIZE = 24,
    NO_CONTENT_FONT_SIZE = 24,
    CONTENT_REGION_SIZE = {760, 50},
    MAIN_CONTENT_REGION_SIZE = {780, 60}
}

-- 显示百科文本内容的界面，处理百科数据表的第三层文本内容或第三层目录加第四层文本内容
local EncyclopediaContent = Class(Screen, function(self, section_data, section_title)
    Screen._ctor(self, "EncyclopediaContent")
    
    -- 验证数据
    if not section_data then
        print("Warning: No section data provided to EncyclopediaContent")
        section_data = {}
    end
    
    self.section_data = section_data
    self.section_title = section_title or (TUNING.isCh2hm and "内容" or "Content")
    
    -- 设置界面缩放和位置
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
    
    -- 主背景
    self.bg = self:AddChild(Image("images/scoreboard.xml", "scoreboard_frame.tex"))
    self.bg:SetSize(unpack(CONTENT_CONSTANTS.MAIN_BG_SIZE))
    self.bg:SetPosition(0, 0)
    
    -- 标题
    self.title = self:AddChild(Text(UIFONT, 36))
    self.title:SetString(self.section_title)
    self.title:SetPosition(0, CONTENT_CONSTANTS.TITLE_Y)
    self.title:SetColour(1, 1, 1, 1)
    
    -- 内容区域背景已移除
    
    -- 关闭按钮 (在背景后创建确保在最上层)
    self.close_button = self:AddChild(TEMPLATES.StandardButton(
        function() self:Close() end, 
        TUNING.isCh2hm and "关闭" or "Close", 
        {150, 40}
    ))
    self.close_button:SetPosition(unpack(CONTENT_CONSTANTS.CLOSE_BUTTON_POS))
    
    -- 创建内容显示
    self:CreateContent()
    
    -- 设置默认焦点
    self.default_focus = self.close_button
end)

function EncyclopediaContent:CreateContent()
    local content_widgets = {}
    
    -- 处理子子章节（第四层）
    self:ProcessSubsubsections(content_widgets)
    
    -- 处理当前章节的直接内容（第三层）
    self:ProcessDirectContent(content_widgets)
    
    -- 如果没有内容，显示提示信息
    if #content_widgets == 0 then
        self:AddNoContentWidget(content_widgets)
    end
    
    -- 创建滚动列表
    self:CreateContentScrollList(content_widgets)
end

-- 处理子子章节内容
function EncyclopediaContent:ProcessSubsubsections(content_widgets)
    if not self.section_data.subsubsections or not next(self.section_data.subsubsections) then
        return
    end
    
    local subsubsections_to_process = self:GetOrderedSubsubsections()
    
    for _, subsubsection in ipairs(subsubsections_to_process) do
        -- 添加子标题
        self:AddSubtitleWidget(content_widgets, subsubsection.title)
        
        -- 添加子子章节内容
        self:AddContentItems(content_widgets, subsubsection.content, CONTENT_CONSTANTS.CONTENT_FONT_SIZE)
        
        -- 添加空行
        self:AddSpacerWidget(content_widgets)
    end
end

-- 获取子子章节列表
function EncyclopediaContent:GetOrderedSubsubsections()
    local subsubsections_to_process = {}
    
    -- 如果有指定顺序，按顺序处理
    if self.section_data.subsubsection_order then
        for _, subsubsection_key in ipairs(self.section_data.subsubsection_order) do
            local subsubsection = self.section_data.subsubsections[subsubsection_key]
            if subsubsection then
                table.insert(subsubsections_to_process, subsubsection)
            end
        end
    -- 否则直接遍历所有子子章节
    else
        for _, subsubsection in pairs(self.section_data.subsubsections) do
            table.insert(subsubsections_to_process, subsubsection)
        end
    end
    
    return subsubsections_to_process
end

-- 处理当前章节的直接内容
function EncyclopediaContent:ProcessDirectContent(content_widgets)
    if self.section_data.content and #self.section_data.content > 0 then
        self:AddContentItems(content_widgets, self.section_data.content, CONTENT_CONSTANTS.MAIN_CONTENT_FONT_SIZE)
    end
end

-- 添加子标题控件
function EncyclopediaContent:AddSubtitleWidget(content_widgets, title)
    local subtitle_widget = Widget("SubtitleWidget")
    local subtitle_root = subtitle_widget:AddChild(Widget("SubtitleRoot"))
    
    local subtitle = subtitle_root:AddChild(Text(UIFONT, CONTENT_CONSTANTS.SUBTITLE_FONT_SIZE))
    subtitle:SetString(title or "Untitled")
    subtitle:SetColour(1, 0.8, 0.2, 1)  -- 金黄色
    subtitle:SetHAlign(ANCHOR_LEFT)
    subtitle:SetRegionSize(780, 30)
    subtitle:SetPosition(390, 0)
    table.insert(content_widgets, subtitle_widget)
end

-- 添加内容项目
function EncyclopediaContent:AddContentItems(content_widgets, content_list, font_size)
    if not content_list or #content_list == 0 then return end
    
    local region_size = font_size == CONTENT_CONSTANTS.MAIN_CONTENT_FONT_SIZE and 
                       CONTENT_CONSTANTS.MAIN_CONTENT_REGION_SIZE or 
                       CONTENT_CONSTANTS.CONTENT_REGION_SIZE
    
    for _, content_line in ipairs(content_list) do
        local content_widget = Widget("ContentWidget")
        local content_root = content_widget:AddChild(Widget("ContentRoot"))
        
        local content_text = content_root:AddChild(Text(BODYTEXTFONT, font_size))
        content_text:SetString("• " .. (content_line or ""))
        content_text:SetColour(0.9, 0.9, 0.9, 1)
        content_text:SetHAlign(ANCHOR_LEFT)
        content_text:SetRegionSize(unpack(region_size))
        content_text:EnableWordWrap(true)
        content_text:SetPosition(region_size[1]/2, 0)
        table.insert(content_widgets, content_widget)
    end
end

-- 添加空行
function EncyclopediaContent:AddSpacerWidget(content_widgets)
    local spacer = Widget("SpacerWidget")
    spacer:SetPosition(0, 0)
    table.insert(content_widgets, spacer)
end

-- 添加无内容提示
function EncyclopediaContent:AddNoContentWidget(content_widgets)
    local no_content_widget = Widget("NoContentWidget")
    local no_content_text = no_content_widget:AddChild(Text(BODYTEXTFONT, CONTENT_CONSTANTS.NO_CONTENT_FONT_SIZE))
    no_content_text:SetString(TUNING.isCh2hm and "该章节暂无详细内容" or "No detailed content available for this section")
    no_content_text:SetColour(0.7, 0.7, 0.7, 1)
    no_content_text:SetPosition(0, 0)
    table.insert(content_widgets, no_content_widget)
end

-- 创建内容滚动列表
function EncyclopediaContent:CreateContentScrollList(content_widgets)
    if #content_widgets == 0 then return end
    
    self.scroll_list = self:AddChild(ScrollableList(
        content_widgets,                           -- items
        CONTENT_CONSTANTS.SCROLL_LIST_SIZE[1],    -- listwidth
        CONTENT_CONSTANTS.SCROLL_LIST_SIZE[2],    -- listheight
        nil,                                      -- itemheight (自动)
        CONTENT_CONSTANTS.ITEM_PADDING,          -- itempadding
        nil,                                      -- updatefn
        nil,                                      -- widgetstoupdate
        nil,                                      -- widgetXOffset
        nil,                                      -- always_show_static
        nil,                                      -- starting_offset
        0                                         -- yInit (初始Y偏移，必须是数字)
    ))
    self.scroll_list:SetPosition(0, 0)  -- 相对于主界面居中
    
    -- 定位滚动条位置
    if self.scroll_list.scroll_bar_container then
        self.scroll_list.scroll_bar_container:SetPosition(-5, 0)  
    end
end

function EncyclopediaContent:Close()
    -- 清理资源
    if self.scroll_list then
        self.scroll_list = nil
    end
    
    TheFrontEnd:PopScreen(self)
end

function EncyclopediaContent:OnControl(control, down)
    if EncyclopediaContent._base.OnControl(self, control, down) then 
        return true 
    end
    
    if not down and control == CONTROL_CANCEL then
        self:Close()
        return true
    end
end

return EncyclopediaContent
