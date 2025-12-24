-- 优化并注释版：showinfo.lua
-- 本文件功能总览：
--  1) 鼠标悬停时在 tooltip 中显示更多目标信息（实体 prefab、组件状态等）
--  2) 背包物品提示（Item Tile / inventorybar）显示更详细的物品属性
--  3) 血条与伤害浮字显示（在实体上方显示实时血量和受伤数字）
--  4) 小地图自定义图标注册
--  5) 状态栏（badge）美化（显示最大值、背景、位置调整）
-- 注：为提高可读性，若干辅助函数改用更语义化的名字并添加详细注释

local GLOBAL = GLOBAL

-- 四舍五入到指定小数位（默认 0 位）
local function round_decimal(num, idp)
    return GLOBAL.tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

local function GetIngredient(prefab)
    local all_receipes = AllRecipes or GLOBAL.GetAllRecipes()
    local receipe = all_receipes[prefab]
    if receipe then
        local describe = "\n材料:"
        for _, ingredient in ipairs(receipe.ingredients) do
            describe = describe .. (GLOBAL.STRINGS.NAMES[GLOBAL.string.upper(ingredient.type)] or "无描述") .. " x" .. ingredient.amount .. " "
        end
        return describe
    end
    return nil
end

-- 以下为物品栏（inventory）提示扩展相关函数
local function round_nearest(n)
    if not n or type(n) ~= "number" then return "NaN" end
    return math.floor(n + 0.5)
end
local function round_tenth(value) return math.floor(value * 10 + 0.5) / 10 end
local function to_int_string(n) return tostring(round_nearest(n)) end

