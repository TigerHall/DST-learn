local image = resolvefilepath("images/inventoryimages/honor_natural_splendor.tex")
     -- 这里一定要用 resolvefilepath() 包装一下，否则会出现找不到贴图的错误
local REVEAL_SHADER = "shaders/vfx_particle_reveal.ksh" -- 系统里的一个shader，跟渲染有关，具体原理不是太清楚


local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local color = {
    common ={
        { 0,    IntColour(255, 228, 196, 160) },  -- 米黄色（稍微透明）
        { .19,  IntColour(255, 228, 196, 160) },  -- 米黄色（稍微透明）
        { .35,  IntColour(140, 80, 50, 80) },      -- 青铜（透明度80）
        { .51,  IntColour(140, 80, 50, 60) },      -- 青铜（透明度60）
        { .75,  IntColour(140, 80, 50, 40) },      -- 青铜（透明度40）
        { 1,    IntColour(140, 80, 50, 0) },       -- 青铜（透明度0，完全透明）
    },
    empty = {
        { 0,    IntColour(255, 228, 196, 160) },  -- 米黄色（稍微透明）
        { .19,  IntColour(255, 228, 196, 160) },  -- 米黄色（稍微透明）
        { .35,  IntColour(140, 80, 50, 80) },      -- 青铜（透明度80）
        { .51,  IntColour(140, 80, 50, 60) },      -- 青铜（透明度60）
        { .75,  IntColour(140, 80, 50, 40) },      -- 青铜（透明度40）
        { 1,    IntColour(140, 80, 50, 0) },       -- 青铜（透明度0，完全透明）
    },
    wheat = {
        { 0,    IntColour(135, 206, 250, 160) },  -- 天蓝色（稍微透明）
        { .19,  IntColour(135, 206, 250, 160) },  -- 天蓝色（稍微透明）
        { .35,  IntColour(135, 206, 250, 80) },   -- 天蓝色（透明度80）
        { .51,  IntColour(135, 206, 250, 60) },   -- 天蓝色（透明度60）
        { .75,  IntColour(135, 206, 250, 40) },   -- 天蓝色（透明度40）
        { 1,    IntColour(135, 206, 250, 0) },    -- 天蓝色（透明度0，完全透明）
    },
    rice = {
        { 0,    IntColour(255, 215, 0, 160) },  -- 金黄色（稍微透明）
        { .19,  IntColour(255, 215, 0, 160) },  -- 金黄色（稍微透明）
        { .35,  IntColour(255, 215, 0, 80) },   -- 金黄色（透明度80）
        { .51,  IntColour(255, 215, 0, 60) },   -- 金黄色（透明度60）
        { .75,  IntColour(255, 215, 0, 40) },   -- 金黄色（透明度40）
        { 1,    IntColour(255, 215, 0, 0) },    -- 金黄色（透明度0，完全透明）
    },
    greentea = {
        { 0,    IntColour(144, 238, 144, 160) },  -- 嫩绿色（稍微透明）
        { .19,  IntColour(144, 238, 144, 160) },  -- 嫩绿色（稍微透明）
        { .35,  IntColour(173, 255, 47, 80) },    -- 浅黄色绿色（透明度80）
        { .51,  IntColour(255, 255, 224, 60) },   -- 浅黄绿色（透明度60）
        { .75,  IntColour(255, 255, 224, 40) },   -- 浅黄绿色（透明度40）
        { 1,    IntColour(255, 255, 224, 0) },    -- 浅黄绿色（完全透明）
    },
    dhp = {
        { 0,    IntColour(255, 0, 0, 160) },         -- 酒红色（稍微透明）
        { .19,  IntColour(255, 100, 100, 160) },     -- 浅酒红色（稍微透明）
        { .35,  IntColour(255, 150, 150, 120) },     -- 浅酒红色渐变（透明度120）
        { .51,  IntColour(255, 200, 180, 60) },      -- 米白色（透着酒红色，透明度60）
        { .75,  IntColour(255, 230, 220, 40) },      -- 浅米白色（透明度40）
        { 1,    IntColour(255, 255, 255, 0) },       -- 完全透明的米白色
    },
    jasmine = {
        { 0,    IntColour(255, 192, 203, 160) },  -- 桃花花瓣浅粉色（稍微透明）
        { .19,  IntColour(255, 192, 203, 160) },  -- 桃花花瓣浅粉色（稍微透明）
        { .35,  IntColour(255, 210, 200, 80) },   -- 淡浅粉色（透明度80）
        { .51,  IntColour(255, 220, 200, 60) },   -- 淡浅粉米黄色（透明度60）
        { .75,  IntColour(255, 228, 196, 40) },   -- 淡米黄色（透明度40）
        { 1,    IntColour(255, 228, 196, 0) },    -- 淡米黄色（完全透明）
    },
    coconut = {
        { 0,    IntColour(139, 69, 19, 160) },  -- 棕褐色（稍微透明）
        { .19,  IntColour(139, 69, 19, 160) },  -- 棕褐色（稍微透明）
        { .35,  IntColour(205, 133, 63, 80) },  -- 椰子灰（透明度80）
        { .51,  IntColour(210, 180, 140, 60) }, -- 椰子灰（透明度60）
        { .75,  IntColour(222, 184, 135, 40) }, -- 椰子灰（透明度40）
        { 1,    IntColour(244, 164, 96, 0) },   -- 椰子灰（完全透明）
    },
}

    --------------------------------------------------------------------------

