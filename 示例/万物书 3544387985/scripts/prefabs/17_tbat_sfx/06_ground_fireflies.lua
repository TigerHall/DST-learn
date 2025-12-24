--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_sfx_ground_fireflies.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function onhammered(inst, worker)        
        inst:Remove()
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
    local function fx()
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
        inst:AddTag("NOBLOCK")

        inst.entity:AddLight()
        -- inst.Light:SetColour(0/255, 180/255, 255/255)
        inst.Light:SetColour(255/255, 255/255, 255/255)
        inst.Light:SetIntensity(0.65)
        inst.Light:SetRadius(0.9)
        inst.Light:SetFalloff(.45)
        inst.Light:Enable(true)

        inst.entity:SetPristine()
        -- inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            return inst
        end
        inst:ListenForEvent("Set",fx_set_event)
        inst:DoTaskInTime(0,rotation_init)
        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onhammered)
        -- inst.components.workable:SetOnWorkCallback(onhit)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_sfx_ground_fireflies", fx, assets)