-- 获取物品详细描述（Item -> string）
-- 包含：prefab 代码、食物三维回复、金块价值、武器伤害、腐烂时间、耐久、保暖/隔热、防水等属性
local function GetItemDescription(item)
    if not item then return "" end
    local str = ""
    local ic = item.components

    -- 显示 prefab 代码（识别用）
    if item.prefab then
        str = str .. "\n代码: " .. tostring(item.prefab)
    end
    local ingred = GetIngredient(item.prefab)
    if ingred then
        str = str .. ingred
    end

    -- travelable 组件：显示可旅行目标的名称（如果存在）
    if ic.travelable then
        if ic.travelable.name then
            str = str .. "\n" .. tostring(ic.travelable.name)
        end
    end

    -- 食物属性（edible）
    if ic.edible then
        local hunger = round_tenth(ic.edible:GetHunger(item))
        local health = round_tenth(ic.edible:GetHealth(item))
        local sanity = round_tenth(ic.edible:GetSanity(item))
        if hunger > 0 then hunger = "+" .. tostring(hunger) end
        if sanity > 0 then sanity = "+" .. tostring(sanity) end
        if health > 0 then health = "+" .. tostring(health) end
        str = str .. "\n饥饿: " .. tostring(hunger) .. "/精神: " .. tostring(sanity) .. "/生命: " .. tostring(health)
    end

    -- 交易价值（金块）
    if ic.tradable and ic.tradable.goldvalue and ic.tradable.goldvalue > 0 then
        str = str .. "\n价值金块: " .. ic.tradable.goldvalue
    end

    -- 武器属性（伤害 / 范围）
    if ic.weapon then
        str = str .. "\n伤害: " .. math.ceil(ic.weapon.damage * 10) / 10
        if ic.weapon.hitrange then
            str = str .. "\n范围: " .. ic.weapon.hitrange
        end
    end

    -- winterometer（温度计）显示当前温度（示例）
    if item.prefab == "winterometer" then
        local sm = GLOBAL.GetSeasonManager()
        local temp = sm and sm:GetCurrentTemperature() or 30
        local low_temp = 0
        temp = math.min(math.max(low_temp, temp), 200)
        str = str .. "\n温度: " .. tostring(math.floor(temp)) .. "\176C"
    end
    


     -- pigpet 状态（示例，基于全局变量）
    if item.prefab == "pigpet" and GLOBAL.Pigpet then
        if GLOBAL.Pigpet.Status == 0 then
            str = str .. "\n状态: 攻击"
        elseif GLOBAL.Pigpet.Status == 1 then
            str = str .. "\n状态: 跟随"
        end
    end

    -- 腐烂时间估算：考虑 owner（是否在冰箱中）、季节温度与全局调参
    if ic.perishable then
        local owner = ic.inventoryitem and ic.inventoryitem.owner or nil
        local modifier = 1
        if owner then
            if owner:HasTag("fridge") then
                if item:HasTag("frozen") then
                    modifier = TUNING.PERISH_COLD_FROZEN_MULT
                else
                    modifier = TUNING.PERISH_FRIDGE_MULT
                end
            elseif owner:HasTag("spoiler") then
                modifier = TUNING.PERISH_GROUND_MULT
            end
        else
            modifier = TUNING.PERISH_GROUND_MULT
        end
        local sm = GLOBAL.GetSeasonManager()
        if sm and sm:GetCurrentTemperature() < 0 then
            if item:HasTag("frozen") and not ic.perishable.frozenfiremult then
                modifier = TUNING.PERISH_COLD_FROZEN_MULT
            else
                modifier = modifier * TUNING.PERISH_WINTER_MULT
            end
        end
        if ic.perishable.frozenfiremult then
            modifier = modifier * TUNING.PERISH_FROZEN_FIRE_MULT
        end
        if TUNING.OVERHEAT_TEMP ~= nil and sm and sm:GetCurrentTemperature() > TUNING.OVERHEAT_TEMP then
            modifier = modifier * TUNING.PERISH_SUMMER_MULT
        end
        modifier = modifier * TUNING.PERISH_GLOBAL_MULT
        local perishremainingtime = math.floor(ic.perishable.perishremainingtime / TUNING.TOTAL_DAY_TIME / modifier * 10 + 0.5) / 10
        str = str .. "\n距离腐烂: " .. perishremainingtime .. " 天"
    end

    -- 装备相关：手持/头部/身体物品的防御与耐久
    if ic.inventory then
        -- 头部
        local headitem = ic.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HEAD)
        if headitem and headitem.components.armor then
            str = str .. "\n头部防御: " .. headitem.components.armor.absorb_percent * 100 .. "%"
            str = str .. " 耐久: " .. math.floor(headitem.components.armor:GetPercent() * 100) .. "%"
        end
        -- 身体
        local bodyitem = ic.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
        if bodyitem and bodyitem.components.armor then
            str = str .. "\n身体防御: " .. bodyitem.components.armor.absorb_percent * 100 .. "%"
            str = str .. " 耐久: " .. math.floor(bodyitem.components.armor:GetPercent() * 100) .. "%"
        end
    end


    -- 格子内生物的 hp（若 item 本身有 health）
    if ic.health then
        str = str .. "\n" .. ic.health.currenthealth .. "/" .. ic.health.maxhealth
    end

    -- 治疗物品（healer）
    if ic.healer and (ic.healer.health ~= 0) then
        str = str .. "\n生命: +" .. ic.healer.health
    end

    -- 攻击力（若存在 combat.defaultdamage）
    if ic.combat and ic.combat.defaultdamage and ic.combat.defaultdamage > 0 then
        str = str .. "\n攻击力: " .. ic.combat.defaultdamage
    end
    
    if ic.combat then
        local attackrange = ic.combat:GetAttackRange()
        if attackrange and attackrange > 0 then
            str = str .. "\n攻击范围: " .. tostring(attackrange)
        end
    end


    -- 装备耐久与防御（armor）
    if ic.armor then
        str = str .. "\n防御: " .. ic.armor.absorb_percent * 100 .. "%("
        if ic.armor.tags then
            for _, v in ipairs(ic.armor.tags) do
                str = str .. v .. ";"
            end
        end
        str = str .. ")"
    end

    -- 温度（temperature 组件）
    if ic.temperature then
        str = str .. "\n温度: " .. math.floor(ic.temperature.current * 10) / 10 .. "\176C"
    end

    -- 防水效果（waterproofer）
    if ic.waterproofer and ic.waterproofer.effectiveness ~= 0 then
        str = str .. "\n防水: " .. ic.waterproofer.effectiveness * 100 .. "%"
    end


    -- 可采集生长时间（pickable / hackable / deployable / growable）
    if ic.pickable and ic.pickable.targettime then
        str = str .. "\n距离成长: " .. tostring(math.ceil((ic.pickable.targettime - GLOBAL.GetTime()) / 48) / 10) .. " 天"
    end
    if ic.hackable and ic.hackable.targettime then
        str = str .. "\n距离成长: " .. tostring(math.ceil((ic.hackable.targettime - GLOBAL.GetTime()) / 48) / 10) .. " 天"
    end
    if ic.deployable and ic.deployable.growtime then
        str = str .. "\n树苗: " .. tostring(math.ceil((ic.deployable.growtime - GLOBAL.GetTime()) / 48) / 10) .. " 天"
    end
    if ic.growable and ic.growable.targettime then
        str = str .. "\n下一阶段: " .. tostring(math.ceil((ic.growable.targettime - GLOBAL.GetTime()) / 48) / 10) .. " 天"
    end

    -- 干燥架（dryer）剩余时间
    if ic.dryer and ic.dryer:IsDrying() and ic.dryer.GetTimeToDry then
        str = str .. "\n剩余: " .. round_decimal((ic.dryer:GetTimeToDry() / TUNING.TOTAL_DAY_TIME) + 0.1, 1) .. " 天"
    end

    -- 精神回复（dapperness）
    if ic.dapperness and ic.dapperness.dapperness and type(ic.dapperness.dapperness) == "number" and ic.dapperness.dapperness ~= 0 then
        local sanity = to_int_string(ic.dapperness.dapperness)
        str = str .. "\n精神: " .. sanity
    elseif ic.equippable and ic.equippable.dapperness and type(ic.equippable.dapperness) == "number" and ic.equippable.dapperness ~= 0 then
        local sanity = round_tenth(ic.equippable.dapperness * 60)
        if sanity > 0 then sanity = "+" .. tostring(sanity) end
        str = str .. "\n精神: " .. sanity .. "/min"
    end

    -- 装备增加移速（equippable.walkspeedmult）
    if ic.equippable and ic.equippable.walkspeedmult and ic.equippable.walkspeedmult ~= 0 then
        local added_speed = ic.equippable.walkspeedmult * 100
        if added_speed > 0 then added_speed = "+" .. tostring(added_speed) end
        str = str .. "\n移速: " .. added_speed .. "%"
    end

    -- workable 动作 id
    if ic.workable then
        local action = ic.workable:GetWorkAction()
        if action and action.id then
            str = str .. "\n动作: " .. GLOBAL.STRINGS.ACTIONS[string.upper(action.id)]
        end
    end

    -- 经验/成长（growth 组件）
    if ic.growth then
        str = str .. "\n等级:" .. ic.growth:GetLevel() .. " (经验: " .. ic.growth:GetCurrentExp() .. "/" .. ic.growth:GetCurrentMaxExp() .. ")"
    end

    -- 船（boathealth）
    if ic.boathealth then
        str = str .. "\n船: " .. math.ceil(ic.boathealth.currenthealth) .. "/" .. ic.boathealth.maxhealth
    end

    -- 爆炸（explosive）
    if item.components.explosive then
        str = str .. "\n爆炸伤害: " .. item.components.explosive.explosivedamage .. "\n爆炸范围: " .. item.components.explosive.explosiverange
    end

    -- 手持物耐久（finiteuses）
    if ic.finiteuses then
        if ic.finiteuses.consumption then
            local use = 1
            for k, v in pairs(ic.finiteuses.consumption) do use = v end
            str = str .. "\n耐久: " .. math.floor(ic.finiteuses.current / use + .5) .. "/" .. math.floor(ic.finiteuses.total / use + .5)
        else
            str = str .. "\n耐久: " .. ic.finiteuses.current .. "/" .. ic.finiteuses.total
        end
    end

    -- 农作物进度与产品
    if ic.crop and ic.crop.growthpercent then
        if ic.crop.product_prefab then
            str = str .. "\n" .. (GLOBAL.STRINGS.NAMES and GLOBAL.STRINGS.NAMES[string.upper(ic.crop.product_prefab)] or ic.crop.product_prefab)
        end
        if ic.crop.growthpercent < 1 then
            str = str .. "\n距离成长: " .. math.ceil(ic.crop.growthpercent * 1000) / 10 .. "%"
        end
    end

    -- pigpet 状态（示例，基于全局变量）
    if item.prefab == "pigpet" and GLOBAL.Pigpet then
        if GLOBAL.Pigpet.Status == 0 then
            str = str .. "\n状态: 攻击"
        elseif GLOBAL.Pigpet.Status == 1 then
            str = str .. "\n状态: 跟随"
        end
    end

    -- 忠诚（follower）
    if ic.follower and ic.follower.maxfollowtime then
        local mx = ic.follower.maxfollowtime
        local cur = math.floor(ic.follower:GetLoyaltyPercent() * mx + 0.5)
        if cur > 0 then
            str = str .. "\n忠诚: " .. cur
        end
    end
    
    -- 驯养相关（domesticatable 组件）：饥饿、顺从、驯服百分比与倾向
    if ic.domesticatable then
        local dom = ic.domesticatable
        if dom.GetDomestication and dom.GetObedience then
            local hunger = ic.hunger and ic.hunger.current or 0
            local obedience = dom:GetObedience()
            local domestication = dom:GetDomestication()
            if domestication and domestication ~= 0 then
                str = str .. "\n饥饿: " .. round_decimal(hunger) .. "\n顺从: " .. round_decimal(obedience * 100, 0) .. "%" .. "\n驯服: " .. round_decimal(domestication * 100, 0) .. "%"
            end
            -- 倾向（tendencies）
            if dom.tendencies then
                for k, v in pairs(dom.tendencies) do
                    local ten = "默认"
                    if k == GLOBAL.TENDENCY.ORNERY then ten = "战牛"
                    elseif k == GLOBAL.TENDENCY.RIDER then ten = "行牛"
                    elseif k == GLOBAL.TENDENCY.PUDGY then ten = "肥牛" end
                    str = str .. string.format("\n %s:%.2f", ten, v)
                end
            end
        end
    end

    -- 烹饪（stewer）剩余时间与食物名
    if ic.stewer and ic.stewer.GetTimeToCook and ic.stewer:GetTimeToCook() > 0 then
        local tm = math.ceil((ic.stewer.targettime - GLOBAL.GetTime()), 0)
        local cookname = GLOBAL.STRINGS.NAMES and GLOBAL.STRINGS.NAMES[string.upper(ic.stewer.product)] or tostring(ic.stewer.product)
        if tm < 0 then tm = 0 end
        str = str .. "\n正在烹饪: " .. tostring(cookname) .. "\n剩余时间(秒): " .. tm
    end

    -- 燃料显示（fueled / fuel）
    if ic.fueled then
        str = str .. "\n剩余燃料:" .. tostring(ic.fueled.currentfuel) .. "/" .. tostring(ic.fueled.fueltype)
    end
    if ic.fuel then
        str = str .. "\n燃料:" .. tostring(ic.fuel.fuelvalue) .. "/" .. tostring(ic.fuel.fueltype)
    end

    -- 火山献祭（appeasement）
    if ic.appeasement then
        str = str .. "\n火山献祭: " .. tostring(ic.appeasement.appeasementvalue)
    end

    if ic.insulator then
        if ic.insulator.insulation > 0 then
            str = str .. "\n保暖: " .. tostring(round_nearest(ic.insulator.insulation))
        elseif ic.insulator.insulation < 0 then
            str = str .. "\n隔热: " .. tostring(round_nearest(ic.insulator.insulation))
        end
    end
    
    -- 打包物品（unwrappable）：列出包裹内的物品名与数量
    if ic.unwrappable then
        local packageprefabname = ""
        for i, v in ipairs(ic.unwrappable.itemdata) do
            if v and v.data.stackable and v.data.stackable.stack then
                packageprefabname = packageprefabname .. "\n" .. (GLOBAL.STRINGS.NAMES and GLOBAL.STRINGS.NAMES[string.upper(v.prefab)] or v.prefab) .. "*" .. v.data.stackable.stack
            elseif v and not v.data.stackable then
                packageprefabname = packageprefabname .. "\n" .. (GLOBAL.STRINGS.NAMES and GLOBAL.STRINGS.NAMES[string.upper(v.prefab)] or v.prefab)
            end
        end
        return packageprefabname
    end

    return str
