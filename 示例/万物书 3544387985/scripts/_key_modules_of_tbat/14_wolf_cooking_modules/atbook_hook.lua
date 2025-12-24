local SERVER_SIDE
local CLIENT_SIDE
if _G.TheNet:GetIsServer() then
    SERVER_SIDE = true
    if not _G.TheNet:IsDedicated() then
        CLIENT_SIDE = true
    end
elseif _G.TheNet:GetIsClient() then
    SERVER_SIDE = false
    CLIENT_SIDE = true
end

local ImageButton = require("widgets/imagebutton")
local utils = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_utils")
local json = require("json")

AddReplicableComponent("atbook_chefwolf")

AddPrefabPostInit("player_classified", function(inst)
    inst.atbook_fooddetail = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_fooddetail").GetFoodDetail()
    inst.atbook_mixtags = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_ingredientdetail").GetMixTags()
end)

AddClassPostConstruct("widgets/controls", function(self)
    local chefwolfwidget = require "widgets/atbook_chefwolfwidget"
    self.chefwolfwidget = self:AddChild(chefwolfwidget())
    self.chefwolfwidget:Hide()

    local atbook_wikiwidget = require "widgets/atbook_wikiwidget"
    self.atbook_wikiwidget = self:AddChild(atbook_wikiwidget())
    self.atbook_wikiwidget:Hide()
end)

AddClassPostConstruct("widgets/hoverer", function(self)
    local OldSetString = self.text.SetString
    self.text.SetString = function(self, str, ...)
        local target = _G.ConsoleWorldEntityUnderMouse()
        if target and target.prefab == "atbook_chefwolf" and target.replica.atbook_chefwolf then
            local info = target.replica.atbook_chefwolf:GetOrderList()
            if info then
                str = str .. info
            end
        end
        OldSetString(self, str, ...)
    end
end)

AddClassPostConstruct("widgets/containerwidget", function(self)
    local OldOpen = self.Open
    self.Open = function(self, container, ...)
        local result = OldOpen(self, container, ...)
        if container and container.prefab == "atbook_chefwolf" then
            if self.button then
                self.button:SetTextures("images/ui/container/icon_gb.xml", "icon_gb.tex")
                self.button:SetFocusScale(1.03, 1.03)
            end
            self.button_spice = self:AddChild(ImageButton("images/ui/container/icon_gz_2.xml", "icon_gz_2.tex"))
            self.button_spice:SetPosition(0, -40)
            self.button_spice:SetFocusScale(1.03, 1.03)
            self.button_spice:SetOnClick(function()
                SendModRPCToServer(MOD_RPC["ATBOOK"]["chefwolfspice"], container)
            end)
        end
        return result
    end

    local OldClose = self.Close
    self.Close = function(self, ...)
        if self.isopen and self.button_spice then
            self.button_spice:Kill()
            self.button_spice = nil
        end
        return OldClose(self, ...)
    end
end)

------------------------------ 秋千 ----------------------------------

AddPlayerPostInit(function(inst)
    inst.entity:AddFollower()
end)
