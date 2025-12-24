------------------------------ 秋千 ----------------------------------

local atbook_sitswing = _G.State {
     name = "atbook_sitswing",
     tags = { "busy", "pausepredict" },
     --sg执行
     onenter = function(inst, data)
          local buffaction = inst:GetBufferedAction()
          local target = buffaction ~= nil and buffaction.target or nil

          if target ~= nil then
               if target.prefab == "tbat_building_cherry_blossom_rabbit_swing" then
                    target.AnimState:PlayAnimation("swing_pre")
                    target.AnimState:PlayAnimation("swing_loop", true)
                    target.passenger = inst
                    target:AddTag("isusing")
                    if inst.Follower then
                         inst.Follower:FollowSymbol(target.GUID, "slot", 0, 0, 0, true)
                         inst.Follower:FollowSymbol(target.GUID, "slot", 0, 80, 0, true)
                         inst.swingprefab = target
                    end
                    inst:AddTag("debugnoattack")
                    inst:AddTag("notarget")
                    inst:AddTag("invisible")
                    inst:AddTag("noattack")
                    inst.Physics:SetActive(false)
                    -----------------------------------------------------------------------------------
                    inst.Transform:SetPredictedNoFaced()
                    inst.AnimState:SetBank("wilson_sit_nofaced")
                    inst.AnimState:PlayAnimation("sit1_loop", true)
                    -----------------------------------------------------------------------------------
                    if TheWorld.ismastersim then
                         local x, y, z = inst.Transform:GetWorldPosition()
                         local ents = TheSim:FindEntities(x, y, z, PLAYER_CAMERA_SEE_DISTANCE, { "_combat" },
                              { "INLIMBO" })
                         for index, value in ipairs(ents) do
                              if value.components.combat and value.components.combat.target == inst then
                                   value.components.combat:DropTarget()
                              end
                         end
                    end
               elseif target.prefab == "tbat_building_red_spider_lily_rocking_chair" then
                    target.AnimState:PlayAnimation("swing_pre")
                    target.AnimState:PlayAnimation("swing_loop", true)
                    target.passenger = inst
                    target:AddTag("isusing")
                    if inst.Follower then
                         inst.Follower:FollowSymbol(target.GUID, "slot", 0, 0, 0, true)
                         inst.Follower:FollowSymbol(target.GUID, "slot", 0, 0, 0, true)
                         inst.swingprefab = target
                    end
                    inst.Physics:SetActive(false)
                    -----------------------------------------------------------------------------------
                    inst.Transform:SetPredictedNoFaced()
                    inst.AnimState:PlayAnimation("atbook_sit3_pre")
                    inst.AnimState:PushAnimation("atbook_sit3_loop", true)
                    -----------------------------------------------------------------------------------
               end
               if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
               end
          end
     end,
     -- --sg结束
     timeline =
     {
          TimeEvent(1, function(inst)
               inst.sg:RemoveStateTag("busy")
               inst.sg:RemoveStateTag("pausepredict")
               inst:PerformBufferedAction()
          end),
     },

     onupdate = function(inst, dt)
          if TheWorld.ismastersim then
               if inst.components.health then
                    inst.components.health:DoDelta(1 * dt, true)
               end
               if inst.swingprefab and inst.swingprefab.prefab == "tbat_building_red_spider_lily_rocking_chair" and inst.components.sanity then
                    inst.components.sanity:DoDelta(3 * dt, true)
               end
               if inst.swingprefab and inst.swingprefab.prefab == "tbat_building_cherry_blossom_rabbit_swing" and inst.components.hunger then
                    inst.components.hunger.burnratemodifiers:SetModifier("tbat_building_cherry_blossom_rabbit_swing", 0)
               end
          end
     end,

     events =
     {
          EventHandler("onremove", function(inst)
               if inst.swingprefab then
                    inst.swingprefab:RemoveTag("isusing")
                    inst.swingprefab = nil
               end

               if inst.Follower then
                    inst.Follower:StopFollowing()
               end
          end),
     },

     onexit = function(inst)
          local x, y, z = inst.Transform:GetWorldPosition()
          inst:RemoveTag("debugnoattack")
          inst:RemoveTag("notarget")
          inst:RemoveTag("invisible")
          inst:RemoveTag("noattack")
          inst.Transform:ClearPredictedFacingModel()
          inst.AnimState:SetBank("wilson")

          if inst.Physics then
               inst.Physics:SetActive(true)
               inst.Physics:Teleport(x, 0, z)
          end

          if inst.components.hunger then
               inst.components.hunger.burnratemodifiers:RemoveModifier("tbat_building_cherry_blossom_rabbit_swing")
          end

          if inst.swingprefab and inst.swingprefab:IsValid() then
               inst.swingprefab.AnimState:PlayAnimation("idle", true)
               inst.swingprefab:RemoveTag("isusing")
               inst.swingprefab.passenger = nil
               inst.swingprefab = nil
          end

          if inst.Follower then
               inst.Follower:StopFollowing()
          end
     end,
}
--加入sg
AddStategraphState("wilson", atbook_sitswing)
AddStategraphState("wilson_client", atbook_sitswing)