end



-- 鼠标悬停扩展信息（widgets/hoverer 实例构造后执行）
-- 把更多的信息拼接到 hoverer 的文本中，显示实体 prefab、travelable 名称、血量、装备属性、烹饪/成长时间等
AddClassPostConstruct("widgets/hoverer", function(self)
    local old_SetString = self.text.SetString
    -- 覆写内部 SetString，追加目标实体信息
    self.text.SetString = function(text, str)
        local target = GLOBAL.TheInput:GetWorldEntityUnderMouse()
        if target then
           str = str .. GetItemDescription(target)
        end
        return old_SetString(text, str)
    end
end)

-- 扩展 inventorybar 的光标提示（把 GetItemDescription 的内容附加到光标提示中）
local Inv = GLOBAL.require "widgets/inventorybar"
local OldUpdCT = Inv.UpdateCursorText
local ItemTile = GLOBAL.require "widgets/itemtile"
local OldGDS = ItemTile.GetDescriptionString
local TextWidget = GLOBAL.require "widgets/text"

function Inv:UpdateCursorText()
    if self.actionstringbody.GetStringAdd and self.actionstringbody.SetStringAdd then
        local str = GetItemDescription(self:GetCursorItem())
        self.actionstringbody:SetStringAdd(str)
    end
    OldUpdCT(self)
