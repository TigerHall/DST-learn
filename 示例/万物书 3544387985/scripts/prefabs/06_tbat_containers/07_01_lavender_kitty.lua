--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    薰衣草小猫

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_lavender_kitty"
    local area_data = {
        --- 注意：以这个半径扫描，会漏掉四周个角落格子。必须 乘以 根号2
        ["3x3"] = {radius = 6},
        ["5x5"] = {radius = 10},
        ["7x7"] = {radius = 14},
        ["9x9"] = {radius = 18},
    }
    local area_radius_form_config = TBAT.CONFIG.LAVENDER_KITTY_WORKING_AREA or "5x5"
    local function GeRadius()
        return area_data[area_radius_form_config].radius
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_lavender_kitty.zip"),
        Asset("ANIM", "anim/tbat_chat_icon_lavender_kitty.zip"),
        Asset("IMAGE", "images/widgets/tbat_container_lavender_kitty_slot.tex"),
        Asset("ATLAS", "images/widgets/tbat_container_lavender_kitty_slot.xml"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语图标
    TBAT.FNS:AddChatIconData(this_prefab,{
        atlas = "images/chat_icon/empty.xml",
        image = "empty.tex",                     --- 128x128 pix
        scale = nil,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
        fx = {
            bank = "tbat_chat_icon_lavender_kitty",
            build = "tbat_chat_icon_lavender_kitty",
            anim = "idle",
            time = 1,
        },  
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器
    local container_install_fn = require("prefabs/06_tbat_containers/07_02_lavender_container_install")
    local container_hud_hook_fn = require("prefabs/06_tbat_containers/07_03_01_lavender_container_hud_hooker")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 功能函数
    local lavender_main_logic_fn = require("prefabs/06_tbat_containers/07_04_lavender_main_logic")
    local lavender_fertilization_logic_fn = require("prefabs/06_tbat_containers/07_07_lavender_fertilization_logic")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 区域指示器
    local function create_area_indecator(inst)
        local tile_offset = GeRadius() - 2
        local start_x,start_z = -tile_offset,tile_offset
        local end_x,end_z = tile_offset,-tile_offset
        local delta = 4
        local offset_points = {}
        for x = start_x,end_x,delta do
            for z = end_z,start_z,delta do
                table.insert(offset_points,Vector3(x,0,z))
            end
        end
        local mark = SpawnPrefab("tbat_sfx_tile_outline")        
        mark:PushEvent("Set",{})
        mark:AddTag("NOBLOCK")
        mark.entity:AddTransform()
        inst:ListenForEvent("onremove",function()
            mark:Remove()
        end)
        for index, pt in pairs(offset_points) do
            local fx = mark:SpawnChild("tbat_sfx_tile_outline")
            fx:PushEvent("Set",{})
            fx.Transform:SetPosition(pt.x,0,pt.z)
        end
        return mark
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建提示器
    local function create_indicator_for_player_client(inst,data)
        if inst.__temp_indicator then
            inst.__temp_indicator:Remove()
        end
        inst.__temp_indicator = create_area_indecator(inst)
        inst.__temp_indicator:DoTaskInTime(5,function()
            inst.__temp_indicator:Remove()
            inst.__temp_indicator = nil
        end)
        local x,y,z = TBAT.MAP:GetTileCenterPoint(inst.Transform:GetWorldPosition())
        inst.__temp_indicator.Transform:SetPosition(x,y,z)
    end
    local function create_indicator_for_player_server(inst,data)
        local doer = data.doer
        local userid = doer and doer.userid or nil
        if userid then
            TBAT.FNS:RPC_PushEvent(doer,"show_indicator_for_working",{userid = userid},inst)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onbuild、deploy 放置位置检测吸附。
    local function IsNearFarmSolid(inst)
        local radius = GeRadius() + 3
        local delta = 3
        while radius > 0 do
            local points = TBAT.FNS:GetSurroundPoints({
                target = inst,
                range = radius,
                num = 6*radius
            })
            for index, pt in pairs(points) do 
                if TheWorld.Map:IsFarmableSoilAtPoint(pt.x,0,pt.z) then
                    return true
                end
            end
            radius = radius - delta
        end
        return false
    end
    local function AutoMove2TileCenter(inst)
        if IsNearFarmSolid(inst) then
            local x,y,z = TBAT.MAP:GetTileCenterPoint(inst.Transform:GetWorldPosition())
            inst.Transform:SetPosition(x,y,z)
        end
    end
    local function OnBuilt(inst,builder)
        AutoMove2TileCenter(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 获取工作范围内地皮的中心坐标点
    local function GetAllTileCenters(inst)
        if not inst:IsNearFarmSolid() then
            return false,nil
        end
        inst:PushEvent("AutoMove2TileCenter")
        local building_x , _ , building_z = inst.Transform:GetWorldPosition()
        local tile_offset = inst:GeRadius() - 2
        local start_x,start_z = -tile_offset,tile_offset
        local end_x,end_z = tile_offset,-tile_offset
        local delta = 4
        local ret_points = {}
        for x = start_x,end_x,delta do
            for z = end_z,start_z,delta do
                table.insert(ret_points,Vector3( building_x + x , 0 , building_z + z ))
            end
        end
        return true,ret_points
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 虚拟人偶安装，包括事件注册
    local function visual_doer_installer(inst)
        local doer = SpawnPrefab(this_prefab.."_visual_doer")
        inst.visual_doer = doer
        inst:ListenForEvent("onremove",function()
            doer:Remove()
        end)
    end
    local function GetVisualDoer(inst)
        if inst.visual_doer and inst.visual_doer:IsValid() then
            return inst.visual_doer
        end
        visual_doer_installer(inst)
        return inst.visual_doer
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
        inst.MiniMapEntity:SetIcon("tbat_container_lavender_kitty.tex")
        inst.AnimState:SetBank("tbat_container_lavender_kitty")
        inst.AnimState:SetBuild("tbat_container_lavender_kitty")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:SetTime(10*math.random())
        inst:AddTag("structure")
        inst:AddTag("NOBLOCK")
        inst:AddTag(this_prefab)
        inst.entity:SetPristine()
        ------------------------------------------------------------
        --- 模块安装
            container_install_fn(inst)
            container_hud_hook_fn(inst)
            lavender_fertilization_logic_fn(inst)
            inst.IsNearFarmSolid = IsNearFarmSolid
            inst.GeRadius = GeRadius
            if TheWorld.ismastersim then
                inst.GetAllTileCenters = GetAllTileCenters
                inst.GetVisualDoer = GetVisualDoer
            end
        ------------------------------------------------------------
        --- 提示器
            if not TheNet:IsDedicated() then
                inst:ListenForEvent("show_indicator_for_working",create_indicator_for_player_client)
            end
        ------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------------------
        --- 数据
            inst:AddComponent("tbat_data")
        ------------------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(0)
        ------------------------------------------------------------
        --- 常用组件
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------
        --- 摧毁
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,9)
        ------------------------------------------------------------
        --- 核心机制
            lavender_main_logic_fn(inst)
        ------------------------------------------------------------
        --- 野草屏蔽器
            inst:AddComponent("tbat_com_weed_plants_blocker")
            inst.components.tbat_com_weed_plants_blocker:SetRadius(GeRadius()*1.5)  --- 根号2 = 1.414  。取1.5 保护包括角落四个格子。
        ------------------------------------------------------------
        --- 创建的时候、其他时候，刷新位置，吸附中心点。
            inst:ListenForEvent("onclose",create_indicator_for_player_server)
            inst:ListenForEvent("onopen",create_indicator_for_player_server)
            inst:ListenForEvent("AutoMove2TileCenter",AutoMove2TileCenter)
            inst:ListenForEvent("onclose",AutoMove2TileCenter)
            inst:ListenForEvent("onopen",AutoMove2TileCenter)
            inst.OnBuilt = OnBuilt
        ------------------------------------------------------------
        --- 虚拟采集者安装。尽早。
            TheWorld.components.tbat_com_special_timer_for_theworld:AddOneTimeTimer(visual_doer_installer,inst)
        ------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:Pause()
        local mark = create_area_indecator(inst)
        inst:DoPeriodicTask(FRAMES,function()
            local x,y,z = inst.Transform:GetWorldPosition()
            x,y,z = TBAT.MAP:GetTileCenterPoint(x,y,z)
            mark.Transform:SetPosition(x,y,z)
            if IsNearFarmSolid(inst) then -- 靠近农田则开始自动吸附
                inst.components.placer.snap_to_tile = true
            else
                inst.components.placer.snap_to_tile = false
            end
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 虚拟人偶。用来执行采集、种地等待。
    local function damage_blocker_for_visual_doer(player,damage, attacker, weapon, spdamage)
        return 0,{}
    end
    local function visual_doer()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst:AddTag("NOBLOCK")
        inst:AddTag("NOCLICK")
        inst:AddTag("companion")
        inst:AddTag("debugnoattack")
        inst.entity:SetPristine()
        ------------------------------------------------------------
        --- 
        ------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------------------
        --- 
            inst.persists = false   --- 是否留存到下次存档加载。
        ------------------------------------------------------------
        --- 血量
            inst:AddComponent("health")
            inst.components.health:SetMinHealth(1)
            inst.components.health:SetMaxHealth(1000000)
        ------------------------------------------------------------
        --- 战斗
            inst:AddComponent("combat")            
        ------------------------------------------------------------
        --- 
            local inventory = inst:AddComponent("inventory")
            inventory:DisableDropOnDeath()
            inventory.maxslots = 10
        ------------------------------------------------------------
        --- tbat_com_inventory_custom_apply_damage
            if inst.components.tbat_com_inventory_custom_apply_damage == nil then
                inst:AddComponent("tbat_com_inventory_custom_apply_damage")
            end
            inst.components.tbat_com_inventory_custom_apply_damage:AddBeforeApplyDamageFn(inst,damage_blocker_for_visual_doer)
        ------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
    Prefab(this_prefab.."_visual_doer", visual_doer),
    MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)

