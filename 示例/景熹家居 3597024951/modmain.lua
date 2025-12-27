--驯猫糕手：我接手了这个模组的代码，基本结构是前一任码师写的，我在这个基础上添砖加瓦。
--不好的地方或许是我边打瞌睡边写的

GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

PrefabFiles = {
    --"jx_decor",         --装饰位点
    "jx_potted",        --盆栽
    "jx_tent",          --圆顶床
    "jx_chest",         --箱子
    "jx_cookpot",       --电煮锅
    "jx_icebox",        --电冰箱
    "jx_fish_tank",     --鱼缸柜
    "jx_tv",            --电视机
    "jx_phonograph",    --电话机
    "jx_tapeplayer",    --磁带录音机
    "jx_wateringcan",   --浇水壶
    "jx_sofa",          --沙发、椅子
    "jx_mushroom_light",--路灯
    "jx_lamp",          --床头灯
    "jx_table",         --沙发桌
    "jx_furnace",       --暖炉
    "jx_wardrobe",      --衣柜
    "jx_sewingmachine", --缝纫机
    "jx_oven",          --烤箱
    "jx_table_2",       --餐桌
    "jx_rug",           --地毯
    "jx_turfs",         --地皮
    "jx_backpack",      --兔子背包
    "jx_backpack_2",    --兔子背包
    "jx_pack",          --便当包
    "jx_mailbox",       --信箱
    "jx_bathtub",       --浴缸
    "jx_hats",          --帽子
    "jx_pan",           --平底锅(武器)
    "jx_weapon",        --刀、叉、勺
    "jx_fan",           --电风扇
    "jx_well",          --水井
    "jx_washer",        --洗衣机
    "jx_toilet_suction",--马桶吸
    "jx_toaster",       --烤面包机
    "jx_basket",        --手工菜篮
    "jx_bookcase",      --展示柜
    "jx_icemaker",      --制冰机
    "jx_lantern_playerfx",--提灯特效
    "jx_lantern",       --提灯
    "jx_car",           --甲壳虫车
    "jx_rug_bag",       --地毯包
}

local locale = GLOBAL.LOC.GetLocaleCode()
if locale == "zh" or locale == "zht" or locale=="zhr" then
  modimport("scripts/jxlanguages/jx_ch")
else
  modimport("scripts/jxlanguages/jx_en")
end

modimport("scripts/jxmain/jx_assets")
modimport("scripts/jxmain/jx_recipes")
modimport("scripts/jxmain/jx_containers")

modimport("scripts/stategraphs/SGjx_pan")
-----------------------------------------------------------------------------------------------
--花岗岩拼花瓷砖
AddTile("GRANITE", "LAND", {ground_name = "Granite"},
  {
    name = "levels/tiles/carpet.tex",
    noise_texture = "noise_jx_granite",
    runsound = "dontstarve/movement/run_carpet",
    walksound = "dontstarve/movement/walk_carpet",
    snowsound = "dontstarve/movement/run_snow",
    mudsound = "dontstarve/movement/run_mud",
    flooring = true,
    hard = true,
  },
  {
    name = "map_edge",
    noise_texture = "mini_noise_jx_granite"
  },
  {
    name = "granite",
    pickupsound = "cloth",
    anim = "jx_turf_granite",
    bank_build = "jx_turfs"
  }
)
-------------------------------------------------------------------------------------------------
--信箱
local writeables = require("writeables")
local homesign = writeables.GetLayout("homesign")
writeables.AddLayout("jx_mailbox", homesign)
------------------------------------------------------------------------------------------------
--电煮锅食谱
local cooking = require("cooking")
local oldRegisterPrefabs = GLOBAL.ModManager.RegisterPrefabs
GLOBAL.ModManager.RegisterPrefabs = function(self,...)
  for k, v in pairs(cooking.recipes) do
    if k and v and k == "cookpot" then
      for _, i in pairs(v) do
        --if not (i.spice or i.platetype) then
          local newrecipe = shallowcopy(i)
          newrecipe.no_cookbook = true
          AddCookerRecipe("jx_cookpot", newrecipe)
				--end
			end
    end
  end
  oldRegisterPrefabs(self,...)
