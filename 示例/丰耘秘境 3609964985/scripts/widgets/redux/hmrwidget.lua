local ImageButton = require "widgets/imagebutton"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"

local HMRTech = require "widgets/redux/hmrtech"
local HMRIntroduce = require "widgets/redux/hmrintroduce"
local HMRConfiguraion = require "widgets/redux/hmrconfiguration"
local HMRBlank = require "widgets/redux/hmrblank"

local HMRWidget = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "HMRWidget")

	self.root = self:AddChild(Widget("HMRWidgetRoot"))

    -- 面板背景
	self.panel_bg = self.root:AddChild(Image("images/plantregistry.xml", "backdrop.tex"))
	self.panel_bg:ScaleToSize(1000, 590)
	self.panel_bg:SetPosition(0, -60, 0)

    -- 面板
	self.panel_root = self.root:AddChild(Widget("HMRWidgetPanelRoot"))
    self:BuildPanel()
    self:MakeTopBar()

    self:SelectTopButton(self.menubuttons[1])

    -- 返回按钮
    self.cancel_button = self.root:AddChild(TEMPLATES.BackButton(function()
        TheFrontEnd:FadeBack()
    end))
    -- self.cancel_button:SetPosition(5, 5, 0)

    -- 模组名字
    self.name_image = self.root:AddChild(Image("images/widgetimages/hmr_name.xml", "name.tex"))
    self.name_image:SetPosition(0, 320, 0)
    self.name_image:SetScale(0.12)
end)

function HMRWidget:BuildPanel(name)
    if self.panels == nil then
        self.panels = {}
    end

    if name == nil then
        self.panels.panel_tech = self.panel_root:AddChild(HMRTech(self.owner))
        self.panels.panel_introduce = self.panel_root:AddChild(HMRIntroduce(self.owner))
        self.panels.panel_configuraion = self.panel_root:AddChild(HMRConfiguraion(self.owner, "HMR"))
        self.panels.blank = self.panel_root:AddChild(HMRBlank(self.owner))
    elseif name == "TECH" then
        if self.panels.panel_tech == nil then
            self.panels.panel_tech = self.panel_root:AddChild(HMRTech(self.owner))
        end
    elseif name == "INTRODUCE" then
        if self.panels.panel_introduce == nil then
            self.panels.panel_introduce = self.panel_root:AddChild(HMRIntroduce(self.owner))
        end
    elseif name == "CONFIGURATIONS" then
        if self.panels.panel_configuraion == nil then
            self.panels.panel_configuraion = self.panel_root:AddChild(HMRConfiguraion(self.owner, "HMR"))
        end
    else
        if self.panels.blank == nil then
            self.panels.blank = self.panel_root:AddChild(HMRBlank(self.owner))
        end
    end
end

function HMRWidget:SelectPanel(panel)
	if self.panels ~= nil then
		for k, v in pairs(self.panels) do
			if v == panel then
				v:Show()
				v:MoveToFront()
                v.isopen = true
			else
				v:Hide()
                v.isopen = false
			end
		end
	end
end

