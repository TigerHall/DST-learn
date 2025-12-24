--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


    蒲公英

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_dandycat"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_dandycat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 采集：使用pickable
    local function remove_pickable(inst)
        if inst.components.pickable then
            -- inst:RemoveComponent("pickable")
            inst.components.pickable:Pause()
        end
    end
    local function onpickedfn(inst,picker,loot)
        inst.components.growable:SetStage(1)
        inst.components.lootdropper:SetLoot(nil)
        inst.components.growable:StartGrowing()
        inst:PushEvent("plant_picked_by",picker)
        inst.components.pickable:MakeEmpty()
        inst.components.pickable:Pause()
    end
    local function install_pickable(inst)
        remove_pickable(inst)
        if inst.components.pickable == nil then
            inst:AddComponent("pickable")
        end
        -- inst.components.pickable:Regen()
        inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
        inst.components.pickable.onpickedfn = onpickedfn            --- 采集之后执行
        inst.components.pickable:SetUp("berries",TUNING.BERRY_REGROW_TIME)
        inst.components.pickable.use_lootdropper_for_product = true -- 以掉落列表形式生成产物
        inst.components.pickable.paused = true -- 这个组件不负责成长。
        local num = math.random(2,4)
        local _loot = {}
        for i = 1, num, 1 do
            table.insert(_loot, "tbat_material_dandycat")
        end
        -- inst.components.lootdropper:SetLoot({"berries","berries","berries"})
        inst.components.lootdropper:SetLoot(_loot)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 生长
    local function grow_time_by_step(inst,step)
        if TBAT.DEBUGGING then
            return 1*TUNING.TOTAL_DAY_TIME
        end
        return 3*TUNING.TOTAL_DAY_TIME
    end
    local growable_stages = {
        --[[        
            【笔记】 fn 先执行，再执行growfn ，onload的时候只执行 fn
        ]]--
        {
            name = "stage_1",     --- 
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("stage_1",true)
                -- remove_pickable(inst)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("stage_1",true)
                remove_pickable(inst)
                inst:PushEvent("stage_acitve",1)
            end,
        },
        {
            name = "stage_2",     --- 
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("stage_1_to_2")
                inst.AnimState:PushAnimation("stage_2",true)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
                -- remove_pickable(inst)
                inst:PushEvent("grow_to",2)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("stage_2",true)
                remove_pickable(inst)
                inst:PushEvent("stage_acitve",2)
            end,
        },
        {
            name = "stage_3",     --- 
            time = function(inst) return grow_time_by_step(inst,2) end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("stage_2_to_3")
                inst.AnimState:PushAnimation("stage_3",true)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
                -- install_pickable(inst)
                inst:PushEvent("grow_to",3)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("stage_3",true)
                install_pickable(inst)
                inst:PushEvent("stage_acitve",3)
            end,
        },
        

    }
    local function grow_init(inst_or_com)
        local inst = inst_or_com
        if inst_or_com.inst then
            inst = inst_or_com.inst
        end
        if inst.components.growable:GetStage() ~= 3 then
            inst.components.growable:StartGrowing()
        else
            inst.components.growable:StopGrowing()
        end
    end
    local function growable_com_install(inst)
        inst:AddComponent("growable")
        inst.components.growable.stages = growable_stages
        inst.components.growable:SetStage(1)
        inst.components.growable.loopstages = false
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        inst.components.growable.magicgrowable = false
        inst:DoTaskInTime(0,grow_init)
        inst.components.tbat_data:AddOnLoadFn(grow_init)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 挖掘
    local function dig_remove_event(inst)
        inst.components.tbat_data:Set("block_dig",true) 
        if inst.components.workable then
            inst:RemoveComponent("workable")
        end
    end
    local function dig_remove_onload(com)
        if com:Get("block_dig") then
            dig_remove_event(com.inst)
        end
    end
    local function onhammered(inst,worker)
        inst.components.lootdropper:SpawnLootPrefab(this_prefab.."_kit")
        inst:Remove()
    end
    local function dig_com_install(inst)
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onhammered)
        -- inst.components.workable:SetOnWorkCallback(onhit)
        inst:ListenForEvent("block_dig",dig_remove_event)
        inst.components.tbat_data:AddOnLoadFn(dig_remove_onload)
    end    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 种植
    local function on_plant_event(inst,cmd)
        inst.Transform:SetPosition(cmd.pt.x,0,cmd.pt.z)
        local stage = cmd.stage or 1
        if cmd.wild then
            inst:PushEvent("block_dig")
            stage = 3            
        else
            inst.components.tbat_data:Set("transplanted",true)
        end

        inst.components.growable:SetStage(stage)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 核心逻辑
    local main_logic_install = require("prefabs/09_tbat_plants/07_02_dandycat_logic")    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function plant_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.MEDIUM] / 2) --plantables deployspacing/2


        inst.AnimState:SetBank("tbat_plant_dandycat")
        inst.AnimState:SetBuild("tbat_plant_dandycat")
        inst.AnimState:PlayAnimation("stage_1",true)

        inst:AddTag("tbat_plant_dandycat")

        inst.entity:SetPristine()
        -----------------------------------------------
        ---
            if inst.components.tbat_data == nil then
                inst:AddComponent("tbat_data")
            end
        -----------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------------
        ---
            inst:AddComponent("lootdropper")
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        -----------------------------------------------
        --- 生长
            growable_com_install(inst)
        -----------------------------------------------
        --- 
            dig_com_install(inst)
        -----------------------------------------------
        ---
            inst:ListenForEvent("on_plant",on_plant_event)
        -----------------------------------------------
        ---
            main_logic_install(inst)
        -----------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- item
    local function on_deploy(inst, pt, deployer)
        inst.components.stackable:Get():Remove()
        SpawnPrefab(this_prefab):PushEvent("on_plant",{
            pt = pt,
        })
    end
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:PlayAnimation("item_water")
        else
            inst.AnimState:PlayAnimation("item")
        end
    end
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_plant_dandycat")
        inst.AnimState:SetBuild("tbat_plant_dandycat")
        inst.AnimState:PlayAnimation("item")
        -- inst:AddTag("usedeploystring")
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        -----------------------------------------
        ---
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_plant_dandycat_kit","images/inventoryimages/tbat_plant_dandycat_kit.xml")
            MakeHauntableLaunch(inst)
        -----------------------------------------
        ---落水处理
            inst:ListenForEvent("on_landed",shadow_init)
            shadow_init(inst)
        -----------------------------------------
        ---
            inst:AddComponent("stackable")
        -----------------------------------------
        ---
            inst:AddComponent("deployable")
            -- inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
            inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
            inst.components.deployable.ondeploy = on_deploy
        -----------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- placer
    local function placer_postinit_fn(inst)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- mark
    local function mark_init(inst)
        if not inst.ready then
            inst:Remove()
        end
    end
    local function random_point(inst,cmd)
        -- cmd = {
        --     target = target, -- Vector3() -- inst :做多态和缺省。
        --     radius = radius,
        --     num = num,
        -- }
        local pt = nil
        if cmd.target then
            if cmd.target.x then
                pt = cmd.target
            elseif cmd.target.Transform then
                pt = Vector3(cmd.target.Transform:GetWorldPosition())
            end
        end
        if pt == nil then
            pt = Vector3(inst.Transform:GetWorldPosition())
        end
        local num = math.max(cmd.num or 8,8)
        local points = TBAT.FNS:GetSurroundPoints({
            pt = pt,
            range = cmd.radius or 8,
            num = num,
        })
        local ret_pt = points[math.random(#points)]
        inst.Transform:SetPosition(ret_pt.x,0,ret_pt.z)
        inst.ready = true
    end
    local function mark_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        if TBAT.DEBUGGING then
            inst.AnimState:SetBank("cane")
            inst.AnimState:SetBuild("swap_cane")
            inst.AnimState:PlayAnimation("idle")
        end

        inst:AddTag("FX")
        inst:AddTag("NOBLOCK")
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")        

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(0)
        inst:ListenForEvent("random_update",random_point)
        inst:DoTaskInTime(0,mark_init)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab,plant_fn,assets),
        Prefab(this_prefab.."_kit",item_fn,assets),
        MakePlacer(this_prefab.."_kit_placer",this_prefab,this_prefab,"stage_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil),
        Prefab(this_prefab.."_mark",mark_fn)