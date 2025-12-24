--------------------------------------------------------------------------
--[[ Tool ]]--[[ 工具 ]]
--------------------------------------------------------------------------
require("util")
local utils = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_utils")

local cooking = require "cooking"
local atbook_exception = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_exception")
local _dtag = 0.25
local diary_food_detail = {} -- raw format recipes
local alltags = {} -- all known tags
local allnames = {} -- all known names

local aliases = utils.aliases
local aliases_reverse = utils.aliases_reverse
local tag_str = require("_key_modules_of_tbat/14_wolf_cooking_modules/atbook_tags")

-- 下方数个函数参考自craftpot，适配并修复原函数错误（已告知原作者）
-- pcall wrapper, returns:
--  1 for success,
--  0 for fail,
-- -1 for compare error,
-- -2 for sum error,
-- -3 for unknown error
local function _ptest(test, names, tags)
    local st,res = pcall(test, "", names, tags)
    return st and (res and 1 or 0) or string.find(res, "compare") and -1 or string.find(res, "arith") and -2 or -3
end

local function Composition(list)
    --[[包含某料理不同制作配方的共用部分和特别部分
    如：火鸡正餐，有两种制作方式：
    1. names.drumstick = 2, tags.meat = 1.25, tags.fruit = 0.25
    2. names.drumstick = 2, tags.meat = 1.25, tags.veggie = 0.5
    ['minmix'] = {
        -- 共用部分
        [1] = {
                ['name'] = 'drumstick',
                ['amt'] = 2
        },
        [2] = {
                ['tag'] = 'meat',
                ['amt'] = 1.25
        },
        -- 特别部分
        [3] = {
                [1] = {
                        ['tag'] = 'fruit',
                        ['amt'] = 0.25
                },
                [2] = {
                        ['tag'] = 'veggie',
                        ['amt'] = 1
                }
        }
    }
    ]]

    local mix = {}
    local sets = {} -- specific format {type:"name"/"tag"}_{name/tag}_{amt} = {mix={name/tag={name/tag},amt={amt}}, used={#1,#2,#3}}
    -- first read the recipes in a huge line
    for idx,recipe in ipairs(list) do
        for name, amt in pairs(recipe.names) do
            --table.insert(branch,{name=name,amt=amt})
            local key = "n_"..name.."_"..amt
            local used = sets[key] and sets[key].used or {}
            table.insert(used,idx)
            sets[key] = {mix={name=name,amt=amt},used=used}
        end
        for tag, amt in pairs(recipe.tags) do
            --table.insert(branch,{tag=tag,amt=amt})
            local key = "t_"..tag.."_"..amt
            local used = sets[key] and sets[key].used or {}
            table.insert(used,idx)
            sets[key] = {mix={tag=tag,amt=amt},used=used}
        end
    end

    -- only leave those that are repeating
    local uniques = {}
    for key, data in pairs(sets) do
        if #data.used == #list then
            table.insert(mix, data.mix)
        else
            table.insert(uniques, data)
        end
    end

    if #uniques > 0 then
        local alt = {}
        -- let us begin composition
        for _, data in ipairs(uniques) do
            for _, uidx in ipairs(data.used) do
                if not alt[uidx] then
                    alt[uidx] = data.mix
                elseif alt[uidx].amt then
                    alt[uidx] = {alt[uidx], data.mix}
                else
                    table.insert(alt[uidx], data.mix)
                end
            end
        end
        table.insert(mix, alt)
    end

    return mix
end

local function RawToSimple(names, tags)
    local recipe = {
        minnames = {},
        mintags = {},
        maxnames = {},
        maxtags = {}
    }

    for name, amount in pairs(names) do
        if amount < 1000 then
            recipe.maxnames[name] = amount
        end
        if amount > 0 then
            recipe.minnames[name] = amount
        end
    end

    for tag, amount in pairs(tags) do
        if amount < 1000 then
            recipe.maxtags[tag] = amount
        end
        if amount > 0 then
            recipe.mintags[tag] = amount
        end
    end

    return recipe
end

-- 通过循环调用各料理（忽略添加调味料的料理）的test函数，记录调用的name和tag索引，直至找到一种能够完成料理的name和tag组合
local function SmartSearch(test)
    local tags = {}  -- 存储食材标签的值，例：{vtags.veggie = {nil, 0.25 至 4, 步长0.25}}
    local names = {} -- 存储食材名称的值，例：{vnames.froglegs = {nil,1,2,3,4}}

    -- 通过元表将每个料理的test函数中所调用的name和tag索引，在access_list中记录下来，并返回上面定义的tags和names对应的键值
    local tags_proxy = {}
    local names_proxy = {}

    local recipe = {tags={},names={}}

    local access_list = {} -- list of {type="names"/"tags", field={field}}
    local isSpicedFoodRecipe = false

    setmetatable(names_proxy, {__index=function(t,field)
        field = aliases[field] or field
        if cooking.ingredients[field] then
            table.insert(access_list, {type="names",field=field})
            return names[field]
        elseif string.find(tostring(field), "spice_") == 1 or diary_food_detail[field] then
            -- if we find some recipe name in the recipe, then it is probably food+spice and should not be added
            isSpicedFoodRecipe = true
            return nil
        else
            print("CookDiary ~ detected invalid ingredient ["..field.."] in one of the recipes.")
            return nil
        end
    end})

    setmetatable(tags_proxy, {__index=function(t,field)
        if alltags[field] then
            table.insert(access_list, {type="tags",field=field})
            return tags[field]
        else
            print("CookDiary ~ detected invalid tag ["..field.."] in one of the recipes.")
            return nil
        end
    end})

    local result
    while true do
        access_list = {}
        result = _ptest(test,names_proxy,tags_proxy)

        if isSpicedFoodRecipe then
            return false
        elseif result == 1 then
            return RawToSimple(names,tags)
        elseif result == -3 or #access_list == 0 then -- test returned unknown error or no access
            print ("Could not find recipe, unknown error"..result)
            return false
        elseif result == -2 then -- test returned arithmetic error
            local found = false
            for idx=#access_list,0,-1 do -- iterate access_list from end to start
                if not recipe[access_list[idx].type] then
                    recipe[access_list[idx].type] = 0
                    found = true
                    break
                end
            end
            if not found then -- could not fix sum error ???
                print ("Could not find recipe, persistent sum error")
                return false
            end
        else -- test returned false or compare error (-1 or 0)
            local access = table.remove(access_list)
            if access.type == "tags" then
                tags[access.field] = tags[access.field] and tags[access.field] + _dtag or _dtag
                if tags[access.field] > 4 then -- quit condition, tag over max value
                    print ("Could not find recipe, tag over max")
                    return false
                end
            elseif access.type == "names" then
                names[access.field] = names[access.field] and names[access.field] + 1 or 1
                if names[access.field] > 4 then -- quit condition name over max value
                    print ("Could not find recipe, name over max")
                    return false
                end
            end

        end -- else

    end -- while true

end

local function CheckMinnameInMinlist(minname, minlist)
    for _,v in ipairs(minlist) do
        local cur_minnames = v.names
        local common_key = {}
        local first_check = true
        local second_check = true
        for name, amt in pairs(cur_minnames) do
            if minname[name] ~= nil and minname[name] == amt then
                common_key[name] = 1
            else
                first_check = false
                break
            end
        end
        if first_check then
            for name_, _ in pairs(minname) do
                if common_key[name_] == nil then
                    second_check = false
                    break
                end
            end
            if second_check then
                -- utils.dprint("CheckMinnameInMinlist true")
                -- utils.dprint("cur_minnames", cur_minnames)
                -- utils.dprint("minname", minname)
                return true
            end
        end
    end
    -- utils.dprint("CheckMinnameInMinlist false")
    return false
end

local function MinimizeRecipe(food_name, recipe)
    --[[
        ['minlist'] = {
            [1] = {
                    ['tags'] = {
                            ['meat'] = 0.25,
                            ['fruit'] = 0.25
                    },
                    ['names'] = {
                            ['drumstick'] = 2
                    }
            },
            [2] = {
                    ['tags'] = {
                            ['meat'] = 0.25,
                            ['veggie'] = 0.5
                    },
                    ['names'] = {
                            ['drumstick'] = 2
                    }
            }
        }
    ]]
    for k,v in pairs(diary_food_detail[food_name]) do
        recipe[k] = v
    end

    -- validate used names and tags
    local names = {}
    local tags = {}
    local test = recipe.test

    for name, amount in pairs(recipe.minnames) do
        names[name] = amount
    end

    for tag, amount in pairs(recipe.mintags) do
        tags[tag] = amount
    end

    if _ptest(test, names, tags) ~= 1 then
        print("CookDiary ~~~ Invalid recipe for "..food_name)
        return false
    end

    local buffer = nil

    -- *************
    -- find minnames
    -- *************
    for name,amount in pairs(names) do
        names[name] = nil
        if _ptest(test, names, tags) == 1 then -- _Test[nil] == true, not a required name
            recipe.minnames[name] = nil
        else -- _Test[nil] == false, minname is required
            names[name] = amount - 1
            if _ptest(test, names, tags) ~= 1 then -- _Test[amount-1] == false, valid minname
                names[name] = amount
            else -- _Test[amount-1] == true, invalid restriction
                names[name] = 1
                while _ptest(test, names, tags) ~= 1 and names[name] <= 4 do
                    names[name] = names[name] + 1
                end
                recipe.minnames[name] = names[name]
            end
        end
    end

    -- ************
    -- find mintags
    -- ************
    for tag,amount in pairs(tags) do
        tags[tag] = nil
        if _ptest(test, names, tags) == 1 then -- _Test[nil] == true, not a required tag
            recipe.mintags[tag] = nil
        else -- _Test[nil] == false, mintag is required
            tags[tag] = amount - _dtag
            if _ptest(test, names, tags) ~= 1 then -- _Test[amount-1] == false, valid mintag
                tags[tag] = amount
            else -- _Test[amount-1] == true, invalid restriction
                tags[tag] = _dtag
                while _ptest(test, names, tags) ~= 1 and tags[tag] < 1001 do
                    tags[tag] = tags[tag] + _dtag
                end
                recipe.mintags[tag] = tags[tag]
            end
        end
    end

    -- *************
    -- find maxnames
    -- *************
    local maxtest

    for name,_ in pairs(allnames) do
        buffer = names[name] or nil

        maxtest = math.max(recipe.minnames[name] and recipe.minnames[name] + 1 or 0, recipe.maxnames[name] and recipe.maxnames[name] + 1 or 0, 1)
        names[name] = maxtest
        if _ptest(test, names, tags) == 1 then -- _Test[amount+1] == true, invalid restriction
            names[name] = 4
            if _ptest(test, names, tags) == 1 then -- _Test[amount+1] == true and _Test[1000] == true, no restriction needed
                recipe.maxnames[name] = nil
            else -- _Test[amount+1] == true and _Test[1000] == false, restriction is somwhere above
                names[name] = maxtest + 1
                while _ptest(test, names, tags) == 1 and names[name] <= 4 do
                    names[name] = names[name] + 1
                end
                recipe.maxnames[name] = names[name] - 1
            end
        else -- _Test[amount+1] == false, valid restriction, but maybe we could reduce it
            repeat
                names[name] = names[name] - 1
            until names[name] <= 0 or _ptest(test,names,tags) == 1
            recipe.maxnames[name] = names[name]
        end

        names[name] = buffer
    end

    -- ************
    -- find maxtags
    -- ************
    for tag,_ in pairs(alltags) do
        buffer = tags[tag] or nil

        maxtest = math.max(recipe.mintags[tag] and recipe.mintags[tag] + _dtag or 0, recipe.maxtags[tag] and recipe.maxtags[tag] + _dtag or 0, _dtag)
        tags[tag] = maxtest
        if _ptest(test, names, tags) == 1 then -- _Test[amount+1] == true, invalid restriction
            tags[tag] = 1000
            if _ptest(test, names, tags) == 1 then -- _Test[amount+1] == true and _Test[1000] == true, no restriction needed
                recipe.maxtags[tag] = nil
            else -- _Test[amount+1] == true and _Test[1000] == false, restriction is somewhere above
                tags[tag] = maxtest + _dtag
                while _ptest(test, names, tags) == 1 and tags[tag] < 1001 do
                    tags[tag] = tags[tag] + _dtag
                end
                recipe.maxtags[tag] = tags[tag] - _dtag
            end
        else -- _Test[amount+1] == false, valid restriction, but maybe we could reduce it
            repeat
                tags[tag] = tags[tag] - _dtag
            until tags[tag] <= 0 or _ptest(test,names,tags) == 1
            recipe.maxtags[tag] = tags[tag]
        end
        tags[tag] = buffer
    end

    --------------------------
    -- analog recipe finder --
    --------------------------
    local minnames = recipe.minnames -- these are links to recipe tables,
    local mintags = recipe.mintags   -- any changes to them will be applied to the recipe

    local minnames_list = deepcopy(minnames)
    local mintags_list = deepcopy(mintags)

    recipe.minlist = {{names=minnames_list,tags=mintags_list}}

    -- 寻找相似的料理配方
    -- 遍历_allnames和_alltags，尝试将一个name变为1个其他的tag或name
    local changed_names = {}
    for minname, amt in pairs(minnames_list) do
        buffer = minnames[minname]
        minnames[minname] = minnames[minname] > 1 and minnames[minname]-1 or nil -- reduce name by 1

        -- try to replace minname it with a new name
        for name,_ in pairs(allnames) do
            if name ~= minname then
                minnames[name] = minnames[name] and minnames[name]+1 or 1
            if _ptest(test,minnames,mintags) == 1 then
                table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                local total_amt = (minnames[name] or 0) + (minnames[minname] or 0)
                table.insert(changed_names, {minname, name, total_amt})
            --    print("Found an analog for "..food_name.." can use "..name.." instead of "..minname)
            end
            minnames[name] = minnames[name] > 1 and minnames[name]-1 or nil
            end
        end

        -- try to replace minname with a new tag
        for tag,_ in pairs(alltags) do
            mintags[tag] = mintags[tag] and mintags[tag]+1 or 1
            if _ptest(test,minnames,mintags) == 1 then
                table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
            --print("Found an analog for "..food_name.." can use "..tag.." instead of "..minname)
            end
            mintags[tag] = mintags[tag] > 1 and mintags[tag]-1 or nil
        end

        minnames[minname] = buffer
    end

    recipe.changed = changed_names

    -- if next(changed_names) ~= nil and food_name == "mfp_jelly_roll" then
    --     local name_str = STRINGS.NAMES[string.upper(food_name)] or food_name
    --     utils.dprint("++++++++++++++++----+++++++++++++++++++")
    --     utils.dprint(food_name)
    --     utils.dprint(name_str)
    --     utils.dprint("recipe.minlist", recipe.minlist)
    --     utils.dprint("changed_names", changed_names)
    --     utils.dprint("minnames", minnames)
    -- end

    -- 将数目>1的 orig_name 逐个替换为 turn_name
    for _, changed_name in ipairs(changed_names) do
        local orig_name = changed_name[1]
        local turn_name = changed_name[2]
        local num_orig_name = minnames[orig_name]

        if num_orig_name > 1 then
            -- utils.dprint("选择1种替换")
            for ii=2,num_orig_name do
                minnames[orig_name] = num_orig_name > ii and num_orig_name-ii or nil                                    -- orig_name 减少 ii 个
                minnames[turn_name] = minnames[turn_name] and minnames[turn_name]+ii or ii                              -- turn_name 增加 ii 个
                if _ptest(test,minnames,mintags) == 1 then
                    -- utils.dprint("变换后minnames", minnames)
                    table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                end
                minnames[turn_name] = minnames[turn_name] > ii and minnames[turn_name]-ii or nil                        -- 还原turn_name的数量
                minnames[orig_name] = num_orig_name
                -- utils.dprint("还原后minnames", minnames)
            end
        end
    end

    -- 下面处理 changed_names 长度>1的情况
    if #changed_names > 1 then
        -- utils.dprint("选择2种替换")
        --选择2种 orig_name 全部替换为相应的 turn_name
        for i=1,#changed_names-1 do
            for j=i+1,#changed_names do
                local buffer1 = minnames[changed_names[i][1]]
                local buffer2 = minnames[changed_names[j][1]]
                local orig_name1 = changed_names[i][1]
                local turn_name1 = changed_names[i][2]
                local orig_name2 = changed_names[j][1]
                local turn_name2 = changed_names[j][2]
                -- utils.dprint(tostring(orig_name1).."=>"..tostring(turn_name1), tostring(orig_name2).."=>"..tostring(turn_name2))
                if orig_name1 ~= orig_name2 then
                    for ii=1,buffer1 do
                        for jj=1,buffer2 do
                            minnames[orig_name1] = minnames[orig_name1] > ii and minnames[orig_name1]-ii or nil                 -- orig_name 减少 ii 个
                            minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+ii or ii                       -- turn_name 增加 ii 个
                            minnames[orig_name2] = minnames[orig_name2] > jj and minnames[orig_name2]-jj or nil                 -- orig_name 减少 jj 个
                            minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+jj or jj                       -- turn_name 增加 jj 个
                            if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                -- utils.dprint("变换后minnames", minnames)
                                table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                            end
                            minnames[turn_name2] = minnames[turn_name2] > jj and minnames[turn_name2]-jj or nil                 -- 还原turn_name的数量
                            minnames[orig_name2] = minnames[orig_name2] and minnames[orig_name2]+jj or jj                       -- 还原orig_name的数量
                            minnames[turn_name1] = minnames[turn_name1] > ii and minnames[turn_name1]-ii or nil                 -- 还原turn_name的数量
                            minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+ii or ii                       -- 还原orig_name的数量
                            -- utils.dprint("还原后minnames", minnames)
                        end
                    end
                else  --如 叶肉/干叶肉/烤叶肉>=3的情况，通过该分支可以将 叶肉=3 变为 叶肉=1、干叶肉=1、烤叶肉=1。
                    if buffer1 > 1 then
                        for ii=1,buffer1 do
                            for jj=0,buffer1-ii do
                                minnames[orig_name1] = minnames[orig_name1] > (ii+jj) and minnames[orig_name1]-ii-jj or nil         -- orig_name 减少 ii+jj 个
                                minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+ii or ii                       -- turn_name 增加 ii 个
                                minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+jj or (jj>0 and jj or nil)     -- turn_name 增加 jj 个，jj可能为0
                                if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                    -- utils.dprint("同源变换后minnames", minnames)
                                    table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                                end
                                minnames[turn_name2] = minnames[turn_name2] and (minnames[turn_name2] > jj and minnames[turn_name2]-jj or nil) or nil                 -- 还原turn_name的数量
                                minnames[orig_name2] = minnames[orig_name2] and minnames[orig_name2]+jj or jj                       -- 还原orig_name的数量
                                minnames[turn_name1] = minnames[turn_name1] > ii and minnames[turn_name1]-ii or nil                 -- 还原turn_name的数量
                                minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+ii or ii                       -- 还原orig_name的数量
                                -- utils.dprint("还原后minnames", minnames)
                            end
                        end
                    end
                end
            end
        end
    end

    if #changed_names > 2 then
        -- utils.dprint("选择3种替换")
        --选择3种 orig_name 全部替换为响应的 turn_name
        for i=1,#changed_names-2 do
            for j=i+1,#changed_names-1 do
                for k=j+1,#changed_names do
                    local buffer1 = minnames[changed_names[i][1]]
                    local buffer2 = minnames[changed_names[j][1]]
                    local buffer3 = minnames[changed_names[k][1]]
                    local orig_name1 = changed_names[i][1]
                    local turn_name1 = changed_names[i][2]
                    local orig_name2 = changed_names[j][1]
                    local turn_name2 = changed_names[j][2]
                    local orig_name3 = changed_names[k][1]
                    local turn_name3 = changed_names[k][2]
                    -- utils.dprint(tostring(orig_name1).."=>"..tostring(turn_name1).." "..tostring(orig_name2).."=>"..tostring(turn_name2).." "..tostring(orig_name3).."=>"..tostring(turn_name3))
                    if orig_name1~=orig_name2 and orig_name1~=orig_name3 and orig_name2~=orig_name3 then
                        for ii=1,buffer1 do
                            for jj=1,buffer2 do
                                for kk=1,buffer3 do
                                    minnames[orig_name1] = minnames[orig_name1] > ii and minnames[orig_name1]-ii or nil                 -- orig_name 减少 ii 个
                                    minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+ii or ii                       -- turn_name 增加 ii 个
                                    minnames[orig_name2] = minnames[orig_name2] > jj and minnames[orig_name2]-jj or nil                 -- orig_name 减少 jj 个
                                    minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+jj or jj                       -- turn_name 增加 jj 个
                                    minnames[orig_name3] = minnames[orig_name3] > kk and minnames[orig_name3]-kk or nil                 -- orig_name 减少 kk 个
                                    minnames[turn_name3] = minnames[turn_name3] and minnames[turn_name3]+kk or kk                       -- turn_name 增加 kk 个
                                    -- utils.dprint("变换后minnames", minnames)
                                    if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                        -- utils.dprint("变换有效")
                                        table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                                    end
                                    minnames[turn_name3] = minnames[turn_name3] > kk and minnames[turn_name3]-kk or nil                 -- 还原turn_name的数量
                                    minnames[orig_name3] = minnames[orig_name3] and minnames[orig_name3]+kk or kk                       -- 还原orig_name的数量
                                    minnames[turn_name2] = minnames[turn_name2] > jj and minnames[turn_name2]-jj or nil                 -- 还原turn_name的数量
                                    minnames[orig_name2] = minnames[orig_name2] and minnames[orig_name2]+jj or jj                       -- 还原orig_name的数量
                                    minnames[turn_name1] = minnames[turn_name1] > ii and minnames[turn_name1]-ii or nil                 -- 还原turn_name的数量
                                    minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+ii or ii                       -- 还原orig_name的数量
                                    -- utils.dprint("还原后minnames", minnames)
                                end
                            end
                        end
                    elseif orig_name1==orig_name2 and orig_name1~=orig_name3 and orig_name2~=orig_name3 then
                        for ii=1,buffer1 do
                            for jj=0,buffer1-ii do
                                for kk=1,buffer3 do
                                    minnames[orig_name1] = minnames[orig_name1] > (ii+jj) and minnames[orig_name1]-ii-jj or nil         -- orig_name 减少 ii+jj 个
                                    minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+ii or ii                       -- turn_name 增加 ii 个
                                    minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+jj or (jj>0 and jj or nil)     -- turn_name 增加 jj 个，jj可能为0
                                    minnames[orig_name3] = minnames[orig_name3] > kk and minnames[orig_name3]-kk or nil                 -- orig_name 减少 kk 个
                                    minnames[turn_name3] = minnames[turn_name3] and minnames[turn_name3]+kk or kk                       -- turn_name 增加 kk 个
                                    -- utils.dprint("变换后minnames", minnames)
                                    if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                        -- utils.dprint("变换有效")
                                        table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                                    end
                                    minnames[turn_name3] = minnames[turn_name3] > kk and minnames[turn_name3]-kk or nil                 -- 还原turn_name的数量
                                    minnames[orig_name3] = minnames[orig_name3] and minnames[orig_name3]+kk or kk                       -- 还原orig_name的数量
                                    minnames[turn_name2] = minnames[turn_name2] and (minnames[turn_name2] > jj and minnames[turn_name2]-jj or nil) or nil -- 还原turn_name的数量
                                    minnames[turn_name1] = minnames[turn_name1] > ii and minnames[turn_name1]-ii or nil                 -- 还原turn_name的数量
                                    minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+ii+jj or ii+jj                 -- 还原orig_name的数量
                                    -- utils.dprint("还原后minnames", minnames)
                                end
                            end
                        end
                    elseif orig_name1==orig_name3 and orig_name1~=orig_name2 and orig_name2~=orig_name3 then
                        for ii=1,buffer1 do
                            for jj=1,buffer2 do
                                for kk=0,buffer1-ii do
                                    minnames[orig_name1] = minnames[orig_name1] > (ii+kk) and minnames[orig_name1]-ii-kk or nil         -- orig_name 减少 ii+kk 个
                                    minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+ii or ii                       -- turn_name 增加 ii 个
                                    minnames[orig_name2] = minnames[orig_name2] > jj and minnames[orig_name2]-jj or nil                 -- orig_name 减少 jj 个
                                    minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+jj or jj                       -- turn_name 增加 jj 个
                                    minnames[turn_name3] = minnames[turn_name3] and minnames[turn_name3]+kk or (kk>0 and kk or nil)     -- turn_name 增加 kk 个，kk可能为0
                                    -- utils.dprint("变换后minnames", minnames)
                                    if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                        -- utils.dprint("变换有效")
                                        table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                                    end
                                    minnames[turn_name3] = minnames[turn_name3] and (minnames[turn_name3] > kk and minnames[turn_name3]-kk or nil) or nil -- 还原turn_name的数量
                                    minnames[turn_name2] = minnames[turn_name2] > jj and minnames[turn_name2]-jj or nil                 -- 还原turn_name的数量
                                    minnames[orig_name2] = minnames[orig_name2] and minnames[orig_name2]+jj or jj                       -- 还原orig_name的数量
                                    minnames[turn_name1] = minnames[turn_name1] > ii and minnames[turn_name1]-ii or nil                 -- 还原turn_name的数量
                                    minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+ii+kk or ii+kk                 -- 还原orig_name的数量
                                    -- utils.dprint("还原后minnames", minnames)
                                end
                            end
                        end
                    elseif orig_name2==orig_name3 and orig_name1~=orig_name2 and orig_name1~=orig_name3 then
                        for ii=1,buffer1 do
                            for jj=1,buffer2 do
                                for kk=0,buffer2-jj do
                                    minnames[orig_name1] = minnames[orig_name1] > ii and minnames[orig_name1]-ii or nil                 -- orig_name 减少 ii 个
                                    minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+ii or ii                       -- turn_name 增加 ii 个
                                    minnames[orig_name2] = minnames[orig_name2] > (jj+kk) and minnames[orig_name2]-jj-kk or nil         -- orig_name 减少 jj+kk 个
                                    minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+jj or jj                       -- turn_name 增加 jj 个
                                    minnames[turn_name3] = minnames[turn_name3] and minnames[turn_name3]+kk or (kk>0 and kk or nil)     -- turn_name 增加 kk 个，kk可能为0
                                    -- utils.dprint("变换后minnames", minnames)
                                    if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                        -- utils.dprint("变换有效")
                                        table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                                    end
                                    minnames[turn_name3] = minnames[turn_name3] and (minnames[turn_name3] > kk and minnames[turn_name3]-kk or nil) or nil -- 还原turn_name的数量
                                    minnames[turn_name2] = minnames[turn_name2] > jj and minnames[turn_name2]-jj or nil                 -- 还原turn_name的数量
                                    minnames[orig_name2] = minnames[orig_name2] and minnames[orig_name2]+jj+kk or jj+kk                 -- 还原orig_name的数量
                                    minnames[turn_name1] = minnames[turn_name1] > ii and minnames[turn_name1]-ii or nil                 -- 还原turn_name的数量
                                    minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+ii or ii                       -- 还原orig_name的数量
                                    -- utils.dprint("还原后minnames", minnames)
                                end
                            end
                        end
                    elseif orig_name1==orig_name2 and orig_name1==orig_name3 then
                        for ii=1,buffer1 do
                            for jj=0,buffer1-ii do
                                for kk=0,buffer1-ii-jj do
                                    minnames[orig_name1] = minnames[orig_name1] > (ii+jj+kk) and minnames[orig_name1]-ii-jj-kk or nil   -- orig_name 减少 ii+jj+kk 个
                                    minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+ii or ii                       -- turn_name 增加 ii 个
                                    minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+jj or (jj>0 and jj or nil)     -- turn_name 增加 jj 个，jj可能为0
                                    minnames[turn_name3] = minnames[turn_name3] and minnames[turn_name3]+kk or (kk>0 and kk or nil)     -- turn_name 增加 kk 个，kk可能为0
                                    -- utils.dprint("变换后minnames", minnames)
                                    if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                        -- utils.dprint("变换有效")
                                        table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                                    end
                                    minnames[turn_name3] = minnames[turn_name3] and (minnames[turn_name3] > kk and minnames[turn_name3]-kk or nil) or nil -- 还原turn_name的数量
                                    minnames[turn_name2] = minnames[turn_name2] and (minnames[turn_name2] > jj and minnames[turn_name2]-jj or nil) or nil -- 还原turn_name的数量
                                    minnames[turn_name1] = minnames[turn_name1] > ii and minnames[turn_name1]-ii or nil                 -- 还原turn_name的数量
                                    minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+ii+jj+kk or ii+jj+kk           -- 还原orig_name的数量
                                    -- utils.dprint("还原后minnames", minnames)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #changed_names > 3 then
        -- utils.dprint("选择4种替换")
        --4种 orig_name 全部替换为响应的 turn_name
        for i=1,#changed_names-3 do
            for j=i+1,#changed_names-2 do
                for k=j+1,#changed_names-1 do
                    for l=k+1,#changed_names do
                        local buffer1 = minnames[changed_names[i][1]]
                        local buffer2 = minnames[changed_names[j][1]]
                        local buffer3 = minnames[changed_names[k][1]]
                        local buffer4 = minnames[changed_names[l][1]]
                        local orig_name1 = changed_names[i][1]
                        local turn_name1 = changed_names[i][2]
                        local orig_name2 = changed_names[j][1]
                        local turn_name2 = changed_names[j][2]
                        local orig_name3 = changed_names[k][1]
                        local turn_name3 = changed_names[k][2]
                        local orig_name4 = changed_names[l][1]
                        local turn_name4 = changed_names[l][2]
                        if orig_name1~=orig_name2 and orig_name1~=orig_name3 and orig_name1~=orig_name4 and orig_name2~=orig_name3 and orig_name2~=orig_name4 and orig_name3~=orig_name4 then
                            minnames[orig_name1] = nil                                                                          -- orig_name 减少 num_orig_name 个
                            minnames[turn_name1] = minnames[turn_name1] and minnames[turn_name1]+buffer1 or buffer1             -- turn_name 增加 num_orig_name 个
                            minnames[orig_name2] = minnames[orig_name2] > buffer2 and minnames[orig_name2]-buffer2 or nil       -- orig_name 减少 buffer 个
                            minnames[turn_name2] = minnames[turn_name2] and minnames[turn_name2]+buffer2 or buffer2             -- turn_name 增加 num_orig_name 个
                            minnames[orig_name3] = minnames[orig_name3] > buffer3 and minnames[orig_name3]-buffer3 or nil       -- orig_name 减少 buffer 个
                            minnames[turn_name3] = minnames[turn_name3] and minnames[turn_name3]+buffer3 or buffer3             -- turn_name 增加 num_orig_name 个
                            minnames[orig_name4] = minnames[orig_name4] > buffer4 and minnames[orig_name4]-buffer4 or nil       -- orig_name 减少 buffer 个
                            minnames[turn_name4] = minnames[turn_name4] and minnames[turn_name4]+buffer4 or buffer4             -- turn_name 增加 num_orig_name 个
                            -- utils.dprint("变换后minnames", minnames)
                            if _ptest(test,minnames,mintags) == 1 and not CheckMinnameInMinlist(minnames, recipe.minlist) then
                                -- utils.dprint("变换有效")
                                table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                            end
                            minnames[turn_name1] = minnames[turn_name1] > buffer1 and minnames[turn_name1]-buffer1 or nil       -- 还原turn_name的数量
                            minnames[orig_name1] = minnames[orig_name1] and minnames[orig_name1]+buffer1 or buffer1             -- 还原orig_name的数量
                            minnames[turn_name2] = minnames[turn_name2] > buffer2 and minnames[turn_name2]-buffer2 or nil       -- 还原turn_name的数量
                            minnames[orig_name2] = minnames[orig_name2] and minnames[orig_name2]+buffer2 or buffer2             -- 还原orig_name的数量
                            minnames[turn_name3] = minnames[turn_name3] > buffer3 and minnames[turn_name3]-buffer3 or nil       -- 还原turn_name的数量
                            minnames[orig_name3] = minnames[orig_name3] and minnames[orig_name3]+buffer3 or buffer3             -- 还原orig_name的数量
                            minnames[turn_name4] = minnames[turn_name4] > buffer4 and minnames[turn_name4]-buffer4 or nil       -- 还原turn_name的数量
                            minnames[orig_name4] = minnames[orig_name4] and minnames[orig_name4]+buffer4 or buffer4             -- 还原orig_name的数量
                            -- utils.dprint("还原后minnames", minnames)
                        end
                    end
                end
            end
        end
    end

    -- 遍历_allnames和_alltags，尝试将一个tag变为1个其他的tag或name
    for mintag, amt in pairs(mintags_list) do
        buffer = mintags[mintag]
        if buffer ~= nil then
            mintags[mintag] = mintags[mintag] > 1 and mintags[mintag]-1 or nil -- reduce mintag by 1

            -- try to replace mintag it with a new name
            for name,_ in pairs(allnames) do
                minnames[name] = minnames[name] and minnames[name]+1 or 1
                if _ptest(test,minnames,mintags) == 1 then
                    table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                end
                minnames[name] = minnames[name] > 1 and minnames[name]-1 or nil
            end

            -- try to replace mintag with a new tag
            for tag,_ in pairs(alltags) do
                if tag ~= mintag then
                    local max_num = recipe.maxtags[tag] ~= nil and recipe.maxtags[tag]-0.25 or 4
                    mintags[tag] = mintags[tag] and mintags[tag]+max_num or max_num
                    if _ptest(test,minnames,mintags) == 1 then
                        -- 再做一遍 寻找最小要求
                        local amount = mintags[tag]
                        mintags[tag] = nil
                        if _ptest(test, minnames, mintags) == 1 then -- _Test[nil] == true, not a required tag
                            recipe.mintags[tag] = nil
                        else -- _Test[nil] == false, mintag is required
                            mintags[tag] = amount - _dtag
                            if _ptest(test, minnames, mintags) ~= 1 then -- _Test[amount-1] == false, valid mintag
                                mintags[tag] = amount
                            else -- _Test[amount-1] == true, invalid restriction
                                mintags[tag] = _dtag
                                while _ptest(test, minnames, mintags) ~= 1 and mintags[tag] < 1001 do
                                    mintags[tag] = mintags[tag] + _dtag
                                end
                                recipe.mintags[tag] = mintags[tag]
                            end
                        end
                        table.insert(recipe.minlist, {names=deepcopy(minnames),tags=deepcopy(mintags)})
                    end
                    mintags[tag] = mintags[tag] > max_num and mintags[tag]-max_num or nil
                end
            end

            mintags[mintag] = buffer
        end
    end

    recipe.minmix = Composition(recipe.minlist)
    recipe.maxmix = Composition({{names=recipe.maxnames, tags=recipe.maxtags}})

    -- 去除食材name所提供的tag，例：火鸡正餐，names.drumstick = 2, tags.meat = 1.25, tags.fruit = 0.25
    -- 由于2个火鸡腿names.drumstick会提供1个肉度tags.meat，因此tags.meat变为0.25
    for _, minset in ipairs(recipe.minlist) do
        for name, name_amt in pairs(minset.names) do
            for tag, tag_amt in pairs(cooking.ingredients[name].tags) do
                if minset.tags[tag] then
                    minset.tags[tag] = minset.tags[tag] - tag_amt * name_amt
                    if minset.tags[tag] <= 0 then
                        minset.tags[tag] = nil
                    end
                end
            end
        end
    end

    return true
end

local function GetAllNameTag()
    for name, ing in pairs(cooking.ingredients) do
        allnames[name] = 1
        for tag, _ in pairs(ing.tags) do
            alltags[tag] = 1
        end
    end
end

local function GetGroupIndex(groups, changed_name)
    if next(groups) == nil then
        return -1
    end
    for idx, group in ipairs(groups) do
        if table.contains(group.group, changed_name[1]) or table.contains(group.group, changed_name[2]) then
            return idx
        end
    end
    return 0
end

local function GetChangeGroup(changed_names)
    --[[{
        [1] = {
            [1] = 'kyno_mussel_cooked',
            [2] = 'kyno_mussel'
            [3] = 1
        },
        [2] = {
            [1] = 'pondeel',
            [2] = 'eel_cooked'
            [3] = 2
        },
        [3] = {
            [1] = 'pondeel',
            [2] = 'eel'
            [3] = 2
        }
    }	
    ==>
    {
        [1] = {
            group = {'kyno_mussel_cooked', 'kyno_mussel'}
            amt = 1
        }
        [2] = {
            group = {'pondeel', 'eel_cooked', 'eel'}
            amt = 2
        }
    }]]--
    if next(changed_names) == nil then
        return {}
    end
    local groups = {}
    for _, v in ipairs(changed_names) do
        local grp_idx = GetGroupIndex(groups, v)
        -- utils.dprint("groups", groups)
        -- utils.dprint("grp_idx", grp_idx)
        if grp_idx == -1 or grp_idx == 0 then
            local cur_group = {group={}, amt=0}
            table.insert(cur_group.group, v[1])
            table.insert(cur_group.group, v[2])
            cur_group.amt = v[3]
            table.insert(groups, cur_group)
        else
            local cur_group = groups[grp_idx]
            -- utils.dprint("cur_group", cur_group)
            if cur_group.amt == v[3] then
                if not table.contains(cur_group.group, v[1]) then
                    table.insert(cur_group.group, v[1])
                end
                if not table.contains(cur_group.group, v[2]) then
                    table.insert(cur_group.group, v[2])
                end
                -- utils.dprint("cur_group", cur_group)
                -- utils.dprint("groups", groups)
            else
                print("GetChangeGroup 数量之和错误")
                -- utils.dprint("changed_names", changed_names)
                -- utils.dprint("groups", groups)
            end
        end
    end
    return groups
end

local function GetMixForOneGroup(group)
    --[[对于a+b+c+...=amt的形式生成mix
        {
            group = {'pondeel', 'eel_cooked', 'eel'}
            amt = 2
        }
    ]]--
    local grp_len = #(group.group)
    local grp_amt = group.amt
    local iter_max = math.min(grp_len, grp_amt)
    local res = {}
    if iter_max > 0 then  --选出1种食材进行组合
        for i=1, grp_len do
            local cur_mix = {}
            cur_mix[group.group[i]] = grp_amt
            table.insert(res, cur_mix)
        end
    end
    if iter_max > 1 then  --选出2种食材进行组合
        for i=1, grp_len-1 do
            for j=i+1, grp_len do
                for ii=1, grp_amt-1 do
                    local cur_mix = {}
                    cur_mix[group.group[i]] = ii
                    cur_mix[group.group[j]] = grp_amt-ii
                    table.insert(res, cur_mix)
                end
            end
        end
    end
    if iter_max > 2 then  --选出3种食材进行组合
        for i=1, grp_len-2 do
            for j=i+1, grp_len-1 do
                for k=j+1, grp_len do
                    for ii=1, grp_amt-2 do
                        for jj=1, grp_amt-ii-1 do
                            local cur_mix = {}
                            cur_mix[group.group[i]] = ii
                            cur_mix[group.group[j]] = jj
                            cur_mix[group.group[k]] = grp_amt-ii-jj
                            table.insert(res, cur_mix)
                        end
                    end
                end
            end
        end
    end
    if iter_max > 3 then  --选出4种食材进行组合
        for i=1, grp_len-3 do
            for j=i+1, grp_len-2 do
                for k=j+1, grp_len-1 do
                    for l=k+1, grp_len do
                        local cur_mix = {}
                        cur_mix[group.group[i]] = 1
                        cur_mix[group.group[j]] = 1
                        cur_mix[group.group[k]] = 1
                        cur_mix[group.group[l]] = 1
                        table.insert(res, cur_mix)
                    end
                end
            end
        end
    end
    return res
end

local function GetMixForAllGroups(groups)
    if next(groups) == nil then
        return {}
    end
    local mix_groups = {}
    local max_idxs = {}
    local cur_idxs = {}
    for _,group in ipairs(groups) do
        table.insert(mix_groups, GetMixForOneGroup(group))
        table.insert(max_idxs, #mix_groups[#mix_groups])
        table.insert(cur_idxs, 1)
    end
    -- utils.dprint("mix_groups", mix_groups)
    -- utils.dprint("max_idxs", max_idxs)
    -- utils.dprint("cur_idxs", cur_idxs)
    local res = {}
    local function check_end(cur_idx, max_idx)
        for i=1,#cur_idx do
            if cur_idx[i] < max_idx[i] then
                -- utils.dprint("check_end", "false")
                return false
            end
        end
        -- utils.dprint("check_end", "true")
        return true
    end
    local function check_overflow(cur_idx, max_idx)
        for i=1,#cur_idx do
            if cur_idx[i] > max_idx[i] then
                return i
            end
        end
        return #cur_idx+1
    end
    local function step_cur_idx(cur_idx, max_idx)
        cur_idx[1] = cur_idx[1] + 1
        while check_overflow(cur_idx, max_idx)<#cur_idx do
            local overflow_idx = check_overflow(cur_idx, max_idx)
            cur_idx[overflow_idx] = 1
            cur_idx[overflow_idx+1] = cur_idx[overflow_idx+1] + 1
        end
        return cur_idx
    end
    --融合列表，重复元素原样插入
    local function merge_array(all_grp)
        if #all_grp == 1 then
            return all_grp[1]
        end
        local merged = {}
        for _,t in ipairs(all_grp) do
            for k,v in pairs(t) do
                merged[k] = v
            end
        end
        return merged
    end
    cur_idxs[1] = 0
    while not check_end(cur_idxs, max_idxs) do
        cur_idxs = step_cur_idx(cur_idxs, max_idxs)
        -- utils.dprint("cur_idxs", cur_idxs)
        local cur_all_grp = {}
        for i=1,#cur_idxs do
            table.insert(cur_all_grp, mix_groups[i][cur_idxs[i]])
        end
        table.insert(res, merge_array(cur_all_grp))
        -- utils.dprint("cur_all_grp", cur_all_grp)
        -- utils.dprint("res", res)
    end
    return res
end

local function GetStrForOneGroup(group)
    --[[对于a+b+c+...=amt的形式生成str
        {
            group = {'pondeel', 'eel_cooked', 'eel'}
            amt = 2
        }
    ]]--
    -- utils.dprint("GetStrForOneGroup.group", group)
    local except
    except = {'pondeel', 'eel_cooked', 'eel'}
    if utils.array_match(except, group.group) then
        return STRINGS.UI.COOKBOOK.COOK_RECIPE.PHRASE.EEL.."≥"..tostring(group.amt)
    end
    except = {'trunk_summer', 'trunk_cooked', 'trunk_winter'}
    if utils.array_match(except, group.group) then
        return STRINGS.UI.COOKBOOK.COOK_RECIPE.PHRASE.TRUNK.."≥"..tostring(group.amt)
    end
    except = {'kyno_plantmeat_dried', 'plantmeat', 'plantmeat_cooked'}
    if utils.array_match(except, group.group) then
        return STRINGS.UI.COOKBOOK.COOK_RECIPE.PHRASE.HOF.PLANTMEAT.."≥"..tostring(group.amt)
    end
    local res = nil
    local processed_ing = {}
    for _,v in ipairs(group.group) do
        -- utils.dprint("processed_ing", processed_ing)
        -- utils.dprint("v", v)
        if processed_ing[v] == nil then
            local raw_v = utils.get_raw(v)
            -- utils.dprint("raw_v",raw_v)
            processed_ing[raw_v] = 1
            processed_ing[raw_v.."_cooked"] = 1
            processed_ing[raw_v.."_dried"] = 1
            local exist_t = {}
            exist_t["raw"] = table.contains(group.group, raw_v)
            exist_t["cooked"] = table.contains(group.group, raw_v.."_cooked")
            exist_t["dried"] = table.contains(group.group, raw_v.."_dried")
            -- utils.dprint("exist_t",exist_t)
            -- utils.dprint("res",res)
            if exist_t["raw"] then
                local raw_str = STRINGS.NAMES[string.upper(aliases_reverse[raw_v] or raw_v)] or (aliases_reverse[raw_v] or raw_v)
                if exist_t["cooked"] and exist_t["dried"] then
                    local mix_str = STRINGS.UI.COOKBOOK.COOK_RECIPE_BOTH..raw_str
                    res = res and res.."/"..mix_str or mix_str
                elseif exist_t["cooked"] and not exist_t["dried"] then
                    local mix_str = STRINGS.UI.COOKBOOK.COOK_RECIPE_COOKED..raw_str
                    res = res and res.."/"..mix_str or mix_str
                elseif not exist_t["cooked"] and exist_t["dried"] then
                    local mix_str = STRINGS.UI.COOKBOOK.COOK_RECIPE_DRIED..raw_str
                    res = res and res.."/"..mix_str or mix_str
                elseif not exist_t["cooked"] and not exist_t["dried"] then
                    res = res and res.."/"..raw_str or raw_str
                end
            else
                local cooked_str = STRINGS.NAMES[string.upper(aliases_reverse[raw_v.."_cooked"] or raw_v.."_cooked")] or (aliases_reverse[raw_v.."_cooked"] or raw_v.."_cooked")
                local dried_str = STRINGS.NAMES[string.upper(aliases_reverse[raw_v.."_dried"] or raw_v.."_dried")] or (aliases_reverse[raw_v.."_dried"] or raw_v.."_dried")
                if exist_t["cooked"] and exist_t["dried"] then
                    local mix_str = cooked_str.."/"..dried_str
                    res = res and res.."/"..mix_str or mix_str
                elseif exist_t["cooked"] and not exist_t["dried"] then
                    res = res and res.."/"..cooked_str or cooked_str
                elseif not exist_t["cooked"] and exist_t["dried"] then
                    res = res and res.."/"..dried_str or dried_str
                end
            end
            -- utils.dprint("res",res)
        end
    end
    res = res and res.."≥"..tostring(group.amt) or "≥"..tostring(group.amt)
    -- utils.dprint("res", res)
    return res
end

local function GetStrForAllGroups(groups)
    -- utils.dprint("GetStrForAllGroups.groups", groups)
    if next(groups) == nil then
        return ""
    end
    local res = nil
    for _, group in ipairs(groups) do
        local cur_str = GetStrForOneGroup(group)
        res = res and res..STRINGS.UI.COOKBOOK.SEP..cur_str or cur_str
        -- utils.dprint("group", group)
        -- utils.dprint("cur_str", cur_str)
        -- utils.dprint("res", res)
    end
    return res and res or ""
end

local function GetRecipeStringIter(mix, arr)
	for _, conj in ipairs(mix) do
		if conj.amt then
			table.insert(arr, conj)
		else
			table.insert(arr, "{")
			for aid, alt in ipairs(conj) do
				if aid > 1 then
					table.insert(arr, ',')
				end
				if alt.amt then
					table.insert(arr, alt)
				else
					GetRecipeStringIter(alt, arr)
				end
			end
			local brackets = (#arr ~= 0 or #mix == 0)
			if brackets then
				table.insert(arr, "}")
			end
		end
	end
	return arr
end

local function GetRecipeString(food_name)
    --原版特例
	if food_name == "californiaroll" then --加利福尼亚卷
		return STRINGS.UI.COOKBOOK.COOK_RECIPE.CALIFORNIAROLL
    end
    --永不妥协
    if TUNING.MOD_UM_ENABLED then
        if food_name == "um_deviled_eggs" then --永不妥协 恶魔蛋
            -- 永test函数中的tags.monster > tags.egg写法不规范，无法解析，手动写一下
            -- test = function(cooker, names, tags) 
            -- return tags.monster and tags.egg and not tags.meat and tags.monster > tags.egg end,
            return STRINGS.UI.COOKBOOK.COOK_RECIPE.UM.UM_DEVILED_EGGS
        elseif food_name == "figatoni" then --永不妥协 原版 无花果意面
            return STRINGS.UI.COOKBOOK.COOK_RECIPE.UM.FIGATONI
        end
    end
    --Heap Of Foods
    if TUNING.MOD_HOF_ENABLED then
        if food_name == "cornincup" then --墨西哥玉米杯装
            return STRINGS.UI.COOKBOOK.COOK_RECIPE.HOF.CORNINCUP
        end
    end

    local minmix = diary_food_detail[food_name].minmix
    local maxmix = diary_food_detail[food_name].maxmix
    -- utils.dprint("minmix", minmix)
    -- utils.dprint("maxmix", maxmix)

    if minmix == nil then
        return STRINGS.UI.COOKBOOK.COOK_RECIPE_UNKNOWN
    end

    local groups = GetChangeGroup(diary_food_detail[food_name].changed)
    local allmix = GetMixForAllGroups(groups)
    local newstr = GetStrForAllGroups(groups)
    -- utils.dprint("changed", diary_food_detail[food_name].changed)
    -- utils.dprint("groups", groups)
    -- utils.dprint("allmix", allmix)
    -- utils.dprint("newstr", newstr)
    -- utils.dprint("minmix", minmix)
    -- utils.dprint("maxmix", maxmix)

	local arr = {}
	arr = GetRecipeStringIter(minmix, arr)

	local str = ""
	local prev = "^"

	local matching_mix			    --开始匹配混合组合，简记为mm
	local mm_follow_combin		    --非首个组合
	local mm_all_combine		    --根据首个组合计算出的所有组合
	local mm_prefix_str

	local function reset_mm()
		matching_mix = false		--开始进入连续or
		mm_follow_combin = {}		--非首个组合
		mm_all_combine = {}			--根据首个组合计算出的所有组合
		mm_prefix_str = ""			--从开始进入连续or时记录str已有内容
	end

	reset_mm()

	for _, conj in ipairs(arr) do
		if conj == "," then
			str = str..STRINGS.UI.COOKBOOK.COOK_RECIPE_OR

            -- utils.dprint("---------------------------,")
            -- utils.dprint("str", str)

            if matching_mix then
                -- utils.dprint("mm_all_combine", mm_all_combine)
                -- utils.dprint("mm_follow_combin", mm_follow_combin)
                if mm_follow_combin.tag == nil then
                    local hit_i = nil
                    for i, t in ipairs(mm_all_combine) do
                        if utils.map_match(t, mm_follow_combin) then
                            hit_i = i
                        end
                    end

                    -- utils.dprint("hit_i", hit_i)
                    mm_follow_combin = {}
                    if hit_i ~= nil then
                        table.remove(mm_all_combine, hit_i)
                        -- utils.dprint("mm_all_combine", mm_all_combine)
                        if next(mm_all_combine) == nil then
                            reset_mm()
                        end
                    else
                        reset_mm()
                    end
                else
                    mm_follow_combin = {}
                end
            end
		elseif conj == "{" then
			if string.len(str) > 0 then
				mm_prefix_str = str..STRINGS.UI.COOKBOOK.SEP
				str = str..STRINGS.UI.COOKBOOK.SEP..conj
			else
				mm_prefix_str = ""
				str = str..conj
			end
            -- utils.dprint("---------------------------{")
            -- utils.dprint("str", str)
			matching_mix = true
            mm_all_combine = allmix
		elseif conj == "}" then
			str = str..conj
            -- utils.dprint("---------------------------}")
            -- utils.dprint("str", str)
			if matching_mix then
				--匹配最后一个组合
                -- utils.dprint("mm_all_combine", mm_all_combine)
				local hit_i = nil
				for i, t in ipairs(mm_all_combine) do
					if utils.map_match(t, mm_follow_combin) then
						hit_i = i
					end
				end
                -- utils.dprint("mm_follow_combin", mm_follow_combin)
                -- utils.dprint("hit_i", hit_i)
				if hit_i ~= nil then
					table.remove(mm_all_combine, hit_i)
                    -- utils.dprint("mm_all_combine", mm_all_combine)
				end
				if next(mm_all_combine) == nil and newstr ~= "" then
					str = mm_prefix_str..newstr
				end
				reset_mm()
			end
		else
			local item = conj["name"]~=nil and (aliases[conj["name"]] or conj["name"]) or conj["tag"]
			local type = conj["name"]~=nil and "name" or "tag"
            -- utils.dprint("---------------------------aaa")
            -- utils.dprint("item", item)
            -- utils.dprint("type", type)
			-- local name_str = STRINGS.NAMES[string.upper(aliases_reverse[item] or item)] or subfmt(STRINGS.UI.COOKBOOK.UNKNOWN_FOOD_NAME, {food = aliases_reverse[item] or item or "SDF"})
			local name_str = STRINGS.NAMES[string.upper(aliases_reverse[item] or item)] or (aliases_reverse[item] or item)
			local next_str
			if type == "name" then
				local i1, i2 = math.modf(conj["amt"])
				if i2 == 0 or i2 == 0.5 then
					local wait_remove
					for i, v in ipairs(maxmix) do
						if v["name"] == conj["name"] and v["amt"] == conj["amt"] then
							wait_remove = i
						end
					end
					if wait_remove ~= nil then
						next_str = name_str.."="..tostring(conj["amt"])
						table.remove(maxmix, wait_remove)
					else
						next_str = name_str.."≥"..tostring(conj["amt"])
					end
				elseif i2 == 0.25 then
					next_str = name_str..">"..tostring(i1)
				else
					next_str = name_str..">"..tostring(conj["amt"]-0.25)
				end
                -- utils.dprint("matching_mix", matching_mix)
                if matching_mix then
                    mm_follow_combin[item] = conj["amt"]
                    -- utils.dprint("mm_follow_combin", mm_follow_combin)
				end

			else
				local i1, i2 = math.modf(conj["amt"])
				if i2 == 0 or i2 == 0.5 then
					next_str = tag_str[item].."≥"..tostring(conj["amt"])
				elseif i2 == 0.25 then
					next_str = tag_str[item]..">"..tostring(i1)
				else
					next_str = tag_str[item]..">"..tostring(conj["amt"]-0.25)
				end
				if matching_mix then
                    mm_follow_combin[item] = conj["amt"]
                    mm_follow_combin["tag"] = true
                    -- utils.dprint("mm_follow_combin", mm_follow_combin)
					mm_prefix_str = mm_prefix_str..next_str..STRINGS.UI.COOKBOOK.COOK_RECIPE_OR
                    -- utils.dprint("mm_prefix_str", mm_prefix_str)
				end
			end
			if prev ~= "^" and prev ~= "{" and prev ~= "," then
				next_str = STRINGS.UI.COOKBOOK.SEP..next_str
			end
			str = str..next_str
            -- utils.dprint("str", str)
		end
		prev = conj
	end

	if maxmix ~= nil and next(maxmix) ~= nil then
		str = str.."\n"

		for i, conj in ipairs(maxmix) do
			local item = conj["name"]~=nil and conj["name"] or conj["tag"]
			local type = conj["name"]~=nil and "name" or "tag"
			if conj["amt"] == 0 then
				if type == "name" then
					str = str..
						STRINGS.UI.COOKBOOK.COOK_RECIPE_NO..
						(STRINGS.NAMES[string.upper(aliases_reverse[item] or item)] or (aliases_reverse[item] or item))
				else
					str = str..
						STRINGS.UI.COOKBOOK.COOK_RECIPE_NO..
						tag_str[item]
				end
			else
				if type == "name" then
					str = str..(STRINGS.NAMES[string.upper(aliases_reverse[item] or item)] or (aliases_reverse[item] or item)).."≤"..tostring(conj["amt"])
				else
					str = str..tag_str[item].."≤"..tostring(conj["amt"])
				end
			end
			if i < #maxmix then
				str = str..STRINGS.UI.COOKBOOK.SEP
			end
		end
	end
	return str
end

local function GetTypeString(food_data)
	local str = STRINGS.UI.FOOD_TYPES[food_data.foodtype or FOODTYPE.GENERIC] or STRINGS.UI.COOKBOOK.FOOD_TYPE_UNKNOWN
	if food_data.secondaryfoodtype ~= nil then
		local secondary = STRINGS.UI.FOOD_TYPES[food_data.secondaryfoodtype]
		if secondary ~= nil then
			str = str..STRINGS.UI.COOKBOOK.SEP..secondary
		end
	end
	return str
end

local function GetSpoilString(perishtime)
	return perishtime == nil and STRINGS.UI.COOKBOOK.PERISH_NEVER
			or perishtime <= TUNING.PERISH_SUPERFAST and STRINGS.UI.COOKBOOK.PERISH_VERY_QUICKLY
			or perishtime <= TUNING.PERISH_FAST and STRINGS.UI.COOKBOOK.PERISH_QUICKLY
			or perishtime <= TUNING.PERISH_MED and STRINGS.UI.COOKBOOK.PERISH_AVERAGE
			or perishtime <= TUNING.PERISH_SLOW and STRINGS.UI.COOKBOOK.PERISH_SLOWLY
			or STRINGS.UI.COOKBOOK.PERISH_VERY_SLOWLY
end

local function GetMethodString(food_data)
	return ((food_data.cooker == nil and STRINGS.UI.COOKBOOK.COOK_METHOD_COOKER_UNKNOWN
			or food_data.cooker == "cookpot" and STRINGS.NAMES.COOKPOT
			or food_data.cooker == "portablecookpot" and STRINGS.NAMES.PORTABLECOOKPOT_ITEM
			or food_data.cooker == "archive_cookpot" and STRINGS.NAMES.ARCHIVE_COOKPOT)..
			STRINGS.UI.COOKBOOK.SEP)..
			(food_data.cooktime == nil and STRINGS.UI.COOKBOOK.COOK_METHOD_TIME_UNKNOWN
			or math.floor(TUNING.BASE_COOK_TIME * food_data.cooktime + 0.5))..
			STRINGS.UI.COOKBOOK.COOK_METHOD_TIME_UNIT..
			STRINGS.UI.COOKBOOK.SEP..
			STRINGS.UI.COOKBOOK.COOK_METHOD_PRIORITY..
			(food_data.priority == nil and STRINGS.UI.COOKBOOK.COOK_METHOD_PRIORITY_UNKNOWN
			or food_data.priority)
end

local function GetCookingTimeString(cooktime)
	return cooktime == nil and STRINGS.UI.COOKBOOK.COOKINGTIME_UNKNOWN
			or cooktime < 1.0 and STRINGS.UI.COOKBOOK.COOKINGTIME_SHORT
			or cooktime < 2.0 and STRINGS.UI.COOKBOOK.COOKINGTIME_AVERAGE
			or cooktime < 2.5 and STRINGS.UI.COOKBOOK.COOKINGTIME_LONG
			or STRINGS.UI.COOKBOOK.COOKINGTIME_VERY_LONG
end

local function GetSideEffectString(food_data)
	return  food_data.oneat_desc
			or (food_data.temperature ~= nil and food_data.temperature > 0) and STRINGS.UI.COOKBOOK.FOOD_EFFECTS_HOT_FOOD
			or (food_data.temperature ~= nil and food_data.temperature < 0) and STRINGS.UI.COOKBOOK.FOOD_EFFECTS_COLD_FOOD
			or STRINGS.UI.COOKBOOK.FOOD_EFFECTS_NONE
end

local function GetFoodDetail()
	local myth_food_uncookable = {  -- 神话书说中只能在茶肴小铺中购买，无法烹饪的料理
		myth_food_lrhs = 1,  -- 驴肉火烧
		myth_food_thl  = 1,  -- 糖葫芦
		myth_food_gqmx = 1,	 -- 过桥米线
		myth_food_xcmt = 1,  -- 咸菜馒头
		myth_food_lhyx = 1,  -- 莲花血鸭
		myth_food_nrlm = 1,  -- 牛肉拉面
		myth_food_cdf  = 1,  -- 臭豆腐
		myth_food_djyt = 1,  -- 豆浆油条
	}

    -- 增加 supported_cooker 键，值为 table
    diary_food_detail = {}
    local official_cookpots = {"cookpot", "portablecookpot", "archive_cookpot"}
    for _, cooker_name in ipairs(official_cookpots) do
        for food_name, recipe in pairs(cooking.recipes[cooker_name]) do
            if string.find(tostring(food_name), "_spice_") == nil and myth_food_uncookable[food_name] == nil then
                diary_food_detail[food_name] = diary_food_detail[food_name] or recipe
                diary_food_detail[food_name].supported_cooker = diary_food_detail[food_name].supported_cooker or {}
                diary_food_detail[food_name].supported_cooker[cooker_name] = true
            end
        end
    end
    for cooker_name, recipes in pairs(cooking.recipes) do
        if not table.contains(official_cookpots, cooker_name) then
            for food_name, recipe in pairs(recipes) do
                if string.find(tostring(food_name), "_spice_") == nil and myth_food_uncookable[food_name] == nil then
                    diary_food_detail[food_name] = diary_food_detail[food_name] or recipe
                    diary_food_detail[food_name].supported_cooker = diary_food_detail[food_name].supported_cooker or {}
                    diary_food_detail[food_name].supported_cooker[cooker_name] = true
                end
            end
        end
    end

    -- 增加 minnames maxnames mintags maxtags minmix maxmix minlist 键，值为 string
    GetAllNameTag()
    -- parse recipes from the raw cookbook
    for food_name, recipe in pairs(diary_food_detail) do
        --增加例外
        if atbook_exception[food_name] ~= nil then
            diary_food_detail[food_name].minlist = atbook_exception[food_name].minlist
            diary_food_detail[food_name].maxmix = atbook_exception[food_name].maxmix
        else
            --找到一种能够完成料理的name和tag组合，记录在 raw_recipe 的 minnames maxnames mintags maxtags 中
            local raw_recipe = SmartSearch(recipe.test)

            --生成 raw_recipe 的 minmix maxmix minlist，其中推荐使用的是 minlist 和 maxmix。并记录在 knownfoods 中
            if raw_recipe and MinimizeRecipe(food_name, raw_recipe) then
                diary_food_detail[food_name] = raw_recipe
                --[[raw_recipe 中有用的部分，其中推荐使用 minlist 和 maxmix：
                    {
                        {
                            ['name'] = 'flowersalad',
                            ['supported_cooker'] = {
                                ['portablecookpot'] = true,
                                ['cookpot'] = true,
                                ['archive_cookpot'] = true
                            }
    
                            ['minnames'] = {
                                ['cactus_flower'] = 1
                            },
                            ['maxnames'] = {},
                            ['mintags'] = {
                                ['veggie'] = 2
                            },
                            ['maxtags'] = {
                                ['egg'] = 0,
                                ['fruit'] = 0,
                                ['sweetener'] = 0,
                                ['inedible'] = 0,
                                ['meat'] = 0
                            },
    
                            ['minmix'] = {
                                [1] = {
                                    ['amt'] = 2,
                                    ['tag'] = 'veggie'
                                },
                                [2] = {
                                    ['name'] = 'cactus_flower',
                                    ['amt'] = 1
                                }
                            },
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
                            },
                            ['minlist'] = {
                                [1] = {
                                    ['tags'] = {
                                        ['veggie'] = 1.5
                                    },
                                    ['names'] = {
                                        ['cactus_flower'] = 1
                                    }
                                }
                            },
                        }
                    }
                ]]
            end
        end
    end

    for food_name, food_detail in pairs(diary_food_detail) do
        -- 增加 cooker 键，值为 string
        food_detail.cooker = food_detail.supported_cooker and (
            food_detail.supported_cooker["cookpot"]         and "cookpot"           or (
            food_detail.supported_cooker["portablecookpot"] and "portablecookpot"   or "archive_cookpot"
        )) or "cookpot"
        -- 增加 *_string 键，值为 string
        food_detail.recipe_string = GetRecipeString(food_name)
        -- print(food_name, food_detail.recipe_string)
        food_detail.type_string = GetTypeString(food_detail)
        food_detail.spoil_string = GetSpoilString(food_detail.perishtime)
        food_detail.method_string = GetMethodString(food_detail)
        food_detail.cooktime_string = GetCookingTimeString(food_detail.cooktime)
        food_detail.sideeffect_string = GetSideEffectString(food_detail)
        food_detail.name_string = STRINGS.NAMES[string.upper(food_name)] or subfmt(STRINGS.UI.COOKBOOK.UNKNOWN_FOOD_NAME, {food = food_name or "SDF"})
        food_detail.defaultsortkey = hash(food_name)
        -- 增加图标
        local img_name = food_detail.cookbook_tex or (food_name..".tex")
        local atlas = food_detail.cookbook_atlas or GetInventoryItemAtlas(img_name, true)
        if atlas ~= nil then
            food_detail.food_tex = img_name
            food_detail.food_atlas = atlas
        else
            food_detail.food_tex = "cookbook_missing.tex"
            food_detail.food_atlas = "images/quagmire_recipebook.xml"
        end
    end
    return diary_food_detail
end


return {GetFoodDetail=GetFoodDetail}
