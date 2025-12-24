------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    用来往 棱镜-子圭育 里放入数据


]]--
------------------------------------------------------------------------------------------------------------------------------------------------
---
    function TBAT.FNS:IsLeginWorking()
        if _G.rawget(_G, "TRANS_DATA_LEGION") == nil then
            return false
        end
        return true
    end
------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function hooker_fn()
        -----------------------------------------------------------
        --- 检查棱镜有没有开启
            if not TBAT.FNS:IsLeginWorking() then            
                return
            end
        -----------------------------------------------------------
        TRANS_DATA_LEGION["tbat_eq_fantasy_apple_oversized"] ={
            swap = { build = "tbat_farm_plant_fantasy_apple", file = "swap_body", symboltype = "3" },
            fruit = "tbat_plant_mutated_fantasy_apple_seed",
            fruitnum_min = 1, fruitnum_max = 1,
        }
        TRANS_DATA_LEGION["tbat_eq_fantasy_apple_mutated_oversized"] ={
            swap = { build = "tbat_farm_plant_fantasy_apple_mutated", file = "swap_body", symboltype = "3" },
            fruit = "tbat_plant_mutated_fantasy_apple_seed",
            fruitnum_min = 2, fruitnum_max = 2,
        }

        TRANS_DATA_LEGION["tbat_eq_fantasy_peach_oversized"] ={
            swap = { build = "tbat_farm_plant_fantasy_peach", file = "swap_body", symboltype = "3" },
            fruit = "tbat_plant_mutated_fantasy_peach_seed",
            fruitnum_min = 1, fruitnum_max = 1,
        }
        TRANS_DATA_LEGION["tbat_eq_fantasy_peach_mutated_oversized"] ={
            swap = { build = "tbat_farm_plant_fantasy_peach_mutated", file = "swap_body", symboltype = "3" },
            fruit = "tbat_plant_mutated_fantasy_peach_seed",
            fruitnum_min = 2, fruitnum_max = 2,
        }

        TRANS_DATA_LEGION["tbat_eq_fantasy_potato_oversized"] ={
            swap = { build = "tbat_farm_plant_fantasy_potato", file = "swap_body", symboltype = "3" },
            fruit = "tbat_plant_mutated_fantasy_potato_seed",
            fruitnum_min = 1, fruitnum_max = 1,
        }
        TRANS_DATA_LEGION["tbat_eq_fantasy_potato_mutated_oversized"] ={
            swap = { build = "tbat_farm_plant_fantasy_potato_mutated", file = "swap_body", symboltype = "3" },
            fruit = "tbat_plant_mutated_fantasy_potato_seed",
            fruitnum_min = 2, fruitnum_max = 2,
        }
    end
------------------------------------------------------------------------------------------------------------------------------------------------
---
    AddPrefabPostInit("world",hooker_fn)
------------------------------------------------------------------------------------------------------------------------------------------------
