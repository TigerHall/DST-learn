--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    容器界面参数配置

    需要单独的prefab

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ UI模块
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----
    local container_widget_name = "tbat_building_lavender_flower_house_wild_container"
    local this_prefab = "tbat_building_lavender_flower_house_wild"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 容器界面
    local all_container_widgets = require("containers")
    local params = all_container_widgets.params
    if params[container_widget_name] == nil then
        ------------------------------------------------------------------------------------------
        ---
            params[container_widget_name] = {}
            local widget_data = params[container_widget_name]
        ------------------------------------------------------------------------------------------
        ---
            widget_data.widget = {
                    slotpos = {},
                    slotbg = {},
                    animbank = "ui_construction_4x1",
                    animbuild = "ui_construction_4x1",
                    pos = Vector3(200, 0, 0),
                    top_align_tip = 50,
                    buttoninfo =
                    {
                        text = TBAT:GetString2(this_prefab,"action_button_str") or STRINGS.ACTIONS.APPLYCONSTRUCTION.GENERIC,
                        position = Vector3(0, -94, 0),
                    },
                    --V2C: -override the default widget sound, which is heard only by the client
                    --     -most containers disable the client sfx via skipopensnd/skipclosesnd,
                    --      and play it in world space through the prefab instead.
                    opensound = "dontstarve/wilson/chest_open",
                    closesound = "dontstarve/wilson/chest_close",
                    --
                }
                widget_data.usespecificslotsforitems = true
                widget_data.type = "cooker"
        ------------------------------------------------------------------------------------------
        --- slot 坐标和背景
            local single_slot_bg = { image = "tbat_building_lavender_flower_house_slot.tex", atlas = "images/widgets/tbat_building_lavender_flower_house_slot.xml" }
            for i = 1, 5 do
                table.insert(widget_data.widget.slotpos, Vector3(0, i*75, 0))
                table.insert(widget_data.widget.slotbg, single_slot_bg)                    
            end
        ------------------------------------------------------------------------------------------
        ---- item test
            widget_data.itemtestfn =  function(container_com, item, slot)
                local doer = container_com.inst.entity:GetParent()
                return doer ~= nil
                    and doer.components.constructionbuilderuidata ~= nil
                    and doer.components.constructionbuilderuidata:GetIngredientForSlot(slot) == item.prefab
            end
        ------------------------------------------------------------------------------------------
        --- 按钮
            widget_data.widget.buttoninfo.fn = function(inst, doer)
                if inst.components.container ~= nil then
                    BufferedAction(doer, inst, ACTIONS.APPLYCONSTRUCTION):Do()
                elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
                    SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.APPLYCONSTRUCTION.code, inst, ACTIONS.APPLYCONSTRUCTION.mod_name)
                end
            end
        ------------------------------------------------------------------------------------------
        --- 按钮激活
            widget_data.widget.buttoninfo.validfn = function(inst)
                return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
            end
        ------------------------------------------------------------------------------------------
    end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 安装容器界面的标准流程
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
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_pear_cat/open")
    end
    local function on_close(inst,_table)
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_container_pear_cat/close")
    end
    local function add_container_before_not_ismastersim_return(inst)
        -------------------------------------------------------------------------------------------------
        ----
            inst:ListenForEvent("TBAT_OnEntityReplicated.container",container_replica_init)
            if TheWorld.ismastersim then
                inst:AddComponent("container")
                container_Widget_change(inst.components.container)
                inst:ListenForEvent("onclose",on_close)
                inst:ListenForEvent("onopen",on_open)
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
--- 自定义
    local function hook_widget(inst,front_root)
        --------------------------------------------------------------
        --- 前置参数
            local bank_build = "tbat_building_lavender_flower_house"
        --------------------------------------------------------------
        --- 配置隐藏原有物品
            front_root.bganim:Hide()
            front_root.button:Hide()
            -- front_root.button:SetPosition(100,0,0)
        --------------------------------------------------------------
        --- 
            local box = front_root:AddChild(Widget())
            box:MoveToBack()
            local box_scale = 1.8
            box:SetScale(box_scale,box_scale,box_scale)
        --------------------------------------------------------------
        --- 新的背景。
            local bg = box:AddChild(UIAnim())
            local bg_anim = bg:GetAnimState()
            bg_anim:SetBank(bank_build)
            bg_anim:SetBuild(bank_build)
            bg_anim:PlayAnimation("bg",true)
        --------------------------------------------------------------
        --- slot 坐标重做
            local start_y = 270
            local start_x = 0
            local delta_y = 130
            local points = {}
            for i = 1, 5, 1 do
                table.insert(points,Vector3(start_x,start_y-delta_y*(i-1),0))
            end
            for i = 1, 5, 1 do
                local item_slot = front_root.inv[i]
                local pt = points[i]
                item_slot:SetPosition(pt.x,pt.y,0)
            end
        --------------------------------------------------------------
        --- 按钮
            local decoration_button = box:AddChild(AnimButton(bank_build,{
                idle = "decoration_button",
                over = "decoration_button",
                disabled = "decoration_button",
            }))
            decoration_button:SetPosition(0,230,0)
            decoration_button:SetOnClick(function()
                local widget = inst.replica.container:GetWidget()
                if widget.buttoninfo.validfn(inst) then
                    widget.buttoninfo.fn(inst,ThePlayer)
                    front_root.inst:PushEvent("force_close")
                end
            end)
        --------------------------------------------------------------
        --- close button
            local close_button = box:AddChild(AnimButton(bank_build,{
                idle = "close_button",
                over = "close_button",
                disabled = "close_button",
            }))
            close_button:SetPosition(70,190,0)
            close_button:SetOnClick(function()
                -- print("close_button")
                front_root.inst:PushEvent("force_close")
            end)
        --------------------------------------------------------------
        --- 封装close
            front_root.inst:ListenForEvent("force_close",function()
                TBAT.FNS:RPC_PushEvent(ThePlayer,"CLOSE_WIDGET",{
                    userid = ThePlayer.userid,
                },inst)
                front_root:Hide()
            end)
        --------------------------------------------------------------
        --- 尝试配置同步关闭
            local item_slot = front_root.inv[1]
            item_slot.__old_Kill = item_slot.Kill
            item_slot.Kill = function(...)
                item_slot.__old_Kill(...)
                front_root:Hide()
            end
        --------------------------------------------------------------
    end
    local function widget_open(inst,front_root)
        hook_widget(inst,front_root)
    end
    local function close_widget_by_rpc(inst,data)
        local userid = data and data.userid
        if userid then
            local doer = LookupPlayerInstByUserID(userid)
            if doer then
                inst.components.container:Close(doer)
                if inst.components.constructionsite then
                    inst.components.constructionsite:OnStopConstruction(doer)
                end
                if doer.sg and not doer.sg:HasStateTag("busy") then
                    doer.sg:GoToState("idle")
                end
            end
        end
    end
    local function hud_update_event_install(inst)
        inst:ListenForEvent("tbat_event.container_widget_open",widget_open)
        if not TheWorld.ismastersim then
            return
        end
        inst:ListenForEvent("CLOSE_WIDGET",close_widget_by_rpc)
    end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 文字修改
    --[[
        STRINGS.ACTIONS.STOPCONSTRUCTION.OFFER
        STRINGS.ACTIONS.APPLYCONSTRUCTION.OFFER
    ]]--
    --------------------------------------------------------------------------------------------------------
    -- stop
        local old_STOPCONSTRUCTION_strfn = ACTIONS.STOPCONSTRUCTION.strfn
        ACTIONS.STOPCONSTRUCTION.strfn = function(act,...)
            if act.target and act.target:HasTag(this_prefab) then
                return "TBAT_STOP_CONSTRUCTION"
            end
            return old_STOPCONSTRUCTION_strfn(act,...)
        end
        STRINGS.ACTIONS.STOPCONSTRUCTION.TBAT_STOP_CONSTRUCTION = TBAT:GetString2(this_prefab,"action_stop_str")
    --------------------------------------------------------------------------------------------------------
    --- start
        local old_APPLYCONSTRUCTION_strfn = ACTIONS.APPLYCONSTRUCTION.strfn
        ACTIONS.APPLYCONSTRUCTION.strfn = function(act,...)
            -- print("APPLYCONSTRUCTION 6666 ",act.target)
            if act.target and act.target:HasTag(this_prefab) then
                return "TBAT_APPLY_CONSTRUCTION"
            end
            return old_APPLYCONSTRUCTION_strfn(act,...)
        end
        STRINGS.ACTIONS.APPLYCONSTRUCTION.TBAT_APPLY_CONSTRUCTION = TBAT:GetString2(this_prefab,"action_start_str")
    --------------------------------------------------------------------------------------------------------
    --- start 另外一个
        local old_CONSTRUCT_strfn = ACTIONS.CONSTRUCT.strfn
        ACTIONS.CONSTRUCT.strfn = function(act,...)
            if act.target and act.target:HasTag(this_prefab) then
                return "TBAT_CONSTRUCT"
            end
            return old_CONSTRUCT_strfn(act,...)
        end
        STRINGS.ACTIONS.CONSTRUCT.TBAT_CONSTRUCT = TBAT:GetString2(this_prefab,"action_start_str")
    --------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器prefab。  inst.components.constructionsite:SetConstructionPrefab("construction_container")  使用的prefab。
    local assets = {
        Asset("ANIM", "anim/tbat_building_lavender_flower_house.zip"),
        Asset("IMAGE", "images/widgets/tbat_building_lavender_flower_house_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_building_lavender_flower_house_slot.xml"),
    }
    local function fn()
        -----------------------------------------------------------
        --- 基础的模块组
            local inst = CreateEntity()
            inst.entity:AddSoundEmitter()
            inst.entity:AddTransform()
            inst.entity:AddNetwork()
            inst:AddTag("bundle")
            --V2C: blank string for controller action prompt
            inst.name = " "
            inst.entity:SetPristine()
        -----------------------------------------------------------
        --- 容器界面安装和修改
            add_container_before_not_ismastersim_return(inst)
            hud_update_event_install(inst)
        -----------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst.persists = false   -- 是否留存到下次存档重启
        -----------------------------------------------------------
        return inst
    end
    return Prefab(container_widget_name, fn, assets)
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------