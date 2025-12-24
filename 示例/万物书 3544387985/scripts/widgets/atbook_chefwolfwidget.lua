local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"

local cooking = require("cooking")
local cookable = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_cookable")
local scrapbookdata = require("screens/redux/scrapbookdata")

local function RGB(r, g, b)
    return { r / 255, g / 255, b / 255, 1 }
end

local IMAGES = {
    BG = { "images/ui/atbook_chefwolf/icon_k.xml", "icon_k.tex" },
    BG_SMALL = { "images/ui/atbook_chefwolf/icon_shiwusx.xml", "icon_shiwusx.tex" },
    BG_RIGHT = { "images/ui/atbook_chefwolf/icon_di_r.xml", "icon_di_r.tex" },
    BG_LEFT = { "images/ui/atbook_chefwolf/icon_di_l.xml", "icon_di_l.tex" },
    BG_NUM = { "images/ui/atbook_chefwolf/di_sl.xml", "di_sl.tex" },
    TITLE = { "images/ui/atbook_chefwolf/icon_mc.xml", "icon_mc.tex" },
    SLOT = { "images/ui/atbook_chefwolf/icon_gz_kz.xml", "icon_gz_kz.tex" },
    SLOT_DARK = { "images/ui/atbook_chefwolf/icon_gz_jz.xml", "icon_gz_jz.tex" },
    ARROW = { "images/ui/atbook_chefwolf/icon_fy_u.xml", "icon_fy_u.tex" },
    ARROW2 = { "images/ui/atbook_chefwolf/icon_sl_l.xml", "icon_sl_l.tex" },
    SCROLL_BAR = { "images/ui/atbook_chefwolf/icon_hd.xml", "icon_hd.tex" },
    POSITION_MARKER = { "images/ui/atbook_chefwolf/icon_hl.xml", "icon_hl.tex" },
    CLOSE = { "images/ui/atbook_chefwolf/icon_gb.xml", "icon_gb.tex" },
    BTN_BLUE = { "images/ui/atbook_chefwolf/icon_dc_1.xml", "icon_dc_1.tex" },
    BTN_PINK = { "images/ui/atbook_chefwolf/icon_dc_2.xml", "icon_dc_2.tex" },
    BTN_GREEN = { "images/ui/atbook_chefwolf/icon_pd.xml", "icon_pd.tex" },
}

