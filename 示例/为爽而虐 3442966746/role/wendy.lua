local wendy = require("prefabs/wendy")

-- 技能树文本改动
local SkillTreeDefs = require("prefabs/skilltree_defs")
if SkillTreeDefs.SKILLTREE_DEFS["wendy"] ~= nil then
    SkillTreeDefs.SKILLTREE_DEFS["wendy"].wendy_avenging_ghost.desc = STRINGS.SKILLTREE.WENDY.WENDY_AVENGING_GHOST_DESC ..
        (TUNING.isCh2hm and "\ncd为3天。" or
        "\ncd is 3 days.")
end

-- 阿比盖尔的护盾不再是无敌的
TUNING.ABIGAIL_FORCEFIELD_ABSORPTION = 0.9

-- 不屈药剂和蒸馏复仇提供额外10%的护盾防御


-- 阿比盖尔成长速度更慢
TUNING.ABIGAIL_BOND_LEVELUP_TIME = TUNING.ABIGAIL_BOND_LEVELUP_TIME * 2

-- 阿比盖尔现在有温度，且会热得掉血
local maxoverheattemp = TUNING.OVERHEAT_TEMP * 5 / 7
local newmaxoverheattemp = TUNING.OVERHEAT_TEMP
local function processtempcolour(inst, force)
    local self = inst.components.temperature
    if not inst:HasTag("swc2hm") and self then
        local gbhundred = self.current > 0 and
                              math.ceil((self.current > self.overheattemp and 75 or (self.overheattemp - self.current) / self.overheattemp * 25 + 75)) or 100
        if inst:IsInLimbo() then gbhundred = math.max(76, gbhundred) end
        if not self.lastFrames2hm then self.lastFrames2hm = GetTime() - FRAMES end
        if force then
            local gb = gbhundred / 100
            inst.AnimState:SetMultColour(1, gb, gb, 1)
        elseif GetTime() - FRAMES > self.lastFrames2hm then
            self.lastFrames2hm = GetTime()
            local r, g, b, alpha = inst.AnimState:GetMultColour()
            local oldgbhundred = math.ceil((g + b) * 50)
            if oldgbhundred == gbhundred then return end
            gbhundred = gbhundred > oldgbhundred and (oldgbhundred + 1) or (oldgbhundred - 1)
            local gb = oldgbhundred / 100
            inst.AnimState:SetMultColour(1, gb, gb, 1)
        end
        if inst._playerlink and inst._playerlink:IsValid() and inst._playerlink.abigailgbhundred2hm then
            inst._playerlink.abigailgbhundred2hm:set(gbhundred)
        end
    end
end
local function updatetemperature(inst)
    if inst.components.temperature and inst.components.temperature.current > -20 then
        inst.components.temperature:SetTemperature(inst.components.temperature.current - 1)
    elseif inst.temptask2hm then
        inst.temptask2hm:Cancel()
        inst.temptask2hm = nil
    end
end
local function onstartoverheating(inst)
    if inst._playerlink and inst._playerlink:IsValid() and inst._playerlink.components.talker then
        inst._playerlink.components.talker:Say(GetString(inst._playerlink, "ANNOUNCE_ABIGAIL_LOW_HEALTH"))
    end
    if not inst:IsInLimbo() and not inst.hottrailfx2hm then
        inst.hottrailfx2hm = SpawnPrefab("hotcold_fx")
        inst.hottrailfx2hm.entity:SetParent(inst.entity)
        inst.hottrailfx2hm.AnimState:SetScale(0.7, 0.7)
        inst.hottrailfx2hm.entity:AddFollower():FollowSymbol(inst.GUID, "ghost_eyes", 10, -140, 0)
        -- inst.hottrailfx2hm.AnimState:SetDeltaTimeMultiplier(0.75)
    end
end
local function onstopoverheating(inst)
    if inst.hottrailfx2hm then
        inst.hottrailfx2hm:Remove()
        inst.hottrailfx2hm = nil
    end
