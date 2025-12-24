--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    容器界面
    
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_container_lavender_kitty"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    -----------------------------------------------------------------------------------
    ----- 容器界面名 --- 要独特一点，避免冲突
        local container_widget_name = this_prefab
    -----------------------------------------------------------------------------------
    ----- 检查和注册新的容器界面
        local all_container_widgets = require("containers")
        local params = all_container_widgets.params
        if params[container_widget_name] == nil then
            params[container_widget_name] = {
                widget =
                {
                    slotpos = {},
                    slotbg = {},
                    animbank = "ui_fish_box_5x4",
                    animbuild = "ui_fish_box_5x4",
                    pos = Vector3(0, 0, 0),
                },
                type = this_prefab or "chest",
            }
            ------------------------------------------------------------------------------------------
            ---
            ------------------------------------------------------------------------------------------
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            --- 左上角是格子1
                local single_slot_bg = { image = "tbat_container_lavender_kitty_slot.tex", atlas = "images/widgets/tbat_container_lavender_kitty_slot.xml" }
                for i = 1, 9, 1 do
                    table.insert(widget_data.widget.slotpos, Vector3(0, 0, 0))
                    table.insert(widget_data.widget.slotbg, single_slot_bg)                    
                end
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    return item:HasTag("deployedfarmplant")
                end

            ------------------------------------------------------------------------------------------
        end
    -----------------------------------------------------------------------------------
    local function container_Widget_change(theContainer)       
        theContainer:WidgetSetup(container_widget_name)
        ------------------------------------------------------------------------
        --- 声音关闭
            theContainer.ShouldSkipOpenSnd = function() return true end
            theContainer.ShouldSkipCloseSnd = theContainer.ShouldSkipOpenSnd
        ------------------------------------------------------------------------
    end

    local function container_replica_init(inst,replica_com)
        container_Widget_change(replica_com)        
    end
    
    local function on_open(inst,_table)
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_cherry_blossom_rabbit/open")
    end
    local function on_close(inst,_table)
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_cherry_blossom_rabbit/close")
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
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return add_container_before_not_ismastersim_return