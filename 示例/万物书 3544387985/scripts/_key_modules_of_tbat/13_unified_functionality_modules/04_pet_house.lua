--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    由于3个宠物的房子有相同逻辑，统一封装API在这，统一维护.

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 参数
    local common_prefab = "tbat_building_pet_house_common"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 修改一些container API
    local function container_com_hook(inst) --- 修改API，屏蔽其他MOD的操作。
        local container = inst.components.container
        -- container.TBAT_DropItemBySlot = container.DropItemBySlot
        -- container.DropItemBySlot = function(self,...)
        --     if self.tbat_cmd then
        --         return self.TBAT_DropItemBySlot(self,...)
        --     end
        --     return nil
        -- end
        -- local API_NAMES = {"DropItemBySlot","DropEverythingWithTag","DropEverything","DropItem","DropOverstackedExcess","DropItemAt","CanTakeItemInSlot"}
        local API_NAMES = {"DropItemBySlot","DropEverythingWithTag","DropEverything","DropItem","DropOverstackedExcess","DropItemAt"}
        for k, api_name in pairs(API_NAMES) do
            container["TBAT_"..api_name] = container[api_name]
            container[api_name] = function(self,...)
                if self.tbat_cmd then
                    return self["TBAT_"..api_name](self,...)
                end
                return nil
            end
        end
        function container:TBAT_CMD(flag)
            self.tbat_cmd = flag
        end
        inst:ListenForEvent("special_give_item",function(_,item)
            container:TBAT_CMD(true)
            container:GiveItem(item)
            container:TBAT_CMD(false)
        end)
        inst:ListenForEvent("special_drop_item",function(_,item)
            container:TBAT_CMD(true)
            container:DropItem(item)
            container:TBAT_CMD(false)
        end)
    end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器界面注册
    ----- 容器界面名 --- 要独特一点，避免冲突
        local container_widget_name = "tbat_pet_house_container_widget"
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
                type = "tbat_pet_house_container_widget",
            }
            ------------------------------------------------------------------------------------------
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            --- 
            for y = 2.5, -0.5, -1 do
                for x = -1, 3 do
                    table.insert(widget_data.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
                end
            end
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    return item:HasTag("tbat_pet_eyebone") and container_com.inst:HasTag(item.prefab)
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
                -- inst:ListenForEvent("onclose",on_close)
                -- inst:ListenForEvent("onopen",on_open)
                -- inst.components.container:EnableInfiniteStackSize(true)
                -- inst.components.container.canbeopened = TBAT.DEBUGGING or false
                inst.components.container.canbeopened = false
                container_com_hook(inst)
                -- inst:DoTaskInTime(0.5,container_com_hook)
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
---- 交互
    local function workable_test_fn(inst,doer,right_click)
        if right_click then
            local weapon = doer.replica.combat:GetWeapon()
            if weapon and weapon:HasTag("HAMMER_tool") then
                return false
            end
            return true
        end
        return false
    end
    local function workable_on_work_fn(inst,doer)
        inst:PushEvent("special_work_by",doer)
        local backpack = doer.TBAT_Get_Pet_Eyebone_Backpack and doer:TBAT_Get_Pet_Eyebone_Backpack()
        if backpack == nil then
            return false
        end
        local items = backpack.components.container:GetItemsWithTag(inst.eyebone_prefab) or {}
        local item = items[1]
        if item == nil then
            return false,"give_back_item_fail"
        end
        if inst.components.container:IsFull() then
            return false,"house_full"
        end
        backpack:PushEvent("special_drop_item",item)
        inst:PushEvent("special_give_item",item)

        item:PushEvent("RestartBrain")
        inst:PushEvent("give_back_eyebone_succeed",{
            item = item,
            doer = doer,
        })
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("stop_follow_player",TBAT:GetString2(common_prefab,"stop_follow_player"))
        replica_com:SetSGAction("dolongaction")
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- on build event
    local function on_build_event(inst,_table)
        inst.components.tbat_data:Set("build",true)
        -- inst:PushEvent("pet_spawn")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 宠物生成
    local function pet_spawn_event(inst)
        if not (inst.eyebone_prefab and PrefabExists(inst.eyebone_prefab) )then
            return
        end
        if inst.components.container:IsFull() then
            return
        end
        local item = SpawnPrefab(inst.eyebone_prefab)
        inst:PushEvent("special_give_item",item)
    end
    local function pet_spawn_task(inst)
        if not inst.components.container:IsEmpty() then
            inst.components.tbat_data:Set("days",0)
            return
        end
        local days = inst.components.tbat_data:Add("days",1)
        if days >= 3 then
            inst:PushEvent("pet_spawn")
            inst.components.tbat_data:Set("days",0)            
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- init
    local function init_0(inst)
        if not inst.components.tbat_data:Get("build") and inst.components.workable then
            inst:RemoveComponent("workable")
        end
        if inst.components.tbat_data:Get("inited") then
            return
        end
        inst.components.tbat_data:Set("inited",true)
        inst:PushEvent("pet_spawn")
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 关键模块安装
    function TBAT.PET_MODULES:PetHouseComInstall(inst,eyebone_prefab)
        --------------------------------------------------------------
        ----
            if TheWorld.ismastersim then
                inst:AddComponent("tbat_data")
            end
        --------------------------------------------------------------
        ----
            inst:AddTag("nosteal")
            inst:AddTag("tbat_pet_eyebone_box")
            inst:AddTag(eyebone_prefab)
            add_container_before_not_ismastersim_return(inst)
            workable_install(inst)
            inst.eyebone_prefab = eyebone_prefab
        --------------------------------------------------------------
            if not TheWorld.ismastersim then
                return
            end
        --------------------------------------------------------------
        --- 交互失败
            inst:AddComponent("tbat_com_action_fail_reason")
            inst.components.tbat_com_action_fail_reason:Add_Reason("give_back_item_fail",TBAT:GetString2(common_prefab,"give_back_item_fail"))
            inst.components.tbat_com_action_fail_reason:Add_Reason("house_full",TBAT:GetString2(common_prefab,"house_full"))
        --------------------------------------------------------------
        --- 摧毁
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst)
        --------------------------------------------------------------
        --- 
            inst:ListenForEvent("onbuilt",on_build_event)
        --------------------------------------------------------------
        ---
            inst:ListenForEvent("pet_spawn",pet_spawn_event)
            inst:WatchWorldState("cycles",pet_spawn_task)
        --------------------------------------------------------------
        ---
            inst:DoTaskInTime(0,init_0)
        --------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 家养、野生、跟随玩家判定
    function TBAT.PET_MODULES:ThisIsWildAnimal(inst)
        if inst.components.follower then
            local leader = inst.components.follower:GetLeader()
            if leader and leader:HasTag("tbat_pet_eyebone") then
                return false
            end
        end
        return true
    end
    function TBAT.PET_MODULES:ThisIsHouseAnimal(inst)
        return not self:ThisIsWildAnimal(inst)
    end
    function TBAT.PET_MODULES:IsFollowingPlayer(inst)
        if inst.GetFollowingPlayer then
            local player = inst:GetFollowingPlayer()
            if player and player:IsValid() then
                return true , player
            end
        end
        if inst.components.follower then
            local leader = inst.components.follower:GetLeader()
            if leader and leader:IsValid() then
                if leader:HasTag("player") then
                    return true,leader
                end
                if leader.components.inventoryitem then
                    local owner = leader.components.inventoryitem:GetGrandOwner()
                    if owner and owner:IsValid() and owner:HasTag("player") then
                        return true,owner
                    end
                end
            end
        end
        return false,nil
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 速度跟随(统一封装个，方便参数统一)
    local follow_dis_max_sq = 20*20
    function TBAT.PET_MODULES:Need2RunClosePlayer(inst)
        local ret = false
        local player = inst.GetFollowingPlayer and inst:GetFollowingPlayer()
        if player and player:IsValid() then
            local dis_sq = inst:GetDistanceSqToInst(player)
            ret = dis_sq > follow_dis_max_sq
        end
        return ret
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
