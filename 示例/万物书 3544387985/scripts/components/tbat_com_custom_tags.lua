----------------------------------------------------------------------------------------------------------------------------------
--[[

    客制化的 tag 信道。

]]--
----------------------------------------------------------------------------------------------------------------------------------
--- 
    local function GetReplica(self)
        return self.inst.replica.tbat_com_custom_tags or self.inst.replica._.tbat_com_custom_tags
    end
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_custom_tags = Class(function(self, inst)
    self.inst = inst

    self._flag = 0
    self._tags = {}

    -- self.inst:DoPeriodicTask(2,function()
    --     self:Sync()
    -- end)
    self.__sync_tasks = {}

end,
nil,
{

})
------------------------------------------------------------------------------------------------------------------------------
-- 同步
    function tbat_com_custom_tags:_Sync()
        local replica_com = GetReplica(self)
        if replica_com then
            self._flag = math.random(0,100000)
            local data = {
                _flag = self._flag,
                tags_str = json.encode(self._tags),
            }
            local str = json.encode(data)
            replica_com:Set_All_Tags_Data_Str(str)
        end
    end
    function tbat_com_custom_tags:Sync()
        for k, task in pairs(self.__sync_tasks) do
            task:Cancel()
        end
        self.__sync_tasks = {}
        for i = 1, 60, 1 do
            local temp_task = self.inst:DoTaskInTime(i-1, function()
                self:_Sync()
                if i == 60 then
                    self.__sync_tasks = {}
                end
            end)
            table.insert(self.__sync_tasks, temp_task)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
-- AddTag / RemoveTag
    function tbat_com_custom_tags:AddTag(tag)
        self._tags[tag] = true
        self:Sync()
    end
    function tbat_com_custom_tags:RemoveTag(tag)
        local new_table = {}
        for k,v in pairs(self._tags) do
            if k ~= tag then
                new_table[k] = v
            end
        end
        self._tags = new_table
        self:Sync()
    end
    function tbat_com_custom_tags:HasTag(tag)
        return self._tags[tag] or false
    end
------------------------------------------------------------------------------------------------------------------------------
--- OnPostInit    
    function tbat_com_custom_tags:OnPostInit()
        -- self:HookAPI()
        -- print("fake error tbat_com_custom_tags")
        -- print("fake error tbat_com_custom_tags")
        -- print("fake error tbat_com_custom_tags")
        -- print("fake error tbat_com_custom_tags")
        -- print("fake error tbat_com_custom_tags")
        -- print("fake error tbat_com_custom_tags")
        -- print("fake error tbat_com_custom_tags")
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_custom_tags







