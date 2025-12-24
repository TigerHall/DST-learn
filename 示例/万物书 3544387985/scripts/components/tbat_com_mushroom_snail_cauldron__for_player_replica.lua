----------------------------------------------------------------------------------------------------------------------------------
--[[



]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_mushroom_snail_cauldron__for_player = Class(function(self, inst)
    self.inst = inst
    TBAT:ReplicaTagRemove(inst,"tbat_com_mushroom_snail_cauldron__for_player")
    self.unlocked_data = {}
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("tbat_com_mushroom_snail_cauldron__for_player",function(inst,zipped_str)
            local str = TBAT.FNS:UnzipJsonStr(zipped_str)
            local flag,data = pcall(json.decode, str)
            if flag then
                self.unlocked_data = data
            end
        end)
    end
    
end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
--
    function tbat_com_mushroom_snail_cauldron__for_player:HasRecipe(product)
        if TheWorld.ismastersim then
            return self.inst.components.tbat_com_mushroom_snail_cauldron__for_player:HasRecipe(product)
        else
            return self.unlocked_data[product] == true
        end
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_mushroom_snail_cauldron__for_player







