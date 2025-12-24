--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    核心逻辑

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ 
    local AUTO_SEARCH_CYCLE = TBAT.CONFIG.SPECIAL_CONTAINER_MAP_SEARCH_CYCLE or 10
    local AUTO_SEARCH_ON = TBAT.CONFIG.SPECIAL_CONTAINER_MAP_SEARCH or false
    local AUTO_SEARCH_FULL_MAP = TBAT.CONFIG.PEAR_CAT_SEARCH_RADIUS == 999
    local AUTO_SEARCH_RADIUS = TBAT.CONFIG.PEAR_CAT_SEARCH_RADIUS or 300
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------ 界面控件
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
    local Screen = require "widgets/screen"
    local AnimButton = require "widgets/animbutton"
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器界面更新
    local hud_x,hud_y = nil,nil
    local function hud_hook_fn(inst,front_root)
        --------------------------------------------------------
        --- 新建根节点
            local new_root = front_root.parent:AddChild(Widget())
            new_root:AddChild(front_root)
            new_root.inst:DoPeriodicTask(0.5,function()
                if not front_root.inst:IsValid() then
                    new_root:Kill()
                end
            end)
        --------------------------------------------------------
        --- 重置缩放
            new_root:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            new_root:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            new_root:SetScaleMode(TBAT.PARAM.CONTAINER_HOOKED_HUD_SCALE_MODE)   --- 缩放模式
            local scale = 0.4
            front_root:SetScale(scale,scale)

            local screen_w,screen_h = TheSim:GetScreenSize()                
            local offset_x, offset_y = 0, -50
            local x,y = screen_w/2+offset_x,screen_h/2+offset_y
            if hud_x and hud_y then
                x,y = hud_x,hud_y
            end
            new_root:SetPosition(x,y)
        --------------------------------------------------------
        --- 清除
            inst.hud_data = inst.hud_data or {}
            for k, v in pairs(inst.hud_data) do
                v:Kill()
            end
            inst.hud_data = {}
            front_root.inst:ListenForEvent("close",function()
                for k, v in pairs(inst.hud_data) do
                    v:Kill()
                end
                inst.hud_data = {}
            end)
        --------------------------------------------------------
        --- 关闭事件。让按钮 在关闭的瞬间 清除。
            local tempAnimState = TBAT.FNS:Hook_Inst_AnimState(front_root.bganim.inst)
            tempAnimState.old_PlayAnimation = tempAnimState.PlayAnimation
            tempAnimState.PlayAnimation = function(self,anim,flag)
                if anim == "close" then
                    front_root.inst:PushEvent("close")
                end
                self.old_PlayAnimation(self,anim,flag)
            end
        --------------------------------------------------------
        --- 刷新按钮。
            local button_refresh = front_root:AddChild(AnimButton("tbat_container_pear_cat",{
                idle = "ui_cat",
                over = "ui_cat",
                disabled = "ui_cat",
            }))
            button_refresh:SetOnClick(function()
                if button_refresh.cd then
                    return
                end
                button_refresh.cd = button_refresh.inst:DoTaskInTime(3,function()
                    button_refresh.cd = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"refresh_slots",nil,inst)
            end)
            button_refresh:SetPosition(-240,270,0)
            local tempAnimState = TBAT.FNS:Hook_Inst_AnimState(button_refresh.anim.inst)
            tempAnimState.old_PlayAnimation = tempAnimState.PlayAnimation
            tempAnimState.PlayAnimation = function(self,anim,flag)
                self.old_PlayAnimation(self,anim,true)
            end            
            button_refresh.anim:GetAnimState():PlayAnimation("ui_cat",true)
            button_refresh:MoveToBack()
            table.insert(inst.hud_data,button_refresh)            
        --------------------------------------------------------
        --- button in
            local button_in = front_root:AddChild(AnimButton("tbat_container_pear_cat",{
                idle = "button_in",
                over = "button_in",
                disabled = "button_in",
            }))
            button_in:SetOnClick(function()
                if button_in.cd then
                    return
                end
                button_in.cd = button_in.inst:DoTaskInTime(3,function()
                    button_in.cd = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"item_in",nil,inst)
            end)
            button_in:SetPosition(400,-400,0)
            table.insert(inst.hud_data,button_in)
        --------------------------------------------------------
        --- button close
            local button_close = front_root:AddChild(AnimButton("tbat_container_pear_cat",{
                idle = "button_close",
                over = "button_close",
                disabled = "button_close",
            }))
            button_close:SetOnClick(function()
                if button_close.cd then
                    return
                end
                button_close.cd = button_close.inst:DoTaskInTime(3,function()
                    button_close.cd = nil
                end)
                TBAT.FNS:RPC_PushEvent(ThePlayer,"close_contianer",nil,inst)
                front_root:Hide()
            end)
            button_close:SetPosition(-400,-400,0)
            table.insert(inst.hud_data,button_close)
        --------------------------------------------------------                        
        --- 点击拖动
        --- -- 旧写法暂时注释掉
            -- local move_btm = front_root:AddChild(AnimButton("tbat_container_pear_cat",{
            --     idle = "test",
            --     over = "test",
            --     disabled = "test",
            -- }))
            -- move_btm:SetPosition(0.9,0.9,0)
            -- move_btm:MoveToBack()
            -- move_btm:SetClickable(true)
            -- move_btm:SetOnClick(function()end)
            -- move_btm.clickoffset = Vector3(0,0,0)
            -- table.insert(inst.hud_data, move_btm)
            -- -----
            -- local start_pt = Vector3(0,0,0)
            -- local start_window_pt = Vector3(0,0,0)
            -- local function start_follow()
            --     start_pt = TheInput:GetScreenPosition()
            --     start_window_pt = new_root:GetPosition()
            --     if move_btm.inst.__task then
            --         move_btm.inst.__task:Cancel()
            --     end
            --     move_btm.inst.__task = move_btm.inst:DoPeriodicTask(FRAMES,function()
            --         local current_pt = TheInput:GetScreenPosition()
            --         local offset = current_pt - start_pt
            --         -- print(offset)
            --         local new_window_pt = start_window_pt + offset
            --         new_root:SetPosition(new_window_pt.x,new_window_pt.y)
            --     end)
            -- end
            -- local function stop_follow()
            --     if move_btm.inst.__task then
            --         move_btm.inst.__task:Cancel()
            --         move_btm.inst.__task = nil
            --     end
            --     local new_pt = new_root:GetPosition()
            --     hud_x,hud_y = new_pt.x,new_pt.y
            -- end
            -- local mouse_handler = TheInput:AddMouseButtonHandler(function(button, down, x, y)
            --     if down and button == MOUSEBUTTON_RIGHT then
            --         local ent = TheInput:GetHUDEntityUnderMouse()
            --         if ent == move_btm.anim.inst then
            --             start_follow()
            --         end
            --     else
            --         stop_follow()
            --     end
            -- end)
            -- front_root.inst:ListenForEvent("onremove", function()
            --     mouse_handler:Remove()
            -- end)
        --------------------------------------------------------
    end
    local function widget_open(inst,front_root)
        -- if TBAT.DEBUGGING and TBAT.hud_hook_fn then
        --     TBAT.hud_hook_fn(inst,front_root)
        --     return
        -- end
        hud_hook_fn(inst,front_root)
    end
    local function hud_update_event_install(inst)
        inst:ListenForEvent("tbat_event.container_widget_open",widget_open)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- events
    local function container_close_event(inst)
        inst.components.container:Close()
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 刷新物品
    local function ContainerSortItems(self,opener)
        if self.readonlycontainer then
            return
        end
        local data = {}
        local max_slots = self:GetNumSlots()
        local dropped_items = {}
        for index = 1,max_slots do
            local item = self:GetItemInSlot(index)
            if item then
                if item:HasOneOfTags({ "nonpotatable", "irreplaceable" }) then
                    self:DropItemBySlot(index)
                    table.insert(dropped_items, item)
                else
                    data[item.prefab] = data[item.prefab] or {}
                    local record = item:GetSaveRecord()
                    table.insert(data[item.prefab],record)
                    item:Remove()
                end
            end
        end
        for index, item in ipairs(dropped_items) do
            self:GiveItem(item)
        end
        for prefab, temp_records in pairs(data) do
            for k, record in pairs(temp_records) do
                self:GiveItem(SpawnSaveRecord(record))
            end
        end
    end
    local function container_item_refresh(inst)
        local opener = inst.opener
        if opener == nil then
            return
        end
        ContainerSortItems(inst.components.container,opener)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品进入
    local function container_is_full(inst,ignore_prefab)
        if ignore_prefab == nil then
            return inst.components.container:IsFull()
        end
        if not inst.components.container:IsFull() then
            return false
        end
        local num_slots = inst.components.container:GetNumSlots()
        for i = 1, num_slots, 1 do
            local item = inst.components.container:GetItemInSlot(i)
            if item and item.prefab == ignore_prefab then
                return false
            end
        end
        return true
    end
    local function search_and_pickup_items(inst)
        ---------------------------------------------------
        --- 
            -- print("search_and_pickup_items task start ")
        ---------------------------------------------------
        --- 
            if not inst:HasTag("lv2") then
                return
            end
            -- if inst.components.container:IsFull() then
            --     inst:PushEvent("refresh_slots")
            --     if inst.components.container:IsFull() then
            --         return
            --     end
            -- end
            -- print("lv2 task start",inst)
        ---------------------------------------------------
        --- 记录已经有的
            local prefab_list = {}
            local count = 0
            inst.components.container:ForEachItem(function(item)
                if item and item.prefab then
                    -- print("搜索目标:",item.prefab)
                    prefab_list[item.prefab] = true
                    count = count + 1
                end
            end)
            if count == 0 then
                return
            end
            -- print("TBAT: 梨花猫猫搜索中...",count)
        ---------------------------------------------------
        ---
            local searched_list = {}
            local function put_into(tempInst)                
                if tempInst and tempInst:IsValid()
                    and tempInst.prefab and prefab_list[tempInst.prefab]
                    and tempInst.entity:GetParent() == nil
                    and tempInst.components.inventoryitem and tempInst.components.inventoryitem.owner == nil
                    and tempInst.components.inventoryitem.cangoincontainer == true
                    -- and not inst.components.container:IsFull()
                    and not container_is_full(inst,tempInst.prefab)
                    and not tempInst:HasOneOfTags({"INLIMBO" ,"NOCLICK"})
                then
                    print("put_into",tempInst)
                    -- tempInst.components.inventoryitem.nobounce = true
                    tempInst.components.inventoryitem.canbepickedup = true
                    tempInst.components.inventoryitem.canbepickedupalive = true
                    OnEntityWake(tempInst.GUID)
                    inst.components.container:GiveItem(tempInst)
                    searched_list[tempInst.prefab] = (searched_list[tempInst.prefab] or 0) + 1
                end
                -- -- if inst.components.container:IsFull() then
                -- if container_is_full(inst,tempInst.prefab) then
                --     return false
                -- end
                return true
            end
        ---------------------------------------------------
        ---
            if AUTO_SEARCH_FULL_MAP then
                for k, tempInst in pairs(Ents) do
                    if put_into(tempInst) == false then                        
                        return
                    end
                end
                -- for k, v in pairs(searched_list) do
                --     print("+++",k,v)
                -- end
            else
                local x,y,z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x,0, z, AUTO_SEARCH_RADIUS, {"_inventoryitem"})
                for k,tempInst in pairs(ents) do                    
                    if put_into(tempInst) == false then
                        return
                    end
                end
            end
        ---------------------------------------------------
    end
    local function lv1_item_in(inst)
        local opener = inst.opener
        if opener == nil then
            return
        end
        ---------------------------------------------------
        --- 记录已经有的
            local prefab_list = {}
            inst.components.container:ForEachItem(function(item)
                if item and item.prefab and item.components.stackable then
                    prefab_list[item.prefab] = true
                end
            end)
        ---------------------------------------------------
        --- 遍历玩家身上的
            for k, item in pairs(opener.components.inventory.itemslots) do
                if item and prefab_list[item.prefab] then
                    opener.components.inventory:RemoveItemBySlot(k,true)
                    inst.components.container:GiveItem(item)
                end
            end
            for k, equipment in pairs(opener.components.inventory.equipslots) do
                if equipment and equipment.components.container then
                    for kk, item in pairs(equipment.components.container.slots) do
                        if item and prefab_list[item.prefab] then
                            equipment.components.container:RemoveItemBySlot(kk)
                            inst.components.container:GiveItem(item)
                        end
                    end
                end
            end
        ---------------------------------------------------


    end
    local function container_item_in(inst)
        -- if inst:HasTag("lv2") then
        --     -- lv2_item_in(inst)
        --     lv1_item_in(inst)
        --     return
        -- end
        lv1_item_in(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    if not TheNet:IsDedicated() then
        hud_update_event_install(inst)
    end
    if not TheWorld.ismastersim then
        return
    end

    inst:ListenForEvent("close_contianer",container_close_event)
    inst:ListenForEvent("refresh_slots",container_item_refresh)
    inst:ListenForEvent("item_in",container_item_in)

    if AUTO_SEARCH_ON then
        -- inst:DoPeriodicTask(AUTO_SEARCH_CYCLE,lv2_item_in,math.random(30))
        TheWorld:DoTaskInTime(math.random(30),function()
            if inst:IsValid() then
                TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(inst,AUTO_SEARCH_CYCLE,search_and_pickup_items)
            end            
        end)
    end

end