--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_turf_water_lily_cat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local ret_prefabs = {}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 地面特效上的猫
    local function AddHighLightChild(inst,child)
        inst.highlightchildren = inst.highlightchildren or{}
        table.insert(inst.highlightchildren,child)
    end
    local function AddHighLightChild_Client(inst)
        local parent = inst.entity:GetParent()
        if parent then
            parent.highlightchildren = parent.highlightchildren or{}
            table.insert(parent.highlightchildren,inst)
        end
    end
    local fx_data = {
        {
            anim = "cat2",                
            pt = Vector3(0,0,0),
            fn = function(fx,parent)
                local inst = parent.face_fx
                fx.entity:SetParent(inst.entity)
                fx.entity:AddFollower()
                fx.Follower:FollowSymbol(inst.GUID, "slot", 0, 0, 0)
                fx.AnimState:SetTime(math.random(3))
            end,
        },
        {   anim = "cat4", pt = Vector3(-2.3,0,-1.5), },
        {   anim = "cat3", pt = Vector3(-2,0,1), },
        {   anim = "cat1", pt = Vector3(1.7,0,1), },
        {   anim = "cat1", pt = Vector3(-0.5,0,-2), },
        {   anim = "cat1", pt = Vector3(-0.7,0,2.2),fn = function(fx) fx.AnimState:SetScale(-1,1) end },
        {   anim = "cat2", pt = Vector3(1.5,0,-1.3), fn = function(fx) fx.AnimState:SetScale(-0.5,0.5)  end},
    }
    local function create_cats(inst)
        inst.cats = inst.cats or {}
        if #inst.cats > 0 then
            return
        end
        inst.face_fx = inst:SpawnChild("tbat_turf_water_lily_cat_face_fx")
        AddHighLightChild(inst,inst.face_fx)        
        for num, data in pairs(fx_data) do
            local fx = inst:SpawnChild("tbat_turf_water_lily_cat_fx")
            table.insert(inst.cats,fx)
            local x,y,z = data.pt.x,0,data.pt.z
            fx.Transform:SetPosition(x,0,z)
            fx.AnimState:PlayAnimation(data.anim,true)
            if data.fn then
                data.fn(fx,inst)
            end
            fx.AnimState:SetTime(math.random(3))
            AddHighLightChild(inst,fx)
        end
    end
    local function cats_show_internal(inst,flag)
        for k, v in pairs(inst.cats) do
            if flag then
                v:Show()
            else
                v:Hide()
            end
        end
    end
    local function cats_show_event(inst,flag)
        inst.cats = inst.cats or {}
        if #inst.cats == 0 then
            inst:DoTaskInTime(0, function()
                create_cats(inst)
                cats_show_internal(inst,flag)
            end)            
        else
            cats_show_internal(inst,flag)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 地面特效
    local rotations = {0,90,180,270}
    local function init_fn(inst)        
        local x,y,z = inst.Transform:GetWorldPosition()
        if TheWorld.Map:GetTileAtPoint(x,y,z) ~= WORLD_TILES[string.upper("tbat_turf_water_lily_cat")] then
            inst:Remove()
            return
        end
        x,y,z = TBAT.MAP:GetTileCenterPoint(x,y,z)
        inst.Transform:SetPosition(x,0,z)
        inst.Transform:SetRotation(rotations[math.random(#rotations)])
        create_cats(inst)
    end
    local function onload_remove_test(com)
        local inst = com.inst
        if com:Get("removed") then
            inst:Remove()
            return
        end
    end
    local function remove_event(inst)
        inst:Hide()
        inst.Transform:SetPosition(10000,1000,10000)
        inst.components.tbat_data:Set("removed",true)
    end
    local function logic_install(inst)
        local fn = require("prefabs/14_tbat_turfs/01_water_lily_cat_logic")
        if type(fn) == "function" then
            fn(inst)
        end
    end
    local function ground_fx()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_turf_water_lily_cat.tex")

        -- inst:AddTag("walkableplatform")
        inst:AddTag("waterproofer")
        inst:AddTag("tbat_turf_water_lily_cat")
        inst:SetDeploySmartRadius(2.8) --- 不允许在这个范围内种植、建造东西

        inst.AnimState:SetBank("tbat_turf_water_lily_cat")
        inst.AnimState:SetBuild("tbat_turf_water_lily_cat")
        inst.AnimState:PlayAnimation("ground_fx",true)
        -- inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

        inst.AnimState:HideSymbol("test")
        inst.AnimState:SetTime(math.random(5))

        inst.entity:SetPristine()
        -------------------------------------------------
        --- 高亮处理
            inst:AddComponent("highlight")  -- parent.highlightchildren = {inst}
        -------------------------------------------------
        --- 外围逻辑
            if TheWorld.ismastersim then
                inst:AddComponent("tbat_data")
            end
            logic_install(inst)
        -------------------------------------------------
        --- master sim
            if not TheWorld.ismastersim then
                return inst
            end
        -------------------------------------------------
        --- 防水
            inst:AddComponent("waterproofer")            
        -------------------------------------------------
        --- 可步行平台
            -- inst:AddComponent("walkableplatform")
        -------------------------------------------------
        --- 检查
            -- inst:AddComponent("inspectable")
        -------------------------------------------------
        --- 初始化
            inst:DoTaskInTime(0,init_fn)
        -------------------------------------------------
        --- 显示猫咪
            inst:ListenForEvent("show_cats",cats_show_event)
        -------------------------------------------------
        --- 移除。直接删除会有几率崩溃，直接移走隐藏。下次存档重载的时候再移除。
            inst:ListenForEvent("destory_remove",remove_event)
            inst.components.tbat_data:AddOnLoadFn(onload_remove_test)
        -------------------------------------------------
        return inst
    end
    table.insert(ret_prefabs,Prefab("tbat_turf_water_lily_cat", ground_fx, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 脸部
    local function onnear(inst)
        inst.AnimState:OverrideSymbol("emoji_normal","tbat_turf_water_lily_cat","emoji_press")
        inst.SoundEmitter:PlaySound("tbat_sound_stage_1/tbat_turf_water_lily_cat/onwork_"..math.random(2))
    end
    local function onfar(inst)
        inst.AnimState:ClearOverrideSymbol("emoji_normal")
    end
    local function face_fx()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("CLASSIFIED")
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        inst.Transform:SetEightFaced()

        inst.AnimState:SetBank("tbat_turf_water_lily_cat")
        inst.AnimState:SetBuild("tbat_turf_water_lily_cat")
        inst.AnimState:PlayAnimation("face")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(1)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:HideSymbol("text")
        inst.AnimState:OverrideSymbol("slot","tbat_turf_water_lily_cat","slot_empty")


        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = AddHighLightChild_Client
            return inst
        end

        inst:AddComponent("playerprox")
        inst.components.playerprox:SetDist(1.5, 2)
        inst.components.playerprox:SetOnPlayerNear(onnear)
        inst.components.playerprox:SetOnPlayerFar(onfar)


        return inst
    end
    table.insert(ret_prefabs,Prefab("tbat_turf_water_lily_cat_face_fx", face_fx, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function cat_fx()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst:AddTag("CLASSIFIED")
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")

        inst.AnimState:SetBank("tbat_turf_water_lily_cat")
        inst.AnimState:SetBuild("tbat_turf_water_lily_cat")
        -- inst.AnimState:PlayAnimation("idle")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = AddHighLightChild_Client
            return inst
        end
        return inst
    end
    table.insert(ret_prefabs,Prefab("tbat_turf_water_lily_cat_fx", cat_fx, assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    return unpack(ret_prefabs)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- return Prefab(this_prefab, fn, assets)
