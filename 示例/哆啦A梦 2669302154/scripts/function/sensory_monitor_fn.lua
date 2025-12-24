--------------------------------
--[[ 感觉监视器函数,将一些复杂的函数放在这里]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-01]]
--[[ @updateTime: 2022-01-01]]
--[[ @email: x7430657@163.com]]
--------------------------------

local PlayerUtil =  require("util/player_util")
local Logger =  require("util/logger")
local Table =  require("util/table")
local ScreenUtil =  require("util/screen_util")
local ComponentUtil = require("util/component_util")
local SensoryMonitorFn = {}

local brain = require("brains/sensory_monitor_brain")

local function Teleport(inst,pos)
    if inst.Physics then
        inst.Physics:Teleport(pos:Get())
    else
        inst.Transform:SetPosition(pos:Get())
    end
end
--[[隐藏目标]]
function SensoryMonitorFn:Hide(inst)
    inst.MiniMapEntity:SetEnabled(false) -- 小地图
    inst:AddTag("NOCLICK")		--不可被点击，查看
    inst:AddTag("NOBLOCK")		--不可被查看	建造不会被遮挡
    inst:AddTag("notarget")		--不能被作为目标
    inst:AddTag("CLASSIFIED")	--增加保密标签,客机无法查看
    inst:AddTag("haunted")      --防作祟标签
    inst:AddTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG)      --正在使用感觉监视器标签
    inst.components.health:SetInvincible(true)
    if inst.Physics and inst.Physics:GetCollisionMask() ~= COLLISION.GROUND then
        RemovePhysicsColliders(inst)
        inst._sensory_monitor_no_physics_collision = true
    end
    inst.DynamicShadow:Enable(false) -- 影子禁用
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(false)
    end
    if inst.components.talker ~= nil then
        inst.components.talker:ShutUp()
        inst.components.talker:IgnoreAll()
    end
    if inst.components.inventory then
        inst.components.inventory:Close(true)
    end
    if inst.components.locomotor then
        inst.components.locomotor.pathcaps = { player = true, ignorecreep = true ,allowocean = true}
        inst.components.locomotor.fasteronroad = false
        inst.old_triggerscreep = inst.components.locomotor.triggerscreep
        if inst.old_triggerscreep ~= nil then
            inst.components.locomotor:SetTriggersCreep(false)
        end
        inst.components.locomotor:SetAllowPlatformHopping(false)--平台跳跃
    end
    if inst.components.catcher ~= nil then -- 捕捉
        inst.components.catcher:SetEnabled(false)
    end
    if inst.components.drownable then -- 溺水
        inst.components.drownable.enabled = false
    end
    -- 最后再隐藏
    inst:Hide()
end

--[[显示目标]]
function SensoryMonitorFn:Show(inst)
    inst.MiniMapEntity:SetEnabled(true) -- 小地图
    inst:RemoveTag("NOCLICK")		--不可被点击，查看
    inst:RemoveTag("NOBLOCK")		--不可被查看	建造不会被遮挡
    inst:RemoveTag("notarget")		--不能被作为目标
    inst:RemoveTag("CLASSIFIED")	--增加保密标签,客机无法查看
    inst:RemoveTag("haunted")      --防作祟标签
    inst:RemoveTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) --感觉监视器
    inst.components.health:SetInvincible(false)--去除无敌
    if inst._sensory_monitor_no_physics_collision and inst.Physics then
        ChangeToCharacterPhysics(inst)
        inst._sensory_monitor_no_physics_collision = false
    end
    inst.DynamicShadow:Enable(true) -- 影子禁用
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(true)
    end
    if inst.components.talker ~= nil then
        inst.components.talker:StopIgnoringAll()
    end
    if inst.components.inventory and not inst.components.health:IsDead() then
        inst.components.inventory:Open()
    end
    if inst.components.locomotor then
        inst.components.locomotor.pathcaps = { player = true, ignorecreep = true }
        inst.components.locomotor.fasteronroad = true
        --可被催眠
        if inst.old_triggerscreep ~= nil then
            inst.components.locomotor:SetTriggersCreep(inst.old_triggerscreep)
        end
        -- 平台跳跃 应该跳船
        inst.components.locomotor:SetAllowPlatformHopping(true)
    end
    if inst.components.catcher ~= nil then -- 捕捉
        inst.components.catcher:SetEnabled(true)
    end
    if inst.components.drownable then -- 溺水
        inst.components.drownable.enabled = true
    end
    inst:Show()
