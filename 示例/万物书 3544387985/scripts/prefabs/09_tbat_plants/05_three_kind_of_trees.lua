--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    梨花树+樱花树

    四个阶段：
    burnt , stump ,small_tree ,tree

    burnt : 被烧焦。不可继续成长。只能砍伐。不可燃。
    stump : 树干。30天后变小树。只能挖掘。燃烧出碳
    small_tree : 小树。3天后变树。可燃（小），只能挖掘。燃烧出灰。
    tree : 树。可燃（大），只能砍伐。切换到burnt。


    动画：
    item
    item_water


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 阶段参数
    local TREE_STAGE = {
        [1] = "burnt",
        [2] = "stump",
        [3] = "small_tree",
        [4] = "tree",
        ["burnt"] = 1,
        ["stump"] = 2,
        ["small_tree"] = 3,
        ["tree"] = 4,
    }
    local function get_current_stage(inst)
        return inst.components.growable:GetStage()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable
    local function remove_workable(inst)
        if inst.components.workable then
            inst:RemoveComponent("workable")
        end
    end
    local function chop_OnFinishCallback(inst,worker)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
        if not (worker ~= nil and worker:HasTag("playerghost")) then
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
        end
        if inst.tree_chop_finish_fn then
            inst.tree_chop_finish_fn(inst,worker)
        end
        if not inst:HasTag("burnt") then
            if inst:IsValid() and TREE_STAGE[get_current_stage(inst)] == "tree" then
                inst.components.growable:SetStage(TREE_STAGE["stump"])
                inst.components.growable:StopGrowing()
                inst.components.growable:StartGrowing()
            end
        else
            inst.AnimState:PlayAnimation("chop_burnt_normal",false)
            inst:ListenForEvent("animover",inst.Remove)
        end
    end
    local function chop_onhit(inst,worker)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
        if not (worker ~= nil and worker:HasTag("playerghost")) then
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
        end
        if inst.chop_onhit then
            inst.chop_onhit(inst,worker)
        end
        if not inst:HasTag("burnt") then
            if inst.fx_prefab and PrefabExists(inst.fx_prefab) then
                local fx = SpawnPrefab(inst.fx_prefab)
                fx:PushEvent("Set",{
                    pt = Vector3(inst.Transform:GetWorldPosition()),
                    anim = "chop",
                    scale = 1.5,
                    remove = true
                })
            end
            inst.AnimState:PlayAnimation("chop_normal",false)
            inst.AnimState:PushAnimation("sway2_normal",true)
        else

        end
    end
    local function install_chop(inst)
        remove_workable(inst)
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetWorkLeft(inst:HasTag("burnt") and 1 or 5)
        inst.components.workable:SetOnFinishCallback(chop_OnFinishCallback)
        inst.components.workable:SetOnWorkCallback(chop_onhit)
    end
    local function dig_OnFinishCallback(inst,worker)
        if inst.tree_dig_finish_fn then
            inst.tree_dig_finish_fn(inst,worker)
        end
    end
    local function install_dig(inst)
        remove_workable(inst)
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(dig_OnFinishCallback)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- burnt
    local function onburntup(inst)
        local stage = get_current_stage(inst)
        if TREE_STAGE[stage] == "stump" then
            inst.components.lootdropper:SpawnLootPrefab("charcoal")
            inst:Remove()
            return
        end
        if TREE_STAGE[stage] == "small_tree" then
            inst:Remove()
            return
        end
        if TREE_STAGE[stage] == "tree" then
            inst.components.lootdropper:SpawnLootPrefab("charcoal")
            inst.components.growable:SetStage(TREE_STAGE["burnt"])
            return
        end
    end
    local function uninstall_burnt(inst)
        if inst.components.burnable then
            inst:RemoveComponent("burnable")
        end
        if inst.components.propagator then
            inst:RemoveComponent("propagator")
        end
        inst:RemoveEventCallback("burntup",onburntup)
    end
    local function install_burnt(inst,small)
        uninstall_burnt(inst)
        if small then
            MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
            MakeSmallPropagator(inst)
        else
            MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
            inst.components.burnable:SetFXLevel(5)
            inst.components.burnable:SetOnBurntFn(onburntup)
            MakeMediumPropagator(inst)
        end
        inst:ListenForEvent("burntup", onburntup)   --- 烧完
        -- inst:ListenForEvent("onignite", onignite)   --- 冒烟
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 特效
    local function create_fx_origin(inst)
        if inst.fx then
            inst.fx:Remove()
            inst.fx = nil            
        end
        if inst.fx2 then
            inst.fx2:Remove()
            inst.fx2 = nil            
        end
        if inst.fx_prefab and PrefabExists(inst.fx_prefab) then
            local speed = 0.8
            local fx = inst:SpawnChild(inst.fx_prefab)
            fx:PushEvent("Set",{pt = Vector3(0,1.5,0),anim = "fall",scale = 1.5,remove = true,speed = speed,})
            inst.fx = fx
            local fx = inst:SpawnChild(inst.fx_prefab)
            fx:PushEvent("Set",{pt = Vector3(0,0,0),anim = "chop",scale = 1.5,remove = true,speed = speed,})
            inst.fx2 = fx
        end
    end
    local function remove_fx(inst)
        if inst.fx then
            inst.fx:Remove()
            inst.fx = nil
        end
        if inst.fx2 then
            inst.fx2:Remove()
            inst.fx2 = nil            
        end
        if inst.__fx_task then
            inst.__fx_task:Cancel()
            inst.__fx_task = nil
        end
    end
    local function create_fx(inst)
        remove_fx(inst)
        inst.__fx_task = inst:DoPeriodicTask(6,function()
            create_fx_origin(inst)
        end,math.random()*10)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 生长
    local growable_stages = {
        --[[        
            【笔记】 fn 先执行，再执行growfn ，onload的时候只执行 fn
        ]]--
        {
            name = "burnt",
            time = function(inst) return 300*TUNING.TOTAL_DAY_TIME end,
            growfn = function(inst)
                inst:AddTag("burnt")
                inst.AnimState:PlayAnimation("burnt_normal",false)
                -- inst.components.growable:StopGrowing()
                -- uninstall_burnt(inst)
                -- install_chop(inst)
                -- remove_fx(inst)
            end,
            fn = function(inst)
                inst:AddTag("burnt")
                inst.AnimState:PlayAnimation("burnt_normal",true)
                inst.components.growable:StopGrowing()
                uninstall_burnt(inst)
                install_chop(inst)
                remove_fx(inst)
            end,
        },
        {
            name = "stump",
            time = function(inst) return 30*TUNING.TOTAL_DAY_TIME end,
            growfn = function(inst)
                inst.AnimState:PlayAnimation("idle_stump",true)
                -- remove_fx(inst)
            end,    -- DoGrowth 的时候执行（时间到了）
            fn = function(inst)     -- SetStage 的时候执行
                inst.AnimState:PlayAnimation("idle_stump",true)
                install_burnt(inst)
                install_dig(inst)
                remove_fx(inst)
            end,
        },
        {
            name = "small_tree", --- 
            time = function(inst) return 5*TUNING.TOTAL_DAY_TIME end,
            growfn = function(inst) -- DoGrowth 的时候执行（时间到了）
                inst.AnimState:PlayAnimation("idle_1",false)
                inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
                -- remove_fx(inst)
            end,   
            fn = function(inst)     -- SetStage 的时候执行
                inst.AnimState:PlayAnimation("idle_1",true)
                inst.components.growable:StartGrowing()
                install_burnt(inst,true)
                install_dig(inst)
                remove_fx(inst)
            end,                                                     
        },
        {
            name = "tree",
            time = function(inst) return 5*TUNING.TOTAL_DAY_TIME end,
            growfn = function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
                inst.AnimState:PlayAnimation("grow1_2",false)
                inst.AnimState:PushAnimation("sway2_normal",true)
                -- install_chop(inst)
                -- install_burnt(inst)
                -- create_fx(inst)
            end,
            fn = function(inst)
                inst.AnimState:PlayAnimation("sway2_normal",true)
                install_burnt(inst)
                install_chop(inst)
                create_fx(inst)
                inst.AnimState:SetTime(4*math.random())
            end,
        },

    }
    local function grow_state_init(inst)
        local stage = get_current_stage(inst)
        if TREE_STAGE[stage] == "burnt" then
            --  or TREE_STAGE[stage] == "stump"
            inst.components.growable:StopGrowing()
        else
            inst.components.growable:StartGrowing()
        end
    end
    local function on_load_fn(com)
        grow_state_init(com.inst)
    end
    local function growable_com_install(inst)
        inst:AddComponent("growable")
        inst.components.growable.stages = growable_stages
        inst.components.growable:SetStage(4)
        inst.components.growable.loopstages = false
        inst.components.growable.springgrowth = true
        inst.components.growable:StartGrowing()
        inst.components.growable.magicgrowable = false
        inst:DoTaskInTime(0,grow_state_init)
        inst.components.tbat_data:AddOnLoadFn(on_load_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function MakeTree(data)
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 素材
            local assets =
            {
                Asset("ANIM", "anim/"..data.prefab..".zip"),
            }
        ----------------------------------------------------------------------------------------------------------------------------------------------
        ---- 植物
            local function tree_fn()
                local inst = CreateEntity()
                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.entity:AddSoundEmitter()
                inst.entity:AddNetwork()
                MakeObstaclePhysics(inst, .25)
                inst.AnimState:SetBank(data.prefab)
                inst.AnimState:SetBuild(data.prefab)
                inst.AnimState:PlayAnimation("sway2_normal",true)
                inst.AnimState:HideSymbol("test")
                inst:AddTag("plant")
                inst:AddTag("tree")
                inst:AddTag(data.prefab)
                inst:AddTag("wildfireprotected") -- 无法野火
                if data.minimap then
                    inst.entity:AddMiniMapEntity()
                    inst.MiniMapEntity:SetIcon(data.minimap)
                end
                inst.entity:SetPristine()
                if data.tree_common_fn then
                    data.tree_common_fn(inst)
                end
                if not TheWorld.ismastersim then
                    return inst
                end
                inst:AddComponent("tbat_data")
                inst.components.tbat_data:Set("flag",true)
                inst:AddComponent("lootdropper")
                growable_com_install(inst)
                inst:AddComponent("inspectable")
                MakeHauntableLaunch(inst)
                TBAT.FNS:SnowInit(inst)
                if data.tree_master_fn then
                    data.tree_master_fn(inst)
                end
                if data.tree_chop_finish_fn then
                    inst.tree_chop_finish_fn = data.tree_chop_finish_fn
                end
                if data.tree_dig_finish_fn then
                    inst.tree_dig_finish_fn = data.tree_dig_finish_fn
                end
                inst.fx_prefab = data.prefab.."_fx"
                return inst
            end
        ----------------------------------------------------------------------------------------------------------------------------------------------
        ---- 物品
            local function on_deploy(inst, pt, deployer)
                if inst.plant then
                    local plant = SpawnPrefab(inst.plant)
                    plant.components.growable:SetStage(TREE_STAGE["small_tree"])
                    plant.Transform:SetPosition(pt.x,0,pt.z)
                end
                inst.components.stackable:Get():Remove()                
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
                inst.AnimState:SetBank(data.prefab)
                inst.AnimState:SetBuild(data.prefab)
                inst.AnimState:PlayAnimation("item",true)
                inst.AnimState:HideSymbol("test")
                -- inst:AddTag("usedeploystring")
                MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
                inst.entity:SetPristine()
                if data.item_common_fn then
                    data.item_common_fn(inst)
                end
                if not TheWorld.ismastersim then
                    return inst
                end
                -----------------------------------------
                ---
                    inst:AddComponent("inspectable")
                    inst:AddComponent("inventoryitem")
                -----------------------------------------
                ---
                    inst:AddComponent("stackable")
                    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
                -----------------------------------------
                ---
                    inst:AddComponent("deployable")
                    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
                    inst.components.deployable.ondeploy = on_deploy
                -----------------------------------------
                --- 数据表
                    inst.plant = data.prefab
                    if data.item_master_fn then
                        data.item_master_fn(inst)
                    end
                -----------------------------------------
                --- 落水处理
                    inst:ListenForEvent("on_landed",shadow_init)
                    shadow_init(inst)
                -----------------------------------------
                --- 可燃物
                    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
                    MakeSmallPropagator(inst)
                    MakeHauntableLaunchAndIgnite(inst)
                -----------------------------------------
                return inst
            end
        ----------------------------------------------------------------------------------------------------------------------------------------------
        ---- placer
            local function placer_postinit_fn(inst)
                TBAT.FNS:SnowInit(inst)
                if data.placer_postinit_fn then
                    data.placer_postinit_fn(inst)
                end
            end
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- fx 落叶特效
            local function set_anim(inst,cmd)
                local anim = cmd.anim or "chop"
                local random = cmd.random or false
                local remove = cmd.remove or false
                local speed = cmd.speed or 1
                if anim == "chop" then
                    inst.AnimState:PlayAnimation("chop",not remove)
                    if random then
                        inst.AnimState:SetTime(math.random(14)/10)
                    end
                elseif anim == "fall" then
                    inst.AnimState:PlayAnimation("fall",not remove)
                    if random then
                        inst.AnimState:SetTime(math.random(20)/10)
                    end
                end
                if remove then
                    inst:ListenForEvent("animover",inst.Remove)
                end
                if cmd.scale then
                    inst.AnimState:SetScale(cmd.scale,cmd.scale,cmd.scale)
                end
                if cmd.pt then
                    inst.Transform:SetPosition(cmd.pt.x,cmd.pt.y,cmd.pt.z)
                end
                inst.AnimState:SetDeltaTimeMultiplier(speed)
            end
            local function fx_fn()
                local inst = CreateEntity()
                inst.entity:AddTransform()
                inst.entity:AddAnimState()

                inst.AnimState:SetBank("tree_leaf_fx")
                inst.AnimState:SetBuild("tree_leaf_fx_yellow")

                local layers = {"","2","3","4","5","6","7","13","14"}
                for k, v in pairs(layers) do
                    inst.AnimState:OverrideSymbol("fff"..v,data.prefab,"fx_petail")
                end
                inst.AnimState:OverrideSymbol("needle",data.prefab,"fx_needle")

                local anim_type = 1
                if anim_type == 1 then                    
                    inst.AnimState:PlayAnimation("chop",true)
                    inst.AnimState:SetTime(math.random(14)/10)
                else                    
                    inst.AnimState:PlayAnimation("fall",true)
                    inst.AnimState:SetTime(math.random(20)/10)
                end
                inst:AddTag("NOBLOCK")
                inst:AddTag("NOCLICK")
                inst:AddTag("FX")
                inst.entity:SetPristine()
                if not TheWorld.ismastersim then
                    return inst
                end
                inst:ListenForEvent("Set",set_anim)
                return inst
            end
        ----------------------------------------------------------------------------------------------------------------------------------------------
        return Prefab(data.prefab,tree_fn,assets),
                Prefab(data.prefab.."_kit",item_fn,assets),
                MakePlacer(data.prefab.."_kit_placer",data.prefab,data.prefab,"idle_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil),
                Prefab(data.prefab.."_fx",fx_fn,assets)

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 掉落封装
    local function drop_loot_with_num(inst,prefab,num)
        if not PrefabExists(prefab) then
            return
        end
        num = num or 1
        for i=1,num do
            inst.components.lootdropper:SpawnLootPrefab(prefab)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local tree_data = {
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 梨花树
            {
                prefab = "tbat_plant_pear_blossom_tree",
                minimap = "tbat_plant_pear_blossom_tree.tex",
                tree_common_fn = function(inst) end,
                tree_master_fn = function(inst) end,
                tree_chop_finish_fn = function(inst,worker)
                    local stage = get_current_stage(inst)
                    if TREE_STAGE[stage] == "burnt" then                        
                        drop_loot_with_num(inst,"charcoal",math.random(3,5))
                        -- inst:Remove()
                    elseif TREE_STAGE[stage] == "tree" then
                        if math.random() <= 0.3 then
                            drop_loot_with_num(inst,"tbat_plant_pear_blossom_tree_kit",math.random(1,2))
                        end
                        drop_loot_with_num(inst,"tbat_material_miragewood",4)
                        drop_loot_with_num(inst,"tbat_food_pear_blossom_petals",4)
                    end
                end,
                tree_dig_finish_fn = function(inst,worker)
                    local stage = get_current_stage(inst)
                    if TREE_STAGE[stage] == "small_tree" then
                        drop_loot_with_num(inst,"twigs")
                    elseif TREE_STAGE[stage] == "stump" then
                        drop_loot_with_num(inst,"tbat_plant_pear_blossom_tree_kit",1)
                    end
                    inst:Remove()
                end,
                item_common_fn = function(inst) end,
                item_master_fn = function(inst)
                    inst.components.inventoryitem:TBATInit("tbat_plant_pear_blossom_tree_kit","images/map_icons/tbat_plant_pear_blossom_tree_kit.xml")
                end,                                
                placer_postinit_fn = function(inst)  end,
            },
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 樱花树
            {
                prefab = "tbat_plant_cherry_blossom_tree",
                minimap = "tbat_plant_cherry_blossom_tree.tex",
                tree_common_fn = function(inst) end,
                tree_master_fn = function(inst) end,
                tree_chop_finish_fn = function(inst,worker)
                    local stage = get_current_stage(inst)
                    if TREE_STAGE[stage] == "burnt" then                        
                        drop_loot_with_num(inst,"charcoal",math.random(3,5))
                        -- inst:Remove()
                    elseif TREE_STAGE[stage] == "tree" then
                        if math.random() <= 0.3 then
                            drop_loot_with_num(inst,"tbat_plant_cherry_blossom_tree_kit",math.random(1,2))
                        end
                        drop_loot_with_num(inst,"tbat_material_miragewood",4)
                        drop_loot_with_num(inst,"tbat_food_cherry_blossom_petals",4)
                    end
                end,
                tree_dig_finish_fn = function(inst,worker)
                    local stage = get_current_stage(inst)
                    if TREE_STAGE[stage] == "small_tree" then
                        drop_loot_with_num(inst,"twigs")
                    elseif TREE_STAGE[stage] == "stump" then
                        drop_loot_with_num(inst,"tbat_plant_cherry_blossom_tree_kit",1)
                    end
                    inst:Remove()
                end,
                item_common_fn = function(inst) end,
                item_master_fn = function(inst)
                    inst.components.inventoryitem:TBATInit("tbat_plant_cherry_blossom_tree_kit","images/map_icons/tbat_plant_cherry_blossom_tree_kit.xml")
                end,                                
                placer_postinit_fn = function(inst)  end,
            },
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 秋枫树
            {
                prefab = "tbat_plant_crimson_maple_tree",
                minimap = "tbat_plant_crimson_maple_tree.tex",
                tree_common_fn = function(inst) end,
                tree_master_fn = function(inst) end,
                tree_chop_finish_fn = function(inst,worker)
                    local stage = get_current_stage(inst)
                    if TREE_STAGE[stage] == "burnt" then                        
                        drop_loot_with_num(inst,"charcoal",math.random(3,5))
                        -- inst:Remove()
                    elseif TREE_STAGE[stage] == "tree" then
                        if math.random() <= 0.3 then
                            drop_loot_with_num(inst,"tbat_plant_crimson_maple_tree_kit",math.random(1,2))
                        end
                        drop_loot_with_num(inst,"tbat_material_miragewood",6)
                        drop_loot_with_num(inst,"tbat_item_holo_maple_leaf",2)
                    end
                end,
                tree_dig_finish_fn = function(inst,worker)
                    local stage = get_current_stage(inst)
                    if TREE_STAGE[stage] == "small_tree" then
                        drop_loot_with_num(inst,"twigs")
                    elseif TREE_STAGE[stage] == "stump" then
                        drop_loot_with_num(inst,"tbat_material_miragewood",1)
                    end
                    inst:Remove()
                end,
                item_common_fn = function(inst) end,
                item_master_fn = function(inst)
                    inst.components.inventoryitem:TBATInit("tbat_plant_crimson_maple_tree_kit","images/map_icons/tbat_plant_crimson_maple_tree_kit.xml")
                end,                                
                placer_postinit_fn = function(inst)  end,
            },
        ----------------------------------------------------------------------------------------------------------------------------------------------
    }
    local ret = {}
    local function temp_insert(_table,...)
        local args = {...}
        for k, v in pairs(args) do
            table.insert(_table,v)
        end
    end
    for i,v in ipairs(tree_data) do
        temp_insert(ret,MakeTree(v))
    end
    return unpack(ret)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------