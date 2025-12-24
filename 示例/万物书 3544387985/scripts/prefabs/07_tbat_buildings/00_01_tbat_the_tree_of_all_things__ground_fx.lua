--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    地面的云阴影。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_the_tree_of_all_things__ground_fx"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_the_tree_of_all_things__ground_fx.zip"),
        Asset("ANIM", "anim/tbat_sfx_ground_fireflies.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function get_mirror_random()
        if math.random() > 0.5 then
            return -1
        else
            return 1
        end
    end
    local function create_fx(parent)
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst:AddTag("INLIMBO")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("fx")
        inst:AddTag("FX")
        inst.AnimState:SetBank(this_prefab)
        inst.AnimState:SetBuild(this_prefab)
        inst.AnimState:PlayAnimation("fx",true)
        inst.AnimState:SetTime(10*math.random())
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(1)
        inst.AnimState:SetFinalOffset(2)
        inst.entity:SetParent(parent.entity)        
        local random_num = math.random(7)
        if random_num > 1 then
            inst.AnimState:OverrideSymbol("cloud_1",this_prefab,"cloud_"..random_num)            
        end
        inst.entity:SetParent(parent.entity)
        inst.entity:AddFollower()
        inst.Follower:FollowSymbol(parent.GUID, "slot", 0, 0, 0,true)
        inst.AnimState:SetScale(get_mirror_random(),get_mirror_random(),get_mirror_random())
        inst.AnimState:SetAddColour(0/255,0/255,0/255,0.6)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function set_location(inst,pt)
        inst.Transform:SetPosition(pt.x,pt.y,pt.z)
    end
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank(this_prefab)
        inst.AnimState:SetBuild(this_prefab)
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(1)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:HideSymbol("text")
        inst.AnimState:OverrideSymbol("slot",this_prefab,"empty")
        inst:AddTag("INLIMBO")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("fx")
        inst:AddTag("FX")
        inst.Transform:SetEightFaced()
        if not TheNet:IsDedicated() then
            create_fx(inst)
        end
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            return inst
        end
        inst:ListenForEvent("Set",set_location)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 萤火虫特效
    local rot_table = {0,45,90,135,180,-180,-135,-90,-45}
    local function rotation_init(inst)
        inst.Transform:SetRotation(rot_table[math.random(#rot_table)])
    end
    local function fx_set_event(inst,cmd)
        inst.Transform:SetPosition(cmd.pt.x,0,cmd.pt.z)        
    end
    local function fn2()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_sfx_ground_fireflies")
        inst.AnimState:SetBuild("tbat_sfx_ground_fireflies")
        inst.AnimState:PlayAnimation("idle_loop",true)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetSortOrder(3)
	    inst.AnimState:SetRayTestOnBB(true)
        inst:AddTag("INLIMBO")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("fx")
        inst:AddTag("FX")
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            return inst
        end
        inst:ListenForEvent("Set",fx_set_event)
        inst:DoTaskInTime(0,rotation_init)
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
