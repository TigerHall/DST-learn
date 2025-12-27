--[[local function DoThrust(inst)
    local weapon = inst.components.combat:GetWeapon()
    if weapon and weapon:HasTag("fire_machete") then
        inst.components.combat:DoAttack(inst.sg.statemem.target, inst.components.combat:GetWeapon(), nil, nil, 0.393)
        weapon.components.finiteuses:Repair(0.8)
    end
end]]

--[[local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end]]

AddStategraphPostInit("wilson", function(sg)
    local old_ATTACK = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action,...)
		  local weapon = inst.components.combat:GetWeapon()
      if weapon and weapon:HasTag("jx_pan") then
        --[[if weapon:HasTag("fire_machete_multithrust") then 
          return "fire_machete_multithrust"
        elseif weapon:HasTag("fire_machete_hop") then 
          return "fire_machete_hop"
        elseif weapon:HasTag("fire_machete_lunge") then 
          return "fire_machete_lunge"
        elseif weapon:HasTag("fire_machete_chop") then 
          return "fire_machete_chop"
        else
          inst.SoundEmitter:PlaySound("fire_machete/attack/attack")
        end]]
        if weapon:HasTag("jx_pan_lunge") then 
          return "jx_pan_lunge"
        elseif weapon:HasTag("jx_pan_chop") then 
          return "jx_pan_chop"
        end
      end
      return old_ATTACK(inst, action,...)
    end
end)

AddStategraphPostInit("wilson_client", function(sg)
    local old_ATTACK = sg.actionhandlers[ACTIONS.ATTACK].deststate
    sg.actionhandlers[ACTIONS.ATTACK].deststate = function(inst, action,...)
	  	local weapon = inst.replica.combat:GetWeapon()
      if weapon and weapon:HasTag("jx_pan") then
        --[[if weapon:HasTag("fire_machete_multithrust") then 
          return "fire_machete_multithrust"
        elseif weapon:HasTag("fire_machete_hop") then 
          return "fire_machete_hop"
        elseif weapon:HasTag("fire_machete_lunge") then 
          return "fire_machete_lunge"
        elseif weapon:HasTag("fire_machete_chop") then 
          return "fire_machete_chop"
        else
          inst.SoundEmitter:PlaySound("fire_machete/attack/attack")
        end]]
        if weapon:HasTag("jx_pan_lunge") then 
          return "jx_pan_lunge"
        elseif weapon:HasTag("jx_pan_chop") then 
          return "jx_pan_chop"
        end
      end
      return old_ATTACK(inst, action,...)
    end
end)

--技能跳劈部分------
--修改释放技能的动作(主机)
--[[AddStategraphPostInit("wilson", function(sg)
    local old_CASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
      if action.invobject ~= nil and action.invobject:HasTag("willow_ember") then
        if action.invobject.components.spellbook:GetSpellName() == STRINGS.PYROMANCY.LUNAR_FIRE and inst:HasTag("lunarfire_ing") then
          return "willow_cast_quick"--中断月火
        else
          return inst:HasTag("canrepeatcast") and "repeatcastspellmind" or "castspellmind"
        end
      end
      local weapon = inst.components.combat:GetWeapon()
		  if weapon then
        if weapon:HasTag("fire_machete_aoeweapon_leap") then 
				  return "moyu_combat_leap_start"
        end
		  end
      return old_CASTAOE(inst, action)
    end
end)
AddStategraphPostInit("wilson_client", function(sg)
    local old_CASTAOE = sg.actionhandlers[ACTIONS.CASTAOE].deststate
    sg.actionhandlers[ACTIONS.CASTAOE].deststate = function(inst, action)
      if action.invobject ~= nil and action.invobject:HasTag("willow_ember") then
        if action.invobject.components.spellbook:GetSpellName() == STRINGS.PYROMANCY.LUNAR_FIRE and inst:HasTag("lunarfire_ing") then
          return "willow_cast_quick"
        else
          return inst:HasTag("canrepeatcast") and "repeatcastspellmind" or "castspellmind"
        end
      end
      local weapon = inst.replica.combat:GetWeapon()
      if weapon then
        if weapon:HasTag("fire_machete_aoeweapon_leap") then 
          return "moyu_combat_leap_start"
        end
		  end
      return old_CASTAOE(inst, action)
    end
end)]]

