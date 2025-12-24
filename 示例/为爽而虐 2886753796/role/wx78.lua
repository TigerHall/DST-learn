-- WX-78能力削弱，电路板只能使用1次，但拆卸没有损耗，连续拆卸掉1格电量
-- TUNING.WX78_MODULE_USES = 2
-- AddComponentPostInit(
--     "upgrademodule",
--     function(self)
--         self.inst:DoTaskInTime(
--             0,
--             function()
--                 self.onremovedfromownerfn = function()
--                 end
--             end
--         )
--     end
-- )
AddComponentPostInit("upgrademoduleowner", function(self)
    local old = self.UpdateActivatedModules
    self.UpdateActivatedModules = function(self, ...)
        old(self, ...)
        if self.inst.components.hunger then
            local level = 0
            for _, module in ipairs(self.modules) do
                if module and not module.nohunger2hm and module.components.upgrademodule.activated and module.level2hm then
                    level = level + module.components.upgrademodule.slots * module.level2hm:value()
                end
            end
            level = math.max(level - TUNING.WX78_MAXELECTRICCHARGE, 0)
            if level == 0 then
                self.inst.components.hunger.burnratemodifiers:RemoveModifier(self.inst, "wx78module2hm")
            else
                self.inst.components.hunger.burnratemodifiers:SetModifier(self.inst, 1 + 0.75 / TUNING.WX78_MAXELECTRICCHARGE * level, "wx78module2hm")
            end
        end
    end
end)

local healths = {"maxhealth", "maxhealth2"}
local function newhealthactivate(inst, wx, ...)
    local health
    if wx and wx.components.health then health = wx.components.health.currenthealth end
    inst.oldonactivatedfn2hm(inst, wx, ...)
    if health then wx.components.health:SetCurrentHealth(health) end
end
local function newhealthdeactivatedfn(inst, wx, ...)
    local health
    if wx and wx.components.health then health = wx.components.health.currenthealth end
    inst.oldondeactivatedfn2hm(inst, wx, ...)
    if health then wx.components.health:SetCurrentHealth(health) end
end
for index, name in ipairs(healths) do
    AddPrefabPostInit("wx78module_" .. name, function(inst)
        if not TheWorld.ismastersim then return end
        inst.nohunger2hm = true
        if inst.components.upgrademodule then
            inst.oldonactivatedfn2hm = inst.components.upgrademodule.onactivatedfn
            inst.components.upgrademodule.onactivatedfn = newhealthactivate
            inst.oldondeactivatedfn2hm = inst.components.upgrademodule.ondeactivatedfn
            inst.components.upgrademodule.ondeactivatedfn = newhealthdeactivatedfn
        end
    end)
end
local hungers = {"maxhunger", "maxhunger1"}
TUNING.WX78_MAXHUNGER1_BOOST = TUNING.WX78_MAXHUNGER1_BOOST * 1.25
TUNING.WX78_MAXHUNGER_BOOST = TUNING.WX78_MAXHUNGER_BOOST * 1.5
TUNING.WX78_MAXHUNGER_SLOWPERCENT = 1
local function newhungeractivate(inst, wx, ...)
    local hunger
    if wx and wx.components.hunger then hunger = wx.components.hunger.current end
    if wx then wx._hunger_chips = wx._hunger_chips2hm or wx._hunger_chips or 0 end
    inst.oldonactivatedfn2hm(inst, wx, ...)
    if hunger then
        wx.components.hunger.current = hunger
        wx.components.hunger.burnratemodifiers:RemoveModifier(inst)
    end
    if wx and wx._hunger_chips then
        wx._hunger_chips2hm = wx._hunger_chips
        wx._hunger_chips = math.floor(wx._hunger_chips * 3 / 4)
    end
end
local function newhungerdeactivatedfn(inst, wx, ...)
    local hunger
    if wx and wx.components.hunger then hunger = wx.components.hunger.current end
    if wx then wx._hunger_chips = wx._hunger_chips2hm or wx._hunger_chips or 0 end
    inst.oldondeactivatedfn2hm(inst, wx, ...)
    if hunger then wx.components.hunger.current = hunger end
    if wx and wx._hunger_chips then
        wx._hunger_chips2hm = wx._hunger_chips
        wx._hunger_chips = math.floor(wx._hunger_chips * 3 / 4)
    end
