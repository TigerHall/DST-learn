local UIAnim = require "widgets/uianim"
local Tooltip2hm = require "widgets/tooltips_2hm"
-----------------------------------------------------------------
AddClassPostConstruct("widgets/craftslot", function(self)
	local _OldShowRecipe = self.ShowRecipe
	local _OldOnControl = self.OnControl
	local _OldHideRecipe = self.HideRecipe

	function self:ShowRecipe(...)
		if self.tooltips2hm ~= nil then
			self.tooltips2hm.item_tip = nil
			self.tooltips2hm.skins_spinner = nil
			self.tooltips2hm:HideTip()
		end

		self.tooltips2hm = self:AddChild(Tooltip2hm(self.owner))

		if self.tooltips2hm ~= nil and self.recipe ~= nil and self.recipepopup ~= nil and self.recipe.name 
		   and STRINGS.TOOLTIP_2HM[string.upper(self.recipe.name)] ~= nil then
			self.tooltips2hm.item_tip = self.recipe.name
			self.tooltips2hm.skins_spinner = self.recipepopup.skins_spinner or nil
			self.tooltips2hm:ShowTip()
		end
		
		_OldShowRecipe(self, ...)
	end

	function self:OnControl(...)
		if self.tooltips2hm ~= nil then
			self.tooltips2hm.item_tip = nil
			self.tooltips2hm.skins_spinner = nil
			self.tooltips2hm:HideTip()
		end

		self.tooltips2hm = self:AddChild(Tooltip2hm(self.owner))

		if self.tooltips2hm ~= nil and self.recipe ~= nil and self.recipepopup ~= nil and self.recipe.name 
		   and STRINGS.TOOLTIP_2HM[string.upper(self.recipe.name)] ~= nil then
			self.tooltips2hm.item_tip = self.recipe.name
			self.tooltips2hm.skins_spinner = self.recipepopup.skins_spinner or nil
			self.tooltips2hm:ShowTip()
		end

		_OldOnControl(self, ...)
	end

	function self:HideRecipe(...)
		if self.tooltips2hm ~= nil then
			self.tooltips2hm.item_tip = nil
			self.tooltips2hm.skins_spinner = nil
			self.tooltips2hm:HideTip()
		end

		_OldHideRecipe(self, ...)
	end
end)

AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self)
	local _OldOnUpdate = self.OnUpdate

	function self:OnUpdate(...)
		if self.craftingmenu ~= nil and self.tooltips2hm == nil then
			self.tooltips2hm = self.craftingmenu:AddChild(Tooltip2hm(self.owner))
			self.tooltips2hm:SetPosition( -107, -210)
			self.tooltips2hm:SetScale(0.35)
		end

		if self.craftingmenu ~= nil and
			self.craftingmenu.crafting_hud ~= nil and
			self.craftingmenu.crafting_hud:IsCraftingOpen() and
			self.tooltips2hm ~= nil and
			self.craftingmenu.details_root ~= nil and
			self.craftingmenu.details_root.data and
			self.craftingmenu.details_root.data.recipe ~= nil and
			self.craftingmenu.details_root.data.recipe.name and
			STRINGS.TOOLTIP_2HM[string.upper(self.craftingmenu.details_root.data.recipe.name)] then
			self.tooltips2hm.item_tip = self.craftingmenu.details_root.data.recipe.name
			self.tooltips2hm.skins_spinner = self.craftingmenu.details_root.skins_spinner or nil
			self.tooltips2hm:ShowTip()
		elseif self.tooltips2hm ~= nil then
			self.tooltips2hm.item_tip = nil
			self.tooltips2hm.skins_spinner = nil
			self.tooltips2hm:HideTip()
		end

		_OldOnUpdate(self, ...)
	end
end)


--

AddClassPostConstruct( "widgets/controls", function(self, inst)
	local tooltips2hm = require "widgets/tooltips_2hm"
	self.tooltips2hm = self:AddChild(Tooltip2hm(self.owner))
	self.tooltips2hm:MoveToBack()
end)