--[[AddStategraphState("wilson", 
    State{
        name = "moyu_combat_leap_start",
        tags = { "aoe", "doing", "busy", "nointerrupt", "nomorph", "noattack" },

        onenter = function(inst)
            local weapon = inst.components.combat:GetWeapon()
            if not weapon or not weapon:IsValid() then
              inst.sg:GoToState("idle")
              return
            elseif weapon.components.rechargeable and not weapon.components.rechargeable:IsCharged() then
              inst.sg:GoToState("idle")
              if inst.components.talker then
                inst.components.talker:Say(STRINGS.FIREMACHETE_RECHARGE)
              end
              return
            elseif weapon.components.finiteuses and weapon.components.finiteuses:GetUses() <= 0 then
              inst.sg:GoToState("idle")
              if inst.components.talker then
                inst.components.talker:Say(STRINGS.FIREMACHETE_ONFINISHED)
              end
              return
            end
            
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")
            inst.components.health:SetInvincible(true)
        end,

        events =
        {
            EventHandler("combat_leap", function(inst, data)
                inst.sg.statemem.leap = true
                inst.sg:GoToState("fire_machete_combat_leap", {data = data})
                inst.SoundEmitter:PlaySound("fire_machete/attack/leap", nil, .7)
            end),
        },
        
        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                if inst.AnimState:IsCurrentAnimation("atk_leap_pre") then
                  inst.AnimState:PlayAnimation("atk_leap_lag")
                  inst:PerformBufferedAction()
                else
                  inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst) 
          inst.components.health:SetInvincible(false)
        end,
    }
)

AddStategraphState("wilson", 
    State{
        name = "fire_machete_combat_leap",
        tags = { "aoe", "doing", "busy", "nointerrupt", "nopredict", "nomorph", "noattack" },

        onenter = function(inst, data)
            inst.components.health:SetInvincible(true)
            inst.sg.statemem.isphysicstoggle = true
            
            if data ~= nil then
                data = data.data
                if data ~= nil and
                    data.targetpos ~= nil and
                    data.weapon ~= nil and
                    data.weapon.components.aoeweapon_leap ~= nil and
                    inst.AnimState:IsCurrentAnimation("atk_leap_lag") then
                    ToggleOffPhysics(inst)
                    inst.Transform:SetEightFaced()
                    inst.AnimState:PlayAnimation("atk_leap")
                    inst.sg.statemem.startingpos = inst:GetPosition()
                    inst.sg.statemem.weapon = data.weapon
                    inst.sg.statemem.targetpos = data.targetpos
                    inst.sg.statemem.flash = 0
                    if inst.sg.statemem.startingpos.x ~= data.targetpos.x or inst.sg.statemem.startingpos.z ~= data.targetpos.z then
                        inst:ForceFacePoint(data.targetpos:Get())
                        inst.Physics:SetMotorVel(math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z, data.targetpos.x, data.targetpos.z)) / (12 * FRAMES), 0 ,0)
                    end
                    return
                end
            end
            --Failed
            inst.sg:GoToState("idle", true)
        end,

        onupdate = function(inst)
            if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                local c = math.min(1, inst.sg.statemem.flash)
                if inst.components.colouradder then
                    inst.components.colouradder:PushColour("leap", c,c,c, 0)
                end
            end
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")
                if inst.components.colouradder then
                    inst.components.colouradder:PushColour("leap", 0, .1, .1, 0)
                end
            end),
            TimeEvent(11 * FRAMES, function(inst)
                if inst.components.colouradder then
                    inst.components.colouradder:PushColour("leap", 0, .2, .2, 0)
                end
            end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.components.colouradder then
                    inst.components.colouradder:PushColour("leap", 0, .4, .4, 0)
                end
                ToggleOnPhysics(inst)
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)
                inst.components.bloomer:PushBloom("leap", "shaders/anim.ksh", -2)
                inst.components.colouradder:PushColour("leap", 0, 1, 1, 0)
                inst.sg.statemem.flash = 1.3
                inst.sg:RemoveStateTag("nointerrupt")
                if inst.sg.statemem.weapon:IsValid() then
                    inst.sg.statemem.weapon.components.aoeweapon_leap:DoLeap(inst, inst.sg.statemem.startingpos, inst.sg.statemem.targetpos)
                end
            end),
            TimeEvent(20 * FRAMES, function(inst)
                inst.components.bloomer:PopBloom("leap")
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
            end
            inst.Transform:SetFourFaced()
            inst.components.bloomer:PopBloom("leap")
            inst.components.colouradder:PopColour("leap")
            inst.components.health:SetInvincible(false)
        end,
    }
)

