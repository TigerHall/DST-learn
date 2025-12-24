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
    local this_prefab = "tbat_building_lavender_flower_house_visual_container"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 
    local reward_items = {
        ["tbat_material_lavender_laundry_detergent"] = 0.5,  --- 薰衣草洗衣液
        ["tbat_plant_lavender_bush_kit"] = 0.05,  --- 薰衣草草丛
        ["tbat_food_fantasy_apple_seeds"] = 0.15,  --- 种子
        ["tbat_food_fantasy_peach_seeds"] = 0.15,  --- 种子
        ["tbat_food_fantasy_potato_seeds"] = 0.15,  --- 种子
    }
    local function get_random_reward_prefab()
        local total_prob = 0
        for _, v in pairs(reward_items) do
            total_prob = total_prob + v
        end
        -- 检查总概率是否为0（避免除零错误）
        if total_prob <= 0 then
            return "tbat_material_lavender_laundry_detergent"
        end
        local rand = math.random() * total_prob  -- 生成 [0, total_prob) 的随机数
        for k, v in pairs(reward_items) do
            if rand < v then  -- 修正：必须用 '<' 而非 '<='
                return k
            end
            rand = rand - v  -- 仅需更新 rand，无需修改 total_prob
        end
        return "tbat_material_lavender_laundry_detergent"  -- 理论上不会执行到此处（总概率已覆盖）
    end
    local function item_test(item)
        return reward_items[item.prefab] ~= nil
    end
    local function acitve_reward_event_fn(inst,data)
        local num = data and data.num or 1
        local prefab = data and data.prefab
        for i = 1, num, 1 do
            inst.components.container:GiveItem(SpawnPrefab(get_random_reward_prefab()))
        end
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
                    slotbg = {},
                    animbank = "ui_construction_4x1",
                    animbuild = "ui_construction_4x1",
                    pos = Vector3(200, 0, 0),
                    top_align_tip = 50,
                }
                widget_data.type = this_prefab or "cooker"
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
--- 自定义界面
    local function hook_widget(inst,front_root)
        --------------------------------------------------------------
        --- 前置参数
            local bank_build = "tbat_building_lavender_flower_house"
        --------------------------------------------------------------
        --- 配置隐藏原有物品
            front_root.bganim:Hide()
        --------------------------------------------------------------
        --- 
            local box = front_root:AddChild(Widget())
            box:MoveToBack()
            local box_scale = 1.2
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
            local start_y = 160
            local start_x = 0
            local delta_y = 80
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
            -- local decoration_button = box:AddChild(AnimButton(bank_build,{
            --     idle = "decoration_button",
            --     over = "decoration_button",
            --     disabled = "decoration_button",
            -- }))
            -- decoration_button:SetPosition(0,230,0)
            -- decoration_button:SetClickable(false)
            -- decoration_button:SetOnClick(function()
            --     local widget = inst.replica.container:GetWidget()
            --     if widget.buttoninfo.validfn(inst) then
            --         widget.buttoninfo.fn(inst,ThePlayer)
            --         front_root.inst:PushEvent("force_close")
            --     end
            -- end)
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
--- 密语
    local function WhisperTo(inst,player_or_userid,str)
        TBAT.FNS:Whisper(player_or_userid,{
            icondata = "tbat_building_lavender_flower_house" ,
            sender_name = TBAT:GetString2("tbat_building_lavender_flower_house","name.pet"),
            s_colour = {193/255,163/255,213/255},
            message = str,
            m_colour = {208/255,228/255,255/255},
        })
    end
    local function close_and_whisper_to(inst,data)
        local doer = data and data.doer
        if doer then
            WhisperTo(inst,doer,TBAT:GetString2("tbat_building_lavender_flower_house","container.close"))
        end
    end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 本体
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
            inst:AddTag("CLASSIFIED")
            inst:AddTag("FX")
            inst:AddTag("fx")
            inst:AddTag("NOBLOCK")
            inst:AddTag("NOCLICK")
            inst.entity:SetPristine()
        -----------------------------------------------------------
        --- 容器界面安装和修改
            add_container_before_not_ismastersim_return(inst)
            hud_update_event_install(inst)
            inst.WhisperTo = WhisperTo
        -----------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
            inst.persists = false   -- 是否留存到下次存档重启
        -----------------------------------------------------------
        --- 传递过来的数据
            inst:ListenForEvent("pet_pick",acitve_reward_event_fn)
            inst:ListenForEvent("onclose",close_and_whisper_to)
        -----------------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(0)
        -----------------------------------------------------------
        return inst
    end
    return Prefab(this_prefab, fn, assets)
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------