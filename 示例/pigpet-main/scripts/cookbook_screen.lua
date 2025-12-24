-- 优化并注释版：CookbookScreen（食谱界面）
-- 目的：
--   - 清晰展示玩家当前可烹饪的菜品（来源：自动烹饪模块）
--   - 支持翻页/滚动与关闭操作
-- 说明：
--   - 将原来的 CookBook 类重命名为 CookbookScreen（语义更明确）
--   - 将若干函数重命名为更具语义的名字（例如 Refresh -> RefreshItems, SetupUpDownButton -> SetupNavigationButtons）
--   - 保持对外接口与原逻辑一致（只改名和注释），便于维护
local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local CookBookItem = require "widgets/cookbookitem" -- 保持现有 widget 路径
local autoCook = require "widgets/autocook"         -- 自动烹饪工具，提供可烹饪项

-- 可视化常量，便于调整布局与行为
local VISIBLE_ROWS = 3           -- 每次可见的行数
local ITEM_HEIGHT = 180          -- 单个 cookbook item 的纵向高度（像素）

-- 每页/布局常量（保持与原布局一致）
local COLUMNS_PER_ROW = 6

-- CookbookScreen: 主界面类
local CookbookScreen = Class(Screen, function(self)
    Screen._ctor(self, "CookbookScreen")
    SetPause(true, "CookbookScreen")
    -- 当前已滚动到的行索引（1 开始）
    self.current_row = 1
    -- 总行数（根据内容动态计算）
    self.total_rows = 1

    -- 半透明背景，覆盖全屏
    self.background = self:AddChild(Image("images/global.xml", "square.tex"))
    self.background:SetVRegPoint(ANCHOR_MIDDLE)
    self.background:SetHRegPoint(ANCHOR_MIDDLE)
    self.background:SetVAnchor(ANCHOR_MIDDLE)
    self.background:SetHAnchor(ANCHOR_MIDDLE)
    self.background:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.background:SetTint(0, 0, 0, .3)

    -- 根节点：所有内容挂载在此，便于整体移动/缩放
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    -- 将内容整体右移 20 像素（响应窗口缩放）
    self.root:SetPosition(20, 0, 0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    -- 标题文本
    self.title = self.root:AddChild(Text(DEFAULTFONT, 40, "可烹饪的食物"))
    self.title:SetPosition(0, 300)

    -- 列表容器：所有 CookBookItem 会被加入到这里
    self.list_root = self.root:AddChild(Widget("list_root"))
    self.list_root:SetPosition(-100, 0)

    -- 初始化内容并创建控制按钮
    self:RefreshItems()
    self:SetupNavigationButtons()
    self:SetupCloseButton()
end)

-- SetupCloseButton: 创建并绑定“关闭”按钮
function CookbookScreen:SetupCloseButton()
    self.close_btn = self.root:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex"))
    self.close_btn:SetPosition(0, 0)
    self.close_btn:SetText("关闭")
    self.close_btn:SetScale(0.75)
    self.close_btn:SetFont(BUTTONFONT)
    self.close_btn:SetOnClick(function()
        self:OnClose()
    end)
end

-- SetupNavigationButtons: 创建上下滚动按钮并绑定回调
function CookbookScreen:SetupNavigationButtons()
    -- 向下翻页（展示更后面的行）
    self.down_button = self.root:AddChild(ImageButton(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex"))
    self.down_button:SetPosition(0, -250)
    self.down_button:SetScale(0.5)
    self.down_button:SetOnClick(function() self:ScrollDown() end)

    -- 向上翻页（展示前面的行）
    self.up_button = self.root:AddChild(ImageButton(HUD_ATLAS, "craft_end_normal.tex", "craft_end_normal_mouseover.tex", "craft_end_normal_disabled.tex"))
    self.up_button:SetPosition(0, 250)
    self.up_button:SetScale(0.5)
    self.up_button:SetRotation(180)
    self.up_button:SetOnClick(function() self:ScrollUp() end)
end

-- ScrollDown: 向下滚动一行（若存在更多行）
function CookbookScreen:ScrollDown()
    -- 只有当还能下移（当前行 + 可视行数 <= 总行数）时才允许
    if self.current_row + VISIBLE_ROWS <= self.total_rows then
        self.current_row = self.current_row + 1
        self:UpdateVisibleItems()
    end
end

-- ScrollUp: 向上滚动一行（若不是第一行）
function CookbookScreen:ScrollUp()
    if self.current_row - 1 > 0 then
        self.current_row = self.current_row - 1
        self:UpdateVisibleItems()
    end
end

-- OnClose: 统一处理关闭界面逻辑（播放声音、关闭界面）
function CookbookScreen:OnClose()
    -- 只在不是 HUD 层时弹出（与原逻辑保持一致）
    local screen = TheFrontEnd:GetActiveScreen()
    if screen and screen.name:find("HUD") == nil then
        TheFrontEnd:PopScreen()
    end
    SetPause(false)
    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
end

-- 更新当前可见的 CookBookItem（按需创建/销毁，仅创建 visible_rows 内的项）
function CookbookScreen:UpdateVisibleItems()
    -- 清理当前已创建的 item
    if self.cookbook_items then
        for _, it in ipairs(self.cookbook_items) do
            if it and it.Kill then it:Kill() end
        end
    end
    self.cookbook_items = {}

    if not self.entries_array or #self.entries_array == 0 then
        self.title:SetString("没有可烹饪的食物")
        return
    end

    local start_row = self.current_row
    local end_row = math.min(self.total_rows, start_row + VISIBLE_ROWS - 1)
    local created = 0

    for r = start_row, end_row do
        for c = 1, COLUMNS_PER_ROW do
            local idx = (r - 1) * COLUMNS_PER_ROW + c
            local entry = self.entries_array[idx]
            if not entry then break end

            local x = (c - 3) * ITEM_HEIGHT
            local y = (2 - (r - start_row)) * ITEM_HEIGHT - 150  -- 0..VISIBLE_ROWS-1 -> rows on screen
            table.insert(self.cookbook_items, self.list_root:AddChild(CookBookItem(self, entry, x, y, 0.8, true)))
            created = created + 1
        end
    end

    self.title:SetString(created > 0 and "可烹饪的食物" or "没有可烹饪的食物")
end

-- RefreshItems: 只准备数据并计算行数，不一次性创建全部 widget
function CookbookScreen:RefreshItems()
    -- 取消并清理可能的创建任务（旧逻辑可能有）
    if self._create_task then
        self._create_task:Cancel()
        self._create_task = nil
    end

    -- 清理旧的 item（如果有）
    if self.cookbook_items then
        for _, v in ipairs(self.cookbook_items) do
            if v and v.Kill then v:Kill() end
        end
    end
    self.cookbook_items = {}
    self.entries_array = {}

    -- 获取数据（product -> cooktable），然后转数组以便按索引分页
    local inventory_recipes = autoCook.GetAvailableInventoryCookpotRecipes()
    -- 太多了现不显示了
    local cookbook_recipes = {} --autoCook.GenerateCookbookRecipes()
    for product, v in pairs(inventory_recipes) do
        for _, detail in ipairs(v.ingredients_list) do
            local entry = {
                -- 实物的信息
                recipe = v.recipe,
                -- 配方
                selected_ingredient = detail.selected_ingredient,
                can_cook = detail.can_cook,
            }
            table.insert(self.entries_array, entry)
        end
    end

    for product, v in pairs(cookbook_recipes) do
        for _, detail in ipairs(v.ingredients_list) do
            local entry = {
                -- 实物的信息
                recipe = v.recipe,
                -- 配方
                selected_ingredient = detail.selected_ingredient,
                can_cook = detail.can_cook,
            }
            table.insert(self.entries_array, entry)
        end
    end

    -- 计算总行数（每行 COLUMNS_PER_ROW 项）
    local total_items = #self.entries_array
    self.total_rows = math.max(1, math.ceil(total_items / COLUMNS_PER_ROW))
    self.current_row = math.min(self.current_row or 1, self.total_rows)

    -- 创建当前可见页的项（按需创建）
    self:UpdateVisibleItems()
end

return CookbookScreen