end
for index, name in ipairs(hungers) do
    AddPrefabPostInit("wx78module_" .. name, function(inst)
        if not TheWorld.ismastersim then return end
        inst.nohunger2hm = true
        if inst.components.upgrademodule then
            inst.oldonactivatedfn2hm = inst.components.upgrademodule.onactivatedfn
            inst.components.upgrademodule.onactivatedfn = newhungeractivate
            inst.oldondeactivatedfn2hm = inst.components.upgrademodule.ondeactivatedfn
            inst.components.upgrademodule.ondeactivatedfn = newhungerdeactivatedfn
        end
    end)
end
local sanitys = {"maxsanity", "maxsanity1", "bee"}

--2025.11.4夜风修复困难模式拔插芯片刷新理智状态bug
local function newsanityactivate(inst, wx, ...)
    local sanity
    if wx and wx.components.sanity then sanity = wx.components.sanity.current end
    inst.oldonactivatedfn2hm(inst, wx, ...)
    if sanity then 
        wx.components.sanity.current = math.min(sanity, wx.components.sanity.max)
    end
end
local function newsanitydeactivatedfn(inst, wx, ...)
    local sanity
    if wx and wx.components.sanity then sanity = wx.components.sanity.current end
    inst.oldondeactivatedfn2hm(inst, wx, ...)
    if sanity then 
        wx.components.sanity.current = math.min(sanity, wx.components.sanity.max)
    end
end
for index, name in ipairs(sanitys) do
    AddPrefabPostInit("wx78module_" .. name, function(inst)
        if not TheWorld.ismastersim then return end
        inst.nohunger2hm = true
        --2025.11.4夜风修复困难模式拔插芯片刷新理智状态bug
        if inst.components.upgrademodule then
            inst.oldonactivatedfn2hm = inst.components.upgrademodule.onactivatedfn
            inst.components.upgrademodule.onactivatedfn = newsanityactivate
            inst.oldondeactivatedfn2hm = inst.components.upgrademodule.ondeactivatedfn
            inst.components.upgrademodule.ondeactivatedfn = newsanitydeactivatedfn
        end
        --
    end)
end

