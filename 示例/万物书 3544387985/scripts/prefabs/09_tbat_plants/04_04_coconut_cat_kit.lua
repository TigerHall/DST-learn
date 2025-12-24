--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_coconut_cat_kit"
    local anim_scale = 2
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_coconut_cat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 浇水+灭火
    -- local NOTAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "player", "monster" }
    local NOTAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "player" }
    local ONEOFTAGS = { "fire", "smolder" ,"plant","structure"}
    local RANDOM_OFFSET_MAX = TUNING.WATERPUMP.MAXRANGE
    local PUMP_WORK_RANGE = 17        
    local easing = require("easing")
    local function spawn_project_for_pos(start_pos,targetpos,attacker,owningweapon)
        local x,y,z = start_pos.x,start_pos.y,start_pos.z
        local projectile = SpawnPrefab("waterstreak_projectile")
        projectile.Transform:SetPosition(x, 5, z)
        local dx = targetpos.x - x
        local dz = targetpos.z - z
        local rangesq = dx * dx + dz * dz
        local maxrange = PUMP_WORK_RANGE
        local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
        projectile.components.complexprojectile:SetHorizontalSpeed(speed)
        projectile.components.complexprojectile:SetGravity(-25)
        projectile.components.complexprojectile:Launch(targetpos, attacker, owningweapon)
    end
    local function LaunchProjectile(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        if true then
            local ents = TheSim:FindEntities(x, y, z, PUMP_WORK_RANGE, nil, NOTAGS, ONEOFTAGS)
            local targetpos
            -- print("ents",#ents)
            if #ents == 0 then
                -- targetpos = ents[1]:GetPosition()
                targetpos = Vector3(x,y,z)
                spawn_project_for_pos(targetpos,targetpos,inst,inst)
            else
                local start_pos = Vector3(x,y,z)
                for i, tempInst in ipairs(ents) do
                    tempInst:DoTaskInTime(i*FRAMES*2,function()
                        spawn_project_for_pos(start_pos,tempInst:GetPosition(),inst,inst)
                    end)
                end
            end

        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 右键使用
    local function create_indicator(inst,doer)
        if not (ThePlayer and ThePlayer:IsValid() ) then
            return
        end

        if inst.indicator and inst.indicator:IsValid() then
            inst.indicator.time = 0
            return
        end
        local indicator = ThePlayer:SpawnChild("tbat_sfx_dotted_circle_client")
        indicator:PushEvent("Set",{ radius = PUMP_WORK_RANGE })
        inst.indicator = indicator
        local update_time = 0.3
        indicator:DoPeriodicTask(update_time,function()
            indicator.time = (indicator.time or 0) + update_time
            if indicator.time > 1 then
                indicator:Remove()
            end
        end)
        indicator:ListenForEvent("onremove",function()
            indicator:Remove()
        end,inst)
    end
    local function workable_test_fn(inst,doer,right_click)
        local ret = inst.replica.inventoryitem:IsGrandOwner(doer)
        create_indicator(inst,doer)
        if ret then
            return true
        else
            return false
        end
    end
    local function workable_on_work_fn(inst,doer)
        inst.components.stackable:Get():Remove()
        LaunchProjectile(doer)
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.POUR_WATER.GENERIC)
        replica_com:SetSGAction("dolongaction")
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 部署
    local function on_deploy(inst, pt, deployer)
        inst.components.stackable:Get():Remove()
        SpawnPrefab("tbat_plant_coconut_cat"):PushEvent("deploy",{
            deployer = deployer,
            pt = pt,
        })        
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
        inst.AnimState:SetBank("tbat_plant_coconut_cat")
        inst.AnimState:SetBuild("tbat_plant_coconut_cat")
        inst.AnimState:PlayAnimation("stage_2",true)
        inst:AddTag("usedeploystring")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.AnimState:SetScale(anim_scale,anim_scale)
        inst.entity:SetPristine()
        -----------------------------------------
        --- 可交互
            workable_install(inst)
        -----------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_plant_coconut_cat_kit","images/inventoryimages/tbat_plant_coconut_cat_kit.xml")
            MakeHauntableLaunch(inst)
        -----------------------------------------
        ---
            TBAT.FNS:ShadowInit(inst)
        -----------------------------------------
        ---
            inst:AddComponent("stackable")
        -----------------------------------------
        ---
            inst:AddComponent("deployable")
            -- inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
            inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
            inst.components.deployable.ondeploy = on_deploy
            -- inst.components.deployable:SetDeploySpacing(0.1)
        -----------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("stage_2",true)
        local fx = inst:SpawnChild("tbat_sfx_dotted_circle_client")
        fx:PushEvent("Set",{ radius = 12 })
        inst.AnimState:SetScale(anim_scale,anim_scale)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Prefab(this_prefab, fn, assets),
    MakePlacer(this_prefab.."_placer","tbat_plant_coconut_cat","tbat_plant_coconut_cat", "stage_2", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

