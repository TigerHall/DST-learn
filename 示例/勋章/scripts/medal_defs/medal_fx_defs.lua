local function FinalOffset1(inst)
    inst.AnimState:SetFinalOffset(1)
end
local function GroundOrientation(inst)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
end
local function OceanTreeLeafFxFallUpdate(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, y - inst.fall_speed * FRAMES, z)
end
--特效统一配置
local medal_fx={
	{--血蜜粘液
		name = "medal_blood_honey_splat",
		bank = "spat_splat",
		build = "medal_blood_honey_splat",
		anim = "idle",
	},
	{--血蜜飞溅
		name = "medal_honey_splash",
		bank = "honey_splash",
		build = "medal_honey_splash",
		anim = "anim",
		nofaced = true,
		transform = Vector3(1.4, 1.4, 1.4),
		fn = FinalOffset1,
	},
	{--血蜜飞溅(aoe效果)
		name = "medal_honey_splash2",
		bank = "honey_splash",
		build = "medal_honey_splash",
		anim = "anim",
		nofaced = true,
		transform = Vector3(1.4, 1.4, 1.4),
	},
	{--防护罩
		name = "medal_shield",
		bank = "stalker_shield",
		build = "stalker_shield",
		anim = "idle1",
		nofaced = true,
		transform = Vector3(1.4, 1.4, 1.4),
		sound="dontstarve/creatures/together/stalker/shield",
	},
	{--防护罩(玩家)
		name = "medal_shield_player",
		bank = "stalker_shield",
		build = "stalker_shield",
		anim = "idle1",
		nofaced = true,
		-- transform = Vector3(1.4, 1.4, 1.4),
		sound="dontstarve/creatures/together/stalker/shield",
	},
    {--球状闪电1
        name = "medal_spark_shock_fx",
        bank = "shock_fx",
        build = "medal_shock_fx",
        anim = "weremoose_shock",
        sound = "moonstorm/common/moonstorm/spark_attack",
        eightfaced = true,
        autorotate = true,
        fn = FinalOffset1,
    },
    {--球状闪电2
        name = "medal_spark_shock_fx2",
        bank = "shock_fx",
        build = "medal_shock_fx",
        anim = "weregoose_shock",
        sound = "moonstorm/common/moonstorm/spark_attack",
        eightfaced = true,
        autorotate = true,
        fn = FinalOffset1,
    },
    {--时空尘雾特效1
        name = "medal_spacetime_puff_small",
        bank = "small_puff",
        build = "medal_spacetime_puff_small",
        anim = "puff",
        sound = "dontstarve/common/deathpoof",
    },
    {--时空尘雾特效2
        name = "medal_spacetime_puff",
        bank = "sand_puff",
        build = "medal_spacetime_puff",
        anim = "forage_out",
        sound = "dontstarve/common/deathpoof",
    },
    {--时空晶矿破碎特效
        name = "medal_spacetime_glass_ground_fx",
        bank = "moonglass_charged",
        build = "medal_spacetime_charged_tile",
        anim = "explosion",
        fn = GroundOrientation,
    },
    {--时空晶矿破碎残渣
        name = "medal_spacetime_glass_fx",
        bank = "moonglass_charged",
        build = "medal_spacetime_charged_tile",
        anim = "crack_fx",
    },
    {--驱光遗骸从骨架复活时的特效
        name = "medal_shadowthrall_revive_from_bones_fx",
        bank = "lavaarena_player_revive_fx",
        build = "lavaarena_player_revive_fx",
        anim = "player_revive",
        sound = "dontstarve/common/revive",
        bloom = true,
        fourfaced = true,
        autorotate = true,
        fn = function(inst)
            FinalOffset1(inst)
            inst.AnimState:SetMultColour(0/255, 0/255, 0/255, 0.75)
        end,
    },
    {--驱光遗骸诞生特效
        name = "medal_shadowthrall_screamer_spawn_fx",
        bank = "shadow_thrall_projectile_fx",
        build = "shadow_thrall_projectile_fx",
        anim = "projectile_impact",
        fn = function(inst)
            inst.AnimState:SetScale(2, 2)
        end,
    },
    -- {--混乱特效
    --     name = "medal_confusion_fx",
    --     bank = "fx_wathgrithr_buff",
    --     build = "medal_fx_wathgrithr_buff",
    --     anim = "fx_shadowaligned",
    -- },
    -- {--叶片攻击特效
        -- name = "medal_origin_mushgnome_attack_fx",
        -- bank = "alterguardian_phase3",
        -- build = "alterguardian_phase3",
        -- anim = "attk_stab2_loop",
        -- fn = function(inst)
            -- inst.AnimState:SetScale(.5, .5)
			-- inst.AnimState:HideSymbol("p3_moon_base")
			-- inst.AnimState:HideSymbol("p3_moon_arms")
			-- inst.AnimState:HideSymbol("p3_fx_ball_centre")
			-- inst.AnimState:HideSymbol("p3_fx_top_loop")
			-- inst.AnimState:HideSymbol("p3_eye_fx")
        -- end,
    -- },
    {--寄生值消耗特效
        name = "medal_origin_parasitic_fx",
        bank = "wortox_teleport_reviver_fx",
        build = "wortox_teleport_reviver_fx",
        anim = "decoy_expirefade",
        fn = function(inst)
            -- inst.AnimState:SetScale(.5, .5)
            -- inst.AnimState:SetMultColour(0/255, 255/255, 255/255, 1)
            FinalOffset1(inst)
            inst.AnimState:SetAddColour(20/255, 160/255, 50/255, 0.75)
			inst.AnimState:HideSymbol("spiral_ripple")
        end,
    },
    {--混乱特效
        name = "medal_confusion_fx",
        bank = "cursed_fx",
        build = "cursed_fx",
        anim = "idle",
        sound = "monkeyisland/wonkycurse/curse_fx",
        nofaced = true,
        fn = function(inst)
            FinalOffset1(inst)
            -- inst.AnimState:SetScale(.5, .5)
            inst.AnimState:SetMultColour(100/255, 100/255, 100/255, 0.75)
            -- inst.AnimState:SetAddColour(20/255, 160/255, 50/255, 0.75)
			inst.AnimState:HideSymbol("fx_fur_part")
        end,
    },
    {--本源之树落花特效
        name = "medal_origin_tree_leaf_fx",
        bank = "oceantree_leaf_fx",
        build = "medal_origin_tree_leaf_fx",
        anim = "fall",
        fn = function(inst)
            local scale = 1 + 0.3 * math.random()
            inst.Transform:SetScale(scale, scale, scale)
            inst.fall_speed = 2.75 + 3.5 * math.random()
            inst:DoPeriodicTask(FRAMES, OceanTreeLeafFxFallUpdate)
        end,
    },
}


--子弹特效
local shot_types = {"mandrakeberry", "devoursoul", "sanityrock", "sandspike", "spines", "water", "houndstooth", "taunt"}
for _, shot_type in ipairs(shot_types) do
    table.insert(medal_fx, {
        name = "slingshotammo_hitfx_"..shot_type,
        bank = "slingshotammo",
        build = "medalslingshotammo",
        anim = "used",
        fn = function(inst)
			if shot_type ~= "rocks" then
		        inst.AnimState:OverrideSymbol("rock", "medalslingshotammo", shot_type)
			end
		    inst.AnimState:SetFinalOffset(3)
		end,
    })
end

return medal_fx