-- 妥协加速芯片
if TUNING.DSTU and TUNING.DSTU.WXLESS then
    local return5fn = function() return 5 end
    local function newmovespeedactivate(inst, wx, ...)
        inst.oldonactivatedfn2hm(inst, wx, ...)
        if inst.accelarate ~= nil and not inst.accelarate2hm then
            inst.accelarate2hm = true
            local accelarate = inst.accelarate
            wx:RemoveEventCallback("locomote", accelarate, wx)
            inst.accelarate = function(wx, _, ...)
                local movetime = wx.components.locomotor:GetTimeMoving()
                local speed = math.clamp(TUNING.WILSON_RUN_SPEED + movetime, TUNING.WILSON_RUN_SPEED,
                                         12 - TUNING.WX78_MOVESPEED_CHIPBOOSTS[wx._movespeed_chips + 1])
                if wx.speedloosetask == nil then
                    wx.accelarate_speed = speed
                    wx.components.locomotor.runspeed = speed
                end
                local GetTimeMoving = wx.components.locomotor.GetTimeMoving
                wx.components.locomotor.GetTimeMoving = return5fn
                accelarate(wx, inst, ...)
                wx.components.locomotor.GetTimeMoving = GetTimeMoving
                if wx.speedloosetask == nil then
                    if not inst.accelarateListen2hm then
                        inst.accelarateListen2hm = true
                        inst:ListenForEvent("newstate", inst.accelarate, wx)
                    end
                    wx.accelarate_speed = speed
                    wx.components.locomotor.runspeed = speed
                else
                    if inst.accelarateListen2hm then
                        inst.accelarateListen2hm = nil
                        inst:RemoveEventCallback("newstate", inst.accelarate, wx)
                    end
                    wx.accelarate_speed = TUNING.WILSON_RUN_SPEED
                    wx.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED
                end
            end
            inst:ListenForEvent("locomote", inst.accelarate, wx)
        end
    end
    local function newmovespeeddeactivatedfn(inst, wx, ...)
        inst.accelarateListen2hm = nil
        inst:RemoveEventCallback("locomote", inst.accelarate, wx)
        inst:RemoveEventCallback("newstate", inst.accelarate, wx)
        inst.oldondeactivatedfn2hm(inst, wx, ...)
        if inst.accelarate == nil and inst.accelarate2hm then
            inst.accelarate2hm = nil
            wx.accelaratecd2hm = nil
        end
    end
    local movespeeds = {"movespeed", "movespeed2"}
    for index, name in ipairs(movespeeds) do
        AddPrefabPostInit("wx78module_" .. name, function(inst)
            if not TheWorld.ismastersim then return end
            if inst.components.upgrademodule then
                inst.oldonactivatedfn2hm = inst.components.upgrademodule.onactivatedfn
                inst.components.upgrademodule.onactivatedfn = newmovespeedactivate
                inst.oldondeactivatedfn2hm = inst.components.upgrademodule.ondeactivatedfn
                inst.components.upgrademodule.ondeactivatedfn = newmovespeeddeactivatedfn
            end
        end)
    end
    local function newtaseractivate(inst, wx, ...)
        inst.oldonactivatedfn2hm(inst, wx, ...)
        if inst._onblocked ~= nil and not inst._onblocked2hm then
            inst._onblocked2hm = true
            local _onblocked = inst._onblocked
            inst:RemoveEventCallback("blocked", inst._onblocked, wx)
            inst:RemoveEventCallback("attacked", inst._onblocked, wx)
            inst._onblocked = function(wx, data, ...)
                if inst._cdtask == nil then
                    _onblocked(wx, data, ...)
                    if inst._cdtask then inst._cdtask.period = 6 end
                end
            end
            inst:ListenForEvent("blocked", inst._onblocked, wx)
            inst:ListenForEvent("attacked", inst._onblocked, wx)
        end
    end
    local function newtaserdeactivatedfn(inst, wx, ...)
        inst.oldondeactivatedfn2hm(inst, wx, ...)
        if inst._onblocked == nil and inst._onblocked2hm then inst._onblocked2hm = nil end
    end
    AddPrefabPostInit("wx78module_taser", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.upgrademodule then
            inst.oldonactivatedfn2hm = inst.components.upgrademodule.onactivatedfn
            inst.components.upgrademodule.onactivatedfn = newtaseractivate
            inst.oldondeactivatedfn2hm = inst.components.upgrademodule.ondeactivatedfn
            inst.components.upgrademodule.ondeactivatedfn = newtaserdeactivatedfn
        end
    end)
end

--2025.11.9夜风 添加额外的扫描生物解锁电路逻辑
if GetModConfigData("WX-78 Safe Remove Module") then
    local wx78_moduledefs = require("wx78_moduledefs")
    
    -- 扫描牛解锁超级强化电路
    wx78_moduledefs.AddCreatureScanDataDefinition("beefalo", "maxhealth2", 6)
    
    -- 扫描月熠解锁照明电路
    wx78_moduledefs.AddCreatureScanDataDefinition("hutch", "light", 4)

end