AddStategraphState("wilson_client", 
	State
    {
        name = "moyu_combat_leap_start",
        tags = { "doing", "busy", "nointerrupt", "noattack" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")
            inst.AnimState:PushAnimation("atk_leap_lag", false)
            --inst.SoundEmitter:PlaySound("fire_machete/attack/leap", nil, .7)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(8 * FRAMES)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    }
)]]



--连刺
--[[AddStategraphState("wilson", 
 State{
		name = "fire_machete_multithrust",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" },
		onenter = function(inst)
			local target = nil 
			inst.components.locomotor:Stop()
      inst.AnimState:PlayAnimation("multithrust")
      inst.SoundEmitter:PlaySound("fire_machete/attack/multithrust", nil, .5)
      inst.Transform:SetEightFaced()
			
			if inst.bufferedaction ~= nil and inst.bufferedaction.target ~= nil and inst.bufferedaction.target:IsValid() then
        inst.sg.statemem.target = inst.bufferedaction.target
        inst.components.combat:SetTarget(inst.sg.statemem.target)
        inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				target = inst.sg.statemem.target
      end

      if target ~= nil and target:IsValid() then
        inst.sg.statemem.target = target
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
      end

      inst.sg:SetTimeout(20 * FRAMES)
		end,
		timeline =
		{
			TimeEvent(7 * FRAMES, function(inst)
				  inst:PerformBufferedAction()
        end),
      TimeEvent(11 * FRAMES, function(inst)
			  	inst.sg.statemem.weapon = inst.components.combat:GetWeapon()
          inst:PerformBufferedAction()
          DoThrust(inst)
        end),
      TimeEvent(13 * FRAMES, DoThrust),
      TimeEvent(15 * FRAMES, DoThrust),
      TimeEvent(17 * FRAMES, DoThrust),
      TimeEvent(19 * FRAMES, DoThrust),
		},

    ontimeout = function(inst)
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
          end),
    },

    onexit = function(inst)
      inst.components.combat:SetTarget(nil)
      inst.Transform:SetFourFaced()
    end,
		
}
)


--跳劈
AddStategraphState("wilson", 
 State{
		name = "fire_machete_hop",
    tags = { "attack", "notalking", "abouttoattack", "autopredict","nointerrupt","noattack"},
		onenter = function(inst,nohopattack)
			local target = nil 
			inst.sg.statemem.nohopattack = nohopattack
			inst.components.locomotor:Stop()
      inst.components.health:SetInvincible(true)
			inst.AnimState:PlayAnimation("atk_leap")
      inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
      inst.SoundEmitter:PlaySound("fire_machete/attack/hop", nil, .6)
			
			if inst.bufferedaction ~= nil and inst.bufferedaction.target ~= nil and inst.bufferedaction.target:IsValid() then
        inst.sg.statemem.target = inst.bufferedaction.target
        inst.components.combat:SetTarget(inst.sg.statemem.target)
        inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				target = inst.sg.statemem.target
      end

      if target ~= nil and target:IsValid() then
        inst.sg.statemem.target = target
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
				inst.sg.statemem.targetpos = target:GetPosition()
      end
      inst.sg:SetTimeout(20 * FRAMES)
		end,
		
		onupdate = function(inst)
      if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
        inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
        local c = math.min(1, inst.sg.statemem.flash)
      end
    end,
		
		timeline =
		{
			TimeEvent(4 * FRAMES, function(inst)
        if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
          (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
          inst.sg.statemem.targetfx = nil
        end
      end),
      TimeEvent(9 * FRAMES, function(inst)
          inst.sg.statemem.add_color = {250/255, 156/255, 25/255}
          local r,g,b = unpack(inst.sg.statemem.add_color)
          inst.components.colouradder:PushColour("leap", r,g,b, 0)
        end),
      TimeEvent(12 * FRAMES, function(inst)
          ToggleOnPhysics(inst)
          inst.Physics:Stop()
          inst.Physics:SetMotorVel(0, 0, 0)
			  	inst.sg.statemem.flash = 1.3
          inst.sg:AddStateTag("busy")
          if not inst.sg.statemem.nohopattack then 
			  		inst:PerformBufferedAction()
            ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)
            inst.components.bloomer:PushBloom("leap", "shaders/anim.ksh", -2)
            inst.SoundEmitter:PlaySound("dontstarve/common/fireBurstLarge")
				  	if inst.components.combat.target then
              local weapon = inst.components.combat:GetWeapon()
              local target = inst.components.combat.target
              if weapon and weapon:HasTag("fire_machete") then
                weapon:SpawnFx(inst,target)
              end
            end
				  end
        end),
      TimeEvent(19 * FRAMES, function(inst)
          inst.sg:RemoveStateTag("busy")
          inst.components.bloomer:PopBloom("leap")
        end),
		},

    ontimeout = function(inst)
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
              inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
      inst.sg.statemem.nohopattack = nil 
      inst.components.combat:SetTarget(nil)
      inst.components.health:SetInvincible(false)
		  if inst.sg.statemem.isphysicstoggle then
        ToggleOnPhysics(inst)
        inst.Physics:Stop()
        inst.Physics:SetMotorVel(0, 0, 0)
      end
      inst.components.bloomer:PopBloom("leap")
      inst.components.colouradder:PopColour("leap")
      if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
        (inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
       end
    end,
		
}
)]]



