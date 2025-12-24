local atbook_exception = {

    -- 永不妥协的恶魔蛋，test函数中的tags.monster > tags.egg写法不规范，无法解析，手动写一下
    -- test = function(cooker, names, tags) 
    -- return tags.monster and tags.egg and not tags.meat and tags.monster > tags.egg end,
    um_deviled_eggs =
    {
        fn_minlist = function()
            local recipe_minlist = {}
			for i=0.5,4,0.5 do
				table.insert(recipe_minlist,{
					['tags'] = {
						['monster'] = i+0.25,
						['egg'] = i
					},
					['names'] = {}
				})
			end
            return recipe_minlist
        end,
        fn_maxmix = function()
			return {
				[1] = {
					['amt'] = 0,
					['tag'] = 'meat'
				}
			}
        end
    },

    -- 原版的加利福利亚鱼肉卷，test函数无法解析，手动写一下
    -- test = function(cooker, names, tags) 
    -- return ((names.kelp or 0) + (names.kelp_cooked or 0) + (names.kelp_dried or 0)) == 2 and (tags.fish and tags.fish >= 1) end,
    californiaroll =
    {
        fn_minlist = function()
            local recipe_minlist = {}
            local ings = {"kelp", "kelp_cooked", "kelp_dried"}
			for i=1,#ings do
				for j=i,#ings do
					if i == j then
						table.insert(recipe_minlist,{
							['tags'] = {
								["fish"] = 1
							},
							['names'] = {
								[ings[i]] = 2
							}
						})
					else
						table.insert(recipe_minlist,{
							['tags'] = {
								["fish"] = 1
							},
							['names'] = {
								[ings[i]] = 1,
								[ings[j]] = 1
							}
						})
					end
				end
			end
            return recipe_minlist
        end,
        fn_maxmix = function()
            local recipe_maxmix = {}
            local ings = {"kelp", "kelp_cooked", "kelp_dried"}
			for i=1,#ings do
				table.insert(recipe_maxmix,{
					['amt'] = 2,
					['tag'] = ings[i]
				})
			end
            return recipe_maxmix
        end
    }
}

for _, food_fns in pairs(atbook_exception) do
    food_fns.minlist = food_fns.fn_minlist()
    food_fns.maxmix = food_fns.fn_maxmix()
end

return atbook_exception