-- 修改强化芯片电路（maxhealth）配方
AddRecipePostInit("wx78module_maxhealth", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：4个生物数据 + 2个治疗药膏
    recipe.ingredients = {
        Ingredient("scandata", 4),
        Ingredient("healingsalve", 2),
    }
end)
-- 修改超级强化芯片电路（maxhealth2）配方
AddRecipePostInit("wx78module_maxhealth2", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：4个生物数据 + 1个强化电路
    recipe.ingredients = {
        Ingredient("scandata", 4),
        Ingredient("wx78module_maxhealth", 1),
    }
end)
-- 修改处理器芯片电路（maxsanitY1）配方
AddRecipePostInit("wx78module_maxsanity1", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：2个生物数据 + 2个蝴蝶+6个绿蘑菇
    recipe.ingredients = {
        Ingredient("scandata", 2),
        Ingredient("butterfly", 2),
        Ingredient("green_cap", 6),
    }
end)
-- 修改超级处理器芯片电路（maxsanitY）配方
AddRecipePostInit("wx78module_maxsanity", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：4个生物数据 + 1个噩梦燃料+1个处理器芯片
    recipe.ingredients = {
        Ingredient("scandata", 4),
        Ingredient("nightmarefuel", 1),
        Ingredient("wx78module_maxsanitY1", 1),
    }
end)
-- 修改加速芯片电路（movespeed）配方
AddRecipePostInit("wx78module_movespeed", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：4个生物数据 + 1个兔子
    recipe.ingredients = {
        Ingredient("scandata", 4),
        Ingredient("rabbit", 1),
    }
end)
-- 修改超级加速芯片电路（movespeed2）配方
AddRecipePostInit("wx78module_movespeed2", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：4个生物数据 + 2个治疗药膏
    recipe.ingredients = {
        Ingredient("scandata", 8),
        Ingredient("gears", 2),
        Ingredient("wx78module_movespeed", 2),
    }
end)
-- 修改热能芯片电路（heat）配方
AddRecipePostInit("wx78module_heat", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：8个生物数据 + 2个重生护符+1个紫宝石
    recipe.ingredients = {
        Ingredient("scandata", 8),
        Ingredient("amulet", 2),
        Ingredient("purplegem", 1),
    }
end)
-- 修改制冷电路芯片电路（cold）配方
AddRecipePostInit("wx78module_cold", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：8个生物数据 + 2个寒冰护符+1个紫宝石
    recipe.ingredients = {
        Ingredient("scandata", 8),
        Ingredient("blueamulet", 2),
        Ingredient("purplegem", 2),
    }
end)
-- 修改电气化芯片电路（taser）配方
AddRecipePostInit("wx78module_taser", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：10个生物数据 + 2个羊奶+1羊角
    recipe.ingredients = {
        Ingredient("scandata", 10),
        Ingredient("goatmilk", 2),
        Ingredient("lightninggoathorn", 1),
    }
end)
-- 修改光电芯片电路（nightvision）配方
AddRecipePostInit("wx78module_nightvision", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：4个生物数据 + 1个鼹鼠 + 2个大发光浆果 + 2个照明电路
    recipe.ingredients = {
        Ingredient("scandata", 4),
        Ingredient("mole", 1),
        Ingredient("wormlight", 2),
        Ingredient("wx78module_light", 2),
    }
end)
-- 修改照明芯片电路（light）配方
AddRecipePostInit("wx78module_light", function(recipe)
    -- 清空原有材料
    recipe.ingredients = {}
    -- 添加新材料：6个生物数据 + 2个荧光果 + 2个萤火虫
    recipe.ingredients = {
        Ingredient("scandata", 6),
        Ingredient("lightbulb", 2),
        Ingredient("fireflies", 2),
    }
end)

--2025.11.9夜风 豆增压电路（bee模块）添加超载状态功能
-- 检查WX-78是否装备了bee模块
local function HasBeeModule(wx)
    if wx and wx.components.upgrademoduleowner then
        for _, module in ipairs(wx.components.upgrademoduleowner.modules) do
            if module and module.prefab == "wx78module_bee" and module.components.upgrademodule and module.components.upgrademodule.activated then
                return true
            end
        end
    end
    return false
end

-- 超载状态效果更新（逐渐减弱）
local function UpdateOverloadEffects(wx)
    if not wx.overload_time2hm or wx.overload_time2hm <= 0 then
        -- 超载结束，清除所有效果
        if wx.overload_task2hm then
            wx.overload_task2hm:Cancel()
            wx.overload_task2hm = nil
        end
        if wx.overload_light2hm then
            wx.overload_light2hm:Enable(false)
        end
        if wx.components.locomotor then
            wx.components.locomotor:RemoveExternalSpeedMultiplier(wx, "wx78_overload2hm")
        end
        if wx.components.temperature then
            wx.components.temperature:RemoveModifier("wx78_overload2hm")
        end
        wx.overload_time2hm = nil
        wx:RemoveTag("wx78_overloaded2hm")
        return
    end
    
    -- 计算衰减系数（从1到0）
    local decay = wx.overload_time2hm / TUNING.TOTAL_DAY_TIME
    
    -- 更新移动速度（从35%逐渐降到0）
    if wx.components.locomotor then
        wx.components.locomotor:SetExternalSpeedMultiplier(wx, "wx78_overload2hm", 1 + 0.35 * decay)
    end
    
    -- 更新光照强度（从4格逐渐降到0）
    if wx.overload_light2hm then
        wx.overload_light2hm:SetRadius(4 * decay)
        wx.overload_light2hm:SetIntensity(0.8 * decay)
    end
    
    wx.overload_time2hm = wx.overload_time2hm - 1
end

