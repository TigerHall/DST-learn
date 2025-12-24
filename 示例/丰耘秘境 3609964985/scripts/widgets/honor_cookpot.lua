local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local ImageButton = require "widgets/imagebutton"

local IMAGE_SIZE = {80, 50}
local TEXT_SIZE = 40

local HonorCookpot = Class(Widget, function(self, owner)
    Widget._ctor(self, "HonorCookpot")

    self.owner = owner

    self.honor_cookpot = nil    -- 记录当前的辉煌炼化容器

    -- 烹饪箭头
    self.cookarrow = self:AddChild(UIAnim())
	self.cookarrow:GetAnimState():SetBuild("ui_honor_cookpot_widgets")
	self.cookarrow:GetAnimState():SetBank("ui_honor_cookpot_widgets")
	self.cookarrow:GetAnimState():PlayAnimation("arrow1_idle")
	self.cookarrow:SetPosition(-120, 0)
    self.cookarrow:SetScale(0.6)

    -- 烹饪进度条
    self.cookprogress = self:AddChild(UIAnim())
	self.cookprogress:GetAnimState():SetBuild("ui_honor_cookpot_widgets")
	self.cookprogress:GetAnimState():SetBank("ui_honor_cookpot_widgets")
	self.cookprogress:GetAnimState():PlayAnimation("progress1_idle")
	self.cookprogress:SetPosition(-230, 15)

    -- 研磨箭头
    self.grindarrow = self:AddChild(UIAnim())
	self.grindarrow:GetAnimState():SetBuild("ui_honor_cookpot_widgets")
	self.grindarrow:GetAnimState():SetBank("ui_honor_cookpot_widgets")
	self.grindarrow:GetAnimState():PlayAnimation("arrow1_idle")
	self.grindarrow:SetPosition(120, 0)
    self.grindarrow:SetScale(0.6)

    -- 调味箭头
    self.seasonarrow = self:AddChild(UIAnim())
	self.seasonarrow:GetAnimState():SetBuild("ui_honor_cookpot_widgets")
	self.seasonarrow:GetAnimState():SetBank("ui_honor_cookpot_widgets")
	self.seasonarrow:GetAnimState():PlayAnimation("arrow2_idle")
	self.seasonarrow:SetPosition(0, -110)
    self.seasonarrow:SetScale(0.5)

    -- 调味进度条
    self.seasonprogress = self:AddChild(UIAnim())
	self.seasonprogress:GetAnimState():SetBuild("ui_honor_cookpot_widgets")
	self.seasonprogress:GetAnimState():SetBank("ui_honor_cookpot_widgets")
	self.seasonprogress:GetAnimState():PlayAnimation("progress2_idle")
    self.seasonprogress:SetPosition(0, -250)

    -- 烹饪
    self.cookbutton = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.cookbutton:ForceImageSize(unpack(IMAGE_SIZE))
    self.cookbutton:SetPosition(-120, 0)
    self.cookbutton:SetFont(CHATFONT)
    self.cookbutton.text:SetColour(0, 0, 0, 1)
    self.cookbutton.text:SetSize(TEXT_SIZE)
    self.cookbutton:SetScale(1)
    self.cookbutton.onclick = function()
        if self.honor_cookpot ~= nil then
            if not self.honor_cookpot._cookbtn:value() then
                SendModRPCToServer(MOD_RPC["HMR"]["honor_cookpot_cook"], self.honor_cookpot, true)
                self.cookbutton:SetText(STRINGS.HMR.HONOR_COOKPOT.STOP_COOK_BUTTON)
            else
                SendModRPCToServer(MOD_RPC["HMR"]["honor_cookpot_cook"], self.honor_cookpot, false)
                self.cookbutton:SetText(STRINGS.HMR.HONOR_COOKPOT.START_COOK_BUTTON)
            end
        end
    end

    -- 研磨
    self.grindbutton = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.grindbutton:ForceImageSize(unpack(IMAGE_SIZE))
    self.grindbutton:SetPosition(120, 0)
    self.grindbutton:SetFont(CHATFONT)
    self.grindbutton.text:SetColour(0, 0, 0, 1)
    self.grindbutton.text:SetSize(TEXT_SIZE)
    self.grindbutton:SetScale(1)
    self.grindbutton:SetText(STRINGS.HMR.HONOR_COOKPOT.GRIND_BUTTON)
    self.grindbutton.onclick = function()
        if self.honor_cookpot ~= nil then
            SendModRPCToServer(MOD_RPC["HMR"]["honor_cookpot_grind"], self.honor_cookpot)
        end
    end

    -- 调味
    self.seasonbutton = self:AddChild(ImageButton("images/global_redux.xml", "button_carny_long_normal.tex", "button_carny_long_hover.tex", "button_carny_long_disabled.tex", "button_carny_long_down.tex"))
    self.seasonbutton:ForceImageSize(unpack(IMAGE_SIZE))
    self.seasonbutton:SetPosition(0, -80)
    self.seasonbutton:SetFont(CHATFONT)
    self.seasonbutton.text:SetColour(0, 0, 0, 1)
    self.seasonbutton.text:SetSize(TEXT_SIZE)
    self.seasonbutton:SetScale(1)
    self.seasonbutton:SetText(STRINGS.HMR.HONOR_COOKPOT.SEASON_BUTTON)
    self.seasonbutton.onclick = function()
        if self.honor_cookpot ~= nil then
            SendModRPCToServer(MOD_RPC["HMR"]["honor_cookpot_season"], self.honor_cookpot)
        end
    end
end)

