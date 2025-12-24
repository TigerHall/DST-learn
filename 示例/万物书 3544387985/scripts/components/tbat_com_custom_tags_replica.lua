----------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
----------------------------------------------------------------------------------------------------------------------------------
---
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_custom_tags = Class(function(self, inst)
    self.inst = inst
    -- TBAT:ReplicaTagRemove(inst,"tbat_com_custom_tags") -- 不能移除替换的tag组件
    self.classified = nil
    self.tags = {}
end)
------------------------------------------------------------------------------------------------------------------------------
--- classified API
    local function classified_inst_init_fn(classified)
        if classified.__custom_tags_json_str == nil then
            classified.__custom_tags_json_str = net_string(classified.GUID,"custom_tags_json_str","custom_tags_json_str_update")
        end
        classified.__custom_tags_json_str:set(json.encode({}))
        function classified:SetCustomTagsJsonStr(json_str)
            if TheWorld.ismastersim then
                self.__custom_tags_json_str:set(json_str)
            end
        end
        function classified:GetCustomTagsJsonStr()
            return self.__custom_tags_json_str:value()
        end
    end
    function tbat_com_custom_tags:GetClassifiedInitFn()
        return classified_inst_init_fn
    end
    function tbat_com_custom_tags:AttachClassified(classified)
        self.classified = classified
        self.inst:ListenForEvent("custom_tags_json_str_update",function()
            local json_str = self:GetCustomTagsJsonStr()
            local succeed_flag,data = pcall(json.decode,json_str)
            if succeed_flag then
                local tags_str = data.tags_str or json.encode({})
                local _s,tags = pcall(json.decode,tags_str)
                if _s then
                    self.tags = tags
                end
            end
            self.inst:PushEvent("refreshcrafting")
        end,classified)
    end
------------------------------------------------------------------------------------------------------------------------------
--- 
    function tbat_com_custom_tags:Set_All_Tags_Data_Str(data_str)
        if self.classified then
            self.classified:SetCustomTagsJsonStr(data_str)
        end
    end
    function tbat_com_custom_tags:GetCustomTagsJsonStr()
        if self.classified then
            return self.classified:GetCustomTagsJsonStr()
        end
        return json.encode({})
    end
------------------------------------------------------------------------------------------------------------------------------
--- 
    function tbat_com_custom_tags:HasTag(tag)
        return self.tags[tag] or false
    end
------------------------------------------------------------------------------------------------------------------------------
--- 
    function tbat_com_custom_tags:OnPostInit()
        -- print("fake error tbat_com_custom_tags replica OnPostInit")
        -- print("fake error tbat_com_custom_tags replica OnPostInit")
        -- print("fake error tbat_com_custom_tags replica OnPostInit")
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_custom_tags