local ChefwolfWidget = Class(Widget, function(self)
    Widget._ctor(self, "ChefwolfWidget")
    self.root = self:AddChild(Widget("root"))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)

    self.main = self.root:AddChild(Widget("main"))

    self.attribute = "health"
    self.category = "cookpot"
    self.foods = {}
    self.foodcombinations = {}
    self.precombinations = {}

    local backdrop = self.main:AddChild(Image(IMAGES.BG[1], IMAGES.BG[2]))
    backdrop:SetScale(0.65)

    local backdrop_left = self.main:AddChild(Image(IMAGES.BG_LEFT[1], IMAGES.BG_LEFT[2]))
    backdrop_left:SetScale(0.68, 0.64)
    backdrop_left:SetPosition(-140, -50)

    local backdrop_right = self.main:AddChild(Image(IMAGES.BG_RIGHT[1], IMAGES.BG_RIGHT[2]))
    backdrop_right:SetScale(0.60)
    backdrop_right:SetPosition(210, -20)

    local backdrop_small = self.main:AddChild(Image(IMAGES.BG_SMALL[1], IMAGES.BG_SMALL[2]))
    backdrop_small:SetPosition(210, 90)
    backdrop_small:SetScale(0.6)

    local title = self.main:AddChild(Image(IMAGES.TITLE[1], IMAGES.TITLE[2]))
    title:SetPosition(-250, 140)
    title:SetScale(0.7)

    local closebutton = self.main:AddChild(ImageButton(IMAGES.CLOSE[1], IMAGES.CLOSE[2]))
    closebutton:SetPosition(360, 230)
    closebutton:SetScale(0.6)
    closebutton:SetFocusScale(1.03, 1.03)
    closebutton:SetHoverText(STRINGS.UI.HELP.CLOSE)
    closebutton:SetOnClick(function() self:PreHide() end)

    self.btn_cookpot = self.main:AddChild(ImageButton(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2]))
    self.btn_cookpot:SetPosition(-140, 130)
    self.btn_cookpot:SetScale(0.6)
    self.btn_cookpot:SetFocusScale(1.03, 1.03)
    self.btn_cookpot:SetOnClick(function()
        self.btn_cookpot:SetTextures(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2])
        self.btn_portablecookpot:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_mod:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_cookpot.desc:SetColour(RGB(207, 255, 255))
        self.btn_portablecookpot.desc:SetColour(RGB(34, 50, 158))
        self.btn_mod.desc:SetColour(RGB(34, 50, 158))
        self.category = "cookpot"
        self:LoadData()
    end)
    self.btn_cookpot.desc = self.btn_cookpot:AddChild(Text(HEADERFONT, 26, "普通料理", RGB(207, 255, 255)))
    self.btn_cookpot.desc:SetPosition(0, -2)

    self.btn_portablecookpot = self.main:AddChild(ImageButton(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2]))
    self.btn_portablecookpot:SetPosition(-70, 130)
    self.btn_portablecookpot:SetScale(0.6)
    self.btn_portablecookpot:SetFocusScale(1.03, 1.03)
    self.btn_portablecookpot:SetOnClick(function()
        self.btn_cookpot:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_portablecookpot:SetTextures(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2])
        self.btn_mod:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_cookpot.desc:SetColour(RGB(34, 50, 158))
        self.btn_portablecookpot.desc:SetColour(RGB(207, 255, 255))
        self.btn_mod.desc:SetColour(RGB(34, 50, 158))
        self.category = "portablecookpot"
        self:LoadData()
    end)
    self.btn_portablecookpot.desc = self.btn_portablecookpot:AddChild(Text(HEADERFONT, 26, "大厨料理", RGB(34, 50, 158)))
    self.btn_portablecookpot.desc:SetPosition(0, -2)

    self.btn_mod = self.main:AddChild(ImageButton(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2]))
    self.btn_mod:SetPosition(0, 130)
    self.btn_mod:SetScale(0.6)
    self.btn_mod:SetFocusScale(1.03, 1.03)
    self.btn_mod:SetOnClick(function()
        self.btn_cookpot:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_portablecookpot:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_mod:SetTextures(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2])
        self.btn_cookpot.desc:SetColour(RGB(34, 50, 158))
        self.btn_portablecookpot.desc:SetColour(RGB(34, 50, 158))
        self.btn_mod.desc:SetColour(RGB(207, 255, 255))
        self.category = "mod"
        self:LoadData()
    end)
    self.btn_mod.desc = self.btn_mod:AddChild(Text(HEADERFONT, 26, "模组料理", RGB(34, 50, 158)))
    self.btn_mod.desc:SetPosition(0, -2)

    self.btn_health = self.main:AddChild(ImageButton(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2]))
    self.btn_health:SetPosition(-140, 160)
    self.btn_health:SetScale(0.6)
    self.btn_health:SetFocusScale(1.03, 1.03)
    self.btn_health:SetOnClick(function()
        self.btn_health:SetTextures(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2])
        self.btn_hunger:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_sanity:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_health.desc:SetColour(RGB(207, 255, 255))
        self.btn_hunger.desc:SetColour(RGB(34, 50, 158))
        self.btn_sanity.desc:SetColour(RGB(34, 50, 158))
        self.attribute = "health"
        self:LoadData()
    end)
    self.btn_health.desc = self.btn_health:AddChild(Text(HEADERFONT, 26, "血量", RGB(207, 255, 255)))
    self.btn_health.desc:SetPosition(0, -2)

    self.btn_hunger = self.main:AddChild(ImageButton(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2]))
    self.btn_hunger:SetPosition(-70, 160)
    self.btn_hunger:SetScale(0.6)
    self.btn_hunger:SetFocusScale(1.03, 1.03)
    self.btn_hunger:SetOnClick(function()
        self.btn_health:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_hunger:SetTextures(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2])
        self.btn_sanity:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_health.desc:SetColour(RGB(34, 50, 158))
        self.btn_hunger.desc:SetColour(RGB(207, 255, 255))
        self.btn_sanity.desc:SetColour(RGB(34, 50, 158))
        self.attribute = "hunger"
        self:LoadData()
    end)
    self.btn_hunger.desc = self.btn_hunger:AddChild(Text(HEADERFONT, 26, "饱食", RGB(34, 50, 158)))
    self.btn_hunger.desc:SetPosition(0, -2)

    self.btn_sanity = self.main:AddChild(ImageButton(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2]))
    self.btn_sanity:SetPosition(0, 160)
    self.btn_sanity:SetScale(0.6)
    self.btn_sanity:SetFocusScale(1.03, 1.03)
    self.btn_sanity:SetOnClick(function()
        self.btn_health:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_hunger:SetTextures(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2])
        self.btn_sanity:SetTextures(IMAGES.BTN_PINK[1], IMAGES.BTN_PINK[2])
        self.btn_health.desc:SetColour(RGB(34, 50, 158))
        self.btn_hunger.desc:SetColour(RGB(34, 50, 158))
        self.btn_sanity.desc:SetColour(RGB(207, 255, 255))
        self.attribute = "sanity"
        self:LoadData()
    end)
    self.btn_sanity.desc = self.btn_sanity:AddChild(Text(HEADERFONT, 26, "理智", RGB(34, 50, 158)))
    self.btn_sanity.desc:SetPosition(0, -2)
