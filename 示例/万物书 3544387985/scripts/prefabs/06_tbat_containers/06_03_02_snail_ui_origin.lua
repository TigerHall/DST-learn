--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ 界面调试
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function create_hud(inst,front_root,container_root)        
        -------------------------------------------------------------------------------
        ---
            local box = front_root:AddChild(Widget())
            local bank_build = "tbat_container_mushroom_snail_cauldron_ui"
            local scale = 0.6
            box:SetScale(scale,scale)
            box:SetPosition(0,50)
        -------------------------------------------------------------------------------
        --- 带洞穴的时候，瞬间离开加载范围，导致inst直接移除，界面相关的东西必须跟着移除
            local remove_event_fn = function()
                container_root:Kill()
                front_root:Kill()
            end
            front_root.inst:ListenForEvent("onremove",remove_event_fn,inst)
            container_root.inst:ListenForEvent("onremove",remove_event_fn,inst)
        -------------------------------------------------------------------------------
        --- 背景
            local bg = box:AddChild(UIAnim())
            bg:GetAnimState():SetBank(bank_build)
            bg:GetAnimState():SetBuild(bank_build)
            bg:GetAnimState():PlayAnimation("bg",true)
            bg:GetAnimState():Hide("BUBBLE")
        -------------------------------------------------------------------------------
        --- 关闭按钮
            local close_btn = box:AddChild(AnimButton(bank_build,{idle = "close_button",over = "close_button",disabled = "close_button"}))
            close_btn:SetOnClick(function()
                front_root.inst:PushEvent("close_widget")
            end)
            close_btn:SetPosition(470,40)
        -------------------------------------------------------------------------------
        --- 炼制按钮 中心点
            local main_button_x,main_button_y = -205,-100
        -------------------------------------------------------------------------------
        --- 特效 fx 
            local fx = box:AddChild(UIAnim())
            fx:GetAnimState():SetBank(bank_build)
            fx:GetAnimState():SetBuild(bank_build)
            fx:GetAnimState():PlayAnimation("cycle_normal",true)
            fx:SetPosition(main_button_x,main_button_y)
            local fx_out = box:AddChild(UIAnim())
            fx_out:GetAnimState():SetBank(bank_build)
            fx_out:GetAnimState():SetBuild(bank_build)
            fx_out:GetAnimState():PlayAnimation("cycle_out_normal",true)
            fx_out:SetPosition(main_button_x,main_button_y)
            local working_flag = false
            local fx_recipe_avalable = false
            local fx_update_fn = function()
                if inst:HasOneOfTags({"working","can_be_harvest"}) then
                    if not working_flag then
                        fx:GetAnimState():PlayAnimation("cycle_full",true)
                        fx_out:GetAnimState():PlayAnimation("cycle_out_full",true)
                        fx:GetAnimState():Resume()
                        fx_out:GetAnimState():Resume()
                    end 
                    working_flag = true
                else
                    working_flag = false
                    if not fx_recipe_avalable then
                        fx:GetAnimState():PlayAnimation("cycle_normal")
                        fx_out:GetAnimState():PlayAnimation("cycle_out_normal")
                    else
                        fx:GetAnimState():PlayAnimation("cycle_full")
                        fx_out:GetAnimState():PlayAnimation("cycle_out_full")
                        fx:GetAnimState():Pause()
                        fx_out:GetAnimState():Pause()
                    end
                end
            end
            fx_update_fn()
            fx.inst:DoPeriodicTask(0.1,fx_update_fn)
            fx.inst:ListenForEvent("mushroom_snail_cauldron_update",fx_update_fn,inst)
        -------------------------------------------------------------------------------
        --- 容器图层顺序调整
            container_root:MoveToFront()
            container_root.bganim:Hide()
            for i = 1, 34, 1 do
                local ItemSlot = container_root.inv[i]
                ItemSlot.__old_OnGainFocus = ItemSlot.OnGainFocus
                ItemSlot.OnGainFocus = function(...)
                    ItemSlot:MoveToFront()
                    return ItemSlot.__old_OnGainFocus(...)
                end
            end
        -------------------------------------------------------------------------------
        --- 30 slots
            local start_x,start_y = 60,130
            local delta = 70
            local num = 1
            local points = {}
            for y =1 ,6,1 do
                for x =1 ,5,1 do
                    table.insert(points,Vector3( start_x + (x-1)*delta  , start_y - (y-1)*delta , 0 ))
                end
            end
            for i = 1, 30, 1 do
                local pt = points[i]
                container_root.inv[i]:SetPosition(pt.x,pt.y,pt.z)
            end
        -------------------------------------------------------------------------------
        --- 预设4个位置
            local prepared_offset = 100
            local prepared_slots_pt = {
                Vector3(main_button_x - prepared_offset,main_button_y,0),
                Vector3(main_button_x + prepared_offset,main_button_y,0),
                Vector3(main_button_x,main_button_y - prepared_offset,0),
                Vector3(main_button_x,main_button_y + prepared_offset,0),
            }
            local prepared_slots = {}
            local offset_slot = 30
            local prepared_slots_box = box:AddChild(Widget())
            for i = 1, 4, 1 do
                local pt = prepared_slots_pt[i]
                local item_slot = container_root.inv[i+offset_slot]
                item_slot:SetPosition(pt.x,pt.y,pt.z)
                table.insert(prepared_slots,item_slot)
                prepared_slots_box:AddChild(item_slot)
            end
            prepared_slots_box:Hide()
        -------------------------------------------------------------------------------
        --- 开始按钮
            local button_start = box:AddChild(AnimButton(bank_build,{idle = "start_button",over = "start_button",disabled = "start_button"}))
            button_start:SetPosition(main_button_x,main_button_y)
            button_start:SetOnClick(function()
                inst.replica.tbat_com_mushroom_snail_cauldron:OnStartClick(ThePlayer)
            end)
            button_start:Hide()
            local function button_start_update_fn()
                if inst:HasOneOfTags({"working","can_be_harvest"}) then
                    button_start:Hide()
                    prepared_slots_box:Hide()
                    bg:GetAnimState():Show("BUBBLE")
                else
                    button_start:Show()
                    prepared_slots_box:Show()
                    bg:GetAnimState():Hide("BUBBLE")
                end
            end
            button_start_update_fn()
            button_start.inst:DoPeriodicTask(0.1,button_start_update_fn)
            button_start.inst:ListenForEvent("mushroom_snail_cauldron_update",button_start_update_fn,inst)
        -------------------------------------------------------------------------------
        --- 蜗牛装饰
            local snail = box:AddChild(UIAnim())
            snail:GetAnimState():SetBank(bank_build)
            snail:GetAnimState():SetBuild(bank_build)
            snail:GetAnimState():PlayAnimation("snail",true)
            snail:SetPosition(-260,-330)
        -------------------------------------------------------------------------------
        --- 拖动
            local moving_click_target = bg
            moving_click_target.__old_OnMouseButton = moving_click_target.OnMouseButton
            local MOUSE_RIGHT = 1001
            local MOUSE_LEFT = 1000
            moving_click_target.OnMouseButton = function(self,button, down, x, y)
                if down and button == MOUSE_RIGHT then 
                    if moving_click_target.mouse_handler then
                        moving_click_target.mouse_handler:Remove()
                    end
                    moving_click_target.mouse_handler = TheInput:AddMouseButtonHandler(function(button,down,x,y)
                            if not down and button == MOUSE_RIGHT then
                                moving_click_target.mouse_handler:Remove()
                                moving_click_target.mouse_handler = nil
                                front_root:StopFollowMouse()
                                local mouse_x,mouse_y = TheSim:GetPosition()
                                front_root:SetPosition(mouse_x,mouse_y)
                            end
                    end)
                    front_root:FollowMouse()
                    moving_click_target.inst:ListenForEvent("onremove",function()
                        if moving_click_target.mouse_handler then
                            moving_click_target.mouse_handler:Remove()
                        end
                    end)
                end
                return self.__old_OnMouseButton(self,button, down, x, y)
            end
        -------------------------------------------------------------------------------
        --- result image 结果图标
            local function GetResultImage(root,recipe_data,cook_fail)
                local preview_data_or_fn = recipe_data.preview
                if cook_fail then
                    preview_data_or_fn = recipe_data.fail_preview
                end
                if type( preview_data_or_fn ) == "function" then
                    return root:AddChild(preview_data_or_fn(root))
                elseif type( preview_data_or_fn ) == "table" then
                    local atlas = preview_data_or_fn.atlas
                    local image = preview_data_or_fn.image
                    local offset = preview_data_or_fn.offset or Vector3(0,0,0)
                    local scale = preview_data_or_fn.scale or Vector3(1,1,1)
                    local image_widget = root:AddChild(Image(atlas,image))
                    image_widget:SetPosition(offset.x,offset.y,offset.z)
                    image_widget:SetScale(scale.x,scale.y,scale.z)
                    return image_widget
                end                
            end
        -------------------------------------------------------------------------------
        --- 结果按钮。
            local result_button = box:AddChild(AnimButton(bank_build,{idle = "slot",over = "slot",disabled = "slot"}))
            result_button:SetPosition(main_button_x,main_button_y)
            result_button:Hide()
            result_button:SetScale(3,3,3)
            result_button.anim:GetAnimState():SetMultColour(1,1,1,0)
            local result_preview = box:AddChild(UIAnim())
            result_preview:SetPosition(main_button_x,main_button_y-50)
            result_preview:Hide()
            result_preview:GetAnimState():SetBank(bank_build)
            result_preview:GetAnimState():SetBuild(bank_build)
            result_preview:GetAnimState():PlayAnimation("slot")
            result_preview:SetScale(0.7,0.7,0.7)
            local function result_button_update_fn()
                if inst:HasTag("can_be_harvest") then
                    result_button:Show()
                    result_preview:Show()
                else
                    result_button:Hide()
                    result_preview:Hide()
                end
                local current_product = inst.replica.tbat_com_mushroom_snail_cauldron:GetOriginProduct()
                local current_product_data = TBAT.MSC:GetRecipeData(current_product)
                if result_button.product ~= current_product and current_product_data then
                    if result_button.diplay_box then
                        result_button.diplay_box:Kill()
                    end
                    result_button.product = current_product
                    ----------------------------------------------------------------------------------
                    --- 图标
                        local cook_fail = inst.replica.tbat_com_mushroom_snail_cauldron:GetCookFail()
                        local recipe_data = inst.replica.tbat_com_mushroom_snail_cauldron:GetRecipeData()
                        -- result_button.diplay_box = GetResultImage(result_button.anim,current_product_data,cook_fail)
                        local overridebuild = cook_fail and recipe_data.fail_overridebuild or recipe_data.overridebuild
                        local overridesymbolname = cook_fail and recipe_data.fail_overridesymbolname or recipe_data.overridesymbolname
                        result_preview:GetAnimState():OverrideSymbol("slot",overridebuild,overridesymbolname)
                    ----------------------------------------------------------------------------------
                end
            end
            result_button_update_fn()
            result_button.inst:DoPeriodicTask(0.1,result_button_update_fn)
            result_button.inst:ListenForEvent("mushroom_snail_cauldron_update",result_button_update_fn,inst)
            result_button:SetOnClick(function()
                inst.replica.tbat_com_mushroom_snail_cauldron:OnHarvestClick(ThePlayer)
            end)
        -------------------------------------------------------------------------------
        --- preveiw box
            local preview_box_root = box:AddChild(UIAnim())
            preview_box_root:GetAnimState():SetBank(bank_build)
            preview_box_root:GetAnimState():SetBuild(bank_build)
            preview_box_root:GetAnimState():PlayAnimation("preveiw_solt",true)
            preview_box_root:SetPosition(-80,-250)
        -------------------------------------------------------------------------------
        --- preveiw slot
            local prevew_box = preview_box_root:AddChild(Widget())
            prevew_box:SetPosition(0,0)
            preview_box_root:Hide()
        -------------------------------------------------------------------------------
        --- preveiw 周期性任务
            local last_product_prefab = nil
            local function GetItemInSolts()
                return inst.replica.container:GetItemInSlot(31),
                    inst.replica.container:GetItemInSlot(32),
                    inst.replica.container:GetItemInSlot(33),
                    inst.replica.container:GetItemInSlot(34)
            end
            front_root.inst:DoPeriodicTask(0.3,function()
                local product,recipe_data = TBAT.MSC:TestByItems(GetItemInSolts())
                if product ~= last_product_prefab then
                    if product == nil then
                        preview_box_root:Hide()
                        fx_recipe_avalable = false
                    else
                        preview_box_root:Show()
                        local has_recipe = ThePlayer.replica.tbat_com_mushroom_snail_cauldron__for_player:HasRecipe(product)
                        local has_fail_product = recipe_data.fail_product_prefab ~= nil
                        local cook_fail = has_fail_product and not has_recipe
                        local ret_img = GetResultImage(prevew_box,recipe_data)
                        if cook_fail then
                            preview_box_root:GetAnimState():Show("WARNING")
                            ret_img:SetPosition(-10,0,0)
                        else
                            preview_box_root:GetAnimState():Hide("WARNING")
                        end
                        fx_recipe_avalable = true
                    end
                    last_product_prefab = product
                end
                if product == nil then
                    preview_box_root:Hide()
                end
            end)
        -------------------------------------------------------------------------------
        --- 计时器。
            local timer = box:AddChild(Text(CODEFONT,40,"1",{ 0/255 , 0/255 ,0/255 , 1}))
            timer:SetPosition(main_button_x,main_button_y)
            timer:Hide()
            local function timer_update_fn()
                if inst:HasTag("working") then
                    timer:Show()
                    timer:SetString(tostring(inst.replica.tbat_com_mushroom_snail_cauldron:GetRemainingTime()))
                else
                    timer:Hide()
                end
            end
            timer.inst:ListenForEvent("mushroom_snail_cauldron_update",timer_update_fn,inst)
            timer_update_fn()
        -------------------------------------------------------------------------------
    
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    return function(inst,front_root,container_root)
        -- if TBAT._____new_root_fn then
        --     TBAT._____new_root_fn(inst,front_root,container_root)
        -- end
        create_hud(inst,front_root,container_root)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------