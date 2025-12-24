-- 默认编队相关的常量定义
local FORMATION_ROTATION_SPEED = 0.9    -- 编队旋转速度
local FORMATION_RADIUS = 10             -- 编队半径
local FORMATION_SEARCH_RADIUS = 100     -- 编队搜索半径
local FORMATION_MAX_SPEED = 9999999     -- 编队最大速度
local FORMATION_MAX_OFFSET = 0          -- 编队最大偏移量
local FORMATION_OFFSET_LERP = 0.95      -- 编队位置插值速度
local FORMATION_MIN_SIZE = 1            -- 编队最小大小
local FORMATION_MAX_SIZE = 6            -- 编队最大大小
local VALIDATE_FORMATION_FREQ = 1       -- 编队验证频率
local FIND_TARGET_MUSTTAGS = { "player" }  -- 必须是带"player"标签的目标
local FIND_TARGET_NOTAGS = { "playerghost" }  -- 不包括"playerghost"标签的目标

-- 生成新编队函数
local MakeFormation

-----------------------------------------------------------------------------------------
---[[编队领导者部分]]
-----------------------------------------------------------------------------------------
-- 处理编队解散的逻辑
local function onformationdisband(inst)
    if inst.components.formationleader.target ~= nil then
        inst.components.formationleader.target._hmr_formation = nil
    end
end

local function LeaderOnUpdate(inst)
    local leader = inst.components.formationleader
    if leader.target ~= nil and leader.target:IsValid() then
        local tx, ty, tz = leader.target.Transform:GetWorldPosition()

        local r = -(leader.target.Transform:GetRotation() / RADIANS)

        -- 计算目标的偏移位置
        local targetoffsetdistance =
            leader.target.components.locomotor ~= nil and
            leader.target.components.locomotor.walkspeed * (leader.target.components.locomotor.wantstomoveforward and FORMATION_MAX_OFFSET or 0)
            or 0
        local targetoffset_x = tx + math.cos(r) * targetoffsetdistance
        local targetoffset_z = tz + math.sin(r) * targetoffsetdistance

        -- 初始化偏移量并通过线性插值调整位置
        inst._offset.x = Lerp(inst._offset.x, targetoffset_x, FORMATION_OFFSET_LERP)
        inst._offset.z = Lerp(inst._offset.z, targetoffset_z, FORMATION_OFFSET_LERP)

        inst.Transform:SetPosition(inst._offset.x, ty, inst._offset.z)
    end
end

-- 验证编队的有效性
local function LeaderValidateFormation(inst)
    if inst.components.formationleader:GetFormationSize() <= 0 or
            inst.components.formationleader.target == nil or not inst.components.formationleader.target:IsValid() then
        inst.components.formationleader:DisbandFormation()
        inst:Remove()
    end

    -- 将外圈成员移入未满的内圈
    local leaders = {}
    local mx, my, mz = inst.Transform:GetWorldPosition()
    local formations = TheSim:FindEntities(mx, my, mz, 10, {"formationleader"})
    for _, formation in pairs(formations) do
        if formation.components.formationleader.target == inst.components.formationleader.target then
            table.insert(leaders, formation)
        end
    end

    if #leaders > 0 then
        -- 按照领导者年龄排序,年龄大的排在前面
        local sort = function(w1, w2)
            if w1.components.formationleader.age > w2.components.formationleader.age then
                return true
            end
        end
        table.sort(leaders, sort)

        for i = 2, #leaders do
            if leaders[i] == inst and
                leaders[i].components.formationleader:GetFormationSize() > 0 and
                not leaders[i - 1].components.formationleader:IsFormationFull()
            then
                local last_formation = next(inst.components.formationleader.formation)
                leaders[i].components.formationleader:OnLostFormationMember(last_formation)
                leaders[i - 1].components.formationleader:NewFormationMember(last_formation)
            end
        end
    end
end

-- 创建新的編隊
MakeFormation = function(inst, target)
    local leader = SpawnPrefab("formationleader")
    local x, y, z = inst.Transform:GetWorldPosition()
    leader.Transform:SetPosition(x, y, z)
    leader._offset = leader:GetPosition()

    leader.components.formationleader:SetUp(target, inst)  -- 设置首领的目标和成员

    target._hmr_formation = leader  -- 设置目标的编队标记
    leader.components.formationleader.ondisbandfn = onformationdisband  -- 设置解散时的回调

    -- 成员数量设置
    leader.components.formationleader.min_formation_size = inst.min_size
    leader.components.formationleader.max_formation_size = inst.max_size

    leader.components.formationleader.radius = inst.radius  -- 设置编队半径
    leader.components.formationleader.thetaincrement = inst.rotation_speed  -- 设置旋转速度

    leader.components.formationleader.onupdatefn = LeaderOnUpdate  -- 设置更新函数

    leader:DoPeriodicTask(VALIDATE_FORMATION_FREQ, LeaderValidateFormation)  -- 定期校验编队
end

-----------------------------------------------------------------------------------------
---[[编队成员部分]]
-----------------------------------------------------------------------------------------

