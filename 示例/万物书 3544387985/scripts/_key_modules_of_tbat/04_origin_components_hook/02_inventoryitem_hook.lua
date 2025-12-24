-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --[[

--     通过元表 hook 进指定的 loca API

-- ]]--
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --  
--    AddClassPostConstruct("components/inventoryitem", function(self)
--         local mt = getmetatable(self)
--         local original_newindex = mt.__newindex

--         mt.__newindex = function(t, k, v)
--             if k == "owner" then
--                 if t.inst.replica.inventoryitem then
--                     original_newindex(t, k, v)
--                 else
--                     print("TBAT error : self.inst.replica.inventoryitem == nil",self.inst)
--                 end
--             else
--                 original_newindex(t, k, v)
--             end
--         end
--     end)