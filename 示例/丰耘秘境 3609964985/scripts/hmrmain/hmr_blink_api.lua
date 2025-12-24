---------------------------------------------------------------------------------------
---[[声明]]
---------------------------------------------------------------------------------------
--[[
    作者：晴浅
    日期：2025/6/21
    版本：1.0
    权限：搬运请注明出处

    使用方法：为需要跃迁的角色添加hmrblinker组件
]]

---------------------------------------------------------------------------------------
---[[跃迁动作]]
---------------------------------------------------------------------------------------
local HIGH_ACTION_PRIORITY = 10

-- 跃迁
local function TryToBlink(act, act_pos)
    return act.doer ~= nil
        and act.doer.sg ~= nil
        and act.doer.sg.currentstate.name == "hmr_blinkin_pre"
        and act_pos ~= nil
end
local HMR_BLINK = Action({ priority=HIGH_ACTION_PRIORITY, rmb=true, distance=50, mount_valid=true })
HMR_BLINK.id = "HMR_BLINK"
HMR_BLINK.str = "跃迁"
HMR_BLINK.fn = function(act)
	local act_pos = act:GetActionPoint()
    if TryToBlink(act, act_pos) then
        act.doer.sg:GoToState("hmr_blinkin", {dest = act_pos,})
        return true
    end
end
AddAction(HMR_BLINK)
AddStategraphActionHandler("wilson", ActionHandler(HMR_BLINK, function(inst, action)
    return "hmr_blinkin_pre"
end))
AddStategraphActionHandler("wilson_client", ActionHandler(HMR_BLINK, function(inst, action)
    return "hmr_blinkin_pre"
end))

-- 地图跃迁
local function ArriveAnywhere()
    return true
end
local HMR_BLINK_MAP = Action({ priority=HIGH_ACTION_PRIORITY, customarrivecheck=ArriveAnywhere, rmb=true, mount_valid=true, map_action=true, })
HMR_BLINK_MAP.id = "HMR_BLINK_MAP"
HMR_BLINK_MAP.str = "跃迁"
HMR_BLINK_MAP.fn = function(act)
	local act_pos = act:GetActionPoint()
    if TryToBlink(act, act_pos, true) then
        act.doer.sg:GoToState("hmr_blinkin", {dest = act_pos, from_map = true,})
        return true
    end
end
AddAction(HMR_BLINK_MAP)
AddStategraphActionHandler("wilson", ActionHandler(HMR_BLINK_MAP, function(inst, action)
    return "hmr_blinkin_pre"
end))
AddStategraphActionHandler("wilson_client", ActionHandler(HMR_BLINK_MAP, function(inst, action)
    return "hmr_blinkin_pre"
end))

