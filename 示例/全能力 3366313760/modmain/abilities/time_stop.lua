--[[
时停

时停标签：aab_time_stop，不会给玩家添加

]]

local Utils = require("aab_utils/utils")
local TIME_STOP_KEY = GLOBAL["KEY_" .. GetModConfigData("time_stop")]
local TIME_STOP_RADIUS = 40
local TIME_STOP_TIME = 8
local TIME_STOP_CD = 60
local STRINGS_SKILL_CD = AAB_L("Skill cooldown.", "技能冷却中。")

table.insert(Assets, Asset("SOUNDPACKAGE", "sound/allability.fev"))
table.insert(Assets, Asset("SOUND", "sound/allability.fsb"))

local function GroundOrientation(inst)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND) --在地面上
    inst.AnimState:SetSortOrder(3)

    inst.AnimState:SetDeltaTimeMultiplier(inst.AnimState:GetCurrentAnimationLength() / TIME_STOP_TIME)
end

AAB_AddFx({
    name = "aab_time_stop_fx",
    bank = "pocketwatch_cast_fx",
    build = "pocketwatch_casting_fx",
    anim = "pocketwatch_ground", --NOTE: 16 blank frames at the start for audio syncing
    fn = GroundOrientation,
    bloom = true,
})

----------------------------------------------------------------------------------------------------


local function StartPause(inst, ent)
    ent:AddTag("aab_time_stop")
    ent:StopBrain()
    if ent.sg then
        ent.sg:Stop()
    end
    if ent.Physics then
        ent.Physics:SetActive(false)
    end
    if ent.AnimState then
        ent.AnimState:Pause()
    end

    ent._aab_time_stop_start = inst._aab_time_stop_start --同步时长
end

local function StopPause(ent)
    ent:RemoveTag("aab_time_stop")
    if ent.Physics then
        ent.Physics:SetActive(true)
    end
    if ent.AnimState then
        ent.AnimState:Resume()
    end
    ent:RestartBrain()
    if ent.sg then
        ent.sg:Start()
    end

    ent._aab_time_stop_start = nil
end

----------------------------------------------------------------------------------------------------

local CancelTimeStop

local function OnPlayerRemove(inst, data)
    CancelTimeStop(inst)
end

CancelTimeStop = function(inst, task)
    for k, _ in pairs(inst._aab_time_stop_ents) do
        if k:IsValid() then
            StopPause(k)
        end
    end
    inst._aab_time_stop_ents = nil
    inst._aab_time_stop_start = nil
    task:Cancel()

    inst:RemoveEventCallback("onremove", OnPlayerRemove)
    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/MarkPosition")
end

--[[
希望排除以下对象
- 建筑
- 墙体和门
- 特效

]]
local TIME_STOP_CANT_TAGS = { "player", "INLIMBO", "wall", "structure", "can_offset_sort_pos", "FX", "boat" }

-- 刷帧！
local function TryStopNear(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, y, z, TIME_STOP_RADIUS, nil, TIME_STOP_CANT_TAGS)) do
        if not inst._aab_time_stop_ents[v] then
            StartPause(inst, v)
            inst._aab_time_stop_ents[v] = true
        end
    end
end

local function ResetCd(inst)
    inst:RemoveTag("aab_time_stop_cd")
    inst:SpawnChild("pocketwatch_heal_fx")
    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/MarkPosition")
end

AddModRPCHandler(modname, "TimeStop", function(inst)
    if inst._aab_time_stop_ents then return end

    inst:AddTag("aab_time_stop_cd")
    inst:SpawnChild("aab_time_stop_fx")

    inst._aab_time_stop_ents = {}
    inst._aab_time_stop_start = GetTime()

    inst:ListenForEvent("onremove", OnPlayerRemove) --玩家要是这个时候退出游戏就立即停止
    inst:DoTaskInTime(TIME_STOP_TIME, CancelTimeStop, inst:DoPeriodicTask(0, TryStopNear))
    inst:DoTaskInTime(TIME_STOP_CD, ResetCd)
end)

----------------------------------------------------------------------------------------------------
local WAVE_FX_LEN = 0.5
local function WaveFxOnUpdate(inst, dt)
    inst.t = inst.t + dt

    if inst.t < WAVE_FX_LEN then
        local k = 1 - inst.t / WAVE_FX_LEN
        k = k * k
        inst.AnimState:SetMultColour(1, 1, 1, k)
        k = (2 - 1.7 * k) * (inst.scalemult or 1)
        inst.AnimState:SetScale(k, k)
    else
        inst:Remove()
    end
