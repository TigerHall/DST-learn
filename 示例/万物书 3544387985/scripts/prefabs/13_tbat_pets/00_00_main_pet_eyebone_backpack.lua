--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_pet_eyebone_backpack"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/cane.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onequip/onunequip
    local function onequip(inst, owner)
    end

    local function onunequip(inst, owner)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- backpack item test fn
    local function backpack_item_test_fn(item)
        if item:HasTag("tbat_pet_eyebone") then
            return true
        end
        if TBAT.DEBUGGING and item:HasTag("hutch_fishbowl") then
            return true
        end
        return false
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 安装容器界面
    local function container_Widget_change(theContainer)
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
                    animbank = "ui_fish_box_5x4",
                    animbuild = "ui_fish_box_5x4",
                    pos = Vector3(0, 220, 0),
                    side_align_tip = 160,
                },
                type = "tbat_pet_eyebone_backpack",
                acceptsstacks = false,
            }

            for y = 2.5, -0.5, -1 do
                for x = -1, 3 do
                    table.insert(params[container_widget_name].widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
                end
            end
            ------------------------------------------------------------------------------------------
            ---- item test
                params[container_widget_name].itemtestfn =  function(container_com, item, slot)
                    return item and backpack_item_test_fn(item)
                end
            ------------------------------------------------------------------------------------------

            ------------------------------------------------------------------------------------------
        end
        
        theContainer:WidgetSetup(container_widget_name)
    end
    local function add_container_before_not_ismastersim_return(inst)
        -------------------------------------------------------------------------------------------------
        ------ 添加背包container组件    --- 必须在 SetPristine 之后，
            if TheWorld.ismastersim then
                inst:AddComponent("container")
                inst.components.container.openlimit = 10  ---- 限制10个人打开
                inst.components.container.canbeopened = false
                container_Widget_change(inst.components.container)
            else
                inst.OnEntityReplicated = function(inst)
                    container_Widget_change(inst.replica.container)
                end
            end
        -------------------------------------------------------------------------------------------------
    end
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
        local API_NAMES = {"DropItemBySlot","DropEverythingWithTag","DropEverything","DropItem","DropOverstackedExcess","DropItemAt","CanTakeItemInSlot"}
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
--- API - Event
    local function Link(inst,player)
        if inst.player then
            return
        end
        inst.player = player
        ------------------------------------------------------------------------------------
        --- 通知骨眼初始化
            inst.components.container:ForEachItem(function(item)
                if item then
                    item:PushEvent("bacpack_inited") --- 用来释放储存的宠物
                end
            end)
        ------------------------------------------------------------------------------------
        --- 通知骨眼 玩家离开
            inst:ListenForEvent("ms_playerleft",function(_,temp_player)
                if temp_player == inst.player then
                    inst.components.container:ForEachItem(function(item)
                        if item then
                            item:PushEvent("player_left")  --- 用来储存宠物数据到骨眼
                        end
                    end)
                end
            end,TheWorld)
        ------------------------------------------------------------------------------------
        --- 战斗
            inst:ListenForEvent("attacked",function(_,_table)
                local attacker = _table and _table.attacker
                if attacker then
                    inst.components.container:ForEachItem(function(item)
                        if item then
                            item:PushEvent("player_attacked_by",attacker)
                            item:PushEvent("player_battle_with",attacker)
                        end
                    end)
                end
            end,player)
            inst:ListenForEvent("onhitother",function(_,_table)
                local target = _table and _table.target
                if target then
                    inst.components.container:ForEachItem(function(item)
                        if item then
                            item:PushEvent("player_onhitother",target)
                            item:PushEvent("player_battle_with",target)
                        end
                    end)
                end
            end,player)
        ------------------------------------------------------------------------------------
        --- 蜗牛炼丹炉 Event 传递
            inst:ListenForEvent("tbat_com_mushroom_snail_cauldron.Started",function(_,_table)
                inst.components.container:ForEachItem(function(item)
                    if item then
                        item:PushEvent("tbat_com_mushroom_snail_cauldron.Started",_table)
                    end
                end)
            end,player)
            inst:ListenForEvent("tbat_container_mushroom_snail_cauldron.open",function(_,_table)
                inst.components.container:ForEachItem(function(item)
                    if item then
                        item:PushEvent("tbat_container_mushroom_snail_cauldron.open",_table)
                    end
                end)
            end,player)
            inst:ListenForEvent("tbat_container_mushroom_snail_cauldron.close",function(_,_table)
                inst.components.container:ForEachItem(function(item)
                    if item then
                        item:PushEvent("tbat_container_mushroom_snail_cauldron.close",_table)
                    end
                end)
            end,player)
        ------------------------------------------------------------------------------------
        ---
            
        ------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- init
    local function init(inst)
        local owner = inst.components.inventoryitem.owner
        if owner and owner:HasTag("player") then
            Link(inst,owner)
        else
            inst:Remove()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("cane")
        inst.AnimState:SetBuild("swap_cane")
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("nosteal")

        inst.entity:SetPristine()
        -------------------------------------------------
        ---
            add_container_before_not_ismastersim_return(inst)
        -------------------------------------------------
        ---
            if not TheWorld.ismastersim then
                return inst
            end
        -------------------------------------------------
        ---- 
            inst.Link = Link
        -------------------------------------------------
        ---- 
            inst:AddComponent("inspectable")
            inst:AddComponent("tbat_data")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.cangoincontainer = false
            inst.components.inventoryitem:ChangeImageName("cane")
            inst.components.inventoryitem.keepondeath = true
        -------------------------------------------------
        ----
            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.TBAT_PET_EYEBONE_BACKPACK
            inst.components.equippable:SetOnEquip(onequip)
            inst.components.equippable:SetOnUnequip(onunequip)
            inst.components.equippable.restrictedtag = "player"
            inst:DoTaskInTime(0,container_com_hook)
        -------------------------------------------------
        ---
            inst:DoTaskInTime(0,init)
        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
