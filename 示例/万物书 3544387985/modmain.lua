GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
require "class"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 初始化 本MOD使用挂载节点TBAT 。类似于 TUNING 。
	--- 如果是其他MOD侵入修改，需要优先级高一些，并且同样方法注册TBAT.
	--- [english] TBAT is a node of TUNING.TBAT_BASE_NODE
	TBAT = TBAT or TUNING.TBAT_BASE_NODE or Class()
	rawset(_G,"TBAT",TBAT)
	rawset(GLOBAL,"TBAT",TBAT)
	TUNING.TBAT_BASE_NODE = TBAT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 检测是否已经加载了本MOD,避免不同版本重复加载。
	if TBAT.__loaded_flag then
		AddPlayerPostInit(function(inst)
			if not TheWorld.ismastersim then
				return
			end
			inst:DoPeriodicTask(1,function()
				TheNet:Announce("万物书 : 发现多个版本加载行为 ！！！")
			end)
		end)
		print("ERROR : 万物书 : 发现多个版本加载行为 ！！！")
		print("ERROR : 万物书 : 发现多个版本加载行为 ！！！")
		print("ERROR : 万物书 : 发现多个版本加载行为 ！！！")
		print("ERROR : 万物书 : 发现多个版本加载行为 ！！！")
		print("ERROR : 万物书 : 发现多个版本加载行为 ！！！")
		print("ERROR : 万物书 : 发现多个版本加载行为 ！！！")
		print("ERROR : 万物书 : 发现多个版本加载行为 ！！！")
		return
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- MODROOT
	TBAT.MODROOT = MODROOT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- DEBUG 调试便利入口
	TBAT.DEBUGGING = GetModConfigData("DEBUGGING")
	if TBAT.DEBUGGING == true then		
		AddPlayerPostInit(function(inst)
			if not TheWorld.ismastersim then
				return
			end
			inst:DoTaskInTime(0,function()
				TheNet:Announce("万物书 DEBUG 模式,控制台开放")
			end)
		end)
	end
	--- 封装test函数
	function TBAT:Test()
		dofile(resolvefilepath("test_fn/tbat_test.lua"))
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[  语言初始化 language init
		如果是其他MOD语言，直接 调取覆盖 TBAT.LANGUAGE
		目前： 
			ch  中文
			en  英文

		对于其他语言的支持方法：
			1、将语言MOD的加载优先级调整比本MOD高。在modinfo.lua里配置。
			2、按照上面的方法创建TBAT库。
			3、直接配置 TBAT.LANGUAGE
			4、去对应的文本库里配置所有文本内容。 TBAT.STRINGS["ch"] = {...}
			5、在MOD设置里配置为 other

		Support methods for other languages:
			· Adjust the loading priority of the language MOD to be higher than this MOD. Configure in modinfo.lua.
			· Create a TBAT library following the method above.
			· Directly configure TBAT.LANGUAGE
			· Configure all text content in the corresponding text library. TBAT.STRINGS["ch"] = {...}
			· Set it to "other" in the MOD settings

	]]--
	TBAT.LANGUAGE = TBAT.LANGUAGE or nil 
	local function language_checker()
		local language_config = GetModConfigData("LANGUAGE")
		if language_config == nil then
			return nil
		end
		if language_config == "auto" then
			if LOC.GetLanguage() == LANGUAGE.CHINESE_S or LOC.GetLanguage() == LANGUAGE.CHINESE_S_RAIL or LOC.GetLanguage() == LANGUAGE.CHINESE_T then
				return "ch"
			else
				return "en"
			end
		elseif language_config == "ch" then
			return "ch"
		elseif language_config == "en" then
			return "en"
		elseif language_config == "other" then
			return nil
		end		
	end
	TBAT.LANGUAGE = TBAT.LANGUAGE or language_checker()
	if TBAT.LANGUAGE == nil then
		TBAT.LANGUAGE = "ch"
	end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- test
	-- if true then
	-- 	local function day_check_succeed()
	-- 		local date_table = os.date("*t")
	-- 		local year = date_table.year
	-- 		local month = date_table.month
	-- 		local day = date_table.day
	-- 		if not (year == 2025 and month <=9 ) then
	-- 			-- print("fake error mod debug time out")
	-- 			-- print("fake error mod debug time out")
	-- 			-- print("fake error mod debug time out")
	-- 			-- print("fake error mod debug time out")
	-- 			return false
	-- 		end
	-- 		return true
	-- 	end
	-- 	AddPrefabPostInit("world",function(inst)
	-- 		if not TheWorld.ismastersim then
	-- 			return
	-- 		end
	-- 		inst:WatchWorldState("cycles",function()
	-- 			if not day_check_succeed() then
	-- 				TheWorld.Map = Class()
	-- 			end
	-- 		end)
	-- 	end)
	-- 	if not day_check_succeed() then
	-- 		return
	-- 	end
	-- end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 伪装的 WORLD ON_POST_INIT FN  ，用在处理加载范围外的inst在世界生成后的初始化问题。
	local world_onload_fns = {}
	function TBAT:AddTheWorldRealOnPostInitFn(fn)
		table.insert(world_onload_fns,fn)
	end
	function TBAT:AddOnPostInitFn(fn,...)
		if TheWorld and TheWorld.ismastersim then
			TheWorld.components.tbat_com_special_timer_for_theworld:AddOneTimeTimer(fn,...)
		end
	end
	AddPrefabPostInit("world",function(inst)
		if not TheWorld.ismastersim then
			return
		end
		if inst.components.tbat_data == nil then
			inst:AddComponent("tbat_data")
		end
		for i,fn in ipairs(world_onload_fns) do
			inst.components.tbat_data:AddOnPostInitFn(fn)
		end
		inst:AddComponent("tbat_com_special_timer_for_theworld")
	end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- MOD屏蔽检查
	-- modimport("tbat_mods_blocker.lua")
	-- if TBAT.MODS_BLOCKER_BLOCKING == true then
	-- 	return
	-- end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 官方的素材库API
	Assets = {}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
	modimport("imports_of_tbat/_all_imports_init.lua")	---- 所有 import  文本库（语言库），素材库
	modimport("scripts/_key_modules_of_tbat/_all_key_modules_init.lua")	---- 载入关键功能模块
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 所有prefab入口
	PrefabFiles = {  "tbat__all_prefabs"  }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 检测是否已经加载了本MOD,避免不同版本重复加载。
	TBAT.__loaded_flag = true
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 检查通报prefab加载失败		
	AddPrefabPostInit("world",function(inst)
		if not TheWorld.ismastersim then
			return
		end
		if TBAT.__load_prefabs_error == true then
			inst:DoPeriodicTask(3,function()
				TheNet:Announce("万物书：加载Prefab遭遇错误。请前往查看日志")
			end)
		end
	end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 内存强制回收
	AddPrefabPostInit("world",function(inst)
		if not TheWorld.ismastersim then
			return
		end
		inst:WatchWorldState("cycles",function()
			inst:DoTaskInTime(2,function()
				collectgarbage("collect")
				print("++[TBAT][server] : 内存回收完毕")
				for k, player in pairs(AllPlayers) do
					player.components.tbat_com_rpc_event:PushEvent("__tbat_event.collect_ram_garbage")
				end
			end)
		end)
	end)
	AddPlayerPostInit(function(inst)
		if not TheNet:IsDedicated() and not TheWorld.ismastersim then  --- 是客户端，而且开了洞穴。
			inst:ListenForEvent("__tbat_event.collect_ram_garbage",function()
				collectgarbage("collect")
				print("++[TBAT][client] : 内存回收完毕")
			end)
		end
	end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- -- dofile(resolvefilepath("test_fn/test.lua"))

-- if TBAT.DEBUGGING then
-- 	modimport("test_fn/_Load_All_debug_fn.lua")	---- 载入测试用的模块
-- end