local function MakeFx(name, color)

    local function InitEnvelope(name, color)
        EnvelopeManager:AddColourEnvelope(name.."_colourenvelope", color)

        local glow_max_scale = .3
        EnvelopeManager:AddVector2Envelope(
            name.."_scaleenvelope",
            {
                { 0,    { glow_max_scale * 0.7, glow_max_scale * 0.7 } },
                { .55,  { glow_max_scale * 1.2, glow_max_scale * 1.2 } },
                { 1,    { glow_max_scale * 1.3, glow_max_scale * 1.3 } },
            }
        )

        InitEnvelope = nil
        IntColour = nil
    end

    --------------------------------------------------------------------------
    local GLOW_MAX_LIFETIME = 1

    -- 粒子触发器里第三个参数fn里调用的方法，展示粒子大小，方向，速度，生命周期等等信息
    local function emit_glow_fn(effect, emitter_fn)
        local vx, vy, vz = .005 * UnitRand(), 0, .005 * UnitRand()
        local lifetime = GLOW_MAX_LIFETIME --* (.9 + math.random() * .1)
        local px, py, pz = emitter_fn()

        px = px + math.random(-1,1) * .2
        py = py + math.random(-1,1) * .2
        pz = pz + math.random(-1,1) * .2
        local uv_offset = math.random(0, 3) * .25
        effect:AddRotatingParticle(
            0,
            lifetime,           -- lifetime  生命周期
            px, py, pz,         -- position  位置
            vx, vy, vz,         -- velocity  速度
            uv_offset,-- angle               角度
            0    -- angle velocity           角速度
        )
    end

    local assets =
    {
        Asset("IMAGE", image),
        Asset("SHADER", REVEAL_SHADER),
    }

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst.entity:SetPristine()

        inst.persists = false
        inst.mode = "empty" -- 空白，米黄色，金黄色，天蓝色
        --Dedicated server does not need to spawn local particle fx
        if TheNet:IsDedicated() then
            return inst
        elseif InitEnvelope ~= nil then
            InitEnvelope(name, color) -- 初始化颜色和形状变化的设置
        end

        -- 给prefab添加粒子特效
        local effect = inst.entity:AddVFXEffect() -- 添加粒子特效组件
        effect:InitEmitters(1) -- 初始化发射器的数量
        effect:SetRenderResources(0, image, REVEAL_SHADER) -- 设置渲染资源
        effect:SetMaxNumParticles(0, 128) -- 设置最大粒子数量
        effect:SetRotationStatus(0, true) -- 开启粒子的旋转状态
        effect:SetMaxLifetime(0, GLOW_MAX_LIFETIME) -- 设置最大生命周期
        effect:SetColourEnvelope(0, name.."_colourenvelope") -- 设置颜色变化的封套
        effect:SetScaleEnvelope(0, name.."_scaleenvelope") -- 设置缩放变化的封套
        effect:SetBlendMode(0, BLENDMODE.AlphaBlended) -- 设置粒子混合模式
        effect:EnableBloomPass(0, true) -- 启用辉光通道
        effect:SetSortOrder(0, 0) -- 设置排序顺序
        effect:SetSortOffset(0, 0) -- 设置排序偏移
        effect:SetKillOnEntityDeath(0, true) -- 设置实体死亡时粒子死亡
        -----------------------------------------------------


        local tick_time = TheSim:GetTickTime() -- 获取每个tick的时间

        local sparkle_desired_pps_low = 5 -- 每秒期望的最少粒子数
        local sparkle_desired_pps_high = 50 -- 每秒期望的最多粒子数
        local low_per_tick = sparkle_desired_pps_low * tick_time -- 每个tick应发射的最少粒子数
        local high_per_tick = sparkle_desired_pps_high * tick_time -- 每个tick应发射的最多粒子数
        local num_to_emit = 0 -- 当前要发射的粒子数量
        local sphere_emitter = CreateSphereEmitter(.25) -- 创建球形发射器
        inst.last_pos = inst:GetPosition() -- 记录上一次的位置

        EmitterManager:AddEmitter(inst, nil, function()
            local dist_moved = inst:GetPosition() - inst.last_pos -- 计算移动的距离
            local move = dist_moved:Length() -- 获取移动的长度
            move = math.clamp(move*6, 0, 1) -- 限制移动比例在0到1之间

            local per_tick = Lerp(low_per_tick, high_per_tick, move) -- 利用线性插值计算每个tick的粒子发射数量

            inst.last_pos = inst:GetPosition() -- 更新上一次的位置

            num_to_emit = num_to_emit + per_tick * math.random() * 3 -- 更新待发射的粒子数
            while num_to_emit > 1 do -- 当待发射数量大于1时，发射粒子
                emit_glow_fn(effect, sphere_emitter) -- 调用发射粒子的函数
                num_to_emit = num_to_emit - 1 -- 减少待发射数量
            end
        end)

        return inst
    end

    return Prefab(name, fn, assets)
end

return MakeFx("honor_weapon_fx_common", color.common),
    MakeFx("honor_weapon_fx_empty", color.empty),
    MakeFx("honor_weapon_fx_wheat", color.wheat),
    MakeFx("honor_weapon_fx_rice", color.rice),
    MakeFx("honor_weapon_fx_greentea", color.greentea),
    MakeFx("honor_weapon_fx_dhp", color.dhp),
    MakeFx("honor_weapon_fx_jasmine", color.jasmine),
    MakeFx("honor_weapon_fx_coconut", color.coconut)