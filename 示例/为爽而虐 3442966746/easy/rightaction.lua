--[[
    右键动作系统 - 为玩家添加各种特殊右键动作能力
    包括：冲刺(Dodge)、盈能(Rotate)、未来行走/倒走(Warp)、暗影冲刺(Lunge)等
]]--

-- ================================
-- 配置变量获取
-- ================================

-- 控制键相关配置
local ctrldisable = GetModConfigData("ctrl disable right")       -- Ctrl键禁用右键功能
local ctrlwrapback = GetModConfigData("right Wrapback need ctrl") -- 倒走需要Ctrl键
local ctrlLunge = GetModConfigData("right Lunge need ctrl")       -- 暗袭需要Ctrl键

-- 保留的配置项（未启用）
-- local ctrloverrideequip = GetModConfigData("ctrl disable item") or true
-- local handlekeys = GetModConfigData("right action key")

-- ================================
-- 通用工具函数
-- ================================

-- 取消无敌状态的任务
local function cancelmiss(inst)
    inst.cancelmisstask2hm = nil
    if inst.allmiss2hm then 
        inst.allmiss2hm = nil 
    end
end

-- 清除客户端状态缓存
local function ClearCachedServerState(inst) 
    if inst.player_classified ~= nil then 
        inst.player_classified.currentstate:set_local(0) 
    end 
end

-- 检查是否装备AOE目标物品
local function equipaoetargeting(inst)
    local item = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return item ~= nil and item.components.aoetargeting ~= nil
    -- and not (ctrloverrideequip and inst.components.playercontroller and inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK))
end


-- ================================
-- 冲刺（Dodge）系统
-- ================================

--[[
    冲刺冷却机制说明：
    
    1. 基础冷却：
       - 通用冲刺冷却：2秒
    
    2. 二段冲刺：
       - 当上次冲刺时间 > 冷却时间/2 时，获得"doubledodge2hm"标签
       - 拥有此标签时可以无视冷却时间立即冲刺
    
    3. 角色特殊处理：
       - 不同角色可通过配置设定不同的冷却时间
       - 骑牛时的特殊效果由角色配置决定
]]--

-- 添加冲刺动作
AddAction("DODGE_WALTER", "Dodge", function(act, data)
    if act.pos or act.target then
        local doer = act.doer
        act.doer.sg:GoToState("dodge2hm", {pos = act.pos or act.target})
        return true
    end
end)

-- 冲刺动作配置
ACTIONS.DODGE_WALTER.distance = math.huge
ACTIONS.DODGE_WALTER.instant = true
ACTIONS.DODGE_WALTER.mount_valid = true
STRINGS.ACTIONS.DODGE_WALTER = {GENERIC = TUNING.isCh2hm and "冲刺" or "Dodge"}

-- 服务端冲刺状态图
AddStategraphState("wilson", State {
    name = "dodge2hm",
    tags = {"busy", "evade", "no_stun", "canrotate", "pausepredict", "nopredict", "drowning"},
    
    onenter = function(inst, data)
        -- 停止移动并暂停预测
        inst.components.locomotor:Stop()
        if inst.components.playercontroller ~= nil then 
            inst.components.playercontroller:RemotePausePrediction() 
        end
        
        -- 设置朝向
        if data and data.pos then
            local pos = data.pos:GetPosition()
            inst.tmpangle2hm = inst:GetAngleToPoint(pos.x, 0, pos.z)
            inst:ForceFacePoint(pos.x, 0, pos.z)
        end
        
        -- 禁用地面速度倍增器并设置无敌状态
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)
        inst.allmiss2hm = true
        
        -- 处理双重冲刺标记
        if inst.rightaction2hm_double then
            if GetTime() - inst.last_rightaction2hm_time > inst.rightaction2hm_cooldown / 2 then
                inst:AddTag("doubledodge2hm")
            else
                inst:RemoveTag("doubledodge2hm")
            end
        end
        
        -- 检查是否骑乘状态
        local riding = inst.components.rider and inst.components.rider:IsRiding()
        
        -- 获取牛的体型倍率（默认为1）
        local beefalo_scale = riding and inst.components.rider:GetMount().myscale or 1
        -- 计算受体型影响的冲刺距离倍率（1-2倍体型 → 1-0.25倍距离）
        local scale_multiplier = beefalo_scale > 1 and (1 - (beefalo_scale - 1)) or 1
        
        -- 播放动画
        if riding then
            inst.AnimState:PlayAnimation("slingshot_pre")
            inst.AnimState:PushAnimation("slingshot", false)
        else
            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")
            inst.AnimState:PushAnimation("wortox_portal_jumpin_lag", false)
        end
        
        -- 播放音效
        inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out")
        
        -- 设置冲刺速度
        local speed = inst.rightaction2hm_range or 20
        if riding then 
            speed = speed * 1.2 * scale_multiplier 
        end
        inst.Physics:SetMotorVelOverride(speed, 0, 0)
        
        -- 设置冲刺时长
        local dodgetime = riding and 0.3 or 0.25
        inst.last_rightaction2hm_time = GetTime() + dodgetime
        inst.rightaction2hm:set(inst.rightaction2hm:value() == false and true or false)
        inst.sg:SetTimeout(dodgetime)
    end,
    
    ontimeout = function(inst)
        -- 执行回调函数
        if inst.rightaction2hm_callback then 
            inst.rightaction2hm_callback(inst) 
        end
        
        -- 延迟取消无敌状态
        if not inst.cancelmisstask2hm then 
            inst.cancelmisstask2hm = inst:DoTaskInTime(0.1, cancelmiss) 
        end
        inst.sg:GoToState("idle")
    end,
    
    onexit = function(inst)
        -- 恢复移动设置
        inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        inst.Physics:ClearMotorVelOverride()
        inst.components.locomotor:Stop()
        inst.components.locomotor:SetBufferedAction(nil)
        
        -- 清理临时变量和状态
        if not inst.cancelmisstask2hm then 
            inst.cancelmisstask2hm = inst:DoTaskInTime(0.1, cancelmiss) 
        end
        if inst.tmpangle2hm then 
            inst.tmpangle2hm = nil 
        end
    end
})
-- 客户端冲刺状态图
AddStategraphState("wilson_client", State {
    name = "dodge2hm",
    tags = {"busy", "evade", "no_stun", "canrotate", "pausepredict", "nopredict", "drowning"},
    
    onenter = function(inst, data)
        -- 停止移动并清除状态
        inst.components.locomotor:Stop()
        inst.components.locomotor:Clear()
        inst:ClearBufferedAction()
        inst.entity:FlattenMovementPrediction()
        inst.entity:SetIsPredictingMovement(false)
        ClearCachedServerState(inst)
        
        -- 设置朝向
        if data and data.pos then
            local pos = data.pos:GetPosition()
            inst:ForceFacePoint(pos.x, 0, pos.z)
        end
        
        -- 检查骑乘状态并播放动画
        local riding = inst.replica and inst.replica.rider and inst.replica.rider:IsRiding()
        if riding then
            inst.AnimState:PlayAnimation("slingshot_pre")
            inst.AnimState:PushAnimation("slingshot", false)
        else
            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")
            inst.AnimState:PushAnimation("wortox_portal_jumpin_lag", false)
        end
        
        -- 设置时间和超时
        local dodgetime = riding and 0.3 or 0.25
        inst.last_rightaction2hm_time = GetTime() + dodgetime
        inst.sg:SetTimeout(2)
    end,
    
    onupdate = function(inst)
        -- 检查服务端状态同步
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
    
    onexit = function(inst)
        -- 注释掉的代码：恢复移动预测
        -- inst.entity:SetIsPredictingMovement(true)
    end
})