end

function SensoryMonitorFn:Exit(inst)
    -- 先获取该用户使用的监视器,并且移除
    if inst._sensory_monitor and inst._sensory_monitor._sensory_monitor_users then
        Table:RemoveValue(inst._sensory_monitor._sensory_monitor_users,inst)
        inst._sensory_monitor = nil
    end
    local body = TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY[inst]
    if body ~= nil and body:IsValid() then
        -- 传送回去
        local pos = body:GetPosition()
        Teleport(inst,pos)
        -- 调用此方法会在原地显示出来，再传送回去，因此废弃
        --inst:DoTaskInTime(0, Teleport,pos)--这里只传pos即可DoTaskInTime会自动加inst

        -- 如果正在被监视,需要将监视者挪回真正的人物上面
        Logger:Debug({"退出监视-获取切换用户",TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[body]},2)
        for _,cameraFollower in pairs(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[body]) do
            Logger:Debug({"退出监视-判断切换用户",body == TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[cameraFollower],
                          cameraFollower:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG),
                          cameraFollower ~= inst})
            if body == TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[cameraFollower]
                    and cameraFollower:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG)
                and cameraFollower ~= inst -- 不是退出监视的用户
            then
                self:Switch(cameraFollower,inst) -- 切换至真正的用户所在位置
            end
        end
        -- 删除body对应FOLLOWERS(该数据已成为垃圾数据)
        Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS,body)
        body.removeOwner(body)
        -- 删除body
        body._no_exit = true -- 防止删除后又执行exit方法
        body:Remove()
    end
    -- 从跟踪者们中移除
    if TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[inst] ~= nil then
        local oldTarget = TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[inst]
        Table:RemoveValue(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[oldTarget],inst)
    end
    -- 从摄像头和body中删除
    Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER,inst)
    Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY,inst)
    -- 停止大脑
    inst:StopBrain()
    inst.brainfn = inst._old_brain_fn
    if inst._old_brain then
        inst.brain = inst._old_brain
        if inst._old_brain_stopped then
            inst.brain:Start()
        end
    end
    if inst.components.locomotor then
        inst.components.locomotor:Stop() -- 停止
    end
    self:Show(inst)
    -- 还原监控状态变量
    inst._senory_monitor_status:set(false)
end

-- 传送到目标
function SensoryMonitorFn:Switch(doer,target)
    if target ~= nil and  target:IsValid()
    -- 这里去除判断是否目标一致,以便出现bug,用户可重置监控状态
    -- and doer.cameraLeader ~= target
    then
        -- 传送到目标
        -- 从旧FOLLOWERS中删除
        Logger:Debug({"退出监视-切换用户",doer,target},1)
        if TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[doer] ~= nil then
            local oldTarget = TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[doer]
            Table:RemoveValue(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[oldTarget],doer)
        end
        -- 增加到新的FOLLOWERS中
        if not Table:HasValue(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[target],doer) then
            --table.insert(target.cameraFollowers,doer)
            table.insert(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[target],doer)
        end
        -- 标记目标
        TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[doer] = target
        Logger:Debug({"退出监视-切换用户后",doer,TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[doer],TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[target]},1)
        doer:RestartBrain()
        local pos = target:GetPosition()
        Teleport(doer,pos)
        return true
    end
    return false
end