------------------------------ 沙发 ----------------------------------

local atbook_sitsofa = _G.State {
     name = "atbook_sitsofa",
     tags = { "busy", "pausepredict" },
     --sg执行
     onenter = function(inst, data)
          local buffaction = inst:GetBufferedAction()
          local target = buffaction ~= nil and buffaction.target or nil

          if target ~= nil then
               if target.prefab == "tbat_building_rough_cut_wood_sofa" then
                    target.passenger = inst
                    target:AddTag("isusing")
                    if inst.Follower then
                         inst.sofaprefab = target
                         inst.Follower:FollowSymbol(target.GUID, "slot", 0, 0, 0, true)
                         local follower_offset = 80
                         if target:GetSkinName() == "tbat_wood_sofa_magic_broom" or target:GetSkinName() == "tbat_wood_sofa_sunbloom" then
                              follower_offset = 40
                         end
                         inst.Follower:FollowSymbol(target.GUID, "slot", 0, follower_offset, 0, true)
                    end
                    inst.Physics:SetActive(false)
                    -----------------------------------------------------------------------------------
                    inst.Transform:SetPredictedNoFaced()
                    -- 使用正面坐姿
                    if target:GetSkinName() == "tbat_wood_sofa_magic_broom" or target:GetSkinName() == "tbat_wood_sofa_sunbloom" then
                         inst.AnimState:PlayAnimation("atbook_sit3_loop", true)
                    else
                         inst.AnimState:SetBank("wilson_sit_nofaced")
                         inst.AnimState:PlayAnimation("sit1_loop", true)
                    end
               end
               if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
               end
          end
     end,
     -- --sg结束
     timeline =
     {
          TimeEvent(1, function(inst)
               inst.sg:RemoveStateTag("busy")
               inst.sg:RemoveStateTag("pausepredict")
               inst:PerformBufferedAction()
          end),
     },

     events =
     {
          EventHandler("onremove", function(inst)
               if inst.sofaprefab then
                    inst.sofaprefab:RemoveTag("isusing")
                    inst.sofaprefab = nil
               end

               if inst.Follower then
                    inst.Follower:StopFollowing()
               end
          end),
     },

     onexit = function(inst)
          local x, y, z = inst.Transform:GetWorldPosition()
          inst.Transform:ClearPredictedFacingModel()
          inst.AnimState:SetBank("wilson")

          if inst.Physics then
               inst.Physics:SetActive(true)
               inst.Physics:Teleport(x, 0, z)
          end

          if inst.sofaprefab and inst.sofaprefab:IsValid() then
               inst.sofaprefab:RemoveTag("isusing")
               inst.sofaprefab.passenger = nil
               inst.sofaprefab = nil
          end

          if inst.Follower then
               inst.Follower:StopFollowing()
          end
     end,
}
--加入sg
AddStategraphState("wilson", atbook_sitsofa)
AddStategraphState("wilson_client", atbook_sitsofa)