end)

function ChefwolfWidget:GetMultiple(combinations)
    local multiple = 1
    while true do
        local flag = false
        local need = {}
        for _, prefab in ipairs(combinations) do
            if need[prefab] then
                need[prefab] = need[prefab] + multiple
            else
                need[prefab] = multiple
            end
        end
        for prefab, num in pairs(need) do
            if num == self.foods[prefab] then
                flag = true
                break
            elseif num > self.foods[prefab] then
                multiple = multiple - 1
                flag = true
                break
            end
        end
        if flag then
            break
        end
        multiple = multiple + 1
    end
    return multiple
end

-- 组合食材
function ChefwolfWidget:Combinations(input, length)
    length = length or 4 -- 默认组合长度为4
    -- 获取键并排序以确保一致顺序
    local keys = {}
    for k, v in pairs(input) do
        v = math.min(4, v)
        table.insert(keys, k)
    end
    table.sort(keys)

    local results = {}
    local current_counts = {} -- 当前组合中每个元素的数量

    -- 初始化当前计数
    for i, k in ipairs(keys) do
        current_counts[i] = 0
    end

    -- 递归生成组合
    local function dfs(index, remaining)
        if index > #keys then
            if remaining == 0 then -- 找到有效组合
                -- 构建结果组合
                local combination = {}
                for i, k in ipairs(keys) do
                    for j = 1, current_counts[i] do
                        table.insert(combination, k)
                    end
                end
                local product = cooking.CalculateRecipe("cookpot", combination)
                if product ~= "wetgoop" then
                    table.insert(results, combination)
                end
            end
            return
        end

        local k = keys[index]
        local max_count = math.min(input[k], remaining)

        for count = 0, max_count do
            current_counts[index] = count
            dfs(index + 1, remaining - count)
        end
    end

    dfs(1, length)
    return results
end