end
local function onenterlimbo(inst)
    if inst.components.temperature then
        inst:StopUpdatingComponent(inst.components.temperature)
        if not inst.temptask2hm then inst.temptask2hm = inst:DoPeriodicTask(1, updatetemperature) end
        processtempcolour(inst, true)
    end
    if inst.hottrailfx2hm then
        inst.hottrailfx2hm:Remove()
        inst.hottrailfx2hm = nil
    end
    --阿比盖尔被收回或死亡时无法获得经验
    if not inst:HasTag("swc2hm") and inst._playerlink ~= nil and inst._playerlink:IsValid() and inst._playerlink.components.ghostlybond then
        inst._playerlink.components.ghostlybond:SetBondTimeMultiplier("abigail2hm", 0)
    end
end
local function onexitlimbo(inst)
    if inst.temptask2hm then
        inst.temptask2hm:Cancel()
        inst.temptask2hm = nil
    end
    if inst.components.temperature then
        inst:StartUpdatingComponent(inst.components.temperature)
        processtempcolour(inst, true)
        if inst.components.temperature.current > inst.components.temperature.overheattemp then onstartoverheating(inst) end
    end
    if not inst:HasTag("swc2hm") and inst._playerlink ~= nil and inst._playerlink:IsValid() and inst._playerlink.components.ghostlybond then
        inst._playerlink.components.ghostlybond:SetBondTimeMultiplier("abigail2hm")
    end
end
local function checkoverheating(inst)
    if inst.components.temperature and not inst:IsInLimbo() then
        processtempcolour(inst, true)
        if inst.components.temperature.current > inst.components.temperature.overheattemp then onstartoverheating(inst) end
    end
end
local function ontemperaturedelta(inst, data)
    if data and data.new and data.last then
        if data.new > 0 and data.last <= 0 then
            inst.components.health:StopRegen()
        elseif data.new <= 0 and data.last > 0 then
            inst.components.health:StartRegen(1, 10)
        end
    end
    processtempcolour(inst, true)
end
local function ondeath(inst) if inst.components.temperature then inst.components.temperature:SetTemperature(-20) end end
local function abigailHeatFn(inst, observer)
    return (observer == nil or observer.prefab ~= "wendy" or TheWorld.state.issummer) and
               (TheWorld.state.issummer and math.min(inst.components.temperature.current, TheWorld.state.temperature, 50) or
                   (inst.components.temperature.current - 40) / 3) or nil
end
AddPrefabPostInit("abigail", function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.health:StartRegen(1, 10)
    if not inst.components.temperature then
        inst:AddComponent("temperature")
        inst.components.temperature.current = -20
        inst.components.temperature.mintemp = -20
        inst.components.temperature.coldtemp2hm = -30
        inst.components.temperature.overheattemp = maxoverheattemp
        inst.components.temperature.inherentinsulation = TUNING.INSULATION_TINY
        inst.components.temperature.inherentsummerinsulation = -TUNING.INSULATION_TINY
        inst.components.temperature:IgnoreTags("ghost")
        inst.components.temperature:IgnoreTags("abigail_flower")
        inst.components.temperature:SetFreezingHurtRate(0)
        inst.components.temperature:SetOverheatHurtRate(1)
        inst:ListenForEvent("temperaturedelta", ontemperaturedelta)
        inst:ListenForEvent("enterlimbo", onenterlimbo)
        inst:ListenForEvent("exitlimbo", onexitlimbo)
        inst:ListenForEvent("startoverheating", onstartoverheating)
        inst:ListenForEvent("stopoverheating", onstopoverheating)
        inst:ListenForEvent("death", ondeath)
        inst:DoTaskInTime(0, checkoverheating)
    end
    if not inst.components.heater then
        inst:AddComponent("heater")
        inst.components.heater.heatfn = abigailHeatFn
        inst.components.heater:SetThermics(false, true)
    end
end)
-- 状态栏的掉血动画不会修，先移除了
-- local function abigailbadge2hmdirty(inst)
--     if inst.abigailgbhundred2hm and inst == ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls 
--                                 and ThePlayer.HUD.controls and ThePlayer.HUD.controls.status and
--         ThePlayer.HUD.controls.status.pethealthbadge then
--         local badge = ThePlayer.HUD.controls.status.pethealthbadge
--         local gbhundred = inst.abigailgbhundred2hm:value()
--         local gb = gbhundred / 100
--         if badge.circleframe and badge.circleframe:GetAnimState() then badge.circleframe:GetAnimState():SetMultColour(1, gb, gb, gb) end
--         local arrowdir2hm = gbhundred <= 75 and -1 or 0
--         if not badge.arrowdir2hm then
--             badge.arrowdir2hm = arrowdir2hm
--             local SetValues = badge.SetValues
--             badge.SetValues = function(self, symbol, percent, arrowdir, ...) SetValues(self, symbol, percent, arrowdir + self.arrowdir2hm, ...) end
--             ThePlayer.HUD.controls.status:RefreshPetHealth()
--         elseif badge.arrowdir2hm ~= arrowdir2hm then
--             badge.arrowdir2hm = arrowdir2hm
--             ThePlayer.HUD.controls.status:RefreshPetHealth()
--         end
--     end
-- end  
local function abigailbadge2hmdirty(inst)
    if inst.abigailgbhundred2hm and inst == ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls 
                            and ThePlayer.HUD.controls.status and
        ThePlayer.HUD.controls.status.pethealthbadge then
        local badge = ThePlayer.HUD.controls.status.pethealthbadge
        local gbhundred = inst.abigailgbhundred2hm:value()
        local gb = gbhundred / 100
        
        -- 仅修改颜色，不改变其他逻辑
        if badge.circleframe and badge.circleframe:GetAnimState() then 
            badge.circleframe:GetAnimState():SetMultColour(1, gb, gb, gb) 
        end
        
        -- 移除箭头方向修改部分，避免动画冲突
    end