-- 获取冲刺特殊动作
local function GetPointSpecialActions_DODGE(inst, pos, useitem, right)
    -- 检查是否满足冲刺条件
    if right and not equipaoetargeting(inst) then
        -- 冷却时间检查
        local cooldown_ready = (GetTime() - inst.last_rightaction2hm_time > inst.rightaction2hm_cooldown) or inst:HasTag("doubledodge2hm")
        
        -- 二段冲刺检查
        local double_ready = inst.rightaction2hm_double and 
                            (GetTime() - inst.last_rightaction2hm_time > inst.rightaction2hm_cooldown / 2)
        
        if cooldown_ready and 
           (inst.rightaction2hm_both or 
            (inst.rightaction2hm_beefalo and inst.replica.rider and inst.replica.rider:IsRiding()) or
            (not inst.rightaction2hm_beefalo and not (inst.replica.rider and inst.replica.rider:IsRiding()))) then 
            return {ACTIONS.DODGE_WALTER} 
        end
    end
    return {}
end

-- 冲刺能力所有者设置
local function OnSetOwner_DODGE(inst)
    if inst.components.playeractionpicker ~= nil then
        -- 设置右键动作函数
        inst.components.playeractionpicker.rightaction2hm = GetPointSpecialActions_DODGE
        
        -- 处理点击特殊动作函数
        if not inst.components.playeractionpicker.pointspecialactionsfn then
            inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions_DODGE
        else
            local old = inst.components.playeractionpicker.pointspecialactionsfn
            inst.components.playeractionpicker.pointspecialactionsfn = function(...)
                if ctrldisable then
                    return (inst.rightaction2hm_beefalo or
                           (inst.components.playercontroller and inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK))) and 
                           old(...) or GetPointSpecialActions_DODGE(...)
                end
                local actions = GetPointSpecialActions_DODGE(...)
                return #actions > 0 and actions or old(...)
            end
        end
        
        -- 特殊处理Walter角色的右键覆盖
        if inst.prefab == "walter" and TUNING.DSTU and inst.components.playeractionpicker.rightclickoverride and not inst.rightaction2hm_beefalo then
            local old = inst.components.playeractionpicker.rightclickoverride
            inst.components.playeractionpicker.rightclickoverride = function(...)
                local actions, usedefault = old(...)
                if ctrldisable and actions and #actions == 1 and actions[1] and actions[1].action and 
                   ACTIONS.WOBY_COMMAND and actions[1].action == ACTIONS.WOBY_COMMAND and 
                   not (inst.components.playercontroller and inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK)) then
                    return {}, true
                end
                return actions, usedefault
            end
        end
        
        -- 特殊处理Woodie角色
        if inst.prefab == "woodie" and GetModConfigData("All Right Dodge") then
            inst.woodiepointspecialactionsfn2hm = inst.components.playeractionpicker.pointspecialactionsfn
        end
    end
end

-- 延迟设置所有者
local function delayOnSetOwner_DODGE(inst) 
    inst:DoTaskInTime(0, OnSetOwner_DODGE) 
end

-- 添加冲刺能力到实例
function AddDodgeAbility(inst)
    inst.rightaction2hm = net_bool(inst.GUID, "player.rightaction2hm", "rightaction2hmdirty")
    inst:ListenForEvent("rightaction2hmdirty", function() 
        inst.last_rightaction2hm_time = GetTime() + 0.25 
    end)
    inst:ListenForEvent("setowner", delayOnSetOwner_DODGE)
    
    -- 冲刺冷却时间设置
    inst.rightaction2hm_cooldown = 2                                          -- 基础冲刺冷却时间（徒步和骑牛通用）
    inst.last_rightaction2hm_time = GetTime() - inst.rightaction2hm_cooldown
end

-- ================================
-- 盈能（Rotate）系统
-- ================================

-- 添加盈能动作
AddAction("ROTATE_WINONA2HM", "Rotate", function(act, data)
    act.doer.sg:GoToState("rotate_weapon2hm")
    return true
end)

-- 盈能动作配置
ACTIONS.ROTATE_WINONA2HM.distance = math.huge
ACTIONS.ROTATE_WINONA2HM.instant = true
ACTIONS.ROTATE_WINONA2HM.do_not_locomote = true
STRINGS.ACTIONS.ROTATE_WINONA2HM = {GENERIC = TUNING.isCh2hm and "盈能" or "Rotate"}

-- 盈能相关辅助函数
local function addrotatetag(inst) 
    inst:AddTag("rotate_weapon2hm") 
end

local function endrotatebuff(inst)
    if inst:HasTag("rotate_weapon2hm") then 
        inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "rotate_weapon2hm") 
    end
end

local function speedupfx(inst)
    if inst.sg and (inst.sg:HasStateTag("moving") or inst.sg:HasStateTag("runing")) then
        SpawnPrefab("ground_chunks_breaking").Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end

local function endrotatespeeduptask(inst)
    inst.rotatespeedup2hmtask = nil
    inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "rotatespeedup2hm")
    
    if inst.rotatespeedupfx2hmtask then
        inst.rotatespeedupfx2hmtask:Cancel()
        inst.rotatespeedupfx2hmtask = nil
    end
    
    inst.components.hunger.burnratemodifiers:RemoveModifier(inst, "rotate_weapon2hm")
end

