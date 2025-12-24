----------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    动物相关的ACTION 注册。用来解决 sg 的 handler 缺失。

    【注意】需要同时处理brain里的 执行 BufferAction。

]]--
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- pog 相关 ： 巴哈理
    AddAction("TBAT_POG_BARK","Bark",function(act)
            return true
    end)
    AddAction("TBAT_POG_RANSACK","Ransack",function(act)
        return true
    end)
    AddAction("MAPLE_SQUIRREL_BOX","Ransack",function(act)
        local doer = act.doer
        local target = act.target

        doer.components.inventory:ForEachItem(function(item)
            if item == nil then
                return
            end
            local record = item:GetSaveRecord()
            item:Remove()
            -- doer.components.inventory:DropItem(item)
            target.components.container:GiveItem(SpawnSaveRecord(record))
        end)
        return true
    end)
    --- 薰衣草猫猫
    AddAction("TBAT_PET_LAVENDER_KITTY_PICK","lavender_kitty_pick",function(act)
        local doer = act.doer
        local target = act.target
        if doer and doer.DoPick then
            doer:DoPick(target)
        end
    end)
    --- 帽子鳐鱼
    AddAction("TBAT_PET_STINKRAY_DO_SWIM_FOR_BURNING","Stinkray_do_swim",function(act)
        local doer = act.doer
        if doer and doer.components.burnable and doer.components.burnable:IsBurning() then
            doer.components.burnable:Extinguish(true)
            -- doer.components.burnable:KillFX()
            -- print("灭火")
        end
        return not doer.components.burnable:IsBurning()
    end)
    AddAction("TBAT_PET_STINKRAY_WANDER_ACTIVE","Stinkray_wander_active",function(act)
        local doer = act.doer
        return true
    end)
    AddAction("TBAT_PET_STINKRAY_WATERPLANT_SHAVE","Stinkray_water_plant_shave",function(act)
        local doer = act.doer
        local target = act.target
        if target and doer 
            and target.components.shaveable and target.components.shaveable:CanShave(target)
            and target.components.harvestable and target.components.harvestable:CanBeHarvested()
            then
                target.components.harvestable:Harvest(doer)
            return true
        end
        return true
    end)
    AddAction("TBAT_PET_STINKRAY_OCEAN_TRAWLER_PICK","Stinkray_ocean_trawler_pick",function(act)
        local doer = act.doer
        local target = act.target
        if target and doer and target.components.container and not target.components.container:IsEmpty() then
            if doer and doer.OceanTrawlerPick then
                doer:OceanTrawlerPick(target)
            end
            return true
        end
        return true
    end)
----------------------------------------------------------------------------------------------------------------------------------------------------------------
