--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    两个灌木：

    anim:
        item            --- 物品 + 影子： SHADOW
        stage_1         --- 枯萎
        stage_1_to_2    --- 恢复动画
        stage_2         --- 正常
        stage_2_to_3    --- 正在结果动画
        stage_3         --- 丰收



]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function MakeBush(data)
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 素材
            local assets =
            {
                Asset("ANIM", "anim/"..data.prefab..".zip"),
            }
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 植物通用fn
            local function onpickedfn(inst, picker,loot)             --- 采集后执行。
                if inst.bush_on_picked_fn then
                    inst.bush_on_picked_fn(inst, picker,loot)
                end
                local times = inst.components.tbat_data:Add("picked_times",1)   --- 采集次数记忆
                if times >= (inst.pick_times or 100000) then
                    inst.components.tbat_data:Set("picked_times",0)
                    inst.components.pickable:MakeBarren()
                else
                    inst.__picked_flag = true
                    inst.components.pickable:MakeEmpty()
                end
            end
            local function makeemptyfn(inst)                    --- 空的状态。
                if inst.__picked_flag then
                    inst.AnimState:PlayAnimation("stage_2",true)
                    inst.__picked_flag = false
                else
                    inst.AnimState:PlayAnimation("stage_1_to_2")
                    inst.AnimState:PushAnimation("stage_2",true)
                end
                inst.components.pickable:Resume() --- 恢复生长
            end
            local function makebarrenfn(inst)                   --- 枯萎的状态。
                inst.AnimState:PlayAnimation("stage_1",true)    --- 
                inst.components.pickable:Pause() --- 停止生长。
            end
            local function makefullfn(inst)                     --- 满状态。        
                inst.AnimState:PlayAnimation("stage_2_to_3")
                inst.AnimState:PushAnimation("stage_3",true)
            end
            local function ontransplantfn(inst)                 --- 移栽。
                inst.components.pickable:MakeBarren()
            end
            local function getregentimefn_normal(inst)          --- 重新生长时间
                if not inst.components.pickable then
                    return inst.regrow_time or TUNING.BERRY_REGROW_TIME
                end
                --V2C: nil cycles_left means unlimited picks, so use max value for math
                local max_cycles = inst.components.pickable.max_cycles
                local cycles_left = inst.components.pickable.cycles_left or max_cycles
                local num_cycles_passed = math.max(0, max_cycles - cycles_left)
                return (inst.regrow_time or TUNING.BERRY_REGROW_TIME)
                    + TUNING.BERRY_REGROW_INCREASE * num_cycles_passed
                    + TUNING.BERRY_REGROW_VARIANCE * math.random()
            end
            local function dig_up_normal(inst, worker)
                local kit_prefab = inst.prefab .. "_kit"
                if PrefabExists(kit_prefab) and not inst.components.pickable:IsBarren() then
                    inst.components.lootdropper:SpawnLootPrefab(kit_prefab)
                else
                    inst.components.lootdropper:SpawnLootPrefab("twigs")
                end
                if inst.components.pickable:CanBePicked() then
                    inst.components.pickable:Pick(TheWorld)
                end
                inst:Remove()
            end
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 植物
            local function tree_fn()
                local inst = CreateEntity()
                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.entity:AddSoundEmitter()
                inst.entity:AddNetwork()
                inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT] / 2) --plantables deployspacing/2
                if not data.nophysics then
                    MakeSmallObstaclePhysics(inst, .1)
                else
                    inst:SetDeploySmartRadius(0.1)
                end
                inst.AnimState:SetBank(data.prefab)
                inst.AnimState:SetBuild(data.prefab)
                inst.AnimState:PlayAnimation("stage_3",true)
                inst.AnimState:HideSymbol("test")
                inst:AddTag("plant")
                inst:AddTag(data.prefab)
                if data.minimap then
                    inst.entity:AddMiniMapEntity()
                    inst.MiniMapEntity:SetIcon(data.minimap)
                end
                inst.entity:SetPristine()
                ----------------------------------------------------------------
                ---
                    if data.bush_common_fn then
                        data.bush_common_fn(inst)
                    end
                ----------------------------------------------------------------
                ---
                    if not TheWorld.ismastersim then
                        return inst
                    end
                ----------------------------------------------------------------
                ---
                    inst:AddComponent("lootdropper")
                    inst.components.lootdropper:SetLoot(data.loot)
                    inst:AddComponent("inspectable")
                    inst:AddComponent("tbat_data")
                ----------------------------------------------------------------
                ---
                    inst:AddComponent("pickable")
                    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
                    inst.components.pickable.onpickedfn = onpickedfn            --- 采集之后执行
                    inst.components.pickable.makeemptyfn = makeemptyfn          --- barren -> empty 时候执行
                    inst.components.pickable.makebarrenfn = makebarrenfn        --- 枯萎 
                    inst.components.pickable.makefullfn = makefullfn            --- 满
                    inst.components.pickable.ontransplantfn = ontransplantfn    --- 移植用
                    inst.components.pickable:SetUp("berries",data.regrow_time or TUNING.BERRY_REGROW_TIME) -- 这句基本没啥用了。
                    inst.components.pickable.getregentimefn = getregentimefn_normal
                    inst.components.pickable.max_cycles = data.pick_times or TUNING.BERRYBUSH_CYCLES + math.random(2)   -- 采集N次后进入枯萎状态
                    inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
                    inst.components.pickable.use_lootdropper_for_product = true -- 以掉落列表形式生成产物
                    inst:AddComponent("witherable") -- 可枯萎/可施肥

                    inst.regrow_time = data.regrow_time or TUNING.MED_REGROWTH_TIME
                ----------------------------------------------------------------
                ---
                    MakeLargeBurnable(inst)
                    MakeMediumPropagator(inst)
                    MakeHauntableLaunch(inst)
                    TBAT.FNS:SnowInit(inst)
                ----------------------------------------------------------------
                ---
                    inst:AddComponent("workable")
                    inst.components.workable:SetWorkAction(ACTIONS.DIG)
                    inst.components.workable:SetWorkLeft(1)
                    inst.components.workable:SetOnFinishCallback(dig_up_normal)
                ----------------------------------------------------------------
                ---
                    if data.bush_master_fn then
                        data.bush_master_fn(inst)
                    end
                    inst.bush_on_picked_fn = data.bush_on_picked_fn
                    inst.pick_times = data.pick_times
                ----------------------------------------------------------------
                return inst
            end
        ----------------------------------------------------------------------------------------------------------------------------------------------
        ---- 物品
            local function on_deploy(inst, pt, deployer)
                if inst.plant then
                    local plant = SpawnPrefab(inst.plant)
                    plant.Transform:SetPosition(pt.x,0,pt.z)
                    if plant.components.pickable then
                        plant.components.pickable:OnTransplant()
                    end
                end
                inst.components.stackable:Get():Remove()                
            end
            local function shadow_init(inst)
                if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
                    inst.AnimState:Hide("SHADOW")
                else
                    inst.AnimState:Show("SHADOW")                    
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
        return Prefab(data.prefab,tree_fn,assets),
                Prefab(data.prefab.."_kit",item_fn,assets),
                MakePlacer(data.prefab.."_kit_placer",data.prefab,data.prefab,"stage_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local bushes_data = {
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 勇者玫瑰灌木
            {
                prefab = "tbat_plant_valorbush",
                minimap = "tbat_plant_valorbush.tex",
                bush_common_fn = function(inst)                    
                end,
                bush_master_fn = function(inst)
                    inst.components.lootdropper:AddChanceLoot("tbat_plant_valorbush_kit",TBAT.DEBUGGING and 0.9 or 0.1)
                end,
                bush_on_picked_fn = function(inst,picker,loot)
                    --- loot 里面是 实体inst列表。
                end,
                loot = {"tbat_food_valorbush","tbat_food_valorbush","tbat_food_valorbush","tbat_food_valorbush"},  --- 掉落列表
                item_common_fn = function(inst)
                end,
                item_master_fn = function(inst)
                    inst.components.inventoryitem:TBATInit("tbat_plant_valorbush_kit","images/map_icons/tbat_plant_valorbush_kit.xml")
                end,
                regrow_time = TBAT.DEBUGGING and 480 or TUNING.BERRY_REGROW_TIME, -- 结果时间(s)。
                pick_times = TBAT.DEBUGGING and 2 or 5,     --- 采集N次后枯萎用。
                nophysics = true,
            },
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 绯露莓刺藤
            {
                prefab = "tbat_plant_crimson_bramblefruit",
                minimap = "tbat_plant_crimson_bramblefruit.tex",
                bush_common_fn = function(inst)                    
                end,
                bush_master_fn = function(inst)
                    inst.components.lootdropper:AddChanceLoot("tbat_plant_crimson_bramblefruit_kit",TBAT.DEBUGGING and 0.9 or 0.1)
                end,
                bush_on_picked_fn = function(inst,picker,loot)
                    --- loot 里面是 实体inst列表。
                end,
                loot = {"tbat_food_crimson_bramblefruit","tbat_food_crimson_bramblefruit","tbat_food_crimson_bramblefruit"},  --- 掉落列表
                item_common_fn = function(inst)
                end,
                item_master_fn = function(inst)
                    inst.components.inventoryitem:TBATInit("tbat_plant_crimson_bramblefruit_kit","images/map_icons/tbat_plant_crimson_bramblefruit_kit.xml")
                end,
                regrow_time = TBAT.DEBUGGING and 480 or TUNING.BERRY_REGROW_TIME, -- 结果时间(s)。
                pick_times = TBAT.DEBUGGING and 2 or 5,     --- 采集N次后枯萎用。
                nophysics = true,
            },
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 薰衣草草丛
            {
                prefab = "tbat_plant_lavender_bush",
                minimap = "tbat_plant_lavender_bush.tex",
                bush_common_fn = function(inst)                    
                end,
                bush_master_fn = function(inst)
                    inst.AnimState:ShowSymbol("test")
                end,
                bush_on_picked_fn = function(inst,picker,loot)
                    --- loot 里面是 实体inst列表。
                end,
                loot = {"tbat_food_lavender_flower_spike","tbat_food_lavender_flower_spike"},  --- 掉落列表
                item_common_fn = function(inst)
                end,
                item_master_fn = function(inst)
                    inst.components.inventoryitem:TBATInit("tbat_plant_lavender_bush_kit","images/map_icons/tbat_plant_lavender_bush_kit.xml")
                end,
                regrow_time = TBAT.DEBUGGING and 480 or 5*480, -- 结果时间(s)。
                pick_times = TBAT.DEBUGGING and 2 or 5,     --- 采集N次后枯萎用。
                nophysics = true,
            },
        ----------------------------------------------------------------------------------------------------------------------------------------------
        --- 桂花矮树
            {
                prefab = "tbat_plant_osmanthus_bush",
                minimap = "tbat_plant_osmanthus_bush.tex",
                bush_common_fn = function(inst)                    
                end,
                bush_master_fn = function(inst)
                    inst.components.lootdropper:AddChanceLoot("tbat_plant_osmanthus_bush_kit",TBAT.DEBUGGING and 0.9 or 5/100)
                    inst.components.lootdropper:AddChanceLoot("beeswax",TBAT.DEBUGGING and 0.9 or 10/100)

                end,
                bush_on_picked_fn = function(inst,picker,loot)
                    --- loot 里面是 实体inst列表。
                end,
                loot = {"tbat_material_osmanthus_ball","honey","honey"},  --- 掉落列表
                item_common_fn = function(inst)
                end,
                item_master_fn = function(inst)
                    inst.components.inventoryitem:TBATInit("tbat_plant_osmanthus_bush_kit","images/map_icons/tbat_plant_osmanthus_bush_kit.xml")
                end,
                regrow_time = TBAT.DEBUGGING and 480 or 5*480, -- 结果时间(s)。
                pick_times = TBAT.DEBUGGING and 2 or 10,     --- 采集N次后枯萎用。
            },
        ----------------------------------------------------------------------------------------------------------------------------------------------
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local ret = {}
    local function temp_insert(_table,...)
        local args = {...}
        for k, v in pairs(args) do
            table.insert(_table,v)
        end
    end
    for i,v in ipairs(bushes_data) do
        temp_insert(ret,MakeBush(v))
    end
    return unpack(ret)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

