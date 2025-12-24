local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Menu = require "widgets/menu"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local TravelItem = require "widgets/travelitem"

local TravelScreen = Class(Screen, function(self, homesign, traveller)
    Screen._ctor(self, "TravelScreen")
    -- 参数存档（属性名使用 snake_case）
    self.home_sign = homesign        -- 当前点（高亮 / 不显示传送按钮）
    self.traveller = traveller       -- 发起传送的实体（通常为玩家）
    -- 进入界面时暂停游戏（保持交互时世界静止）
    SetPause(true, "TravelScreen")

    -- 根节点：所有 UI 元素挂在此（便于整体移动/缩放）
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    -- 背景面板（固定大小，位于根节点上）
    self.bg = self.root:AddChild(Image("images/globalpanels.xml", "panel.tex"))
    self.bg:SetSize(500, 650)
    self.bg:SetPosition(0, 25)

    -- 顶部当前点名称显示（大字号）
    self.current_label = self.root:AddChild(Text(BODYTEXTFONT, 35))
    self.current_label:SetPosition(0, 225, 0)
    self.current_label:SetRegionSize(350, 50)
    self.current_label:SetHAlign(ANCHOR_MIDDLE)
    -- 将 homesign 的 name 显示在顶部（需要 homesign.components.travelable 存在）
    if self.home_sign and self.home_sign.components and self.home_sign.components.travelable then
        self.current_label:SetString(self.home_sign.components.travelable.name)
    else
        self.current_label:SetString("")
    end


    -- 操作菜单：用于显示“关闭”等按钮（简洁布局）
    self.menu = self.root:AddChild(Menu(nil, 200, true))
    self.menu:SetScale(0.6)
    self.menu:SetPosition(0, -225, 0)
    self.cancel_button = self.menu:AddItem("关闭", function()
                                            self:OnCancel()
                                        end)


    -- 向上翻页按钮（右侧）
    self.up_button = self.root:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
    self.up_button:SetPosition(180, 200, 0)
    self.up_button:SetRotation(-90)   -- 旋转指向上方
    self.up_button:SetScale(0.5)
    self.up_button:SetOnClick(
        function()
            self:ScrollUp()
        end
    )

    -- 向下翻页按钮（右侧）
    self.down_button = self.root:AddChild(ImageButton("images/ui.xml", "scroll_arrow.tex", "scroll_arrow_over.tex", "scroll_arrow_disabled.tex"))
    self.down_button:SetPosition(180, -200, 0)
    self.down_button:SetRotation(90)   -- 旋转指向下方
    self.down_button:SetScale(0.5)
    self.down_button:SetOnClick(
        function()
            self:ScrollDown()
        end
    )


    self.menu:SetHRegPoint(ANCHOR_MIDDLE)

    -- travel_items: 列表容器，存放 TravelItem 子控件
    self.travel_items = self.root:AddChild(Widget("ROOT"))
    self.travel_items:SetPosition(-100, 0)
    self.travel_items:SetScale(0.8)

    -- current_row 用于分页偏移：表示当前页面从第 current_row 条记录开始显示
    self.current_row = 1

    -- 初始加载第一页内容
    self:LoadTravelItems(self.current_row)
end)


-- ScrollUp: 向上翻页（向前一页）
-- 通过 current_row 减少 5 来实现一次整页翻页（若已到开头则不变）
function TravelScreen:ScrollUp()
    if self.current_row >= 5 then
        self.current_row = self.current_row - 5
        self:LoadTravelItems(self.current_row)
    end
end

-- ScrollDown: 向下翻页（向后一页）
-- 通过 current_row 加 5 来实现一次整页翻页（确保不超出总条目数）
function TravelScreen:ScrollDown()
    -- Pigpet.homesigns 应为数组；检查边界防止越界
    if self.current_row <= #Pigpet.homesigns - 5 then
        self.current_row = self.current_row + 5
        self:LoadTravelItems(self.current_row)
    end
end


-- LoadTravelItems: 从指定索引开始加载最多 5 条 TravelItem 并显示
-- 参数：
--   index - 从 Pigpet.homesigns 的第 index 项开始显示（1 基）
-- 行为：
--   - 先清除已有列表项（KillAllChildren）
--   - 遍历 Pigpet.homesigns，从 index 开始创建 TravelItem，最多 5 个
--   - 对每个 TravelItem 设置位置与 is_current 标志（用于在 TravelItem 内决定是否显示传送按钮）
function TravelScreen:LoadTravelItems(index)
    -- 清理旧条目，避免重复控件残留
    self.travel_items:KillAllChildren()
    -- 从 index 开始遍历， 只显示 5 个条目
    local num_items = 0
    for i = index, #Pigpet.homesigns do
        if num_items >= 5 then
            break
        end
        local v = Pigpet.homesigns[i]
        -- 判断是否为当前 homesign（顶部高亮项）
        local is_current = v == self.home_sign
        -- 创建 TravelItem 子控件（传入 homesign、是否当前、traveller 与父 screen）
        local travel_item = self.travel_items:AddChild(TravelItem(v, is_current, self.traveller, self))
        -- 布局：从上到下排列，每行高度约 100（与 TravelItem 内部 scale/布局配合）
        travel_item:SetPosition(120, 200 - num_items * 100, 0)
        num_items = num_items + 1
    end
end


-- OnCancel: 关闭界面并恢复游戏
-- 注意：SetPause(false) 恢复世界更新，TheFrontEnd:PopScreen 移除当前屏幕
function TravelScreen:OnCancel()
    SetPause(false)
    TheFrontEnd:PopScreen(self)
end

return TravelScreen