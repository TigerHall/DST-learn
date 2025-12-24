--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    使用图层锚定偏移。方便任何尺寸的 文本 数据偏移。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_info_slot.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- slot 文本替换
    local function slot_update_fn(parent,data)
        --------------------------------------------------------------------
        --- 前置检查
            if parent.__last_check_display_type_is_layer ~= nil then
                local temp_current_type_is_layer = parent.__last_check_display_type_is_layer
                local temp_target_type_is_layer = data.layer ~= nil
                if parent.slot_inst ~= nil then
                    if temp_current_type_is_layer ~= temp_target_type_is_layer
                        or parent.__last_check_display_anim ~= data.anim then
                        parent.slot_inst:Remove()
                    end
                end
            end
        --------------------------------------------------------------------
        --- 创建动画控制节点inst
            if parent.slot_inst == nil or not parent.slot_inst:IsValid() then
                local inst = CreateEntity()
                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.AnimState:SetBank("tbat_building_info_slot")
                inst.AnimState:SetBuild("tbat_building_info_slot")
                -- inst.AnimState:PlayAnimation("idle")
                inst.AnimState:SetFinalOffset(1)
                inst.AnimState:OverrideSymbol("slot","tbat_building_info_slot","empty")
                inst:AddTag("fx")
                inst:AddTag("FX")
                inst:AddTag("INLIMBO")
                inst:AddTag("NOCLICK")
                inst:AddTag("NOBLOCK")
                inst.entity:SetParent(parent.entity)
                inst.entity:AddFollower()
                inst.Follower:FollowSymbol(parent.GUID, "slot",0,0,0)
                parent.slot_inst = inst
            end
            local inst = parent.slot_inst
        --------------------------------------------------------------------
        --- 位置偏移
            if data.pt then
                inst.Follower:FollowSymbol(parent.GUID, "slot",data.pt.x,data.pt.y,0)
            end
        --------------------------------------------------------------------
        --- 尺寸缩放
            if data.scale then
                if type(data.scale) == "number" then
                    inst.AnimState:SetScale(data.scale,data.scale,data.scale)
                elseif type(data.scale) == "table" then
                    inst.AnimState:SetScale(data.scale.x,data.scale.y,data.scale.z)
                end
            else
                inst.AnimState:SetScale(1,1)
            end
        --------------------------------------------------------------------
        --- 模式切换
            local current_type_is_layer = inst.layer ~= nil
            local target_type_is_layer = data.layer ~= nil
            parent.__last_check_display_type_is_layer = target_type_is_layer
            parent.__last_check_display_anim = data.anim
            if current_type_is_layer and target_type_is_layer then
                --- 同是layer模式
                -- print("同是layer模式")
                inst.AnimState:SetBank("tbat_building_info_slot")
                inst.AnimState:SetBuild("tbat_building_info_slot")
                if not inst.AnimState:IsCurrentAnimation("idle") then
                    inst.AnimState:PlayAnimation("idle")
                end
                if inst.layer == data.layer then

                else
                    inst.AnimState:OverrideSymbol("slot",data.build,data.layer)
                end
                inst.build = data.build
                inst.layer = data.layer
                inst.bank = nil
                inst.anim = nil
            elseif current_type_is_layer == false and target_type_is_layer == true then
                --- anim 模式 -> layer 模式
                -- print("anim 模式 -> layer 模式")
                inst.AnimState:SetBank("tbat_building_info_slot")
                inst.AnimState:SetBuild("tbat_building_info_slot")
                inst.AnimState:PlayAnimation("idle")
                -- inst.AnimState:ClearOverrideSymbol("slot")
                inst.AnimState:OverrideSymbol("slot",data.build,data.layer)
                inst.build = data.build
                inst.layer = data.layer
                inst.bank = nil
                inst.anim = nil
            elseif current_type_is_layer == false and target_type_is_layer == false then
                --- 同是anim模式
                -- print("同是anim模式")
                if inst.bank == data.bank and inst.anim == data.anim and inst.build == data.build then
                    
                else
                    inst.AnimState:SetBank(data.bank)
                    inst.AnimState:SetBuild(data.build)
                    inst.AnimState:PlayAnimation(data.anim,true)
                end
                inst.bank = data.bank
                inst.anim = data.anim
                inst.build = data.build
                inst.layer = nil
            elseif current_type_is_layer == true and target_type_is_layer == false then
                --- layer 模式 -> anim 模式
                -- print("layer 模式 -> anim 模式")
                inst.AnimState:SetBank(data.bank)
                inst.AnimState:SetBuild(data.build)
                inst.AnimState:PlayAnimation(data.anim,true)
                inst.AnimState:ClearOverrideSymbol("slot")
                inst.bank = data.bank
                inst.anim = data.anim
                inst.build = data.build
                inst.layer = nil
            end
        --------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- net 数据传送
    local function Set_Event(inst,_table)
        inst.data = _table or {}
        local str = json.encode(inst.data)
        inst.__net_json_data:set(str)
    end
    local function json_data_update_fn(inst)
        local data_str = inst.__net_json_data:value()
        local flag,data = pcall(json.decode,data_str)
        if flag then
            inst:PushEvent("update_slot",data)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- wake / sleep
    local function sync_task_fn(inst)
        inst.data = inst.data or {}
        inst.data.flag = math.random(1000000)
        local str = json.encode(inst.data)
        inst.__net_json_data:set(str)
    end
    local function entitywake_event(inst)
        if inst.___sync_task then
            return
        end
        inst.___sync_task = inst:DoPeriodicTask(1,sync_task_fn)
    end
    local function entitysleep_event(inst)
        if inst.___sync_task then
            inst.___sync_task:Cancel()
        end
        inst.___sync_task = nil
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 主体
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_building_info_slot")
        inst.AnimState:SetBuild("tbat_building_info_slot")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:OverrideSymbol("slot","tbat_building_info_slot","empty")
        inst:AddTag("fx")
        inst:AddTag("FX")
        inst:AddTag("INLIMBO")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst.__net_json_data = net_string(inst.GUID, "net_json_data", "json_data_update")
        inst.entity:SetPristine()
        ---------------------------------------------------------------------
        --
            if not TheNet:IsDedicated() then
                inst:ListenForEvent("json_data_update",json_data_update_fn)
                inst:ListenForEvent("update_slot",slot_update_fn)
            end
        ---------------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ---------------------------------------------------------------------
        ---
            inst:ListenForEvent("Set", Set_Event)
        ---------------------------------------------------------------------
        ---
            inst:ListenForEvent("entitywake", entitywake_event)
            inst:ListenForEvent("entitysleep", entitysleep_event)
        ---------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab("tbat_building_info_slot", fn, assets)