function SensoryMonitorFn:Change(doer,type,userid,guid)
    if doer:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then -- 正在监视
        local target = nil -- 目标
        if type == TUNING.DORAEMON_TECH.SENSORY_MONITOR_TYPE_PLAYER then
            -- 玩家
            local allPlayers = PlayerUtil:GetAllPlayers(true)
            for _,v in pairs(allPlayers) do
                if v.userid == userid then
                    target = v
                end
            end
            -- 目标不为null ， 这里要判断一下target是否在监视，在监视取body
            -- 否则产生自身监视自身的bug
            if target ~= nil then
                if target:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then
                    target = TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY[target]
                end
            end

        elseif type == TUNING.DORAEMON_TECH.SENSORY_MONITOR_TYPE_CAMERA then
            -- 摄像头
            local allCameras = TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERAS
            for _,camera in pairs(allCameras) do
                if camera.GUID == guid and (userid == nil or userid == camera._owner.userid) then
                    target = camera
                    break
                end
            end
        end
        self:Switch(doer,target)
    end
end

-- 监视自己
function SensoryMonitorFn:BackToSelf(inst)
    -- 拿到body
    local target = TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY[inst]
    local  result = self:Switch(inst,target)
    -- 没有成功切换则退出监视, 但按逻辑以下代码不该执行
    -- 保鲜起见增加以下代码
    if not result then
        self:Exit(inst)
    end
end

-- 使用
function SensoryMonitorFn:Onuse(act)
    -- 用户位置放下一个假人，传送到
    local doer = act.doer
    local target = act.target
    Logger:Debug({"监视器执行",doer,target},1)
    if doer and target then
        -- 保存当前使用的用户
        if not Table:HasValue(target._sensory_monitor_users,doer) then
            table.insert(target._sensory_monitor_users,doer)
        end
        -- 在用户身上保存使用的监视器
        doer._sensory_monitor = target
        -- 如果背负重物则丢掉
        if doer.components.inventory and doer.components.inventory:IsHeavyLifting() then
            doer.components.inventory:DropItem(
                    doer.components.inventory:Unequip(EQUIPSLOTS.BODY),
                    true,
                    true
            )
        end
        --[[假人物品耐久同步问题]]
        --[[暂时将物品全部给假人,后续以假人为准]]
        --[[但不兼容成长性人物后续其人物可保鲜]]
        --[[也可以换种方法,锁死玩家目前的物品状态]]
        -- 生成body
        local body  = SpawnPrefab(TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB,doer:GetSkinName())
        -- setOwner 会切换装备
        body.setOwner(body,doer)
        self:Hide(doer)
        doer._senory_monitor_status:set(true) -- 通知客户端显示相关界面(监视和退出监视的按钮)
        TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY[doer] = body
        body.Transform:SetPosition(doer:GetPosition():Get())
        if act.target then -- 面向监视器
            body:FacePoint(act.target:GetPosition():Get())
        else -- 随便设置一个，因为是重叠的，所以应该是朝向下方的
            body:FacePoint(doer:GetPosition():Get())
        end
        -- 设置监控大脑和相关辅助变量
        doer._old_brain_fn = doer.brainfn -- 旧大脑fn
        -- 存在大脑且正在运行则停止
        if doer.brain ~= nil  then
            doer._old_brain = doer.brain
            if not doer.brain.stopped then
                doer:StopBrain() -- 设置大脑前先停止
                doer._old_brain_stopped = true -- 标志，用以结束时还原大脑状态
            end
        end
        doer:SetBrain(brain)
        doer:RestartBrain()
        --标记监视者
        TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[body] = {}
        table.insert(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[body],doer)
        TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[doer] = body
        -- 万一有人在监视玩家,需要将监视玩家的人转至body
        for _,cameraFollower in pairs(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[doer]) do
            if doer == TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[cameraFollower]
                    and cameraFollower:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG)
            then
                self:Switch(cameraFollower,body) -- 切换至body
            end
        end
        return true
    end
end
return SensoryMonitorFn