end
--[[local foods = require("preparedfoods")
for k, recipe in pairs(foods) do 
  AddCookerRecipe("jx_cookpot", recipe) 
end
local nonfoods = require("preparednonfoods")
for k, recipe in pairs(nonfoods) do 
  AddCookerRecipe("jx_cookpot", recipe)
end]]
--------------------------------------------------------------------------------------------------------
--是否禁本地
local client_mods_disabled = KnownModIndex:IsModEnabled("client_mods_disabled")
--------------------------------------------------------------------------------------------------------
--兼容智能锅workshop-727774324 --本地模组
--函数在 workshop-727774324 的 scripts/cookingpots.lua 中被定义
if not client_mods_disabled and KnownModIndex:IsModEnabled("workshop-727774324") then
  GLOBAL.AddCookingPot('jx_cookpot')
end
---------------------------------------------------------------------------------------------------------
--兼容自动做饭workshop-2033458869 --本地模组
if not client_mods_disabled then
  local cookware_morphs = { cookpot = { jx_cookpot = true } }
  local AUTO_COOKING_COOKWARES = GLOBAL.rawget(GLOBAL, "AUTO_COOKING_COOKWARES") or {}
  GLOBAL.AUTO_COOKING_COOKWARES = AUTO_COOKING_COOKWARES
  for base, morphs in pairs(cookware_morphs) do
    AUTO_COOKING_COOKWARES[base] = shallowcopy(morphs, AUTO_COOKING_COOKWARES[base])
  end
end
-------------------------------------------------------------------------------------------------------------
--兼容智能小木牌workshop-1595631294 --服务器模组
if KnownModIndex:IsModEnabled("workshop-1595631294") then
  AddPrefabPostInit("jx_chest", function(inst)
      if not TheWorld.ismastersim then return end
      inst:AddComponent("smart_minisign")
  end)
end
--------------------------------------------------------------------------------------------------------------
--兼容showme中文版的容器高亮显示workshop-2287303119 --服务器模组
local containers =
{
  "jx_chest",
  "jx_icebox",
}
for k, m in pairs(ModManager.mods) do
  if m and GLOBAL.rawget(m, "SHOWME_STRINGS") then
    if m.postinitfns and m.postinitfns.PrefabPostInit and m.postinitfns.PrefabPostInit.treasurechest then
      for _,v in ipairs(containers) do
        m.postinitfns.PrefabPostInit[v] = m.postinitfns.PrefabPostInit.treasurechest
      end
    end
    break
  end
end
-------------------------------------------------------------------------------------------------------------
--伯尼可以给缝纫机修补
AddPrefabPostInit("bernie_inactive", function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("tradable")
end)
----------------------------------------------------------------------------------------------------
--干草叉可以铲地毯
--[[AddPrefabPostInit("pitchfork", function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddTag("pitchfork")
end)
AddPrefabPostInit("goldenpitchfork", function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddTag("pitchfork")
end)

local jx_rug_dig = AddAction("JX_RUG_DIG", STRINGS.ACTIONS.DIG, function(act)
    if act.target and act.target:HasTag("jx_rug") and 
      act.doer and act.doer.components.inventory:EquipHasTag("pitchfork") 
    then
      act.target.components.workable:WorkedBy(act.doer)
      return true
    end
end)
jx_rug_dig.priority  = 1
jx_rug_dig.right = true

AddComponentAction("EQUIPPED", "terraformer", function(inst, doer, target, actions, right)
    if right and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) and
      target:HasTag("jx_rug")
    then
      table.insert(actions, ACTIONS.JX_RUG_DIG)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(jx_rug_dig, "dig_start"))
AddStategraphActionHandler("wilson_client", ActionHandler(jx_rug_dig, "dig_start"))
----小分割线
local old_terraformer_fn = ACTIONS.TERRAFORM.fn
ACTIONS.TERRAFORM.fn = function(act)
  if act.invobject ~= nil and act.invobject.components.terraformer ~= nil then
    if act.doer then
      local x, y, z = act.doer.Transform:GetWorldPosition()
      local ents = TheSim:FindEntities(x, y, z, 2.8, {"jx_rug"})
      if #ents > 0 then
        ents[1].components.workable:WorkedBy(act.doer)
        return true
      end
    end
    return old_terraformer_fn(act)
  end
end]]
--改成马桶吸
local jx_rug_dig = AddAction("JX_RUG_DIG", STRINGS.ACTIONS.DIG, function(act)
    if act.target and act.target:HasTag("jx_rug") and 
      act.doer and act.doer.components.inventory:EquipHasTag("jx_toilet_suction") 
    then
      act.target.components.workable:WorkedBy(act.doer)
      return true
    end
end)
jx_rug_dig.priority  = 1
jx_rug_dig.right = true

