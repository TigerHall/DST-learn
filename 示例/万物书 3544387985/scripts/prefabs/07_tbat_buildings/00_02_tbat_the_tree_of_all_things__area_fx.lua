--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_ui_sky_clouds.zip"),
    }
    local Widget = require "widgets/widget"
    local Image = require "widgets/image"
    local UIAnim = require "widgets/uianim"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- PRAM
    local RADIUS = TBAT.PARAM.THE_TREE_OF_ALL_THINGS_RADIUS
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 
    local function __tbat_ui_sky_clouds_create(inst)
        ---------------------------------------------------------------------------------------
        --- 参数
            local search_radius = inst.RADIUS+1       
        ---------------------------------------------------------------------------------------
        ---- 
        ---------------------------------------------------------------------------------------
        ----
            if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.___tbat_main_tree_clouds and ThePlayer.HUD.___tbat_main_tree_clouds.inst:IsValid() then
                return
            end
        ---------------------------------------------------------------------------------------
        ---
            -- local front_root = ThePlayer.HUD.controls:AddChild(Widget())
            local front_root = ThePlayer.HUD:AddChild(Widget())
            ThePlayer.HUD.___tbat_main_tree_clouds = front_root
            front_root:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
            front_root:SetVAnchor(1) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
            front_root:SetPosition(0,0)
            front_root:MoveToBack()
            front_root:SetScaleMode(SCALEMODE_FIXEDSCREEN_NONDYNAMIC)   --- 缩放模式
            front_root:SetClickable(false)
        ---------------------------------------------------------------------------------------
        ---
            front_root.inst:DoPeriodicTask(3,function()
                if front_root.fade_in then
                    return
                end
                local x,y,z = ThePlayer.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, 0, z,search_radius*2,{"tbat_the_tree_of_all_things__area_fx"})
                if #ents == 0 and front_root and front_root.inst:IsValid() then
                    front_root:Kill()
                    -- print("加载范围外，移除顶部特效。")
                end
            end)
        ---------------------------------------------------------------------------------------
        --- 创建根节点
            local root = front_root:AddChild(Widget())
            local scale = 0.7
            root:SetScale(scale,scale)
        ---------------------------------------------------------------------------------------
        --- 创建box
            local box = root:AddChild(UIAnim())
            box:GetAnimState():SetBank("tbat_ui_sky_clouds")
            box:GetAnimState():SetBuild("tbat_ui_sky_clouds")
            box:GetAnimState():PlayAnimation("idle",true)
        ---------------------------------------------------------------------------------------
        --- 偏移参数
            local offset_y_origin = 300                
            local offset_y = offset_y_origin
            local delta_y = 10
            box:SetPosition(0,offset_y,0)
        ---------------------------------------------------------------------------------------
        --- 渐入渐出
            local function fade_in()
                if offset_y <= 0 then
                    return
                end
                offset_y = offset_y - delta_y
                offset_y = math.max(offset_y,0)
                box:SetPosition(0,offset_y,0)
                front_root:Show()
                front_root.fade_in = true
            end
            local function fade_out()
                front_root.fade_in = false
                if offset_y > offset_y_origin then
                    -- front_root:Kill() -- 不再删除，避免出现偶发的 无法继续显示。
                    front_root:Hide()
                    return
                end
                offset_y = offset_y + delta_y
                offset_y = math.min(offset_y,offset_y_origin)
                box:SetPosition(0,offset_y,0)
            end
        ---------------------------------------------------------------------------------------
        --- 渐入渐出update
            local function update_fn()
                local x,y,z = ThePlayer.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, 0, z,search_radius,{"tbat_the_tree_of_all_things__area_fx"})
                if #ents > 0 then
                    fade_in()
                else
                    fade_out()
                end
            end
            TBAT:AddInputUpdateFn(front_root.inst,update_fn)
        ---------------------------------------------------------------------------------------

        ---------------------------------------------------------------------------------------
    end
    local function player_near_client(inst)
        if TBAT.DEBUGGING and TBAT.__tbat_ui_sky_clouds_create then
            TBAT.__tbat_ui_sky_clouds_create(inst)
        end
        __tbat_ui_sky_clouds_create(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 调试用的范围指示器
    local function create_debug_cycle(parent)
        local inst = parent:SpawnChild("tbat_sfx_dotted_circle_client")
        inst:PushEvent("Set",{
            radius = RADIUS,
        })
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- near far 
    local function OnPlayerNear(inst, player)
        -- print("+++ OnPlayerNear",player)
        TBAT.FNS:RPC_PushEvent(player,"player_near",{},inst)
    end
    local function OnPlayerFar(inst, player)
        -- print("--- OnPlayerFar",player)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ground stars
    local function ground_fx(inst)
        -----------------------------------------------------------------
        ---
            local delta_radius = 10
            local radius = (inst.RADIUS or 40) - 5
            local min_radius = 6
        -----------------------------------------------------------------
        ---
            local temp_points_2 = {}            
            while radius > min_radius do
                radius = radius - delta_radius
                local points_num = math.floor(2*3*radius * 0.7)
                points_num = math.max(points_num, 3)
                local points = TBAT.FNS:GetSurroundPoints({
                    target = inst,
                    range = radius,
                    num = points_num
                })
                for k, pt in pairs(points) do
                    pt.x = pt.x + math.random()*delta_radius*(math.random()>0.5 and 1 or -1)
                    pt.z = pt.z + math.random()*delta_radius*(math.random()>0.5 and 1 or -1)
                    table.insert(temp_points_2,pt)
                end                    
            end

            local ret_num = math.min(#temp_points_2,50)
            local ret_points = TBAT.FNS:GetRandomDiffrenceValuesFromTable(temp_points_2, ret_num)
            for k, pt in pairs(ret_points) do
                local fx = SpawnPrefab("tbat_sfx_ground_fireflies")
                fx.Transform:SetPosition(pt.x,0,pt.z)
            end
            -- print("ret_num:",ret_num)
            -- print("fx:",#inst.ground_fx)
        -----------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        if TBAT.DEBUGGING then
            -- inst.AnimState:SetBank("cane")
            -- inst.AnimState:SetBuild("swap_cane")
            -- inst.AnimState:PlayAnimation("idle")
            if not TheNet:IsDedicated() then
                inst:DoTaskInTime(0,create_debug_cycle)
            end
        end
        inst:AddTag("tbat_the_tree_of_all_things__area_fx")
        -- inst:AddTag("lightningblocker")
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("player_near",player_near_client)
        end
        inst.RADIUS = RADIUS
        if not TheWorld.ismastersim then
            return inst
        end

        local playerprox = inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(RADIUS, RADIUS+2)
        inst.components.playerprox:SetOnPlayerNear(OnPlayerNear)
        inst.components.playerprox:SetOnPlayerFar(OnPlayerFar)
        inst.components.playerprox:SetTargetMode(playerprox.TargetModes.AllPlayers)
        inst.components.playerprox:SetPlayerAliveMode(playerprox.AliveModes.DeadOrAlive)

        inst:ListenForEvent("spawn_ground_fx",ground_fx)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_the_tree_of_all_things__area_fx", fn, assets)