--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    require "prefabutil"
    local assets =
    {
        Asset("ANIM", "anim/butterfly_basic.zip"),
        Asset("ANIM", "anim/tbat_animal_ephemeral_butterfly.zip"),
    }
    local brain = require "brains/05_tbat_animal_ephemeral_butterfly_brain"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 丢弃
    local function OnDropped(inst)
        inst.sg:GoToState("idle")
        if inst.butterflyspawner ~= nil then
            inst.butterflyspawner:StartTracking(inst)
        end
        if inst.components.workable ~= nil then
            inst.components.workable:SetWorkLeft(1)
        end
        if inst.components.stackable ~= nil then
            while inst.components.stackable:StackSize() > 1 do
                local item = inst.components.stackable:Get()
                if item ~= nil then
                    if item.components.inventoryitem ~= nil then
                        item.components.inventoryitem:OnDropped()
                    end
                    item.Physics:Teleport(inst.Transform:GetWorldPosition())
                end
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 拾取
    local function OnPickedUp(inst)
        inst.flower = nil
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 抓捕
    local function OnWorked(inst, worker)
        if worker.components.inventory ~= nil then
            if inst.butterflyspawner ~= nil then
                inst.butterflyspawner:StopTracking(inst)
            end
            worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
            worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 种植
    local function OnDeploy(inst, pt, deployer)
        SpawnPrefab("tbat_plant_ephemeral_flower").Transform:SetPosition(pt:Get())
        if deployer and deployer.SoundEmitter then
            deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
        end
        inst.components.stackable:Get():Remove()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 飞走
    local function fly_out_event(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local rotation = inst.Transform:GetRotation()
        local fx = SpawnPrefab("tbat_animal_ephemeral_butterfly_fx")
        fx.Transform:SetPosition(x,y,z)
        fx.Transform:SetRotation(rotation)
        inst:Remove()
    end
    local function fly_out_install(inst)
        inst:ListenForEvent("cmd_fly_out", fly_out_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 灯光控制
    local LIGHT_RADIUS = .5
    local LIGHT_INTENSITY = .5
    local LIGHT_FALLOFF = .8

    local function OnUpdateFlicker(inst, starttime)
        local time = starttime ~= nil and (GetTime() - starttime) * 15 or 0
        local flicker = math.sin(time * 0.7 + math.sin(time * 6.28)) -- range = [-1 , 1]
        flicker = (1 + flicker) * .5 -- range = 0:1
        inst.Light:SetIntensity(LIGHT_INTENSITY + .05 * flicker)
    end
    local function light_com_install(inst)
        inst.entity:AddLight()
        inst.Light:SetFalloff(LIGHT_FALLOFF)
        inst.Light:SetIntensity(LIGHT_INTENSITY)
        inst.Light:SetRadius(LIGHT_RADIUS)
        -- inst.Light:SetColour(0.3, 0.55, 0.45)
        inst.Light:SetColour(153/255,51/255,255/255)
        inst.Light:Enable(true)
        inst.Light:EnableClientModulation(true)
        inst:DoPeriodicTask(.1, OnUpdateFlicker, nil, GetTime())
        OnUpdateFlicker(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 拖尾特效
    local function fly_tail_fx_install(inst)
        local fx = SpawnPrefab("cane_victorian_fx")
        fx.entity:SetParent(inst.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(inst.GUID, "butterfly_body", 0,0,0)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 通用
    local function common_fn()
        local inst = CreateEntity()
        --Core components
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddDynamicShadow()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        --Initialize physics
        MakeTinyFlyingCharacterPhysics(inst, 1, .5)
        inst:AddTag("butterfly")
        inst:AddTag("flying")
        inst:AddTag("ignorewalkableplatformdrowning")
        inst:AddTag("insect")
        inst:AddTag("smallcreature")
        inst:AddTag("cattoyairborne")
        inst:AddTag("wildfireprotected")
        inst:AddTag("deployedplant")
        inst:AddTag("noember")
        inst:AddTag("tbat_animal_ephemeral_butterfly")
        inst.Transform:SetTwoFaced()
        inst.AnimState:SetBuild("tbat_animal_ephemeral_butterfly")
        inst.AnimState:SetBank("butterfly")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetRayTestOnBB(true)
        local scale = 0.3 * 1.5
        inst.AnimState:SetScale(scale,scale,scale)
        inst.DynamicShadow:SetSize(.8, .5)
        MakeInventoryFloatable(inst)
        MakeFeedableSmallLivestockPristine(inst)
        light_com_install(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 本体
    local function animal_fn()
        local inst = common_fn()
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        --------------------------------------------------------------------------
        --- 马达
            inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            inst.components.locomotor:SetTriggersCreep(false)
        --------------------------------------------------------------------------
        --- SG
            inst:SetStateGraph("SGbutterfly")
            inst.sg.mem.burn_on_electrocute = true
        --------------------------------------------------------------------------
        --- 物品叠堆        
            inst:AddComponent("stackable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_animal_ephemeral_butterfly","images/inventoryimages/tbat_animal_ephemeral_butterfly.xml")
            inst.components.inventoryitem.canbepickedup = false
            inst.components.inventoryitem.canbepickedupalive = true
            inst.components.inventoryitem.nobounce = true
            inst.components.inventoryitem.pushlandedevents = false
        --------------------------------------------------------------------------
        --- 战斗、血量
            inst:AddComponent("health")
            inst.components.health:SetMaxHealth(1)        
            inst:AddComponent("combat")
            inst.components.combat.hiteffectsymbol = "butterfly_body"
        --------------------------------------------------------------------------
        --- 位置记忆器
            inst:AddComponent("knownlocations")
        --------------------------------------------------------------------------
        --- 可燃、着火、惊恐
            MakeSmallBurnableCharacter(inst, "butterfly_body")
            MakeHauntablePanicAndIgnite(inst)
        --------------------------------------------------------------------------
        --- 冻结
            -- MakeTinyFreezableCharacter(inst, "butterfly_body")
        --------------------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------------------
        --- 掉落
            inst:AddComponent("lootdropper")
            -- inst.components.lootdropper:AddRandomLoot("butter", 0.1)
            -- inst.components.lootdropper:AddRandomLoot("butterflywings", 5)
            -- inst.components.lootdropper.numrandomloot = 1
            inst.components.lootdropper:SetLoot({"tbat_food_ephemeral_flower","tbat_food_ephemeral_flower_butterfly_wings"})
        --------------------------------------------------------------------------
        --- 捕虫网
            inst:AddComponent("workable")
            inst.components.workable:SetWorkAction(ACTIONS.NET)
            inst.components.workable:SetWorkLeft(1)
            inst.components.workable:SetOnFinishCallback(OnWorked)
        --------------------------------------------------------------------------
        --- 交易
            inst:AddComponent("tradable")
        --------------------------------------------------------------------------
        --- 种植
            inst:AddComponent("deployable")
            inst.components.deployable.ondeploy = OnDeploy
            inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
        --------------------------------------------------------------------------
        --- 脑子
            inst:SetBrain(brain)
        --------------------------------------------------------------------------
        --- 落地、拾取
            MakeFeedableSmallLivestock(inst, TUNING.BUTTERFLY_PERISH_TIME, OnPickedUp, OnDropped)
        --------------------------------------------------------------------------
        --- 飞走
            fly_out_install(inst)
        --------------------------------------------------------------------------
        --- 拖尾特效
            fly_tail_fx_install(inst)
        --------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 用来拆分离开用的特效。彻底摆脱物理引擎和AI交叉导致的往上飞的过程出问题。
    local function flyout_task(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if y >= 20 then
            inst:Remove()
        end
    end
    local function leave_fx()
        local inst = common_fn()
        inst.AnimState:PlayAnimation("shock_loop",true)
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddTag("NOCLICK")
        inst.Physics:Stop()
        local fly_out_speed = 6
        inst.Physics:SetMotorVel(0,0,0)
        inst.Physics:SetMotorVelOverride(0,fly_out_speed,0)
        inst.Physics:SetMotorVel(0,fly_out_speed,0)
        inst.Physics:Teleport(inst.Transform:GetWorldPosition())
        inst.DynamicShadow:Enable(false)
        inst:DoPeriodicTask(0.1,flyout_task)
        fly_tail_fx_install(inst)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 放置
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle"..math.random(4))        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_animal_ephemeral_butterfly", animal_fn, assets),
    MakePlacer("tbat_animal_ephemeral_butterfly_placer","tbat_plant_ephemeral_flower","tbat_plant_ephemeral_flower", "idle1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil),
    Prefab("tbat_animal_ephemeral_butterfly_fx", leave_fx)

