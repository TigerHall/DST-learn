AddGamePostInit(function()
    AAB_ReplaceCharacterLines("wortox")
end)

AAB_ActivateSkills("wortox")

AAB_AddClickAction(function(inst, target, pos, useitem, right, bufs)
    if #bufs <= 0
        and right
        and not target
        and not useitem
    then
        local canblink
        if inst.checkingmapactions then
            canblink = inst.CanBlinkFromWithMap(inst:GetPosition())
        else
            canblink = inst.CanBlinkTo(pos)
        end
        if canblink and inst.CanSoulhop and inst:CanSoulhop() then
            return ACTIONS.BLINK
        end
    end
end)

----------------------------------------------------------------------------------------------------

local function CanBlinkTo(pt)
    return TheWorld.Map:IsPassableAtPoint(pt:Get()) and not TheWorld.Map:IsGroundTargetBlocked(pt) -- NOTES(JBK): Keep in sync with blinkstaff. [BATELE]
end

local function CanBlinkFromWithMap(pt)
    return true -- NOTES(JBK): Change this if there is a reason to anchor Wortox when trying to use the map to teleport.
end

local function ReticuleTargetFn(inst)
    return ControllerReticle_Blink_GetPosition(inst, inst.CanBlinkTo)
end

local function CanSoulhop(inst, souls)
    if inst.replica.hunger and inst.replica.hunger:GetCurrent() >= (souls or 1) * 5 then
        local rider = inst.replica.rider
        if rider == nil or not rider:IsRiding() then
            return true
        end
    end
    return false
end

local function TryToPortalHop(inst, souls, consumeall)
    local cost = (souls or 1) * 5
    if inst.components.hunger.current < cost then
        return false
    end

    inst.components.hunger:DoDelta(-cost)

    return true
end

AddPlayerPostInit(function(inst)
    if inst.prefab == "wortox" then return end

    inst:AddTag("soulstealer")

    inst.CanSoulhop = CanSoulhop
    inst.CanBlinkTo = CanBlinkTo
    inst.CanBlinkFromWithMap = CanBlinkFromWithMap

    if not inst.components.reticule then
        inst:AddComponent("reticule")
    end
    inst.components.reticule.targetfn = ReticuleTargetFn
    inst.components.reticule.ease = true

    if not TheWorld.ismastersim then return end

    inst.TryToPortalHop = TryToPortalHop
    inst.DoCheckSoulsAdded = function() end
end)
