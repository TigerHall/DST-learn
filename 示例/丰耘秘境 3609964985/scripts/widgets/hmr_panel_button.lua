local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"

local HMRTech = Class(Widget, function(self, owner)
    Widget._ctor(self, "HMRTech")

    self.owner = owner

    self:SetTooltip("打开丰耘面板")
    --------------------------------------------------------------------------
    -- 打开按钮
    --------------------------------------------------------------------------
    self.openbutton = self:AddChild(ImageButton("images/widgetimages/hmr_tech.xml", "hmr_tech.tex"))
    self.openbutton:MoveToFront()
    self.openbutton:SetFocusScale(0.4, 0.4)
    self.openbutton:SetNormalScale(0.3, 0.3)
    self.openbutton.onclick = function()
        if self.owner and self.owner.HUD and self.owner.HUD.ShowHMRScreen then
            self.owner.HUD:ShowHMRScreen()
        end
    end
end)

-- fronted.lua中调用了，不写会报错
function HMRTech:OnUpdate()
end

return HMRTech