-- 盈能武器状态图
local state_rotate_weapon2hm = State {
    name = "rotate_weapon2hm",
    tags = {"attack", "busy", "drowning"},
    
    onenter = function(inst)
        inst.allmiss2hm = true
        inst.AnimState:PlayAnimation("lunge_pre")
        inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tornado", "rotatespeedup2hm")
    end,
    
    events = {
        EventHandler("animover", function(inst)
            if TheWorld.ismastersim then
                -- 冷却2秒
                inst:RemoveTag("rotate_weapon2hm")
                inst:DoTaskInTime(2, addrotatetag)
                
                -- 获得持续2.5秒的伤害BUFF
                inst.components.combat.externaldamagemultipliers:SetModifier(inst, 1.25, "rotate_weapon2hm")
                inst:DoTaskInTime(2.5, endrotatebuff)
                
                -- 获得持续5秒的33%加速
                if not inst.rotatespeedup2hmtask then
                    inst.rotatespeedup2hmtask = inst:DoTaskInTime(5, endrotatespeeduptask)
                    inst.components.locomotor:SetExternalSpeedMultiplier(inst, "rotatespeedup2hm", 1.25)
                    inst.components.hunger.burnratemodifiers:SetModifier(inst, 1.75, "rotate_weapon2hm")
                    inst.rotatespeedupfx2hmtask = inst:DoPeriodicTask(0.25, speedupfx)
                elseif inst.rotatespeedup2hmtask then
                    inst.rotatespeedup2hmtask:Cancel()
                    inst.rotatespeedup2hmtask = inst:DoTaskInTime(5, endrotatespeeduptask)
                end
            end
            
            -- 取消无敌状态并返回空闲
            if not inst.cancelmisstask2hm then 
                inst.cancelmisstask2hm = inst:DoTaskInTime(0.1, cancelmiss) 
            end
            inst.sg:GoToState("idle")
        end)
    },
    
    onexit = function(inst)
        if not inst.cancelmisstask2hm then 
            inst.cancelmisstask2hm = inst:DoTaskInTime(0.1, cancelmiss) 
        end
        inst.SoundEmitter:KillSound("rotatespeedup2hm")
    end
}

-- 添加状态图到服务端和客户端
AddStategraphState("wilson", state_rotate_weapon2hm)
AddStategraphState("wilson_client", state_rotate_weapon2hm)

-- 获取盈能特殊动作
local function GetPointSpecialActions_Rotate(inst, pos, useitem, right)
    if right and not equipaoetargeting(inst) and inst:HasTag("rotate_weapon2hm") then
        local inventory = inst.replica.inventory
        local tool = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
        local rider = inst.replica.rider
        
        -- 需要装备武器且不在骑乘状态
        if tool ~= nil and not (rider and rider:IsRiding()) then 
            return {ACTIONS.ROTATE_WINONA2HM} 
        end
    end
    return {}
end

-- 盈能能力所有者设置
local function OnSetOwner_Rotate(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.rightaction2hm = GetPointSpecialActions_Rotate
        
        if not inst.components.playeractionpicker.pointspecialactionsfn then
            inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions_Rotate
        else
            local old = inst.components.playeractionpicker.pointspecialactionsfn
            inst.components.playeractionpicker.pointspecialactionsfn = function(...)
                if ctrldisable and inst.components.playercontroller and 
                   inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK) then
                    local oldactions = old(...)
                    return #oldactions > 0 and oldactions or GetPointSpecialActions_Rotate(...)
                end
                local actions = GetPointSpecialActions_Rotate(...)
                return #actions > 0 and actions or old(...)
            end
        end
    end
end

-- 延迟设置盈能所有者
local function delayOnSetOwner_Rotate(inst) 
    inst:DoTaskInTime(0, OnSetOwner_Rotate) 
end

-- 添加盈能能力到实例
function AddRotateAbility(inst)
    inst.rightaction2hm = net_bool(inst.GUID, "player.rightaction2hm", "rightaction2hmdirty")
    inst:AddTag("rotate_weapon2hm")
    inst:ListenForEvent("setowner", delayOnSetOwner_Rotate)
end

-- ================================
-- 时间穿越系统 - 未来行走（WarpFront）
-- ================================

-- 添加未来行走动作
AddAction("WARPFRONT_WANDA", "Wrapfront", function(act, data)
    act.doer.last_rightaction2hm_time = GetTime()
    act.doer.rightaction2hm:set(act.doer.rightaction2hm:value() == false and true or false)
    act.doer.sg:GoToState(TheNet:GetIsClient() and "pocketwatch_warpfront_pre" or "warpfront_pre2hm")
    return true
end)

-- 未来行走动作配置
ACTIONS.WARPFRONT_WANDA.instant = true
STRINGS.ACTIONS.WARPFRONT_WANDA = {GENERIC = TUNING.isCh2hm and "未来行走" or "Warpfront"}

-- 未来行走预备状态图
local state_warpfront_pre2hm = State {
    name = "warpfront_pre2hm",
    tags = {"busy"},
    
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("pocketwatch_warp_pre")
        
        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst.AnimState:OverrideSymbol("watchprop", "pocketwatch_warp", "watchprop")
            inst.sg.statemem.castfxcolour = nil
        end
    end,
    
    timeline = {
        TimeEvent(1 * FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/warp") 
        end)
    },
    
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                local self = inst.components.positionalwarp
                if not self then
                    inst.sg:GoToState("idle")
                    return
                end
                
                -- 记录当前位置
                inst.sg.statemem.portaljumping = true
                local x, y, z = inst.Transform:GetWorldPosition()
                local history_rollback_dist = self.history_rollback_dist
                local maxdist = 0
                local cur = self.history_cur
                
                -- 计算历史位置数量
                for i = 1, history_rollback_dist do
                    if cur == self.history_back then break end
                    maxdist = maxdist + 1
                    cur = (cur - 1) % self.history_max
                end
                
                -- 寻找合适的传送位置
                if maxdist > 0 then
                    for i = history_rollback_dist, 1, -1 do
                        self.history_rollback_dist = i
                        local tx, ty, tz = self:GetHistoryPosition(false)
                        if tx == nil then break end
                        
                        -- 计算未来位置
                        local dest_x = x + (x - tx) * (i > maxdist and i / maxdist or 1)
                        local dest_y = y + (y - ty) * (i > maxdist and i / maxdist or 1)
                        local dest_z = z + (z - tz) * (i > maxdist and i / maxdist or 1)
                        
                        -- 检查位置是否可通过
                        if TheWorld.Map:IsPassableAtPoint(dest_x, dest_y, dest_z) then
                            inst.sg.statemem.warpback = {
                                dest_x = dest_x,
                                dest_y = dest_y,
                                dest_z = dest_z,
                                frontdata2hm = {x = x, y = y, z = z, dist = i, maxdist = maxdist}
                            }
                            self.history_rollback_dist = history_rollback_dist
                            inst.sg:GoToState("pocketwatch_warpback", inst.sg.statemem)
                            return
                        end
                    end
                end
                
                -- 没有找到合适位置，传送到原地
                self.history_rollback_dist = history_rollback_dist
                inst.sg.statemem.warpback = {dest_x = x, dest_y = y, dest_z = z}
                inst.sg:GoToState("pocketwatch_warpback", inst.sg.statemem)
            end
        end)
    },
    
    onexit = function(inst) 
        if not inst.sg.statemem.portaljumping then 
            inst.AnimState:ClearOverrideSymbol("watchprop") 
        end 
    end
}

