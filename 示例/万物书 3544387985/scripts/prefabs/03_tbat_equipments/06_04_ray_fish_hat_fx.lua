--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    复制齿轮帽子的相关特效机制

    wagpunkhat

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 素材
	local assets =
	{
		Asset("ANIM", "anim/tbat_eq_ray_fish_hat.zip"),
		Asset("ANIM", "anim/tbat_eq_ray_fish_hat_sweetheart_cocoa.zip"),
	}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
	local ret_prefabs = {}
	local hide_test_symble_fn = function(inst,parent)
		inst.AnimState:HideSymbol("test")
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 原始的外观
	table.insert(ret_prefabs,TBAT.MODULES:CreateAnimHat("tbat_eq_ray_fish_hat_fx",{
		bank = "tbat_eq_ray_fish_hat",
		build = "tbat_eq_ray_fish_hat",
		anim_down = "hat1",
		anim_side = "hat2",
		anim_up = "hat3",
		loop = true,
		child_fn = hide_test_symble_fn
	},assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 原始的外观
	table.insert(ret_prefabs,TBAT.MODULES:CreateAnimHat("tbat_eq_ray_fish_hat_sweetheart_cocoa_hat_fx",{
		bank = "tbat_eq_ray_fish_hat_sweetheart_cocoa",
		build = "tbat_eq_ray_fish_hat_sweetheart_cocoa",
		anim_down = "down_eq",
		anim_side = "side_eq",
		anim_up = "up_eq",
		loop = true,
		child_fn = hide_test_symble_fn
	},assets))
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return unpack(ret_prefabs)


	--- 测试用的
	-- ,TBAT.MODULES:CreateAnimHat("tbat_test_fan_wheel_fx",{
	-- 	bank = "tbat_test_fan_wheel",
	-- 	build = "tbat_test_fan_wheel",
	-- 	anim_down = "down_fan",
	-- 	anim_side = "side_fan",
	-- 	anim_up = "up_fan",
	-- 	loop = true,
	-- 	override_follow_symbol = "swap_body_tall",
	-- 	override_framebegin = 7,
	-- 	override_frameend = 12,
	-- 	child_fn = function(inst,parent,index)
	-- 		if index <= 10 then
	-- 			inst.AnimState:PlayAnimation("up_fan",true)
	-- 		elseif index == 11 then
	-- 			inst.AnimState:PlayAnimation("side_fan",true)
	-- 		else
	-- 			inst.AnimState:PlayAnimation("down_fan",true)
	-- 		end
	-- 	end,
	-- },{
	-- 	Asset("ANIM", "anim/tbat_test_fan_wheel.zip"),
	-- })