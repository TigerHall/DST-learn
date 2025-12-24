--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_resources_memory_crystal_ore_fx"
    local FLOWER_SPAWN_RADIUS = 3
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_resources_memory_crystal_ore.zip"),
        Asset("ANIM", "anim/tbat_resources_memory_crystal_ore_mine_fx.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- set 绑定 父实体
    local function set_event(inst,_table)
        local anim_type = _table.type or 1
        inst.AnimState:PlayAnimation("fx"..anim_type,true)
        inst.AnimState:SetTime(3*math.random())
        inst.AnimState:SetScale(math.random() < 0.5 and 1 or -1,1,1)
        local parent = _table.parent or inst.entity:GetParent()
        if parent then
            inst:ListenForEvent("flower_picked",function()
                parent.components.tbat_data:Set("last_flower_picked_day",TheWorld.state.cycles)
            end,parent)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 刷新伴生花控制器
    local flower_prefab = "tbat_plant_ephemeral_flower"
    local function HasFlower(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        -- print("++++ has flower",x,y,z)
        local ents = TheSim:FindEntities(x,y,z,FLOWER_SPAWN_RADIUS,{"tbat_plant_ephemeral_flower"})
        return #ents > 0
    end
    local function flower_spawner(inst)
        -------------------------------------------------------------------------------------------------------------------
        --- 前置检查
            if not inst:IsValid() then
                return
            end
            if not inst:IsAsleep() and not TBAT.DEBUGGING then
                return
            end
            if HasFlower(inst) then
                return
            end
        -------------------------------------------------------------------------------------------------------------------
        --- 采集重生CD
            local parent = inst.entity:GetParent()
            -- print("采集重生TEST",parent,parent.components.tbat_data:Get("last_flower_picked_day"))
            if parent.components.tbat_data:Get("last_flower_picked_day") == nil then

            else
                local today = TheWorld.state.cycles
                local last_day = parent.components.tbat_data:Get("last_flower_picked_day")
                if today - last_day < 3 then
                    -- print("花生成CD",today - last_day)
                    return
                end
            end
            -- print(" ++++++++ 生成花 ++++++++ ",inst)
            parent.components.tbat_data:Set("last_flower_picked_day",nil)
        -------------------------------------------------------------------------------------------------------------------
        local avalable_points = {}
        local radius = FLOWER_SPAWN_RADIUS
        local test_butterfly = SpawnPrefab("butterfly")
        while radius > 1 do
            local points = TBAT.FNS:GetSurroundPoints({
                target = inst,
                range = radius,
                num = radius*4*5,
            })
            for k, pt in pairs(points) do
                if TheWorld.Map:CanDeployPlantAtPoint(pt,test_butterfly) then
                    table.insert(avalable_points,pt)
                end
            end
            radius = radius - 0.5
        end
        test_butterfly:Remove()
        if #avalable_points == 0 then
            return
        end
        local pt = avalable_points[math.random(1,#avalable_points)]
        local flower = SpawnPrefab(flower_prefab)
        flower.Transform:SetPosition(pt.x,0,pt.z)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- client light
    local function create_client_light(parent)
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddLight()
        inst.Light:SetFalloff(0.85)
        inst.Light:SetIntensity(.3)
        inst.Light:SetRadius(0.8)
        inst.Light:SetColour(100 / 255, 255 / 255, 255 / 255)
        inst.entity:SetParent(parent.entity)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()        
        inst.AnimState:SetBank("tbat_resources_memory_crystal_ore")
        inst.AnimState:SetBuild("tbat_resources_memory_crystal_ore")
        inst.AnimState:PlayAnimation("fx1",true)
        inst.AnimState:HideSymbol("idle")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetMultColour(1,1,1,0.7)
        -- inst.AnimState:SetTime(3*math.random())
        inst:AddTag("NOCLICK")
        inst:AddTag("fx")
        inst:AddTag("FX")
        inst.entity:AddLight()
        inst.Light:SetFalloff(0.85)
        inst.Light:SetIntensity(.75)
        inst.Light:SetRadius(0.3)
        inst.Light:SetColour(178 / 255, 102 / 255, 255 / 255)
        inst.entity:SetPristine()
        if not TheNet:IsDedicated() then
            create_client_light(inst)
        end
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            return inst
        end
        inst:ListenForEvent("Set",set_event)
        inst:WatchWorldState("cycles",flower_spawner)
        inst:WatchWorldState("isday",flower_spawner)
        inst:WatchWorldState("isdusk",flower_spawner)
        inst:WatchWorldState("isnight",flower_spawner)
        TheWorld:DoTaskInTime(0,function()
            flower_spawner(inst)
        end)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 挖矿特效
    local function mine_fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()        
        inst.AnimState:SetBank("mining_fx")
        inst.AnimState:SetBuild("tbat_resources_memory_crystal_ore_mine_fx")
        inst.AnimState:PlayAnimation("anim",false)
        -- inst.AnimState:SetMultColour(1,1,1,0.7)
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        inst:ListenForEvent("animover",inst.Remove)
        inst.AnimState:SetScale( math.random() < 0.5 and 2 or -2,2,2)
        if not TheWorld.ismastersim then
            return inst
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
    Prefab(this_prefab.."_for_mine", mine_fx, assets)
