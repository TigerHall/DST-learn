local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"

local LARGE_BACKPACK = HMR_CONFIGS.HONOR_BACKPACK_SLOTS == 30

local TEXTBOX_POS = LARGE_BACKPACK and {0, -400, 0} or {0, -342, 0}
local BUTTON_POS = LARGE_BACKPACK and {0, -460, 0} or {0, -390, 0}

local TEXTBOX_SIZE = LARGE_BACKPACK and {200, 50} or {165, 50}
local BUTTON_SCALE = LARGE_BACKPACK and {0.65, 0.8, 1} or {0.54, 0.7, 1}

local HonorBackpack = Class(Widget, function(self, owner)
    Widget._ctor(self, "HonorBackpack")

    self.owner = owner

    -- 文本编辑框
    -- fieldtext, width_field, height, font, font_size, prompt_text
    self.textbox_root = self:AddChild(TEMPLATES.StandardSingleLineTextEntry(nil, TEXTBOX_SIZE[1], TEXTBOX_SIZE[2], nil, 40, STRINGS.HMR.HONOR_BACKPACK.SEARCHBOX_UI)) -- 添加单行文本输入框
    self.textbox_root:SetPosition(unpack(TEXTBOX_POS))
    self.textbox = self.textbox_root.textbox
    self.textbox:SetTextLengthLimit(TEXTBOX_SIZE[1])
    self.textbox:SetForceEdit(true)
    self.textbox:EnableWordWrap(false)
    self.textbox:SetHelpTextApply(STRINGS.HMR.HONOR_BACKPACK.SEARCHBOX_UI)
    self.textbox.prompt:SetHAlign(ANCHOR_MIDDLE)
    self.textbox.OnTextInputted = function()
        self:SetSearchText(self.textbox:GetString())
    end

    -- 图形按钮
    --atlas, normal, focus, disabled, down, selected, scale, offset
    self.button = self:AddChild(ImageButton(
        "images/global_redux.xml",
        "button_carny_long_normal.tex",
        "button_carny_long_hover.tex",
        "button_carny_long_normal.tex",
        "button_carny_long_down.tex",
        "button_carny_long_down.tex",
        BUTTON_SCALE
    ))
    self.button:SetPosition(unpack(BUTTON_POS))
    self.button.control = CONTROL_ACCEPT
    self.button.onclick = function()
        local prefab = self.textbox:GetString()
        SendModRPCToServer(MOD_RPC["HMR"]["HONOR_BACKPACK_TRANSMIT"], prefab)
    end

    -- 按钮文本
    -- font, size, text, colour
    self.buttontext = self:AddChild(Text(BUTTONFONT, 45, STRINGS.HMR.HONOR_BACKPACK.TRANSMIT_BUTTON, {0.3, 0.26, 0.15, 1}))
    self.buttontext:SetPosition(unpack(BUTTON_POS))
end)

function HonorBackpack:SetSearchText(search_text)
	search_text = TrimString(string.lower(search_text)):gsub(" ", "")

	if search_text == self.last_search_text then
		return
	end

	self.last_search_text = self.search_text
	self.search_text = search_text

	self.last_searched_recipes = self.searched_recipes
	self.searched_recipes = {}

	self:StartUpdating()
	self.search_delay = 1
	self.current_recipe_search = nil
end

-- fronted.lua中调用了，不写会报错
function HonorBackpack:OnUpdate()
end

return HonorBackpack
