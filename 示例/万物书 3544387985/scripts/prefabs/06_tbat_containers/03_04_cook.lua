--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    烹饪逻辑

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local cooking = require("cooking")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function get_visual_cook_pot(inst)
        local visual_cook_pot_prefab = "portablecookpot"
        local visual_cook_pot = inst.visual_cook_pot
        if visual_cook_pot and visual_cook_pot:IsValid() then

        else
            visual_cook_pot = inst:SpawnChild(visual_cook_pot_prefab)
            visual_cook_pot.Transform:SetPosition(0,100,0)
            visual_cook_pot:Hide()
            visual_cook_pot.MiniMapEntity:SetEnabled(false)
            visual_cook_pot:ListenForEvent("onclose",function()
                visual_cook_pot:Remove()
            end,inst)
            inst.visual_cook_pot = visual_cook_pot                
        end
        return inst.visual_cook_pot
    end
    ------------------------------------------------------------------------
    --- 处理新鲜度的问题
        
    ------------------------------------------------------------------------
    local function start_cooking(inst,doer)
        local start_slot = 16*6
        local cook_items = {}
        for i = 1, 4, 1 do
            local item = inst.components.container:GetItemInSlot(start_slot+i)
            if item and item.prefab and cooking.IsCookingIngredient(item.prefab) then
                table.insert(cook_items,item)
            end
        end
        if #cook_items ~= 4 then
            -- print("error in cooking")
            return
        end
        local visual_cook_pot = get_visual_cook_pot(inst)
        if visual_cook_pot.components.stewer:IsCooking() then
            return
        end
        -- print("cooking",visual_cook_pot)
        local item_for_cooking = {}
        for i,item in ipairs(cook_items) do 
            -- if item.components.stackable then
            --     if item.components.stackable:StackSize() == 1 then
            --         inst.components.container:DropItem(item)
            --         visual_cook_pot.components.container:GiveItem(item)
            --     else
            --         local temp_item = item.components.stackable:Get(1)
            --         visual_cook_pot.components.container:GiveItem(temp_item)
            --     end
            -- else
            --     inst.components.container:DropItem(item)
            --     visual_cook_pot.components.container:GiveItem(item)
            -- end
            visual_cook_pot.components.container:GiveItem(SpawnPrefab(item.prefab))
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            else
                item:Remove()
            end
        end
        visual_cook_pot.components.stewer.cooktimemult = 0
        visual_cook_pot.components.stewer:StartCooking(doer)
        -- local time = visual_cook_pot.components.stewer.targettime or 480
        visual_cook_pot.components.stewer:LongUpdate(1)
        inst:DoTaskInTime(FRAMES,function()
            visual_cook_pot.components.stewer:Harvest(doer)            
        end)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function cook_button(inst)
        local doer = inst.opener
        if doer == nil then
            return
        end
        -- if TBAT.start_cooking then
        --     TBAT.start_cooking(inst, doer)
        --     return
        -- end
        start_cooking(inst, doer)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("button_cook",cook_button)
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
