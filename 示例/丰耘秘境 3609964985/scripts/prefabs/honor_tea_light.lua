local PULSE_SYNC_PERIOD = 30 -- 定义脉冲同步周期为30秒

-- 需要保存/加载存活时间。

local function kill_sound(inst) -- 杀死声音的函数
    inst.SoundEmitter:KillSound("staff_star_loop") -- 停止“staff_star_loop”声音
end

local function kill_light(inst) -- 杀死光源的函数
    inst.AnimState:PlayAnimation("post") -- 播放消失动画
    inst:ListenForEvent("animover", kill_sound) -- 监听动画结束事件，调用kill_sound
    inst:DoTaskInTime(1, inst.Remove) -- 延迟1秒后移除实例
    inst.persists = false -- 设置实例不持久化
    inst._killed = true -- 标记实例为已被杀死
end

local function ontimer(inst, data) -- 定时器事件处理函数
    if data.name == "extinguish" then -- 如果定时器名称为"extinguish"
        kill_light(inst) -- 杀死光源
    end
end

local function onpulsetimedirty(inst) -- 脉冲时间脏数据处理
    inst._pulseoffs = inst._pulsetime:value() - inst:GetTimeAlive() -- 计算脉冲偏移量
end

local function pulse_light(inst) -- 脉冲光源的函数
    local timealive = inst:GetTimeAlive() -- 获取实例存活时间

    if inst._ismastersim then -- 如果是主模拟器
        if timealive - inst._lastpulsesync > PULSE_SYNC_PERIOD then -- 检查时间间隔
            inst._pulsetime:set(timealive) -- 设置脉冲时间
            inst._lastpulsesync = timealive -- 更新上次脉冲同步时间
        else
            inst._pulsetime:set_local(timealive) -- 设置本地脉冲时间
        end

        inst.Light:Enable(true) -- 启用光源
    end

    -- 客户端光源调制启用：

    local s = math.abs(math.sin(PI * (timealive + inst._pulseoffs) * 0.05)) -- 计算正弦值
    local rad = Lerp(11, 12, s) -- 线性插值计算半径
    local intentsity = Lerp(0.8, 0.7, s) -- 线性插值计算光强
    local falloff = Lerp(0.8, 0.7, s) -- 线性插值计算衰减
    inst.Light:SetFalloff(falloff) -- 设置光源衰减
    inst.Light:SetIntensity(intentsity) -- 设置光源强度
    inst.Light:SetRadius(rad) -- 设置光源半径
end

local function onhaunt(inst) -- 处理惊吓事件的函数
    if inst.components.timer:TimerExists("extinguish") then -- 如果存在“extinguish”定时器
        inst.components.timer:StopTimer("extinguish") -- 停止“extinguish”定时器
        kill_light(inst) -- 杀死光源
    end
    return true
end