function HMRWidget:MakeTopBar()
    self.menubuttons = {}

    local button_data = {
        {
            name = "TECH",
            text = "丰耘科技",
            color = {0.9, 0.9, 0.9, 1},
            text_color = {0.65, 0.57, 0.33, 1},
            pos = {x = - 200, y = 250},
            onselect = function()	-- 不要直接杀死！！！
                self:BuildPanel("TECH")
				self:SelectPanel(self.panels.panel_tech)
                self.panels.panel_tech:RefreshTree()
            end
        },
        {
            name = "INTRODUCE",
            text = "丰耘全书",
            color = {0.9, 0.9, 0.9, 1},
            text_color = {0.65, 0.57, 0.33, 1},
            pos = {x = - 100, y = 250},
            onselect = function()
                self:BuildPanel("INTRODUCE")
				self:SelectPanel(self.panels.panel_introduce)
            end
        },
        {
            name = "MOD",
            text = "模组相关",
            color = {0.7, 0.7, 0.7, 1},
            text_color = {0.65, 0.57, 0.33, 1},
            pos = {x = 0, y = 250},
            onselect = function()
                self:BuildPanel("OTHERS")
                self:SelectPanel(self.panels.blank)
            end
        },
        {
            name = "ACHIEVEMENTS",
            text = "丰耘成就",
            color = {0.7, 0.7, 0.7, 1},
            text_color = {0.65, 0.57, 0.33, 1},
            pos = {x = 100, y = 250},
            onselect = function()
                self:BuildPanel("ACHIEVEMENTS")
                self:SelectPanel(self.panels.blank)
            end
        },
        {
            name = "CONFIGURATIONS",
            text = "模组设置",
            color = {0.7, 0.7, 0.7, 1},
            text_color = {0.65, 0.57, 0.33, 1},
            pos = {x = 200, y = 250},
            onselect = function()
                self:BuildPanel("CONFIGURATIONS")
				self:SelectPanel(self.panels.panel_configuraion)
            end
        },
    }
    local function MakeButton(idx, data)
        local buttonwidth = 100
        local buttonheight = 40

		local buttonwidget = self.root:AddChild(Widget())
        buttonwidget:SetPosition(data.pos.x, data.pos.y)

		local button = buttonwidget:AddChild(ImageButton(
            "images/quagmire_recipebook.xml",
            "quagmire_recipe_tab_inactive.tex",
            "quagmire_recipe_tab_active.tex",
            "quagmire_recipe_tab_inactive.tex",
            "quagmire_recipe_tab_active.tex",
            "quagmire_recipe_tab_active.tex"))
		button:ForceImageSize(buttonwidth, buttonheight)
		button.scale_on_focus = false
		button.basecolor = {data.color[1],data.color[2],data.color[3]}
		button:SetImageFocusColour(math.min(1,data.color[1]*1.2),math.min(1,data.color[2]*1.2),math.min(1,data.color[3]*1.2),1)
		button:SetImageNormalColour(data.color[1],data.color[2],data.color[3],1)
		button:SetImageSelectedColour(data.color[1],data.color[2],data.color[3],1)
		button:SetImageDisabledColour(data.color[1],data.color[2],data.color[3],1)
		button:SetOnClick(function()
            self:SelectTopButton(buttonwidget)
        end)

        button:SetText(data.text)
        button:SetTextColour(unpack(data.text_color))
        button:SetTextFocusColour(unpack(data.text_color))
        button:SetTextDisabledColour(unpack(data.text_color))
        button:SetTextSelectedColour(unpack(data.text_color))
        button:SetTextSize(25)

		-- buttonwidget.flash = buttonwidget:AddChild(UIAnim())
		-- buttonwidget.flash:GetAnimState():SetBank("cookbook_newrecipe")
		-- buttonwidget.flash:GetAnimState():SetBuild("cookbook_newrecipe")
		-- buttonwidget.flash:GetAnimState():PlayAnimation("anim", true)
		-- buttonwidget.flash:GetAnimState():SetDeltaTimeMultiplier(1.25)
		-- buttonwidget.flash:SetScale(.8, .8, .8)
		-- buttonwidget.flash:SetPosition(40, 0, 0)
		-- buttonwidget.flash:Hide()
		-- buttonwidget.flash:SetClickable(false)

		buttonwidget.name = data.name
        buttonwidget.onselect = data.onselect
		buttonwidget.button = button

		table.insert(self.menubuttons, buttonwidget)
    end

    for i, data in ipairs(button_data) do
        MakeButton(i, data)
    end
end

function HMRWidget:SelectTopButton(buttonwidget)
    local old_selected = self.selected_topbuttonwidget
    if old_selected ~= nil then
        old_selected.button:Unselect()
    end

    if buttonwidget ~= nil then
        self.selected_topbuttonwidget = buttonwidget
        buttonwidget.button:Select()
        buttonwidget.button:MoveToFront()
        if buttonwidget.onselect ~= nil then
            buttonwidget.onselect()
        end
    end
end

return HMRWidget
