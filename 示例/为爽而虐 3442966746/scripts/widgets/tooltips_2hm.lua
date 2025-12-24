local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local UIAnim = require "widgets/uianim"
local easing = require "easing"
local Text = require "widgets/text"


local Tooltip_2hm = Class(Widget, function(self, owner)
		self.owner = owner
		Widget._ctor(self, "Happypatch Tooltip")

		self.icon1 = self:AddChild(Image("images/terrorbeak2hm.xml", "terrorbeak2hm.tex"))
		self.icon1:SetPosition(200, 300, 0)
		self.icon1:SetScaleMode(0.01)
		self.icon1:SetScale(.9, .9, .9)

		self:Hide()
		self:RefreshTooltips()
		self.item_tip = nil
		self.skins_spinner = nil
	end)

function Tooltip_2hm:ShowTip()
	self:RefreshTooltips()
	self:Show()
end

function Tooltip_2hm:HideTip()
	self:RefreshTooltips()
	self:Hide()
end

function Tooltip_2hm:RefreshTooltips()
	if self.skins_spinner ~= nil then
		self.icon1:SetPosition(200, 300, 0)
	else
		self.icon1:SetPosition(200, 245, 0)
	end

	local tip_2hm = self.item_tip ~= nil and STRINGS.TOOLTIP_2HM[string.upper(self.item_tip)] ~= nil and
		STRINGS.TOOLTIP_2HM[string.upper(self.item_tip)] .. "\n" or ""

	local tooltip = tip_2hm 

	if self.item_tip ~= nil and tip_2hm ~= "" then
		self.icon1:SetTooltip(tooltip)
		self.icon1:Show()
	else
		self.icon1:Hide()
	end
end

return Tooltip_2hm
