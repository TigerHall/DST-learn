--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    插入一条函数，方便后续继续调用。
    AnimState:GetScale 
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local tempInst = CreateEntity()
tempInst.entity:AddTransform()
tempInst.entity:AddAnimState()

local theAnimState = getmetatable(tempInst.AnimState).__index

if type(theAnimState) == "table" and theAnimState.GetScale == nil then
    -- 关键修改：使用弱引用表（键为弱引用）存储scale数据
    local temp_scale_data = setmetatable({}, { __mode = "k" })
    
    local old_SetScale = theAnimState.SetScale
    theAnimState.SetScale = function(self, x, y, z, ...)
        old_SetScale(self, x, y, z, ...)
        temp_scale_data[self] = {x, y, z, ...}
    end
    
    theAnimState.GetScale = function(self)
        local data = temp_scale_data[self]
        if data then
            return unpack(data)
        else
            return 1, 1, 1
        end
    end
    
    -- 保存弱引用表到AnimState对象（避免被GC回收）
    theAnimState.temp_scale_data = temp_scale_data
end

tempInst:Remove()