require "prefabutil" -- 引入 prefabutil 库，用于处理 prefab 相关功能

-- 墙壁修复者
local function DeltaHealth(inst)
    if inst.level == 2 then
        inst:DoPeriodicTask(5, function()
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, 0, z, 10)
            for k,v in pairs(ents) do
                if v ~= inst and v:HasTag("wall") and v.components.health and v.components.health:GetPercent() < 1 then
                    -- 只能由一个修复者修复
                    if v.honor_wallrepairer == nil then
                        v.honor_wallrepairer = inst
                    elseif v.honor_wallrepairer ~= inst then
                        return
                    end
                    -- 设置最大修复值，避免修复至下一阶段
                    local healthpercent = v.components.health:GetPercent()
                    if v.honor_maxrepair == nil or v.honor_maxrepair < healthpercent then
                        if healthpercent <= 0.4 then
                            v.honor_maxrepair = 0.4
                        elseif healthpercent <= 0.5 then
                            v.honor_maxrepair = 0.5
                        elseif healthpercent <= 0.99 then
                            v.honor_maxrepair = 0.99
                        else
                            v.honor_maxrepair = 1
                        end
                    end
                    if v.components.health and healthpercent < v.honor_maxrepair then
                        local delta = math.random()* 2 + 0.5
                        local x2, y2, z2 = v.Transform:GetWorldPosition()
                        local distance = math.sqrt((x - x2)^2 + (z - z2)^2)
                        local speed = 20
                        if v.components.health.currenthealth + delta <= v.honor_maxrepair * v.components.health.maxhealth then
                            inst:DoTaskInTime(distance/speed, function()
                                v.components.health:DoDelta(delta)
                            end)
                        else
                            inst:DoTaskInTime(distance/speed, function()
                                v.components.health:DoDelta(v.honor_maxrepair * v.components.health.maxhealth - v.components.health.currenthealth)
                                v:RemoveTag("honor_wall_repairing")
                            end)
                        end
                        -- 特效
                        for i = 1, 5 do
                            inst:DoTaskInTime(i*0.1, function()
                                local life = SpawnPrefab("honor_walls_fx")
                                if life ~= nil then
                                    life.movingTarget = v
                                    life.Transform:SetPosition(inst.Transform:GetWorldPosition())
                                end
                            end)
                        end
                    end
                end
            end
        end)
    end
end

local function OnSave(inst, data)
    data.level = inst.level
end

local function OnLoad(inst, data)
    inst.level = data.level or 1
    if inst.level == 1 then
        inst.components.trader:Enable()
    else
        inst.components.trader:Disable()
        DeltaHealth(inst)
    end
end

-- 当路径查找状态变化时的处理函数
local function OnIsPathFindingDirty(inst)
    if inst._ispathfinding:value() then -- 检查当前是否在路径寻找状态
        if inst._pfpos == nil and inst:GetCurrentPlatform() == nil then -- 如果没有设置路径点且当前平台为空
            inst._pfpos = inst:GetPosition() -- 获取当前实体的位置并设置为路径点
            TheWorld.Pathfinder:AddWall(inst._pfpos:Get()) -- 在路径查找器中添加一面墙
        end
    elseif inst._pfpos ~= nil then -- 如果路径点已设置
        TheWorld.Pathfinder:RemoveWall(inst._pfpos:Get()) -- 从路径查找器中移除墙
        inst._pfpos = nil -- 清除路径点
    end
end

-- 初始化路径查找
local function InitializePathFinding(inst)
    inst:ListenForEvent("onispathfindingdirty", OnIsPathFindingDirty) -- 监听路径查找状态变化事件
    OnIsPathFindingDirty(inst) -- 初始化时调用状态更新函数
end

-- 创建障碍物
local function makeobstacle(inst)
    inst.Physics:SetActive(true) -- 激活物理碰撞
    inst._ispathfinding:set(true) -- 设置为路径寻找状态
end

-- 清除障碍物
local function clearobstacle(inst)
    inst.Physics:SetActive(false) -- 禁用物理碰撞
    inst._ispathfinding:set(false) -- 清除路径寻找状态
end

-- 动画状态阈值
local anims =
{
    { threshold = 0, anim = "broken" },
    { threshold = 0.4, anim = "onequarter" },
    { threshold = 0.5, anim = "half" },
    { threshold = 0.99, anim = "threequarter" },
    { threshold = 1, anim = { "fullA", "fullB", "fullC" } },
}

