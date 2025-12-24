---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    试图加速全局物品的搜索。

]]--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  
    local item_lists = {}
    local function Add_To_List(item)
        if item and item:IsValid() then
            item_lists[item] = true
        end
    end
    local function GetListWithCallBack(CallBack_table,fn)
        local new_table = {}        
        for item, v in pairs(item_lists) do
            if item:IsValid() and item.components.inventoryitem then
                new_table[item] = true
                if fn == nil or fn(item) then
                    table.insert(CallBack_table,item)
                end
            else

            end
        end
        item_lists = new_table
    end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  
    AddClassPostConstruct("components/inventoryitem", function(self)
        Add_To_List(self.inst)
    end)

    AddPrefabPostInit("world",function(inst)   
        if not TheWorld.ismastersim then
            return
        end
        inst:ListenForEvent("tbat_event.get_all_items",function(inst,cmd)
            if type(cmd) == "table" and type(cmd.callback) == "table" then
                GetListWithCallBack(cmd.callback,cmd.fn)
            end
        end)
    end)