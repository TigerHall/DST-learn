local Text = require "widgets/text"
local Widget = require "widgets/widget"

local Configuration = Class(Widget, function(self)
	Widget._ctor(self, "Configuration")

    self.root = self:AddChild(Widget("root"))
    self.root:SetPosition(0, 0, 0)

    self.text = self.root:AddChild(Text(HEADERFONT, 50, "施工中..."))
    self.text:SetPosition(0, 0, 0)
end)

return Configuration
