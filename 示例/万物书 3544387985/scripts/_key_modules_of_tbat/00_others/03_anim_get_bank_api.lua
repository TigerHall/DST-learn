--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    插入一条函数，方便后续继续调用。
    AnimState:GetBank 
]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local tempInst = CreateEntity()
-- tempInst.entity:AddTransform()
-- tempInst.entity:AddAnimState()


-- local theAnimState = getmetatable(tempInst.AnimState).__index  ------ 侵入userdata 修改函数

-- if type(theAnimState) == "table" and theAnimState.GetBank == nil then
    

--     local temp_banks = {}

--     local old_set_bank = theAnimState.SetBank
--     theAnimState.SetBank = function(self,bank)
--         old_set_bank(self,bank)
--         temp_banks[self] = bank
--     end

--     theAnimState.GetBank = function(self)
--         return temp_banks[self]
--     end

-- end

-- tempInst:Remove()

---------------------------
--[[

    以下代码为AI优化，使用弱引用表侵入方式，防止内存在 temp_banks无限增值，造成内存泄漏

]]--
---------------------------

tempInst.entity:AddTransform()
tempInst.entity:AddAnimState()
local theAnimState = getmetatable(tempInst.AnimState).__index
------ 侵入userdata 修改函数
if type(theAnimState) == "table" and theAnimState.GetBank == nil then
    -- 关键修改：使用弱引用表，键为弱引用
    local temp_banks = setmetatable({}, {__mode = "k"})
    local old_set_bank = theAnimState.SetBank
    theAnimState.SetBank = function(self, bank)
        old_set_bank(self, bank)
        temp_banks[self] = bank
    end
    theAnimState.GetBank = function(self)
        return temp_banks[self]
    end
    ------------------------------------------------------
    --- debug
        if TBAT.DEBUGGING then
            function TBAT:D_ANIM_GETBANK_NUM()
                local NUM = 0
                for k, v in pairs(temp_banks) do
                    NUM = NUM + 1
                end
                print("AnimState:GetBank() NUM:",NUM)
            end
        end
    ------------------------------------------------------
end
tempInst:Remove()