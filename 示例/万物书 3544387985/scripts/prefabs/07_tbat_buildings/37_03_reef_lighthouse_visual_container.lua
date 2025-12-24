--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    容器界面参数配置

    需要单独的prefab

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local this_prefab = "tbat_building_reef_lighthouse_visual_container"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 
    local item_list = {
        ["barnacle"] = true , -- 藤壶
    }
    local function item_test(item)
        return item:HasTag("smalloceancreature") or item_list[item.prefab] or false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 容器界面
    local all_container_widgets = require("containers")
    local params = all_container_widgets.params
    if params[this_prefab] == nil then
        ------------------------------------------------------------------------------------------
        ---
            params[this_prefab] = {}
            local widget_data = params[this_prefab]
        ------------------------------------------------------------------------------------------
        ---
            widget_data.widget = {
                    slotpos = {},
                    animbank = "ui_fish_box_5x4",
                    animbuild = "ui_fish_box_5x4",
                    pos = Vector3(0, 220, 0),
                    side_align_tip = 160,
                }
                widget_data.type = this_prefab or "chest"
        ------------------------------------------------------------------------------------------
        --- slot 坐标和背景
            for y = 2.5, -0.5, -1 do
                for x = -1, 3 do
                    table.insert(widget_data.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
                end
            end
        ------------------------------------------------------------------------------------------
        ---- item test
            widget_data.itemtestfn =  function(container_com, item, slot)
                return item_test(item)
            end
        ------------------------------------------------------------------------------------------
    end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 安装容器界面的标准流程
    local function container_Widget_change(theContainer)       
        theContainer:WidgetSetup(this_prefab)
        ------------------------------------------------------------------------
        --- 声音关闭
            -- theContainer.ShouldSkipOpenSnd = function() return true end
            -- theContainer.ShouldSkipCloseSnd = theContainer.ShouldSkipOpenSnd
        ------------------------------------------------------------------------
    end
    local function container_replica_init(inst,replica_com)
        container_Widget_change(replica_com)
    end    
    local function on_open(inst,_table)
        -- inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_pear_cat/open")
    end
    local function on_close(inst,_table)
        -- inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_pear_cat/close")
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
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 本体
    local assets = {
        -- Asset("ANIM", "anim/tbat_building_lavender_flower_house.zip"),
        -- Asset("IMAGE", "images/widgets/tbat_building_lavender_flower_house_slot.tex"),
        -- Asset("ATLAS", "images/widgets/tbat_building_lavender_flower_house_slot.xml"),
    }
    local function fn()
        -----------------------------------------------------------
        --- 基础的模块组
            local inst = CreateEntity()
            inst.entity:AddSoundEmitter()
            inst.entity:AddTransform()
            inst.entity:AddNetwork()
            inst:AddTag("CLASSIFIED")
            inst:AddTag("FX")
            inst:AddTag("fx")
            inst:AddTag("NOBLOCK")
            inst:AddTag("NOCLICK")
            inst.entity:SetPristine()
        -----------------------------------------------------------
        --- 容器界面安装和修改
            add_container_before_not_ismastersim_return(inst)
        -----------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst.persists = false   -- 是否留存到下次存档重启
        -----------------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(0)
        -----------------------------------------------------------
        return inst
    end
    return Prefab(this_prefab, fn, assets)
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------