end

function ItemTile:GetDescriptionString()
    local oldstr = OldGDS(self)
    local str = ""
    if self.item and self.item.components and self.item.components.inventoryitem then
        str = GetItemDescription(self.item)
    end
    if string.len(str) > 3 then
        str = oldstr .. str
    else
        str = oldstr
    end
    return str
end

-- 文本辅助接口：支持追加字符串（SetStringAdd / GetStringAdd）
function TextWidget:SetStringAdd(str)
    self.stringadd = str
end

function TextWidget:SetString(str)
    if not str then str = "" else str = tostring(str) end
    self.string = str
    if self.stringadd and (type(self.stringadd) == "string") then str = str .. self.stringadd end
    self.inst.TextWidget:SetString(str or "")
end

function TextWidget:GetStringAdd()
    if self.stringadd and (type(self.stringadd) == "string") then
        return self.stringadd
    else
        return ""
    end
end

-- 以下为伤害浮字与血条显示逻辑
-- Create an invisible label entity anchored to parent position
local function CreateLabelEntity(inst, parent)
    inst.persists = false
    if not inst.Transform then
        inst.entity:AddTransform()
    end
    inst.Transform:SetPosition(parent.Transform:GetWorldPosition())
    return inst
end

local HEALTH_LOSE_COLOR = { r = 0.7, g = 0, b = 0 }
local HEALTH_GAIN_COLOR = { r = 0, g = 0.7, b = 0 }

