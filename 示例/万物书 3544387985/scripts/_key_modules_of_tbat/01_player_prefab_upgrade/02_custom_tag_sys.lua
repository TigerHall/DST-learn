-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddPlayerPostInit(function(inst)
    -- 定义唯一前缀，避免与其他 MOD 的标签冲突
    local CUSTOM_TAG_PREFIX = "tbat_custom_"

    -- 自定义标签系统初始化
    local tbat_tag_sys_ready = false
    if not inst.TBATAddTag then
        inst.TBATAddTag = function(inst, tag)
            if TheWorld.ismastersim and inst.components.tbat_com_custom_tags then
                if not tbat_tag_sys_ready then
                    inst:DoTaskInTime(0, function()
                        inst.components.tbat_com_custom_tags:AddTag(CUSTOM_TAG_PREFIX .. tag)
                        tbat_tag_sys_ready = true
                    end)
                else
                    inst.components.tbat_com_custom_tags:AddTag(CUSTOM_TAG_PREFIX .. tag)
                end
            end
        end
        inst:DoTaskInTime(0, function()
            tbat_tag_sys_ready = true
        end)
    end

    if not inst.TBATRemoveTag then
        inst.TBATRemoveTag = function(inst, tag)
            if TheWorld.ismastersim and inst.components.tbat_com_custom_tags then
                if not tbat_tag_sys_ready then
                    inst:DoTaskInTime(0, function()
                        inst.components.tbat_com_custom_tags:RemoveTag(CUSTOM_TAG_PREFIX .. tag)
                        tbat_tag_sys_ready = true
                    end)
                else
                    inst.components.tbat_com_custom_tags:RemoveTag(CUSTOM_TAG_PREFIX .. tag)
                end
            end
        end
    end

    if not inst.TBATHasTag then
        inst.TBATHasTag = function(inst, tag)
            if TheWorld.ismastersim then
                return inst.components.tbat_com_custom_tags and inst.components.tbat_com_custom_tags:HasTag(CUSTOM_TAG_PREFIX .. tag)
            else
                return inst.replica.tbat_com_custom_tags and inst.replica.tbat_com_custom_tags:HasTag(CUSTOM_TAG_PREFIX .. tag)
            end
            return false
        end
    end

    -- 保存原始 HasTag 方法
    local old_has_tag = inst.HasTag
    -- 使用唯一前缀隔离自定义标签逻辑
    inst.HasTag = function(inst, tag)
        -- 如果是自定义标签，直接调用自定义逻辑
        if type(tag) == "string" and tag:sub(1, #CUSTOM_TAG_PREFIX) == CUSTOM_TAG_PREFIX then
            return inst.TBATHasTag(inst, tag)
        end

        -- 调用原始 HasTag 时添加递归保护
        local old_flag = false
        local call_depth = 0
        local function safe_call()
            call_depth = call_depth + 1
            if call_depth > 10 then
                error("HasTag recursion detected for tag: " .. tag)
                return false
            end
            old_flag = old_has_tag(inst, tag)
            call_depth = call_depth - 1
        end
        safe_call()

        -- 如果原始 HasTag 返回 false，再检查自定义标签
        if not old_flag and tbat_tag_sys_ready then
            old_flag = inst.TBATHasTag(inst, tag)
        end
        return old_flag
    end

    -- 添加自定义组件（仅服务器端）
    if TheWorld.ismastersim then
        inst:AddComponent("tbat_com_custom_tags")
    end
end)