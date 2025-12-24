--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local assets =
    {
        Asset("ANIM", "anim/tbat_sfx_ground_four_leaves_clover.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 渐变
    local delta_down = 0.015
    local delta_up = 0.01
    local function display_init(inst)
        inst.AnimState:SetMultColour(1,1,1,0)
        inst.__current = inst.__current or 0
        inst.__wait_time = inst.__wait_time or 0
    end
    local function display_update(inst)
        if inst.__wait_time > 0 then
            inst.__wait_time = inst.__wait_time - 1
            return
        end
        if inst.__go_down then
            inst.__current = inst.__current - delta_down
            if inst.__current <= 0 then
                inst.__go_down = false
                inst.__wait_time = 30
            end
        else
            inst.__current = inst.__current + delta_up
            if inst.__current >= 1 then
                inst.__go_down = true
            end
        end
        inst.AnimState:SetMultColour(1,1,1,math.clamp(inst.__current,0,1))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function common_fn()
        local inst = CreateEntity()
        inst.entity:AddNetwork()
        inst.entity:AddTransform()
        inst:AddTag("CLASSIFIED")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("fx")
        inst:AddTag("FX")
        if not TheNet:IsDedicated() then
            inst.entity:AddAnimState()
            inst.AnimState:SetBank("tbat_sfx_ground_four_leaves_clover")
            inst.AnimState:SetBuild("tbat_sfx_ground_four_leaves_clover")
            inst.AnimState:PlayAnimation("idle")
            inst.AnimState:SetLightOverride(1)
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
            inst.AnimState:SetSortOrder(3)

            display_init(inst)
            inst:DoPeriodicTask(FRAMES,display_update)
        end
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            return inst
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_sfx_ground_four_leaves_clover", common_fn,assets)