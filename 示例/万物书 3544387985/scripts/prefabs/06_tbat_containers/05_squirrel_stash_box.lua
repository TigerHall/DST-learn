--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_squirrel_stash_box"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_squirrel_stash_box.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    -----------------------------------------------------------------------------------
    ----- 容器界面名 --- 要独特一点，避免冲突
        local container_widget_name = "tbat_container_squirrel_stash_box"
    -----------------------------------------------------------------------------------
    ----- 检查和注册新的容器界面
        local all_container_widgets = require("containers")
        local params = all_container_widgets.params
        if params[container_widget_name] == nil then
            params[container_widget_name] = {
                widget =
                {
                    slotpos = {},
                    animbank = "ui_fish_box_5x4",
                    animbuild = "ui_fish_box_5x4",
                    pos = Vector3(0, 220, 0),
                    side_align_tip = 160,
                },
                type = "chest",
            }
            ------------------------------------------------------------------------------------------
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            --- 左上角是格子1
                for y = 2.5, -0.5, -1 do
                    for x = -1, 3 do
                        table.insert(widget_data.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
                    end
                end
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    return true
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
        inst.AnimState:PlayAnimation("idle_open")
    end
    local function on_close(inst,_table)
        inst.AnimState:PlayAnimation("idle")
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
--- 创建物品
    local function building_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        -- MakeObstaclePhysics(inst, 0)
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_container_squirrel_stash_box.tex")

        inst.AnimState:SetBank("tbat_container_squirrel_stash_box")
        inst.AnimState:SetBuild("tbat_container_squirrel_stash_box")
        inst.AnimState:PlayAnimation("idle",true)

        inst:AddTag("structure")
        inst:AddTag("tbat_container_squirrel_stash_box")

        inst.entity:SetPristine()
        ---------------------------------------------------
        add_container_before_not_ismastersim_return(inst)
        ---------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        ---------------------------------------------------
        ---------------------------------------------------
        --- 基础模块
            inst:AddComponent("lootdropper")
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ---------------------------------------------------
        ---
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst)
        ---------------------------------------------------
        --- 保险
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(0)
        ---------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

