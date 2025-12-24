local prefs = {}
local TOOLS_F = require("tools_fx_legion")
local pas = {} --专门放各个prefab独特的变量

--一些好用的特效
--trinket_echoes

local function MakeFx(data) --不需要网络功能
	table.insert(prefs, Prefab(
		data.name,
		function()
			local inst = CreateEntity()

			inst.entity:AddTransform()
			inst.entity:AddNetwork()

			--Dedicated server does not need to spawn the local fx
			if not TheNet:IsDedicated() then
				--Delay one frame so that we are positioned properly before starting the effect
				--or in case we are about to be removed
				inst:DoTaskInTime(0, function(proxy)
					local inst2 = CreateEntity()

					--[[Non-networked entity]]

					inst2.entity:AddTransform()
					inst2.entity:AddAnimState()
					inst2.entity:SetCanSleep(false)
					inst2.persists = false

                    inst2:AddTag("FX")

					local parent = proxy.entity:GetParent()
					if parent ~= nil then
						inst2.entity:SetParent(parent.entity)
					end
					inst2.Transform:SetFromProxy(proxy.GUID)

					if data.fn_anim ~= nil then
						data.fn_anim(inst2)
					end

                    if data.fn_remove ~= nil then
						data.fn_remove(inst2)
                    else
                        inst2:ListenForEvent("animover", inst2.Remove)
					end
				end)
			end

            inst:AddTag("FX")

            if data.fn_common ~= nil then
				data.fn_common(inst)
			end

			inst.entity:SetPristine()
			if not TheWorld.ismastersim then return inst end

			inst.persists = false
			inst:DoTaskInTime(data.removetime or 1, inst.Remove)

			return inst
		end,
		data.assets,
		nil
	))
end
local function MakeFx2(data) --需要网络功能
    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        if not data.noanim then
            inst.entity:AddAnimState()
        end
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.persists = false

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, data.assets, nil ))
end

------

local function OnRemove_followfx(inst)
    if inst.fx ~= nil then
        for _, v in ipairs(inst.fx) do
            v:Remove()
        end
    end
end
local function ColorChanged_followfx(inst, r, g, b, a)
    if inst.fx ~= nil then
        for _, v in ipairs(inst.fx) do
            v.AnimState:SetAddColour(r, g, b, a)
        end
    end
end
local function CreateNonNetInst(fn_anim, v)
    local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")

	inst.persists = false

    inst:AddComponent("highlightchild") --这个组件是为了同步主体的高亮，达到一致性

    if v.fn_anim ~= nil then
        v.fn_anim(inst, v)
    else
        fn_anim(inst, v)
    end

	return inst
end
local function SpawnFollowFxForOwner(inst, owner, dd)
    inst.fx = {}
    local frame
    for _, v in ipairs(dd.fx) do
        local fx = CreateNonNetInst(dd.fn_anim, v)
        if dd.randomanim or v.randomanim then
            frame = frame or math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1
        end
        fx.entity:SetParent(owner.entity)
        fx.Follower:FollowSymbol(owner.GUID, v.symbol or dd.symbol, v.x, v.y, v.z, true, nil, v.idx, v.idx2)
        if frame ~= nil then
            fx.AnimState:SetFrame(frame)
        end
        fx.components.highlightchild:SetOwner(owner)
        table.insert(inst.fx, fx)
    end
    inst.components.colouraddersync:SetColourChangedFn(ColorChanged_followfx)
	inst.OnRemoveEntity = OnRemove_followfx
end
local function MakeFxFollow(data) --绑定式特效
    local function OnEntityReplicated(inst)
		local owner = inst.entity:GetParent()
		if owner ~= nil then
			SpawnFollowFxForOwner(inst, owner, data)
		end
	end
	local function AttachToOwner(inst, owner)
		inst.entity:SetParent(owner.entity)
		--Dedicated server does not need to spawn the local fx
		if not TheNet:IsDedicated() then
			SpawnFollowFxForOwner(inst, owner, data)
		end
	end

    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst:AddTag("FX")

        inst:AddComponent("colouraddersync")

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = OnEntityReplicated
            return inst
        end

        inst.persists = false
        inst.AttachToOwner = AttachToOwner

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, data.assets, nil))
end

---------------
---------------

MakeFx({ --举盾：盾反成功特效
    name = "shield_attack_l_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_beetletaur_fx.zip") --官方的熔炉甲虫猪防御特效动画
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_beetletaur_fx")
        inst.AnimState:SetBuild("lavaarena_beetletaur_fx")
        inst.AnimState:PlayAnimation("defend_fx")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetScale(0.6, 0.6)
    end
})