-- 根据生命值百分比决确定要播放的动画
local function resolveanimtoplay(inst, percent)
    for i, v in ipairs(anims) do
        if percent <= v.threshold then
            if type(v.anim) == "table" then -- 如果动画是一个表
                -- 根据实体的世界位置获取稳定的动画
                local x, y, z = inst.Transform:GetWorldPosition()
                local x = math.floor(x)
                local z = math.floor(z)
                local q1 = #v.anim + 1
                local q2 = #v.anim + 4
                local t = ( ((x%q1)*(x+3)%q2) + ((z%q1)*(z+3)%q2) )% #v.anim + 1
                return v.anim[t]
            else
                return v.anim
            end
        end
    end
end

-- 处理生命值变化
local function onhealthchange(inst, old_percent, new_percent)
    local anim_to_play = resolveanimtoplay(inst, new_percent) -- 获取对应的动画
    if new_percent > 0 then -- 如果新生命值大于0
        if old_percent <= 0 then
            makeobstacle(inst) -- 如果旧生命值小于等于0，创建障碍
        end
        inst.AnimState:PlayAnimation(anim_to_play.."_hit") -- 播放受到攻击的动画
        inst.AnimState:PushAnimation(anim_to_play, false) -- 推送正常动画
    else -- 如果新生命值小于等于0
        if old_percent > 0 then
            clearobstacle(inst) -- 清除障碍
        end
        inst.AnimState:PlayAnimation(anim_to_play)
    end
end

-- 保持目标函数，始终返回 false
local function keeptargetfn()
    return false
end

-- 实体加载时的处理
local function onload(inst,data)
    if inst.components.health:IsDead() then
        clearobstacle(inst) -- 如果实体已死亡，清除障碍
    end

    if data and data.gridnudge then -- 检查数据中是否有 gridnudge
        local function normalize(coord)

            local temp = coord%0.5
            coord = coord + 0.5 - temp

            if  coord%1 == 0 then
                coord = coord -0.5
            end

            return coord
        end

        local pt = Vector3(inst.Transform:GetWorldPosition()) -- 获取当前实例的世界位置
        pt.x = normalize(pt.x) -- 标准化 x 坐标
        pt.z = normalize(pt.z) -- 标准化 z 坐标
        inst.Transform:SetPosition(pt.x,pt.y,pt.z) -- 设置实例的新位置
    end
end

-- 移除实体时的处理
local function onremove(inst)
    inst._ispathfinding:set_local(false) -- 设置路径寻找状态为局部 false
    OnIsPathFindingDirty(inst) -- 更新路径状态
end

-- 可用来验证修复的函数
local PLAYER_TAGS = { "player" }
local function ValidRepairFn(inst)
    if inst.Physics:IsActive() then
        return true -- 如果物理活动，则可以修复
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    if TheWorld.Map:IsAboveGroundAtPoint(x, y, z) then
        return true -- 如果在地面上则可以修复
    end

    if TheWorld.Map:IsVisualGroundAtPoint(x,y,z) then
        for i, v in ipairs(TheSim:FindEntities(x, 0, z, 1, PLAYER_TAGS)) do
            if v ~= inst and
            v.entity:IsVisible() and
            v.components.placer == nil and
            v.entity:GetParent() == nil then
                local px, _, pz = v.Transform:GetWorldPosition()
                if math.floor(x) == math.floor(px) and math.floor(z) == math.floor(pz) then
                    return false -- 如果周围有玩家实体则无法修复
                end
            end
        end
    end
    return true -- 否则可以修复
end

local assets =
{
    Asset("ANIM", "anim/honor_wall.zip"),
    Asset("ANIM", "anim/wall.zip"),
}

local prefabs =
{
    "collapse_small",
    "brokenwall_stone",
}

local function ondeploywall(inst, pt, deployer) -- 部署墙体时的逻辑
    --inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
    --local wall = SpawnPrefab("honor_wall", inst.linked_skinname, inst.skin_id) -- 生成墙体实例(带皮肤)
    local wall = SpawnPrefab("honor_wall", inst.linked_skinname, inst.skin_id)
    if wall ~= nil then
        local x = math.floor(pt.x) + .5
        local z = math.floor(pt.z) + .5
        wall.Physics:SetCollides(false) -- 禁用碰撞
        wall.Physics:Teleport(x, 0, z) -- 传送墙体到指定位置
        wall.Physics:SetCollides(true) -- 启用碰撞
        inst.components.stackable:Get():Remove() -- 移除堆叠物品

        wall.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone") -- 播放建筑音效
    end
