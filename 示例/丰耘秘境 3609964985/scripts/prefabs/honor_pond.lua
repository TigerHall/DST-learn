require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/honor_pond.zip"),
    Asset("ANIM", "anim/splash.zip"),
}

local prefabs_normal =
{
    "marsh_plant",
    "pondfish",
    "frog",
}

local function SpawnPlants(inst)
    inst.task = nil

    if inst.plant_ents ~= nil then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 1.5)
    local marsh_plant_count = 0

    for k, v in pairs(ents) do
        if v.prefab == "rocks" or v.prefab == "monkeytail" or v.prefab == "cavein_boulder" or v.prefab == "evergreen" or v.prefab == "deciduoustree" then
            v:Remove()
        elseif v.prefab == "marsh_plant" then
            marsh_plant_count = marsh_plant_count + 1
            if marsh_plant_count >= 2 then
                v:Remove()
            end
        end
    end

    if inst.plants == nil then
        inst.plants = {}

        for _ = 1, math.random(14, 18) do
            local theta = math.random() * TWOPI -- 随机生成角度
            -- 将植物的位置偏移量插入植物列表
            table.insert(inst.plants,
            {
                offset =
                {
                    math.sin(theta) * 1.9 + math.random() * .3, -- 计算x轴偏移
                    0, -- y轴偏移设为0
                    math.cos(theta) * 2.1 + math.random() * .3, -- 计算z轴偏移
                },
            })
        end
    end

    -- 初始化植物实体列表
    inst.plant_ents = {}

    -- 遍历每个植物并生成实际植物实体
    for i, v in pairs(inst.plants) do
        if type(v.offset) == "table" and #v.offset == 3 then

            -- 选择场景
            local plant = nil
            local rand = math.random()

            if rand < 0.8 then
                plant = SpawnPrefab("rocks")
            elseif rand < 0.95 then
                plant = SpawnPrefab("marsh_plant")
            elseif rand < 0.97 then
                plant = SpawnPrefab("monkeytail")
            elseif rand < 0.98 then
                plant = SpawnPrefab("cavein_boulder")
            elseif rand < 0.99 then
                plant = SpawnPrefab("evergreen")
            else
                plant = SpawnPrefab("deciduoustree")
            end

            -- 如果生成位置在池塘上，则不生成
            local ex, ey, ez = v.offset[1] + x, v.offset[2] + y, v.offset[3] + z
            local pound = TheSim:FindEntities(ex, ey, ez, 1.7, "honor_pond")
            if #pound > 1 then -- 排除自身
                for j, p in ipairs(pound) do
                    if p ~= inst and p:HasTag("honor_pond") then
                        local px, py, pz = p.Transform:GetWorldPosition()
                        local r = p.Physics and p.Physics:GetRadius() or nil
                        if (ex - px)^2 + (ey - py)^2 + (ez - pz)^2 < (r or 1.7)^2 then
                            plant = nil
                        end
                    end
                end
            end

            if plant ~= nil then
                plant.entity:SetParent(inst.entity)
                plant.Transform:SetPosition(unpack(v.offset))
                plant.persists = false
                table.insert(inst.plant_ents, plant)
            end
        end
    end
end

local function DespawnPlants(inst)
    if inst.plant_ents ~= nil then
        for i, v in ipairs(inst.plant_ents) do
            if v:IsValid() then
                v:Remove()
            end
        end

        inst.plant_ents = nil
    end

    inst.plants = nil
end

local function SlipperyRate(inst, target)
    local speed = target.Physics and target.Physics:GetMotorSpeed() or 0
    if speed > TUNING.WILSON_RUN_SPEED then
        return 50
    end

    return 5
end

local function OnSnowLevel(inst, snowlevel)
    -- 检查雪覆盖层是否超过阈值
    if snowlevel > .02 then
        -- 如果当前未被冻结
        if not inst.frozen then
            inst.frozen = true  -- 设置为被冻结状态
            inst.AnimState:PlayAnimation("frozen")  -- 播放冻结动画
            inst.SoundEmitter:PlaySound("dontstarve/winter/pondfreeze")  -- 播放冻结声效

            inst.components.fishable:Freeze()  -- 将可钓鱼组件设置为冻结状态

            inst.Physics:SetCollisionGroup(COLLISION.LAND_OCEAN_LIMITS)  -- 设置物理碰撞组
            inst.Physics:ClearCollisionMask()  -- 清除碰撞掩膜
            inst.Physics:CollidesWith(COLLISION.WORLD)  -- 与世界碰撞
            inst.Physics:CollidesWith(COLLISION.ITEMS)  -- 与物品碰撞

            --DespawnPlants(inst)  -- 移除植物

            inst.components.watersource.available = false  -- 设置水源不可用
            local slipperyfeettarget = inst:AddComponent("slipperyfeettarget")  -- 添加滑溜脚目标组件
            slipperyfeettarget:SetSlipperyRate(SlipperyRate)  -- 设置滑溜速率
        end
    -- 如果当前被冻结状态，并且雪覆盖层降低
    elseif inst.frozen then
        inst.frozen = false  -- 取消冻结状态
        inst.AnimState:PlayAnimation("idle", true)  -- 播放空闲动画
        --inst.components.childspawner:StartSpawning()  -- 开始生成子物体（注释掉了）
        inst.components.fishable:Unfreeze()  -- 将可钓鱼组件恢复为可用状态

        inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)  -- 恢复物理碰撞组
        inst.Physics:ClearCollisionMask()  -- 清除碰撞掩膜
        inst.Physics:CollidesWith(COLLISION.ITEMS)  -- 与物品碰撞
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)  -- 与角色碰撞
        inst.Physics:CollidesWith(COLLISION.GIANTS)  -- 与巨人碰撞

        SpawnPlants(inst)  -- 重新生成植物

        inst.components.watersource.available = true  -- 设置水源可用
        inst:RemoveComponent("slipperyfeettarget")  -- 移除滑溜脚目标组件
    -- 如果被冻结状态尚未定义
    elseif inst.frozen == nil then
        inst.frozen = false  -- 默认设置为未冻结状态
        SpawnPlants(inst)  -- 生成植物
    end
end


local function OnSave(inst, data)
    data.plants = inst.plants
    data.nitreformations = inst.nitreformations
end

local function OnLoad(inst, data)
    if data ~= nil then
        if inst.task ~= nil and inst.plants == nil then
            inst.plants = data.plants
        end
    end
end

local function OnInit(inst)
    inst.task = nil
    --inst:WatchWorldState("isday", OnIsDay)
    inst:WatchWorldState("snowlevel", OnSnowLevel)
    --OnIsDay(inst, TheWorld.state.isday)
    OnSnowLevel(inst, TheWorld.state.snowlevel)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakePondPhysics(inst, 1.5)

    inst.AnimState:SetBuild("honor_pond")
    inst.AnimState:SetBank("honor_pond")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    inst.MiniMapEntity:SetIcon("pond.png")

    -- From watersource component
    inst:AddTag("watersource")
    inst:AddTag("pond")
    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")
    inst:AddTag("honor_pond")

    inst.no_wet_prefix = true

	inst:SetDeploySmartRadius(2)

    inst.entity:SetPristine()


    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "pond"

    inst:AddComponent("fishable")
    inst.components.fishable:SetRespawnTime(TUNING.FISH_RESPAWN_TIME)
    inst.components.fishable:AddFish("pondfish")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("watersource")

    inst.dayspawn = true
    inst.task = inst:DoTaskInTime(0, OnInit)

    --inst.OnPreLoad = OnPreLoadFrog

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab( "honor_pond", fn, assets, prefabs_normal )