-- 读取食材
function ChefwolfWidget:LoadContainer()
    -- local r = "bonestew"
    -- local a,b = cookable.GetCookable(r, self.foods)
    -- print("<<<<", r, b)
    -- for key, value in pairs(a) do
    --     print(">>>>",key, value)
    -- end
    -- local function GetIngredientValues(prefablist)
    --     local prefabs = {}
    --     local tags = {}
    --     for k, v in pairs(prefablist) do
    --         local name = v
    --         prefabs[name] = (prefabs[name] or 0) + 1
    --         local data = cooking.ingredients[name]
    --         if data ~= nil then
    --             for kk, vv in pairs(data.tags) do
    --                 tags[kk] = (tags[kk] or 0) + vv
    --             end
    --         end
    --     end
    --     return { tags = tags, names = prefabs }
    -- end

    -- local input = deepcopy(self.foods)
    -- local combinations = self:Combinations(self.foods, 4)

    -- self.foodcombinations = {}

    -- for index, value in ipairs(combinations) do
    --     local ingdata = GetIngredientValues(value)
    --     if ingdata then
    --         local info = {}
    --         info.ingdata = ingdata
    --         info.combinations = value
    --         table.insert(self.foodcombinations, info)
    --     end
    -- end
end

--按照属性值排序
function ChefwolfWidget:Sort(data, field)
    table.sort(data, function(a, b)
        local valA = a[field]
        local valB = b[field]

        -- 处理nil值（将nil视为最小值）
        if valA == nil and valB == nil then
            return false -- 保持相对顺序
        elseif valA == nil then
            return false -- b非nil时，b应排在a前面
        elseif valB == nil then
            return true  -- a非nil时，a应排在b前面
        end

        -- 数值比较（降序）
        return valA > valB
    end)
end

-- 加载料理列表
function ChefwolfWidget:LoadData()
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end

    local category = self.category
    local attribute = self.attribute

    if cooking then
        if category and cooking.cookbook_recipes[category] then
            local cookbook_recipes = deepcopy(cooking.cookbook_recipes[category])
            for _, product in pairs(cookbook_recipes) do
                local combinations, cancook = cookable.GetCookable(product.name, self.foods, 1)
                if cancook then
                    product.cancook = true
                    product.combinations = combinations
                end
            end
            -- for _, foodcombination in ipairs(self.foodcombinations) do
            --     local product = cooking.CalculateRecipe(category, foodcombination.combinations)
            --     if cookbook_recipes[product] then
            --         cookbook_recipes[product].cancook = true
            --     end
            -- end

            local info = {}
            local info_gray = {}
            for key, value in pairs(cookbook_recipes) do
                if value.name ~= "wetgoop" and not string.find(value.name, "_spice") then
                    value.category = category
                    if value.cancook then
                        table.insert(info, value)
                    else
                        table.insert(info_gray, value)
                    end
                end
            end
            self:Sort(info, attribute)
            self:Sort(info_gray, attribute)

            for _, value in pairs(info_gray) do
                table.insert(info, value)
            end
            self.scrollinggrid = self.main:AddChild(self:BuildScrollingGrid(info))
            self.scrollinggrid:SetPosition(-140, -50)
        end
    end
end

