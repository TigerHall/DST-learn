---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    所有可擦除物品

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
    local item_list = {}
    local function refresh()
        local new_table = {}        
        for inst,v in pairs(item_list) do
            if inst:IsValid() and inst.components.erasablepaper and inst.components.inventoryitem and inst.Transform then
                new_table[inst] = v
            end
        end
        item_list = new_table
    end
    local SEARCH_RADIUS = TBAT.CONFIG.LITTLE_CRANE_SEARCH_RADIUS
    local SEARCH_RADIUS_SQ = SEARCH_RADIUS * SEARCH_RADIUS
    local function InSearchRadius(item,x,y,z)
        if SEARCH_RADIUS_SQ == 0 then
            return true
        end
        return item:GetDistanceSqToPoint(x,0,z) <= SEARCH_RADIUS_SQ
    end
    function TBAT.FNS:GetAllErasablePapers(x,y,z)
        refresh()
        local ret_list = {}
        for inst,v in pairs(item_list) do
            if InSearchRadius(inst,x,y,z) then
                table.insert(ret_list, inst)
            end
        end
        return ret_list
    end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
    AddComponentPostInit("erasablepaper", function(self)
        self.inst:AddTag("tbat_tag.erasablepaper")
        item_list[self.inst] = true
        self.inst:ListenForEvent("onremove",refresh)
    end)