--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    容器界面
    
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local this_prefab = "tbat_container_mushroom_snail_cauldron"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- test
    local function test_fn(container_com, item, slot)
        --------------------------------------------------------------------
        --- 物品检查
            if not TBAT.MSC:CheckItem(item) then
                return false
            end
        --------------------------------------------------------------------
        --- 格子检查
            if slot == nil then
                -----------------------------------------------
                --- shift 点击 自动进入
                    for i = 1, 30, 1 do
                        local item = container_com:GetItemInSlot(i)
                        if item == nil then
                            return true
                        end
                    end
                    if not container_com.inst:HasOneOfTags({"working","can_be_harvest"}) then
                        return true
                    end
                    return false
                -----------------------------------------------
            else
                -----------------------------------------------
                --- 手动放入
                    if slot <= 30 then
                        return true
                    else
                        if container_com.inst:HasOneOfTags({"working","can_be_harvest"}) then
                            return false
                        else
                            return true
                        end
                    end
                -----------------------------------------------
            end
        --------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- container widget data
    -----------------------------------------------------------------------------------
    ----- 容器界面名 --- 要独特一点，避免冲突
        local container_widget_name = this_prefab
        local slot_num = 30 + 4
    -----------------------------------------------------------------------------------
    ----- 检查和注册新的容器界面
        local all_container_widgets = require("containers")
        all_container_widgets.MAXITEMSLOTS = math.max(all_container_widgets.MAXITEMSLOTS, slot_num)
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
                    side_align_tip = 100,
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
                local single_slot_bg = { image = "tbat_container_mushroom_snail_cauldron_slot.tex", atlas = "images/widgets/tbat_container_mushroom_snail_cauldron_slot.xml" }
                for i = 1, slot_num do
                    table.insert(widget_data.widget.slotpos, Vector3(0, 0, 0))
                    table.insert(widget_data.widget.slotbg, single_slot_bg)                    
                end
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    return test_fn(container_com, item, slot)
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
        local doer = _table and _table.doer
        if doer then
            doer:PushEvent("tbat_container_mushroom_snail_cauldron.open",{
                pot = inst,
                doer = doer,
            })
        end
    end
    local function on_close(inst,_table)
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_cherry_blossom_rabbit/close")
        local doer = _table and _table.doer
        if doer then
            doer:PushEvent("tbat_container_mushroom_snail_cauldron.close",{
                pot = inst,
                doer = doer,
            })
        end
    end
    local function add_container_before_not_ismastersim_return(inst)
        -------------------------------------------------------------------------------------------------
        ----
            inst:ListenForEvent("TBAT_OnEntityReplicated.container",container_replica_init)
            if TheWorld.ismastersim then
                inst:AddComponent("container")
                inst.components.container.openlimit = 1
                container_Widget_change(inst.components.container)
                inst:ListenForEvent("onclose",on_close)
                inst:ListenForEvent("onopen",on_open)
                inst.components.container:EnableInfiniteStackSize(true)
            end
        -------------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return add_container_before_not_ismastersim_return