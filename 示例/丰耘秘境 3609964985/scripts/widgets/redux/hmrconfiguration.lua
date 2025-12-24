require "util"
require "strings"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local PopupDialogScreen = require "screens/redux/popupdialog"

local ClientConfiguration = require "widgets/redux/hmrconfigurationclient"
local ServerConfiguration = require "widgets/redux/hmrconfigurationserver"

local modname = "HMR"

local function MakeButton(self, data)
    local buttonwidth = 100
    local buttonheight = 40

    local buttonwidget = Widget()
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
        self:SelectPanel(buttonwidget)
    end)

    button:SetText(data.text)
    button:SetTextColour(unpack(data.text_color))
    button:SetTextFocusColour(unpack(data.text_color))
    button:SetTextDisabledColour(unpack(data.text_color))
    button:SetTextSelectedColour(unpack(data.text_color))
    button:SetTextSize(25)

    buttonwidget.name = data.name
    buttonwidget.onselect = data.onselect
    buttonwidget.button = button

    return buttonwidget
end


local Configuration = Class(Widget, function(self)
	Widget._ctor(self, "Configuration")

    self.root = self:AddChild(Widget("root"))
    self.root:SetPosition(0, 0, 0)

    self.panel_root = self.root:AddChild(Widget("panel_root"))
    self.panel_root:SetPosition(130, -50, 0)

    self.client_panel = self.panel_root:AddChild(ClientConfiguration(modname))
    self.server_panel = self.panel_root:AddChild(ServerConfiguration(modname))

    local client_data = {
        name = "CLIENT",
        text = "本地设置",
        color = {0.7, 0.7, 0.7, 1},
        text_color = {0.65, 0.57, 0.33, 1},
        pos = {x = -400, y = 50},
        onselect = function()
            self.client_panel:Show()
            self.client_panel:MoveToFront()
            self.server_panel:Hide()

            self.last_panel_button = self.client_button
        end
    }
    self.client_button = self.root:AddChild(MakeButton(self, client_data))

    local server_data = {
        name = "SERVER",
        text = "服务器设置",
        color = {0.7, 0.7, 0.7, 1},
        text_color = {0.65, 0.57, 0.33, 1},
        pos = {x = -400, y = -50},
        onselect = function()
            self.server_panel:Show()
            self.server_panel:MoveToFront()
            self.client_panel:Hide()

            self.last_panel_button = self.server_button
        end
    }
    self.server_button = self.root:AddChild(MakeButton(self, server_data))

    self.last_panel_button = self.last_panel_button or self.client_button
    self:SelectPanel(self.last_panel_button)
end)

function Configuration:SelectPanel(buttonwidget)
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

return Configuration
