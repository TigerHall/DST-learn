--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_projectile_dandelion_umbrella"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_material_dandelion_umbrella.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 弹药系统
    local function OnHit(inst, attacker, target)
        inst:PushEvent("OnHit",target)
        target:PushEvent("HitBy",inst)
        inst.pause_time = math.random(5)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- start follow event
    local function following_task(inst)
        if not inst.ready then
            inst:Remove()
            return
        end
        inst.pause_time = inst.pause_time or 0
        if inst.target and inst.target:IsValid() then
            if inst.pause_time == 0 then
                inst.components.projectile:Throw(inst,inst.target,inst.target)
            else
                inst.pause_time = inst.pause_time - 1
            end
        else
            inst:Remove()
        end
    end
    local function start_following(inst,cmd)
        local target = cmd.target
        if target then
            inst.target = target
        end
        local speed = cmd.speed
        if speed then
            inst.components.projectile:SetSpeed(speed + math.random())
        end
        inst.ready = true
        following_task(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- work
    local function onworked(inst, worker)
        if worker.components.inventory ~= nil then
            worker.components.inventory:GiveItem(SpawnPrefab("tbat_material_dandelion_umbrella"), nil, inst:GetPosition())
            inst:Remove()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- fly out event
    local function fly_out_event(inst)
        inst.AnimState:PlayAnimation("flyout",false)
        inst:ListenForEvent("animover",inst.Remove)
        if inst.components.workable then
            inst:RemoveComponent("workable")
        end
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst:AddTag("FX")
        inst:AddTag("fx")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("tbat_material_dandelion_umbrella")
        inst.AnimState:SetBuild("tbat_material_dandelion_umbrella")
        inst.AnimState:PlayAnimation("fly",true)
        inst.AnimState:SetTime(1.5*math.random())
        -----------------------------------------------------------------
        --- 影子
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(.5, .5)
        -----------------------------------------------------------------
        --- 物理参数配置
            MakeInventoryPhysics(inst)
            RemovePhysicsColliders(inst)
        -----------------------------------------------------------------
        --- tag
            inst:AddTag("projectile")
            inst:AddTag("structure")
            inst:AddTag("NOBLOCK")      -- 不会影响种植和放置
        -----------------------------------------------------------------
        ---
            inst.Transform:SetTwoFaced()
        -----------------------------------------------------------------
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end


        inst:AddComponent("inspectable")
        -----------------------------------------------------------------
        --- 弹药系统
            -- inst:AddComponent("weapon")
            -- inst.components.weapon:SetDamage(0)
            inst:AddComponent("projectile")
            inst.components.projectile:SetSpeed(20)
            inst.components.projectile:SetHoming(false)
            inst.components.projectile:SetHitDist(1.5)
            inst.components.projectile:SetOnHitFn(OnHit)
        -----------------------------------------------------------------
        ---
            inst:ListenForEvent("follow",start_following)
            inst:DoPeriodicTask(1,following_task)
            inst:ListenForEvent("flyout",fly_out_event)
        -----------------------------------------------------------------
        --- 
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.NET)
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnFinishCallback(onworked)
        -----------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
