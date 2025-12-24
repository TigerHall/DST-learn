--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_magic_potion_cabinet"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets = require("prefabs/07_tbat_buildings/04_02_cabinet_skins")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- item test
    local blocking_com = {
        ["health"] = true,
        ["container"] = true,
    }
    local function item_test_succeed_client(item)
        for com_name, v in pairs(item.replica._) do
            if blocking_com[com_name] then
                return false
            end
        end
        for com_name, v in pairs(item.components) do
            if blocking_com[com_name] then
                return false
            end
        end
        return true
    end
    local function item_test_succeed(item)
        if not item_test_succeed_client(item) then
            return false
        end
        if item.sg then
            return false
        end
        if item.brainfn then
            return false
        end
        return true
    end
    local function got_new_item_event(inst,_table)
        local item = _table.item
        local slot = _table.slot
        if item_test_succeed(item) then
        else
            inst.components.container:DropItemBySlot(slot)            
        end
    end
    local function got_new_item_event_install(inst)
        if TheWorld.ismastersim then
            inst:ListenForEvent("itemget",got_new_item_event)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器
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
                    slotbg  = {},
                    animbank = "ui_fish_box_5x4",
                    animbuild = "ui_fish_box_5x4",
                    pos = Vector3(0, 220, 0),
                    side_align_tip = 160,
                },
                type = "chest",
            }
            ------------------------------------------------------------------------------------------
            ---
                local widget_data = params[container_widget_name]
            ------------------------------------------------------------------------------------------
            --- 格子布局
                for y = 2.5, -0.5, -1 do
                    for x = -1, 3 do
                        table.insert(widget_data.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
                    end
                end
            ------------------------------------------------------------------------------------------
            ---- item test
                widget_data.itemtestfn =  function(container_com, item, slot)
                    return item_test_succeed_client(item)
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
                inst:ListenForEvent("onclose",on_close)
                inst:ListenForEvent("onopen",on_open)
                inst.components.container:EnableInfiniteStackSize(true)
            end
        -------------------------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品显示
    local function GetItemImageAtlas(item)
        ---- 暂时没法 给MOD 物品用
        local tar_atlas = nil
        local tar_image = nil

        local imagename = item.nameoverride or item.components.inventoryitem.imagename or item.prefab
        imagename  = string.gsub(imagename,".tex", "") .. ".tex"
        local atlasname = item.components.inventoryitem.atlasname or GetInventoryItemAtlas(imagename)
        if TheSim:AtlasContains(atlasname, imagename) then
            --- 官方物品
            tar_atlas = atlasname
            tar_image = imagename
            -- break
        else
            --- 自定义MOD物品
            atlasname = GetInventoryItemAtlas(imagename)
            atlasname = resolvefilepath_soft(atlasname) --为了兼容mod物品，不然是没有这道工序的
            tar_atlas = atlasname
            tar_image = imagename
            -- break
        end
        if tar_atlas and tar_image and TheSim:AtlasContains(tar_atlas, tar_image) then
            return tar_atlas,tar_image
        end
        return nil,nil
    end
    local function clear_target_layer(inst,layer)
        inst.AnimState:OverrideSymbol(layer,"tbat_building_magic_potion_cabinet","empty")
    end
    local function display_item(inst)
        ------------------------------------------------------------------------------------------------------
        --- 初始化
            inst.item_fx = inst.item_fx or {}
            for k, v in pairs(inst.item_fx) do
                v:Remove()
            end            
            inst.item_fx = {}
        ------------------------------------------------------------------------------------------------------
        --- 皮肤检查
            local current_skin_data = inst.components.tbat_com_skin_data:GetCurrentData()
            local max_slot = 6
            if current_skin_data and current_skin_data.max_slot then
                max_slot = current_skin_data.max_slot
            end
            local icon_offset = Vector3(0,30,0) -- 默认素材的为png中点，需要偏移才不会突兀。
            if current_skin_data and current_skin_data.icon_offset then
                icon_offset = current_skin_data.icon_offset
            end
            local display_item_ground_type = true
            if current_skin_data and current_skin_data.display_item_ground_type == false then
                display_item_ground_type = false
            end
        ------------------------------------------------------------------------------------------------------
        --- 物品显示类型
            if display_item_ground_type then                
                local slot_offset = 2 -- 动画那边需要做偏移才能成功定位 layer 图层 。从3开始。
                for i = 1, max_slot, 1 do
                    local item = inst.components.container:GetItemInSlot(i)
                    if item then
                        local item_fx = TBAT.FNS:BlankStateClone(item,{"INLIMBO","NOCLICK","NOBLOCK","FX","fx"})
                        item_fx.entity:SetParent(inst.entity)
                        item_fx.entity:AddFollower()
                        item_fx.Follower:FollowSymbol(inst.GUID, "slot"..(i+slot_offset),icon_offset.x,icon_offset.y,icon_offset.z,true)
                        table.insert(inst.item_fx,item_fx)
                    end
                end
            end
        ------------------------------------------------------------------------------------------------------
        --- 图标显示类型. 物品图标在动画里需要被定义为 256X256
            if not display_item_ground_type then
                local slot_offset = 2 -- 动画那边需要做偏移才能成功定位 layer 图层 。从3开始。
                for i = 1, max_slot, 1 do
                    local tar_layer = "slot"..(i+slot_offset)
                    local item = inst.components.container:GetItemInSlot(i)
                    if item then
                        local tar_atlas,tar_image = GetItemImageAtlas(item)
                        -- print(i,tar_atlas,tar_image,tar_layer)
                        if tar_atlas and tar_image then
                            inst.AnimState:OverrideSymbol(tar_layer,tar_atlas,tar_image)
                        else
                            -- inst.AnimState:ClearOverrideSymbol(tar_layer)
                            clear_target_layer(inst,tar_layer)
                        end
                    else
                        -- inst.AnimState:ClearOverrideSymbol(tar_layer)
                        clear_target_layer(inst,tar_layer)
                    end 
                end
            end
        ------------------------------------------------------------------------------------------------------
    end
    local function on_close_event(inst)
        display_item(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- destroy com
--- 参数
    local MAX_HIT_NUM = 9
    local function onhammered(inst, worker)
        inst.components.lootdropper:DropLoot()
        if inst.components.container then
            inst.components.container:DropEverything()
        end
        local fx = SpawnPrefab("collapse_big")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
        inst:Remove()
    end
    local function onhit(inst, worker)
        inst.components.container:Close()
    end
    local old_WorkedByFn = nil
    local new_workedbyfn = function(self,worker, numworks,...)
        if worker and worker:HasTag("player") then
            old_WorkedByFn(self,worker, numworks,...)
        end
    end
    local function destory_com_install(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(MAX_HIT_NUM)
        inst.components.workable:SetOnFinishCallback(onhammered)
        inst.components.workable:SetOnWorkCallback(onhit)
        old_WorkedByFn = old_WorkedByFn or inst.components.workable.WorkedBy
        inst.components.workable.WorkedBy = new_workedbyfn
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function empty_slot_layers(inst)
        for i = 3, 23, 1 do
            inst.AnimState:OverrideSymbol("slot"..i,"tbat_building_magic_potion_cabinet","empty")
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
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(this_prefab..".tex")
        TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_magic_potion_cabinet","tbat_building_magic_potion_cabinet")
        inst.AnimState:SetBank("tbat_building_magic_potion_cabinet")
        inst.AnimState:SetBuild("tbat_building_magic_potion_cabinet")
        inst.AnimState:PlayAnimation("idle",true)
        empty_slot_layers(inst)
        inst.AnimState:SetTime(4*math.random())
        inst:AddTag("structure")
        inst.entity:SetPristine()
        ---------------------------------------------------
        --- 容器
            add_container_before_not_ismastersim_return(inst)
        ---------------------------------------------------
        --- 摧毁
            destory_com_install(inst)
        ---------------------------------------------------
        --- 物品获取
            got_new_item_event_install(inst)
        ---------------------------------------------------
        --- 常规
            if not TheWorld.ismastersim then
                return inst
            end
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ---------------------------------------------------
        --- 
            inst:ListenForEvent("empty_slot_layers",empty_slot_layers)
            inst:ListenForEvent("tbat_com_skin_data.skin_change",empty_slot_layers)
        ---------------------------------------------------
        --- 显示
            inst:ListenForEvent("onclose",on_close_event)
            inst:DoTaskInTime(0,display_item)
        ---------------------------------------------------
        --- 
            inst:AddComponent("tbat_com_skin_data")
            inst:ListenForEvent("tbat_com_skin_data.skin_change",display_item)
            inst:AddComponent("named")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
        ---------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            -- inst.components.preserver:SetPerishRateMultiplier(-0.1)
            inst.components.preserver:SetPerishRateMultiplier(0)
        ---------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "test", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

