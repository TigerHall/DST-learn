-- require("stategraphs/commonstates")

local function Moving(inst)
    local rand = math.random()
    -- if rand < 0.5 then
    --     inst.sg:GoToState("moving")
    -- else
    --     inst.sg:GoToState("moving3")
    -- end
    if rand < 0.7 then
        inst.sg:GoToState("moving")
    elseif rand < 0.85 then
        inst.sg:GoToState("moving2")
    elseif inst._tag_moving3 <= 0 then --不要连续出现，不然会像个游动的扇贝，哈哈哈
        inst.sg:GoToState("moving3")
    else
        inst.sg:GoToState("moving")
    end
end

local events = {
    -- CommonHandlers.OnLocomote(true, true),
    EventHandler("locomote", function(inst)
        if inst.sg:HasStateTag("busy") or inst._owner_s == nil or inst:HasTag("bookstay_l") then
            return
        end
        if inst.components.locomotor:WantsToMoveForward() and not inst.sg:HasStateTag("moving") then
            Moving(inst)
        end
    end),
    EventHandler("trytoheal", function(inst)
        if not inst.sg:HasStateTag("busy") and inst._owner_s ~= nil then
            inst.sg:GoToState("castspell", 3)
        end
    end),
    EventHandler("trytosharesouls", function(inst)
        if not inst.sg:HasStateTag("busy") and inst._owner_s ~= nil then
            inst.sg:GoToState("castspell", 2)
        end
    end),
    EventHandler("trytosharelvls", function(inst)
        if not inst.sg:HasStateTag("busy") and inst._owner_s ~= nil then
            inst.sg:GoToState("castspell", 1)
        end
    end),
    EventHandler("trytostay", function(inst)
        if inst.sg:HasStateTag("moving") then
            inst.sg:GoToState("idle")
        end
    end),
    EventHandler("trytoteleport", function(inst)
        if inst.sg:HasStateTag("busy") and not (inst.sg:HasStateTag("doing") or inst.sg:HasStateTag("jumpin")) then
            return
        end
        inst.sg:GoToState(inst:IsAsleep() and "jumpout" or "jumpin")
    end),
    EventHandler("ownerchange", function(inst)
        if inst._owner_s == nil then --没有签订者，不能活动了
            if not inst.sg:HasStateTag("closedbook") then
                inst.sg:GoToState("closing")
            end
        elseif inst.sg:HasStateTag("closedbook") then --有签订者了，该动起来了
            inst.sg:GoToState("opening")
        end
    end),
    EventHandler("trytoshowlvlup", function(inst)
        if inst:IsAsleep() or inst.sg:HasStateTag("jumpin") then
            return
        end
        local x, y, z = inst.Transform:GetWorldPosition()
        local fx = SpawnPrefab(inst._dd and inst._dd.lvlfx or "soulbook_lvlup_l_fx")
        if inst._owner_s ~= nil and inst._owner_s:IsValid() then --可以打断busy状态
            y = y + 1.5 --有签订者时，是漂浮的，位置要高一点
            inst.sg:GoToState("castspell", 4)
        end
        fx.Transform:SetPosition(x, y, z)
    end)
}

local function ChooseNextAction(inst)
    if inst._owner_s == nil or not inst._owner_s:IsValid() then --该变回未启用状态了
        inst.sg:GoToState("closing")
    elseif inst._needsharelvl then --需要分享等级
        inst.sg:GoToState("castspell", 1)
    elseif inst._needsharesoul then --需要分享灵魂
        inst.sg:GoToState("castspell", 2)
    elseif inst._needheal and inst._soulnum >= 1 then --需要范围回血
        inst.sg:GoToState("castspell", 3)
    elseif inst._needteleport then --需要传送
        inst.sg:GoToState(inst:IsAsleep() and "jumpout" or "jumpin")
    elseif inst:HasTag("bookstay_l") then --原地停留
        inst.sg:GoToState("idle")
    elseif inst.components.locomotor:WantsToMoveForward() then
        Moving(inst)
    else
        inst.sg:GoToState("idle")
    end
end