end

local function onhammered(inst, worker) -- 当被锤击时的处理
    local num_loots = math.max(1, math.floor(2 * inst.components.health:GetPercent())) -- 根据生命值计算掉落物数量
    for i = 1, num_loots do
        inst.components.lootdropper:SpawnLootPrefab("potato") -- 生成掉落物
    end

    local fx = SpawnPrefab("collapse_small") -- 生成碎裂效果
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) -- 设置效果位置
    fx:SetMaterial("stone") -- 设置材料

    -- 清除修复者
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 10)
    for k,v in pairs(ents) do
        if v.honor_wallrepairer and v.honor_wallrepairer == inst then
            v.honor_wallrepairer = nil -- 清除修复者
        end
    end
    inst:Remove() -- 移除当前实例
end

local function itemfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("wallbuilder")

    inst.AnimState:SetBank("wall")
    inst.AnimState:SetBuild("honor_wall")
    inst.AnimState:PlayAnimation("idle")

    --inst.AnimState:SetSymbolLightOverride("wall_segment_red", 1) -- 设置光效

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial = "potato"
    inst.components.repairer.healthrepairvalue = 30

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploywall
    inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)

    MakeHauntableLaunch(inst)

    return inst
end

local function onhit(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")

    local healthpercent = inst.components.health:GetPercent()
    if healthpercent > 0 then
        local anim_to_play = resolveanimtoplay(inst, healthpercent)
        inst.AnimState:PlayAnimation(anim_to_play.."_hit")
        inst.AnimState:PushAnimation(anim_to_play, false)
    end
end

local function onrepaired(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")
    makeobstacle(inst)
end

local function OnAccept(inst, item, giver)
    inst.level = 2
    inst.components.trader:Disable()
    DeltaHealth(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetEightFaced()

    inst:SetDeploySmartRadius(0.5)

    MakeObstaclePhysics(inst, .5)
    inst.Physics:SetDontRemoveOnSleep(true)

    --inst.Transform:SetScale(1.3,1.3,1.3) -- 可选，设置缩放
    --inst.AnimState:SetMultColour(s, s, s, 1) -- 设置颜色

    inst:AddTag("wall")
    inst:AddTag("noauradamage") -- 添加不受气场伤害标签

    inst.AnimState:SetBank("wall")
    inst.AnimState:SetBuild("honor_wall")
    inst.AnimState:PlayAnimation("half")

    MakeSnowCoveredPristine(inst)

    inst._pfpos = nil -- 初始化路径点为 nil
    inst._ispathfinding = net_bool(inst.GUID, "_ispathfinding", "onispathfindingdirty") -- 初始化路径寻找状态变量
    makeobstacle(inst)
    --推迟此操作，因为创建障碍会根据默认设置路径寻找
    -- 但我们希望在实体位置设置后再处理它
    inst:DoTaskInTime(0, InitializePathFinding) -- 延迟初始化路径查找

    inst.OnRemoveEntity = onremove -- 设置移除实体时的回调（更新寻路）

    inst.entity:SetPristine()
    inst.level = 1

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_specialinfo = "WALLS"
    inst.scrapbook_anim = "half"

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = "potato"
    inst.components.repairable.onrepaired = onrepaired
    inst.components.repairable.testvalidrepairfn = ValidRepairFn

    inst:AddComponent("combat")
    inst.components.combat:SetKeepTargetFunction(keeptargetfn) -- 设置保持目标函数始终为false
    inst.components.combat.onhitfn = onhit

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)
    inst.components.health:SetCurrentHealth(100)
    inst.components.health.ondelta = onhealthchange
    inst.components.health.nofadeout = true
    inst.components.health.canheal = false
    inst.components.health:SetAbsorptionAmountFromPlayer(0.2) -- 设置玩家伤害修正(0~1)
    inst.components.health.fire_damage_scale = 0 -- 不受火焰伤害

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(function(inst, item, giver)
        return item.prefab == "potato"
    end)
    inst.components.trader.onaccept = OnAccept

    MakeHauntableWork(inst)
    inst.OnLoad = onload

    MakeSnowCovered(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("honor_wall", fn, assets, prefabs),
    Prefab("honor_wall_item", itemfn, assets, { "honor_wall_item", "honor_wall_item_placer" }),
    MakePlacer("honor_wall_item_placer", "wall", "honor_wall", "half", false, false, true, nil, nil, "eight")