end
AddPrefabPostInit("wendy", function(inst)
    inst.abigailgbhundred2hm = net_byte(inst.GUID, "abigail.gbhundred2hm", "abigailbadge2hmdirty")
    inst.abigailgbhundred2hm:set(100)
    if not TheWorld.ismastersim then inst:ListenForEvent("abigailbadge2hmdirty", abigailbadge2hmdirty) end
end)

-- 阿比盖尔之花也能传达部分姐姐的温度
local function abigailflowerHeatFn(inst)
    if TheWorld.state.issummer and inst.components.inventoryitem and inst.components.inventoryitem.owner then
        local owner = inst.components.inventoryitem.owner
        if owner:IsValid() and owner:HasTag("player") and owner.prefab == "wendy" and owner.components.temperature then
            local ghost = owner.components.ghostlybond and owner.components.ghostlybond.ghost
            if ghost and ghost:IsValid() and ghost:IsInLimbo() and ghost.components.heater then
                if not ghost.flower2hm then
                    ghost.flower2hm = inst
                elseif ghost.flower2hm ~= inst and ghost.flower2hm:IsValid() then
                    if ghost.flower2hm.components.inventoryitem.owner == owner then return end
                    ghost.flower2hm = inst
                end
                return math.min(TheWorld.state.temperature, 65)
            end
        end
    end
end
AddPrefabPostInit("abigail_flower", function(inst)
    if not TheWorld.ismastersim then return end
    if not inst.components.heater then
        inst:AddComponent("heater")
        inst.components.heater.carriedheatfn = abigailflowerHeatFn
        inst.components.heater:SetThermics(false, true)
    end
end)

-- 夜影万金油可以提高姐姐的温度上限
AddPrefabPostInit("ghostlyelixir_attack_buff", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.potion_tunings and not inst.potion_tunings.tempprocess2hm then
        inst.potion_tunings.tempprocess2hm = true
        local ONAPPLY = inst.potion_tunings.ONAPPLY
        inst.potion_tunings.ONAPPLY = function(inst, target, ...)
            if target and target:IsValid() and target:HasTag("abigail") and target.components.temperature then
                target.components.temperature.overheattemp = newmaxoverheattemp
                if target.components.temperature.current > maxoverheattemp and target.components.temperature.current < newmaxoverheattemp then
                    target:PushEvent("stopoverheating")
                end
            end
            ONAPPLY(inst, target, ...)
        end
        local ONDETACH = inst.potion_tunings.ONDETACH
        inst.potion_tunings.ONDETACH = function(inst, target, ...)
            if target and target:IsValid() and target:HasTag("abigail") and target.components.temperature then
                target.components.temperature.overheattemp = maxoverheattemp
                if target.components.temperature.current < newmaxoverheattemp and target.components.temperature.current > maxoverheattemp then
                    target:PushEvent("startoverheating")
                end
            end
            ONDETACH(inst, target, ...)
        end
    end
end)