AddStategraphState("wilson", state_warpfront_pre2hm)

-- 修改传送回归状态图以支持未来数据
AddStategraphPostInit("wilson", function(sg)
    local onenter = sg.states.pocketwatch_warpback_pst.onenter
    sg.states.pocketwatch_warpback_pst.onenter = function(inst, data, ...)
        if data and data.warpback_data and data.warpback_data.frontdata2hm then 
            inst.sg.statemem.frontdata2hm = data.warpback_data.frontdata2hm 
        end
        onenter(inst, data, ...)
        if inst.sg.statemem.frontdata2hm then 
            inst.sg.statemem.frontdata2hm = nil 
        end
    end
end)

-- 获取未来行走特殊动作
local function GetPointSpecialActions_WARPFRONT(inst, pos, useitem, right)
    if right and not equipaoetargeting(inst) and 
       GetTime() - inst.last_rightaction2hm_time > inst.rightaction2hm_cooldown and 
       not inst:GetCurrentPlatform() and
       not (inst.replica.rider and inst.replica.rider:IsRiding()) then 
        return {ACTIONS.WARPFRONT_WANDA} 
    end
    return {}
end

-- 未来行走能力所有者设置
local function OnSetOwner_WARPFRONT(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.rightaction2hm = GetPointSpecialActions_WARPFRONT
        
        if not inst.components.playeractionpicker.pointspecialactionsfn then
            inst.components.playeractionpicker.pointspecialactionsfn = ctrlwrapback and function(...)
                return inst.components.playercontroller and 
                       inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK) and
                       GetPointSpecialActions_WARPFRONT(...) or {}
            end or GetPointSpecialActions_WARPFRONT
        else
            local old = inst.components.playeractionpicker.pointspecialactionsfn
            inst.components.playeractionpicker.pointspecialactionsfn = function(...)
                local pressctrl = inst.components.playercontroller and 
                                 inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK)
                
                if ctrlwrapback then 
                    return pressctrl and GetPointSpecialActions_WARPFRONT(...) or old(...) 
                end
                
                if ctrldisable and pressctrl then
                    local oldactions = old(...)
                    return #oldactions > 0 and oldactions or GetPointSpecialActions_WARPFRONT(...)
                end
                
                local actions = GetPointSpecialActions_WARPFRONT(...)
                return #actions > 0 and actions or old(...)
            end
        end
    end
end
-- 穿梭到未来添加新的N个坐标
local function positionalwarpaddfuturepos(self, frontdata2hm)
    if not frontdata2hm then return end
    
    local x = frontdata2hm.x
    local y = frontdata2hm.y
    local z = frontdata2hm.z
    local dist = frontdata2hm.dist
    local maxdist = frontdata2hm.maxdist
    
    if not (x and y and z and dist and maxdist) then return end
    
    -- 保存当前回滚距离设置
    local history_rollback_dist = self.history_rollback_dist
    local history_x = {}
    local history_y = {}
    local history_z = {}
    
    -- 计算未来位置坐标
    for i = 1, dist do
        self.history_rollback_dist = i
        local tx, ty, tz = self:GetHistoryPosition(false)
        if tx == nil then break end
        history_x[i] = x + (x - tx) * (i > maxdist and i / maxdist or 1)
        history_y[i] = y + (y - ty) * (i > maxdist and i / maxdist or 1)
        history_z[i] = z + (z - tz) * (i > maxdist and i / maxdist or 1)
    end
    
    -- 添加未来位置到历史记录
    for i = 1, dist do
        if history_x[i] == nil then break end
        self.history_cur = (self.history_cur + 1) % self.history_max
        if self.history_cur == self.history_back then 
            self.history_back = (self.history_back + 1) % self.history_max 
        end
        self.history_x[self.history_cur + 1] = history_x[i]
        self.history_y[self.history_cur + 1] = history_y[i]
        self.history_z[self.history_cur + 1] = history_z[i]
    end
    
    -- 恢复设置并更新标记
    self.history_rollback_dist = history_rollback_dist
    self:UpdateMarker()
end

-- 传送回归事件处理
local function OnWarpBack(inst, data)
    if inst.components.positionalwarp ~= nil then
        if data ~= nil and data.reset_warp then
            inst.components.positionalwarp:Reset()
        else
            inst.components.positionalwarp:GetHistoryPosition(true)
        end
    end
end

-- 添加未来行走能力到实例
function AddWrapFrontAbility(inst)
    inst.rightaction2hm = net_bool(inst.GUID, "player.rightaction2hm", "rightaction2hmdirty")
    inst:ListenForEvent("rightaction2hmdirty", function() 
        inst.last_rightaction2hm_time = GetTime() 
    end)
    inst:ListenForEvent("setowner", OnSetOwner_WARPFRONT)
    
    -- 设置冷却时间
    inst.rightaction2hm_cooldown = 2
    inst.last_rightaction2hm_time = GetTime() - inst.rightaction2hm_cooldown
    
    -- 服务端特殊处理
    if not TheWorld.ismastersim then return end
    
    -- 获取或创建位置传送组件
    local self = inst.components.positionalwarp
    if not self then
        self = inst:AddComponent("positionalwarp")
        inst:DoTaskInTime(0, function() 
            self:SetMarker("pocketwatch_warp_marker") 
        end)
        self:SetWarpBackDist(TUNING.WANDA_WARP_DIST_OLD)
        inst:ListenForEvent("onwarpback", OnWarpBack)
    end
    
    -- 覆盖标记启用函数，始终启用标记
    local oldEnableMarker = self.EnableMarker
    self.EnableMarker = function(self, enable) 
        oldEnableMarker(self, true) 
    end
    self:EnableMarker(true)
    
    -- 覆盖历史位置获取函数以支持未来位置添加
    local GetHistoryPosition = self.GetHistoryPosition
    self.GetHistoryPosition = function(self, rewind, ...)
        if rewind and self.inst.sg and self.inst.sg.statemem and self.inst.sg.statemem.frontdata2hm then
            positionalwarpaddfuturepos(self, self.inst.sg.statemem.frontdata2hm)
            return
        end
        return GetHistoryPosition(self, rewind, ...)
    end
end


-- ================================
-- 时间穿越系统 - 倒走（WarpBack）
-- ================================

