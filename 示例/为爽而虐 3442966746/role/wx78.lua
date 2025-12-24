-- =====================================================================================
-- 所有电路都会增加饥饿消耗，每个插槽每分钟消耗0.5饱食度
AddComponentPostInit("upgrademoduleowner", function(self)
    local old = self.UpdateActivatedModules
    self.UpdateActivatedModules = function(self, ...)
        old(self, ...)
        if self.inst.components.hunger then
            -- 计算所有已激活电路的总插槽数
            local total_slots = 0
            local taser_slots = 0  -- 单独统计电气化电路的插槽数
            local is_integrated_mode = GetModConfigData("WX-78 Integrated Upgrade Module Level")
            
            for _, module in ipairs(self.modules) do
                if module and module.components.upgrademodule.activated and module.level2hm then
                    local slots = module.components.upgrademodule.slots
                    local level = module.level2hm:value()
                    
                    -- 豆增压电路在简单模式下插槽计数翻倍
                    if is_integrated_mode and module.prefab == "wx78module_bee" then
                        total_slots = total_slots + slots * level * 2
                    else
                        total_slots = total_slots + slots * level
                    end
                    
                    -- 记录电气化电路的插槽数（用于过载状态加倍）
                    if module.prefab == "wx78module_taser" then
                        taser_slots = taser_slots + slots * level
                    end
                end
            end
            
            -- 如果处于过载状态，电气化电路插槽数翻倍
            if self.inst:HasDebuff("wx78_overload_buff2hm") and taser_slots > 0 then
                total_slots = total_slots + taser_slots  -- 再加一倍电气化电路的槽位
            end
            
            if total_slots == 0 then
                self.inst.components.hunger.burnratemodifiers:RemoveModifier(self.inst, "wx78module2hm")
            else
                -- 每个插槽每分钟消耗0.5饱食度
                -- 原版角色每天（8分钟）消耗75饱食度，即每分钟消耗9.375饱食度
                -- 额外消耗倍率 = (基础消耗 + 额外消耗) / 基础消耗
                -- = (9.375 + total_slots * 0.5) / 9.375
                -- = 1 + total_slots * 0.5 / 9.375
                local hunger_multiplier = 1 + total_slots / 18.75
                self.inst.components.hunger.burnratemodifiers:SetModifier(self.inst, hunger_multiplier, "wx78module2hm")
            end
        end
        -- 兼容妥协开启时计算总插槽数，但不直接设置_chip_inuse
        -- _chip_inuse会在耗电时动态设置，避免影响插槽上限验证
        if TUNING.DSTU and TUNING.DSTU.WXLESS and self.inst._chip_inuse ~= nil then
            -- 计算实际生效的插槽数（包括升级电路）
            local actual_slots = 0
            for _, module in ipairs(self.modules) do
                if module and module.components.upgrademodule.activated and module.level2hm then
                    local slots = module.components.upgrademodule.slots
                    local level = module.level2hm:value()
                    actual_slots = actual_slots + slots * level
                end
            end
            
            -- 只保存真实插槽数
            self.inst._actual_slots2hm = math.min(actual_slots, 20)
        end
    end
end)

-- ======================================================================================
-- 血量、饥饿、理智电路保留数值而非百分比；移除饥饿电路减少饥饿消耗的效果
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
    if hunger then 
        wx.components.hunger.current = hunger
        
        -- 检查饱食度是否溢出新的上限，溢出部分转化为理智惩罚
        local new_max = wx.components.hunger.max
        local overflow = hunger - new_max
        if overflow > 0 then
            wx.components.hunger.current = new_max
            
            if wx.components.sanity then
                wx.components.sanity:DoDelta(overflow * (wx.components.sanity:IsLunacyMode() and 0.5 or -0.5))
            end
        end
    end
    if wx and wx._hunger_chips then
        wx._hunger_chips2hm = wx._hunger_chips
        wx._hunger_chips = math.floor(wx._hunger_chips * 3 / 4)
    end
end
for index, name in ipairs(hungers) do
    AddPrefabPostInit("wx78module_" .. name, function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.upgrademodule then
            inst.oldonactivatedfn2hm = inst.components.upgrademodule.onactivatedfn
            inst.components.upgrademodule.onactivatedfn = newhungeractivate
            inst.oldondeactivatedfn2hm = inst.components.upgrademodule.ondeactivatedfn
            inst.components.upgrademodule.ondeactivatedfn = newhungerdeactivatedfn
        end
    end)
end
local sanitys = {"maxsanity", "maxsanity1", "bee"}
local function newsanityactivate(inst, wx, ...)
    local sanity
    if wx and wx.components.sanity then sanity = wx.components.sanity.current end
    inst.oldonactivatedfn2hm(inst, wx, ...)
    if sanity then wx.components.sanity:SetPercent(sanity / wx.components.sanity.max) end
