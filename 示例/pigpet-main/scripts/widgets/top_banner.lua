local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local TopBanner = Class(Widget, function(self, init_text)
    Widget._ctor(self, "TopBanner")

    -- 背景（如果没有 atlas/tex 可以注释掉这一行）
    -- self.bg = self:AddChild(Image("images/ui.xml", "panel.tex"))
    -- self.bg:SetTint(0,0,0,0.6)
    -- self.bg:SetScale(1, 1, 1)
     -- 使 widget 相对于屏幕左上角定位
    self.text = self:AddChild(Text(UIFONT, 28))
    self.text:SetString(init_text or "")

    -- 初始定位（会在 AddClassPostConstruct 时被父控件调整）
    self.margin_x = 1050
    self.margin_y = 150

    -- 每隔 1 秒打印 hello（启动定时器）
     GetPlayer():DoPeriodicTask(1, function()
        local world = GetWorld()
        if not world or not world.components then
            return
        end

        local desc = ""
        if world.components.hounded then
            desc = "下一次猎犬来袭: " .. tostring(math.floor(world.components.hounded.timetoattack or 0)) .. " 秒" .. " | 猎犬数量: " .. tostring(world.components.hounded.houndstorelease or 0) .. "\n"
        end
        self:SetString(desc)
    end)
end)

function TopBanner:SetString(s)
    self.text:SetString(s or "")
end

return TopBanner