-- 添加倒走动作
AddAction("WARPBACK_WANDA", "Wrapback", function(act, data)
    act.doer.last_rightaction2hm_time = GetTime()
    act.doer.rightaction2hm:set(act.doer.rightaction2hm:value() == false and true or false)
    act.doer.sg:GoToState(TheNet:GetIsClient() and "pocketwatch_warpback_pre" or "warpback_pre2hm")
    return true
end)

-- 倒走动作配置
ACTIONS.WARPBACK_WANDA.instant = true
STRINGS.ACTIONS.WARPBACK_WANDA = {GENERIC = TUNING.isCh2hm and "倒走" or "Warpback"}

-- 倒走预备状态图
local state_warpback_pre2hm = State {
    name = "warpback_pre2hm",
    tags = {"busy"},
    
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("pocketwatch_warp_pre")
        
        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst.AnimState:OverrideSymbol("watchprop", "pocketwatch_warp", "watchprop")
            inst.sg.statemem.castfxcolour = nil
        end
    end,
    
    timeline = {
        TimeEvent(1 * FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/warp") 
        end)
    },
    
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                -- 获取历史位置
                local tx, ty, tz = inst.components.positionalwarp:GetHistoryPosition(false)
                if tx ~= nil then
                    inst.sg.statemem.portaljumping = true
                    inst.sg.statemem.warpback = {dest_x = tx, dest_y = ty, dest_z = tz}
                    inst.sg:GoToState("pocketwatch_warpback", inst.sg.statemem)
                else
                    -- 没有可用的历史位置
                    inst.sg:GoToState("idle")
                    inst:DoTaskInTime(15 * FRAMES, function(inst)
                        -- 如果玩家立即开始移动则跳过此提示
                        if inst.sg == nil or inst.sg:HasStateTag("idle") then
                            inst.components.talker:Say(STRINGS.CHARACTERS.WANDA.ACTIONFAIL.CAST_POCKETWATCH.WARP_NO_POINTS_LEFT)
                        end
                    end)
                end
            end
        end)
    },
    
    onexit = function(inst) 
        if not inst.sg.statemem.portaljumping then 
            inst.AnimState:ClearOverrideSymbol("watchprop") 
        end 
    end
}

AddStategraphState("wilson", state_warpback_pre2hm)

-- 获取倒走特殊动作（与未来行走相同的条件检查）
local function GetPointSpecialActions_WARPBACK(inst, pos, useitem, right)
    if right and not equipaoetargeting(inst) and 
       GetTime() - inst.last_rightaction2hm_time > inst.rightaction2hm_cooldown and 
       not inst:GetCurrentPlatform() and
       not (inst.replica.rider and inst.replica.rider:IsRiding()) then 
        return {ACTIONS.WARPBACK_WANDA} 
    end
    return {}
end

-- 倒走能力所有者设置
local function OnSetOwner_WARPBACK(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.rightaction2hm = GetPointSpecialActions_WARPBACK
        
        if not inst.components.playeractionpicker.pointspecialactionsfn then
            inst.components.playeractionpicker.pointspecialactionsfn = ctrlwrapback and function(...)
                return inst.components.playercontroller and 
                       inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK) and
                       GetPointSpecialActions_WARPBACK(...) or {}
            end or GetPointSpecialActions_WARPBACK
        else
            local old = inst.components.playeractionpicker.pointspecialactionsfn
            inst.components.playeractionpicker.pointspecialactionsfn = function(...)
                local pressctrl = inst.components.playercontroller and 
                                 inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK)
                
                if ctrlwrapback then 
                    return pressctrl and GetPointSpecialActions_WARPBACK(...) or old(...) 
                end
                
                if ctrldisable and pressctrl then
                    local oldactions = old(...)
                    return #oldactions > 0 and oldactions or GetPointSpecialActions_WARPBACK(...)
                end
                
                local actions = GetPointSpecialActions_WARPBACK(...)
                return #actions > 0 and actions or old(...)
            end
        end
    end
end

-- 添加倒走能力到实例
function AddWrapAbility(inst)
    inst.rightaction2hm = net_bool(inst.GUID, "player.rightaction2hm", "rightaction2hmdirty")
    inst:ListenForEvent("rightaction2hmdirty", function() 
        inst.last_rightaction2hm_time = GetTime() 
    end)
    inst:ListenForEvent("setowner", OnSetOwner_WARPBACK)
    
    -- 设置冷却时间
    inst.rightaction2hm_cooldown = 2
    inst.last_rightaction2hm_time = GetTime() - inst.rightaction2hm_cooldown
    
    -- 服务端特殊处理
    if not TheWorld.ismastersim then return end
    
    -- 获取或创建位置传送组件
    if not inst.components.positionalwarp then
        inst:AddComponent("positionalwarp")
        inst:DoTaskInTime(0, function() 
            inst.components.positionalwarp:SetMarker("pocketwatch_warp_marker") 
        end)
        inst.components.positionalwarp:SetWarpBackDist(TUNING.WANDA_WARP_DIST_OLD)
        inst:ListenForEvent("onwarpback", OnWarpBack)
    end
    
    -- 覆盖标记启用函数，始终启用标记
    local oldEnableMarker = inst.components.positionalwarp.EnableMarker
    inst.components.positionalwarp.EnableMarker = function(self, enable) 
        oldEnableMarker(self, true) 
    end
    inst.components.positionalwarp:EnableMarker(true)
end

-- ================================
-- 暗影冲刺（Lunge）系统
-- ================================

-- 添加暗影冲刺动作
AddAction("Lunge_WAXWELL2HM", "lunge", function(act, data)
    if TheNet:GetIsClient() then
        act.doer.sg:GoToState("combat_lunge_start")
    else
        act.doer.sg:GoToState("lunge_pre2hm", {
            targetpos = act.pos or (act.target and Vector3(act.target.Transform:GetWorldPosition()))
        })
    end
    return true
end)

ACTIONS.Lunge_WAXWELL2HM.distance = math.huge
ACTIONS.Lunge_WAXWELL2HM.instant = true
STRINGS.ACTIONS.Lunge_WAXWELL2HM = {GENERIC = TUNING.isCh2hm and "暗袭" or "Lunge"}

-- 结束暗影冲刺冷却
local function endlungecd(inst)
    inst.shadowlungecdtask2hm = nil
    if inst.shadowlungeendfn2hm then
        inst:shadowlungeendfn2hm()
    else
        inst:AddTag("shadowlunge2hm")
    end
end

