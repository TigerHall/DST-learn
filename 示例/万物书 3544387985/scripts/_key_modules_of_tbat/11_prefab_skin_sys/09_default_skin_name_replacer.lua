--------------------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
--------------------------------------------------------------------------------------------------------------------------------------------
--
    local default_data = {}
    function TBAT.SKIN:SetDefaultSkinName(skins_data,this_prefab,display_name)
        for skin_name, v in pairs(skins_data) do
            default_data[skin_name] = display_name
        end
    end
    function TBAT.SKIN:GetDefaultSkinName(skin_index)
        return default_data[skin_index]
    end
--------------------------------------------------------------------------------------------------------------------------------------------
--
    local function has_replaced_default_name(skins_list)
        for k, data in pairs(skins_list) do
            local ret = TBAT.SKIN:GetDefaultSkinName(data.item)
            if ret ~= nil then
                return ret
            end
        end
        return nil
    end
    local function is_this_mod_item_and_has_skin(self)
        return true
        -- local all_data = self:GetSkinsList() or {}
        -- for k, data in pairs(all_data) do
        --     if data and data.item and (TBAT.SKIN.SKINS_DATA_SKINS[data.item] or TBAT.SKIN.SKINS_DATA_PREFABS[data.item]) then
        --         return true
        --     end
        -- end
        -- return false
    end
    local function start_replace(self)
        -- print("+++++++++666++++",self.spinner:GetSelectedIndex())
        ------------------------------------------------------------------------------
        --- 如果是本MOD的皮肤,修改字体
            if is_this_mod_item_and_has_skin(self) and self.spinner and self.spinner.text and self.spinner.text.font == UIFONT then
                self.spinner.text:SetFont(CODEFONT)
            end
        ------------------------------------------------------------------------------
        local replaced_name = has_replaced_default_name(self.skins_list) 
        if replaced_name == nil 
            or self.skins_options == nil or #self.skins_options<2 
            or self.spinner == nil or self.spinner.SetSelectedIndex == nil
            then
                return
        end
        local data = self.skins_options and self.skins_options[1] or {}
        data.text = replaced_name
        if self.spinner:GetSelectedIndex() == 1 then
            self.spinner:SetSelectedIndex(2)    --- 刷一下才能正常在第一次显示
            self.spinner:SetSelectedIndex(1)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------
---
    local function hook_fn(self)
        start_replace(self)
        -- self.inst:DoTaskInTime(0,function()
        --     start_replace(self)
        -- end)
    end
    AddClassPostConstruct("widgets/recipepopup",hook_fn)  --- 可能不起作用
    AddClassPostConstruct("widgets/redux/craftingmenu_skinselector",hook_fn)
--------------------------------------------------------------------------------------------------------------------------------------------