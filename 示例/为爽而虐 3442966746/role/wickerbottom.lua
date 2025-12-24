-- 薇克巴顿能力削弱，书柜回复耐久速度变慢，书籍耐久削弱
local TechTree = require("techtree")

TUNING.BOOK_USES_SMALL = 1.01
TUNING.BOOK_USES_LARGE = 1.67
TUNING.BOOKSTATION_RESTORE_TIME = TUNING.BOOKSTATION_RESTORE_TIME * 2
-- 养蜂笔记蜜蜂上限16→8
TUNING.BOOK_MAX_GRUMBLE_BEES = 8
AddRecipePostInit("bookstation", function(inst)
    inst.builder_tag = nil
    inst.level = TechTree.Create(TECH.SCIENCE_ONE)
end)

if GetModConfigData("wickerbottom") ~= -1 then
    local bookCosts = {
        book_birds = {items = {"seeds"}, count = 4, name_ch = "种子", name_en = "seeds"},
        book_gardening = {items = {"poop", "guano"}, count = 5, name_ch = "便便", name_en = "poop"},
        book_horticulture = {items = {"poop", "guano"}, count = 5, name_ch = "便便", name_en = "poop"},
        book_horticulture_upgraded = {items = {"poop", "guano"}, count = 10, name_ch = "便便", name_en = "poop"},
        book_silviculture = {items = {"livinglog"}, count = 2, name_ch = "活木", name_en = "living log"},
        book_sleep = {items = {"nightmarefuel"}, count = 1, name_ch = "噩梦燃料", name_en = "nightmare fuel"},
        book_tentacles = {items = {"tentaclespots"}, count = 1, name_ch = "触手皮", name_en = "tentacle spots"},
        book_brimstone = {items = {}, count = 0},           -- 末日将至！无需消耗
        book_fish = {items = {"barnacle"}, count = 3, name_ch = "藤壶", name_en = "barnacle"},
        book_fire = {items = {}, count = 0},                -- 意念控火术无需消耗
        book_web = {items = {"silk"}, count = 1, name_ch = "蛛丝", name_en = "silk"},
        book_temperature = {items = {}, count = 0},         -- 控温学无需消耗
        book_light = {items = {}, count = 0},               -- 永恒之光无需消耗
        book_light_upgraded = {items = {}, count = 0},      -- 永恒复兴无需消耗
        book_rain = {items = {"goose_feather"}, count = 1, name_ch = "麋鹿毛", name_en = "goose feather"},
        book_bees = {items = {"stinger"}, count = 1, name_ch = "蜂刺", name_en = "bee stinger"},
        book_research_station = {items = {}, count = 0},    -- 万物百科无需消耗
        book_moon = {items = {}, count = 0}                 -- 月之魔典无需消耗
    }
    
    local function HasRequiredItems(reader, bookname)
        if not bookCosts[bookname] or bookCosts[bookname].count == 0 then
            return true -- 不需要消耗材料的书
        end
        
        if not reader.components.inventory then
            return false
        end
        
        local cost = bookCosts[bookname]
        for _, itemname in ipairs(cost.items) do
            if reader.components.inventory:Has(itemname, cost.count) then
                return true, itemname -- 找到符合条件的材料
            end
        end
        
        return false
    end
    
    local function ConsumeItems(reader, bookname)
        if not bookCosts[bookname] or bookCosts[bookname].count == 0 then
            return true
        end
        
        if not reader.components.inventory then
            return false
        end
        
        local cost = bookCosts[bookname]
        for _, itemname in ipairs(cost.items) do
            if reader.components.inventory:Has(itemname, cost.count) then
                reader.components.inventory:ConsumeByName(itemname, cost.count)
                return true
            end
        end
        
        return false
    end
    
    local function ShowMissingItemsMessage(reader, bookname)
        if reader.components.talker and bookCosts[bookname] then
            local cost = bookCosts[bookname]
            local item_name = TUNING.isCh2hm and cost.name_ch or cost.name_en
            local message = TUNING.isCh2hm and 
                string.format("需要%d个%s才能阅读此书！", cost.count, item_name) or
                string.format("You need %d %s to read this book!", cost.count, item_name)
            reader.components.talker:Say(message)
        end
    end
    
    AddComponentPostInit("book", function(self)
        local Interact = self.Interact
        self.Interact = function(self, fn, reader, ...)
            -- 判断是否为浏览模式（鱼妹看书不触发效果）
            -- onperuse是浏览模式，onread是正常阅读模式
            local is_peruse_mode = (fn == self.onperuse)
            
            -- 浏览模式下不需要检查和消耗材料
            if not is_peruse_mode and bookCosts[self.inst.prefab] and reader and reader:IsValid() then
                local hasItems, foundItem = HasRequiredItems(reader, self.inst.prefab)
                
                if not hasItems and bookCosts[self.inst.prefab].count > 0 then
                    reader:DoTaskInTime(0, function()
                        ShowMissingItemsMessage(reader, self.inst.prefab)
                    end)
                    -- 返回false但不传递特殊reason，避免触发原版的失败台词
                    return false
                end
            end
            
            -- 调用原始的读书函数
            local success, reason = Interact(self, fn, reader, ...)
            
            -- 如果读书成功且不是浏览模式，消耗材料
            if success and not is_peruse_mode and bookCosts[self.inst.prefab] and reader and reader:IsValid() then
                ConsumeItems(reader, self.inst.prefab)
            end
            
            return success, reason
        end
    end)
end
