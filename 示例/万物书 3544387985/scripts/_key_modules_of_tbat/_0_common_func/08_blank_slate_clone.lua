----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    白板复制目标，清除模块、tag

]]--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 带这些组件的都不算物品
    local is_not_item_com = {
        ["spellbook"] = true,
        ["aoetargeting"] = true,
        ["container"] = true,
    }
    local function item_com_check_succeed(item)
        for com_name, v in pairs(item.components) do
            if is_not_item_com[com_name] then
                return false
            end
        end
        return true
    end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function TBAT.FNS:BlankStateClone(target_or_prefab,ex_tags)
    -------------------------------------------------------------------
    --- 物品的时候直接复制白板
        if type(target_or_prefab) == "table"
            and target_or_prefab.prefab
            and target_or_prefab.sg == nil
            and target_or_prefab.brainfn == nil
            and target_or_prefab.components.health == nil
            and target_or_prefab.components.combat == nil
            and item_com_check_succeed(target_or_prefab)
            then
                return self:BlankStateCloneItem(target_or_prefab,ex_tags)
        end
        --- 其他情况走下面形式。
    -------------------------------------------------------------------
    local prefab = target_or_prefab
    local bank,build,anim = nil,nil,nil
    local scale_x,scale_y,scale_z = 1,1,1
    if type(target_or_prefab) == "table" then
        -- prefab = target_or_prefab.prefab
        bank,build,anim = TBAT.FNS:GetBankBuildAnim(target_or_prefab)
        local flag,tx,ty,tz = pcall(function()
            return target_or_prefab.AnimState:GetScale()
        end)
        if flag then
            scale_x,scale_y,scale_z = tx,ty,tz
        end
    else
        local temp_inst = SpawnPrefab(prefab)
        local bank,build,anim = TBAT.FNS:GetBankBuildAnim(temp_inst)
        temp_inst:Remove()
    end
    local fx = SpawnPrefab("tbat_other_fake_item_for_follow_layer")
    if bank and build and anim then
        fx.AnimState:SetBank(bank)
        fx.AnimState:SetBuild(build)
        fx.AnimState:PlayAnimation(anim,true)
        fx.AnimState:SetScale(scale_x,scale_y,scale_z)
        -- print("TBAT.FNS:BlankStateClone",prefab,bank,build,anim,scale_x,scale_y,scale_z)
    end
    fx:AddTag("nosteal")
    if type(ex_tags) == "table" then
        for k, v in pairs(ex_tags) do
            fx:AddTag(v)
        end
    end
    fx.persists = false   --- 是否留存到下次存档加载。
    return fx
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function StopAllTimerTask(inst)
        inst:CancelAllPendingTasks()
    end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local components_white_list = {
    ["inventoryitem"] = true,
}
function TBAT.FNS:BlankStateCloneItem(target_or_prefab,ex_tags)
    local prefab = target_or_prefab
    if type(target_or_prefab) == "table" then
        prefab = target_or_prefab.prefab
    end
    local item_fx = SpawnPrefab(prefab)
    StopAllTimerTask(item_fx)
    local tags = TBAT.FNS:GetAllTags(item_fx)
    for k, v in pairs(tags) do
        item_fx:RemoveTag(v)
    end
    for com_name, v in pairs(item_fx) do
        if not components_white_list[com_name] then
            item_fx:RemoveComponent(com_name)
        end
    end
    if type(ex_tags) == "table" then
        for k, v in pairs(ex_tags) do
            item_fx:AddTag(v)
        end
    end
    item_fx.prefab = "tbat_other_fake_item_for_follow_layer"
    item_fx:CancelAllPendingTasks()
    item_fx:RemoveAllEventCallbacks()
    item_fx:StopAllWatchingWorldStates()
    if item_fx.Physics then
        item_fx.Physics:ClearMotorVelOverride()
        item_fx.Physics:SetMotorVel(0,0,0)
        item_fx.Physics:SetMotorVelOverride(0,0,0)
        item_fx.Physics:SetActive(false)
    end
    item_fx:AddTag("nosteal")
    item_fx.persists = false   --- 是否留存到下次存档加载。

    return item_fx
end