-- 鬼魂有温度
local function ghostHeatFn(inst, observer)
    return (observer == nil or observer.prefab ~= "wendy" or TheWorld.state.issummer) and
               (TheWorld.state.issummer and math.min(TheWorld.state.temperature, 60) or -10) or nil
end
AddPrefabPostInit("ghost", function(inst)
    if not TheWorld.ismastersim then return end
    if not inst.components.heater then
        inst:AddComponent("heater")
        inst.components.heater.heatfn = ghostHeatFn
        inst.components.heater:SetThermics(false, true)
    end
end)
local function smallghostHeatFn(inst, observer)
    return (observer == nil or observer.prefab ~= "wendy" or TheWorld.state.issummer) and
               (TheWorld.state.issummer and math.min(TheWorld.state.temperature, 70) or 0) or nil
end
AddPrefabPostInit("smallghost", function(inst)
    if not TheWorld.ismastersim then return end
    if not inst.components.heater then
        inst:AddComponent("heater")
        inst.components.heater.heatfn = smallghostHeatFn
        inst.components.heater:SetThermics(false, true)
    end
end)


-- 计算阿比盖尔经验
local function UpdateHoverStr(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner:HasTag("player") then
        if owner.components.ghostlybond then
            local bond = owner.components.ghostlybond
            if bond.externalbondtimemultipliers and bond.bondlevel then
                local scale = bond.externalbondtimemultipliers:Get()
                if scale > 0 then
                    if bond.maxbondlevel and bond.bondlevel < bond.maxbondlevel and bond.bondleveltimer and bond.bondlevelmaxtime then
                        local time = math.floor((bond.bondlevelmaxtime - bond.bondleveltimer) / scale)
                        inst.components.hoverer2hm.hoverStr = string.format(TUNING.util2hm.GetLanguage("等级:%s 升级剩余:%s", "Level:%s Upgrade Last:%s"),
                            tostring(bond.bondlevel), TUNING.util2hm.GetTime(time))
                    else
                        inst.components.hoverer2hm.hoverStr = string.format(TUNING.util2hm.GetLanguage("等级:%s", "Level:%s"),
                            tostring(bond.bondlevel))
                    end
                else
                    inst.components.hoverer2hm.hoverStr = string.format(TUNING.util2hm.GetLanguage("等级:%s", "Level:%s"),
                            tostring(bond.bondlevel))
                end
            end
        end
    end
end

local function ondropped(inst)
    inst.components.hoverer2hm.hoverStr = ""
    if inst.doUpdateHoverTask then
        inst.doUpdateHoverTask:Cancel()
        inst.doUpdateHoverTask = nil
    end
end

local function onputininventory(inst)
    ondropped(inst)
    inst.doUpdateHoverTask = inst:DoPeriodicTask(1, UpdateHoverStr)
    UpdateHoverStr(inst)
end

AddPrefabPostInit("abigail_flower", function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("hoverer2hm")
    inst:ListenForEvent("onputininventory", onputininventory)
    inst:ListenForEvent("ondropped", ondropped)
end)

--温蒂技能树改动
-- local BuildSkillsData = require("prefabs/skilltree_wendy_mod")
-- local defs = require("prefabs/skilltree_defs")
-- local data = BuildSkillsData(defs.FN)

-- defs.CreateSkillTreeFor("wendy", data.SKILLS)
-- defs.SKILLTREE_ORDERS["wendy"] = data.ORDERS


-- 万灵药成本增加
AddRecipePostInit("ghostlyelixir_attack", function(inst) table.insert(inst.ingredients, Ingredient("mole", 1)) end)
AddRecipePostInit("ghostlyelixir_speed", function(inst) table.insert(inst.ingredients, Ingredient("rabbit", 1)) end)

-- 灵魂容器成本增加
AddRecipePostInit("graveurn", function(inst) table.insert(inst.ingredients, Ingredient("ghostflower", 10)) end)

-- 幽魂花冠成本增加
AddRecipePostInit("ghostflowerhat", function(inst) table.insert(inst.ingredients, Ingredient("nightmarefuel", 2)) end)

-- 蝴蝶现在批量复活4个
AddRecipe2("wendy_butterfly",				{Ingredient("ghostflower", 8), Ingredient("butterflywings", 4)}, 
TECH.NONE,	{builder_skill="wendy_ghostflower_butterfly", product="butterfly",image="butterfly.tex",numtogive = 4})
AddRecipe2("wendy_moonbutterfly",			{Ingredient("ghostflower", 16), Ingredient("moonbutterflywings", 4)},	
TECH.NONE,	{builder_skill="wendy_ghostflower_butterfly", product="moonbutterfly",image="moonbutterfly.tex",numtogive = 4})

-- 恐怖经历消耗血量
AddRecipe2("ghostlyelixir_revive",	{Ingredient("forgetmelots", 1), Ingredient("ghostflower", 3),Ingredient(CHARACTER_INGREDIENT.HEALTH, 20)},
TECH.NONE,	{builder_skill="wendy_potion_revive", override_numtogive_fn = elixir_numtogive, no_deconstruction=true})

-- 鬼魂复仇有cd
AddComponentPostInit("avengingghost", function(self)
    if not self.inst.components.timer then
        self.inst:AddComponent("timer")
    end

    local old_StartAvenging = self.StartAvenging
    self.StartAvenging = function(self, time)
        -- 检查冷却
        if self.inst.components.timer:TimerExists("avenging_cooldown") then
            return
        end
        return old_StartAvenging(self, time)
    end

    local old_StopAvenging = self.StopAvenging
    self.StopAvenging = function(self)
        old_StopAvenging(self)
        -- 启动冷却计时器
        self.inst.components.timer:StartTimer("avenging_cooldown", 480 * 3) -- 3天冷却
    end

    local old_ShouldAvenge = self.ShouldAvenge
    self.ShouldAvenge = function(self)
        -- 冷却期间不能复仇
        if self.inst.components.timer:TimerExists("avenging_cooldown") then
            return false
        end
        return old_ShouldAvenge(self)
    end
end)

-- 灵魂容器能在非自然地皮放置
local function restrictdeploy2hm(inst)
    if not inst.components.deployable then inst:AddComponent("deployable") end
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
end
AddPrefabPostInit("graveurn", restrictdeploy2hm)

-- 修复骨灰盒重载时失效的问题
AddPrefabPostInit("abigail", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 确保在加载后检查骨灰罐状态
    inst:DoTaskInTime(0, function()
        if inst._playerlink and inst._playerlink:IsValid() then
            -- 强制更新骨灰罐状态
            local is_active = TheWorld.components.sisturnregistry and TheWorld.components.sisturnregistry:IsActive()            
            inst._playerlink.components.ghostlybond:SetBondTimeMultiplier("sisturn", is_active and TUNING.ABIGAIL_BOND_LEVELUP_TIME_MULT or nil)
        end
    end)
end)

-- 阿比盖尔逃离动作后收回有cd
AddPrefabPostInit("abigail", function(inst)
	if not TheWorld.ismastersim then return end
	inst:ListenForEvent("do_ghost_escape", function(inst) -- 加个标记
        inst.escape_mark2hm = inst:DoTaskInTime(1,function(inst) inst.escape_mark2hm = nil end)
    end)
end)
AddPrefabPostInit("wendy", function(inst)
	if not TheWorld.ismastersim then return end
    if inst.components.ghostlybond then
        local _Recall = inst.components.ghostlybond.Recall
        inst.components.ghostlybond.Recall = function(self, was_killed, ...)
            if self.ghost ~= nil and self.summoned and not self.inst.sg:HasStateTag("dissipate") and self.ghost.escape_mark2hm then
                return false -- escape_mark2hm则不收回
            end
            return _Recall(self, was_killed, ...)
        end
    end
end)