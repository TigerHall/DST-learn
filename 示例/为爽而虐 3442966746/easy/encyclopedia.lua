-- 百科全书UI功能独立文件，包含目录和文本两个界面
-- 依照easy/ui.lua的结构实现

-- 百科按钮文本
local ENCYCLOPEDIA_CONFIG = {
    BUTTON_TEXT = {
        CHINESE = "[百科全书] 为爽而虐模组改动说明",
        ENGLISH = "[Encyclopedia] Mod Features Guide"
    }
}

-- 导入百科数据
if not ENCYCLOPEDIA_DATA2HM then
    modimport("encyclopedia2hm.lua")
end

-- 导入目录和内容界面文件
local EncyclopediaIndex = require("widgets/encyclopedia2hm_index")
local EncyclopediaContent = require("widgets/encyclopedia2hm_content")

-- 百科全书状态管理器
local EncyclopediaManager = {
    is_open = false,
    current_screen = nil,
    cached_data = nil
}

-- 导入百科文本数据
local function ParseEncyclopediaData()
    if EncyclopediaManager.cached_data then 
        return EncyclopediaManager.cached_data 
    end
    
    if not ENCYCLOPEDIA_DATA2HM then
        return nil
    end
    
    EncyclopediaManager.cached_data = ENCYCLOPEDIA_DATA2HM
    return EncyclopediaManager.cached_data
end

-- 打开百科内容页面
_G.OpenEncyclopediaContent = function(section_data, title)
    if not section_data then return end
    
    local content_screen = EncyclopediaContent(section_data, title)
    TheFrontEnd:PushScreen(content_screen)
end

-- 打开百科全书主页
_G.OpenEncyclopedia = function()
    if EncyclopediaManager.is_open then return end
    
    local data = ParseEncyclopediaData()
    if not data then return end
    
    local index_screen = EncyclopediaIndex(data)
    EncyclopediaManager.current_screen = index_screen
    EncyclopediaManager.is_open = true
    TheFrontEnd:PushScreen(index_screen)
end

-- 关闭百科全书
_G.CloseEncyclopedia = function()
    if EncyclopediaManager.is_open and EncyclopediaManager.current_screen then
        TheFrontEnd:PopScreen(EncyclopediaManager.current_screen)
        EncyclopediaManager.current_screen = nil
        EncyclopediaManager.is_open = false
    end
end

-- 获取百科按钮文本
local function GetEncyclopediaButtonText()
    return TUNING.isCh2hm and ENCYCLOPEDIA_CONFIG.BUTTON_TEXT.CHINESE or ENCYCLOPEDIA_CONFIG.BUTTON_TEXT.ENGLISH
end

-- 创建百科按钮项目
local function CreateEncyclopediaItem()
    return {
        text = GetEncyclopediaButtonText(),
        onclick = function() OpenEncyclopedia() end
    }
end

-- 尝试添加到list_data
local function TryAddToListData(screen, item)
    if screen.list_data then
        table.insert(screen.list_data, 1, item)
        if screen.scroll_list and screen.scroll_list.RefreshView then
            screen.scroll_list:RefreshView()
        end
        return true
    end
    return false
end

-- 尝试添加到scroll_list.items
local function TryAddToScrollListItems(screen, item)
    if screen.scroll_list and screen.scroll_list.items then
        table.insert(screen.scroll_list.items, 1, item)
        if screen.scroll_list.RefreshView then
            screen.scroll_list:RefreshView()
        end
        return true
    end
    return false
end

-- 尝试通过修改构造函数添加
local function TryAddViaConstructor(screen, item)
    if not screen._ctor then return false end
    
    local old_construct = screen._ctor
    screen._ctor = function(self, ...)
        local result = old_construct(self, ...)
        if self.list_data then
            table.insert(self.list_data, 1, item)
        end
        return result
    end
    return true
end

-- 在游戏内查看模组中添加百科按钮
function AddEncyclopediaToModsList2HM(original_screen)
    if not original_screen then return end
    
    local encyclopedia_item = CreateEncyclopediaItem()
    
    -- 按优先级尝试不同的添加方法
    local add_methods = {
        TryAddToListData,
        TryAddToScrollListItems,
        TryAddViaConstructor
    }
    
    for _, method in ipairs(add_methods) do
        if method(original_screen, encyclopedia_item) then
            return
        end
    end
end

