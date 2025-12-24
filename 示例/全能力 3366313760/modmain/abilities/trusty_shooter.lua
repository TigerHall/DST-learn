local Utils = require("aab_utils/utils")

table.insert(Assets, Asset("ANIM", "anim/player_pistol.zip"))
table.insert(PrefabFiles, "aab_trusty_shooter")

STRINGS.NAMES.AAB_TRUSTY_SHOOTER = "气枪喇叭"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AAB_TRUSTY_SHOOTER = "可以有效利用多余的材料。"
STRINGS.RECIPE_DESC.AAB_TRUSTY_SHOOTER = "它是一把小手枪。"

----------------------------------------------------------------------------------------------------

AAB_AddCharacterRecipe("aab_trusty_shooter", { Ig("twigs", 1), Ig("rocks", 2) }, {
    atlas = "images/inventoryimages/trusty_shooter.xml",
    image = "trusty_shooter.tex"
})

----------------------------------------------------------------------------------------------------

local params = require("containers").params

params.aab_trusty_shooter =
{
    widget =
    {
        slotpos = {
            Vector3(0, 2, 0),
        },
        animbank = "ui_antlionhat_1x1",
        animbuild = "ui_antlionhat_1x1",
        pos = Vector3(0, 40, 0),
    },
    type = "hand_inv",
    excludefromcrafting = true,
}

function params.aab_trusty_shooter.itemtestfn(container, item, slot)
    return item:HasTag("_stackable")
        and not item:HasTag("irreplaceable")
end

----------------------------------------------------------------------------------------------------
AddStategraphPostInit("wilson", function(sg)
    Utils.FnDecorator(sg.actionhandlers[ACTIONS.ATTACK], "deststate", function(inst, action)
        local playercontroller = inst.components.playercontroller
        local attack_tag = playercontroller ~= nil and playercontroller.remote_authority and playercontroller.remote_predicting and "abouttoattack" or "attack"
        if not (inst.sg:HasStateTag(attack_tag) and action.target == inst.sg.statemem.attacktarget or inst.components.health:IsDead()) then
            local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
            if weapon and weapon:HasTag("aab_gun") then
                return { "aab_hand_shoot" }, true
            end
        end
    end)
end)

AddStategraphPostInit("wilson_client", function(sg)
    Utils.FnDecorator(sg.actionhandlers[ACTIONS.ATTACK], "deststate", function(inst, action)
        if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or IsEntityDead(inst)) then
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip and equip:HasTag("aab_gun") then
                return { "aab_hand_shoot" }, true
            end
        end
    end)
end)

AddStategraphState("wilson", State {
    name = "aab_hand_shoot",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" },

    onenter = function(inst)
        if inst.components.rider:IsRiding() then
            inst.Transform:SetFourFaced()
        end

        inst.AnimState:PlayAnimation("hand_shoot")
        if inst.sg.laststate == inst.sg.currentstate then
            inst.sg.statemem.chained = true
            inst.AnimState:SetFrame(13)
        end

        inst.sg:SetTimeout((inst.sg.statemem.chained and 12 or 24) * FRAMES)

        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        if target and target:IsValid() then
            inst.components.combat:BattleCry()
            inst:FacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.target = target
        end
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
    end,

    timeline =
    {
        TimeEvent(5 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end
        end),
        TimeEvent(8 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                inst.sg:RemoveStateTag("attack")
            end
        end),
        TimeEvent(17 * FRAMES, function(inst)
            if not inst.sg.statemem.chained then
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end
        end),
        TimeEvent(20 * FRAMES, function(inst)
            if not inst.sg.statemem.chained then
                inst.sg:RemoveStateTag("attack")
            end
        end),
    },

    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },

    onexit = function(inst)
        if inst.components.rider:IsRiding() then
            inst.Transform:SetSixFaced()
        end

        inst.components.combat:SetTarget(nil)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
})

AddStategraphState("wilson_client", State {
    name = "aab_hand_shoot",
    tags = { "attack", "notalking", "abouttoattack" },

    onenter = function(inst)
        if inst.replica.rider and inst.replica.rider:IsRiding() then
            inst.Transform:SetFourFaced()
        end

        inst.AnimState:PlayAnimation("hand_shoot")
        if inst.sg.laststate == inst.sg.currentstate then
            inst.sg.statemem.chained = true
            inst.AnimState:SetFrame(13)
        end

        inst.sg:SetTimeout((inst.sg.statemem.chained and 12 or 24) * FRAMES)

        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        if target and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.attacktarget = target
        end
        inst.replica.combat:StartAttack()
        inst.components.locomotor:Stop()
    end,

    timeline =
    {
        TimeEvent(5 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                inst:PerformPreviewBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end
        end),
        TimeEvent(8 * FRAMES, function(inst)
            if inst.sg.statemem.chained then
                inst.sg:RemoveStateTag("attack")
            end
        end),
        TimeEvent(17 * FRAMES, function(inst)
            inst:PerformPreviewBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
        end),
        TimeEvent(20 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("attack")
        end),
    },

    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    events =
    {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end),
    },

    onexit = function(inst)
        if inst.replica.rider and inst.replica.rider:IsRiding() then
            inst.Transform:SetSixFaced()
        end

        if inst.sg:HasStateTag("abouttoattack") then
            inst.replica.combat:CancelAttack()
        end
    end,
})