-- 暗影冲刺预备状态图
local state_lunge_pre = State {
    name = "lunge_pre2hm",
    tags = {"attack", "busy", "evade", "no_stun", "pausepredict", "nopredict", "drowning", 
            "busy", "aoe", "doing", "nointerrupt", "nomorph"},
    
    onenter = function(inst, data)
        -- 验证目标位置
        local targetpos = data and data.targetpos and data.targetpos:GetPosition()
        if not targetpos then
            inst.sg:GoToState("idle")
            return
        end
        
        -- 设置面向和移动
        inst.components.locomotor:Stop()
        inst:ForceFacePoint(targetpos)
        
        -- 计算冲刺范围和目标位置
        local radius = math.max((inst.shadowlevel2hm or 4) * 4, 8)
        local firstradius = inst:GetDistanceSqToPoint(targetpos)
        
        -- 根据距离调整目标位置
        if firstradius <= 16 then
            -- 距离太近，向前冲刺
            local theta = inst.Transform:GetRotation() * DEGREES
            local pos = inst:GetPosition()
            for i = 4, radius, 1 do
                local offset = Vector3(i * math.cos(theta), 0, -i * math.sin(theta))
                local targetpos = pos + offset
                if not TheWorld.Map:IsOceanAtPoint(targetpos.x, 0, targetpos.z, false) then
                    inst.sg.statemem.targetpos = targetpos
                    break
                end
            end
        elseif firstradius >= radius * radius then
            -- 距离太远，缩短冲刺距离
            local theta = inst.Transform:GetRotation() * DEGREES
            local pos = inst:GetPosition()
            for i = radius, 4, -1 do
                local offset = Vector3(i * math.cos(theta), 0, -i * math.sin(theta))
                local targetpos = pos + offset
                if not TheWorld.Map:IsOceanAtPoint(targetpos.x, 0, targetpos.z, false) then
                    inst.sg.statemem.targetpos = targetpos
                    break
                end
            end
        else
            -- 距离合适，直接使用目标位置
            inst.sg.statemem.targetpos = targetpos
        end
        
        -- 检查是否找到合适的目标位置
        if not inst.sg.statemem.targetpos then
            inst.sg:GoToState("idle")
            return
        end
        
        -- 设置状态和冷却
        inst.sg.statemem.use = inst:GetDistanceSqToPoint(inst.sg.statemem.targetpos) / (radius * radius)
        inst.allmiss2hm = true
        
        if not inst.cancelmisstask2hm then 
            inst.cancelmisstask2hm = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 0.1, cancelmiss) 
        end
        
        -- 移除标签并设置冷却
        inst:RemoveTag("shadowlunge2hm")
        inst.shadowlungecdtask2hm = inst:DoTaskInTime(8, endlungecd)
        
        -- 播放动画和记录武器
        inst.AnimState:PlayAnimation("lunge_pre")
        inst.sg.statemem.weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    end,
    
    timeline = {
        TimeEvent(4 * FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/common/twirl", nil, nil, true) 
        end)
    },
    
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("lunge_loop2hm", {
                    weapon = inst.sg.statemem.weapon, 
                    use = inst.sg.statemem.use, 
                    targetpos = inst.sg.statemem.targetpos
                })
            end
        end)
    },
    
    onexit = function(inst)
        if inst.cancelmisstask2hm then 
            inst.cancelmisstask2hm:Cancel() 
        end
        inst.cancelmisstask2hm = inst:DoTaskInTime(0.1, cancelmiss)
    end
}
-- 暗影冲刺命中效果
local function onlungehit(inst, doer, target)
    local fx = SpawnPrefab(math.random() < .5 and "shadowstrike_slash_fx" or "shadowstrike_slash2_fx")
    local x, y, z = target.Transform:GetWorldPosition()
    fx.Transform:SetPosition(x, y + 1.5, z)
    fx.Transform:SetRotation(doer.Transform:GetRotation())
end

-- 投掷物品相关标签
local TOSS_MUSTTAGS = {"_inventoryitem"}
local TOSS_CANTTAGS = {"locomotor", "INLIMBO"}