AddComponentAction("EQUIPPED", "jx_rug_dig", function(inst, doer, target, actions, right)
    if right and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) and
      target:HasTag("jx_rug")
    then
      table.insert(actions, ACTIONS.JX_RUG_DIG)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(jx_rug_dig, "dig_start"))
AddStategraphActionHandler("wilson_client", ActionHandler(jx_rug_dig, "dig_start"))
-----------------------------------------------------------------------------------------------------------
--栅栏击剑旋转地毯
AddComponentPostInit("fencerotator",function(self)
    local old_Rotate = self.Rotate
    function self:Rotate(target, delta,...)
      if target and target:HasTag("jx_rug") and target.rotatable_angle then
        local angle = target.Transform:GetRotation()
        target.Transform:SetRotation(angle + target.rotatable_angle)--不用delta参数
        if target.NOCLICK_Tag_Task then
          target.NOCLICK_Tag_Task:Cancel()
          target.NOCLICK_Tag_Task = nil
        end
        target.NOCLICK_Tag_Task = target:DoTaskInTime(target.NOCLICK_Tag_Task_Time or 5,function() target:AddTag("NOCLICK") end)
        
        self.inst:PushEvent("fencerotated")
        SpawnPrefab("fence_rotator_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
        
      else
        old_Rotate(self, target, delta,...)
      end
    end
end)

--[[AddPrefabPostInit("fence_rotator", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.equippable then
      local old_onequipfn = inst.components.equippable.onequipfn
      inst.components.equippable:SetOnEquip(function(inst, owner)
        old_onequipfn(inst, owner)
        if owner then
          local x, y, z = owner.Transform:GetWorldPosition()
          local ents = TheSim:FindEntities(x, y, z, 2.8, {"jx_rug", "rotatableobject",})
          if #ents > 0 then
            local target = ents[1]
            target:RemoveTag("NOCLICK")
            if target.NOCLICK_Tag_Task then
              target.NOCLICK_Tag_Task:Cancel()
              target.NOCLICK_Tag_Task = nil
            end
            target.NOCLICK_Tag_Task = target:DoTaskInTime(target.NOCLICK_Tag_Task_Time or 3,function() target:AddTag("NOCLICK") end)
          end
        end
      end)
    end
end)]]
------------------------------------------------------------------------------------------------------------
--部署动作加“铺设地毯”字符
local old_deploy_strfn = ACTIONS.DEPLOY.strfn
ACTIONS.DEPLOY.strfn = function(act)
	return act.invobject and act.invobject:HasTag("jx_rug_item") and "JX_DEPLOY" or old_deploy_strfn(act)
end
-----------------------------------------------------------------------------------------------------------
--采集动作加“拿取”字符
local old_pick_strfn = ACTIONS.PICK.strfn
ACTIONS.PICK.strfn = function(act)
	return act.target and act.target:HasAnyTag("jx_oven", "jx_table_2", "jx_table_6", "jx_icemaker") and "TAKEITEM" or old_pick_strfn(act)
end
-----------------------------------------------------------------------------------------------------------
--交易动作加字符
local old_give_strfn = ACTIONS.GIVE.strfn
ACTIONS.GIVE.strfn = function(act)
	return act.target and act.target:HasTag("jx_washer") and "WASH" or
    act.target and act.target:HasTag("jx_sewingmachine") and "SEW" or
    old_give_strfn(act)
end
-----------------------------------------------------------------------------------------------------------
--浴缸动作和状态机
local jx_bath = AddAction("JX_BATH", STRINGS.ACTIONS.BATH--[["泡澡"]], function(act)
    if act.target and act.target:HasTag("jx_bathtub") then
      act.target:PushEvent("onstartbath", {player = act.doer})
      return true
    end
end)

AddComponentAction("SCENE", "jx_bath", function(inst, doer, actions, right)
    if inst:HasTag("jx_bathtub") and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) then
      table.insert(actions, ACTIONS.JX_BATH)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(jx_bath, "jx_bath"))
AddStategraphActionHandler("wilson_client", ActionHandler(jx_bath, "jx_bath"))

local function SetStartBathState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:AddImmunity("bath")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:IgnoreAll("bath")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Disable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(false)
        inst.components.playercontroller:Enable(false)
    end
    inst:OnSleepIn()
    inst.components.inventory:Hide()
    inst:PushEvent("ms_closepopups")
    inst:ShowActions(false)
end

local function SetStopBathState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:RemoveImmunity("bath")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:StopIgnoringAll("bath")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Enable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(true)
        inst.components.playercontroller:Enable(true)
    end
    inst:OnWakeUp()
    inst.components.inventory:Show()
    inst:ShowActions(true)