local LIFT_ACC = 0.003
local LABEL_TIME_DELTA = 0.05

-- 生成伤害/治疗浮字（在实体上方显示一次性动画）
local function SpawnDamageIndicator(inst, amount)
    local labelEntity = CreateLabelEntity(GLOBAL.CreateEntity(), inst)
    local label = labelEntity.entity:AddLabel()
    label:SetFont(GLOBAL.NUMBERFONT)
    label:SetFontSize(70)
    label:SetPos(0, 4, 0)
    local color = amount < 0 and HEALTH_LOSE_COLOR or HEALTH_GAIN_COLOR
    label:SetColour(color.r, color.g, color.b)
    label:SetText(string.format("%d", amount))

    labelEntity:StartThread(function()
        local t = 0
        local ddy = 0.0
        local dy = 0.05
        local side = 0
        local dside = 0.0
        local ddside = 0.0
        local t_max = 0.5
        local y = 4
        while labelEntity:IsValid() and t < t_max do
            -- 垂直抛升 & 轻微左右摆动，兼顾相机朝向（兼容不同 heading）
            ddy = LIFT_ACC * (math.random() * 0.5 + 0.5)
            dy = dy + ddy
            y = y + dy
            ddside = -side * math.random() * 0.15
            dside = dside + ddside
            side = side + dside

            local headingtarget = 45 --[[TheCamera.headingtarget]] % 180
            if headingtarget == 0 then
                label:SetPos(0, y, 0)
            else
                label:SetPos(side, y, 0)
            end
            t = t + LABEL_TIME_DELTA
            label:SetFontSize(70 * math.sqrt(1 - t / t_max))
            GLOBAL.Sleep(LABEL_TIME_DELTA)
        end
        labelEntity:Remove()
    end)
end

-- 给非玩家实体附加血条标签（在实体上方显示实时血量）
local function AttachHealthLabel(inst)
    -- 只对非玩家且有 health 组件的实体附加血条
    if inst:HasTag("player") or not inst.components.health then
        return
    end
    local label = inst.entity:AddLabel()
    label:SetFont(GLOBAL.NUMBERFONT)
    label:SetFontSize(20)
    label:SetText(string.format("%d/%d", inst.components.health.currenthealth, inst.components.health:GetMaxHealth()))
    label:SetPos(0, 0, 0)

    -- 周期性更新显示数值
    inst:DoPeriodicTask(1, function()
        if inst.components and inst.components.health then
            label:SetText(string.format("%d/%d", inst.components.health.currenthealth, inst.components.health:GetMaxHealth()))
        end
    end)