-- AOE武器暗影冲刺执行函数
function AOEWeapon_Lunge_DoLunge(self, doer, startingpos, targetpos)
    if not startingpos or not targetpos or not doer or not doer.components.combat then 
        return false 
    end
    
    if self.onprelungefn ~= nil then 
        self.onprelungefn(self.inst, doer, startingpos, targetpos) 
    end
    
    -- 攻击处理 -----------------------------------------------------------------
    local doer_combat = doer.components.combat
    doer_combat:EnableAreaDamage(false)
    
    -- 临时禁用武器磨损
    local weapon = self.inst.components.weapon
    local attackwear = 0
    if weapon then
        attackwear = weapon.attackwear
        if attackwear ~= 0 then weapon.attackwear = 0 end
    end
    
    -- 计算攻击路径
    local p1 = {x = startingpos.x, y = startingpos.z}
    local p2 = {x = targetpos.x, y = targetpos.z}
    local dx, dy = p2.x - p1.x, p2.y - p1.y
    local dist = dx * dx + dy * dy
    local toskip = {}
    local pv = {}
    local r, cx, cy
    
    -- 沿路径攻击目标
    if dist > 0 then
        dist = math.sqrt(dist)
        r = (dist + doer_combat.hitrange * 0.5 + self.physicspadding) * 0.5 + 0.15
        dx, dy = dx / dist, dy / dist
        cx, cy = p1.x + dx * r, p1.y + dy * r
        doer_combat.ignorehitrange = true
        
        local c_hit_targets = TheSim:FindEntities(cx, 0, cy, r, nil, self.notags, self.combinedtags)
        for _, hit_target in ipairs(c_hit_targets) do
            toskip[hit_target] = true
            if hit_target ~= doer and hit_target:IsValid() and not hit_target:IsInLimbo() and
               not (hit_target.components.health and hit_target.components.health:IsDead()) then
                pv.x, pv._, pv.y = hit_target.Transform:GetWorldPosition()
                local vrange = self.siderange + hit_target:GetPhysicsRadius(0.5) + 0.15
                if DistPointToSegmentXYSq(pv, p1, p2) < vrange * vrange then 
                    self:OnHit(doer, hit_target) 
                end
            end
        end
        doer_combat.ignorehitrange = false
    end
    
    -- 攻击终点区域目标
    local angle = (doer.Transform:GetRotation() + 90) * DEGREES
    local p3 = {x = p2.x + doer_combat.hitrange * math.sin(angle), y = p2.y + doer_combat.hitrange * math.cos(angle)}
    local p2_hit_targets = TheSim:FindEntities(p2.x, 0, p2.y, doer_combat.hitrange + self.physicspadding, nil, self.notags, self.combinedtags)
    
    for _, hit_target in ipairs(p2_hit_targets) do
        if not toskip[hit_target] and hit_target:IsValid() and not hit_target:IsInLimbo() and
           not (hit_target.components.health and hit_target.components.health:IsDead()) then
            pv.x, pv._, pv.y = hit_target.Transform:GetWorldPosition()
            local vradius = hit_target:GetPhysicsRadius(0.5)
            local vrange = doer_combat.hitrange + vradius
            if distsq(pv.x, pv.y, p2.x, p2.y) < vrange * vrange then
                vrange = self.siderange + vradius
                if DistPointToSegmentXYSq(pv, p2, p3) < vrange * vrange then 
                    self:OnHit(doer, hit_target) 
                end
            end
        end
    end
    
    -- 恢复战斗和武器设置
    doer_combat:EnableAreaDamage(true)
    if weapon then 
        if attackwear ~= 0 then weapon.attackwear = attackwear end 
    end
    
    -- 投掷物品处理 -----------------------------------------------------------------
    toskip = {}
    local srcpos = Vector3()
    
    -- 沿路径投掷物品
    if dist > 0 then
        local c_toss_targets = TheSim:FindEntities(cx, 0, cy, r, TOSS_MUSTTAGS, TOSS_CANTTAGS)
        for _, toss_target in ipairs(c_toss_targets) do
            toskip[toss_target] = true
            pv.x, pv._, pv.y = toss_target.Transform:GetWorldPosition()
            local lensq = DistPointToSegmentXYSq(pv, p1, p2)
            local vrangesq = self.siderange + toss_target:GetPhysicsRadius(0.5)
            vrangesq = vrangesq * vrangesq
            if lensq < vrangesq and pv._ < 0.2 then
                local dxv, dyv = pv.x - p1.x, pv.y - p1.y
                local proj = math.sqrt(dxv * dxv + dyv * dyv - lensq)
                srcpos.x = p1.x + dx * proj
                srcpos.z = p1.y + dy * proj
                if lensq <= 0 then
                    proj = (math.random(2) - 1.5) * .1
                    srcpos.x = srcpos.x + dy * proj
                    srcpos.z = srcpos.z + dx * proj
                end
                self:OnToss(doer, toss_target, srcpos, 1 - lensq / vrangesq, math.sqrt(lensq))
            end
        end
    end
    
    -- 终点区域投掷物品
    local p2_toss_targets = TheSim:FindEntities(p2.x, 0, p2.y, doer_combat.hitrange + self.physicspadding, TOSS_MUSTTAGS, TOSS_CANTTAGS)
    for _, toss_target in ipairs(p2_toss_targets) do
        if not toskip[toss_target] then
            pv.x, pv._, pv.y = toss_target.Transform:GetWorldPosition()
            local lensq = distsq(pv.x, pv.y, p2.x, p2.y)
            local vradius = toss_target:GetPhysicsRadius(0)
            local vrangesq = doer_combat.hitrange + vradius
            if lensq < vrangesq * vrangesq and pv._ < 0.2 then
                vrangesq = self.siderange + vradius
                vrangesq = vrangesq * vrangesq
                if DistPointToSegmentXYSq(pv, p2, p3) < vrangesq then
                    local dxv, dyv = pv.x - p2.x, pv.y - p2.y
                    local proj = math.sqrt(dxv * dxv + dyv * dyv - lensq)
                    srcpos.x = p1.x + dx * proj
                    srcpos.z = p1.y + dy * proj
                    if lensq <= 0 then
                        proj = (math.random(2) - 1.5) * 0.1
                        srcpos.x = srcpos.x + dy * proj
                        srcpos.z = srcpos.z + dx * proj
                    end
                    self:OnToss(doer, toss_target, srcpos, 1.5 - lensq / vrangesq, math.sqrt(lensq))
                end
            end
        end
    end
    
    -- 特效轨迹 ----------------------------------------------------------------
    if self.fxprefab and (self.fxspacing or 0) > 0 then
        if dist <= 0 then
            local fx = SpawnPrefab(self.fxprefab)
            fx.Transform:SetPosition(p2.x, 0, p2.y)
        else
            dist = math.floor(dist / self.fxspacing)
            dx = dx * self.fxspacing
            dy = dy * self.fxspacing
            local flip = math.random() < 0.5
            for i = 0, dist do
                if i == 0 then
                    p2.x = p2.x - dx * 0.25
                    p2.y = p2.y - dy * 0.25
                elseif i == 1 then
                    p2.x = p2.x - dx * 0.75
                    p2.y = p2.y - dy * 0.75
                else
                    p2.x = p2.x - dx
                    p2.y = p2.y - dy
                end
                local fx = SpawnPrefab(self.fxprefab)
                fx.Transform:SetPosition(p2.x, 0, p2.y)
                local k = (dist > 0 and math.max(0, 1 - i / dist)) or 0
                k = 1 - k * k
                if fx.FastForward then fx:FastForward(0.4 * k) end
                if fx.SetMotion then
                    k = 1 + k * 2
                    fx:SetMotion(k * dx, 0, k * dy)
                end
                if flip and fx.AnimState then fx.AnimState:SetScale(-1, 1) end
                flip = not flip
            end
        end
    end
    
    if self.onlungedfn ~= nil then 
        self.onlungedfn(self.inst, doer, startingpos, targetpos) 
    end
    return true
end

-- 检查物品组件是否存在
local function itemcomponent(item) 
    return item and item:IsValid() and (item.components.finiteuses or item.components.fueled or item.components.armor) 
