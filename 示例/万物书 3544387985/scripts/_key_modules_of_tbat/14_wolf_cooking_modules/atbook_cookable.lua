--------------------------------------------------------------------------
--[[ Tool ]]
--[[ 工具 ]]
--------------------------------------------------------------------------
local utils = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_utils")
require("util")

--------------------------------------------------------------------------
--[[ Get Cookable Recipe ]]
--[[ 查找可烹饪配方 ]]
--------------------------------------------------------------------------

--以下代码于客户端运行

local cooking = require("cooking")

local aliases = utils.aliases

local function GetIngTagClasses(items)
	if next(items) == nil then
		return {}
	end
	local classes = {}
	for name, amt in pairs(items) do
		local ing_property = cooking.ingredients[aliases[name] or name]
		if ing_property ~= nil then
			for tagname, _ in pairs(ing_property.tags) do
				if tagname ~= "precook" and tagname ~= "dried" then
					classes[tagname] = classes[tagname] or {}
					classes[tagname][name] = amt
				end
			end
		end
	end
	return classes
end

local function GetNumber(item, num_ing)
	-- local name_ing = aliases[item] or item
	if num_ing ~= nil then
		return num_ing[item] or 0
	else
		return 0
	end
end

local function GetIngTagClassesReduce(classes, name, amt)
	--计算去除amt个name后的TagClasses，需确保name在classes中，且至少有amt个
	local ing_property = cooking.ingredients[aliases[name] or name]
	if ing_property ~= nil then
		for tagname, _ in pairs(ing_property.tags) do
			if tagname ~= "precook" and tagname ~= "dried" and classes[tagname] ~= nil then
				classes[tagname][name] = math.max(classes[tagname][name] - amt, 0)
			end
		end
	end
	return classes
end

local function GetNumIngReduce(num_ing, name, amt)
	--计算去除amt个name后的num_ing，需确保name在num_ing中，且至少有amt个
	if num_ing[name] ~= nil then
		num_ing[name] = math.max(num_ing[name] - amt, 0)
		if num_ing[name] == 0 then
			num_ing[name] = nil
		end
	end
	return num_ing
end

local function RecipeToNumIng(recipe)
	-- Convert recipe table to num_ing table
	-- 得到该配方中每种食材需要的数量
	-- recipe table: {[1] = ing1, [2] = ing2, [3] = ing3, [4] = ing4}
	-- num_ing table: {[ing1] = num_ing1, [ing2] = num_ing2, ...}
	local num_ing = {}
	for _, ing in ipairs(recipe) do
		if num_ing[ing] == nil then
			num_ing[ing] = 1
		else
			num_ing[ing] = num_ing[ing] + 1
		end
	end
	return num_ing
end

local function GetSumTags(ings)
	--[[计算ings的tag之和
		ings {[1]=meat, [2]=meat, [3]=carrot}
		sumtag {'meat'=2, 'veggie'=1}
	]]
	local sumtag = {}
	for _, ing in ipairs(ings) do
		if type(ing) == "table" then
			ing = ing[1]
		end
		for tag, tagval in pairs(cooking.ingredients[ing].tags) do
			sumtag[tag] = sumtag[tag] and sumtag[tag] + tagval or tagval
		end
	end
	return sumtag
end

local function GetCurMixTags(num_ings, mixtags)
	local cur_mixtags = {}
	for ingname, _ in pairs(num_ings) do
		local mix_tag = mixtags[ingname]
		cur_mixtags[mix_tag] = cur_mixtags[mix_tag] or {}
		table.insert(cur_mixtags[mix_tag], ingname)
	end
	local list_mixtag = {}
	for mtag, _ in pairs(cur_mixtags) do
		table.insert(list_mixtag, mtag)
	end
	--[[
		num_ings	
		{
			['green_cap'] = 1,
			['twigs'] = 3,
			['red_cap'] = 1,
			['blue_cap'] = 1,
			['monstermeat'] = 1,
			['meat'] = 1,
			['berries'] = 3
		}
		cur_mixtags
		{
			['1inedible4'] = {
				[1] = 'twigs'
			},
			['1meat4'] = {
				[1] = 'meat'
			},
			['2meat4monster4'] = {
				[1] = 'monstermeat'
			},
			['1veggie2'] = {
				[1] = 'green_cap',
				[2] = 'red_cap',
				[3] = 'blue_cap'
			},
			['1fruit2'] = {
				[1] = 'berries'
			}
		}
		list_mixtag
		{
			[1] = '1inedible4',
			[2] = '1meat4',
			[3] = '2meat4monster4',
			[4] = '1veggie2',
			[5] = '1fruit2'
		}	
	]]
	return cur_mixtags, list_mixtag
end

local function CheckMaxmix(sumtag, maxmix)
	--[[判断ings是否满足maxmix的要求
	ings {[1]=meat, [2]=meat, [3]=carrot}
	例：花沙拉
	['maxmix'] = {
		[1] = {
			['amt'] = 0,
			['tag'] = 'inedible'
		},
		[2] = {
			['amt'] = 0,
			['tag'] = 'fruit'
		},
		[3] = {
			['amt'] = 0,
			['tag'] = 'sweetener'
		},
		[4] = {
			['amt'] = 0,
			['tag'] = 'egg'
		},
		[5] = {
			['amt'] = 0,
			['tag'] = 'meat'
		}
	}]]
	local pass = true
	for _, cond in ipairs(maxmix) do
		if sumtag[cond.tag] ~= nil and sumtag[cond.tag] > cond.amt then
			pass = false
			break
		end
	end
	return pass
end

local function CheckMintags(sumtag, mintags)
	local pass = true
	for tag, amt in pairs(mintags) do
		if sumtag[tag] == nil or (sumtag[tag] ~= nil and sumtag[tag] < amt) then
			pass = false
			break
		end
	end
	return pass
end