end
local function newsanitydeactivatedfn(inst, wx, ...)
    local sanity
    if wx and wx.components.sanity then sanity = wx.components.sanity.current end
    inst.oldondeactivatedfn2hm(inst, wx, ...)
    if sanity then wx.components.sanity:SetPercent(sanity / wx.components.sanity.max) end
end
for index, name in ipairs(sanitys) do
    AddPrefabPostInit("wx78module_" .. name, function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.upgrademodule then
            inst.oldonactivatedfn2hm = inst.components.upgrademodule.onactivatedfn
            inst.components.upgrademodule.onactivatedfn = newsanityactivate
            inst.oldondeactivatedfn2hm = inst.components.upgrademodule.ondeactivatedfn
            inst.components.upgrademodule.ondeactivatedfn = newsanitydeactivatedfn
        end
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

-- 妥协模组兼容：过载时不耗电，超过8插槽时自定义耗电速度
if TUNING.DSTU and TUNING.DSTU.WXLESS then
    -- 扩展妥协模组的耗电时间表，支持9-20插槽
    -- 原版：CHARGE_DEGENTIME = { 300, 270, 240, 210, 180, 150, 120, 90 }
    -- 每3个槽加速10秒，上限20槽50秒
    if CHARGE_DEGENTIME then
        CHARGE_DEGENTIME[9] = 80
        CHARGE_DEGENTIME[10] = 80
        CHARGE_DEGENTIME[11] = 80
        CHARGE_DEGENTIME[12] = 70
        CHARGE_DEGENTIME[13] = 70
        CHARGE_DEGENTIME[14] = 70
        CHARGE_DEGENTIME[15] = 60
        CHARGE_DEGENTIME[16] = 60
        CHARGE_DEGENTIME[17] = 60
        CHARGE_DEGENTIME[18] = 50
        CHARGE_DEGENTIME[19] = 50
        CHARGE_DEGENTIME[20] = 50
    end
    
    AddPrefabPostInit("wx78", function(inst)
        if not TheWorld.ismastersim then return inst end
        
        -- 过载时不耗电
        if inst.components.upgrademoduleowner then
            local old_addcharge = inst.components.upgrademoduleowner.AddCharge
            inst.components.upgrademoduleowner.AddCharge = function(self, amount, ...)
                -- 过载时阻止耗电
                if inst._overload_no_drain2hm and amount < 0 then
                    return
                end
                return old_addcharge(self, amount, ...)
            end
        end
        
        -- 兼容UM：在UM的耗电计算时临时使用真实插槽数
        inst:DoTaskInTime(0, function()
            -- Hook UM的_onpusheddegen（OnUpgradeModuleChargeChanged）
            if inst._onpusheddegen then
                local old_onpusheddegen = inst._onpusheddegen
                inst._onpusheddegen = function(inst_inner, ...)
                    -- 在UM计算耗电时临时替换 _chip_inuse 为真实插槽数
                    if inst_inner._actual_slots2hm then
                        local saved_chip_inuse = inst_inner._chip_inuse
                        inst_inner._chip_inuse = inst_inner._actual_slots2hm
                        
                        old_onpusheddegen(inst_inner, ...)
                        
                        inst_inner._chip_inuse = saved_chip_inuse
                    else
                        old_onpusheddegen(inst_inner, ...)
                    end
                end
                
                inst:RemoveEventCallback("upgrademodulesdirty", old_onpusheddegen)
                inst:ListenForEvent("upgrademodulesdirty", inst._onpusheddegen)
            end

            if inst.components.timer and TUNING.DSTU and TUNING.DSTU.WXLESS then
                local old_StartTimer = inst.components.timer.StartTimer
                inst.components.timer.StartTimer = function(self, name, time, ...)
                    -- 临时使用真实插槽数
                    if name == "chargedegenupdate" and inst._actual_slots2hm then
                        local saved_chip_inuse = inst._chip_inuse
                        inst._chip_inuse = inst._actual_slots2hm
                        local result = old_StartTimer(self, name, time, ...)
                        inst._chip_inuse = saved_chip_inuse
                        return result
                    end
                    return old_StartTimer(self, name, time, ...)
                end
            end
        end)
    end)
end

-- 齿轮三维回复削弱
AddPrefabPostInit("gears", function(inst)
    if not TheWorld.ismastersim then return inst end
    if inst.components.edible then
        inst.components.edible.healthvalue = TUNING.HEALING_LARGE       -- 60→40
        inst.components.edible.hungervalue = TUNING.CALORIES_LARGE      -- 75→37.5
        inst.components.edible.sanityvalue = TUNING.SANITY_LARGE        -- 50→33
    end
end)