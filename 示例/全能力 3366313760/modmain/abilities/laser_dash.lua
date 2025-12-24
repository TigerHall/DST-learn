--[[
暂时废弃，与其说划过敌人造成伤害，一直顶着敌人好像还伤害时间更长

激光疾驰
按下快捷键进入滑行状态，经过位置生成激光对附近单位造成伤害，滑行期间持续消耗饱食度，饱食度不够时会尝试寻找身上的食物并吃下，饱食度为0时取消滑行状态，滑行时间越长饱食度消耗越快并且伤害越高移速越快。
]]

-- local LASER_DASH_KEY = GLOBAL["KEY_" .. GetModConfigData("laser_dash")]
-- local Utils = require("aab_utils/utils")
-- local GetPrefab = require("aab_utils/getprefab")

-- table.insert(Assets, Asset("ANIM", "anim/player_actions_roll.zip"))

-- ----------------------------------------------------------------------------------------------------
-- local MAX_SPEED_MULT = 2
-- local MAX_HUNGER_MULT = 10

-- local function StopSkill(inst)
--     inst:RemoveTag("aab_laser_dash")
--     inst._aab_laser_dash_start = nil
--     inst._aab_laser_dash_level = nil
--     if inst._aab_laser_dash_task then
--         inst._aab_laser_dash_task:Cancel()
--         inst._aab_laser_dash_task = nil
--     end
--     inst:RemoveEventCallback("startstarving", StopSkill)
-- end

-- local function Update(inst)
--     if GetPrefab.IsEntityDeadOrGhost(inst) then
--         StopSkill(inst)
--         return
--     end

--     local delta = GetTime() - inst._aab_laser_dash_start
--     local level = math.floor(delta / 4)
--     if level ~= inst._aab_laser_dash_level then
--         inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "aab_laser_dash")
--         inst.components.locomotor:SetExternalSpeedMultiplier(inst, "aab_laser_dash", math.min(1 + 0.25 * level, MAX_SPEED_MULT))

--         inst.components.hunger.burnratemodifiers:RemoveModifier(inst, "aab_laser_dash")
--         inst.components.hunger.burnratemodifiers:SetModifier(inst, math.min(1 + 0.25 * level, MAX_HUNGER_MULT), "aab_laser_dash")

--         inst._aab_laser_dash_level = level
--     end

--     local x, y, z = inst.Transform:GetWorldPosition()
--     local fx = SpawnPrefab("alterguardian_laser")
--     fx.caster = inst
--     fx.overridedmg = (level + 1) * 10 --伤害提高
--     fx.Transform:SetPosition(x, 0, z)
--     fx:Trigger(0, { [inst] = true })
-- end

-- AddModRPCHandler(modname, "LaserDash", function(inst)
--     if GetPrefab.IsEntityDeadOrGhost(inst) then
--         return
--     end

--     if inst:HasTag("aab_laser_dash") then
--         --结束
--         StopSkill(inst)
--     else
--         --开始
--         inst:AddTag("aab_laser_dash")
--         inst._aab_laser_dash_start = GetTime()
--         inst._aab_laser_dash_level = 0
--         inst._aab_laser_dash_task = inst:DoPeriodicTask(0.1, Update)
--         inst:ListenForEvent("startstarving", StopSkill)
--     end
-- end)

-- TheInput:AddKeyDownHandler(LASER_DASH_KEY, function()
--     if Utils.IsDefaultScreen()
--         and not ThePlayer:HasTag("playerghost")
--         and ThePlayer.replica.hunger and ThePlayer.replica.hunger:GetCurrent() > 0
--         and not (ThePlayer.replica.rider ~= nil and ThePlayer.replica.rider:IsRiding())
--     then
--         SendModRPCToServer(MOD_RPC[modname]["LaserDash"])
--     end
-- end)

-- ----------------------------------------------------------------------------------------------------

