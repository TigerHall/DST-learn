--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    树藤注册

    inst 挂载节点：

    tree.vines = {}



]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 参数
    local base_prefab = "tbat_the_tree_of_all_things_vine_"
    local ANIM_SCALE = 1.5
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_the_tree_of_all_things_vine_container.zip"),

        Asset("ANIM", "anim/tbat_the_tree_of_all_things_vine_maple_squirrel.zip"),      -- 松鼠
        Asset("ANIM", "anim/tbat_the_tree_of_all_things_vine_snow_plum_chieftain.zip"), -- 梅雪小狼
        Asset("ANIM", "anim/tbat_the_tree_of_all_things_vine_osmanthus_cat.zip"),       -- 桂花猫猫
        Asset("ANIM", "anim/tbat_the_tree_of_all_things_vine_mushroom_snail.zip"),      -- 蘑菇蜗牛
        Asset("ANIM", "anim/tbat_the_tree_of_all_things_vine_lavender_kitty.zip"),      -- 薰衣草猫猫
        Asset("ANIM", "anim/tbat_the_tree_of_all_things_vine_stinkray.zip"),            -- 帽子鳐鱼

        Asset("IMAGE", "images/widgets/tbat_the_tree_of_all_things_vine_container_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_the_tree_of_all_things_vine_container_slot.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 每种树藤参数
    local all_vines_data = {
        -----------------------------------------------------------------------------
        --[[
            
                index 为 后续拼接的 名字

            ]]
        -----------------------------------------------------------------------------
        --- 枫叶松鼠
            ["maple_squirrel"] = {
                bank = "tbat_the_tree_of_all_things_vine_maple_squirrel",
                build = "tbat_the_tree_of_all_things_vine_maple_squirrel",
                spawn_anim = "in",        --- 生成时候的动画
                idle_anim = "idle",         --- 正常动画
                despawn_anim = "out",      --- 移除时候的动画
                slot_item = {"tbat_material_liquid_of_maple_leaves","tbat_item_holo_maple_leaf"},         --- 容器里能进入的物品
                override_daily_task_fn = nil,  --- 覆盖型每日任务。
            },
        -----------------------------------------------------------------------------
        --- 梅雪小狼
            ["snow_plum_chieftain"] = {
                bank = "tbat_the_tree_of_all_things_vine_snow_plum_chieftain",
                build = "tbat_the_tree_of_all_things_vine_snow_plum_chieftain",
                spawn_anim = "in",        --- 生成时候的动画
                idle_anim = "idle",         --- 正常动画
                despawn_anim = "out",      --- 移除时候的动画
                slot_item = {"tbat_material_snow_plum_wolf_hair","tbat_material_white_plum_blossom"},         --- 容器里能进入的物品
                override_daily_task_fn = nil,  --- 覆盖型每日任务。
            },
        -----------------------------------------------------------------------------
        --- 桂花猫猫
            ["osmanthus_cat"] = {
                bank = "tbat_the_tree_of_all_things_vine_osmanthus_cat",
                build = "tbat_the_tree_of_all_things_vine_osmanthus_cat",
                spawn_anim = "in",        --- 生成时候的动画
                idle_anim = "idle",         --- 正常动画
                despawn_anim = "out",      --- 移除时候的动画
                slot_item = {"tbat_material_osmanthus_wine","tbat_material_osmanthus_ball"},         --- 容器里能进入的物品
                override_daily_task_fn = nil,  --- 覆盖型每日任务。
            },
        -----------------------------------------------------------------------------
        --- 蘑菇蜗牛
            ["mushroom_snail"] = {
                bank = "tbat_the_tree_of_all_things_vine_mushroom_snail",
                build = "tbat_the_tree_of_all_things_vine_mushroom_snail",
                spawn_anim = "in",        --- 生成时候的动画
                idle_anim = "idle",         --- 正常动画
                despawn_anim = "out",      --- 移除时候的动画
                slot_item = {"tbat_plant_fluorescent_moss_item","tbat_plant_fluorescent_mushroom_item"},         --- 容器里能进入的物品
                override_daily_task_fn = nil,  --- 覆盖型每日任务。
            },
        -----------------------------------------------------------------------------
        --- 薰衣草猫猫
            ["lavender_kitty"] = {
                bank = "tbat_the_tree_of_all_things_vine_lavender_kitty",
                build = "tbat_the_tree_of_all_things_vine_lavender_kitty",
                spawn_anim = "in",        --- 生成时候的动画
                idle_anim = "idle",         --- 正常动画
                despawn_anim = "out",      --- 移除时候的动画
                slot_item = {"tbat_material_lavender_laundry_detergent","tbat_food_lavender_flower_spike"},         --- 容器里能进入的物品
                override_daily_task_fn = nil,  --- 覆盖型每日任务。
            },
        -----------------------------------------------------------------------------
        --- 帽子鳐鱼
            ["stinkray"] = {
                bank = "tbat_the_tree_of_all_things_vine_stinkray",
                build = "tbat_the_tree_of_all_things_vine_stinkray",
                spawn_anim = "in",        --- 生成时候的动画
                idle_anim = "idle",         --- 正常动画
                despawn_anim = "out",      --- 移除时候的动画
                slot_item = {"tbat_item_crystal_bubble","barnacle"},         --- 容器里能进入的物品
                override_daily_task_fn = nil,  --- 覆盖型每日任务。
            },
        -----------------------------------------------------------------------------
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- container
    -----------------------------------------------------------------------------------
    ----- 容器界面名 --- 要独特一点，避免冲突
        local container_widget_name = "tbat_the_tree_of_all_things_vine_container"
    -----------------------------------------------------------------------------------
    ----- 检查和注册新的容器界面
        local all_container_widgets = require("containers")
        local params = all_container_widgets.params
        if params[container_widget_name] == nil then
            params[container_widget_name] = {
                widget =
                {
                    slotpos =
                    {
                        Vector3(50, -20, 0),
                        Vector3(50, -120, 0),
                    },
                    slotbg =
                    {
                        { image = "tbat_the_tree_of_all_things_vine_container_slot.tex", atlas = "images/widgets/tbat_the_tree_of_all_things_vine_container_slot.xml" },
                        { image = "tbat_the_tree_of_all_things_vine_container_slot.tex", atlas = "images/widgets/tbat_the_tree_of_all_things_vine_container_slot.xml" },
                    },
                    animbank = "ui_cookpot_1x2",
                    animbuild = "tbat_the_tree_of_all_things_vine_container",
                    pos = Vector3(100, 100, 0),
                },
                acceptsstacks = true,
                usespecificslotsforitems = true,
                type = "chest",
            }
            ------------------------------------------------------------------------------------------
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    local inst = container_com.inst
                    local slot_item = inst.slot_item or {}
                    local slot_item_idx = inst.slot_item_idx or {}
                    if slot == nil and slot_item_idx[item.prefab] then
                        return true
                    end
                    if slot_item[slot] == item.prefab then
                        return true
                    end
                    return false
                end
            ------------------------------------------------------------------------------------------
        end
    -----------------------------------------------------------------------------------
    local function container_Widget_change(theContainer)       
        theContainer:WidgetSetup(container_widget_name)
        ------------------------------------------------------------------------
        --- 声音关闭
        -- if theContainer.SetSkipOpenSnd then
        --     theContainer:SetSkipOpenSnd(true)   ---- 打开时候的声音
        --     theContainer:SetSkipCloseSnd(true)  ---- 关闭时候的声音
        -- end
        ------------------------------------------------------------------------
    end

    local function container_replica_init(inst,replica_com)
        container_Widget_change(replica_com)        
    end    
    local function on_open(inst,_table)
    end
    local function on_close(inst,_table)
    end
    local function add_container_before_not_ismastersim_return(inst)
        -------------------------------------------------------------------------------------------------
        ----
            inst:ListenForEvent("TBAT_OnEntityReplicated.container",container_replica_init)
            if TheWorld.ismastersim then
                inst:AddComponent("container")
                inst.components.container.openlimit = 10  ---- 限制10个人打开
                container_Widget_change(inst.components.container)
                inst:ListenForEvent("onclose",on_close)
                inst:ListenForEvent("onopen",on_open)
                inst.components.container:EnableInfiniteStackSize(true)
            end
        -------------------------------------------------------------------------------------------------
        ------ 添加背包container组件    --- 必须在 SetPristine 之后，
            -- if TheWorld.ismastersim then
            --     inst:AddComponent("container")
            --     inst.components.container.openlimit = 10  ---- 限制10个人打开
            --     container_Widget_change(inst.components.container)    
            -- else
            --     inst.OnEntityReplicated = function(inst)
            --         container_Widget_change(inst.replica.container)
            --     end
            -- end
        -------------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- daily_task
    local function daily_task_fn(inst)
        if inst.override_daily_task_fn then
            inst.override_daily_task_fn(inst)
            return
        end
        local need_2_spawn_prefabs = {}
        inst.components.container:ForEachItem(function(item)
            if item then
                need_2_spawn_prefabs[item.prefab] = true
            end
        end)
        for prefab, v in pairs(need_2_spawn_prefabs) do
            inst.components.container:GiveItem(SpawnPrefab(prefab))
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 控制事件
    local function animqueueover_event(inst)
        inst.AnimState:PlayAnimation(inst.idle_anim,true)
        inst.AnimState:SetTime(math.random()*4)
        inst:RemoveEventCallback("animqueueover",inst.animqueueover_event)
    end
    local function spawn_event(inst,cmd)
        if not cmd.sleeping and inst.spawn_anim and inst.idle_anim then
            inst.AnimState:PlayAnimation(inst.spawn_anim)
            inst.AnimState:PushAnimation(inst.idle_anim,false)
            inst.animqueueover_event = animqueueover_event
            inst:ListenForEvent("animqueueover",inst.animqueueover_event)
        else
            inst.AnimState:SetTime(math.random()*4)
        end
        local pt = cmd.pt
        inst.Transform:SetPosition(pt.x,0,pt.z)
    end
    local function despawn_event(inst)
        inst.components.container:Close()
        inst.components.container:DropEverything()
        inst:AddTag("INLIMBO")
        inst:AddTag("NOCLICK")
        if inst:IsAsleep() then
            inst:Remove()
        else
            inst.AnimState:PlayAnimation(inst.despawn_anim or inst.idle_anim or "idle")
            inst:ListenForEvent("animover",inst.Remove)
        end
    end
    local function controll_event_install(inst)
        inst:ListenForEvent("Set",spawn_event)
        inst:ListenForEvent("despawn",despawn_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 建筑本体
    local function common_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.entity:AddDynamicShadow()
        inst.DynamicShadow:SetSize(1, 1)

        inst:AddTag("structure")
        inst:AddTag("NOBLOCK")

        inst.entity:SetPristine()
        ---------------------------------------------------
        ---
            add_container_before_not_ismastersim_return(inst)
        ---------------------------------------------------
        --- 
            inst.persists = false   --- 是否留存到下次存档加载。
        ---------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        ---------------------------------------------------
        --- 基础模块
            inst:AddComponent("inspectable")
        ---------------------------------------------------
        ---
            inst:WatchWorldState("cycles",daily_task_fn)
        ---------------------------------------------------
        ---
            controll_event_install(inst)
        ---------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(0)
        ---------------------------------------------------
        --- 防止复制
            inst:DoTaskInTime(0,function()
                if inst.tree == nil then
                    inst:Remove()
                end
            end)
        ---------------------------------------------------
        return inst
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 按分类生成，并赋予数据。
    local ret = {}
    for ex_name, data in pairs(all_vines_data) do
        local this_prefab = base_prefab..ex_name
        local function fn()
            local inst = common_fn()
            inst.AnimState:SetBank(data.bank)
            inst.AnimState:SetBuild(data.build)
            inst.AnimState:PlayAnimation(data.idle_anim,true)
            inst.idle_anim = data.idle_anim
            inst.spawn_anim = data.spawn_anim
            inst.despawn_anim = data.despawn_anim
            inst.AnimState:SetScale(ANIM_SCALE,ANIM_SCALE,ANIM_SCALE)
            inst.slot_item = data.slot_item or {} -- 给容器用的
            inst.slot_item_idx = {}
            for k, temp_prefab in pairs(inst.slot_item) do
                inst.slot_item_idx[temp_prefab] = k
            end
            if not TheWorld.ismastersim then
                return inst
            end
            inst.override_daily_task_fn = data.override_daily_task_fn
            return inst
        end
        table.insert(ret,Prefab(this_prefab,fn, assets))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret)
