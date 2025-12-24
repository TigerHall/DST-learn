--定时器结束
local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end
--存储
local function onsave(inst,data)
    data.buff_layer = inst.buff_layer--buff层数
end
--加载
local function onload(inst,data)
    inst.buff_layer = data.buff_layer
end

--生成buff
local function MakeBuff(defs)
    --附加Buff函数
	local function OnAttached(inst, target,followsymbol, followoffset, data)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        if data then
            local extend_duration = defs.duration
            --自定义buff时长
            if data.add_duration and data.add_duration > 0 then
                extend_duration = data.add_duration
            --时长倍率
            elseif data.duration_mult then
                extend_duration = extend_duration * data.duration_mult
            --特殊函数,具体多少自己算
            elseif data.special_durationfn then
                extend_duration = data.special_durationfn(extend_duration, 0)
            end
            --实际时长和原本时长不同时才需要执行
            if extend_duration ~= defs.duration then
                inst.components.timer:StopTimer("buffover")
                inst.components.timer:StartTimer("buffover", extend_duration)
            end
        end

		--获得buff提示
		if defs.priority then
			target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_"..string.upper(defs.name), priority = defs.priority })
		end
        if defs.onattachedfn ~= nil then
            defs.onattachedfn(inst, target, data)
        end
    end

    --延长buff函数
	local function OnExtended(inst, target,followsymbol, followoffset, data)
        local extend_duration = defs.duration
        local timer_left=inst.components.timer:GetTimeLeft("buffover")--获取定时器剩余时间dd
        if data and timer_left then
			--时长倍率
            if data.duration_mult then
                --默认情况下不叠时长,所以在duration_mult<1时要确保添加buff时不会降低原本的时长,延长的时长不能超过倍率限制
                extend_duration = math.max(extend_duration * data.duration_mult, timer_left)
            end

            --增加时长(无视上限)
            if data.add_duration and data.add_duration > 0 then
                extend_duration = timer_left + data.add_duration
            --延长时间而不是直接用原来的固定时间替换(max_duration_mult即为最大时长倍数,由于该算法有边际递减的效果,一般时长加到最大倍数的50%会更划算)
            elseif data.max_duration_mult then
                extend_duration = math.min(extend_duration + math.ceil(timer_left * (1 - 1 / data.max_duration_mult)), extend_duration * data.max_duration_mult)
            --消耗时间
            elseif data.consume_duration then
                extend_duration = math.max(0, timer_left - data.consume_duration)
            --或者自定义一个计算函数？是增是减随便咯
            elseif data.special_durationfn then
                extend_duration = data.special_durationfn(extend_duration, timer_left)
            end
		--没有特殊处理参数的情况下,新的时长不应该低于原本的时长(防止玩家在不满足叠时长的情况下加一次buff一朝回到解放前)
        elseif timer_left and timer_left > extend_duration then
            extend_duration = timer_left
        end
		inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", extend_duration)
        --延长的时候才执行以下内容,否则就是减少Buff时长
        if timer_left==nil or extend_duration >= timer_left then
            --获得buff提示
            if defs.priority then
                target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_"..string.upper(defs.name), priority = defs.priority })
            end
            --onextendedfn方法和onattachedfn相同
            if defs.same_extended and defs.onattachedfn ~= nil then
                defs.onattachedfn(inst, target, data)
            elseif defs.onextendedfn ~= nil then
                defs.onextendedfn(inst, target, data)
            end
        end
    end

    --解除buff函数
	local function OnDetached(inst, target)
        if defs.ondetachedfn ~= nil then
            defs.ondetachedfn(inst, target)
        end
		--失去buff提示
		if defs.priority then
			target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_"..string.upper(defs.name), priority = defs.priority })
		end
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")
        
        inst.maxlayers = defs.maxlayers--最大叠加层数
        inst.maxlayerfn = defs.maxlayerfn--满层回调

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)--设置附加Buff时执行的函数
        inst.components.debuff:SetDetachedFn(OnDetached)--设置解除buff时执行的函数
        inst.components.debuff:SetExtendedFn(OnExtended)--设置延长buff时执行的函数
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")--添加定时器
        inst.components.timer:StartTimer("buffover", defs.duration)
        inst:ListenForEvent("timerdone", OnTimerDone)--监听定时器结束并触发结束

        inst.OnSave = onsave 
        inst.OnLoad = onload

        return inst
    end

    return Prefab(defs.name, fn, nil, defs.prefabs)
end

local medal_buffs={}
for k, v in pairs(require("medal_defs/medal_buff_defs")) do
    table.insert(medal_buffs, MakeBuff(v))
end
return unpack(medal_buffs)