function HonorCookpot:SetCookpot(cookpot)
    local old_cookpot = self.honor_cookpot
    self.honor_cookpot = cookpot

    local function OnIsCookingDirty(_cookpot)
        local cooking = _cookpot._is_cooking:value()
        if cooking then
            self.cookarrow:GetAnimState():PlayAnimation("arrow1_cooking")
        else
            self.cookarrow:GetAnimState():PlayAnimation("arrow1_idle")
        end
    end
    local function OnCookPercentDirty(_cookpot)
        if _cookpot._is_cooking:value() then
            self.cookprogress:GetAnimState():PlayAnimation("progress1_cooking")
            local percent = 1 - _cookpot._cook_percent:value()
            local frames = self.cookprogress:GetAnimState():GetCurrentAnimationNumFrames() or 0
            self.cookprogress:GetAnimState():SetFrame(math.floor(frames * percent))
            self.cookprogress:GetAnimState():Pause()
        else
            self.cookprogress:GetAnimState():PlayAnimation("progress1_idle")
        end
    end
    local function OnIsSeasoningDirty(_cookpot)
        local seasoning = _cookpot._is_seasoning:value()
        if seasoning then
            self.seasonarrow:GetAnimState():PlayAnimation("arrow2_cooking")
        else
            self.seasonarrow:GetAnimState():PlayAnimation("arrow2_idle")
        end
    end
    local function OnSeasonPercentDirty(_cookpot)
        if _cookpot._is_seasoning:value() then
            self.seasonprogress:GetAnimState():PlayAnimation("progress2_cooking")
            local percent = 1 - _cookpot._season_percent:value()
            local frames = self.seasonprogress:GetAnimState():GetCurrentAnimationNumFrames() or 0
            self.seasonprogress:GetAnimState():SetFrame(math.floor(frames * percent))
            self.seasonprogress:GetAnimState():Pause()
        else
            self.seasonprogress:GetAnimState():PlayAnimation("progress2_idle")
        end
    end

    if self.honor_cookpot ~= nil then
        if self.honor_cookpot._cookbtn:value() then
            self.cookbutton:SetText(STRINGS.HMR.HONOR_COOKPOT.STOP_COOK_BUTTON)
        else
            self.cookbutton:SetText(STRINGS.HMR.HONOR_COOKPOT.START_COOK_BUTTON)
        end

        self.honor_cookpot:ListenForEvent("net_is_cooking_dirty", OnIsCookingDirty)
        self.honor_cookpot:ListenForEvent("net_cook_percent_dirty", OnCookPercentDirty)
        self.honor_cookpot:ListenForEvent("net_is_seasoning_dirty", OnIsSeasoningDirty)
        self.honor_cookpot:ListenForEvent("net_season_percent_dirty", OnSeasonPercentDirty)
    elseif old_cookpot ~= nil then
        old_cookpot:RemoveEventCallback("net_is_cooking_dirty", OnIsCookingDirty)
        old_cookpot:RemoveEventCallback("net_cook_percent_dirty", OnCookPercentDirty)
        old_cookpot:RemoveEventCallback("net_is_seasoning_dirty", OnIsSeasoningDirty)
        old_cookpot:RemoveEventCallback("net_season_percent_dirty", OnSeasonPercentDirty)
    end
end

-- fronted.lua中调用了，不写会报错
function HonorCookpot:OnUpdate()
end

return HonorCookpot