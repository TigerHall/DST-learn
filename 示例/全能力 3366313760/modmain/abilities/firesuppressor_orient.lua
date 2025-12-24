table.insert(PrefabFiles, "aab_firesuppressor_orient")

----------------------------------------------------------------------------------------------------

STRINGS.NAMES.AAB_FIRESUPPRESSOR_ORIENT = AAB_L("Orienting Device", "定位装置")
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AAB_FIRESUPPRESSOR_ORIENT = AAB_L("This device directs the snowball launcher to fire in a specific direction.", "这东西在哪里，雪球发射器就会往哪里发射。")

STRINGS.ACTIONS.AAB_FIRESUPPRESSOR_ORIENT = {
    RETRIEVE = "收回",
    DETACH = "取下"
}

----------------------------------------------------------------------------------------------------
local OnFindFire

local function UnBind(inst)
    inst:RemoveTag("aab_orient_detached")
    inst.components.entitytracker:ForgetEntity("aab_firesuppressor_orient")
    inst.components.aab_simpleperiodtask:Cancel("orient") --不能移除组件，万一其他的地方还要用呢
    inst.components.firedetector:SetOnFindFireFn(OnFindFire)
end

local function Launch(inst)
    if inst.components.machine:IsOn() then
        local item = inst.components.entitytracker:GetEntity("aab_firesuppressor_orient")
        if item then                             --一定存在
            OnFindFire(inst, item:GetPosition()) --这里不考虑射程了，扔的特别远，感觉也挺有意思的
        end
    end
end

local function Bind(inst, target)
    inst:AddTag("aab_orient_detached") --客机判断使用
    if not inst.components.aab_simpleperiodtask then
        inst:AddComponent("aab_simpleperiodtask")
    end
    inst.components.aab_simpleperiodtask:DoPeriodicTask("orient", TUNING.FIRE_DETECTOR_PERIOD, Launch)
    inst:ListenForEvent("onremove", function() UnBind(inst) end, target)
    inst.components.firedetector:SetOnFindFireFn(function() end) --屏蔽掉原来的发射

    target:Setup(inst)
end

-- 就当替代onsave和onload了
local function TrackEntityBefore(self, name, inst)
    if name == "aab_firesuppressor_orient" then
        Bind(self.inst, inst)
    end
end

local Utils = require("aab_utils/utils")
AddPrefabPostInit("firesuppressor", function(inst)
    if not TheWorld.ismastersim then return end

    if not inst.components.entitytracker then
        inst:AddComponent("entitytracker")
    end
    Utils.FnDecorator(inst.components.entitytracker, "TrackEntity", TrackEntityBefore)

    OnFindFire = OnFindFire or inst.components.firedetector.onfindfire
end)


----------------------------------------------------------------------------------------------------

local Constructor = require("aab_utils/constructor")
Constructor.AddAction({}, "AAB_FIRESUPPRESSOR_ORIENT", function(act)
    return act.target:HasTag("aab_orient_detached") and "RETRIEVE" or "DETACH"
end, function(act)
    if not act.target.components.entitytracker then
        return false
    end

    local item = act.target.components.entitytracker:GetEntity("aab_firesuppressor_orient")
    if item then
        --收回
        item:Remove()
    else
        --取下
        item = SpawnPrefab("aab_firesuppressor_orient")
        act.target.components.entitytracker:TrackEntity("aab_firesuppressor_orient", item)
        act.doer.components.inventory:GiveItem(item)
    end

    return true
end, "domediumaction", "domediumaction")

AAB_AddComponentAction("SCENE", "firedetector", function(inst, doer, actions, right)
    if inst.prefab == "firesuppressor" then
        table.insert(actions, ACTIONS.AAB_FIRESUPPRESSOR_ORIENT)
    end
end)