-- 地图跃迁（目标辅助）
local BLINK_MAP_MUST = { "CLASSIFIED", "globalmapicon", "fogrevealer" }
local function BlinkRemap(act, targetpos)
    -- 获取执行动作的角色
    local doer = act.doer
    -- 如果执行角色为空，则直接返回nil，表示无法执行该动作
    if doer == nil then
        return nil
    end

    -- 初始化变量，aimassisted用于标识是否进行了目标辅助，distoverride用于存储重置后的距离
    local aimassisted = false
    local distoverride = nil

    -- 检查目标位置是否在地面上
    if not TheWorld.Map:IsAboveGroundAtPoint(targetpos.x, targetpos.y, targetpos.z) then
        -- 如果目标位置不在地面上，尝试寻找一个地图标志物（例如船只周围的雾揭示器）
        -- 先查找PLAYER_REVEAL_RADIUS * 0.4范围内的标志物
        local ents = TheSim:FindEntities(targetpos.x, targetpos.y, targetpos.z, PLAYER_REVEAL_RADIUS * 0.4, BLINK_MAP_MUST)
        local revealer = nil
        -- 定义一个可行走平台的最大直径平方，用于后续判断
        local MAX_WALKABLE_PLATFORM_DIAMETERSQ = TUNING.MAX_WALKABLE_PLATFORM_RADIUS * TUNING.MAX_WALKABLE_PLATFORM_RADIUS * 4 -- 直径的平方

        -- 遍历找到的实体，寻找合适的地图揭示器
        for _, v in ipairs(ents) do
            -- 忽略距离过近的实体，因为它们可能被误判为船只或其他可行走平台
            if doer:GetDistanceSqToInst(v) > MAX_WALKABLE_PLATFORM_DIAMETERSQ then
                revealer = v
                break
            end
        end

        -- 如果没有找到合适的地图揭示器，则返回nil，表示无法执行该动作
        if revealer == nil then
            return nil
        end

        -- 如果找到了地图揭示器，则重置目标位置为目标揭示器的位置
        targetpos.x, targetpos.y, targetpos.z = revealer.Transform:GetWorldPosition()
        -- 计算目标位置与角色当前位置之间的距离，作为distoverride
        distoverride = act.pos ~= nil and act.pos:GetPosition():Dist(targetpos) or 0

        -- 如果地图揭示器有目标（例如船只），则进一步调整目标位置
        if revealer._target ~= nil then
            -- 这段代码仅在服务器端执行，用于获取船只的目标平台
            local boat = revealer._target:GetCurrentPlatform()
            -- 如果目标平台为空，则返回nil，避免角色传送到水上
            if boat == nil then
                return nil
            end
            -- 重置目标位置为目标平台的位置
            targetpos.x, targetpos.y, targetpos.z = boat.Transform:GetWorldPosition()
        end

        -- 标记该动作使用了目标辅助
        aimassisted = true
    end

    -- 计算最终的距离，如果distoverride不为空，则使用它，否则使用默认的距离计算方法
    local dist = distoverride or act.pos ~= nil and act.pos:GetPosition():Dist(targetpos) or 0

    -- 创建一个新的BufferedAction对象，该对象用于存储动作的详细信息
    local act_remap = BufferedAction(doer, nil, ACTIONS.HMR_BLINK_MAP, act.invobject, targetpos)

    -- 计算距离修正值，基于角色的“自由跳跃计数器”以及TUNING.WORTOX_FREEHOP_HOPSPERSOUL来调整跳跃距离
    local dist_mod = ((doer._freesoulhop_counter or 0) * (TUNING.WORTOX_FREEHOP_HOPSPERSOUL - 1)) * (act.distance or 0)

    -- 计算每个跳跃的距离，基于TUNING.WORTOX_FREEHOP_HOPSPERSOUL和TUNING.WORTOX_MAPHOP_DISTANCE_SCALER
    local dist_perhop = ((act.distance or 0) * TUNING.WORTOX_FREEHOP_HOPSPERSOUL * TUNING.WORTOX_MAPHOP_DISTANCE_SCALER)

    -- 计算需要消耗的魂的数量，基于总距离和每个跳跃的距离
    local dist_souls = (dist + dist_mod) / dist_perhop

    -- 设置BufferedAction对象的属性
    act_remap.maxsouls = TUNING.WORTOX_MAX_SOULS -- 最大魂的数量
    act_remap.distancemod = dist_mod -- 距离修正值
    act_remap.distanceperhop = dist_perhop -- 每个跳跃的距离
    act_remap.distancefloat = dist_souls -- 需要消耗的魂的数量（浮点数）
    act_remap.distancecount = math.clamp(math.ceil(dist_souls), 1, act_remap.maxsouls) -- 需要消耗的魂的数量（整数），并确保其在合理范围内
    act_remap.aimassisted = aimassisted -- 是否使用了目标辅助

    -- 返回重映射后的动作对象
    return act_remap
end
AddComponentPostInit("playercontroller", function(PlayerController)
    local oldRemapMapAction = PlayerController.RemapMapAction
    function PlayerController:RemapMapAction(act, position)
        if act.action.code == HMR_BLINK.code then
            local px, py, pz = position:Get()
            if self.inst:CanSeePointOnMiniMap(px, py, pz) then
                return BlinkRemap(act, Vector3(px, py, pz))
            end
        else
            return oldRemapMapAction(self, act, position)
        end
    end
end)

-- AddClassPostConstruct("components/playeractionpicker", function(self)
--     local oldGetRightClickActions = self.GetRightClickActions
--     function self:GetRightClickActions(position, target, spellbook)
--         if self.inst:HasTag("sakura_blinkable") then
--             local useitem = self.inst.replica.inventory:GetActiveItem()
--             return self:GetPointSpecialActions(position, useitem, true)
--         end

--         return oldGetRightClickActions(self, position, target, spellbook)
--     end
-- end)

---------------------------------------------------------------------------------------
---[[状态图]]
---------------------------------------------------------------------------------------
local function DoBlinkTint(inst, val)
    if not inst.components.hmrblinker:IsTintEnabled() then
        return
    end
    if val > 0 then
        local color = inst.components.hmrblinker:GetTintColor()
        inst.components.colouradder:PushColour("portaltint", color[1] * val, color[2] * val, color[3] * val, 0)
        val = 1 - val
        inst.AnimState:SetMultColour(val, val, val, 1)
    else
        inst.components.colouradder:PopColour("portaltint")
        inst.AnimState:SetMultColour(1, 1, 1, 1)
    end
end

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

AddStategraphState("wilson", State{
    name = "hmr_blinkin_pre",
    tags = { "busy", "nointerrupt" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        if inst.replica.rider == nil or not inst.replica.rider:IsRiding() then
            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")
        else
            inst.AnimState:PlayAnimation("boat_jump_pre")
        end

        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil and buffaction.pos ~= nil then
            inst:ForceFacePoint(buffaction:GetActionPoint():Get())
        end
    end,

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() and not inst:PerformBufferedAction() then
                inst.sg:GoToState("idle")
            end
        end),
    },
})