--快划
AddStategraphState("wilson", 
 State{
		name = "jx_pan_lunge",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" ,"nointerrupt"},
		onenter = function(inst,data)
			local target = nil  
			inst.components.locomotor:Stop()
      inst.AnimState:PlayAnimation("lunge_pst")

			if inst.bufferedaction ~= nil and inst.bufferedaction.target ~= nil and inst.bufferedaction.target:IsValid() then
        inst.sg.statemem.target = inst.bufferedaction.target
        inst.components.combat:SetTarget(inst.sg.statemem.target)
        inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				target = inst.sg.statemem.target
      end
			if data and data.target then 
				target = data.target
			end 
      if target ~= nil and target:IsValid() then
        inst.sg.statemem.target = target
				inst.components.combat:SetTarget(target)
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
      end
			
      inst.SoundEmitter:PlaySound("fire_machete/attack/lunge")
			inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball",nil,nil,true)
			inst.components.bloomer:PushBloom("lunge", "shaders/anim.ksh", -2)
      inst.components.colouradder:PushColour("lunge", 0, 88/255, 189/255, 0) --蓝色
			inst.sg.statemem.flash = 0.8
      inst.sg:SetTimeout(8 * FRAMES)
		end,
		
		onupdate = function(inst)
      if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
        inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
        inst.components.colouradder:PushColour("lunge", 0, 88/255, 189/255, inst.sg.statemem.flash) -- 修改颜色滤镜的透明度
      end
    end,
		
		timeline =
		{
			TimeEvent(2 * FRAMES, function(inst)
          inst:PerformBufferedAction()
			  	if inst.components.combat.target then 
            inst.components.combat:DoAreaAttack(inst.components.combat.target,3, inst.components.combat:GetWeapon(), nil, nil, { "INLIMBO","wall", "companion", "character" })
          end
        end),
			TimeEvent(7 * FRAMES, function(inst)
          inst.components.bloomer:PopBloom("lunge")
        end),
		},

    ontimeout = function(inst)
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
              inst.sg:GoToState("idle")
            end
          end),
        
    },

    onexit = function(inst)
      inst.components.combat:SetTarget(nil)
      inst.components.bloomer:PopBloom("lunge")
      inst.components.colouradder:PopColour("lunge")
    end,
		
}
)

