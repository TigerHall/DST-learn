require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/doaction"
--require "behaviours/choptree"
require "behaviours/findlight"
require "behaviours/panic"
require "behaviours/chattynode"
require "behaviours/leash"

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30


--卡在idle状态下超过1秒就记为失败
local function BufValid(buf)
    return buf.doer and buf.doer.sg and (buf.doer.sg.currentstate.name ~= "idle" or buf.doer.sg:GetTimeInState() < 1)
end

--- 封装一下bufferaction，我希望在动作被中断后DoAction立即判断为失败，而不是让分身站在那不动
local function WrapBuf(buf)
    buf.validfn = BufValid
    return buf
end

----------------------------------------------------------------------------------------------------

local function Disappear(inst)
    inst.target = nil
    inst.disappear = true
    if not inst.sg:HasStateTag("dead") then
        inst.components.health:Kill()
    end
end

local ATTACK_ONEOF_TAGS = { "monster", "hostile" }

local function CheckPickUp(inst, ent)
    return ent.components.inventoryitem
        and not ent.components.inventoryitem:IsHeld()
        and ent.components.inventoryitem.canbepickedup
        and ent.components.inventoryitem.cangoincontainer
        and inst.components.inventory:CanAcceptCount(ent) > 0
end

local function CheckPick(inst, ent)
    return ent.components.pickable and ent.components.pickable.canbepicked
end

local function CheckWork(inst, ent)
    local act = ent.components.workable and ent.components.workable:CanBeWorked() and ent.components.workable:GetWorkAction()
    return act == ACTIONS.MINE or act == ACTIONS.CHOP or act == ACTIONS.DIG
end

local function CheckTarget(inst, ent)
    return ent.components.combat
        and inst.components.combat:CanTarget(ent)
        and inst.components.combat:ShouldAggro(ent)
end

local function FindTarget(inst, checkfn, musttags, canttags, oneoftags)
    if inst.target and inst.target:IsValid() and checkfn(inst, inst.target) then
        return true
    end

    local ents = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    canttags = canttags or {}
    table.insert(canttags, { "INLIMBO" })
    for _, v in ipairs(TheSim:FindEntities(x, y, z, 8, musttags, canttags, oneoftags)) do
        if v.prefab == inst.targetprefab and checkfn(inst, v) then
            table.insert(ents, v)
        end
    end
    if #ents > 0 then
        inst.target = GetClosest(inst, ents)
        return true
    end

    inst.target = nil
    return false
end

-- 检查和刷新目标
local function UpdateTarget(inst)
    local leader = inst.components.follower:GetLeader()
    if not leader then
        Disappear(inst)
        return false
    end

    local target = inst.target
    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.type == "pickup" then
        if FindTarget(inst, CheckPickUp, { "_inventoryitem" }, { "eog_picktag" }) then
            return true
        end
    elseif inst.type == "pick" then
        if FindTarget(inst, CheckPick, { "pickable" }, { "fire", "intense" }) then
            return true
        end
    elseif inst.type == "work" then
        if FindTarget(inst, CheckWork, nil, nil, { "CHOP_workable", "MINE_workable", "DIG_workable" }) then
            return true
        end
    elseif inst.type == "attack" then
        local canattack = false
        if target and target:IsValid() and CheckTarget(inst, target) then
            canattack = true
        end

        if not canattack then
            local ents = {}
            for _, v in ipairs(TheSim:FindEntities(x, y, z, 8, { "_combat" })) do
                if CheckTarget(inst, v)
                    and ((v.components.combat.target and (v.components.combat.target:HasTag("player") or v.components.combat.target == inst))
                        or (v:HasOneOfTags(ATTACK_ONEOF_TAGS) and (not v.components.follower or not v.components.follower.leader or not v.components.follower.leader:HasTag("player"))))
                then
                    table.insert(ents, v)
                end
            end
            if #ents > 0 then
                inst.target = GetClosest(inst, ents)
                canattack = true
            end
        end

        if canattack then
            inst.components.combat:SetTarget(inst.target)

            --武器在这里生成一下
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if not equip then
                local weapon = inst:SpawnTempItem("hambat")
                inst.components.inventory:Equip(weapon)
            end

            return true
        end
    end

    Disappear(inst)
    return false
end

----------------------------------------------------------------------------------------------------

local function PickUpAction(inst)
    if inst.type ~= "pickup" then return end
    return WrapBuf(BufferedAction(inst, inst.target, ACTIONS.PICKUP))
end

----------------------------------------------------------------------------------------------------

local function PickAction(inst)
    if inst.type ~= "pick" then return end
    return WrapBuf(BufferedAction(inst, inst.target, ACTIONS.PICK))
end

----------------------------------------------------------------------------------------------------

local function GetTool(inst, act)
    local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equip then
        if equip.components.tool and equip.components.tool:GetEffectiveness(act) ~= 0 then
            return equip
        else
            inst.components.inventory:DropItem(equip)
        end
    end

    local item = act == ACTIONS.CHOP and "multitool_axe_pickaxe"
        or act == ACTIONS.MINE and "multitool_axe_pickaxe"
        or act == ACTIONS.DIG and "shovel_lunarplant"
        or nil
    if item then
        local it = inst:SpawnTempItem(item)
        inst.components.inventory:Equip(it)
        return it
    end
end

local function WorkAction(inst)
    if inst.type ~= "work" then return end
    local act = inst.target.components.workable:GetWorkAction()
    return WrapBuf(BufferedAction(inst, inst.target, act, GetTool(inst, act)))
end

local MinionBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MinionBrain:OnStart()
    local root = PriorityNode({ WhileNode(function() return UpdateTarget(self.inst) end, "In contest",
        PriorityNode({
            DoAction(self.inst, PickUpAction),
            DoAction(self.inst, PickAction),
            DoAction(self.inst, WorkAction),
            WhileNode(function() return self.inst.type == "attack" end, "AttackMomentarily",
                ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST))
        }, 0.1))
    }, .25)

    self.bt = BT(self.inst, root)
end

return MinionBrain
