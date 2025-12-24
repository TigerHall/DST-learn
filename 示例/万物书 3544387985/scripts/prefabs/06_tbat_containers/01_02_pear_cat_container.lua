--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    容器界面
    
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    -----------------------------------------------------------------------------------
    ----- 容器界面名 --- 要独特一点，避免冲突
        local container_widget_name = "tbat_container_pear_cat"
    -----------------------------------------------------------------------------------
    ----- 检查和注册新的容器界面
        local all_container_widgets = require("containers")
        all_container_widgets.MAXITEMSLOTS = math.max(all_container_widgets.MAXITEMSLOTS, 16*6)
        local params = all_container_widgets.params
        if params[container_widget_name] == nil then
            params[container_widget_name] = {
                widget =
                {
                    slotpos = {},
                    slotbg = {},
                    animbank = "ui_fish_box_5x4",
                    animbuild = "tbat_container_pear_cat",
                    pos = Vector3(0, 50, 0),
                    side_align_tip = 100,
                },
                type = "chest",
                opensound = "tbat_sound_stage_1/tbat_container_pear_cat/open",
		        closesound = "tbat_sound_stage_1/tbat_container_pear_cat/close",
            }
            ------------------------------------------------------------------------------------------
            ---
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            --- 左上角是格子1
                --- 左上角是格子1
                local x_num = 16
                local y_num = 6
                local start_x, start_y = -670, -260
                local slot_offset = 82
                local single_slot_bg = { image = "tbat_container_pear_cat_slot.tex", atlas = "images/widgets/tbat_container_pear_cat_slot.xml" }
                local line_delta = 48
                local vertical_line_delta = -7  -- 新增垂直间隔变量
                for y = 1, y_num do
                    for x = 1, x_num do
                        local x_pos = slot_offset * (x - 1) + start_x + math.floor((x-1)/4)*line_delta
                        local y_pos = slot_offset * (y_num - y) + start_y + math.floor((y-1)/1)*vertical_line_delta + 23  -- 修改y_pos的计算方式
                        table.insert(widget_data.widget.slotpos, Vector3(x_pos, y_pos, 0))
                        table.insert(widget_data.widget.slotbg, single_slot_bg)
                    end
                end
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    -- if item.replica._.container then
                    --     return false
                    -- end
                    return true
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
        inst:PlayAnim("open",false)
        inst:PushAnim("idle",true)
        inst.opener = _table and _table.doer
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_pear_cat/open")
    end
    local function on_close(inst,_table)
        inst:PlayAnim("close",false)
        inst:PushAnim("idle",true)
        inst.opener = nil
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_pear_cat/close")
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
return add_container_before_not_ismastersim_return