-- 展示料理详情
function ChefwolfWidget:LoadDetail(data)
    if self.detailwidget then
        self.main:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end

    self.detailwidget = self.main:AddChild(Widget("detailwidget"))

    if data.name ~= nil then
        local atlas = data.cookbook_atlas or GetInventoryItemAtlas(data.name .. ".tex", true)
        local img = data.cookbook_tex or data.name .. ".tex"
        local name = STRINGS.NAMES[string.upper(data.name)]

        if atlas and img then
            local pic = self.detailwidget:AddChild(Image(atlas, img))
            pic:SetPosition(133, 85)
            if data.category == "mod" then
                pic:ScaleToSizeIgnoreParent(55, 55)
            else
                pic:SetScale(0.25)
            end
        end

        local title = self.detailwidget:AddChild(Text(HEADERFONT, 26, name, RGB(207, 255, 255)))
        title:SetPosition(215, 122)

        local health = self.detailwidget:AddChild(Text(DEFAULTFONT, 16, data.health, RGB(34, 50, 158)))
        health:SetPosition(201, 63)

        local hunger = self.detailwidget:AddChild(Text(DEFAULTFONT, 16, data.hunger, RGB(34, 50, 158)))
        hunger:SetPosition(251, 63)

        local sanity = self.detailwidget:AddChild(Text(DEFAULTFONT, 16, data.sanity, RGB(34, 50, 158)))
        sanity:SetPosition(301, 63)

        if data.cancook then
            self.precombinations = {}
            self.pagenumber = 1
            local combinations = cookable.GetCookable(data.name, self.foods, TUNING.ATBOOK_NUMRECIPEPAGE * 4)
            for _, v in ipairs(combinations) do
                for index, value in ipairs(v) do
                    if type(value) == "table" then
                        v[index] = value[1]
                    end
                end
                table.insert(self.precombinations, { combinations = v })
            end
            self:LoadPreCombinations(data, self.pagenumber)
        end
    end
end