-- 进入超载状态
local function EnterOverloadState(wx)
    if not HasBeeModule(wx) then 
        return 
    end
    
    -- 添加超载标签
    wx:AddTag("wx78_overloaded2hm")
    
    -- 设置超载时长（约1天）
    wx.overload_time2hm = TUNING.TOTAL_DAY_TIME
    
    -- 恢复60点生命，损失33点理智
    if wx.components.health and not wx.components.health:IsDead() then
        wx.components.health:DoDelta(60)
    end
    if wx.components.sanity then
        wx.components.sanity:DoDelta(-33)
    end
    
    -- 添加光照组件
    if not wx.overload_light2hm then
        if not wx.Light then
            wx.entity:AddLight()
        end
        wx.overload_light2hm = wx.Light or wx.entity:AddLight()
        wx.overload_light2hm:SetFalloff(0.5)
        wx.overload_light2hm:SetColour(180/255, 195/255, 225/255)
    end
    wx.overload_light2hm:Enable(true)
    wx.overload_light2hm:SetRadius(4)
    wx.overload_light2hm:SetIntensity(0.8)
    
    -- 免疫寒冷（增加温度抗性）
    if wx.components.temperature then
        wx.components.temperature:SetModifier("wx78_overload2hm", 30)
    end
    
    -- 设置移动速度加成（初始35%，随时间衰减）
    if wx.components.locomotor then
        wx.components.locomotor:SetExternalSpeedMultiplier(wx, "wx78_overload2hm", 1.35)
    end
    
    -- 启动更新任务（每秒更新一次）
    if wx.overload_task2hm then
        wx.overload_task2hm:Cancel()
    end
    wx.overload_task2hm = wx:DoPeriodicTask(1, UpdateOverloadEffects)
    
    -- 播放特效
    local fx = SpawnPrefab("electrichitsparks")
    if fx then
        fx.entity:SetParent(wx.entity)
    end
end

-- WX-78被闪电击中时触发超载
AddPrefabPostInit("wx78", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 延迟初始化，确保所有组件都加载完成
    inst:DoTaskInTime(0, function(inst)
        -- Hook playerlightningtarget 组件的 DoStrike 方法
        if inst.components.playerlightningtarget then
            local old_DoStrike = inst.components.playerlightningtarget.DoStrike
            inst.components.playerlightningtarget.DoStrike = function(self, ...)
                local result = old_DoStrike(self, ...)
                -- 在原版闪电处理后，检查是否装备bee模块并触发超载
                if HasBeeModule(inst) then
                    EnterOverloadState(inst)
                end
                return result
            end
        end
        
        -- 同时监听闪电击中事件（作为备用）
        inst:ListenForEvent("lightningstrike", function(wx, data)
            if HasBeeModule(wx) then
                EnterOverloadState(wx)
            end
        end)
    end)
    
    -- 保存时清理任务
    local old_OnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        if old_OnSave then old_OnSave(inst, data) end
        if inst.overload_time2hm and inst.overload_time2hm > 0 then
            data.overload_time2hm = inst.overload_time2hm
        end
    end
    
    -- 加载时恢复状态
    local old_OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_OnLoad then old_OnLoad(inst, data) end
        if data and data.overload_time2hm then
            inst.overload_time2hm = data.overload_time2hm
            EnterOverloadState(inst)
        end
    end
end)


-- ACTIONS.REMOVEMODULES.fn = function(act)
--     if
--         (act.invobject ~= nil and act.invobject.components.upgrademoduleremover ~= nil) and
--             (act.doer ~= nil and act.doer.components.upgrademoduleowner ~= nil)
--      then
--         if act.doer.components.upgrademoduleowner:NumModules() > 0 then
--             local energy_cost = act.doer.components.upgrademoduleowner:PopOneModule()
--             if energy_cost ~= 0 then
--                 if not act.doer._modremovetask then
--                     act.doer._modremovetask =
--                         act.doer:DoTaskInTime(
--                         30,
--                         function()
--                             act.doer._modremovetask = nil
--                         end
--                     )
--                 else
--                     act.doer.components.upgrademoduleowner:AddCharge(-1)
--                     act.doer._modremovetask:Cancel()
--                     act.doer._modremovetask = nil
--                     act.doer._modremovetask =
--                         act.doer:DoTaskInTime(
--                         30,
--                         function()
--                             act.doer._modremovetask = nil
--                         end
--                     )
--                 end
--             end

--             return true
--         else
--             return false, "NO_MODULES"
--         end
--     end

--     return false
-- end