end

AddStategraphState("wilson",
  State{
    name = "jx_bath",
    tags = { "bath", "busy", "noattack", },
    onenter = function(inst)
      inst.AnimState:PlayAnimation("pickup")
      inst.sg:SetTimeout(6 * FRAMES)
      SetStartBathState(inst)
    end,
    ontimeout = function(inst)
      local bufferedaction = inst:GetBufferedAction()
      if bufferedaction == nil then
        inst.AnimState:PlayAnimation("pickup_pst")
        inst.sg:GoToState("idle", true)
        return
      end
      local bathtub = bufferedaction.target
      if bathtub == nil or not bathtub:HasTag("jx_bathtub") or bathtub:HasTag("hasplayer") then
        inst:PushEvent("performaction", { action = inst.bufferedaction })
        inst:ClearBufferedAction()
        inst.AnimState:PlayAnimation("pickup_pst")
        inst.sg:GoToState("idle", true)
      else
        inst.bathtub = bathtub
        inst:PerformBufferedAction()
        --inst.components.health:SetInvincible(true)
        inst:Hide()
        if inst.Physics ~= nil then
          inst.Physics:Teleport(inst.Transform:GetWorldPosition())
        end
        if inst.DynamicShadow ~= nil then
          inst.DynamicShadow:Enable(false)
        end
        inst.sg:RemoveStateTag("busy")
        if inst.components.playercontroller ~= nil then
          inst.components.playercontroller:Enable(true)
        end
      end
    end,
    onexit = function(inst)
      --inst.components.health:SetInvincible(false)
      inst:Show()
      if inst.DynamicShadow ~= nil then
        inst.DynamicShadow:Enable(true)
      end
      if inst.bathtub ~= nil then
        SetStopBathState(inst)
        inst.bathtub:PushEvent("onstopbath", { player = inst})
        inst.bathtub = nil
      else
        SetStopBathState(inst)
      end
    end,
  }
)
AddStategraphState("wilson_client",
  State{
    name = "jx_bath",
    tags = { "bath", "busy", "noattack", },
    server_states = { "bath" },
    onenter = function(inst)
      inst.components.locomotor:Stop()
      inst.AnimState:PlayAnimation("pickup")
      inst.AnimState:PushAnimation("pickup_lag", false)

      inst:PerformPreviewBufferedAction()
      inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
			if inst.sg:ServerStateMatches() then
        if inst.entity:FlattenMovementPrediction() then
          inst.sg:GoToState("idle", "noanim")
        end
      elseif inst.bufferedaction == nil then
        inst.AnimState:PlayAnimation("pickup_pst")
        inst.sg:GoToState("idle", true)
      end
    end,
    ontimeout = function(inst)
      inst:ClearBufferedAction()
      inst.AnimState:PlayAnimation("pickup_pst")
      inst.sg:GoToState("idle", true)
    end,
  }
)

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("player_despawn", function()
      if inst.sg:HasStateTag("bath") then
        inst:ClearBufferedAction()
      end
      if inst.bathtub ~= nil then
        inst.bathtub.components.jx_bath:OnPlayerDespawn()
        inst.bathtub = nil
      end
    end)
end)
-----------------------------------------------------------------------------------------------------------
--烤箱烹饪曼德拉草保护
AddPrefabPostInit("mandrake", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.cookable then
      local old_oncooked = inst.components.cookable.oncooked
      inst.components.cookable:SetOnCookedFn(function(inst, cooker, chef)
        if chef and chef:HasTag("jx_oven") then
          --只播放声音，移除其余行为
          chef.SoundEmitter:PlaySound("dontstarve/creatures/mandrake/death")
        else
          old_oncooked(inst, cooker, chef)
        end
      end)
    end
end)
-----------------------------------------------------------------------------------------------------------
--冰加标签
AddPrefabPostInit("ice", function(inst) inst:AddTag("ice") end)
-----------------------------------------------------------------------------------------------------------
--洗衣机洗涤按钮(RPC还不会用)
local old_incinerate_fn = ACTIONS.INCINERATE.fn
ACTIONS.INCINERATE.fn = function(act)
  if act.target and act.target:HasAnyTag("jx_washer", "jx_icemaker") then
    if act.target.StartWork then
      if act.target.components.container then
        act.target.components.container:Close()
      end
      act.target:StartWork()
      return true
    else
      return false
    end
  else
    return old_incinerate_fn(act)
  end
end
-----------------------------------------------------------------------------------------------------------