end
-- 暗影冲刺循环状态图
local state_lunge_loop = State {
    name = "lunge_loop2hm",
    tags = {"attack", "busy", "noattack", "temp_invincible"},
    
    onenter = function(inst, data)
        inst.AnimState:PlayAnimation("lunge_pst") -- 注意：这个动画不是循环的
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_nightsword")
        inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_shadow_med_sharp")
        
        -- 设置面向目标
        local pos = inst:GetPosition()
        if pos.x ~= data.targetpos.x or pos.z ~= data.targetpos.z then 
            inst:ForceFacePoint(data.targetpos:Get()) 
        end
        
        -- 获取武器和检查装备组件
        local weapon = data and data.weapon
        local component = itemcomponent(weapon) or 
                         itemcomponent(inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)) or
                         itemcomponent(inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY))
        
        -- 消耗装备耐久
        if component and component.SetPercent then
            component:SetPercent(component:GetPercent() - 0.05 * (data and data.use or 1))
            
            -- 设置武器AOE组件
            if weapon and weapon:IsValid() then
                if not weapon.components.aoeweapon_lunge then
                    -- 如果没有武器组件则添加基础武器组件
                    if not weapon.components.weapon then
                        weapon:AddComponent("weapon")
                        weapon.components.weapon:SetDamage(10)
                    end
                    
                    -- 添加AOE攻击组件
                    weapon:AddComponent("aoeweapon_lunge")
                    if weapon.components.aoeweapon_lunge.SetWorkActions then
                        weapon.components.aoeweapon_lunge:SetWorkActions()
                        weapon.components.aoeweapon_lunge.tags = {"_combat"}
                        weapon.components.aoeweapon_lunge:SetOnHitFn(onlungehit)
                        
                        -- 根据武器类型设置特效和伤害
                        if weapon:HasTag("shadow_item") then
                            if weapon.components.planardamage and inst.components.damagetypebonus then
                                weapon.components.aoeweapon_lunge:SetTrailFX("willow_shadow_flame", 1.5)
                                inst.components.combat.externaldamagemultipliers:SetModifier(weapon, 2, "shadowstrike2hm")
                            else
                                weapon.components.aoeweapon_lunge:SetTrailFX("cane_ancient_fx", 1)
                                inst.components.combat.externaldamagemultipliers:SetModifier(weapon, 1.5, "shadowstrike2hm")
                            end
                        end
                        
                        AOEWeapon_Lunge_DoLunge(weapon.components.aoeweapon_lunge, inst, pos, data.targetpos)
                        
                        -- 清理伤害加成
                        if weapon:IsValid() then
                            if weapon:HasTag("shadow_item") then
                                inst.components.combat.externaldamagemultipliers:RemoveModifier(weapon, "shadowstrike2hm")
                            end
                        end
                    end
                    
                    -- 清理AOE组件
                    if weapon:IsValid() then 
                        weapon:RemoveComponent("aoeweapon_lunge") 
                    end
                end
            end
            
            -- 传送到目标位置
            inst.Physics:Teleport(data.targetpos.x, 0, data.targetpos.z)
        end
        
        -- 设置取消无敌状态任务
        if inst.cancelmisstask2hm then 
            inst.cancelmisstask2hm:Cancel() 
        end
        inst.cancelmisstask2hm = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 0.1, cancelmiss)
    end,
    
    events = {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.cancelmisstask2hm then 
                    inst.cancelmisstask2hm:Cancel() 
                end
                inst.cancelmisstask2hm = inst:DoTaskInTime(0.1, cancelmiss)
                inst.sg:GoToState("idle")
            end
        end)
    },
    
    onexit = function(inst)
        if inst.cancelmisstask2hm then 
            inst.cancelmisstask2hm:Cancel() 
        end
        inst.cancelmisstask2hm = inst:DoTaskInTime(0.1, cancelmiss)
    end
}

-- 添加状态图到服务端和客户端
AddStategraphState("wilson", state_lunge_pre)
AddStategraphState("wilson", state_lunge_loop)

-- 获取暗影冲刺特殊动作
local function GetPointSpecialActions_Lunge(inst, pos, useitem, right)
    if right and not equipaoetargeting(inst) and inst:HasTag("shadowlunge2hm") and not inst:GetCurrentPlatform() then
        local inventory = inst.replica.inventory
        local tool = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
        
        -- 检查是否装备近战武器
        if tool ~= nil then
            local inventoryitem = tool.replica.inventoryitem
            local has_weapon = inventoryitem ~= nil and inventoryitem:IsWeapon() and 
                              not tool:HasTag("rangedweapon") and not tool:HasTag("projectile")
            
            local rider = inst.replica.rider
            -- 需要装备武器、不在骑乘状态、不在海洋中
            if has_weapon and not (rider and rider:IsRiding()) and 
               not TheWorld.Map:IsOceanAtPoint(pos.x, pos.y, pos.z, false) then
                return {ACTIONS.Lunge_WAXWELL2HM}
            end
        end
    end
    return {}
end

-- 暗影冲刺能力所有者设置
local function OnSetOwner_Lunge(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.rightaction2hm = GetPointSpecialActions_Lunge
        
        if not inst.components.playeractionpicker.pointspecialactionsfn then
            inst.components.playeractionpicker.pointspecialactionsfn = ctrlLunge and function(...)
                return inst.components.playercontroller and 
                       inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK) and
                       GetPointSpecialActions_Lunge(...) or {}
            end or GetPointSpecialActions_Lunge
        else
            local old = inst.components.playeractionpicker.pointspecialactionsfn
            inst.components.playeractionpicker.pointspecialactionsfn = function(...)
                local pressctrl = inst.components.playercontroller and 
                                 inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK)
                
                if ctrlLunge then 
                    return pressctrl and GetPointSpecialActions_Lunge(...) or old(...) 
                end
                
                if ctrldisable and pressctrl then
                    local oldactions = old(...)
                    return #oldactions > 0 and oldactions or GetPointSpecialActions_Lunge(...)
                end
                
                local actions = GetPointSpecialActions_Lunge(...)
                return #actions > 0 and actions or old(...)
            end
        end
    end
end

-- 延迟设置暗影冲刺所有者
local function delayOnSetOwner_Lunge(inst) 
    inst:DoTaskInTime(0, OnSetOwner_Lunge) 
end

-- 添加暗影冲刺能力到实例
function AddLungeAbility(inst)
    inst.rightaction2hm = net_bool(inst.GUID, "player.rightaction2hm", "rightaction2hmdirty")
    inst:ListenForEvent("setowner", delayOnSetOwner_Lunge)
end


-- ================================
-- 系统扩展 - 右键动作范围扩展
-- ================================

-- 扩展玩家动作选择器组件以支持右键动作
AddComponentPostInit("playeractionpicker", function(self)
    local DoGetMouseActions = self.DoGetMouseActions
    
    self.DoGetMouseActions = function(self, position, target, spellbook, ...)
        -- 检查实例是否有有效的库存复制品
        if not (self.inst.replica and self.inst.replica.inventory) then 
            return 
        end
        
        -- 获取原始的左右键动作
        local leftaction, rightaction = DoGetMouseActions(self, position, target, spellbook, ...)
        
        -- 如果没有右键动作且有右键动作函数，且鼠标不在HUD上
        if rightaction == nil and self.rightaction2hm and not TheInput:GetHUDEntityUnderMouse() then
            local actions = self.rightaction2hm(self.inst, 
                                               position or TheInput:GetWorldPosition() or (target and target:GetPosition()), 
                                               nil, true)
            rightaction = self:SortActionList(actions)[1]
            
            -- 设置动作位置
            if position and rightaction then
                if not rightaction.pos then
                    rightaction.pos = DynamicPosition(pos)
                    rightaction.pos.local_pt = Vector3(position:Get())
                elseif rightaction.pos and rightaction.pos.local_pt then
                    rightaction.pos.local_pt = Vector3(position:Get())
                end
            end
        end
        
        return leftaction, rightaction
    end
end)