--挥砍
AddStategraphState("wilson", 
 State{
		name = "jx_pan_chop",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" ,"nointerrupt"},
		onenter = function(inst,data)
			local target = nil  
			inst.components.locomotor:Stop()
      inst.AnimState:PlayAnimation("atk_prop_pre")
      inst.AnimState:PushAnimation("atk_prop", false)

			if inst.bufferedaction ~= nil and inst.bufferedaction.target ~= nil and inst.bufferedaction.target:IsValid() then
        inst.sg.statemem.target = inst.bufferedaction.target
        inst.components.combat:SetTarget(inst.sg.statemem.target)
        inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				target = inst.sg.statemem.target
      end
			if data and data.target then 
				target = data.target
			end 
      if target ~= nil and target:IsValid() then
        inst.sg.statemem.target = target
				inst.components.combat:SetTarget(target)
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
      end
			
      inst.SoundEmitter:PlaySound("fire_machete/attack/lunge")
			inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball",nil,nil,true)
			inst.components.bloomer:PushBloom("lunge", "shaders/anim.ksh", -2)
      inst.components.colouradder:PushColour("lunge", 0, 88/255, 189/255, 0)
			inst.sg.statemem.flash = 0.8
      inst.sg:SetTimeout(10 * FRAMES)
		end,
		
		onupdate = function(inst)
      if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
        inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
        inst.components.colouradder:PushColour("lunge", 0, 88/255, 189/255, inst.sg.statemem.flash)
      end
    end,
		
		timeline =
		{
			TimeEvent(2 * FRAMES, function(inst)
          inst:PerformBufferedAction()
			  	if inst.components.combat.target then
            inst.components.combat:DoAreaAttack(inst.components.combat.target,3, inst.components.combat:GetWeapon(), nil, nil, { "INLIMBO","wall", "companion", "character" })
          end
        end),
			TimeEvent(7 * FRAMES, function(inst)
          inst.components.bloomer:PopBloom("lunge")
        end),
		},

    ontimeout = function(inst)
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
              inst.sg:GoToState("idle")
            end
          end),
        
    },

    onexit = function(inst)
      inst.components.combat:SetTarget(nil)
      inst.components.bloomer:PopBloom("lunge")
      inst.components.colouradder:PopColour("lunge")
    end,
		
}
)

--连刺
--[[AddStategraphState("wilson_client", 
 State{
		name = "fire_machete_multithrust",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" },
		onenter = function(inst)
      local buffaction = inst:GetBufferedAction()
			local target = buffaction ~= nil and buffaction.target or nil
			if inst.replica.combat ~= nil then
				inst.replica.combat:StartAttack()
			end
			inst.components.locomotor:Stop()
			inst.Transform:SetEightFaced()
			if target ~= nil then
				inst.AnimState:PlayAnimation("multithrust")
        inst.SoundEmitter:PlaySound("fire_machete/attack/multithrust", nil, .5)
				if buffaction ~= nil then
					inst:PerformPreviewBufferedAction()
					if buffaction.target ~= nil and buffaction.target:IsValid() then
						inst:FacePoint(buffaction.target:GetPosition())
						inst.sg.statemem.attacktarget = buffaction.target
					end
				end
				inst.sg:SetTimeout(20 * FRAMES)
			end 
		end,
		timeline =
		{
			TimeEvent(7 * FRAMES, function(inst)
			  	inst:ClearBufferedAction()
        end),
      TimeEvent(9 * FRAMES, function(inst)
          inst:ClearBufferedAction()
        end),
      TimeEvent(11 * FRAMES, function(inst)
          inst:ClearBufferedAction()
				  inst.sg:RemoveStateTag("abouttoattack")
        end),
      TimeEvent(19 * FRAMES, function(inst)
          inst.sg:RemoveStateTag("nointerrupt")
        end),
		},

    ontimeout = function(inst)
      inst.sg:RemoveStateTag("abouttoattack")
      inst.sg:RemoveStateTag("attack")
      inst.sg:AddStateTag("idle")
      inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("animqueueover", function(inst)
          if inst.AnimState:AnimDone() then
            inst.sg:GoToState("idle")
          end
        end),
    },

    onexit = function(inst)
      inst.Transform:SetFourFaced()
	  	if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
        inst.replica.combat:CancelAttack()
      end
    end,
		
}
)
--跳劈
AddStategraphState("wilson_client", 
 State{
		name = "fire_machete_hop",
    tags = { "attack", "notalking", "abouttoattack", "autopredict","noattack"},
		onenter = function(inst)
        local buffaction = inst:GetBufferedAction()
		    local target = buffaction ~= nil and buffaction.target or nil
        if inst.replica.combat ~= nil then
            inst.replica.combat:StartAttack()
        end
        inst.components.locomotor:Stop()
        
	    	if target ~= nil then
			    inst.AnimState:PlayAnimation("atk_leap")
          inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
          inst.SoundEmitter:PlaySound("fire_machete/attack/hop", nil, .6)
			
			    if buffaction ~= nil then
			     	inst:PerformPreviewBufferedAction()
			    	if buffaction.target ~= nil and buffaction.target:IsValid() then
				    	inst:FacePoint(buffaction.target:GetPosition())
				    	inst.sg.statemem.attacktarget = buffaction.target
			    	end
			    end
		    	inst.sg:SetTimeout(20 * FRAMES)
	    	end 
    end,
		timeline =
		{
			TimeEvent(12 * FRAMES, function(inst)
          inst:ClearBufferedAction()
			  	inst.sg:RemoveStateTag("abouttoattack")
        end),
		},

    ontimeout = function(inst)
		inst.sg:RemoveStateTag("abouttoattack")
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

	onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
            inst.replica.combat:CancelAttack()
        end
    end,
}
)]]