-- 跟随者更新逻辑
local function FollowerOnUpdate(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()
    local dist = VecUtil_Length(targetpos.x - x, targetpos.z - z)

    inst.components.locomotor.walkspeed = math.min(dist * 8, inst.max_speed)
    inst:FacePoint(targetpos.x, 0, targetpos.z)
    if inst.updatecomponents[inst.components.locomotor] == nil then
        inst.components.locomotor:WalkForward(true)
    end
end

-- 离开编队时的处理逻辑
local function OnLeaveFormation(inst, leader)
    if not inst.already_remove then
        inst.already_remove = true
        inst:DoTaskInTime(2, function()
            if not inst.components.formationfollower.in_formation or inst.components.formationfollower.formationleader == nil then
                if inst.anim_pst ~= nil then
                    inst.AnimState:PlayAnimation(inst.anim_pst)
                    inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)
                else
                    inst:Remove()
                end
            end
        end)
    end
end

-- 进入编队时的处理逻辑
local function OnEnterFormation(inst, leader)
    inst.components.locomotor:Stop()
    inst:AddTag("NOBLOCK")
end

local function Init(inst, data)
    inst.radius = data.radius or FORMATION_RADIUS
    inst.rotation_speed = data.rotation_speed or FORMATION_ROTATION_SPEED
    inst.max_speed = data.max_speed or FORMATION_MAX_SPEED
    inst.min_size = data.min_size or FORMATION_MIN_SIZE
    inst.max_size = data.max_size or FORMATION_MAX_SIZE

    if data.anim_pst ~= nil then
        inst.anim_pst = data.anim_pst
    end
end

-----------------------------------------------------------------------------------------
---[[初始化（必执行）]]
-----------------------------------------------------------------------------------------
local function SetLeader(inst, target)
    if target == nil or not target:IsValid() then
        return
    end

    local leaders_for_target = {}
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local leaders = TheSim:FindEntities(tx, ty, tz, 10, {"formationleader"})
    if #leaders > 0 then
        for _, leader in pairs(leaders) do
            if leader.components.formationleader.target == target then
                table.insert(leaders_for_target ,leader)
            end
        end
    end

    if not inst.components.formationfollower:SearchForFormation(leaders_for_target) then  -- 寻找当前编队
        MakeFormation(inst, target)  -- 创建新的编队
    end
end

local function MakeFormationMember(name, common_postinit, master_postinit, assets, prefabs, data)
    assets = assets or {}

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddDynamicShadow()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        MakeGhostPhysics(inst, 1, .5)

        inst.DynamicShadow:SetSize(1, .5)

        inst.AnimState:SetBank(data.bank or data.build or name)
        inst.AnimState:SetBuild(data.build or name)
        if data.anim_pre ~= nil then
            inst.AnimState:PlayAnimation(data.anim_pre)
            inst.AnimState:PushAnimation(data.anim or "idle", true)
        else
            inst.AnimState:PlayAnimation(data.anim or "idle", true)
        end
        if data.random_frame then
            inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
        end

        if data.light ~= nil then
            inst.AnimState:SetLightOverride(1)

            inst.Light:SetFalloff(0.7)
            inst.Light:SetIntensity(.5)
            inst.Light:SetRadius(1.8)
            inst.Light:SetColour(unpack(data.light.colour or {237 / 255, 237 / 255, 209 / 255}))
            inst.Light:Enable(true)
        end

        inst:AddTag("flying")
        inst:AddTag("ignorewalkableplatformdrowning")

        MakeInventoryFloatable(inst)

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        Init(inst, data)

        inst:AddComponent("locomotor")
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)
        inst.components.locomotor:SetTriggersCreep(false)
        inst.components.locomotor.walkspeed = TUNING.LIGHTFLIER.WALK_SPEED
        inst.components.locomotor.pathcaps = { allowocean = true }

        inst:AddComponent("inspectable")

        inst:AddComponent("follower")

        -- formationleader要求
        inst:AddComponent("combat")

        inst:AddComponent("formationfollower")
        inst.components.formationfollower.searchradius = data.search_radius or FORMATION_SEARCH_RADIUS
        inst.components.formationfollower.formation_type = data.formation_type or "lightflier"
        inst.components.formationfollower.onupdatefn = FollowerOnUpdate
        inst.components.formationfollower.onleaveformationfn = OnLeaveFormation
        inst.components.formationfollower.onenterformationfn = OnEnterFormation

        inst.SetLeader = SetLeader

        if master_postinit ~= nil then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return MakeFormationMember
--[[
params:
    name: 预制体名称
    common_postinit: 通用初始化函数
    master_postinit: 主服务器初始化函数
    assets: 资源表
    prefabs: 预制体表
    data: 预制体数据
        radius：半径
        rotation_speed：旋转速度
        max_speed：最大速度
        formation_type：编队类型
        search_radius：搜索半径
        bank：动画银行
        build：动画构建
        anim：动画名称
        anim_pre：动画前缀
        anim_pst：动画后缀
        light：光照设置
            colour：光照颜色
]]