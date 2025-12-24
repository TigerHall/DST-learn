local Utils = require("aab_utils/utils")
local Constructor = require("aab_utils/constructor")

-- 原版角色
TUNING.AAB_CHARACTERS = {
    "wilson",
    "willow",
    "wolfgang",
    "wendy",
    "wx78",
    "wickerbottom",
    "woodie",
    "wes",
    "waxwell",
    "wathgrithr",
    "webber",
    "winona",
    "warly",
    "walter",

    --猴子和dlc角色不要，不能直接设置build那样，跟皮肤有关，比较麻烦
    -- "wortox",
    -- "wormwood",
    -- "wurt",
    -- "wanda",
    -- "wonkey", --hidden internal char
}

table.insert(PrefabFiles, "aab_minion")

----------------------------------------------------------------------------------------------------
local function ArriveAnywhere()
    return true
end

Constructor.AddAction({ priority = 11, instant = true, mount_valid = true, customarrivecheck = ArriveAnywhere, },
    "AAB_PICK_MINION",
    AAB_L("Summon", "召唤"),
    function(act)
        local minions = {}
        local del
        local max_time = 0
        for k in pairs(act.doer.components.leader.followers) do
            if k.prefab == "aab_minion" and not IsEntityDead(k) then
                if k:GetTimeAlive() > max_time then
                    max_time = k:GetTimeAlive()
                    del = k
                end

                table.insert(minions, k)
            end
        end

        if #minions >= 3 then --最多存在3个
            del.disappear = true
            del.components.health:Kill()
        end
        SpawnPrefab("aab_minion"):Setup(act.doer, act.target)
        act.doer.components.hunger:DoDelta(-2) --给点代价，意思意思

        return true
    end
)

local function CanMinion(doer)
    return doer.replica.hunger and doer.replica.hunger:GetCurrent() >= 2
end

-- 分身砍、凿、挖
AAB_AddComponentAction("SCENE", "workable", function(inst, doer, actions, right)
    if CanMinion(doer)
        and right
        and (inst:IsActionValid(ACTIONS.CHOP, right)
            or inst:IsActionValid(ACTIONS.MINE, right)
            or (inst:HasTag("tree") and inst:IsActionValid(ACTIONS.DIG, right)))
    then
        table.insert(actions, ACTIONS.AAB_PICK_MINION)
    end
end)

-- 分身拾取
AAB_AddComponentAction("SCENE", "inventoryitem", function(inst, doer, actions, right)
    if CanMinion(doer)
        and right
        and inst.replica.inventoryitem:CanBePickedUp(doer)
        and not (inst:HasTag("catchable") or (inst:HasTag("fire") and not inst:HasTag("lighter")) or inst:HasTag("smolder"))
        and not inst:HasTag("heavy")
    then
        table.insert(actions, ACTIONS.AAB_PICK_MINION)
    end
end)

-- 分身采集
AAB_AddComponentAction("SCENE", "pickable", function(inst, doer, actions, right)
    if CanMinion(doer)
        and right
        and inst:HasTag("pickable")
        and not (inst:HasTag("fire") or inst:HasTag("intense"))
    then
        table.insert(actions, ACTIONS.AAB_PICK_MINION)
    end
end)

----------------------------------------------------------------------------------------------------
local COVER_ACTIONS = {
    [ACTIONS.PICKUP] = true,
    [ACTIONS.LOOKAT] = true,
    [ACTIONS.PICK] = true,
}

-- 当右键存在多余的action时，禁止召唤
local function GetRightClickActionsAfter(retTab, self, pos, target)
    if not target then return retTab end

    local bufs = retTab[1]
    local minion_bufs = {}
    local forbid = false
    for _, v in ipairs(bufs) do
        if v.action == ACTIONS.AAB_PICK_MINION then
            table.insert(minion_bufs, v)
        elseif not COVER_ACTIONS[v.action] then
            -- print("有其他action", v.action.id)
            --右键存在其他的action，将不能召唤
            forbid = true
        end
    end

    if forbid then
        for _, v in ipairs(minion_bufs) do
            table.removearrayvalue(bufs, v)
        end
    end

    return retTab
end

AddComponentPostInit("playeractionpicker", function(self)
    Utils.FnDecorator(self, "GetRightClickActions", nil, GetRightClickActionsAfter)
end)