-- 加载点菜配方
function ChefwolfWidget:LoadPreCombinations(data, pagenumber)
    if self.precombinationswidget then
        self.detailwidget:RemoveChild(self.precombinationswidget)
        self.precombinationswidget:Kill()
        self.precombinationswidget = nil
    end
    self.precombinationswidget = self.detailwidget:AddChild(Widget("precombinationswidget"))

    local max_pagenumber = math.ceil(#self.precombinations / 4)

    local arrow_left = self.precombinationswidget:AddChild(ImageButton(IMAGES.ARROW[1], IMAGES.ARROW[2]))
    arrow_left:SetRotation(-90)
    arrow_left:SetScale(0.65)
    arrow_left:SetFocusScale(1.03, 1.03)
    arrow_left:SetPosition(180, -180)
    arrow_left:SetOnClick(function()
        self.pagenumber = math.max(1, self.pagenumber - 1)
        self:LoadPreCombinations(data, self.pagenumber)
    end)

    local arrow_right = self.precombinationswidget:AddChild(ImageButton(IMAGES.ARROW[1], IMAGES.ARROW[2]))
    arrow_right:SetRotation(90)
    arrow_right:SetScale(0.65)
    arrow_right:SetFocusScale(1.03, 1.03)
    arrow_right:SetPosition(260, -180)
    arrow_right:SetOnClick(function()
        self.pagenumber = math.min(max_pagenumber, self.pagenumber + 1)
        self:LoadPreCombinations(data, self.pagenumber)
    end)

    local page = self.precombinationswidget:AddChild(Text(DEFAULTFONT, 32, pagenumber .. " / " .. max_pagenumber,
        RGB(255, 255, 255)))
    page:SetScale(0.6, 0.6)
    page:SetPosition(220, -180)

    for i = (pagenumber - 1) * 4 + 1, math.min(pagenumber * 4, #self.precombinations) do
        local i_pos = (i - 1) % 4 + 1
        for j = 1, 4 do
            local slot = self.precombinationswidget:AddChild(Image(IMAGES.SLOT[1], IMAGES.SLOT[2]))
            slot:SetPosition(70 + j * 40, 50 - i_pos * 50)
            slot:SetScale(0.3)

            local prefab = self.precombinations[i].combinations[j]
            if prefab then
                local atlas = GetInventoryItemAtlas(prefab .. ".tex", true)
                local img = prefab .. ".tex"
                if scrapbookdata[prefab] then
                    atlas = GetInventoryItemAtlas(scrapbookdata[prefab].tex, true)
                    img = scrapbookdata[prefab].tex
                end

                if atlas and img then
                    local image = slot:AddChild(Image(atlas, img))
                    image:SetScale(1.3)
                    image:SetHoverText(STRINGS.NAMES[string.upper(prefab)])
                end
            end
        end

        local bg_num = self.precombinationswidget:AddChild(Image(IMAGES.BG_NUM[1], IMAGES.BG_NUM[2]))
        bg_num:SetScale(0.6, 0.6)
        bg_num:SetPosition(269, 50 - i_pos * 50)

        local num = self.precombinationswidget:AddChild(Text(DEFAULTFONT, 32, 1, RGB(255, 255, 255)))
        num:SetScale(0.6, 0.6)
        num:SetPosition(269, 50 - i_pos * 50)

        self.precombinations[i].prenum = 1

        local arrow = self.precombinationswidget:AddChild(ImageButton(IMAGES.ARROW2[1], IMAGES.ARROW2[2]))
        arrow:SetScale(0.6, 0.6)
        arrow:SetFocusScale(1.03, 1.03)
        arrow:SetPosition(257, 50 - i_pos * 50)
        arrow:SetOnClick(function()
            self.precombinations[i].prenum = math.max(1, self.precombinations[i].prenum - 1)
            num:SetString(self.precombinations[i].prenum)
        end)

        local max = self:GetMultiple(self.precombinations[i].combinations)
        local arrow2 = self.precombinationswidget:AddChild(ImageButton(IMAGES.ARROW2[1], IMAGES.ARROW2[2]))
        arrow2:SetScale(-0.6, 0.6)
        arrow2:SetFocusScale(1.03, 1.03)
        arrow2:SetPosition(281, 50 - i_pos * 50)
        arrow2:SetOnClick(function()
            self.precombinations[i].prenum = math.min(max, self.precombinations[i].prenum + 1)
            num:SetString(self.precombinations[i].prenum)
        end)

        local order = self.precombinationswidget:AddChild(ImageButton(IMAGES.BTN_BLUE[1], IMAGES.BTN_BLUE[2]))
        order:SetScale(0.5, 0.5)
        order:SetFocusScale(1.03, 1.03)
        order:SetPosition(310, 53 - i_pos * 50)
        order:SetOnClick(function()
            local time = data.cooktime or 1 -- 默认烹饪时间
            local info = {
                prefab = data.name,
                numcook = self.precombinations[i].prenum,
                cooktime = self.precombinations[i].prenum * time * 10,
                combinations = self.precombinations[i].combinations,
            }
            SendModRPCToServer(MOD_RPC["ATBOOK"]["chefwolforder"], self.machine, ZipAndEncodeString(info))
            self:PreHide()
        end)
        order.desc = order:AddChild(Text(HEADERFONT, 30, "点菜", RGB(34, 50, 158)))
        order.desc:SetPosition(0, -2)
    end
end

-- 构建料理列表滚动区域
function ChefwolfWidget:BuildScrollingGrid(info)
    local function MakeProductWidget(context, index)
        local w = Widget("product")

        w.item = w:AddChild(ImageButton(IMAGES.SLOT[1], IMAGES.SLOT[2]))
        w.item:SetPosition(0, 0, 0)
        w.item:SetScale(0.55, 0.55)
        w.item:SetFocusScale(1.03, 1.03)
        w.item:SetNormalScale(1, 1)
        w.item_image = w.item:AddChild(Image())
        -- w.item_image:SetScale(0.35, 0.35, 0.35)
        -- w.item_image:SetTint(1, 1, 1, 0.3)

        w:Hide()

        return w
    end

    local function ApplyDataToWidget(context, widget, data, index)
        widget.data = data
        if data ~= nil then
            widget:Show()
            if data.name ~= nil then
                local atlas = data.cookbook_atlas or GetInventoryItemAtlas(data.name .. ".tex", true)
                local img = data.cookbook_tex or data.name .. ".tex"
                local name = STRINGS.NAMES[string.upper(data.name)]
                local state, newatlas = pcall(resolvefilepath_soft, atlas)
                if state then
                    if type(newatlas) == "string" then
                        atlas = newatlas
                    end
                end
                widget:SetHoverText(name)
                if atlas and img then
                    widget.item_image:SetTexture(atlas, img)
                end
            end
            if data.cancook then
                widget.item:SetTextures(IMAGES.SLOT[1], IMAGES.SLOT[2])
                -- widget.item_image:SetTint(1, 1, 1, 1)
            else
                widget.item:SetTextures(IMAGES.SLOT_DARK[1], IMAGES.SLOT_DARK[2])
                -- widget.item_image:SetTint(1, 1, 1, 0.75)
            end
            if data.category == "mod" then
                widget.item_image:ScaleToSizeIgnoreParent(55, 55)
            else
                widget.item_image:SetScale(0.35)
            end
            widget.item:SetOnClick(function()
                self:LoadDetail(data)
            end)
        else
            widget:Hide()
        end
    end

    local grid = TEMPLATES.ScrollingGrid({}, {
        context                 = {},
        widget_width            = 70,
        widget_height           = 70,
        num_visible_rows        = 4,
        num_columns             = 5,
        item_ctor_fn            = MakeProductWidget,
        apply_fn                = ApplyDataToWidget,
        scrollbar_offset        = 20,
        scrollbar_height_offset = 0,
        allow_bottom_empty_row  = true,
        force_peek              = true
    })

    grid.up_button:SetTextures(IMAGES.ARROW[1], IMAGES.ARROW[2])
    grid.up_button:SetScale(0.65)
    grid.up_button:SetPosition(grid.up_button:GetPosition().x, grid.up_button:GetPosition().y - 20, 0)

    grid.down_button:SetTextures(IMAGES.ARROW[1], IMAGES.ARROW[2])
    grid.down_button:SetScale(-0.65)
    grid.down_button:SetPosition(grid.down_button:GetPosition().x, grid.down_button:GetPosition().y + 20, 0)

    grid.scroll_bar_line:SetTexture(IMAGES.SCROLL_BAR[1], IMAGES.SCROLL_BAR[2])
    grid.scroll_bar_line:SetScale(0.65)

    grid.position_marker:SetTextures(IMAGES.POSITION_MARKER[1], IMAGES.POSITION_MARKER[2])
    grid.position_marker.image:SetTexture(IMAGES.POSITION_MARKER[1], IMAGES.POSITION_MARKER[2])
    grid.position_marker:SetScale(.65)

    grid:SetItemsData(info)

    return grid
end

function ChefwolfWidget:PreShow(machine, foods)
    self.machine = machine
    self.foods = foods

    self:LoadContainer()

    self.btn_health.onclick()
    self.btn_cookpot.onclick()

    self:Show()
end

function ChefwolfWidget:PreHide()
    if self.scrollinggrid then
        self.main:RemoveChild(self.scrollinggrid)
        self.scrollinggrid:Kill()
        self.scrollinggrid = nil
    end
    if self.detailwidget then
        self.main:RemoveChild(self.detailwidget)
        self.detailwidget:Kill()
        self.detailwidget = nil
    end
    self:Hide()
end

-- function ChefwolfWidget:OnGainFocus()
--     -- self.camera_controllable_reset = TheCamera:IsControllable()
--     -- TheCamera:SetControllable(false)

--     ChefwolfWidget._base.OnLoseFocus(self)
--     TheCamera:SetControllable(false)
-- end

-- function ChefwolfWidget:OnLoseFocus()
--     -- TheCamera:SetControllable(self.camera_controllable_reset)

--     ChefwolfWidget._base.OnLoseFocus(self)
--     TheCamera:SetControllable(true)
-- end

function ChefwolfWidget:OnControl(control, down)
    if self._base.OnControl(self, control, down) then
        return true
    end
    if not down then
        if control == CONTROL_PAUSE or control == CONTROL_CANCEL then
            self:PreHide()
        end
    end
    return true
end

return ChefwolfWidget