local function MakeTeaLight(name, color, multcolor, notmastersimfn, ismastersimfn) -- 定义函数
    
    local assets = -- 定义资源
    {
        Asset("ANIM", "anim/flameball_fx.zip"), -- 动画资源
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        inst._ismastersim = TheWorld.ismastersim
        inst._pulseoffs = 0 -- 初始化脉冲偏移量
        inst._pulsetime = net_float(inst.GUID, "_pulsetime", "pulsetimedirty") -- 初始化网络脉冲时间

        -- inst.scrapbook_persishable = name == "emberlight" and TUNING.EMBER_STAR_DURATION or is_hot and TUNING.YELLOWSTAFF_STAR_DURATION or TUNING.OPALSTAFF_STAR_DURATION -- 设置可消耗时间
        -- inst.scrapbook_anim = "idle_loop" -- 设置动画状态

        inst:DoPeriodicTask(.1, pulse_light)
        inst.Light:SetColour(unpack(color))
        inst.Light:Enable(false)
        inst.Light:EnableClientModulation(true) -- 启用客户端光源调制

        inst.AnimState:SetMultColour(unpack(multcolor))
        inst.AnimState:SetBank("flameball_fx")
        inst.AnimState:SetBuild("flameball_fx")
        inst.AnimState:PlayAnimation("pre")
        inst.AnimState:PushAnimation("idle_loop", true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh") -- 设置动画的辉光效果

        -- HASHEATER (来自加热器组件) 添加到原始状态以优化
        inst:AddTag("HASHEATER") -- 添加标签

        inst:AddTag("ignorewalkableplatforms") -- 添加标签以忽略可行走平台
        inst:SetPhysicsRadiusOverride(.5) -- 设置物理半径
        inst.no_wet_prefix = true -- 设置不可湿润前缀

        notmastersimfn(inst) -- 非主模拟器处理函数
        -- if is_hot then -- 如果是热的光源
        --     inst:AddTag("cooker") -- 添加烹饪标签
        --     inst:AddTag("daylight") -- 添加阳光标签
        --     inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_LP", "staff_star_loop", nil, not inst._ismastersim) -- 播放声音
        -- else -- 如果是冷光源
        --     inst.SoundEmitter:PlaySound("dontstarve/common/staff_coldlight_LP", "staff_star_loop", nil, not inst._ismastersim) -- 播放冷光源声音
        -- end

        inst.entity:SetPristine() -- 设置实体为原始状态

        if not inst._ismastersim then -- 如果不是主模拟器
            inst:ListenForEvent("pulsetimedirty", onpulsetimedirty) -- 监听脉冲时间脏事件
            return inst -- 返回实例
        end

        inst._pulsetime:set(inst:GetTimeAlive()) -- 设置脉冲时间为存活时间
        inst._lastpulsesync = inst._pulsetime:value() -- 更新最后脉冲同步时间

        -- if is_hot then -- 如果是热的光源
        --     inst:AddComponent("cooker") -- 添加烹饪组件
        --     inst:AddComponent("propagator") -- 添加传播者组件
        --     inst.components.propagator.heatoutput = 15 -- 设置热输出
        --     inst.components.propagator.spreading = true -- 启用传播
        --     inst.components.propagator:StartUpdating() -- 开始更新
        -- end

        -- inst:AddComponent("heater") -- 添加加热器组件
        -- if is_hot then
        --     inst.components.heater.heat = 100 -- 热源热量设置
        -- else
        --     inst.components.heater.heat = -100 -- 冷源热量设置
        --     inst.components.heater:SetThermics(false, true) -- 设置热学参数
        -- end

        inst:AddComponent("sanityaura") -- 添加精神光环组件
        inst.components.sanityaura.aura = TUNING.SANITYAURA_SMALL -- 设置精神光环值

        inst:AddComponent("inspectable")
        inst:AddComponent("hauntable") -- 添加惊吓组件
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL) -- 设置惊吓值
        inst.components.hauntable:SetOnHauntFn(onhaunt) -- 设置惊吓回调函数

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("extinguish", name == "honor_greentea_light" and TUNING.OPALSTAFF_STAR_DURATION or TUNING.YELLOWSTAFF_STAR_DURATION) -- 启动灭火定时器
        inst:ListenForEvent("timerdone", ontimer) -- 定时结束，删除实例

        inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_create") -- 播放创建光源声音

        ismastersimfn(inst) -- 主模拟器处理函数

        return inst
    end
    return Prefab(name, fn, assets) -- 返回预制体

end



----------------------------------------------------------------------------
--- 绿茶法球
----------------------------------------------------------------------------
-- 增加移速/防火
local function greentea_notmastersim(inst) -- 绿茶光源非主模拟器处理函数
    inst:AddTag("cooker") -- 添加烹饪标签
    inst:AddTag("daylight") -- 添加阳光标签
    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_LP", "staff_star_loop", nil, not inst._ismastersim) -- 播放声音    
end

local function greentea_ismastersim(inst) -- 绿茶光源主模拟器处理函数
    local range = 10
    inst:AddComponent("heater") -- 添加加热器组件
    inst.components.heater.heat = -10 -- 冷源热量设置
    inst.components.heater:SetThermics(true, true) -- 设置热学参数（是否向周围散发热量/是否吸收周围热量）

    inst:DoPeriodicTask(.2, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, range)
        for k, target in pairs(ents) do
            if target:HasTag("player") and not target:HasTag("honor_greentea_buffed") then
                target:AddTag("honor_greentea_buffed")
                target.oldwalkspeed = target.components.locomotor.walkspeed
                target.components.locomotor.walkspeed = target.oldwalkspeed * 1.2
                target.oldrunspeed = target.components.locomotor.runspeed
                target.components.locomotor.runspeed = target.oldrunspeed * 1.2

                target.oldfire_damage_scale = target.components.health.fire_damage_scale
                target.components.health.fire_damage_scale = 0

                target.greentealightfx = SpawnPrefab("honor_tea_light_fx")
                target.greentealightfx.MakeFormation(target.greentealightfx, target)

                target.greentea_task = target:DoPeriodicTask(0.2, function()
                    local distsq = target:GetDistanceSqToInst(inst)
                    if distsq > range ^ 2 then
                        target.components.locomotor.walkspeed = target.oldwalkspeed
                        target.components.locomotor.runspeed = target.oldrunspeed

                        target.components.health.fire_damage_scale = target.oldfire_damage_scale
                        target:RemoveTag("honor_greentea_buffed")

                        target.greentealightfx.Killfx(target.greentealightfx)

                        target.greentea_task:Cancel()
                    end
                end)
            end
        end
    end)
end