AddStategraphState("wilson", State{
    name = "hmr_blinkin",
    tags = { "busy", "pausepredict", "nodangle", "nomorph", "nointerrupt" },

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        if inst.replica.rider == nil or not inst.replica.rider:IsRiding() then
            inst.AnimState:PlayAnimation("wortox_portal_jumpin")
        else
            inst.AnimState:PlayAnimation("boat_jump_loop")
        end

        local x, y, z = inst.Transform:GetWorldPosition()
        if inst.components.hmrblinker ~= nil then
            inst.components.hmrblinker:BlinkIn()
        end
        -- SpawnPrefab("wortox_portal_jumpin_fx").Transform:SetPosition(x, y, z)
        inst.sg:SetTimeout(11 * FRAMES)
        inst.sg.statemem.from_map = data and data.from_map or nil
        local dest = data and data.dest or nil
        if dest ~= nil then
            inst.sg.statemem.dest = dest
            inst:ForceFacePoint(dest:Get())
        else
            inst.sg.statemem.dest = Vector3(x, y, z)
        end

        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:RemotePausePrediction()
        end
    end,

    onupdate = function(inst)
        if inst.sg.statemem.tints ~= nil then
            DoBlinkTint(inst, table.remove(inst.sg.statemem.tints))
            if #inst.sg.statemem.tints <= 0 then
                inst.sg.statemem.tints = nil
            end
        end
    end,

    timeline =
    {
        TimeEvent(FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/infection_post", nil, .7)
            inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
        end),
        TimeEvent(2 * FRAMES, function(inst)
            inst.sg.statemem.tints = { 1, .6, .3, .1 }
            PlayFootstep(inst)
        end),
        TimeEvent(4 * FRAMES, function(inst)
            inst.sg:AddStateTag("noattack")
            inst.components.health:SetInvincible(true)
            inst.DynamicShadow:Enable(false)
        end),
    },

    ontimeout = function(inst)
        inst.sg.statemem.portaljumping = true
        inst.sg:GoToState("hmr_blinkout", {dest = inst.sg.statemem.dest, from_map = inst.sg.statemem.from_map})
    end,

    onexit = function(inst)
        if not inst.sg.statemem.portaljumping then
            inst.components.health:SetInvincible(false)
            inst.DynamicShadow:Enable(true)
            DoBlinkTint(inst, 0)
        end
    end,
})

AddStategraphState("wilson", State{
    name = "hmr_blinkout",
    tags = { "busy", "nopredict", "nomorph", "noattack", "nointerrupt" },

    onenter = function(inst, data)
        ToggleOffPhysics(inst)
        inst.components.locomotor:Stop()
        if inst.replica.rider == nil or not inst.replica.rider:IsRiding() then
            inst.AnimState:PlayAnimation("wortox_portal_jumpout")
        else
            inst.AnimState:PlayAnimation("boat_jump_pst")
        end

        inst:ResetMinimapOffset()
        if data and data.from_map then
            inst:SnapCamera()
        end
        local dest = data and data.dest or nil
        if dest ~= nil then
            inst.Physics:Teleport(dest:Get())
        else
            dest = inst:GetPosition()
        end
        if inst.components.hmrblinker ~= nil then
            inst.components.hmrblinker:BlinkOut()
        end
        -- SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(dest:Get())
        inst.DynamicShadow:Enable(false)
        inst.sg:SetTimeout(14 * FRAMES)
        DoBlinkTint(inst, 1)
        inst.components.health:SetInvincible(true)
        inst:PushEvent("soulhop")
    end,

    onupdate = function(inst)
        if inst.sg.statemem.tints ~= nil then
            DoBlinkTint(inst, table.remove(inst.sg.statemem.tints))
            if #inst.sg.statemem.tints <= 0 then
                inst.sg.statemem.tints = nil
            end
        end
    end,

    timeline =
    {
        TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out") end),
        TimeEvent(5 * FRAMES, function(inst)
            inst.sg.statemem.tints = { 0, .4, .7, .9 }
        end),
        TimeEvent(7 * FRAMES, function(inst)
            inst.components.health:SetInvincible(false)
            inst.sg:RemoveStateTag("noattack")
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
        TimeEvent(8 * FRAMES, function(inst)
            inst.DynamicShadow:Enable(true)
            ToggleOnPhysics(inst)
        end),
    },

    ontimeout = function(inst)
        inst.sg:GoToState("idle", true)
    end,

    onexit = function(inst)
        inst.components.health:SetInvincible(false)
        inst.DynamicShadow:Enable(true)
        DoBlinkTint(inst, 0)
        if inst.sg.statemem.isphysicstoggle then
            ToggleOnPhysics(inst)
        end
    end,
})

-- 客户端
local TIMEOUT = 2
AddStategraphState("wilson_client", State{
    name = "hmr_blinkin_pre",
    tags = { "busy" },
    server_states = { "hmr_blinkin_pre", "hmr_blinkin" },

    onenter = function(inst)
        inst.components.locomotor:Stop()

        if inst.replica.rider == nil or not inst.replica.rider:IsRiding() then
            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")
            inst.AnimState:PushAnimation("wortox_portal_jumpin_lag", false)
        else
            inst.AnimState:PlayAnimation("boat_jump_pre")
            inst.AnimState:PushAnimation("boat_jump_loop", false)
        end

        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()

            if buffaction.pos ~= nil then
                inst:ForceFacePoint(buffaction:GetActionPoint():Get())
            end
        end

        inst.sg:SetTimeout(TIMEOUT)
    end,

    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,

    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end,
})
