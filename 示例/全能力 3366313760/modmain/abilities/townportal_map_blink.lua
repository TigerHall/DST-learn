local Utils = require("aab_utils/utils")
local Constructor = require("aab_utils/constructor")
local GetPrefab = require("aab_utils/getprefab")



----------------------------------------------------------------------------------------------------

local function ArriveAnywhere()
    return true
end

Constructor.AddAction({ priority == 11, rmb = true, customarrivecheck = ArriveAnywhere, mount_valid = true, map_action = true, instant = true },
    "AAB_TOWNPORTAL_BLINK",
    AAB_L("Teleport", "传送"),
    function(act)
        if act.doer ~= nil and act.doer.sg ~= nil and act.doer.sg.currentstate.name == "channeling" and act.doer.sg.statemem.target and act.target then
            local start = act.doer.sg.statemem.target
            local dest = act.target._target

            --官方的太难用了，事件推送来推送去，设置的target马上就被刷掉了
            start._aab_spawn_fx = true
            local fx = SpawnAt("townportalsandcoffin_fx", act.doer)
            fx:DoTaskInTime(26 * FRAMES, fx.KillFX)
            start.components.teleporter:UseTemporaryExit(act.doer, dest)

            return true
        end
        return true
    end
)

local MAP_SELECT_TOWNPORTAL_MUST = { "CLASSIFIED", "globalmapicon", "aab_townportalicon" };
Utils.FnDecorator(ACTIONS_MAP_REMAP, ACTIONS.BLINK.code, function(act, targetpos)
    local x, y, z = targetpos:Get()
    local target = GetPrefab.FindClosestEnt(TheSim:FindEntities(x, y, z, 6, MAP_SELECT_TOWNPORTAL_MUST), targetpos)
    if target then
        return { BufferedAction(act.doer, target, ACTIONS.AAB_TOWNPORTAL_BLINK) }, true
    end
end)

----------------------------------------------------------------------------------------------------
local function ProcessRMBDecorations_AAB_TOWNPORTAL_BLINK(self, rmb, fresh)
    for _, ent in pairs(Ents) do
        if ent:HasTags(MAP_SELECT_TOWNPORTAL_MUST) then
            local data = self.decorationdata.staticdecorations[ent.GUID .. "_TOWNPORTAL"]
            if data then
                local decoration = data.decoration
                if not data.mapfocus then
                    decoration:GetAnimState():PlayAnimation(data.animgainfocus[1], true)
                    for i = 2, #data.animgainfocus do
                        decoration:GetAnimState():PushAnimation(data.animgainfocus[i])
                    end
                end
                data.mapfocus = TheSim:GetStep() --screens use wallupdate and don't pause like simtick
                break
            end
        end
    end
end

local function ProcessRMBDecorationsAfter(retTab, self, rmb, fresh)
    if rmb.action == ACTIONS.AAB_TOWNPORTAL_BLINK then
        ProcessRMBDecorations_AAB_TOWNPORTAL_BLINK(self, rmb, fresh)
    end
end

local UIAnim = require("widgets/uianim")

-- 初始化塔的图标
local function ProcessStaticDecorationsAfter(retTab, self)
    if not self.owner or not self.owner:HasTag("channeling") then
        return --没触摸小地图不播放动画
    end

    local staticdecorations = self.decorationdata.staticdecorations
    local zoomscale = 0.75 / self.minimap:GetZoom()
    local w, h = TheSim:GetScreenSize()
    w, h = w * 0.5, h * 0.5

    local minzoomscale = 0.18
    local maxzoomscale = 0.55
    local overallzoomscaler = 3.6
    local zoomradius = TUNING.SKILLS.WINONA.WORMHOLE_DETECTION_RADIUS
    local zoomscale_clamped = math.clamp(zoomscale, minzoomscale or zoomscale, maxzoomscale or zoomscale) * overallzoomscaler
    for _, ent in pairs(Ents) do
        if ent:HasTags(MAP_SELECT_TOWNPORTAL_MUST) then
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            if self.owner.CanSeePointOnMiniMap and self.owner:CanSeePointOnMiniMap(ex, ey, ez) then
                local decoration = self.decorationrootstatic:AddChild(UIAnim())
                staticdecorations[ent.GUID .. "_TOWNPORTAL"] = {
                    ent = ent,
                    decoration = decoration,
                    minzoomscale = minzoomscale,
                    maxzoomscale = maxzoomscale,
                    overallzoomscaler = overallzoomscaler,
                    zoomradius = zoomradius,
                    animgainfocus = { "proximity_pre", "proximity_loop" },
                    animlosefocus = { "proximity_pst", "idle" },
                }
                local animstate = decoration:GetAnimState()
                animstate:SetBank("roseglasses_minimap_indicator")
                animstate:SetBuild("roseglasses_minimap_indicator")
                animstate:PlayAnimation("idle", true)
                local x, y = self.minimap:WorldPosToMapPos(ex, ez, 0)
                decoration:SetPosition(x * w, y * h)
                decoration:SetScale(zoomscale_clamped, zoomscale_clamped, 1)
            end
        end
    end
end

AddClassPostConstruct("screens/mapscreen", function(self)
    Utils.FnDecorator(self, "ProcessRMBDecorations", nil, ProcessRMBDecorationsAfter)

    ProcessStaticDecorationsAfter(nil, self)
    Utils.FnDecorator(self, "ProcessStaticDecorations", nil, ProcessStaticDecorationsAfter) --好像也没必要了，初始化的时候就执行了
end)

----------------------------------------------------------------------------------------------------

AAB_AddClickAction(function(inst, target, pos, useitem, right, bufs)
    if #bufs <= 0
        and right
        and useitem == nil
        and inst.checkingmapactions --只能进行小地图传送，这方法主机也会调用
        and inst:HasTag("channeling")
    then
        return ACTIONS.BLINK
    end
end)

----------------------------------------------------------------------------------------------------

local function CreateHiddenGlobalIcon(inst)
    inst.hiddenglobalicon = SpawnPrefab("globalmapiconseeable")
    inst.hiddenglobalicon.MiniMapEntity:SetPriority(50) -- NOTES(JBK): This could be put to a constant for map actions that should go over everything as a reserved flag.
    inst.hiddenglobalicon.MiniMapEntity:SetRestriction("wormholetracker")
    inst.hiddenglobalicon:AddTag("aab_townportalicon")  --根据标签查找
    inst.hiddenglobalicon:TrackEntity(inst)
end

-- 传送完来点特效
local function OnDoneTeleporting(inst, ent)
    if ent and ent:HasTag("player") and inst._aab_spawn_fx then
        local fx = SpawnAt("townportalsandcoffin_fx", ent)
        fx:DoTaskInTime(26 * FRAMES, fx.KillFX)
    end
    inst._aab_spawn_fx = nil
end

AddPrefabPostInit("townportal", function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("doneteleporting", OnDoneTeleporting)

    inst:DoTaskInTime(0, CreateHiddenGlobalIcon)
end)
