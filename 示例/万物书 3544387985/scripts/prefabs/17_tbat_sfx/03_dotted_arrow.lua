--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    箭头指示器

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- param
    local PAD_DURATION = .1
    local SCALE = 1.5
    local FLASH_TIME = .3
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- common
    local function common_fn()
        local inst = CreateEntity()

        --[[Non-networked entity]]
        inst.entity:SetCanSleep(false)

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst:AddTag("CLASSIFIED")
        inst:AddTag("NOCLICK")
        -- inst:AddTag("placer")

        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        --[[Non-networked entity]]
        inst.entity:SetCanSleep(false)
        inst.persists = false

        inst.entity:AddTransform()
        inst.entity:AddAnimState()

        inst.AnimState:SetBank("reticuleline")
        inst.AnimState:SetBuild("reticuleline")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetScale(SCALE, SCALE)

        function inst:SetRotation(angle)
            --- 转置参数，输入为 -180 ~ 360 兼容。输出限制为 -180 ~ 180 .
            if (angle >= 0 and angle <= 180 ) or (angle <= 0 and angle >= -180) then
                inst.Transform:SetRotation(angle)
            end
            while angle > 180 do
                angle = angle - 360
            end
            while angle < -180 do
                angle = angle + 360
            end
            inst.Transform:SetRotation(angle)
        end

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fn()
        local inst = common_fn()
        inst.entity:AddNetwork()
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:ListenForEvent("Set",function(inst,_table)
            -- _table = {
            --     pt = Vector3(0,0,0),
            --     target = target,
            --     range = 1,
            --     color = Vector3(0,0,0),
            --     MultColour_Flag = false,
            -- }
            if type(_table) ~= "table" then
                return
            end

            if _table.pt then
                inst.Transform:SetPosition(_table.pt.x, _table.pt.y, _table.pt.z)
            end
            if _table.target then
                inst.Transform:SetPosition(_table.target.Transform:GetWorldPosition())
            end

            if _table.color and _table.color.x then
                if _table.MultColour_Flag ~= true then
                    inst:AddComponent("colouradder")
                    inst.components.colouradder:OnSetColour(_table.color.x/255 , _table.color.y/255 , _table.color.z/255 , _table.a or 1)
                else
                    inst.AnimState:SetMultColour(_table.color.x,_table.color.y, _table.color.z, _table.a or 1)
                end
            end
            ----------------------------------------------------------------------------------
                
            ----------------------------------------------------------------------------------
            inst.Ready = true
        end)

        inst:DoTaskInTime(0,function(inst)
            if not inst.Ready then
                inst:Remove()
            end
        end)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- client_only
    local function fn_client()
        local inst = common_fn()
        inst:ListenForEvent("Set",function(inst,_table)
            -- _table = {
            --     pt = Vector3(0,0,0),
            --     target = target,
            --     range = 1,
            --     color = Vector3(0,0,0),
            --     MultColour_Flag = false,
            -- }
            if type(_table) ~= "table" then
                return
            end

            if _table.pt then
                inst.Transform:SetPosition(_table.pt.x, _table.pt.y, _table.pt.z)
            end
            if _table.target then
                inst.Transform:SetPosition(_table.target.Transform:GetWorldPosition())
            end

            if _table.color and _table.color.x then
                if _table.MultColour_Flag ~= true then
                    inst:AddComponent("colouradder")
                    inst.components.colouradder:OnSetColour(_table.color.x/255 , _table.color.y/255 , _table.color.z/255 , _table.a or 1)
                else
                    inst.AnimState:SetMultColour(_table.color.x,_table.color.y, _table.color.z, _table.a or 1)
                end
            end
            ----------------------------------------------------------------------------------
                
            ----------------------------------------------------------------------------------
            inst.Ready = true
        end)

        inst:DoTaskInTime(0,function(inst)
            if not inst.Ready then
                inst:Remove()
            end
        end)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_sfx_dotted_arrow", fn),Prefab("tbat_sfx_dotted_arrow_client", fn_client)