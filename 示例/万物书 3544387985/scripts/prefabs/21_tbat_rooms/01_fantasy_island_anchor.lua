--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    幻想岛屿锚点

    A | B
    --M--
    C | D      
    
    A : 红色
    B : 绿色
    C : 蓝色
    D : 黄色

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local types = {
        "main","a","b","c","d","e","f","g"
    }
    local base_prefab = "tbat_room_anchor_fantasy_island_"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_eq_world_skipper.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 相互守望存在模块
    --[[
    
        扫描方法 ： 

        local ents = TheSim:FindEntities(x, 0, z, 500, {"tbat_room_anchor_fantasy_island"})
        local protector_data = {}
        for k, current in pairs(ents) do
            for _, target in pairs(ents) do
                if current ~= target then
                    protector_data[current.flag] = protector_data[current.flag] or {}
                    protector_data[current.flag][target.flag] = Vector3(target.Transform:GetWorldPosition()) - Vector3(current.Transform:GetWorldPosition())
                end
            end
        end
        -- local str = json.encode(protector_data)
        -- print(str)

        --- vect = target - currnt
        --- target = current + vect

    ]]--
    local data_str = '{"a":{"c":{"y":0,"x":-44,"z":60},"main":{"y":0,"x":-52,"z":4},"b":{"y":0,"x":0,"z":40},"e":{"y":0,"x":-108,"z":4},"d":{"y":0,"x":-100,"z":60},"g":{"y":0,"x":-12,"z":-28},"f":{"y":0,"x":-92,"z":-28}},"c":{"a":{"y":0,"x":44,"z":-60},"main":{"y":0,"x":-8,"z":-56},"b":{"y":0,"x":44,"z":-20},"e":{"y":0,"x":-64,"z":-56},"d":{"y":0,"x":-56,"z":0},"g":{"y":0,"x":32,"z":-88},"f":{"y":0,"x":-48,"z":-88}},"main":{"a":{"y":0,"x":52,"z":-4},"c":{"y":0,"x":8,"z":56},"b":{"y":0,"x":52,"z":36},"e":{"y":0,"x":-56,"z":0},"d":{"y":0,"x":-48,"z":56},"g":{"y":0,"x":40,"z":-32},"f":{"y":0,"x":-40,"z":-32}},"b":{"a":{"y":0,"x":0,"z":-40},"main":{"y":0,"x":-52,"z":-36},"c":{"y":0,"x":-44,"z":20},"e":{"y":0,"x":-108,"z":-36},"d":{"y":0,"x":-100,"z":20},"g":{"y":0,"x":-12,"z":-68},"f":{"y":0,"x":-92,"z":-68}},"e":{"a":{"y":0,"x":108,"z":-4},"main":{"y":0,"x":56,"z":0},"b":{"y":0,"x":108,"z":36},"c":{"y":0,"x":64,"z":56},"d":{"y":0,"x":8,"z":56},"g":{"y":0,"x":96,"z":-32},"f":{"y":0,"x":16,"z":-32}},"d":{"a":{"y":0,"x":100,"z":-60},"main":{"y":0,"x":48,"z":-56},"b":{"y":0,"x":100,"z":-20},"e":{"y":0,"x":-8,"z":-56},"c":{"y":0,"x":56,"z":0},"g":{"y":0,"x":88,"z":-88},"f":{"y":0,"x":8,"z":-88}},"g":{"a":{"y":0,"x":12,"z":28},"main":{"y":0,"x":-40,"z":32},"b":{"y":0,"x":12,"z":68},"e":{"y":0,"x":-96,"z":32},"d":{"y":0,"x":-88,"z":88},"c":{"y":0,"x":-32,"z":88},"f":{"y":0,"x":-80,"z":0}},"f":{"a":{"y":0,"x":92,"z":28},"main":{"y":0,"x":40,"z":32},"b":{"y":0,"x":92,"z":68},"e":{"y":0,"x":-16,"z":32},"d":{"y":0,"x":-8,"z":88},"g":{"y":0,"x":80,"z":0},"c":{"y":0,"x":48,"z":88}}}'
    local protector_data = json.decode(data_str)
    local function watch_dog_protector_task(inst)
        if not inst:IsValid() or TheWorld:HasTag("cave") then
            return
        end
        local data = protector_data[inst.flag] or {}
        local x,y,z = inst.Transform:GetWorldPosition()
        local all_anchors = TheSim:FindEntities(x, 0, z, 500, {"tbat_room_anchor_fantasy_island"})
        if #all_anchors == #types then
            return
        end
        local no_exsist_anchor_index = {}
        for k, index in pairs(types) do
            no_exsist_anchor_index[index] = true
        end
        for k, anchor in pairs(all_anchors) do
            no_exsist_anchor_index[anchor.flag] = false
        end
        for index, flag in pairs(no_exsist_anchor_index) do
            if flag then
                print("TBAT error : 检测到锚点缺失 :" ,index)
                local pt = data[index] or {}
                if pt.x and pt.y and pt.z then
                    local tar_pt_x  = x + pt.x
                    local tar_pt_y  = 0
                    local tar_pt_z  = z + pt.z
                    -- SpawnPrefab(base_prefab..index).Transform:SetPosition(tar_pt_x,tar_pt_y,tar_pt_z)
                    TBAT.MAP:CreateUniqueAnchor(base_prefab..index,tar_pt_x,tar_pt_y,tar_pt_z)
                    print("TBAT info 已重新生成锚点 :" ,index)
                end
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 装修指示器
    local function create_tile_indicator(inst)
        ----------------------------------------------------------------
        ---- 鼠标提示            
            if inst.__indicator_task == nil then
                inst.__indicator_task = inst:DoPeriodicTask(0.5, function()
                    local mouse_inst = TheInput and TheInput:GetWorldEntityUnderMouse()
                    if mouse_inst ~= inst then
                        for k, v in pairs(inst.tile_fx or {}) do
                            v:Hide()
                        end
                        -- inst.tile_fx = nil
                        inst.__indicator_task:Cancel()
                        inst.__indicator_task = nil
                        return
                    end
                
                end)
            end
        ----------------------------------------------------------------
        ---
            if inst.tile_fx then
                for k, v in pairs(inst.tile_fx) do
                    v:Show()
                end
                return
            end
            inst.tile_fx = {}
        ----------------------------------------------------------------
        --- 区域、参数
            --[[
            
                A | B
                --M--
                C | D      
                
                A : 红色
                B : 绿色
                C : 蓝色
                D : 黄色
            
            ]]--
            local mid_x,mid_y,mid_z = inst.Transform:GetWorldPosition()
            local scale = 0.95
            local tile_offset = 4
            local side_num = 20
        ----------------------------------------------------------------
        --- 区域A
            local r,g,b = 255/255,0/255,0/255
            local Temp_COLOR_1 = {r,g,b,0}
            local Temp_COLOR_2 = {r,g,b,1}
            for y = 1, side_num, 1 do
                for x = 1, side_num, 1 do
                    local fx = SpawnPrefab("tbat_sfx_tile_outline")
                    fx:PushEvent("Set",{
                        pt = Vector3(mid_x - x*tile_offset ,0,mid_z + y*tile_offset ),
                        scale = scale
                    })
                    fx.AnimState:SetAddColour(unpack(Temp_COLOR_1))
                    fx.AnimState:SetMultColour(unpack(Temp_COLOR_2))
                    fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                    table.insert(inst.tile_fx,fx)
                end
            end
        ----------------------------------------------------------------
        --- 区域B
            local r,g,b = 0/255,255/255,0/255
            local Temp_COLOR_1 = {r,g,b,0}
            local Temp_COLOR_2 = {r,g,b,1}
            for y = 1, side_num, 1 do
                for x = 1, side_num, 1 do
                    local fx = SpawnPrefab("tbat_sfx_tile_outline")
                    fx:PushEvent("Set",{
                        pt = Vector3(mid_x + x*tile_offset ,0,mid_z + y*tile_offset ),
                        scale = scale
                    })
                    fx.AnimState:SetAddColour(unpack(Temp_COLOR_1))
                    fx.AnimState:SetMultColour(unpack(Temp_COLOR_2))
                    fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                    table.insert(inst.tile_fx,fx)
                end
            end
        ----------------------------------------------------------------
        --- 区域C
            local r,g,b = 0/255,0/255,255/255
            local Temp_COLOR_1 = {r,g,b,0}
            local Temp_COLOR_2 = {r,g,b,1}
            for y = 1, side_num, 1 do
                for x = 1, side_num, 1 do
                    local fx = SpawnPrefab("tbat_sfx_tile_outline")
                    fx:PushEvent("Set",{
                        pt = Vector3(mid_x - x*tile_offset ,0,mid_z - y*tile_offset ),
                        scale = scale
                    })
                    fx.AnimState:SetAddColour(unpack(Temp_COLOR_1))
                    fx.AnimState:SetMultColour(unpack(Temp_COLOR_2))
                    fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                    table.insert(inst.tile_fx,fx)
                end
            end
        ----------------------------------------------------------------
        --- 区域D
            local r,g,b = 255/255,255/255,0/255
            local Temp_COLOR_1 = {r,g,b,0}
            local Temp_COLOR_2 = {r,g,b,1}
            for y = 1, side_num, 1 do
                for x = 1, side_num, 1 do
                    local fx = SpawnPrefab("tbat_sfx_tile_outline")
                    fx:PushEvent("Set",{
                        pt = Vector3(mid_x + x*tile_offset ,0,mid_z - y*tile_offset ),
                        scale = scale
                    })
                    fx.AnimState:SetAddColour(unpack(Temp_COLOR_1))
                    fx.AnimState:SetMultColour(unpack(Temp_COLOR_2))
                    fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
                    table.insert(inst.tile_fx,fx)
                end
            end
        ----------------------------------------------------------------        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 点击告示
    local function workable_test_fn(inst,doer,right_click)
        if not TheNet:IsDedicated() then
            create_tile_indicator(inst)
        end
        return true
    end
    local function workable_on_work_fn(inst,doer)
        local x,y,z = inst.Transform:GetWorldPosition()
        local player_x, player_y , player_z = doer.Transform:GetWorldPosition()
        local deleta_x = math.floor((player_x - x)*10)/10
        local deleta_z = math.floor((player_z - z)*10)/10
        local str = "玩家和【 "..inst:GetDisplayName() .." 】的偏差 :\n  X : "..(deleta_x).."  , Z : "..(deleta_z) .. "\n"
        str = str .. "距离 SQ:" .. tostring(inst:GetDistanceSqToInst(doer))
        TheNet:Announce(str)
        doer.components.talker:Say(str)
        return true
    end

    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText("tbat_room_anchor_fantasy_island","获取坐标")
        replica_com:SetSGAction("tbat_sg_empty_active")
        replica_com:SetDistance(100)
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
--- 创建物品    
    local function common_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        -- if TBAT.DEBUGGING then
        --     inst.AnimState:SetBank("tbat_eq_world_skipper")
        --     inst.AnimState:SetBuild("tbat_eq_world_skipper")
        --     inst.AnimState:PlayAnimation("idle",true)
        --     inst.AnimState:SetScale(2,2,2)

        --     inst.entity:AddDynamicShadow()
        --     inst.DynamicShadow:SetSize(1.5, 1.5)

        --     inst.AnimState:SetFinalOffset(3)
        --     inst.AnimState:SetSortOrder(3)
        -- end

        inst:AddTag("NOBLOCK")
        inst:AddTag("tbat_room_anchor_fantasy_island")
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")

        inst.entity:SetPristine()
        workable_install(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst:AddComponent("tbat_com_fantasy_island_anchor_decorator")

        -- inst:DoTaskInTime(0,watch_dog_protector_task)
        TheWorld:DoTaskInTime(0,function()
            watch_dog_protector_task(inst)
        end)
        inst:ListenForEvent("onremove", function()
            TheWorld:DoTaskInTime(1,function()
                TheWorld:PushEvent("tbat_event.fantasy_island_anchor_watch_dog_protector_start")
            end)
        end)
        inst:ListenForEvent("tbat_event.fantasy_island_anchor_watch_dog_protector_start",function()
            watch_dog_protector_task(inst)            
        end,TheWorld)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local ret_prefabs = {}
    for k, name in pairs(types) do
        local this_prefab = base_prefab..name
        local fn = function()
            local inst = common_fn()
            inst:AddTag(this_prefab)
            inst.flag = name
            if not TheWorld.ismastersim then
                return inst
            end
            return inst
        end
        table.insert(ret_prefabs,Prefab(this_prefab, fn, assets))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- return Prefab(this_prefab, fn, assets)
return unpack(ret_prefabs)
