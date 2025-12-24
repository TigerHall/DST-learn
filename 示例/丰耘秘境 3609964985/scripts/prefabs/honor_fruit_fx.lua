local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

-- 定义纹理和着色器
local TEXTURE = {
    COCONUT = resolvefilepath("images/fx/honor_fruit_coconut.tex"),
    -- GREENTEA = "images/fx/honor_fruit_greentea.tex",
    -- DHP = "images/fx/honor_fruit_dhp.tex",
    -- JASMINE = "images/fx/honor_fruit_jasmine.tex"
}
local SHADER = "shaders/vfx_particle.ksh"

local function MakeFruitFx(name, texture)
    local assets =
    {
        Asset("IMAGE", texture),
        Asset("SHADER", SHADER),
    }

    local function InitEnvelope()

        -- 添加三条颜色封包，分别用于不同效果
        EnvelopeManager:AddColourEnvelope(name.."_colourenvelope0",
            {
                { 0, IntColour(255, 0, 0, 255) },  -- 开始状态的颜色
                { 0.5, IntColour(255, 0, 0, 255) }, -- 中间状态的颜色
                { 1, IntColour(255, 0, 0, 0) },     -- 结束状态的颜色
            }
        )

        EnvelopeManager:AddColourEnvelope(name.."_colourenvelope1",
            {
                { 0, IntColour(255, 255, 255, 255) },
                { 0.5, IntColour(255, 255, 255, 255) },
                { 1, IntColour(255, 255, 255, 0) },
            }
        )

        EnvelopeManager:AddColourEnvelope(name.."_colourenvelope2",
            {
                { 0, IntColour(233, 224, 44, 255) },
                { 0.5, IntColour(233, 224, 44, 255) },
                { 1, IntColour(233, 224, 44, 0) },
            }
        )

        -- 初始化缩放封包
        local envs = {}

        local max_scale = .7    -- 最大缩放
        local end_scale = .4    -- 最小缩放
        local t = 0
        local step = .2
        while t + step < 1 do
            local s = Lerp(max_scale, end_scale, Clamp(2*t - 0.5, 0, 1))
            table.insert(envs, { t, { s * 0.25, s } }) -- 插入缩放值
            t = t + step

            local s = Lerp(max_scale, end_scale, Clamp(2*t - 0.5, 0, 1))
            table.insert(envs, { t, { s, s * 0.2 } }) -- 插入另一组缩放值
            t = t + step
        end
        table.insert(envs, { 1, { max_scale, max_scale * 0.6 } }) -- 添加结束缩放值

        -- 添加缩放封包到 EnvelopeManager 中
        EnvelopeManager:AddVector2Envelope(name.."_scaleenvelope", envs)

        -- 清理初始化函数和颜色函数的引用
        InitEnvelope = nil
        IntColour = nil
    end
    --------------------------------------------------------------------------

    local MAX_LIFETIME = 2.0 -- 定义粒子的最大生命周期

    -- 函数：发射玫瑰效果
    local function emit_rose_fn(effect, i, spark_sphere_emitter)
        local lifetime = MAX_LIFETIME * (.5 + UnitRand() * .5) -- 随机生命周期
        local px, py, pz = spark_sphere_emitter() -- 获取发射器位置
        local vx, vy, vz = px * 0.3, -0.1 + py * 0.25, pz * 0.3 -- 计算速度

        local angle = math.random() * 360 -- 随机角度
        local uv_offset = math.random(0, 7) / 8 -- 随机 UV 偏移
        local ang_vel = (UnitRand() - 1) * 5 -- 随机角速度

        -- 添加旋转的粒子到效果中
        effect:AddRotatingParticleUV(
            i,
            lifetime,           -- 生命周期
            px, py, pz,         -- 位置
            vx, vy, vz,         -- 速度
            angle, ang_vel,     -- 角度，角速度
            uv_offset, 0        -- UV 偏移
        )
    end

    -- 主函数：创建粒子效果实体
    local function fn()
        local inst = CreateEntity() -- 创建新实体

        inst.entity:AddTransform()  -- 添加变换组件
        inst.entity:AddNetwork()    -- 添加网络组件

        inst:AddTag("FX") -- 添加特效标签

        inst.entity:SetPristine() -- 设置 pristine 状态

        inst.persists = false -- 设置实体不持久化

        -- 如果是专用服务器，则不需要生成本地粒子特效
        if TheNet:IsDedicated() then
            return inst
        elseif InitEnvelope ~= nil then
            InitEnvelope() -- 初始化封包
        end

        local effect = inst.entity:AddVFXEffect() -- 添加粒子效果
        effect:InitEmitters(6) -- 初始化发射器数量

        local num_emitters = 2 -- 定义发射器数量
        for i=0,num_emitters do
            effect:SetRenderResources(i, texture, SHADER) -- 设置纹理和着色器
            effect:SetRotationStatus(i, true) -- 设置旋转状态
            effect:SetUVFrameSize(i, 1, 1) -- 设置 UV 帧大小
            effect:SetMaxNumParticles(i, 200) -- 设置最大粒子数量
            effect:SetMaxLifetime(i, MAX_LIFETIME) -- 设置最大生命周期
            effect:SetColourEnvelope(i, name.."_colourenvelope"..i) -- 设置颜色封包
            effect:SetScaleEnvelope(i, name.."_scaleenvelope") -- 设置缩放封包
            effect:SetBlendMode(i, BLENDMODE.Premultiplied) -- 设置混合模式
            effect:EnableBloomPass(i, true) -- 启用Bloom效果
            effect:SetSortOrder(i, 0) -- 设置排序顺序
            effect:SetSortOffset(i, 0) -- 设置排序偏移
            effect:SetGroundPhysics(i, true) -- 启用地面物理

            effect:SetAcceleration(i, 0, -0.2, 0) -- 设置加速度
            effect:SetDragCoefficient(i, .1) -- 设置阻力系数
        end

        -----------------------------------------------------

        local tick_time = TheSim:GetTickTime() -- 获取每个 tick 的时间

        -- 定义粒子每秒想要的数量范围
        local sparkle_desired_pps_low = 0
        local sparkle_desired_pps_high = 15
        local low_per_tick = sparkle_desired_pps_low * tick_time -- 低数量每 tick
        local high_per_tick = sparkle_desired_pps_high * tick_time -- 高数量每 tick
        local num_to_emit = 0

        local sphere_emitter = CreateSphereEmitter(.25) -- 创建球形发射器
        inst.last_pos = inst:GetPosition() -- 获取实体上一次位置

        -- 添加发射器管理器
        EmitterManager:AddEmitter(inst, nil, function()
            local dist_moved = inst:GetPosition() - inst.last_pos -- 计算移动距离
            local move = dist_moved:Length()
            move = math.clamp((move - 0.2) * 10, 0, 1) -- 限制移动值在0到1之间

            local per_tick = Lerp(low_per_tick, high_per_tick, move) -- 计算每个 tick 发射的粒子数量

            inst.last_pos = inst:GetPosition() -- 更新上一个位置

            for i = 0, num_emitters do
                local num_to_emit = per_tick -- 每个发射器请求发射的粒子数量
                while num_to_emit > 0 do
                    emit_rose_fn(effect, i, sphere_emitter) -- 发射粒子
                    num_to_emit = num_to_emit - 1 -- 减少数量
                end
            end
        end)

        return inst -- 返回创建的实例
    end

    return Prefab(name, fn, assets)
end

-- 注册 prefab
return MakeFruitFx("honor_fruit_coconut_fx", TEXTURE.COCONUT)
