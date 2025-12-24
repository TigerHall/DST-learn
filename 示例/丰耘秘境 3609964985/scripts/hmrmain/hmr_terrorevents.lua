---------------------------------------------------------------------------
---[[凶险事件]]
---------------------------------------------------------------------------
-- 采摘提示
local oldPICK = GLOBAL.ACTIONS.PICK.fn
GLOBAL.ACTIONS.PICK.fn = function(act)
    if act.target ~= nil and HMR_UTIL.IsTerrorPlant(act.target) then
        if not TheWorld.components.hmrterrorevent:HasPreventSource() then
            local pick_num = TheWorld.components.hmrterrorevent:GetPickNum(act.doer, act.target)
            if pick_num < 2 then
                act.doer:PushEvent("refuseterrorpick")
                TheWorld.components.hmrterrorevent:RecordPick(act.doer, act.target)
                return false, pick_num == 1 and "REFUST_TERROR_PICK" or "REFUST_TERROR_PICK_2"
            else
                TheWorld:PushEvent("terror_event_begin", {picker = act.doer, plant = act.target})
            end
        end
        TheWorld.components.hmrterrorevent:RecordPick(act.doer, act.target)
    end
    return oldPICK(act)
end

local oldDIG = GLOBAL.ACTIONS.DIG.fn
GLOBAL.ACTIONS.DIG.fn = function(act)
    if act.target ~= nil and HMR_UTIL.IsTerrorPlant(act.target) then
        if not TheWorld.components.hmrterrorevent:HasPreventSource() then
            local pick_num = TheWorld.components.hmrterrorevent:GetPickNum(act.doer, act.target)
            if pick_num < 2 then
                act.doer:PushEvent("refuseterrorpick")
                TheWorld.components.hmrterrorevent:RecordPick(act.doer, act.target)
                return false, pick_num == 1 and "REFUST_TERROR_PICK" or "REFUST_TERROR_PICK_2"
            else
                TheWorld:PushEvent("terror_event_begin", {picker = act.doer, plant = act.target})
            end
        end
        TheWorld.components.hmrterrorevent:RecordPick(act.doer, act.target)
    end
    return oldDIG(act)
end

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:AddComponent("hmrterrorevent")
end)

AddPlayerPostInit(function(player)
    player.net_terrorevent = net_string(player.GUID, "net_terrorevent", "net_terrorevent_dirty")
    player.net_terrorevent:set("none")
end)

-- 拒绝采摘
AddStategraphEvent("wilson", EventHandler("refuseterrorpick", function(inst)
    if inst.components.health and not inst.components.health:IsDead() and not inst.sg:HasStateTag("floating") then
        inst.sg:GoToState("refuseeat")
    end
end))
AddStategraphEvent("wilson_client", EventHandler("refuseterrorpick", function(inst)
    if inst.replica.health and not inst.replica.health:IsDead() and not inst.sg:HasStateTag("floating") then
        inst.sg:GoToState("refuseeat")
    end
end))

---------------------------------------------------------------------------
---[[玩家视野]]
---------------------------------------------------------------------------
AddClassPostConstruct("screens/playerhud", function(self)
    local HMR_BeesOver = require("widgets/hmr_bees_over")

    local oldCreateOverlays = self.CreateOverlays
    function self:CreateOverlays(owner)
        oldCreateOverlays(self, owner)
        self.hmr_beesover = self.overlayroot:AddChild(HMR_BeesOver(owner))
    end
end)