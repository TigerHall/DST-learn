local QUICK_BUILD = GetModConfigData("quick_build")
local Utils = require("aab_utils/utils")

-- TODO 比如把物品数据从主机传给客机才行

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst._aab_quick_build_chests = {}
end)

AddModRPCHandler(modname, "QuickBuildCheckChest", function(inst, str)
    for _, v in ipairs(inst._aab_quick_build_chests) do
        if v:IsValid() and v.AnimState then
            v.AnimState:SetAddColour(0, 0, 0, 0)
        end
    end

    if not str then return end

    local x, y, z = inst.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, y, z, QUICK_BUILD)) do
        local container = v.components.container
            or v.components.container_proxy and v.components.container_proxy:GetMaster()
        if container and v.AnimState then
            if container.GetAllItems then
                for _, item in ipairs(container:GetAllItems()) do
                    if str == STRINGS.NAMES[string.upper(item.prefab)] then
                        v.AnimState:SetAddColour(0.3, 0.3, 0, 0)
                        table.insert(inst._aab_quick_build_chests, v)
                        break
                    end
                end
            else
                print("[AllAbility] container没有GetAllItems", v) --有可能GetAllItems不存在，还不知道为什么
            end
        end
    end
end)

local update_interval = 0.5 --更新间隔
local last_update_time = 0
local last_hover_str = nil

local function ClientUpdate(str)
    if last_hover_str == str and GetTime() - last_update_time < update_interval then return end
    last_update_time = GetTime()
    last_hover_str = str
    SendModRPCToServer(MOD_RPC[modname]["QuickBuildCheckChest"], str)
end
AddClassPostConstruct("widgets/hoverer", function(self)
    Utils.FnDecorator(self.text, "SetString", function(text, str)
        local target = TheInput:GetHUDEntityUnderMouse()
        local item = (target and target.widget and target.widget.parent and target.widget.parent.item)
            or TheInput:GetWorldEntityUnderMouse()
        if item and item.prefab then
            str = STRINGS.NAMES[string.upper(item.prefab)]
        elseif target and Utils.ChainGetVal(target, "widget", "parent", "parent", "parent", "parent", "name") == "CraftingMenuIngredients" then
            -- 是制作栏配方
        else
            str = nil
        end

        ClientUpdate(str)
    end)
    Utils.FnDecorator(self.text, "Hide", function()
        ClientUpdate(nil)
    end)
end)


AddClassPostConstruct("widgets/hoverer", function(self)
    local OldSetString = self.text.SetString
    self.text.SetString = function(text, str)
        local target = TheInput:GetHUDEntityUnderMouse()
        target = (target and target.widget and target.widget.parent and target.widget.parent.item)
            or TheInput:GetWorldEntityUnderMouse()
        if not target or not target.replica or not target.components then return OldSetString(text, str) end --好像target有可能不是预制件

        -- 修改str

        return OldSetString(text, str)
    end
end)
