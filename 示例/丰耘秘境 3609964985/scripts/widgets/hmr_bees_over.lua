local UIAnim = require "widgets/uianim"

local SOUND_NAME = "loop"

local BeesOver = Class(UIAnim, function(self, owner)
    self.owner = owner
    UIAnim._ctor(self)

    self:SetClickable(false)

    self:SetHAnchor(ANCHOR_MIDDLE)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)

    self:GetAnimState():SetBank("hmr_terrorbee_over")
    self:GetAnimState():SetBuild("hmr_terrorbee_over")
    self:GetAnimState():PlayAnimation("over_idle", true)
    self:GetAnimState():AnimateWhilePaused(false)

    self:Hide()

    self.owner:ListenForEvent("net_terrorevent_dirty", function()
        local event = self.owner.net_terrorevent:value()
        if event == "terror_bees" then
            self:Enable()
        else
            self:Disable()
        end
    end)
end)

function BeesOver:Enable()
    self:Show()

    self:GetAnimState():PlayAnimation("over_pre")
    self:GetAnimState():PushAnimation("over_idle", true)

    TheFocalPoint.SoundEmitter:PlaySound("meta4/ancienttree/nightvision/effect_LP", SOUND_NAME)
end

function BeesOver:Disable()
    self:GetAnimState():PlayAnimation("over_pst")

    TheFocalPoint.SoundEmitter:KillSound(SOUND_NAME)
end

return BeesOver