end

-- 当实体被添加 health 组件后，启动血条显示并监听 healthdelta 事件以显示浮字
AddComponentPostInit("health", function(Health, inst)
    AttachHealthLabel(inst)
    inst:ListenForEvent("healthdelta", function(inst, data)
        if inst.components.health then
            local amount = (data.newpercent - data.oldpercent) * inst.components.health:GetMaxHealth()
            if math.abs(amount) > 0.99 then
                SpawnDamageIndicator(inst, amount)
            end
        end
    end)
end)

-- 小地图图标注册：把常用资源的 minimap atlas 加入并在 prefab 初始化时设置 icon
-- deerclops 独眼巨鹿
local minimapAtlas = {
    "beefalo",
    "carrot_planted",
    "flint",
    "rabbithole",
}

for i, v in ipairs(minimapAtlas) do
    AddMinimapAtlas("images/" .. v .. ".xml")
    AddPrefabPostInit(v, function(inst)
        local minimap = inst.entity:AddMiniMapEntity()
        minimap:SetIcon(inst.prefab .. ".tex")
    end)
end

-- 内置物品，特殊物品
local builtin_items = {
    "dirtpile",
    "deerclops",
    "bearger",
    "dragonfly",
    "moose",
}

for i, v in ipairs(builtin_items) do
    --AddMinimapAtlas(GLOBAL.resolvefilepath(GLOBAL.GetInventoryItemAtlas(v .. ".tex")))
    AddPrefabPostInit(v, function(inst)
        local minimap = inst.entity:AddMiniMapEntity()
        -- 不愿意找资源，就用牛的图标凑合着看吧
        minimap:SetIcon("beefalo.tex")
        --minimap:SetIcon(inst.prefab .. ".tex")
        local player = GLOBAL.GetPlayer()
        if not player then
            return
        end
        if player.components.talker then
            player.components.talker:Say("生成了:" .. GLOBAL.STRINGS.NAMES[string.upper(inst.prefab)])
        end
    end)
end



-- 状态栏（badge）美化：调整大小、添加背景、显示最大值（hover 时显示）
local WidgetReq = GLOBAL.require('widgets/widget')
local ImageReq = GLOBAL.require('widgets/image')
local TextReq = GLOBAL.require('widgets/text')

local function BadgePostConstruct(self)
    -- 缩放整体 badge
    self:SetScale(.9, .9, .9)

    -- 添加自定义背景图片（status_bgs）
    self.bg = self:AddChild(ImageReq("images/status_bgs.xml", "status_bgs.tex"))
    self.bg:SetScale(.4, .43, 0)
    self.bg:SetPosition(-.5, -40, 0)

    -- 当前值（数字）样式调整
    self.num:SetFont(GLOBAL.NUMBERFONT)
    self.num:SetSize(28)
    self.num:SetPosition(3.5, -40.5, 0)
    self.num:SetScale(1, .78, 1)
    self.num:MoveToFront()
    self.num:Show()

    -- 最大值文本（默认隐藏，仅在 hover 时显示）
    self.maxnum = self:AddChild(TextReq(GLOBAL.NUMBERFONT, 25))
    self.maxnum:SetPosition(6, 0, 0)
    self.maxnum:MoveToFront()
    self.maxnum:Hide()

    -- 覆写 gain/lose focus 行为以显示/隐藏最大值
    local OldOnGainFocus = self.OnGainFocus
    function self:OnGainFocus()
        OldOnGainFocus(self)
        self.maxnum:Show()
    end

    local OldOnLoseFocus = self.OnLoseFocus
    function self:OnLoseFocus()
        OldOnLoseFocus(self)
        self.maxnum:Hide()
        self.num:Show()
    end

    -- 覆写 SetPercent（如果存在）以更新最大值文本内容并保留原行为
    local maxtxt = "Max:\n"
    local OldSetPercent = self.SetPercent
    if OldSetPercent then
        function self:SetPercent(val, max, ...)
            self.maxnum:SetString(maxtxt .. tostring(math.ceil(max or 100)))
            OldSetPercent(self, val, max, ...)
        end
    end
end

AddClassPostConstruct("widgets/badge", BadgePostConstruct)