-- -- 源代码拷贝
-- local function ConfigureRunState(inst)
--     if inst.components.rider:IsRiding() then
--         inst.sg.statemem.riding = true
--         inst.sg.statemem.groggy = inst:HasTag("groggy")
--         inst.sg:AddStateTag("nodangle")
--         inst.sg:AddStateTag("noslip")

--         local mount = inst.components.rider:GetMount()
--         inst.sg.statemem.ridingwoby = mount and mount:HasTag("woby")
--     elseif inst.components.inventory:IsHeavyLifting() then
--         inst.sg.statemem.heavy = true
--         inst.sg.statemem.heavy_fast = inst.components.mightiness ~= nil and inst.components.mightiness:IsMighty()
--         inst.sg:AddStateTag("noslip")
--     elseif inst:IsChannelCasting() then
--         inst.sg.statemem.channelcast = true
--         inst.sg.statemem.channelcastitem = inst:IsChannelCastingItem()
--     elseif inst:HasTag("wereplayer") then
--         inst.sg.statemem.iswere = true
--         inst.sg:AddStateTag("noslip")

--         if inst:HasTag("weremoose") then
--             if inst:HasTag("groggy") then
--                 inst.sg.statemem.moosegroggy = true
--             else
--                 inst.sg.statemem.moose = true
--             end
--         elseif inst:HasTag("weregoose") then
--             if inst:HasTag("groggy") then
--                 inst.sg.statemem.goosegroggy = true
--             else
--                 inst.sg.statemem.goose = true
--             end
--         elseif inst:HasTag("groggy") then
--             inst.sg.statemem.groggy = true
--         else
--             inst.sg.statemem.normal = true
--         end
--     elseif inst:IsInAnyStormOrCloud() and not inst.components.playervision:HasGoggleVision() then
--         inst.sg.statemem.sandstorm = true
--     elseif inst:HasTag("groggy") then
--         inst.sg.statemem.groggy = true
--     elseif inst:IsCarefulWalking() then
--         inst.sg.statemem.careful = true
--         inst.sg:AddStateTag("noslip")
--     else
--         inst.sg.statemem.normal = true
--         inst.sg.statemem.normalwonkey = inst:HasTag("wonkey") or nil
--     end
-- end

-- local function LoopPlayAnimation(inst, anim)
--     if not inst.AnimState:IsCurrentAnimation(anim) then
--         inst.AnimState:PlayAnimation(anim, true)
--     end
-- end

-- AddStategraphPostInit("wilson", function(sg)
--     -- Utils.FnDecorator(sg.states["idle"], "onenter", nil, function(retTab, inst, pushanim)
--     --     if inst.components.rider:IsRiding() or not inst:HasTag("aab_laser_dash") then return end
--     --     LoopPlayAnimation(inst, "slide_loop")
--     -- end)
--     -- Utils.FnDecorator(sg.states["funnyidle"], "onenter", function(inst)
--     --     if inst.components.rider:IsRiding() or not inst:HasTag("aab_laser_dash") then return end
--     --     inst.sg:GoToState("idle")
--     --     return nil, true
--     -- end)

--     Utils.FnDecorator(sg.states["run_start"], "onenter", nil, function(retTab, inst)
--         if inst.components.rider:IsRiding() or not inst:HasTag("aab_laser_dash") then return end
--         inst.AnimState:PlayAnimation("slide_pre")
--     end)
--     Utils.FnDecorator(sg.states["run"], "onenter", function(inst)
--         if inst.components.rider:IsRiding() or not inst:HasTag("aab_laser_dash") then return end

--         -- 自己写onenter，不然老是切换动画会一卡一卡的
--         ConfigureRunState(inst) --重复执行也没问题
--         inst.components.locomotor:RunForward()

--         LoopPlayAnimation(inst, "slide_loop")
--         inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
--         return nil, true
--     end)

--     Utils.FnDecorator(sg.states["run_stop"], "onenter", nil, function(retTab, inst)
--         if inst.components.rider:IsRiding() or not inst:HasTag("aab_laser_dash") then return end
--         inst.AnimState:PlayAnimation("slide_pst")
--     end)
-- end)
