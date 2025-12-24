function hp2hm_save()
    local player = ConsoleCommandPlayer()
    local pt = ConsoleWorldPosition()

    if player and player.components.inventory then
        local hand = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if hand then
            local record = hand:GetSaveRecord()
            TheSim:SetPersistentString("./../../save_hand_record.data", DataDumper(record, nil, false), false)
            print("save", tostring(hand))
        end
    end
end

function hp2hm_load()
    local player = ConsoleCommandPlayer()
    local pt = ConsoleWorldPosition()

    TheSim:GetPersistentString("./../../save_hand_record.data",
        function(load_success, str)
            if load_success == true then
                local success, savedata = RunInSandboxSafe(str)
                if success and string.len(str) > 0 and savedata ~= nil then
                    local inst = SpawnSaveRecord(savedata)
                    inst.Transform:SetPosition(pt:Get())
                    print("load", tostring(inst))
                end
            else
                print ("Could not load save_hand_record.data")
            end
        end)
end
-- =======================================================================================================
-- 删除桥梁地块
-- local p=ConsoleCommandPlayer() local x,y,z=p.Transform:GetWorldPosition() 
-- local m=TheWorld.Map local r=TheWorld.components.ropebridgemanager 
--     for i=-15,15 do 
--         for j=-15,15 do 
--         local tx,ty=m:GetTileCoordsAtPoint(x+i*4,0,z+j*4) 
--         if r.duration_grid:GetDataAtPoint(tx,ty) then 
--             local cx,cy,cz=m:GetTileCenterPoint(tx,ty) 
--             r:DestroyRopeBridgeAtPoint(cx,cy,cz) 
--             print("OK") 
--             return 
--         end 
--     end 
-- end print("None")
-- =======================================================================================================
-- 查询Boss倒计时 
function timer_boss2hm()
    if not TheWorld.components.worldsettingstimer then
        c_announce("世界无时令Boss计时器")
        return
    end
    
    local SEASONAL_BOSS_TIMERS = {
        {name = "deerclops_timetoattack", label = "巨鹿"},
        {name = "mothergoose_timetoattack", label = "鹅妈妈"},
        {name = "mockfly_timetoattack", label = "龙蝇"},
        {name = "bearger_timetospawn", label = "熊獾"},
    }
    
    local result = "=== 时令Boss倒计时 ==="
    local current_day = TheWorld.state.cycles + 1  -- 当前天数（从1开始）
    for _, timer_info in ipairs(SEASONAL_BOSS_TIMERS) do
        local t = TheWorld.components.worldsettingstimer:GetTimeLeft(timer_info.name)
        if t then
            local paused = TheWorld.components.worldsettingstimer:IsPaused(timer_info.name)
            local minutes = t / 60
            local days_offset = t / TUNING.TOTAL_DAY_TIME  -- 剩余天数
            local attack_day = current_day + days_offset  -- 袭击发生的天数
            result = result .. string.format("\n%s: %.1f分钟 (第%.1f天)%s", 
                timer_info.label, minutes, attack_day, paused and " [已暂停]" or "")
        else
            result = result .. string.format("\n%s: 未激活", timer_info.label)
        end
    end
    c_announce(result)
end
-- =======================================================================================================
-- 查询猎犬/蠕虫倒计时 
function timer_hound2hm()
    if not TheWorld.components.hounded then
        c_announce("世界无猎犬/蠕虫组件")
        return
    end
    
    local result = ""
    local is_cave = TheWorld:HasTag("cave")
    
    -- 判断是猎犬还是蠕虫
    if is_cave then
        result = "=== 蠕虫袭击倒计时 ==="
    else
        result = "=== 猎犬袭击倒计时 ==="
    end
    
    local hounded = TheWorld.components.hounded
    local t = hounded:GetTimeToAttack()  
    local current_day = TheWorld.state.cycles + 1  -- 当前天数（从1开始）
    
    if t and t > 0 then
        local debug_string = hounded.GetDebugString and hounded:GetDebugString() or ""
        local is_paused = string.find(debug_string, "BLOCKED") ~= nil
        
        local minutes = t / 60
        local days_offset = t / TUNING.TOTAL_DAY_TIME   -- 剩余天数
        local attack_day = current_day + days_offset    -- 袭击发生的天数
        result = result .. string.format("\n倒计时: %.1f分钟 (第%.1f天)%s", 
            minutes, attack_day, is_paused and " [已暂停]" or "")
            
    else
        result = result .. "\n倒计时: 未激活"
    end
    
    
    c_announce(result)
end