--快划
AddStategraphState("wilson_client", 
 State{
		name ="jx_pan_lunge",
    tags = { "attack", "notalking", "abouttoattack", "autopredict","nointerrupt" },
		onenter = function(inst,data)
        local buffaction = inst:GetBufferedAction()
		    local target = (buffaction ~= nil and buffaction.target) or (data and data.target) or nil 
        if inst.replica.combat ~= nil then
          inst.replica.combat:StartAttack()
        end
        inst.components.locomotor:Stop()
        
	    	if target ~= nil then
		    	inst:ForceFacePoint(target:GetPosition():Get())
		    	inst.AnimState:PlayAnimation("lunge_pst")
          inst.SoundEmitter:PlaySound("fire_machete/attack/lunge")
			    inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball",nil,nil,true)
		    	if buffaction ~= nil then
		    		inst:PerformPreviewBufferedAction()
				    if buffaction.target ~= nil and buffaction.target:IsValid() then
					    inst.sg.statemem.attacktarget = buffaction.target
			    	end
			    end
		    	inst.sg:SetTimeout(8 * FRAMES)
		    end 
    end,
		timeline =
		{
			TimeEvent(2 * FRAMES, function(inst)
          inst:ClearBufferedAction()
				  inst.sg:RemoveStateTag("abouttoattack")
        end),
		},

    ontimeout = function(inst)
		inst.sg:RemoveStateTag("abouttoattack")
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

	onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
            inst.replica.combat:CancelAttack()
        end
    end,
}
)

--挥砍
AddStategraphState("wilson_client", 
 State{
		name ="jx_pan_chop",
    tags = { "attack", "notalking", "abouttoattack", "autopredict","nointerrupt" },
		onenter = function(inst,data)
        local buffaction = inst:GetBufferedAction()
		    local target = (buffaction ~= nil and buffaction.target) or (data and data.target) or nil 
        if inst.replica.combat ~= nil then
          inst.replica.combat:StartAttack()
        end
        inst.components.locomotor:Stop()
        
	    	if target ~= nil then
		    	inst:ForceFacePoint(target:GetPosition():Get())
		    	inst.AnimState:PlayAnimation("atk_prop_pre")
          inst.AnimState:PushAnimation("atk_prop", false)
          inst.SoundEmitter:PlaySound("fire_machete/attack/lunge")
			    inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball",nil,nil,true)
		    	if buffaction ~= nil then
		    		inst:PerformPreviewBufferedAction()
				    if buffaction.target ~= nil and buffaction.target:IsValid() then
					    inst.sg.statemem.attacktarget = buffaction.target
			    	end
			    end
		    	inst.sg:SetTimeout(10 * FRAMES)
		    end 
    end,
		timeline =
		{
			TimeEvent(2 * FRAMES, function(inst)
          inst:ClearBufferedAction()
				  inst.sg:RemoveStateTag("abouttoattack")
        end),
		},

    ontimeout = function(inst)
		inst.sg:RemoveStateTag("abouttoattack")
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
        inst.sg:GoToState("idle", true)
    end,

    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

	onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
            inst.replica.combat:CancelAttack()
        end
    end,
}
)