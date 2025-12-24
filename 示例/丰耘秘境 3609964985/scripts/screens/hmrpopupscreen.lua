local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"

local HMRWidget = require "widgets/redux/hmrwidget"

local HMRPopupScreen = Class(Screen, function(self, owner)
    self.owner = owner
    Screen._ctor(self, "HMRPopupScreen")

    self.letterbox = self:AddChild(TEMPLATES.old.ForegroundLetterbox())
    self.root = self:AddChild(TEMPLATES.ScreenRoot("HMRRoot"))
    self.bg = self.root:AddChild(TEMPLATES.PlainBackground())


	self.hmrwidget = self.root:AddChild(HMRWidget(owner))

	self.default_focus = self.hmrwidget

    SetAutopaused(true)
end)

function HMRPopupScreen:OnDestroy()
    SetAutopaused(false)

    POPUPS.HMR:Close(self.owner)

	HMRPopupScreen._base.OnDestroy(self)
end

function HMRPopupScreen:OnBecomeInactive()
    HMRPopupScreen._base.OnBecomeInactive(self)
end

function HMRPopupScreen:OnBecomeActive()
    HMRPopupScreen._base.OnBecomeActive(self)
end

function HMRPopupScreen:Close(fn)
    TheFrontEnd:FadeBack(nil, nil, fn)
end

function HMRPopupScreen:OnControl(control, down)
    if HMRPopupScreen._base.OnControl(self, control, down) then return true end

    if not down and not self.closing then
	    if control == CONTROL_MAP or control == CONTROL_CANCEL then
			self.closing = true

			self:Close() --go back

			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true
		end
	end

	return false
end

function HMRPopupScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

    return table.concat(t, "  ")
end

return HMRPopupScreen