MakeFx({ --玫瑰酥：零散的气氛烘托特效
    name = "dish_lovingrosecake1_fx",
    assets = {
        Asset("ANIM", "anim/winters_feast_fx.zip"),  --官方节日餐桌气氛动画模板
        Asset("ANIM", "anim/dish_lovingrosecake_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("winters_feast_fx")
        inst.AnimState:SetBuild("dish_lovingrosecake_fx")
        inst.AnimState:PlayAnimation(math.random(1, 10), false)
        inst.AnimState:SetMultColour(255/255, 154/255, 200/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
    end
})
MakeFx({ --玫瑰酥：零散的气氛烘托特效(特殊)
    name = "dish_lovingrosecake2_fx",
    assets = {
        Asset("ANIM", "anim/winters_feast_fx.zip"),  --官方节日餐桌气氛动画模板
        Asset("ANIM", "anim/dish_lovingrosecake2_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("winters_feast_fx")
        inst.AnimState:SetBuild("dish_lovingrosecake2_fx")
        inst.AnimState:PlayAnimation(math.random(1, 10), false)
        inst.AnimState:SetMultColour(255/255, 68/255, 46/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
    end
})
MakeFx({ --玫瑰酥：非常多的气氛烘托特效(特殊)
    name = "dish_lovingrosecake_s2_fx",
    assets = {
        Asset("ANIM", "anim/winters_feast_table_fx.zip"), --官方节日餐桌食物消失动画模板
        Asset("ANIM", "anim/dish_lovingrosecake2_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("winters_feast_table_fx")
        inst.AnimState:SetBuild("dish_lovingrosecake2_fx")
        inst.AnimState:PlayAnimation("burst", false)
        inst.AnimState:SetMultColour(255/255, 68/255, 46/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx({ --金色传说：特效结束
    name = "buff_l_goldenloot_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_item_pickup_fx.zip") --官方的动画模板
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_item_pickup_fx")
        inst.AnimState:SetBuild("lavaarena_item_pickup_fx")
        inst.AnimState:PlayAnimation("pst")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(.4)
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetMultColour(255/255, 211/255, 66/255, 1)
        inst.AnimState:SetScale(0.6, 0.6, 0.6)
    end
})

------
--花香四溢
------

MakeFx({ --兰草花剑：飞溅花瓣
    name = "impact_orchid_fx",
    assets = {
        Asset("ANIM", "anim/impact_orchid.zip"),
        Asset("ANIM", "anim/impact.zip"), --官方击中特效动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("impact")
        inst.AnimState:SetBuild("impact_orchid")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetFinalOffset(1)
    end,
    fn_remove = nil,
})
MakeFx({ --粉色追猎：飞溅花瓣
    name = "impact_orchid_fx_disguiser",
    assets = {
        Asset("ANIM", "anim/lavaarena_heal_projectile.zip"), --官方的熔炉奶杖击中特效动画
        Asset("ANIM", "anim/skin/impact_orchid_fx_disguiser.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_heal_projectile")
        inst.AnimState:SetBuild("impact_orchid_fx_disguiser")
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:SetFinalOffset(1)
    end,
    fn_remove = nil
})
MakeFx({ --铁艺兰珊：飞溅花瓣
    name = "impact_orchid_fx_marble",
    assets = {
        Asset("ANIM", "anim/lavaarena_heal_projectile.zip"), --官方的熔炉奶杖击中特效动画
        Asset("ANIM", "anim/skin/impact_orchid_fx_marble.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_heal_projectile")
        inst.AnimState:SetBuild("impact_orchid_fx_marble")
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:SetFinalOffset(1)
    end,
    fn_remove = nil
})
MakeFx({ --庇佑蝴蝶：护佑
    name = "buff_l_butterflybless_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_boarrior_fx.zip"), --官方的动画模板
        Asset("ANIM", "anim/buff_l_butterflybless_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_boarrior_fx")
        inst.AnimState:SetBuild("buff_l_butterflybless_fx")
        inst.AnimState:PlayAnimation("ground_hit_"..tostring(math.random(3)))
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetScale(1.2, 1.2, 1.2)
    end
})
MakeFx({ --庇佑蝴蝶：护佑边线
    name = "buff_l_butterflybless_fx2",
    assets = {
        Asset("ANIM", "anim/abigail_shield.zip"), --官方的动画模板
        Asset("ANIM", "anim/buff_l_butterflybless_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("abigail_shield")
        inst.AnimState:SetBuild("buff_l_butterflybless_fx")
        inst.AnimState:PlayAnimation("shield")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(.2)
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetScale(1.2, 1.2, 1.2)
    end
})
-- MakeFx({ --施咒蔷薇：火花爆炸
--     name = "rosorns_spell_fx",
--     assets = {
--         Asset("ANIM", "anim/lavaarena_firebomb.zip"), --官方熔炉燃烧瓶特效动画模板
--     },
--     fn_common = nil,
--     fn_anim = function(inst)
--         inst.AnimState:SetBank("lavaarena_firebomb")
--         inst.AnimState:SetBuild("lavaarena_firebomb")
--         inst.AnimState:PlayAnimation("hitfx")
--         inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
--         inst.AnimState:SetFinalOffset(1)
--         inst.AnimState:SetScale(0.7, 0.7)
--     end,
--     fn_remove = nil,
-- })
-- MakeFx({ --施咒蔷薇：火花爆炸2
--     name = "rosorns_spell_fx",
--     assets = {
--         Asset("ANIM", "anim/lavaarena_heal_projectile.zip"), --官方的熔炉奶杖击中特效动画
--     },
--     fn_common = nil,
--     fn_anim = function(inst)
--         inst.AnimState:SetBank("lavaarena_heal_projectile")
--         inst.AnimState:SetBuild("lavaarena_heal_projectile")
--         inst.AnimState:PlayAnimation("hit")
--         inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
--         inst.AnimState:SetFinalOffset(1)
--         -- inst.AnimState:SetScale(0.7, 0.7)
--     end,
--     fn_remove = nil,
-- })
MakeFx({ --贯星剑：闪光炸裂
    name = "rosorns_collector_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_heal_projectile.zip"), --官方的熔炉奶杖击中特效动画
        Asset("ANIM", "anim/skin/rosorns_collector_fx.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_heal_projectile")
        inst.AnimState:SetBuild("rosorns_collector_fx")
        inst.AnimState:PlayAnimation("cast")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1)
    end,
    fn_remove = nil,
})
MakeFx({ --落薇剪：一剪没
    name = "rosorns_marble_fx",
    assets = {
        Asset("ANIM", "anim/boomerang.zip"), --官方的回旋镖动画
        Asset("ANIM", "anim/skin/rosorns_marble_fx.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("boomerang")
        inst.AnimState:SetBuild("rosorns_marble_fx")
        inst.AnimState:PlayAnimation("used")
        inst.AnimState:SetFinalOffset(1)
    end,
    fn_remove = nil,
})

------
--祈雨祭
------

MakeFx({ --艾力冈的剑：燃血
    name = "agronssword_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_boarrior_fx.zip"), --官方的动画模板
        Asset("ANIM", "anim/agronssword_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_boarrior_fx")
        inst.AnimState:SetBuild("agronssword_fx")
        inst.AnimState:PlayAnimation("ground_hit_"..tostring(math.random(2)))
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetFinalOffset(1)
    end
})
MakeFx({ --糖霜法棍：燃血
    name = "agronssword_taste_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_boarrior_fx.zip"), --官方的动画模板
        Asset("ANIM", "anim/skin/agronssword_taste_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_boarrior_fx")
        inst.AnimState:SetBuild("agronssword_taste_fx")
        inst.AnimState:PlayAnimation("ground_hit_"..tostring(math.random(2)))
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetFinalOffset(1)
    end
})
MakeFx({ --日辉轮刺盾：燃血
    name = "agronssword_sun_fx",
    assets = {
        Asset("ANIM", "anim/shadowrift_portal.zip"), --官方的动画模板
        Asset("ANIM", "anim/skin/agronssword_sun_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("shadowrift_portal")
        inst.AnimState:SetBuild("agronssword_sun_fx")
        inst.AnimState:PlayAnimation("particle_3_loop") --和particle_1_loop、particle_2_loop是一样的，大小不同而已
        inst.AnimState:SetScale(0.5, 0.5+math.random()*0.3)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetFinalOffset(1)
    end
})
MakeFx({ --日辉轮刺盾：盾反成功特效
    name = "agronssword_sun_catk_fx",
    assets = {
        Asset("ANIM", "anim/fx_dock_crackleandpop.zip") --官方动画
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("fx_dock_crackleandpop")
        inst.AnimState:SetBuild("fx_dock_crackleandpop")
        inst.AnimState:PlayAnimation("pop")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetScale(0.5, 0.5)
    end
})
MakeFx({ --日辉轮刺盾：盾反成功火纹特效
    name = "agronssword_sun_catk2_fx",
    assets = {
        Asset("ANIM", "anim/deer_fire_charge.zip") --官方动画
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("deer_fire_charge")
        inst.AnimState:SetBuild("deer_fire_charge")
        inst.AnimState:PlayAnimation("blast")
        inst.AnimState:HideSymbol("fire_puff_fx")
        inst.AnimState:HideSymbol("glow_")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetMultColour(255/255, 122/255, 113/255, 0.8)
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetScale(0.8, 0.8)
    end
})
MakeFx({ --日辉轮刺盾：盾反成功敌人特效
    name = "agronssword_sun_catk3_fx",
    assets = {
        Asset("ANIM", "anim/fx_dock_crackleandpop.zip") --官方动画
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("fx_dock_crackleandpop")
        inst.AnimState:SetBuild("fx_dock_crackleandpop")
        inst.AnimState:PlayAnimation("pop")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetScale(0.8, 0.8)
    end
})

MakeFx({ --月折宝剑：涌动
    name = "refracted_l_wave_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_boarrior_fx.zip"), --需要官方的动画模板
        Asset("ANIM", "anim/refractedmoonlight_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_boarrior_fx")
        inst.AnimState:SetBuild("refractedmoonlight_fx")
        inst.AnimState:PlayAnimation("ground_hit_1")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetScale(1.5, 1.5)
        inst.AnimState:SetLightOverride(0.5)
        inst.AnimState:SetFinalOffset(1)
    end
})
MakeFx({ --月折宝剑：月耀注入
    name = "refracted_l_skylight_fx",
    assets = {
        Asset("ANIM", "anim/siving_boss_caw_fx.zip"),
        Asset("ANIM", "anim/alterguardian_meteor.zip") --官方月晶石陷阱动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("alterguardian_meteor")
        inst.AnimState:SetBuild("siving_boss_caw_fx")
        inst.AnimState:PlayAnimation("meteor_pre")
        inst.AnimState:OverrideSymbol("fx_skybeam", "alterguardian_meteor", "fx_skybeam")
        inst.AnimState:OverrideSymbol("fx_beam", "alterguardian_meteor", "fx_beam")
        inst.AnimState:OverrideSymbol("blue_splode", "alterguardian_meteor", "blue_splode")
        inst.AnimState:SetScale(0.8, 0.8)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.5)
        inst.AnimState:SetFinalOffset(2)
    end,
    fn_remove = nil
})
MakeFx({ --月折宝剑：月耀
    name = "refracted_l_light_fx",
    assets = {
        Asset("ANIM", "anim/siving_boss_caw_fx.zip"),
        Asset("ANIM", "anim/alterguardian_meteor.zip") --官方月晶石陷阱动画模板
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("alterguardian_meteor")
        inst.AnimState:SetBuild("siving_boss_caw_fx")
        inst.AnimState:PlayAnimation("meteor_pre")
        -- inst.AnimState:OverrideSymbol("fx_skybeam", "alterguardian_meteor", "fx_skybeam")
        inst.AnimState:OverrideSymbol("fx_beam", "alterguardian_meteor", "fx_beam")
        -- inst.AnimState:OverrideSymbol("blue_splode", "alterguardian_meteor", "blue_splode")
        inst.AnimState:SetScale(0.8, 0.8)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.5)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx({ --月折宝剑：闪闪月耀
    name = "refracted_l_spark_fx",
    assets = {
        Asset("ANIM", "anim/siving_boss_caw_fx.zip"),
        Asset("ANIM", "anim/alterguardian_meteor.zip") --官方月晶石陷阱动画模板
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("alterguardian_meteor")
        inst.AnimState:SetBuild("siving_boss_caw_fx")
        inst.AnimState:PlayAnimation("meteorground_pre")
        inst.AnimState:PushAnimation("meteorground_loop", false)
        inst.AnimState:SetScale(0.4, 0.4)
        inst.AnimState:SetMultColour(131/255, 250/255, 230/255, 0.7)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx({ --烤肠大王：闪闪月耀
    name = "refracted_l_spark_taste_fx",
    assets = {
        Asset("ANIM", "anim/siving_boss_caw_fx.zip"),
        Asset("ANIM", "anim/alterguardian_meteor.zip") --官方月晶石陷阱动画模板
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("alterguardian_meteor")
        inst.AnimState:SetBuild("siving_boss_caw_fx")
        inst.AnimState:PlayAnimation("meteorground_pre")
        inst.AnimState:PushAnimation("meteorground_loop", false)
        inst.AnimState:SetScale(0.4, 0.4)
        inst.AnimState:SetMultColour(255/255, 222/255, 139/255, 0.7)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx2({ --月辉虹隙刃：闪闪月耀
    name = "refracted_l_moon_light_fx",
    assets = {
        Asset("ANIM", "anim/purebrilliance.zip") --官方纯粹辉煌动画
    },
    fn_common = function(inst)
        inst.entity:AddFollower()

        inst.AnimState:SetBank("purebrilliance")
        inst.AnimState:SetBuild("purebrilliance")
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:HideSymbol("glow")
        inst.AnimState:HideSymbol("pb_part")
        inst.AnimState:HideSymbol("pb_shad")
        inst.AnimState:HideSymbol("SparkleBit")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.7)
        inst.AnimState:SetMultColour(1, 1, 1, 0.1)
    end
})
MakeFx2({ --月辉虹隙刃：攻击特效
    name = "refracted_l_moon_atk_fx",
    assets = {
        Asset("ANIM", "anim/carnival_sparkle.zip") --官方动画模板
    },
    fn_common = function(inst)
        inst.AnimState:SetBank("carnival_sparkle")
        inst.AnimState:SetBuild("carnival_sparkle")
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:SetFrame(math.max(0, math.ceil(inst.AnimState:GetCurrentAnimationNumFrames()*0.5)-1))
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.7)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetScale(0.8, 0.8, 0.8)
    end,
    fn_server = function(inst)
        inst:ListenForEvent("animover", inst.Remove)
    end
})
MakeFx({ --月辉虹隙刃：攻击特效2
    name = "refracted_l_moon_atk2_fx",
    assets = {
        Asset("ANIM", "anim/alterguardian_spike.zip") --官方动画模板
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("alterguardian_spike")
        inst.AnimState:SetBuild("alterguardian_spike")
        inst.AnimState:PlayAnimation("spike_pst")
        inst.AnimState:HideSymbol("spike_moonglass_01")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.5)
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetScale(0.6, 0.6, 0.6)
    end
})
MakeFx({ --月轮宝盘：光韵特效
    name = "revolvedmoonlight_fx",
    assets = {
        Asset("ANIM", "anim/terrariumchest_fx.zip"), --官方盒中泰拉箱子的特效
        Asset("ANIM", "anim/revolvedmoonlight_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("terrariumchest_fx")
        inst.AnimState:SetBuild("revolvedmoonlight_fx")
        inst.AnimState:PlayAnimation("idle_front")
        if math.random() < 0.65 then
            inst.AnimState:SetMultColour(255/255, 249/255, 67/255, 0.9)
        else
            inst.AnimState:SetMultColour(1/255, 251/255, 255/255, 0.6)
        end
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.2)
        inst.AnimState:SetFinalOffset(3)
    end
})
MakeFx2({ --月炆宝炊：月焰
    name = "simmerfire_l_fx",
    assets = { Asset("ANIM", "anim/simmerfire_l_fx.zip") },
    fn_common = function(inst)
        inst.entity:AddFollower()
        inst.AnimState:SetBank("simmerfire_l_fx")
        inst.AnimState:SetBuild("simmerfire_l_fx")
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetScale(1.5, 1.5)
        inst.AnimState:SetMultColour(97/255, 198/255, 205/255, 0.5)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(0.5)
        inst.AnimState:SetFinalOffset(2)
        inst.Transform:SetTwoFaced()
        -- inst:AddTag("NOCLICK")

        inst:AddComponent("highlightchild")
    end,
    fn_server = function(inst)
        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    end
})

MakeFx2({ --泡澡：水花特效
    name = "soak_waterspout_l_fx",
    assets = { Asset("ANIM", "anim/crab_king_bubble_fx.zip") }, --官方帝王蟹的技能特效
    fn_common = function(inst)
        inst.AnimState:SetBank("bubble_fx")
        inst.AnimState:SetBuild("crab_king_bubble_fx")
        inst.AnimState:PlayAnimation("waterspout") --plank_hop
        inst.AnimState:SetScale(1, 0.6)
        inst.AnimState:SetFinalOffset(3)
    end,
    fn_server = function(inst)
        inst:ListenForEvent("animover", inst.Remove)
    end
})
table.insert(prefs, Prefab("float_front_l_fx", function() --【客户端】泡澡：前置水纹特效
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --[[Non-networked entity]]

    inst.AnimState:SetBank("float_front")
    inst.AnimState:SetBuild("float_fx")
    inst.AnimState:PlayAnimation("idle_front_med", true)
    -- inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)

    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")
    inst:AddTag("ignorewalkableplatforms")
    inst.persists = false

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    return inst
end, { Asset("ANIM", "anim/float_fx.zip") }, nil))
table.insert(prefs, Prefab("float_back_l_fx", function() --【客户端】泡澡：后置水纹特效
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --[[Non-networked entity]]

    inst.AnimState:SetBank("float_back")
    inst.AnimState:SetBuild("float_fx")
    inst.AnimState:PlayAnimation("idle_back_med", true)
    -- inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(4) --得比池塘高

    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")
    inst:AddTag("ignorewalkableplatforms")
    inst.persists = false

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    return inst
end, { Asset("ANIM", "anim/float_fx.zip") }, nil))

------
--电闪雷鸣
------

MakeFx({ --素白蘑菇帽：作物疾病的治愈时，消散的细菌
    name = "escapinggerms_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_boarrior_fx.zip"),    --需要官方的动画模板
        Asset("ANIM", "anim/agronssword_fx.zip"),           --套用已有的贴图
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_boarrior_fx")
        inst.AnimState:SetBuild("agronssword_fx")
        inst.AnimState:PlayAnimation("ground_hit_1")
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetMultColour(40/255, 40/255, 40/255, 1)
    end,
    fn_remove = nil,
})
MakeFx({ --素白蘑菇帽：玩家身上不断冒出的孢子
    name = "buff_l_sporeresistance_fx",
    assets = {
        Asset("ANIM", "anim/wormwood_pollen_fx.zip"), --官方的动画模板
        Asset("ANIM", "anim/residualspores_fx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("wormwood_pollen_fx")
        inst.AnimState:SetBuild("residualspores_fx")
        inst.AnimState:PlayAnimation("pollen"..tostring(math.random(5)))
        inst.AnimState:SetFinalOffset(2)

        local rand = math.random()
        if rand < 0.1 then
            inst.AnimState:SetMultColour(237/255, 170/255, 165/255, 1)
        elseif rand < 0.2 then
            inst.AnimState:SetMultColour(172/255, 237/255, 165/255, 1)
        elseif rand < 0.3 then
            inst.AnimState:SetMultColour(165/255, 187/255, 237/255, 1)
        end
    end
})

MakeFx({ --芬布尔斧：击中时贴地扩散的闪电
    name = "fimbul_cracklebase_fx",
    assets = {
        Asset("ANIM", "anim/fimbul_static_fx.zip"),
        Asset("ANIM", "anim/lavaarena_hammer_attack_fx.zip"), --官方熔炉锤子大招特效动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
        inst.AnimState:SetBuild("fimbul_static_fx")
        inst.AnimState:PlayAnimation("crackle_projection")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetScale(1.3, 1.3)
        inst.AnimState:SetMultColour(140/255, 239/255, 255/255, 1)
    end,
    fn_remove = nil,
})
MakeFx({ --跃星杖：飘散的星星
    name = "fimbul_axe_collector_fx",
    assets = { Asset("ANIM", "anim/skin/fimbul_axe_collector.zip") },
    fn_anim = function(inst)
        inst.AnimState:SetBank("fimbul_axe_collector")
        inst.AnimState:SetBuild("fimbul_axe_collector")
        inst.AnimState:PlayAnimation("star"..tostring(math.random(4)))
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetLightOverride(0.3)
    end
})
MakeFx({ --跃星杖：炸落的星星
    name = "fimbul_axe_collector2_fx",
    assets = {
        Asset("ANIM", "anim/explode.zip"), --官方爆炸特效动画模板
        Asset("ANIM", "anim/skin/fimbul_axe_collector2_fx.zip"),
    },
    fn_common = function(inst)
        inst.Transform:SetFourFaced()
    end,
    fn_anim = function(inst)
        inst.AnimState:SetBank("explode")
        inst.AnimState:SetBuild("fimbul_axe_collector2_fx")
        inst.AnimState:PlayAnimation("small_firecrackers")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(1.65, 1.65, 1.65)
    end,
    fn_remove = nil,
})
MakeFx({ --跃星杖：扩大的星星
    name = "fimbul_axe_collector3_fx",
    assets = { Asset("ANIM", "anim/skin/fimbul_axe_collector3_fx.zip") },
    fn_anim = function(inst)
        inst.AnimState:SetBank("fimbul_axe_collector3_fx")
        inst.AnimState:SetBuild("fimbul_axe_collector3_fx")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetScale(1.6, 1.6)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1)

        inst.entity:AddSoundEmitter()
        inst.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/active")
    end
})
-- MakeFx({ --芬布尔斧：重锤技能电光
--     name = "fimbul_attack_fx",
--     assets = {
--         Asset("ANIM", "anim/fimbul_attack_fx.zip"),
--         Asset("ANIM", "anim/lavaarena_hammer_attack_fx.zip"), --官方熔炉锤子大招特效动画模板
--     },
--     fn_common = nil,
--     fn_anim = function(inst)
--         inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
--         inst.AnimState:SetBuild("fimbul_attack_fx")
--         inst.AnimState:PlayAnimation("crackle_hit")
--         inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
--         inst.AnimState:SetSortOrder(1)
--         inst.AnimState:SetScale(1.8, 1.8)
--     end,
--     fn_remove = nil,
-- })
MakeFx({ --重铸boss：远程飞溅攻击特效
    name = "fimbul_teleport_fx",
    assets = {
        Asset("ANIM", "anim/fimbul_teleport_fx.zip"),
        Asset("ANIM", "anim/lavaarena_creature_teleport.zip"), --官方熔炉敌人出场特效动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_creature_teleport")
        inst.AnimState:SetBuild("fimbul_teleport_fx")
        inst.AnimState:PlayAnimation("spawn_medium")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetSortOrder(1)

        inst.entity:AddSoundEmitter()
        inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/spark")
        inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/portal_player")
    end,
    fn_remove = nil,
})
MakeFx({ --重铸boss：战吼时的爆炸
    name = "fimbul_explode_fx",
    assets = {
        Asset("ANIM", "anim/fimbul_explode_fx.zip"),
        Asset("ANIM", "anim/explode.zip"), --官方爆炸特效动画模板
    },
    fn_common = function(inst)
        inst.Transform:SetFourFaced()
    end,
    fn_anim = function(inst)
        inst.AnimState:SetBank("explode")
        inst.AnimState:SetBuild("fimbul_explode_fx")
        inst.AnimState:PlayAnimation("small")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(3, 3, 3)

        inst.entity:AddSoundEmitter()
        inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
    end,
    fn_remove = nil,
})

MakeFx({ --米格尔吉他：飘散的万寿菊花瓣
    name = "guitar_miguel_float_fx",
    assets = {
        Asset("ANIM", "anim/pine_needles.zip"), --官方砍树掉落松针特效
        Asset("ANIM", "anim/guitar_miguel_fx.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("pine_needles")
        inst.AnimState:SetBuild("pine_needles")
        inst.AnimState:PlayAnimation(math.random() < 0.5 and "fall" or "chop")
        inst.AnimState:SetSortOrder(1)
        inst.Transform:SetScale(0.6, 0.6, 0.6)
        inst.AnimState:OverrideSymbol("needle", "guitar_miguel_fx", "needle")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end,
    fn_remove = nil,
})
MakeFx({ --爆炸水果蛋糕：爆炸特效
    name = "explode_l_fruitcake",
    assets = {
        Asset("ANIM", "anim/explode.zip") --官方爆炸特效动画模板
    },
    fn_common = function(inst)
        inst.Transform:SetFourFaced()
    end,
    fn_anim = function(inst)
        inst.AnimState:SetBank("explode")
        inst.AnimState:SetBuild("explode")
        inst.AnimState:PlayAnimation("small_firecrackers")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(1.4, 1.4, 1.4)

        inst.entity:AddSoundEmitter()
        inst.SoundEmitter:PlaySoundWithParams("dontstarve/common/together/fire_cracker", { start = math.random() })
        inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/mound_explode")
    end
})
MakeFx({ --爱到爆蛋糕：爆炸后爱心特效
    name = "explode_l_fruitcake_day",
    assets = {
        Asset("ANIM", "anim/winters_feast_table_fx.zip"), --官方节日餐桌食物消失动画模板
        Asset("ANIM", "anim/skin/explode_l_fruitcake_day.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("winters_feast_table_fx")
        inst.AnimState:SetBuild("explode_l_fruitcake_day")
        inst.AnimState:PlayAnimation("burst", false)
        inst.AnimState:SetMultColour(255/255, 88/255, 116/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetScale(2.5, 2.5, 2.5)
        inst.AnimState:SetLightOverride(0.5)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx({ --爱到爆蛋糕：爆炸特效
    name = "explode_l_fruitcake2_day",
    assets = {
        Asset("ANIM", "anim/explode.zip"), --官方爆炸特效动画模板
        Asset("ANIM", "anim/skin/explodingfruitcake_day.zip")
    },
    fn_common = function(inst)
        inst.Transform:SetFourFaced()
    end,
    fn_anim = function(inst)
        inst.AnimState:SetBank("explode")
        inst.AnimState:SetBuild("explode")
        inst.AnimState:PlayAnimation("small_firecrackers")
        inst.AnimState:OverrideSymbol("glow", "explodingfruitcake_day", "glow")
        inst.AnimState:OverrideSymbol("sparks2", "explodingfruitcake_day", "sparks2")
        inst.AnimState:OverrideSymbol("splode", "explodingfruitcake_day", "splode")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(1.4, 1.4, 1.4)

        inst.entity:AddSoundEmitter()
        inst.SoundEmitter:PlaySoundWithParams("dontstarve/common/together/fire_cracker", { start = math.random() })
        inst.SoundEmitter:PlaySound("dontstarve/creatures/slurtle/mound_explode")
    end
})
MakeFx2({ --风景球：落雪
    name = "icire_rock_fx_day",
    assets = {
        Asset("ANIM", "anim/wintersfeastfuel.zip") --官方节日欢愉动画
    },
    fn_common = function(inst)
        inst.entity:AddFollower()

        inst.AnimState:SetBank("wintersfeastfuel")
        inst.AnimState:SetBuild("icire_rock_day")
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:SetFinalOffset(-1) --Tip: 1最上层，0中间层，-1最下层

        local sc = 1.2
        inst.AnimState:SetScale(sc, sc, sc)
    end,
    -- fn_server = function(inst)end
})

local function OnUpdate_eleccore(inst, dt)
    if inst.sound then
        inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/spark")
        inst.sound = nil
    end
    inst.Light:SetIntensity(inst.i)
    inst.i = inst.i - dt * 2
    if inst.i <= 0 then
        if inst.killfx then
            inst:Remove()
        else
            inst.task:Cancel()
            inst.task = nil
        end
    end
end
local function OnAnimOver_eleccore(inst)
    if inst.task == nil then
        inst:Remove()
    else
        inst:RemoveEventCallback("animover", OnAnimOver_eleccore)
        inst.killfx = true
    end
end
MakeFx({ --电气石：摩擦电
    name = "eleccore_spark_fx",
    assets = {
        Asset("ANIM", "anim/sparks.zip"), --官方漏电火花动画
        Asset("ANIM", "anim/sparks_l_fx.zip")
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.entity:AddSoundEmitter()
        inst.entity:AddLight()

        inst.AnimState:SetBank("sparks")
        inst.AnimState:SetBuild("sparks_l_fx")
        inst.AnimState:PlayAnimation("sparks_"..tostring(math.random(3)))
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetMultColour(140/255, 239/255, 255/255, 1)
        inst.Transform:SetScale(2, 2, 2)
        inst.AnimState:SetFinalOffset(3)

        inst.Light:Enable(true)
        inst.Light:SetRadius(2)
        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.9)
        inst.Light:SetColour(50/255, 176/255, 255/255)

        local dt = 1 / 20
        inst.i = .9
        inst.sound = inst.SoundEmitter ~= nil
        inst.task = inst:DoPeriodicTask(dt, OnUpdate_eleccore, nil, dt)
    end,
    fn_remove = function(inst)
        inst:ListenForEvent("animover", OnAnimOver_eleccore)
    end
})
MakeFx({ --霹雳神灯：摩擦电
    name = "eleccore_spark_fx_tale",
    assets = {
        Asset("ANIM", "anim/fimbul_static_fx.zip"),
        Asset("ANIM", "anim/lavaarena_hammer_attack_fx.zip") --官方熔炉锤子大招特效动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.entity:AddSoundEmitter()
        inst.entity:AddLight()

        inst.AnimState:SetBank("lavaarena_hammer_attack_fx")
        inst.AnimState:SetBuild("fimbul_static_fx")
        inst.AnimState:PlayAnimation("crackle_pst")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetMultColour(255/255, 133/255, 149/255, 1)
        inst.AnimState:SetFinalOffset(3)

        inst.Light:Enable(true)
        inst.Light:SetRadius(2)
        inst.Light:SetFalloff(1)
        inst.Light:SetIntensity(.9)
        inst.Light:SetColour(255/255, 133/255, 149/255)

        local dt = 1 / 20
        inst.i = .9
        inst.sound = inst.SoundEmitter ~= nil
        inst.task = inst:DoPeriodicTask(dt, OnUpdate_eleccore, nil, dt)
    end,
    fn_remove = function(inst)
        inst:ListenForEvent("animover", OnAnimOver_eleccore)
    end
})
MakeFx({ --占星石：发光特效
    name = "icire_rock_fx_collector",
    assets = {
        Asset("ANIM", "anim/skin/icire_rock_fx_collector.zip")
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("icire_rock_fx_collector")
        inst.AnimState:SetBuild("icire_rock_fx_collector")
        inst.AnimState:PlayAnimation(math.random() < 0.5 and "idle1" or "idle2")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetLightOverride(.5)
        if math.random() < 0.5 then
            inst.AnimState:OverrideSymbol("sparkle", "icire_rock_fx_collector", "sparkle2")
        end
    end,
    fn_remove = nil
})

pas.co_soul = { r = 154/255, g = 23/255, b = 19/255 } --暗红色(官方)
pas.co_soul_taste = { r = 246/255, g = 207/255, b = 75/255 } --金黄色
pas.Remove_soul_jump = function(inst)
    inst:ListenForEvent("animover", function()
        inst:DoTaskInTime(2 * FRAMES, inst.Remove)
    end)
end

MakeFx({ --灵魂契约：契约自己的治愈的施法特效
    name = "soulbook_l_fx",
    assets = { Asset("ANIM", "anim/wortox_soul_ball.zip") }, --官方的灵魂动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wortox_soul_ball")
        inst.AnimState:SetBuild("wortox_soul_ball")
        inst.AnimState:PlayAnimation("idle_pst")
        inst.AnimState:SetFrame(6)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx({ --灵魂契约：契约自己的分享等级的施法特效
    name = "soulbook_share1_l_fx",
    assets = { Asset("ANIM", "anim/wortox_teleport_reviver_fx.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wortox_teleport_reviver_fx")
        inst.AnimState:SetBuild("wortox_teleport_reviver_fx")
        inst.AnimState:PlayAnimation("decoy_laughsplode")
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx({ --灵魂契约：契约自己的分享灵魂的施法特效
    name = "soulbook_share2_l_fx",
    assets = { Asset("ANIM", "anim/wortox_teleport_reviver_fx.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wortox_teleport_reviver_fx")
        inst.AnimState:SetBuild("wortox_teleport_reviver_fx")
        inst.AnimState:PlayAnimation("soul_spawn_poof")
        inst.AnimState:SetScale(2, 2)
        inst.AnimState:SetFinalOffset(2)
    end
})
MakeFx({ --灵魂契约：契约自己的传入特效
    name = "soulbook_jumpin_l_fx",
    assets = { Asset("ANIM", "anim/wortox_portal.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild("wortox_portal")
        inst.AnimState:PlayAnimation("wortox_portal_jumpin")
        inst.AnimState:SetFinalOffset(2)
    end,
    fn_remove = pas.Remove_soul_jump
})
MakeFx({ --灵魂契约：契约自己的传出特效
    name = "soulbook_jumpout_l_fx",
    assets = { Asset("ANIM", "anim/wortox_portal.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild("wortox_portal")
        inst.AnimState:PlayAnimation("wortox_portal_jumpout")
        inst.AnimState:SetFinalOffset(2)
    end,
    fn_remove = pas.Remove_soul_jump
})
MakeFx({ --灵魂契约：契约自己的升级特效
    name = "soulbook_lvlup_l_fx",
    assets = { Asset("ANIM", "anim/attune_fx.zip") }, --官方的特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("attune_fx")
        inst.AnimState:SetBuild("attune_fx")
        inst.AnimState:PlayAnimation("attune_in")
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetAddColour(pas.co_soul.r, pas.co_soul.g, pas.co_soul.b, 0)
    end
})
MakeFx({ --芝士三明治：契约自己的治愈的施法特效
    name = "soulbook_l_fx_taste",
    assets = { Asset("ANIM", "anim/wortox_soul_ball.zip") }, --官方的灵魂动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wortox_soul_ball")
        inst.AnimState:SetBuild("wortox_soul_ball")
        inst.AnimState:PlayAnimation("idle_pst")
        inst.AnimState:SetFrame(6)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetAddColour(pas.co_soul_taste.r, pas.co_soul_taste.g, pas.co_soul_taste.b, 0)
    end
})
MakeFx({ --芝士三明治：契约自己的分享等级的施法特效
    name = "soulbook_share1_l_fx_taste",
    assets = { Asset("ANIM", "anim/wortox_teleport_reviver_fx.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wortox_teleport_reviver_fx")
        inst.AnimState:SetBuild("wortox_teleport_reviver_fx")
        inst.AnimState:PlayAnimation("decoy_laughsplode")
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetAddColour(pas.co_soul_taste.r, pas.co_soul_taste.g, pas.co_soul_taste.b, 0)
    end
})
MakeFx({ --芝士三明治：契约自己的分享灵魂的施法特效
    name = "soulbook_share2_l_fx_taste",
    assets = { Asset("ANIM", "anim/wortox_teleport_reviver_fx.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wortox_teleport_reviver_fx")
        inst.AnimState:SetBuild("wortox_teleport_reviver_fx")
        inst.AnimState:PlayAnimation("soul_spawn_poof")
        inst.AnimState:SetScale(2, 2)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetAddColour(pas.co_soul_taste.r, pas.co_soul_taste.g, pas.co_soul_taste.b, 0)
    end
})
MakeFx({ --芝士三明治：契约自己的传入特效
    name = "soulbook_jumpin_l_fx_taste",
    assets = { Asset("ANIM", "anim/wortox_portal.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild("wortox_portal")
        inst.AnimState:PlayAnimation("wortox_portal_jumpin")
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetAddColour(pas.co_soul_taste.r, pas.co_soul_taste.g, pas.co_soul_taste.b, 0)
    end,
    fn_remove = pas.Remove_soul_jump
})
MakeFx({ --芝士三明治：契约自己的传出特效
    name = "soulbook_jumpout_l_fx_taste",
    assets = { Asset("ANIM", "anim/wortox_portal.zip") }, --官方的灵魂特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("wilson")
        inst.AnimState:SetBuild("wortox_portal")
        inst.AnimState:PlayAnimation("wortox_portal_jumpout")
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetAddColour(pas.co_soul_taste.r, pas.co_soul_taste.g, pas.co_soul_taste.b, 0)
    end,
    fn_remove = pas.Remove_soul_jump
})
MakeFx({ --灵魂契约：契约自己的升级特效
    name = "soulbook_lvlup_l_fx_taste",
    assets = { Asset("ANIM", "anim/attune_fx.zip") }, --官方的特效动画
    fn_anim = function(inst)
        inst.AnimState:SetBank("attune_fx")
        inst.AnimState:SetBuild("attune_fx")
        inst.AnimState:PlayAnimation("attune_in")
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetAddColour(pas.co_soul_taste.r, pas.co_soul_taste.g, pas.co_soul_taste.b, 0)
    end
})

------
--尘世蜃楼
------

MakeFx({ --白木吉他：弹奏时的飘动音符
    name = "guitar_whitewood_doing_fx",
    assets = {
        Asset("ANIM", "anim/guitar_whitewood_doing_fx.zip"),
        Asset("ANIM", "anim/fx_wathgrithr_buff.zip") --官方战歌特效动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        local anims = {
            "fx_durability",
            "fx_fireresistance",
            "fx_healthgain",
            "fx_sanitygain"
        }
        inst.AnimState:SetBank("fx_wathgrithr_buff")
        inst.AnimState:SetBuild("fx_wathgrithr_buff")
        inst.AnimState:PlayAnimation(anims[math.random(#anims)])
        inst.AnimState:OverrideSymbol("fx_icon", "guitar_whitewood_doing_fx", "fx_icon")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end,
    fn_remove = nil
})
MakeFx2({ --幻象法杖：电光(音速起子12)
    name = "pinkstaff_fx_tvplay",
    assets = {
        Asset("ANIM", "anim/skin/pinkstaff_fx_tvplay.zip")
    },
    fn_common = function(inst)
        inst.entity:AddFollower()
        inst.AnimState:SetBank("pinkstaff_fx_tvplay")
        inst.AnimState:SetBuild("pinkstaff_fx_tvplay")
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetMultColour(115/255, 217/255, 255/255, 0.6)
        inst.AnimState:SetFinalOffset(1)

        inst:AddComponent("highlightchild")
    end,
    -- fn_server = function(inst)end
})
MakeFx({ --影织异种：簇栽特效
    name = "waxcluster_l_fx",
    assets = {
        Asset("ANIM", "anim/fx_plant_spray.zip") --官方暗影打蜡的特效
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("fx_plant_spray")
        inst.AnimState:SetBuild("fx_plant_spray")
        inst.AnimState:PlayAnimation("play_fx")
        inst.AnimState:SetFrame(math.max(0, math.ceil(inst.AnimState:GetCurrentAnimationNumFrames()*0.45)-1))
        inst.AnimState:SetScale(1.3, 1.3, 1.3)
        inst.AnimState:SetFinalOffset(3)
    end
})
MakeFx2({ --稀有基质培植盆：栽培植株体
    name = "potplant_l_fx",
    assets = { Asset("ANIM", "anim/pot_whitewood.zip") },
    fn_common = function(inst)
        inst.entity:AddFollower()

        inst.AnimState:SetBank("pot_whitewood")
        inst.AnimState:SetBuild("pot_whitewood")
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:Hide("basesoil")
        inst.AnimState:HideSymbol("abase")
        inst.Transform:SetTwoFaced()

        inst:AddComponent("highlightchild")
    end
})
MakeFx2({ --全息培植器：光效
    name = "pot_ww_future_fx",
    assets = { Asset("ANIM", "anim/skin/pot_whitewood_future.zip") },
    fn_common = function(inst)
        inst.AnimState:SetBank("pot_whitewood_future")
        inst.AnimState:SetBuild("pot_whitewood_future")
        inst.AnimState:SetLightOverride(0.1)
        inst.Transform:SetTwoFaced()
        inst:AddTag("NOCLICK")

        inst:AddComponent("highlightchild")
    end
})

------
--丰饶传说
------

MakeFx({ --脱壳之翅：逃脱时的茸毛特效
    name = "boltwingout_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_heal_projectile.zip"), --官方的熔炉奶杖击中特效动画
        Asset("ANIM", "anim/boltwingout_fx.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_heal_projectile")
        inst.AnimState:SetBuild("boltwingout_fx")
        inst.AnimState:SetFinalOffset(-1)
        inst.AnimState:PlayAnimation("hit")
    end,
    fn_remove = nil
})
MakeFx({ --枯叶飞舞：逃脱时的茸毛特效
    name = "boltwingout_fx_disguiser",
    assets = {
        Asset("ANIM", "anim/lavaarena_heal_projectile.zip"), --官方的熔炉奶杖击中特效动画
        Asset("ANIM", "anim/skin/boltwingout_fx_disguiser.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_heal_projectile")
        inst.AnimState:SetBuild("boltwingout_fx_disguiser")
        inst.AnimState:SetFinalOffset(-1)
        inst.AnimState:PlayAnimation("hit")
    end,
    fn_remove = nil
})
MakeFx({ --子圭·歃：生命转移特效
    name = "life_trans_fx",
    assets = {
        Asset("ANIM", "anim/life_trans_fx.zip"),
        Asset("ANIM", "anim/cursed_fx.zip"), --官方猴子诅咒特效动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("cursed_fx")
        inst.AnimState:SetBuild("life_trans_fx")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:OverrideSymbol("monkey_fx_parts", "life_trans_fx", "fx_fur_part") --不想显示这部分
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetScale(0.65, 0.65)
    end,
    fn_remove = nil
})
MakeFx({ --子圭寄生花：消失特效
    name = "siving_boss_flower_fx",
    assets = {
        Asset("ANIM", "anim/lavaarena_boarrior_fx.zip"), --官方的动画
        Asset("ANIM", "anim/siving_boss_flower_fx.zip"),
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("lavaarena_boarrior_fx")
        inst.AnimState:SetBuild("siving_boss_flower_fx")
        inst.AnimState:PlayAnimation("ground_hit_"..tostring(math.random(3)))
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetMultColour(1/255, 248/255, 255/255, 1)
    end
})
MakeFx({ --魔音绕梁：音波特效
    name = "siving_boss_taunt_fx",
    assets = {
        Asset("ANIM", "anim/bearger_ring_fx.zip"), --官方的动画
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("bearger_ring_fx")
        inst.AnimState:SetBuild("bearger_ring_fx")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetScale(0.5, 0.5)
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetMultColour(111/255, 255/255, 2/255, 0.25)
    end,
    fn_remove = nil
})
MakeFx({ --花寄语：音波特效
    name = "siving_boss_caw_fx",
    assets = {
        Asset("ANIM", "anim/alterguardian_meteor.zip"), --官方的动画
        Asset("ANIM", "anim/siving_boss_caw_fx.zip")
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("alterguardian_meteor")
        inst.AnimState:SetBuild("siving_boss_caw_fx")
        inst.AnimState:PlayAnimation("meteorground_loop")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetScale(0.5, 0.5)
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetSortOrder(3)
        inst.AnimState:SetMultColour(1/255, 248/255, 255/255, 0.4)
    end,
    fn_remove = function(inst)
        inst:DoTaskInTime(0.8, function()
            inst:Remove()
        end)
    end
})
MakeFx({ --高攻反伤：炸开特效
    name = "siving_boss_thorns_fx",
    assets = {
        Asset("ANIM", "anim/bramblefx.zip"),
        Asset("ANIM", "anim/sivsuitatk_fx.zip")
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank("bramblefx")
        inst.AnimState:SetBuild("sivsuitatk_fx")
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetSymbolBloom("needle01")
        inst.AnimState:SetSymbolLightOverride("needle01", .5)
        inst.AnimState:SetLightOverride(.1)
        if math.random() < 0.5 then
            inst.AnimState:PlayAnimation("idle")
        else
            inst.AnimState:PlayAnimation("trap")
            inst.AnimState:SetScale(1.3, 1.3)
        end
    end,
    fn_remove = nil
})
MakeFx({ --子圭神木岩：科技解锁特效
    name = "siving_thetree_unlock_fx",
    assets = {
        Asset("ANIM", "anim/fence_rotator_fx.zip") --官方的栅栏击剑特效动画
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("fence_rotator_fx")
        inst.AnimState:SetBuild("fence_rotator_fx")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:HideSymbol("fx_puff")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetMultColour(115/255, 255/255, 255/255, 0.7)
        inst.AnimState:SetLightOverride(1)
    end,
    fn_remove = nil
})
MakeFx({ --子圭石子：碎掉特效
    name = "siving_egg_hatched_fx",
    assets = {
        Asset("ANIM", "anim/siving_egg.zip"),
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("siving_egg")
        inst.AnimState:SetBuild("siving_egg")
        inst.AnimState:PlayAnimation("break")
        inst.AnimState:OverrideSymbol("eggbase", "siving_egg", "egg4")
        inst.AnimState:SetFinalOffset(3)
    end,
    fn_remove = nil
})
MakeFx({ --子圭·育：基因解锁时的花火特效(蓝绿色)
    name = "siving_turn_unlock_fx",
    assets = {
        Asset("ANIM", "anim/table_winters_feast.zip")  --官方节日餐桌动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("table_winters_feast")
        inst.AnimState:SetBuild("siving_boss_flower_fx")
        inst.AnimState:PlayAnimation("place", false)
        inst.AnimState:OverrideSymbol("glow_2", "table_winters_feast", "glow_2")
        inst.AnimState:OverrideSymbol("sprks", "table_winters_feast", "sprks")
        inst.AnimState:SetMultColour(40/255, 255/255, 175/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetFinalOffset(4) --子圭·育果实实体的是 3，所以这里得比3大
    end,
    fn_remove = nil
})
MakeFx({ --转星移：基因解锁时的花火特效(金色)
    name = "siving_turn_collector_unlock_fx",
    assets = {
        Asset("ANIM", "anim/table_winters_feast.zip")  --官方节日餐桌动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("table_winters_feast")
        inst.AnimState:SetBuild("siving_boss_flower_fx")
        inst.AnimState:PlayAnimation("place", false)
        inst.AnimState:OverrideSymbol("glow_2", "table_winters_feast", "glow_2")
        inst.AnimState:OverrideSymbol("sprks", "table_winters_feast", "sprks")
        inst.AnimState:SetMultColour(255/255, 234/255, 40/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetFinalOffset(4)
    end,
    fn_remove = nil
})
MakeFx({ --爱汪基因诱变舱：基因解锁时的花火特效(橘色)
    name = "siving_turn_future_unlock_fx",
    assets = {
        Asset("ANIM", "anim/table_winters_feast.zip")  --官方节日餐桌动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("table_winters_feast")
        inst.AnimState:SetBuild("siving_boss_flower_fx")
        inst.AnimState:PlayAnimation("place", false)
        inst.AnimState:OverrideSymbol("glow_2", "table_winters_feast", "glow_2")
        inst.AnimState:OverrideSymbol("sprks", "table_winters_feast", "sprks")
        inst.AnimState:SetMultColour(255/255, 179/255, 109/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetFinalOffset(4)
    end,
    fn_remove = nil
})
MakeFx({ --爱喵基因诱变舱：基因解锁时的花火特效(淡粉色)
    name = "siving_turn_future2_unlock_fx",
    assets = {
        Asset("ANIM", "anim/table_winters_feast.zip")  --官方节日餐桌动画模板
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("table_winters_feast")
        inst.AnimState:SetBuild("siving_boss_flower_fx")
        inst.AnimState:PlayAnimation("place", false)
        inst.AnimState:OverrideSymbol("glow_2", "table_winters_feast", "glow_2")
        inst.AnimState:OverrideSymbol("sprks", "table_winters_feast", "sprks")
        inst.AnimState:SetMultColour(255/255, 160/255, 221/255, 1)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetScale(1.2, 1.2)
        inst.AnimState:SetFinalOffset(4)
    end,
    fn_remove = nil
})
MakeFx({ --旅星猫：投射路径特效
    name = "siving_feather_real_collector_flyfx",
    assets = {
        Asset("ANIM", "anim/gold_nugget.zip"), --官方金块动画
        Asset("ANIM", "anim/skin/siving_feather_collector_fx.zip")
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("goldnugget")
        inst.AnimState:SetBuild("siving_feather_collector_fx")
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")  --使整个动画有光晕效果
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetFrame(math.random( math.floor(inst.AnimState:GetCurrentAnimationNumFrames()/2) ) - 1)

        -- inst.AnimState:SetSymbolBloom("sparkle") --使某通道贴图有光晕效果
        -- inst.AnimState:SetSymbolLightOverride("sparkle", .5) --使某通道贴图不被黑暗色调覆盖，范围0-1，值越大越亮
        inst.AnimState:SetLightOverride(.5) --使整个动画不被黑暗色调覆盖，范围0-1，值越大越亮

        if math.random() < 0.4 then
            inst.AnimState:OverrideSymbol("sparkle", "siving_feather_collector_fx", "star2")
        end

        local rand = math.random()
        if rand < 0.2 then
            inst.AnimState:SetMultColour(82/255, 243/255, 255/255, 1)
        elseif rand < 0.4 then
            inst.AnimState:SetMultColour(81/255, 105/255, 165/255, 1)
        end
    end,
    fn_remove = nil
})
MakeFx({ --流星猫：投射路径特效
    name = "siving_feather_fake_collector_flyfx",
    assets = {
        Asset("ANIM", "anim/gold_nugget.zip"), --官方金块动画
        Asset("ANIM", "anim/skin/siving_feather_collector_fx.zip")
    },
    fn_common = nil,
    fn_anim = function(inst)
        inst.AnimState:SetBank("goldnugget")
        inst.AnimState:SetBuild("siving_feather_collector_fx")
        inst.AnimState:PlayAnimation("sparkle")
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetFrame(math.random( math.floor(inst.AnimState:GetCurrentAnimationNumFrames()/2) ) - 1)
        inst.AnimState:SetLightOverride(.5)

        if math.random() < 0.6 then
            inst.AnimState:OverrideSymbol("sparkle", "siving_feather_collector_fx", "star2")
        end

        local rand = math.random()
        if rand < 0.2 then
            inst.AnimState:SetMultColour(255/255, 213/255, 85/255, 1)
        elseif rand < 0.4 then
            inst.AnimState:SetMultColour(141/255, 125/255, 66/255, 1)
        end
    end,
    fn_remove = nil
})
MakeFx({ --水肥照料机：浇水特效
    name = "sivctl_moi_fx",
    assets = {
        Asset("ANIM", "anim/splash_water_drop.zip"), --官方水滴贴图
        Asset("ANIM", "anim/splash_weregoose_fx.zip"), --官方简单水花动画模板
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("splash_weregoose_fx")
        inst.AnimState:SetBuild("splash_water_drop")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:HideSymbol("splash")
        inst.AnimState:HideSymbol("splashy")
        inst.AnimState:SetFinalOffset(3)
    end
})

------

local anims_kitcoon = {
    "idle_loop", "idle_loop", "idle_loop", "idle_loop", "idle_loop",
    "idle_loop", "idle_loop", "idle_loop", "idle_loop", "idle_loop",
    "idle_loop", "idle_loop", "idle_loop", "idle_loop", "idle_loop",
    "idle_loop", "idle_loop", "idle_loop", "idle_loop", "idle_loop",
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop",  "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_pst" },
    "emote_lick", "emote_lick", "emote_lick", "distress", "emote_stretch", "emote_stretch", "emote_stretch",
    { "walk_pre", "walk_pst" },
    { "jump_pre", "jump_loop", "jump_pst" },
    { "jump_pre", "jump_loop", "jump_loop", "jump_pst" },
    "idle_loop", "idle_loop", "idle_loop", "idle_loop", "idle_loop",
    "idle_loop", "idle_loop", "idle_loop", "idle_loop", "idle_loop"
}
local anims_bird = {
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    "caw", { "caw", "caw" }, { "caw", "caw", "caw" },
    "peck", { "peck", "peck" }, { "peck", "peck", "peck" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    { "flap_pre", "flap_loop", "flap_post" },
    { "flap_pre", "flap_loop", "flap_loop", "flap_post" },
    { "flap_pre", "flap_loop", "flap_loop", "flap_loop", "flap_loop", "flap_post" },
    "hop", "hop", "hop", "hop", "hop", "switch", "switch", "switch", "switch",
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop",  "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_pst" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle"
}
local anims_bird2 = {
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    "caw", { "caw", "caw" }, { "caw", "caw", "caw" },
    { "flap_pre", "flap_loop", "flap_post" },
    { "flap_pre", "flap_loop", "flap_loop", "flap_post" },
    { "flap_pre", "flap_loop", "flap_loop", "flap_loop", "flap_loop", "flap_post" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    "hop", "hop", "hop", "hop", "hop", "switch", "switch", "switch", "switch",
    "hit", "hit", "hit", "attack", "attack", "attack", "attack", "attack",
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop",  "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_pst" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle"
}
local anims_buzzard = {
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    "caw", { "caw", "caw" }, { "caw", "caw", "caw" },
    "peck", { "peck", "peck" }, { "peck", "peck", "peck" },
    { "flap_pre", "flap_loop", "flap_pst" },
    { "flap_pre", "flap_loop", "flap_loop", "flap_pst" },
    { "flap_pre", "flap_loop", "flap_loop", "flap_loop", "flap_loop", "flap_pst" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    "hop", "hop", "hop", "hop", "hop", "taunt", "taunt", "taunt", "taunt", "taunt",
    "hit", "hit", "hit", "atk", "atk", "atk", "atk", "atk",
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop",  "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_pst" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle"
}
local anims_smallbird = {
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    "idle_blink", "idle_blink", "idle_blink", "idle_blink", "idle_blink", "idle_blink", "idle_blink",
    "atk", "atk", "atk",
    "eat", "eat", "eat", "eat", "eat",
    "call", { "call", "call" }, { "call", "call" },
    "meep", { "meep", "meep" }, { "meep", "meep" },
    "hit", { "hit", "hit" }, { "hit", "hit", "hit" }, { "hit", "hit", "hit", "hit" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_loop", "sleep_loop",  "sleep_pst" },
    { "sleep_pre", "sleep_loop", "sleep_loop", "sleep_pst" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle",
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle", "idle", "idle", "idle" },
    { "idle", "idle_blink", "idle_blink", "idle" },
    { "idle", "idle_blink", "idle_blink", "idle" },
    { "idle", "idle_blink", "idle_blink", "idle" },
    { "idle", "idle_blink", "idle_blink", "idle" },
    { "walk_pre", "walk_loop", "walk_pst" },
    { "walk_pre", "walk_loop", "walk_loop", "walk_pst" },
    { "walk_pre", "walk_loop", "walk_loop", "walk_pst" },
    { "walk_pre", "walk_loop", "walk_loop", "walk_pst" },
    { "walk_pre", "walk_loop", "walk_loop", "walk_loop", "walk_pst" },
    "idle", "idle", "idle", "idle", "idle", "idle", "idle"
}
local anims_steak_twist = { "idle1", "idle2" }
local anims_steak_twist_swap = {
    "swap1", "swap2", "swap1", "swap1", "swap3", "swap4", "swap4", "swap4", "atk1", "atk1",
    { "swap1", "swap2" }, { "swap1", "swap3" },
    { "swap4", "swap2" }, { "swap4", "swap3" }, "atk1"
}

local function SetAnim_base(inst, data)
    inst.AnimState:SetBank(data.bank or data.build)
    inst.AnimState:SetBuild(data.build)
    if data.animpush ~= nil then
        inst.AnimState:PlayAnimation(data.anim)
        inst.AnimState:PushAnimation(data.animpush, data.isloop)
    else
        inst.AnimState:PlayAnimation(data.anim, data.isloop)
    end
end
local function SetAnim_cat(inst, data)
    inst.Transform:SetSixFaced()
    inst.AnimState:SetBank("kitcoon")
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation("idle_loop")
    TOOLS_F.StartRandomAnims(inst, false, anims_kitcoon)
end
local function SetAnim_bird(inst, data)
    inst.entity:AddFollower()
    if data.face == 4 then
        inst.Transform:SetFourFaced()
    else
        inst.Transform:SetTwoFaced()
    end
    inst.AnimState:SetBank(data.bank or "crow")
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation(data.anim or "land")
    TOOLS_F.StartRandomAnims(inst, false, data.sg or anims_bird)
end
local function SetAnim_tallbirdegg(inst, data)
    inst.AnimState:SetBank("egg")
    inst.AnimState:SetBuild("tallbird_egg")
    inst.AnimState:PlayAnimation(data.anim, true)
    inst.AnimState:HideSymbol("shdw")
end
local function SetAnim_steak_twist(inst, data)
    inst.entity:AddFollower()
    inst.AnimState:SetBank("dish_tomahawksteak_twist")
    inst.AnimState:SetBuild("dish_tomahawksteak_twist")
    inst.AnimState:PlayAnimation(data.anim or "idle1")
    inst.AnimState:SetSymbolBloom("eye")
    inst.AnimState:SetSymbolLightOverride("eye", 0.5)
    TOOLS_F.StartRandomAnims(inst, false, data.sg)
end

MakeFxFollow({ --旅星猫：蓝色猫猫
    name = "sivfea_real_collector_fofx",
    assets = {
        Asset("ANIM", "anim/skin/siving_feather_real_collector.zip"),
        Asset("ANIM", "anim/kitcoon_basic.zip"),  --官方猫咪动画模板
        Asset("ANIM", "anim/kitcoon_emotes.zip"),
        Asset("ANIM", "anim/kitcoon_jump.zip")
    },
    fx = { {
        fn_anim = SetAnim_cat, symbol = "lantern_overlay", x = 18, y = -12, z = 0,
        build = "siving_feather_real_collector"
    } }
})
MakeFxFollow({ --流星猫：棕色猫猫
    name = "sivfea_fake_collector_fofx",
    assets = {
        Asset("ANIM", "anim/skin/siving_feather_fake_collector.zip"),
        Asset("ANIM", "anim/kitcoon_basic.zip"),  --官方猫咪动画模板
        Asset("ANIM", "anim/kitcoon_emotes.zip"),
        Asset("ANIM", "anim/kitcoon_jump.zip")
    },
    fx = { {
        fn_anim = SetAnim_cat, symbol = "lantern_overlay", x = 18, y = -12, z = 0,
        build = "siving_feather_fake_collector"
    } }
})
MakeFxFollow({ --巫酋血骨面
    name = "sivmask_era_fofx", fn_anim = SetAnim_base, symbol = "swap_hat",
    assets = { Asset("ANIM", "anim/skin/siving_mask_gold_era.zip") },
    fx = {
        { idx = 0, build = "siving_mask_gold_era", anim = "idle1", isloop = true },
        { idx = 1, build = "siving_mask_gold_era", anim = "idle2", isloop = true },
        { idx = 2, build = "siving_mask_gold_era", anim = "idle3", isloop = true }
    }
})
MakeFxFollow({ --巫酋毒骨面
    name = "sivmask_era2_fofx", fn_anim = SetAnim_base, symbol = "swap_hat",
    assets = { Asset("ANIM", "anim/skin/siving_mask_gold_era2.zip") },
    fx = {
        { idx = 0, build = "siving_mask_gold_era2", anim = "idle1", isloop = true },
        { idx = 1, build = "siving_mask_gold_era2", anim = "idle2", isloop = true },
        { idx = 2, build = "siving_mask_gold_era2", anim = "idle3", isloop = true }
    }
})
MakeFxFollow({ --朽目撕裂者：调料后的地面动画
    name = "dish_tomahawksteak_twist_sc_fofx",
    assets = { Asset("ANIM", "anim/skin/dish_tomahawksteak_twist.zip") },
    fx = { { fn_anim = SetAnim_steak_twist, symbol = "swap_food", randomanim = true, sg = anims_steak_twist } }
})
MakeFxFollow({ --朽目撕裂者：在烹饪锅里的动画
    name = "dish_tomahawksteak_twist_cp_fofx",
    assets = { Asset("ANIM", "anim/skin/dish_tomahawksteak_twist.zip") },
    fx = { { fn_anim = SetAnim_steak_twist, symbol = "swap_cooked", randomanim = true, sg = anims_steak_twist } }
})
MakeFxFollow({ --朽目撕裂者：在手里的动画
    name = "dish_tomahawksteak_twist_fofx",
    assets = { Asset("ANIM", "anim/skin/dish_tomahawksteak_twist.zip") },
    fx = { {
        fn_anim = SetAnim_steak_twist, symbol = "swap_object", randomanim = true,
        anim = "swap1", sg = anims_steak_twist_swap
    } }
})
--[[MakeFx({ --朽目撕裂者：足迹特效
    name = "dish_tomahawksteak_twist_trailfx",
    assets = {
        Asset("ANIM", "anim/skin/dish_tomahawksteak_twist_trailfx.zip")
    },
    removetime = 1.5,
    fn_common = function(inst)
        inst:AddTag("steak_twist_trail")
    end,
    fn_anim = function(inst)
        inst.AnimState:SetBank("dish_tomahawksteak_twist_trailfx")
        inst.AnimState:SetBuild("dish_tomahawksteak_twist_trailfx")
        inst.kind_l = tostring(math.random(8))
        inst.AnimState:PlayAnimation("idle"..inst.kind_l)
        local scale = math.random()*0.4 + 0.9
        if math.random() >= 0.5 then
            inst.AnimState:SetScale(scale, scale)
        else
            inst.AnimState:SetScale(-scale, scale) --还能左右相反，差点忘了
        end
    end,
    fn_remove = function(inst)
        inst:DoTaskInTime(math.random()+1.5, function()
            inst.AnimState:PlayAnimation("pst"..inst.kind_l)
            inst:ListenForEvent("animover", inst.Remove)
        end)
    end
})]]--
MakeFx({ --朽目撕裂者：攻击特效
    name = "dish_tomahawksteak_twist_atkfx",
    assets = {
        Asset("ANIM", "anim/skin/dish_tomahawksteak_twist_atkfx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("dish_tomahawksteak_twist_atkfx")
        inst.AnimState:SetBuild("dish_tomahawksteak_twist_atkfx")
        inst.AnimState:PlayAnimation("idle"..tostring(math.random(6)))
        local scale = math.random()*0.5 + 1.2
        if math.random() >= 0.5 then
            inst.AnimState:SetScale(scale, scale)
        else
            inst.AnimState:SetScale(-scale, scale) --还能左右相反，差点忘了
        end
        inst.AnimState:SetSymbolBloom("eye")
        inst.AnimState:SetSymbolLightOverride("eye", 0.5)
        inst.AnimState:SetFinalOffset(3)
    end
})
MakeFx({ --朽目撕裂者：攻击特效2
    name = "dish_tomahawksteak_twist_atkfx2",
    assets = {
        Asset("ANIM", "anim/crystalblast_fx.zip"), --官方动画模板
        Asset("ANIM", "anim/skin/dish_tomahawksteak_twist_atkfx.zip")
    },
    fn_anim = function(inst)
        inst.AnimState:SetBank("crystalblast")
        inst.AnimState:SetBuild("dish_tomahawksteak_twist_atkfx")
        inst.AnimState:PlayAnimation("blast")
        inst.AnimState:SetLightOverride(0.5)
        inst.AnimState:SetFinalOffset(2)
        inst.AnimState:SetScale(0.6, 0.6)
    end
})

--各种普通小猫咪
local cats = {
    "kitcoon_forest", "kitcoon_savanna", "kitcoon_deciduous",
    "kitcoon_marsh", "kitcoon_grass", "kitcoon_rocky",
    "kitcoon_desert", "kitcoon_moon", "kitcoon_yot"
}
for _,v in pairs(cats) do
    MakeFxFollow({
        name = v.."_l_fofx",
        assets = {
            Asset("ANIM", "anim/"..v.."_build.zip"),
            Asset("ANIM", "anim/kitcoon_basic.zip"),  --官方猫咪动画模板
            Asset("ANIM", "anim/kitcoon_emotes.zip"),
            Asset("ANIM", "anim/kitcoon_jump.zip")
        },
        fx = { { fn_anim = SetAnim_cat, x = -10, y = -148, z = 0, randomanim = nil, build = v.."_build", symbol = "swap_hat" } }
    })
end
cats = nil

MakeFxFollow({ --乌鸦
    name = "crow_l_fofx",
    assets = {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/crow_build.zip")
    },
    fx = { { build = "crow_build", x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat" } }
})
MakeFxFollow({ --红雀
    name = "robin_l_fofx",
    assets = {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/robin_build.zip")
    },
    fx = { { build = "robin_build", x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat" } }
})
MakeFxFollow({ --雪雀
    name = "robin_winter_l_fofx",
    assets = {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/robin_winter_build.zip")
    },
    fx = { { build = "robin_winter_build", x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat" } }
})
MakeFxFollow({ --金丝雀
    name = "canary_l_fofx",
    assets = {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/canary_build.zip")
    },
    fx = { { build = "canary_build", x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat" } }
})
MakeFxFollow({ --鸽子
    name = "quagmire_pigeon_l_fofx",
    assets = {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/quagmire_pigeon_build.zip")
    },
    fx = { { build = "quagmire_pigeon_build", x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat" } }
})
MakeFxFollow({ --海鹦鹉
    name = "puffin_l_fofx",
    assets = {
        Asset("ANIM", "anim/crow.zip"),
        Asset("ANIM", "anim/puffin_build.zip")
    },
    fx = { { build = "puffin_build", x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat" } }
})
MakeFxFollow({ --月盲乌鸦
    name = "bird_mutant_l_fofx",
    assets = {
        Asset("ANIM", "anim/mutated_crow.zip"),
        Asset("ANIM", "anim/bird_mutant_build.zip")
    },
    fx = { {
        bank = "mutated_crow", build = "bird_mutant_build", face = 4, sg = anims_bird2,
        x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat"
    } }
})
MakeFxFollow({ --奇形鸟
    name = "bird_mutant_spitter_l_fofx",
    assets = {
        Asset("ANIM", "anim/mutated_robin.zip"),
        Asset("ANIM", "anim/bird_mutant_spitter_build.zip")
    },
    fx = { {
        bank = "mutated_robin", build = "bird_mutant_spitter_build", face = 4, sg = anims_bird2,
        x = -20, y = -148, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat"
    } }
})
MakeFxFollow({ --秃鹫
    name = "buzzard_l_fofx",
    assets = {
        Asset("ANIM", "anim/buzzard_build.zip"),
        Asset("ANIM", "anim/buzzard_basic.zip")
    },
    fx = { {
        bank = "buzzard", build = "buzzard_build", face = 4, sg = anims_buzzard,
        x = -10, y = -143, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat"
    } }
})
MakeFxFollow({ --小高脚鸟
    name = "smallbird_l_fofx",
    assets = { Asset("ANIM", "anim/smallbird_basic.zip") },
    fx = { {
        bank = "smallbird", build = "smallbird_basic", face = 4, sg = anims_smallbird, anim = "hatch",
        x = -10, y = -138, z = 0, fn_anim = SetAnim_bird, symbol = "swap_hat"
    } }
})
MakeFxFollow({ --便便
    name = "poop_l_fofx", fn_anim = SetAnim_base, symbol = "swap_hat",
    assets = {
        Asset("ANIM", "anim/poop.zip"),
        Asset("ANIM", "anim/flies.zip")
    },
    fx = {
        { idx = 0, x = -10, y = -130, z = 0, build = "poop", anim = "dump", animpush = "idle" },
        { idx = 1, x = -20, y = -130, z = 0, build = "poop", anim = "dump", animpush = "idle" },
        { idx = 2, x = -15, y = -130, z = 0, build = "poop", anim = "dump", animpush = "idle" },
        { x = -10, y = -60, z = 0, build = "flies", anim = "swarm_pre", animpush = "swarm_loop", isloop = true }
    }
})
MakeFxFollow({ --鸟粪
    name = "guano_l_fofx", fn_anim = SetAnim_base, symbol = "swap_hat",
    assets = {
        Asset("ANIM", "anim/guano.zip"),
        Asset("ANIM", "anim/flies.zip")
    },
    fx = {
        { idx = 0, x = -10, y = -130, z = 0, build = "guano", anim = "dump", animpush = "idle" },
        { idx = 1, x = -20, y = -130, z = 0, build = "guano", anim = "dump", animpush = "idle" },
        { idx = 2, x = -15, y = -130, z = 0, build = "guano", anim = "dump", animpush = "idle" },
        { x = -10, y = -60, z = 0, build = "flies", anim = "swarm_pre", animpush = "swarm_loop", isloop = true }
    }
})
MakeFxFollow({ --腐烂物
    name = "spoiled_food_l_fofx", fn_anim = SetAnim_base, symbol = "swap_hat",
    assets = { Asset("ANIM", "anim/spoiled_food.zip") },
    fx = {
        { idx = 0, x = 0, y = -140, z = 0, bank = "spoiled", build = "spoiled_food", anim = "idle" },
        { idx = 1, x = -10, y = -140, z = 0, bank = "spoiled", build = "spoiled_food", anim = "idle" },
        { idx = 2, x = -10, y = -140, z = 0, bank = "spoiled", build = "spoiled_food", anim = "idle" }
    }
})
MakeFxFollow({ --高脚鸟蛋
    name = "tallbirdegg_l_fofx1", symbol = "swap_hat", fn_anim = SetAnim_tallbirdegg,
    assets = { Asset("ANIM", "anim/tallbird_egg.zip") },
    fx = {
        { anim = "idle_happy", idx = 0, x = -10, y = -145, z = 0 },
        { anim = "idle_happy", idx = 1, x = -20, y = -145, z = 0 },
        { anim = "idle_happy", idx = 2, x = -20, y = -145, z = 0 }
    }
})
MakeFxFollow({ --高脚鸟蛋(热)
    name = "tallbirdegg_l_fofx2", symbol = "swap_hat", fn_anim = SetAnim_tallbirdegg,
    assets = { Asset("ANIM", "anim/tallbird_egg.zip") },
    fx = {
        { anim = "idle_hot", idx = 0, x = -10, y = -145, z = 0 },
        { anim = "idle_hot", idx = 1, x = -20, y = -145, z = 0 },
        { anim = "idle_hot", idx = 2, x = -20, y = -145, z = 0 }
    }
})
MakeFxFollow({ --高脚鸟蛋(冷)
    name = "tallbirdegg_l_fofx3", symbol = "swap_hat", fn_anim = SetAnim_tallbirdegg,
    assets = { Asset("ANIM", "anim/tallbird_egg.zip") },
    fx = {
        { anim = "idle_cold", idx = 0, x = -10, y = -145, z = 0 },
        { anim = "idle_cold", idx = 1, x = -20, y = -145, z = 0 },
        { anim = "idle_cold", idx = 2, x = -20, y = -145, z = 0 }
    }
})

local function SetAnim_shadow_battleaxe(inst, data)
    inst.AnimState:SetBank("nightmare_axe")
    inst.AnimState:SetBuild("nightmare_axe")
    inst.AnimState:PlayAnimation(data.anim, true)
    inst.AnimState:SetLightOverride(.1)
    inst.AnimState:SetSymbolLightOverride("red", .5)
    inst.AnimState:SetSymbolLightOverride("dread_red", .5)
    inst.AnimState:SetSymbolLightOverride("eye_inner", .5)
end
MakeFxFollow({ --暗影槌1级
    name = "shadow_battleaxe_l_fofx1", randomanim = true, symbol = "swap_object",
    assets = { Asset("ANIM", "anim/nightmare_axe.zip") },
    fn_anim = SetAnim_shadow_battleaxe,
    fx = {
        { idx = 0, idx2 = 2, anim = "swap_level1_f1" },
        { idx = 2, anim = "swap_level1_f3" }, --不是很懂为什么idx和第一个重复了
        { idx = 3, anim = "swap_level1_f4" }, --皆为level1
        { idx = 5, anim = "swap_level1_f6" },
        { idx = 6, anim = "swap_level1_f7" },
        { idx = 7, anim = "swap_level1_f8" }
    }
})
MakeFxFollow({ --暗影槌2级
    name = "shadow_battleaxe_l_fofx2", randomanim = true, symbol = "swap_object",
    assets = { Asset("ANIM", "anim/nightmare_axe.zip") },
    fn_anim = SetAnim_shadow_battleaxe,
    fx = {
        { idx = 0, idx2 = 2, anim = "swap_level2_f1" },
        { idx = 2, anim = "swap_level2_f3" }, --不是很懂为什么idx和第一个重复了
        { idx = 3, anim = "swap_level1_f4" }, --皆为level1
        { idx = 5, anim = "swap_level2_f6" },
        { idx = 6, anim = "swap_level2_f7" },
        { idx = 7, anim = "swap_level2_f8" }
    }
})
MakeFxFollow({ --暗影槌3级
    name = "shadow_battleaxe_l_fofx3", randomanim = true, symbol = "swap_object",
    assets = { Asset("ANIM", "anim/nightmare_axe.zip") },
    fn_anim = SetAnim_shadow_battleaxe,
    fx = {
        { idx = 0, idx2 = 2, anim = "swap_level3_f1" },
        { idx = 2, anim = "swap_level3_f3" }, --不是很懂为什么idx和第一个重复了
        { idx = 3, anim = "swap_level1_f4" }, --皆为level1
        { idx = 5, anim = "swap_level3_f6" },
        { idx = 6, anim = "swap_level3_f7" },
        { idx = 7, anim = "swap_level3_f8" }
    }
})
MakeFxFollow({ --暗影槌4级
    name = "shadow_battleaxe_l_fofx4", randomanim = true, symbol = "swap_object",
    assets = { Asset("ANIM", "anim/nightmare_axe.zip") },
    fn_anim = SetAnim_shadow_battleaxe,
    fx = {
        { idx = 0, idx2 = 2, anim = "swap_level4_f1" },
        { idx = 2, anim = "swap_level4_f3" }, --不是很懂为什么idx和第一个重复了
        { idx = 3, anim = "swap_level1_f4" }, --皆为level1
        { idx = 5, anim = "swap_level4_f6" },
        { idx = 6, anim = "swap_level4_f7" },
        { idx = 7, anim = "swap_level4_f8" }
    }
})

MakeFxFollow({ --阴郁回旋镖
    name = "voidcloth_boomerang_l_fofx", randomanim = true, symbol = "swap_object",
    assets = { Asset("ANIM", "anim/boomerang_voidcloth.zip") },
    fn_anim = function(inst, data)
        inst.AnimState:SetBank("boomerang_voidcloth")
        inst.AnimState:SetBuild("boomerang_voidcloth")
        inst.AnimState:PlayAnimation(data.anim, true)
        inst.AnimState:SetLightOverride(.1)
    end,
    fx = {
        { idx = 0, idx2 = 2, anim = "swap_loop_f1" },
        { idx = 2, anim = "swap_loop_f3" } --不是很懂为什么idx和第一个重复了
    }
})

local function SetAnim_rabbithat(inst, data)
    inst.AnimState:SetBank("rabbithat")
	inst.AnimState:SetBuild(data.build)
	inst.AnimState:AddOverrideBuild("hat_rabbit")
    inst.AnimState:PlayAnimation(data.anim, true)
end
MakeFxFollow({ --洞穴花环
    name = "rabbithat_l_fofx1", randomanim = true, symbol = "swap_hat", fn_anim = SetAnim_rabbithat,
    assets = {
        Asset("ANIM", "anim/hat_rabbit.zip"),
        Asset("ANIM", "anim/rabbit_build.zip")
    },
    fx = {
        { idx = 0, bank = "rabbithat", build = "rabbit_build", anim = "idle1", isloop = true },
        { idx = 1, bank = "rabbithat", build = "rabbit_build", anim = "idle2", isloop = true },
        { idx = 2, bank = "rabbithat", build = "rabbit_build", anim = "idle3", isloop = true }
    }
})
MakeFxFollow({ --洞穴花环(冬季白兔)
    name = "rabbithat_l_fofx2", randomanim = true, symbol = "swap_hat", fn_anim = SetAnim_rabbithat,
    assets = {
        Asset("ANIM", "anim/hat_rabbit.zip"),
        Asset("ANIM", "anim/rabbit_winter_build.zip")
    },
    fx = {
        { idx = 0, bank = "rabbithat", build = "rabbit_winter_build", anim = "idle1", isloop = true },
        { idx = 1, bank = "rabbithat", build = "rabbit_winter_build", anim = "idle2", isloop = true },
        { idx = 2, bank = "rabbithat", build = "rabbit_winter_build", anim = "idle3", isloop = true }
    }
})
MakeFxFollow({ --洞穴花环(梦魇黑兔)
    name = "rabbithat_l_fofx3", randomanim = true, symbol = "swap_hat", fn_anim = SetAnim_rabbithat,
    assets = {
        Asset("ANIM", "anim/hat_rabbit.zip"),
        Asset("ANIM", "anim/beard_monster.zip")
    },
    fx = {
        { idx = 0, bank = "rabbithat", build = "beard_monster", anim = "idle1", isloop = true },
        { idx = 1, bank = "rabbithat", build = "beard_monster", anim = "idle2", isloop = true },
        { idx = 2, bank = "rabbithat", build = "beard_monster", anim = "idle3", isloop = true }
    }
})

---------------
---------------

return unpack(prefs)
