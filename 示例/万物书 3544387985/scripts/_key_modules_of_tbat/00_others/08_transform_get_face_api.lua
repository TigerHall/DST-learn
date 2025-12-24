--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

   
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local tempInst = CreateEntity()
tempInst.entity:AddTransform()
tempInst.entity:AddAnimState()

local theTransform = getmetatable(tempInst.Transform).__index

if type(theTransform) == "table" and theTransform.__tbat_face_data == nil then
    -- 关键修改：创建弱引用表（键为弱引用）
    local face_data = setmetatable({}, { __mode = "k" })
    theTransform.__tbat_face_data = face_data  -- 通过对象持有弱引用表，防止表被GC回收
    
    theTransform.TBAT_GetFace = function(self)
        return face_data[self] or 0  -- 直接使用弱引用表
    end

    local api_data = {
        ["SetNoFaced"] = 0,
        ["SetTwoFaced"] = 2,
        ["SetFourFaced"] = 4,
        ["SetSixFaced"] = 6,
        ["SetEightFaced"] = 8,
    }
    for api_name, value in pairs(api_data) do
        local old_api = theTransform[api_name]
        theTransform[api_name] = function(self, ...)
            face_data[self] = value  -- 通过弱引用表存储数据
            return old_api(self, ...)
        end
    end
end

tempInst:Remove()