-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function talker_hook(inst)
        if inst.components.talker == nil then
            return
        end
        local old_Say = inst.components.talker.Say
        inst.components.talker.Say = function(self,str,...)
            inst:PushEvent("tbat_event.talker_say",str)
            return old_Say(self,str,...)
        end
    end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst:DoTaskInTime(1,talker_hook)
end)
