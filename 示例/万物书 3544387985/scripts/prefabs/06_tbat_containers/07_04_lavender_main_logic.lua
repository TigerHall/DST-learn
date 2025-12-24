--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- auto / manual 工作状态切换、记忆、声明切换。
    local function pushevent_for_working_type_switched(inst)
        inst:PushEvent("working_type_update")        
    end
    local function switch_auto_button_clicked(inst,auto)
        if type(auto) == "table" then
            auto = auto.auto
        end
        -- print("薰衣草猫猫：切换工作模式为："..tostring(auto))
        if auto then
            inst:AddTag("auto")
        else
            inst:RemoveTag("auto")
        end
        inst:DoTaskInTime(0,pushevent_for_working_type_switched)
    end
    local function auto_type_onload_fn(com)
        if com:Get("auto") then
            switch_auto_button_clicked(com.inst,true)
        else
            switch_auto_button_clicked(com.inst,false)
        end
    end
    local function auto_type_onsave_fn(com)
        if com.inst:HasTag("auto") then
            com:Set("auto",true)
        else
            com:Set("auto",false)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- auto working
    local function start_auto_work(inst)
        if not inst:HasTag("auto") then
            return
        end
        local timerInst = CreateEntity()
        local auto_farmming_work_fn = function()
            if not inst:HasTag("auto") then
                timerInst:Remove()
                switch_auto_button_clicked(inst,false)
                return
            end
            local callback = {}
            callback.succeed = false
            inst:PushEvent("start_farmming",callback)
            if callback.succeed then
                if TBAT.DEBUGGING then
                    print("薰衣草猫猫：自动种植完成，开始采集",inst)
                end
                local tempInst = CreateEntity()
                local auto_harvest_fn = function()
                    tempInst:Remove()
                    local callback = {}
                    inst:PushEvent("start_havest",callback)
                    if callback.succeed and TBAT.DEBUGGING then
                        print("薰衣草猫猫：自动采集完成",inst)
                    end
                end
                TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(tempInst,5,auto_harvest_fn)
            end
        end
        TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(timerInst,10,auto_farmming_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    return function(inst)
        -------------------------------------------------------------------------------
        --- 按钮切换事件
            inst:ListenForEvent("switch_auto_button_clicked",switch_auto_button_clicked)
            inst.components.tbat_data:AddOnLoadFn(auto_type_onload_fn)
            inst.components.tbat_data:AddOnSaveFn(auto_type_onsave_fn)
        -------------------------------------------------------------------------------
        --- 种植模块
            local farmming_work_logic_fn = require("prefabs/06_tbat_containers/07_05_lavender_farmming_work_logic")
            farmming_work_logic_fn(inst)
        -------------------------------------------------------------------------------
        --- 采集模块
            local harvest_logic_fn = require("prefabs/06_tbat_containers/07_06_lavender_harvest_area")
            harvest_logic_fn(inst)
        -------------------------------------------------------------------------------
        --- 自动工作模块
            inst:ListenForEvent("working_type_update",start_auto_work)
        -------------------------------------------------------------------------------
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------