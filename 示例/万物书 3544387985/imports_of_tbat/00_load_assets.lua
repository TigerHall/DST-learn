
if Assets == nil then
    Assets = {}
end

local temp_assets = {

    ---------------------------------------------------------------------------
    -- 示例
        -- Asset("IMAGE", "images/inventoryimages/tbat_empty_icon.tex"),
        -- Asset("ATLAS", "images/inventoryimages/tbat_empty_icon.xml"),
	    -- Asset("SHADER", "shaders/mod_test_shader.ksh"),		--- 测试用的
        -- Asset("IMAGE", "images/widgets/tbat_visual_mouse_test_widget.tex"),
        -- Asset("ATLAS", "images/widgets/tbat_visual_mouse_test_widget.xml"),
        -- Asset("ANIM", "anim/tbat_chat_icon_voltorb.zip"),
	---------------------------------------------------------------------------
    -- 制作栏分类
        Asset("IMAGE", "images/widgets/tbat_recipe_filter.tex"),
        Asset("ATLAS", "images/widgets/tbat_recipe_filter.xml"),
        Asset("IMAGE", "images/widgets/tbat_recipe_filter2.tex"),
        Asset("ATLAS", "images/widgets/tbat_recipe_filter2.xml"),
	---------------------------------------------------------------------------
    -- wiki
        Asset("IMAGE", "images/widgets/tbat_wiki_button.tex"),
        Asset("ATLAS", "images/widgets/tbat_wiki_button.xml"),
	---------------------------------------------------------------------------
    ---- 聊天图标
        Asset("IMAGE", "images/chat_icon/empty.tex"),
        Asset("ATLAS", "images/chat_icon/empty.xml"),
	---------------------------------------------------------------------------
	--- 皮肤解锁弹窗使用
        Asset("ATLAS", "images/tradescreen.xml"),
        Asset("IMAGE", "images/tradescreen.tex"),
        Asset("ANIM", "anim/tbat_skin_unlock_info_bg.zip"),
    ---------------------------------------------------------------------------
    
}

for k, v in pairs(temp_assets) do
    table.insert(Assets,v)
end