end

local function CreateDomeFX()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("umbrella_voidcloth")
    inst.AnimState:SetBuild("umbrella_voidcloth")
    inst.AnimState:PlayAnimation("barrier_dome")
    inst.AnimState:SetFinalOffset(7)

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(WaveFxOnUpdate)
    inst.t = 0
    WaveFxOnUpdate(inst, 0)

    return inst
end

local function CLIENT_TriggerFX(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = CreateDomeFX()
    fx.Transform:SetPosition(x, 0, z)
    fx.SoundEmitter:PlaySound("meta2/voidcloth_umbrella/barrier_activate")

    TheWorld:PushEvent("screenflash", .5)
end

TheInput:AddKeyDownHandler(TIME_STOP_KEY, function()
    if Utils.IsDefaultScreen() and not ThePlayer:HasTag("playerghost") then
        if ThePlayer:HasTag("aab_time_stop_cd") then
            if ThePlayer.components.talker then
                ThePlayer.components.talker:Say(STRINGS_SKILL_CD)
            end
        else
            SendModRPCToServer(MOD_RPC[modname]["TimeStop"])

            --客机时停，懒得做同步了
            -- ClientStartPause(ThePlayer)
            -- ThePlayer:DoTaskInTime(TIME_STOP_TIME, ClientStopPause)
            CLIENT_TriggerFX(ThePlayer)
        end
    end
end)


----------------------------------------------------------------------------------------------------
-- 把组件更新停掉
local function OnUpdateBefore(self)
    return nil, self.inst:HasTag("aab_time_stop")
end

local function AddComponentAfter(retTab, self, name)
    local comp = retTab[1]
    if not comp then return retTab end

    if comp.OnUpdate then
        Utils.FnDecorator(comp, "OnUpdate", OnUpdateBefore)
    end

    return retTab
end

AddGlobalClassPostConstruct("entityscript", "EntityScript", function(self)
    Utils.FnDecorator(self, "AddComponent", nil, AddComponentAfter)
end)

----------------------------------------------------------------------------------------------------
-- 把动画停掉
local ANIMSTATE_ENT_MAP = {}

Utils.FnDecorator(Entity, "AddAnimState", nil, function(retTab, ent)
    local inst = Ents[ent:GetGUID()]
    local anim = retTab[1]
    if anim and inst then
        ANIMSTATE_ENT_MAP[anim] = inst
        inst:ListenForEvent("onremove", function() ANIMSTATE_ENT_MAP[anim] = nil end)
    end
    return retTab
end)

Utils.FnDecorator(AnimState, "PlayAnimation", function(self)
    local inst = ANIMSTATE_ENT_MAP[self]
    return nil, inst and inst:HasTag("aab_time_stop")
end)

----------------------------------------------------------------------------------------------------

-- 控制天气粒子
-- TODO 下雨、下雪的粒子特效

----------------------------------------------------------------------------------------------------
-- 时停期间不允许单位死亡

local function UpdateHealth(inst, ...)
    local self = inst.components.health
    if not self then return end

    self._aab_time_stop_updatetask = nil
    inst.components.health:SetVal(...)
end

local function SetValBefore(self, val, ...)
    if self.inst:HasTag("aab_time_stop") and self.inst._aab_time_stop_start then
        local max_health = self:GetMaxWithPenalty()
        local min_health = math.min(self.minhealth or 0, max_health)
        if val <= min_health then
            self.currenthealth = math.clamp(val, min_health + 0.01, max_health) --必须保证剩一点血

            if self._aab_time_stop_updatetask then
                self._aab_time_stop_updatetask:Cancel()
            end
            local end_time = TIME_STOP_TIME - (GetTime() - self.inst._aab_time_stop_start) + 0.1
            self._aab_time_stop_updatetask = self.inst:DoTaskInTime(end_time, UpdateHealth, val, ...)

            return nil, true
        end
    end
end

AddComponentPostInit("health", function(self)
    Utils.FnDecorator(self, "SetVal", SetValBefore)
end)


----------------------------------------------------------------------------------------------------

-- debug
GLOBAL.c_start_time_pause = StartPause
GLOBAL.c_stop_time_pause = StopPause