local function GetAllCandidateRecipes(cooker, names)
	local prefabs = {}
	local tags = {}
	for _, v in pairs(names) do
		if type(v) == "table" then
			v = v[1]
		end
		local name = aliases[v] or v
		prefabs[name] = (prefabs[name] or 0) + 1
		local data = cooking.ingredients[name]
		if data ~= nil then
			for tagname, tagval in pairs(data.tags) do
				tags[tagname] = (tags[tagname] or 0) + tagval
			end
		end
	end

	local recipes = cooking.recipes[cooker] or {}
	local candidates = {}

	--find all potentially valid recipes
	for _, v in pairs(recipes) do
		if v.test(cooker, prefabs, tags) then
			table.insert(candidates, v)
		end
	end

	table.sort(candidates, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
	if #candidates > 0 then
		--find the set of highest priority recipes
		local top_candidates = {}
		local val = candidates[1].priority or 0

		for k, v in ipairs(candidates) do
			if k > 1 and (v.priority or 0) < val then
				break
			end
			table.insert(top_candidates, v.name)
		end
		return top_candidates
	end

	return candidates
end

local function CheckInName(ing, minlist)
	--判断某种ing是否是某种料理的names中限定的食材（如火龙果派中的火龙果）
	if minlist == nil then
		return false
	end
	local in_name = false
	--同一个料理有不同的做法
	for _, method in ipairs(minlist) do
		for ingname, ingamt in pairs(method.names) do
			if ing == ingname then
				in_name = true
				break
			end
		end
		if in_name then
			break
		end
	end
	return in_name
end

local function CheckAllInName(ing, food_names, food_detail)
	for _, food_name in ipairs(food_names) do
		if not CheckInName(ing, food_detail[food_name].minlist) then
			return false
		end
	end
	return true
end

local function CheckAllTagForOneFood(ings, food_names, food_detail)
	--一组ing和一组料理，检查是否存在：对某一个料理，所有的ing都不属于name
	--此时ings所属的mixtag组合不需要继续遍历，可以肯定无法做出想要的料理
	for _, food_name in ipairs(food_names) do
		local all_tag = true
		for _, ing in ipairs(ings) do
			if CheckInName(ing, food_detail[food_name].minlist) then
				all_tag = false
				break
			end
			if all_tag == true then
				return true
			end
		end
	end
	return false
end

local function CheckEnough(part_recipe, num_ings)
	--检验是否满足配方的数量要求
	local ing_num = RecipeToNumIng(part_recipe)
	for ing, ingnum in pairs(ing_num) do
		if ingnum > GetNumber(ing, num_ings) then
			return false
		end
	end
	return true
end

local function GetCookable(food_name, diary_num_ings, need_number)
	if food_name == "wetgoop" then
		return {}, false
	end
	if ThePlayer == nil or ThePlayer.player_classified == nil then
		return {}, false
	end
	local diary_detail  = ThePlayer.player_classified.atbook_fooddetail
	local diary_mixtags = ThePlayer.player_classified.atbook_mixtags

	if diary_detail[food_name] == nil then
		return {}, false
	end

	local recipe_minlist = diary_detail[food_name].minlist
	local recipe_maxmix  = diary_detail[food_name].maxmix
	local cooker         = diary_detail[food_name].cooker
	if recipe_minlist == nil or recipe_maxmix == nil then
		return {}, false
	end

	local cookable_recipe  = {} --只包含食材充足的配方
	local cookable         = false

	local tag_classes_orig = GetIngTagClasses(diary_num_ings) --将ing按照tag分类
	local all_mixtags, list_all_mixtags

	--同一个料理有不同的做法
	for _, method in ipairs(recipe_minlist) do
		local tag_classes = deepcopy(tag_classes_orig) --将ing按照tag分类
		local num_ings = deepcopy(diary_num_ings)

		--计算确定name的食材的数量(<=4)
		local total_names = 0
		local enough = true
		local cur_combination = {}
		for name, amt in pairs(method.names) do
			if GetNumber(name, num_ings) >= amt then
				total_names = total_names + amt
				for _ = 1, amt do
					table.insert(cur_combination, { name, "name" })
				end
				--[[tag_classes的形式是
					{
						['inedible'] = {
							['lightninggoathorn'] = 1,
							['twigs'] = 3,
							['boneshard'] = 3
						},
						['egg'] = {
							['tallbirdegg'] = 1
						},
						...
					}
				]]
				tag_classes = GetIngTagClassesReduce(tag_classes, name, amt) --计算去除amt个name后的tag_classes
				--[[num_ings的形式是
					{
						['lightninggoathorn'] = 1,
						['twigs'] = 3,
						['boneshard'] = 3,
						['tallbirdegg']=1,
						...
					}]]
				num_ings = GetNumIngReduce(num_ings, name, amt) --计算去除amt个name后的num_ings
			else
				enough = false
			end
		end

		--确定name的食材的数量足够
		if enough then
			local total_tags = 4 - total_names
			-- if food_name == "bonesoup" then
			-- 	print("total_tags", total_tags)
			-- end

			--4种食材均已确定
			if total_tags == 0 then
				if table.contains(GetAllCandidateRecipes(cooker, cur_combination), food_name) then
					cookable = true
					if need_number > #cookable_recipe then
						table.insert(cookable_recipe, cur_combination)
					else
						break
					end
				end
			end

			if next(tag_classes) ~= nil and next(num_ings) ~= nil then
				-- 判断玩家是否拥有当前做法所需的所有tag
				local have_all_tags = true
				for tag, _ in pairs(method.tags) do
					if tag_classes[tag] == nil then
						have_all_tags = false
						break
					end
				end

				-- if food_name == "bonestew" then
				-- 	print("have_all_tags", have_all_tags)
				-- end

				if have_all_tags then
					-- 可能出现某食物未指定tag，如大厨的骨头汤，只指定了2个骨片和1个洋葱，所以不能用needed_mixtags来简化计算
					-- --计算玩家拥有的含有当前做法所需tag的所有ing（已将烤制食材合并入原始食材中）
					-- local candidate_ing = {}
					-- for tag, _ in pairs(method.tags) do
					-- 	for ing, _ in pairs(tag_classes[tag]) do
					-- 		candidate_ing[ing] = 1
					-- 	end
					-- end
					-- -- local numd_ing = {}
					-- -- for k,_ in pairs(candidate_ing) do
					-- -- 	table.insert(numd_ing, k)
					-- -- end
					-- local needed_mixtags, list_needed_mixtags = GetCurMixTags(candidate_ing)
					all_mixtags, list_all_mixtags = GetCurMixTags(num_ings, diary_mixtags)

					--有1个食材位未确定
					if total_tags == 1 then
						-- 选出1个类别
						for j = 1, #list_all_mixtags do --对于原版，最多进行26次循环，每次循环最多找出一种cookable的配方
							-- 生成recipe
							local cur_mixtag = list_all_mixtags[j]
							--该ing的tag满足最小要求
							local sumtag = GetSumTags({ all_mixtags[cur_mixtag][1] })
							local cur_combination_d = deepcopy(cur_combination)
							table.insert(cur_combination_d, all_mixtags[cur_mixtag][1])
							local sumtag_4 = GetSumTags(cur_combination_d)
							if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag_4, recipe_maxmix) then --该类别满足tag要求
								for m = 1, #all_mixtags[cur_mixtag] do
									local cur_test_ing = all_mixtags[cur_mixtag][m]
									cur_combination_d = deepcopy(cur_combination)
									table.insert(cur_combination_d, cur_test_ing)
									local candidate_recipes = GetAllCandidateRecipes(cooker, cur_combination_d)
									if table.contains(candidate_recipes, food_name) then
										cookable = true
										if need_number > #cookable_recipe then
											table.insert(cookable_recipe, cur_combination_d)
										else
											break
										end
										break
									else --如果满足了要求却做不出来，就是优先级的问题，需要尝试该类别的其他ing
										--本次做不出来是因为加入了料理限定食材（如因加入火龙果导致作出火龙果派），则需尝试同类别其他食材
										--否则是因为该类别的食材导致tag满足了高优先级料理的要求，则同类别其他食材也无法作出需要的料理，所以不需要继续尝试了
										if not CheckAllInName(cur_test_ing, candidate_recipes, diary_detail) then
											break
										end
									end
								end
								if need_number <= #cookable_recipe then
									break
								end
							end
						end
						if need_number <= #cookable_recipe then
							break
						end
					else
						--计算玩家拥有的所有ing，以列表形式存储（已将烤制食材合并入原始食材中）
						-- local numd_ing_all = {}
						-- for k,_ in pairs(num_ings) do
						-- 	table.insert(numd_ing_all, k)
						-- end
						--[[cur_mixtags的形式是
							{
								['1inedible4'] = {
									[1] = ['lightninggoathorn'],
									[2] = ['twigs'],
									[3] = ['boneshard']
								},
								['1egg16'] = {
									[1] = ['tallbirdegg']
								},
								...
							}]]
						all_mixtags, list_all_mixtags = GetCurMixTags(num_ings, diary_mixtags)

						--有2个食材位未确定
						if total_tags == 2 then
							--选出1个类别
							for j = 1, #list_all_mixtags do
								local cur_mixtag = list_all_mixtags[j]
								local cur_ing = all_mixtags[cur_mixtag][1]
								-- 生成recipe
								local part_recipe = { cur_ing, cur_ing } --取出该类别的第1个ing
								--该ing的tag满足最小要求
								local sumtag = GetSumTags(part_recipe)
								table.insert(part_recipe, 1, cur_combination[1])
								table.insert(part_recipe, 2, cur_combination[2])
								local sumtag_4 = GetSumTags(part_recipe)
								if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag_4, recipe_maxmix) then
									local cookable_found = false --标记当前类别是否已经证明cooable
									local all_tag = false --标记当前类别是否已经证明不可能cooable
									for m = 1, #all_mixtags[cur_mixtag] do
										for n = m, #all_mixtags[cur_mixtag] do
											local cur_ing_m = all_mixtags[cur_mixtag][m]
											local cur_ing_n = all_mixtags[cur_mixtag][n]
											part_recipe = { cur_ing_m, cur_ing_n }
											if (m == n and GetNumber(cur_ing_m, num_ings) >= 2) or m ~= n then
												table.insert(part_recipe, 1, cur_combination[1])
												table.insert(part_recipe, 2, cur_combination[2])
												local candidate_recipes = GetAllCandidateRecipes(cooker, part_recipe)
												if table.contains(candidate_recipes, food_name) then
													cookable_found = true
													cookable = true
													if need_number > #cookable_recipe then
														table.insert(cookable_recipe, part_recipe)
													else
														break
													end
													break
												else
													if CheckAllTagForOneFood({ cur_ing_m, cur_ing_n }, candidate_recipes, diary_detail) then
														all_tag = true --下一个j
														break
													end
													--[[m name n tag 下一个m
														m tag n name 下一个n
														m name n name 下一个n
														m tag n tag 不能完全确定，下一个n]]
													if CheckAllInName(cur_ing_m, candidate_recipes, diary_detail) and (not CheckAllInName(cur_ing_n, candidate_recipes, diary_detail)) then
														break --下一个m
													end
												end
											end
										end
										if need_number <= #cookable_recipe then
											break
										end
										if cookable_found then
											break --下一个j
										end
										if all_tag then
											break --下一个j
										end
									end
									if need_number <= #cookable_recipe then
										break
									end
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
							--选出2个类别
							for j = 1, (#list_all_mixtags - 1) do
								for k = j + 1, #list_all_mixtags do
									local cur_mixtag_j = list_all_mixtags[j]
									local cur_mixtag_k = list_all_mixtags[k]
									local cur_ing_j = all_mixtags[cur_mixtag_j][1]
									local cur_ing_k = all_mixtags[cur_mixtag_k][1]
									-- 生成recipe
									local part_recipe = { cur_ing_j, cur_ing_k }
									--该ing的tag满足最小要求
									local sumtag = GetSumTags(part_recipe)
									table.insert(part_recipe, 1, cur_combination[1])
									table.insert(part_recipe, 2, cur_combination[2])
									local sumtag_4 = GetSumTags(part_recipe)
									if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag_4, recipe_maxmix) then
										local cookable_found = false --标记当前类别组合是否已经证明cooable
										local all_tag = false --标记当前类别组合是否已经证明不可能cooable
										for m = 1, #all_mixtags[cur_mixtag_j] do
											for n = 1, #all_mixtags[cur_mixtag_k] do
												local cur_ing_m = all_mixtags[cur_mixtag_j][m]
												local cur_ing_n = all_mixtags[cur_mixtag_k][n]
												part_recipe = { cur_ing_m, cur_ing_n }
												table.insert(part_recipe, 1, cur_combination[1])
												table.insert(part_recipe, 2, cur_combination[2])
												local candidate_recipes = GetAllCandidateRecipes(cooker, part_recipe)
												if table.contains(candidate_recipes, food_name) then
													cookable_found = true
													cookable = true
													if need_number > #cookable_recipe then
														table.insert(cookable_recipe, part_recipe)
													else
														break
													end
													break
												else
													if CheckAllTagForOneFood({ cur_ing_m, cur_ing_n }, candidate_recipes, diary_detail) then
														all_tag = true --下一个类别组合
														break
													end
													--[[m name n tag 下一个m
														m tag n name 下一个n
														m name n name 下一个n
														m tag n tag 不能完全确定，下一个n]]
													if CheckAllInName(cur_ing_m, candidate_recipes, diary_detail) and (not CheckAllInName(cur_ing_n, candidate_recipes, diary_detail)) then
														break --下一个m
													end
												end
											end
											if need_number <= #cookable_recipe then
												break
											end
											if cookable_found then
												break --下一个类别组合
											end
											if all_tag then
												break --下一个类别组合
											end
										end
										if need_number <= #cookable_recipe then
											break
										end
									end
								end
								if need_number <= #cookable_recipe then
									break
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
						end

						--有3个食材位未确定
						if total_tags == 3 then
							--选出1个类别
							for j = 1, #list_all_mixtags do
								local cur_mixtag = list_all_mixtags[j]
								local cur_ing = all_mixtags[cur_mixtag][1]
								-- 生成recipe
								local part_recipe = { cur_ing, cur_ing, cur_ing } --取出该类别的第1个ing
								--该ing的tag满足最小要求
								local sumtag = GetSumTags(part_recipe)
								table.insert(part_recipe, 1, cur_combination[1])
								local sumtag_4 = GetSumTags(part_recipe)
								if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag_4, recipe_maxmix) then
									local cookable_found = false --标记当前类别是否已经证明cooable
									local all_tag = false --标记当前类别是否已经证明不可能cooable
									for m = 1, #all_mixtags[cur_mixtag] do
										for n = m, #all_mixtags[cur_mixtag] do
											for l = n, #all_mixtags[cur_mixtag] do
												local cur_ing_m = all_mixtags[cur_mixtag][m]
												local cur_ing_n = all_mixtags[cur_mixtag][n]
												local cur_ing_l = all_mixtags[cur_mixtag][l]
												part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l }
												if CheckEnough(part_recipe, num_ings) then
													table.insert(part_recipe, 1, cur_combination[1])
													local candidate_recipes = GetAllCandidateRecipes(cooker, part_recipe)
													if table.contains(candidate_recipes, food_name) then
														cookable_found = true
														cookable = true
														if need_number > #cookable_recipe then
															table.insert(cookable_recipe, part_recipe)
														else
															break
														end
														break
													else
														if CheckAllTagForOneFood({ cur_ing_m, cur_ing_n, cur_ing_l }, candidate_recipes, diary_detail) then
															all_tag = true --下一个j
															break
														end
													end
												end
											end
											if need_number <= #cookable_recipe then
												break
											end
											if cookable_found then
												break --下一个j
											end
											if all_tag then
												break --下一个j
											end
										end
										if need_number <= #cookable_recipe then
											break
										end
										if cookable_found then
											break --下一个j
										end
										if all_tag then
											break --下一个j
										end
									end
									if need_number <= #cookable_recipe then
										break
									end
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
							--选出2个类别
							for j = 1, (#list_all_mixtags - 1) do
								for k = j + 1, #list_all_mixtags do
									local cur_mixtag_j = list_all_mixtags[j]
									local cur_mixtag_k = list_all_mixtags[k]
									local cur_ing_j = all_mixtags[cur_mixtag_j][1]
									local cur_ing_k = all_mixtags[cur_mixtag_k][1]
									-- 生成recipe 2*j 1*k
									local part_recipe = { cur_ing_j, cur_ing_j, cur_ing_k }
									--该ing的tag满足最小要求
									local sumtag = GetSumTags(part_recipe)
									table.insert(part_recipe, 1, cur_combination[1])
									local sumtag_4 = GetSumTags(part_recipe)
									if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag_4, recipe_maxmix) then
										local cookable_found = false --标记当前类别是否已经证明cooable
										local all_tag = false --标记当前类别是否已经证明不可能cooable
										for m = 1, #all_mixtags[cur_mixtag_j] do
											for n = m, #all_mixtags[cur_mixtag_j] do
												for l = 1, #all_mixtags[cur_mixtag_k] do
													local cur_ing_m = all_mixtags[cur_mixtag_j][m]
													local cur_ing_n = all_mixtags[cur_mixtag_j][n]
													local cur_ing_l = all_mixtags[cur_mixtag_k][l]
													part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l }
													if CheckEnough(part_recipe, num_ings) then
														table.insert(part_recipe, 1, cur_combination[1])
														local candidate_recipes = GetAllCandidateRecipes(cooker,
															part_recipe)
														if table.contains(candidate_recipes, food_name) then
															cookable_found = true
															cookable = true
															if need_number > #cookable_recipe then
																table.insert(cookable_recipe, part_recipe)
															else
																break
															end
															break
														else
															if CheckAllTagForOneFood({ cur_ing_m, cur_ing_n, cur_ing_l }, candidate_recipes, diary_detail) then
																all_tag = true --下一个j
																break
															end
														end
													end
												end
												if need_number <= #cookable_recipe then
													break
												end
												if cookable_found then
													break --下一个j
												end
												if all_tag then
													break --下一个j
												end
											end
											if need_number <= #cookable_recipe then
												break
											end
											if cookable_found then
												break --下一个j
											end
											if all_tag then
												break --下一个j
											end
										end
										if need_number <= #cookable_recipe then
											break
										end
									end
									-- 生成recipe 1*j 2*k
									part_recipe = { cur_ing_j, cur_ing_k, cur_ing_k }
									--该ing的tag满足最小要求
									sumtag = GetSumTags(part_recipe)
									table.insert(part_recipe, 1, cur_combination[1])
									sumtag_4 = GetSumTags(part_recipe)
									if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag_4, recipe_maxmix) then
										local cookable_found = false --标记当前类别是否已经证明cooable
										local all_tag = false --标记当前类别是否已经证明不可能cooable
										for m = 1, #all_mixtags[cur_mixtag_j] do
											for n = 1, #all_mixtags[cur_mixtag_k] do
												for l = n, #all_mixtags[cur_mixtag_k] do
													local cur_ing_m = all_mixtags[cur_mixtag_j][m]
													local cur_ing_n = all_mixtags[cur_mixtag_k][n]
													local cur_ing_l = all_mixtags[cur_mixtag_k][l]
													part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l }
													if CheckEnough(part_recipe, num_ings) then
														table.insert(part_recipe, 1, cur_combination[1])
														local candidate_recipes = GetAllCandidateRecipes(cooker,
															part_recipe)
														if table.contains(candidate_recipes, food_name) then
															cookable_found = true
															cookable = true
															if need_number > #cookable_recipe then
																table.insert(cookable_recipe, part_recipe)
															else
																break
															end
															break
														else
															if CheckAllTagForOneFood({ cur_ing_m, cur_ing_n, cur_ing_l }, candidate_recipes, diary_detail) then
																all_tag = true --下一个j
																break
															end
														end
													end
												end
												if cookable_found then
													break --下一个j
												end
												if all_tag then
													break --下一个j
												end
											end
											if cookable_found then
												break --下一个j
											end
											if all_tag then
												break --下一个j
											end
										end
									end
								end
								if need_number <= #cookable_recipe then
									break
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
							--选出3个类别
							for j = 1, (#list_all_mixtags - 2) do
								for k = j + 1, (#list_all_mixtags - 1) do
									for i = k + 1, #list_all_mixtags do
										local cur_mixtag_j = list_all_mixtags[j]
										local cur_mixtag_k = list_all_mixtags[k]
										local cur_mixtag_i = list_all_mixtags[i]
										local cur_ing_j = all_mixtags[cur_mixtag_j][1]
										local cur_ing_k = all_mixtags[cur_mixtag_k][1]
										local cur_ing_i = all_mixtags[cur_mixtag_i][1]
										-- 生成recipe
										local part_recipe = { cur_ing_j, cur_ing_k, cur_ing_i }
										--该ing的tag满足最小要求
										local sumtag = GetSumTags(part_recipe)
										table.insert(part_recipe, 1, cur_combination[1])
										local sumtag_4 = GetSumTags(part_recipe)
										if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag_4, recipe_maxmix) then
											local cookable_found = false --标记当前类别组合是否已经证明cooable
											local all_tag = false --标记当前类别组合是否已经证明不可能cooable
											for m = 1, #all_mixtags[cur_mixtag_j] do
												for n = 1, #all_mixtags[cur_mixtag_k] do
													for l = 1, #all_mixtags[cur_mixtag_i] do
														local cur_ing_m = all_mixtags[cur_mixtag_j][m]
														local cur_ing_n = all_mixtags[cur_mixtag_k][n]
														local cur_ing_l = all_mixtags[cur_mixtag_i][l]
														part_recipe = { cur_combination[1], cur_ing_m, cur_ing_n,
															cur_ing_l }
														local candidate_recipes = GetAllCandidateRecipes(cooker,
															part_recipe)
														if table.contains(candidate_recipes, food_name) then
															cookable_found = true
															cookable = true
															if need_number > #cookable_recipe then
																table.insert(cookable_recipe, part_recipe)
															else
																break
															end
															break
														else
															if CheckAllTagForOneFood({ cur_ing_m, cur_ing_n, cur_ing_l }, candidate_recipes, diary_detail) then
																all_tag = true --下一个类别组合
																break
															end
														end
													end
													if need_number <= #cookable_recipe then
														break
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if need_number <= #cookable_recipe then
													break
												end
												if cookable_found then
													break --下一个类别组合
												end
												if all_tag then
													break --下一个类别组合
												end
											end
											if need_number <= #cookable_recipe then
												break
											end
										end
									end
									if need_number <= #cookable_recipe then
										break
									end
								end
								if need_number <= #cookable_recipe then
									break
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
						end

						--有4个食材位未确定
						if total_tags == 4 then
							--选出1个类别
							for j = 1, #list_all_mixtags do
								local cur_mixtag = list_all_mixtags[j]
								local cur_ing = all_mixtags[cur_mixtag][1]
								-- 生成recipe
								local part_recipe = { cur_ing, cur_ing, cur_ing, cur_ing } --取出该类别的第1个ing
								--该ing的tag满足最小要求
								local sumtag = GetSumTags(part_recipe)
								if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
									local cookable_found = false --标记当前类别是否已经证明cooable
									local all_tag = false --标记当前类别是否已经证明不可能cooable
									for m = 1, #all_mixtags[cur_mixtag] do
										for n = m, #all_mixtags[cur_mixtag] do
											for l = n, #all_mixtags[cur_mixtag] do
												for h = l, #all_mixtags[cur_mixtag] do
													local cur_ing_m = all_mixtags[cur_mixtag][m]
													local cur_ing_n = all_mixtags[cur_mixtag][n]
													local cur_ing_l = all_mixtags[cur_mixtag][l]
													local cur_ing_h = all_mixtags[cur_mixtag][h]
													part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l, cur_ing_h }
													if CheckEnough(part_recipe, num_ings) then
														local candidate_recipes = GetAllCandidateRecipes(cooker,
															part_recipe)
														if table.contains(candidate_recipes, food_name) then
															cookable_found = true
															cookable = true
															if need_number > #cookable_recipe then
																table.insert(cookable_recipe, part_recipe)
															else
																break
															end
															break
														else
															if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																all_tag = true --下一个j
																break
															end
														end
													end
												end
												if need_number <= #cookable_recipe then
													break
												end
												if cookable_found then
													break --下一个j
												end
												if all_tag then
													break --下一个j
												end
											end
											if need_number <= #cookable_recipe then
												break
											end
											if cookable_found then
												break --下一个j
											end
											if all_tag then
												break --下一个j
											end
										end
										if need_number <= #cookable_recipe then
											break
										end
										if cookable_found then
											break --下一个j
										end
										if all_tag then
											break --下一个j
										end
									end
									if need_number <= #cookable_recipe then
										break
									end
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
							--选出2个类别
							for j = 1, (#list_all_mixtags - 1) do
								for k = j + 1, #list_all_mixtags do
									local cur_mixtag_j = list_all_mixtags[j]
									local cur_mixtag_k = list_all_mixtags[k]
									local cur_ing_j = all_mixtags[cur_mixtag_j][1]
									local cur_ing_k = all_mixtags[cur_mixtag_k][1]
									-- 生成recipe 3*j 1*k
									local part_recipe = { cur_ing_j, cur_ing_j, cur_ing_j, cur_ing_k }
									--该ing的tag满足最小要求
									local sumtag = GetSumTags(part_recipe)
									if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
										local cookable_found = false --标记当前类别是否已经证明cooable
										local all_tag = false --标记当前类别是否已经证明不可能cooable
										for m = 1, #all_mixtags[cur_mixtag_j] do
											for n = m, #all_mixtags[cur_mixtag_j] do
												for l = n, #all_mixtags[cur_mixtag_j] do
													for h = 1, #all_mixtags[cur_mixtag_k] do
														local cur_ing_m = all_mixtags[cur_mixtag_j][m]
														local cur_ing_n = all_mixtags[cur_mixtag_j][n]
														local cur_ing_l = all_mixtags[cur_mixtag_j][l]
														local cur_ing_h = all_mixtags[cur_mixtag_k][h]
														part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l, cur_ing_h }
														if CheckEnough(part_recipe, num_ings) then
															local candidate_recipes = GetAllCandidateRecipes(cooker,
																part_recipe)
															if table.contains(candidate_recipes, food_name) then
																cookable_found = true
																cookable = true
																if need_number > #cookable_recipe then
																	table.insert(cookable_recipe, part_recipe)
																else
																	break
																end
																break
															else
																if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																	all_tag = true --下一个类别组合
																	break
																end
															end
														end
													end
													if need_number <= #cookable_recipe then
														break
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if need_number <= #cookable_recipe then
													break
												end
												if cookable_found then
													break --下一个类别组合
												end
												if all_tag then
													break --下一个类别组合
												end
											end
											if need_number <= #cookable_recipe then
												break
											end
											if cookable_found then
												break --下一个类别组合
											end
											if all_tag then
												break --下一个类别组合
											end
										end
										if need_number <= #cookable_recipe then
											break
										end
									end
									-- 生成recipe 2*j 2*k
									part_recipe = { cur_ing_j, cur_ing_j, cur_ing_k, cur_ing_k }
									--该ing的tag满足最小要求
									sumtag = GetSumTags(part_recipe)
									if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
										local cookable_found = false --标记当前类别是否已经证明cooable
										local all_tag = false --标记当前类别是否已经证明不可能cooable
										for m = 1, #all_mixtags[cur_mixtag_j] do
											for n = m, #all_mixtags[cur_mixtag_j] do
												for l = 1, #all_mixtags[cur_mixtag_k] do
													for h = l, #all_mixtags[cur_mixtag_k] do
														local cur_ing_m = all_mixtags[cur_mixtag_j][m]
														local cur_ing_n = all_mixtags[cur_mixtag_j][n]
														local cur_ing_l = all_mixtags[cur_mixtag_k][l]
														local cur_ing_h = all_mixtags[cur_mixtag_k][h]
														part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l, cur_ing_h }
														if CheckEnough(part_recipe, num_ings) then
															local candidate_recipes = GetAllCandidateRecipes(cooker,
																part_recipe)
															if table.contains(candidate_recipes, food_name) then
																cookable_found = true
																cookable = true
																if need_number > #cookable_recipe then
																	table.insert(cookable_recipe, part_recipe)
																else
																	break
																end
																break
															else
																if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																	all_tag = true --下一个类别组合
																	break
																end
															end
														end
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if cookable_found then
													break --下一个类别组合
												end
												if all_tag then
													break --下一个类别组合
												end
											end
											if cookable_found then
												break --下一个类别组合
											end
											if all_tag then
												break --下一个类别组合
											end
										end
									end
									-- 生成recipe 1*j 3*k
									part_recipe = { cur_ing_j, cur_ing_k, cur_ing_k, cur_ing_k }
									--该ing的tag满足最小要求
									sumtag = GetSumTags(part_recipe)
									if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
										local cookable_found = false --标记当前类别是否已经证明cooable
										local all_tag = false --标记当前类别是否已经证明不可能cooable
										for m = 1, #all_mixtags[cur_mixtag_j] do
											for n = 1, #all_mixtags[cur_mixtag_k] do
												for l = n, #all_mixtags[cur_mixtag_k] do
													for h = l, #all_mixtags[cur_mixtag_k] do
														local cur_ing_m = all_mixtags[cur_mixtag_j][m]
														local cur_ing_n = all_mixtags[cur_mixtag_k][n]
														local cur_ing_l = all_mixtags[cur_mixtag_k][l]
														local cur_ing_h = all_mixtags[cur_mixtag_k][h]
														part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l, cur_ing_h }
														if CheckEnough(part_recipe, num_ings) then
															local candidate_recipes = GetAllCandidateRecipes(cooker,
																part_recipe)
															if table.contains(candidate_recipes, food_name) then
																cookable_found = true
																cookable = true
																if need_number > #cookable_recipe then
																	table.insert(cookable_recipe, part_recipe)
																else
																	break
																end
																break
															else
																if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																	all_tag = true --下一个类别组合
																	break
																end
															end
														end
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if cookable_found then
													break --下一个类别组合
												end
												if all_tag then
													break --下一个类别组合
												end
											end
											if cookable_found then
												break --下一个类别组合
											end
											if all_tag then
												break --下一个类别组合
											end
										end
									end
								end
								if need_number <= #cookable_recipe then
									break
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
							--选出3个类别
							for j = 1, (#list_all_mixtags - 2) do
								for k = j + 1, (#list_all_mixtags - 1) do
									for i = k + 1, #list_all_mixtags do
										local cur_mixtag_j = list_all_mixtags[j]
										local cur_mixtag_k = list_all_mixtags[k]
										local cur_mixtag_i = list_all_mixtags[i]
										local cur_ing_j = all_mixtags[cur_mixtag_j][1]
										local cur_ing_k = all_mixtags[cur_mixtag_k][1]
										local cur_ing_i = all_mixtags[cur_mixtag_i][1]
										-- 生成recipe 2*j 1*k 1*i
										local part_recipe = { cur_ing_j, cur_ing_j, cur_ing_k, cur_ing_i }
										--该ing的tag满足最小要求
										local sumtag = GetSumTags(part_recipe)
										if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
											local cookable_found = false --标记当前类别组合是否已经证明cooable
											local all_tag = false --标记当前类别组合是否已经证明不可能cooable
											for m = 1, #all_mixtags[cur_mixtag_j] do
												for n = m, #all_mixtags[cur_mixtag_j] do
													for l = 1, #all_mixtags[cur_mixtag_k] do
														for h = 1, #all_mixtags[cur_mixtag_i] do
															local cur_ing_m = all_mixtags[cur_mixtag_j][m]
															local cur_ing_n = all_mixtags[cur_mixtag_j][n]
															local cur_ing_l = all_mixtags[cur_mixtag_k][l]
															local cur_ing_h = all_mixtags[cur_mixtag_i][h]
															part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l, cur_ing_h }
															if CheckEnough(part_recipe, num_ings) then
																local candidate_recipes = GetAllCandidateRecipes(cooker,
																	part_recipe)
																if table.contains(candidate_recipes, food_name) then
																	cookable_found = true
																	cookable = true
																	if need_number > #cookable_recipe then
																		table.insert(cookable_recipe, part_recipe)
																	else
																		break
																	end
																	break
																else
																	if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																		all_tag = true --下一个类别组合
																		break
																	end
																end
															end
														end
														if need_number <= #cookable_recipe then
															break
														end
														if cookable_found then
															break --下一个类别组合
														end
														if all_tag then
															break --下一个类别组合
														end
													end
													if need_number <= #cookable_recipe then
														break
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if need_number <= #cookable_recipe then
													break
												end
												if cookable_found then
													break --下一个类别组合
												end
												if all_tag then
													break --下一个类别组合
												end
											end
											if need_number <= #cookable_recipe then
												break
											end
										end
										-- 生成recipe 1*j 2*k 1*i
										part_recipe = { cur_ing_j, cur_ing_k, cur_ing_k, cur_ing_i }
										--该ing的tag满足最小要求
										sumtag = GetSumTags(part_recipe)
										if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
											local cookable_found = false --标记当前类别组合是否已经证明cooable
											local all_tag = false --标记当前类别组合是否已经证明不可能cooable
											for m = 1, #all_mixtags[cur_mixtag_j] do
												for n = 1, #all_mixtags[cur_mixtag_k] do
													for l = n, #all_mixtags[cur_mixtag_k] do
														for h = 1, #all_mixtags[cur_mixtag_i] do
															local cur_ing_m = all_mixtags[cur_mixtag_j][m]
															local cur_ing_n = all_mixtags[cur_mixtag_k][n]
															local cur_ing_l = all_mixtags[cur_mixtag_k][l]
															local cur_ing_h = all_mixtags[cur_mixtag_i][h]
															part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l, cur_ing_h }
															if CheckEnough(part_recipe, num_ings) then
																local candidate_recipes = GetAllCandidateRecipes(cooker,
																	part_recipe)
																if table.contains(candidate_recipes, food_name) then
																	cookable_found = true
																	cookable = true
																	if need_number > #cookable_recipe then
																		table.insert(cookable_recipe, part_recipe)
																	else
																		break
																	end
																	break
																else
																	if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																		all_tag = true --下一个类别组合
																		break
																	end
																end
															end
														end
														if cookable_found then
															break --下一个类别组合
														end
														if all_tag then
															break --下一个类别组合
														end
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if cookable_found then
													break --下一个类别组合
												end
												if all_tag then
													break --下一个类别组合
												end
											end
										end
										-- 生成recipe 1*j 1*k 2*i
										part_recipe = { cur_ing_j, cur_ing_k, cur_ing_i, cur_ing_i }
										--该ing的tag满足最小要求
										sumtag = GetSumTags(part_recipe)
										if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
											local cookable_found = false --标记当前类别组合是否已经证明cooable
											local all_tag = false --标记当前类别组合是否已经证明不可能cooable
											for m = 1, #all_mixtags[cur_mixtag_j] do
												for n = 1, #all_mixtags[cur_mixtag_k] do
													for l = 1, #all_mixtags[cur_mixtag_i] do
														for h = l, #all_mixtags[cur_mixtag_i] do
															local cur_ing_m = all_mixtags[cur_mixtag_j][m]
															local cur_ing_n = all_mixtags[cur_mixtag_k][n]
															local cur_ing_l = all_mixtags[cur_mixtag_i][l]
															local cur_ing_h = all_mixtags[cur_mixtag_i][h]
															part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l, cur_ing_h }
															if CheckEnough(part_recipe, num_ings) then
																local candidate_recipes = GetAllCandidateRecipes(cooker,
																	part_recipe)
																if table.contains(candidate_recipes, food_name) then
																	cookable_found = true
																	cookable = true
																	if need_number > #cookable_recipe then
																		table.insert(cookable_recipe, part_recipe)
																	else
																		break
																	end
																	break
																else
																	if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																		all_tag = true --下一个类别组合
																		break
																	end
																end
															end
														end
														if cookable_found then
															break --下一个类别组合
														end
														if all_tag then
															break --下一个类别组合
														end
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if cookable_found then
													break --下一个类别组合
												end
												if all_tag then
													break --下一个类别组合
												end
											end
										end
									end
									if need_number <= #cookable_recipe then
										break
									end
								end
								if need_number <= #cookable_recipe then
									break
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
							--选出4个类别
							for j = 1, (#list_all_mixtags - 3) do
								for k = j + 1, (#list_all_mixtags - 2) do
									for i = k + 1, (#list_all_mixtags - 1) do
										for t = i + 1, #list_all_mixtags do
											local cur_mixtag_j = list_all_mixtags[j]
											local cur_mixtag_k = list_all_mixtags[k]
											local cur_mixtag_i = list_all_mixtags[i]
											local cur_mixtag_t = list_all_mixtags[t]
											local cur_ing_j = all_mixtags[cur_mixtag_j][1]
											local cur_ing_k = all_mixtags[cur_mixtag_k][1]
											local cur_ing_i = all_mixtags[cur_mixtag_i][1]
											local cur_ing_t = all_mixtags[cur_mixtag_t][1]
											-- 生成recipe
											local part_recipe = { cur_ing_j, cur_ing_k, cur_ing_i, cur_ing_t }
											--该ing的tag满足最小要求
											local sumtag = GetSumTags(part_recipe)
											if CheckMintags(sumtag, method.tags) and CheckMaxmix(sumtag, recipe_maxmix) then
												local cookable_found = false --标记当前类别组合是否已经证明cooable
												local all_tag = false --标记当前类别组合是否已经证明不可能cooable
												for m = 1, #all_mixtags[cur_mixtag_j] do
													for n = 1, #all_mixtags[cur_mixtag_k] do
														for l = 1, #all_mixtags[cur_mixtag_i] do
															for h = 1, #all_mixtags[cur_mixtag_t] do
																local cur_ing_m = all_mixtags[cur_mixtag_j][m]
																local cur_ing_n = all_mixtags[cur_mixtag_k][n]
																local cur_ing_l = all_mixtags[cur_mixtag_i][l]
																local cur_ing_h = all_mixtags[cur_mixtag_t][h]
																part_recipe = { cur_ing_m, cur_ing_n, cur_ing_l,
																	cur_ing_h }
																local candidate_recipes = GetAllCandidateRecipes(cooker,
																	part_recipe)
																if table.contains(candidate_recipes, food_name) then
																	cookable_found = true
																	cookable = true
																	if need_number > #cookable_recipe then
																		table.insert(cookable_recipe, part_recipe)
																	else
																		break
																	end
																	break
																else
																	if CheckAllTagForOneFood(part_recipe, candidate_recipes, diary_detail) then
																		all_tag = true --下一个类别组合
																		break
																	end
																end
															end
															if need_number <= #cookable_recipe then
																break
															end
															if cookable_found then
																break --下一个类别组合
															end
															if all_tag then
																break --下一个类别组合
															end
														end
														if need_number <= #cookable_recipe then
															break
														end
														if cookable_found then
															break --下一个类别组合
														end
														if all_tag then
															break --下一个类别组合
														end
													end
													if need_number <= #cookable_recipe then
														break
													end
													if cookable_found then
														break --下一个类别组合
													end
													if all_tag then
														break --下一个类别组合
													end
												end
												if need_number <= #cookable_recipe then
													break
												end
											end
										end
										if need_number <= #cookable_recipe then
											break
										end
									end
									if need_number <= #cookable_recipe then
										break
									end
								end
								if need_number <= #cookable_recipe then
									break
								end
							end
							if need_number <= #cookable_recipe then
								break
							end
						end
					end
				end
			end
		end
	end
	return cookable_recipe, cookable
end

return {
	GetNumber = GetNumber,
	RecipeToNumIng = RecipeToNumIng,
	GetCookable = GetCookable,
	GetCurMixTags = GetCurMixTags
}