local states = {
    State{ name = "idle",
        tags = { "idle" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("proximity_loop", false)

            --暗影秘典的声音不太符合契约
            -- if not inst.SoundEmitter:PlayingSound("idlesound") then
            --     inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/active_LP", "idlesound", 0.5)
            -- end
            --灵魂的挣扎声
            if math.random() <= 0.25 then
                inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .2)
            end
        end,
        TimeEvent(12 * FRAMES, function(inst)
            if math.random() <= 0.3 then
                inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .2)
            end
        end),
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end)
        }
    },
    State{ name = "moving",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
            -- if inst.components.locomotor:WantsToRun() then
            --     inst.components.locomotor:RunForward()
            -- else
                inst.components.locomotor:WalkForward()
            -- end
            inst.AnimState:PlayAnimation("proximity_loop", false)
            if inst._tag_moving3 > 0 then
                inst._tag_moving3 = inst._tag_moving3 - 1
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.components.locomotor:WantsToMoveForward() then
                        Moving(inst)
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end)
        }
    },
    State{ name = "moving2",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("use", false)
            inst.AnimState:HideSymbol("pages")
            if inst._tag_moving3 > 0 then
                inst._tag_moving3 = inst._tag_moving3 - 1
            end
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.components.locomotor:WantsToMoveForward() then
                        Moving(inst)
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end)
        },
        onexit = function(inst)
            inst.AnimState:ShowSymbol("pages")
        end
    },
    State{ name = "moving3",
        tags = { "moving", "canrotate" },
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("proximity_pst", false)
        end,
        timeline = {
            TimeEvent(10*FRAMES, function(inst) --合上之后的那一刻
                inst.AnimState:Pause()
            end),
            TimeEvent(13*FRAMES, function(inst) --停留3帧，不然变化太快了
                inst.AnimState:Resume()
                inst.AnimState:SetDeltaTimeMultiplier(-1) --OMG!写成负数居然真的是倒放，非常不错呢！
            end),
            TimeEvent(22*FRAMES, function(inst) --大概倒放回原点了，可以结束了
                inst._tag_moving3 = 3
                if inst.components.locomotor:WantsToMoveForward() then
                    Moving(inst)
                else
                    inst.sg:GoToState("idle")
                end
            end)
        },
        onexit = function(inst)
            inst.AnimState:Resume()
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end
    },
    State{ name = "closing",
        tags = { "busy", "closingbook", "closedbook" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("proximity_pst", false)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        timeline = {
            TimeEvent(5 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/close")
            end),
            -- TimeEvent(6 * FRAMES, function(inst)
            --     inst.SoundEmitter:KillSound("idlesound")
            -- end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/drop")
            end)
        },
        ontimeout = function(inst)
            if inst._owner_s ~= nil and inst._owner_s:IsValid() then
                inst.sg:GoToState("opening")
            else
                inst.sg:GoToState("closed")
            end
        end
    },
    State{ name = "closed",
        tags = { "busy", "closedbook" },
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", false)
        end
    },
    State{ name = "opening",
        tags = { "busy", "openingbook" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("proximity_pre", false)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        ontimeout = ChooseNextAction
    },
    State{ name = "castspell",
        tags = { "busy", "doing" },
        onenter = function(inst, cmd)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("use", false)
            inst.AnimState:Hide("FX")
            inst.SoundEmitter:PlaySound("dontstarve/common/together/book_maxwell/use")
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            inst.sg.statemem.bookcmd = cmd
            -- if cmd == 3 and inst.components.locomotor:WantsToMoveForward() then --移动施法！可惜有"busy"标签，会让自动面向目标停止判定
            --     inst.components.locomotor:WalkForward()
            -- else
            --     inst.Physics:Stop()
            -- end
        end,
        timeline = {
            TimeEvent(0.3, function(inst)
                local cmd = inst.sg.statemem.bookcmd
                if cmd == 3 then --范围治疗
                    inst._needheal = nil
                    if inst._owner_s == nil or not inst._owner_s:IsValid() then
                        inst:DoHeal(nil, inst:GetPosition())
                    else
                        inst:DoHeal(nil, inst._owner_s:GetPosition())
                    end
                    if not inst:IsAsleep() then
                        local fx = SpawnPrefab(inst._dd and inst._dd.bookhealfx or "soulbook_l_fx")
                        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    end
                elseif cmd == 2 then --分享灵魂
                    inst:ShareSouls()
                    inst._needsharesoul = nil
                elseif cmd == 1 then --分享等级
                    inst:ShareLevel()
                    inst._needsharelvl = nil
                end
            end)
        },
        ontimeout = ChooseNextAction,
        onexit = function(inst)
            inst.sg.statemem.bookcmd = nil
        end
    },
    State{ name = "jumpin",
        tags = { "busy", "jumpin" },
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("noanim", false)
            local fx = SpawnPrefab(inst._dd and inst._dd.jumpinfx or "soulbook_jumpin_l_fx")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.sg:SetTimeout(11 * FRAMES)
        end,
        timeline = {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/infection_post", nil, .7)
                inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
            end)
        },
        ontimeout = function(inst)
            inst.sg:GoToState("jumpout")
        end
    },
    State{ name = "jumpout",
        tags = { "busy", "jumpout" },
        onenter = function(inst)
            inst.Physics:Stop()
            if inst._owner_s == nil or not inst._owner_s:IsValid() then
                inst.sg:GoToState("closing")
                return
            end
            local x, y, z = inst._owner_s.Transform:GetWorldPosition()
            local rad = 2+math.random()*3
            local the = math.random() * 2 * PI
            x = x + rad * math.cos(the)
            z = z - rad * math.sin(the)
            inst.sg.statemem.bookpos = { x = x, y = y+3, z = z, yy = y, step = 3/(18*FRAMES) }
            inst.Physics:Teleport(x, y+3, z)
            inst.AnimState:PlayAnimation("proximity_pre", false)
            local fx = SpawnPrefab(inst._dd and inst._dd.jumpoutfx or "soulbook_jumpout_l_fx")
            fx.Transform:SetPosition(x, y, z)

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,
        onupdate = function(inst)
            if inst.sg.statemem.bookpos ~= nil then
                local pos = inst.sg.statemem.bookpos
                pos.y = pos.y - pos.step
                if pos.y <= pos.yy then
                    inst.Physics:Teleport(pos.x, pos.yy, pos.z)
                    inst.sg.statemem.bookpos = nil
                else
                    inst.Physics:Teleport(pos.x, pos.y, pos.z)
                end
            end
        end,
        timeline = {
            TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out") end)
        },
        ontimeout = function(inst)
            inst._needteleport = nil
            ChooseNextAction(inst)
        end,
        onexit = function(inst)
            inst.sg.statemem.bookpos = nil
        end
    }
}

return StateGraph("soul_contracts", states, events, "opening")