----------------------------------------------------------------------------
--- 大红袍法球
----------------------------------------------------------------------------
-- 大幅增加伤害/防火/防水
local function dhp_notmastersim(inst)
    inst:AddTag("cooker")
    inst:AddTag("daylight")
    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_LP", "staff_star_loop", nil, not inst._ismastersim) -- 播放声音
end

local function dhp_ismastersim(inst)
    local range = 10
    inst:AddComponent("heater")
    inst.components.heater.heat = 40
    inst.components.heater:SetThermics(true, true) -- 设置热学参数（是否向周围散发热量/是否吸收周围热量）

    inst:AddComponent("cooker")

    inst:DoPeriodicTask(.2, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, range)
        for k, target in pairs(ents) do
            if target:HasTag("player") and not target:HasTag("honor_dhp_buffed") then
                target:AddTag("honor_dhp_buffed")
                target.olddamage = target.components.combat.externaldamagemultipliers:Get()
                target.components.combat.externaldamagemultipliers:SetModifier(inst, target.olddamage * 1.4)

                target.oldfire_damage_scale = target.components.health.fire_damage_scale
                target.components.health.fire_damage_scale = 0

                if not target.components.moistureimmunity then
                    target:AddComponent("moistureimmunity")
                end
                target.components.moistureimmunity:AddSource(inst)

                target.dhp_task = target:DoPeriodicTask(0.2, function()
                    local distsq = target:GetDistanceSqToInst(inst)
                    if distsq > range ^ 2 then
                        target.components.combat.externaldamagemultipliers:SetModifier(inst, target.olddamage)
                        target.components.health.fire_damage_scale = target.oldfire_damage_scale
                        if target.components.moistureimmunity then
                            target.components.moistureimmunity:RemoveSource(inst)
                        end
                        target:RemoveTag("honor_dhp_buffed")
                        target.dhp_task:Cancel()
                    end
                end)
            end
        end
    end)
end

----------------------------------------------------------------------------
--- 茉莉花法球
----------------------------------------------------------------------------
-- 增加从食物获得的收益/提升生命上限
local function jasmine_notmastersim(inst)
    inst:AddTag("cooker")
    inst:AddTag("daylight")
    inst.SoundEmitter:PlaySound("dontstarve/common/staff_star_LP", "staff_star_loop", nil, not inst._ismastersim) -- 播放声音
end

local function jasmine_ismastersim(inst)
    local range = 10
    inst:AddComponent("heater")
    inst.components.heater.heat = 10
    inst.components.heater:SetThermics(true, true) -- 设置热学参数（是否向周围散发热量/是否吸收周围热量）

    inst:DoPeriodicTask(.2, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, range)
        for k, target in pairs(ents) do
            if target:HasTag("player") and not target:HasTag("honor_jasmine_buffed") then
                target:AddTag("honor_jasmine_buffed")

                target.oldhealthabsorption = target.components.eater.healthabsorption
                target.oldhungerabsorption = target.components.eater.hungerabsorption
                target.oldsanityabsorption = target.components.eater.sanityabsorption

                if target.prefab == "wormwood" then
                    target.components.eater:SetAbsorptionModifiers(0.5, 1.5, 1.5)
                else
                    target.components.eater:SetAbsorptionModifiers(1.4, 1.4, 1.4)
                end

                target.oldmaxhealth = target.components.health.maxhealth
                local healthpercent = target.components.health:GetPercent()

                target.components.health:SetMaxHealth(target.oldmaxhealth * 1.2)
                target.components.health:SetPercent(healthpercent * 1.2, 0)

                target.jasmine_task = target:DoPeriodicTask(0.2, function()
                    local distsq = target:GetDistanceSqToInst(inst)
                    if distsq > range ^ 2 then
                        target.components.eater:SetAbsorptionModifiers(target.oldhealthabsorption, target.oldhungerabsorption, target.oldsanityabsorption)

                        local healthpercent = target.components.health:GetPercent()
                        target.components.health:SetPercent(healthpercent, 0)
                        target.components.health:SetMaxHealth(target.oldmaxhealth)

                        target:RemoveTag("honor_jasmine_buffed")
                        target.jasmine_task:Cancel()
                    end
                end)
            end
        end
    end)
end

return MakeTeaLight("honor_greentea_light", { 144 / 255, 238 / 255, 144 / 255 }, {144 / 255, 238 / 255, 144 / 255, 1}, greentea_notmastersim, greentea_ismastersim),
       MakeTeaLight("honor_dhp_light", { 255 / 255, 128 / 255, 0 / 255 }, {255 / 255, 128 / 255, 0 / 255, 1}, dhp_notmastersim, dhp_ismastersim),
       MakeTeaLight("honor_jasmine_light", { 255 / 255, 182 / 255, 193 / 255 }, {255 / 255, 182 / 255, 193 / 255, 1}, jasmine_notmastersim, jasmine_ismastersim)