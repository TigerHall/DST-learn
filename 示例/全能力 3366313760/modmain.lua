GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

--[[
全局变量：
AAB_L(en, zh)
AAB_AddFx(data)
AAB_AddCharacterRecipe(name, ingredients, data, filters)
AAB_ReplaceCharacterLines(character)
AAB_AddComponentAction(actiontype, component, fn)
AAB_ActivateSkills(character)
AAB_AddSpecialAction(getactionfn)



]]



PrefabFiles = {}

----------------------------------------------------------------------------------------------------

Assets = {}

----------------------------------------------------------------------------------------------------

local Constructor = require("aab_utils/constructor")
Constructor.SetEnv(env)


----------------------------------------------------------------------------------------------------

local language
if GetModConfigData("language") ~= "AUTO" then
    language = GetModConfigData("language")
else
    local lan = require "languages/loc".GetLanguage()
    language = (lan == LANGUAGE.CHINESE_S or lan == LANGUAGE.CHINESE_S_RAIL) and "zh" or "en"
end

function AAB_L(en, zh)
    return language == "en" and en or zh
end

GLOBAL.AAB_L = AAB_L

local function Trace(character, root, tab, path)
    for k, v in pairs(tab) do
        if type(v) == "table" then
            table.insert(path, k)
            Trace(character, root, v, path)
            table.remove(path, #path)
        else
            for k2, v2 in pairs(root) do
                if k2 ~= path[1] then
                    local data = v2
                    for i = 2, #path do
                        data = data[path[i]]
                        if not data then break end
                    end
                    if type(data) == "table" then
                        -- if data[k] == "only_used_by_" .. string.lower(character) then
                        if type(data[k]) == "string" and string.match(data[k], "only_used_by_" .. string.lower(character)) then
                            data[k] = v
                        end
                    end
                end
            end
        end
    end
end

local function DFS(character, tab)
    for k, v in pairs(tab) do
        if type(v) == "table" then
            if v[character] and type(v[character]) == "table" then
                --新的递归
                Trace(character, v, v[character], { character })
            else
                DFS(character, v)
            end
        end
    end
end

function AAB_ReplaceCharacterLines(character)
    DFS(string.upper(character), STRINGS)
end

----------------------------------------------------------------------------------------------------

local FX_DATA = {
    -- {
    -- 	name = "mami_gun_flash_fx",
    -- 	anim = "anim",
    -- 	fn = function(inst, proxy) end,
    -- 	eightfaced = true,
    -- 	sound = "mami_sfx/gun/oneshot",
    -- 	soundvolumn = 0.15,
    -- },
}
function AAB_AddFx(data)
    table.insert(FX_DATA, data)
end

----------------------------------------------------------------------------------------------------

--- 统一添加
local AAB_COMPONENT_ACTIONS = {
    SCENE = {},
    USEITEM = {},
    POINT = {},
    EQUIPPED = {},
    INVENTORY = {}
}

function AAB_AddComponentAction(actiontype, component, fn)
    AAB_COMPONENT_ACTIONS[actiontype][component] = AAB_COMPONENT_ACTIONS[actiontype][component] or {}
    table.insert(AAB_COMPONENT_ACTIONS[actiontype][component], fn)
end

----------------------------------------------------------------------------------------------------
Ig = Ingredient

function AAB_AddCharacterRecipe(name, ingredients, data, filters)
    data = data or {}
    return AddRecipe2(name,
        ingredients,
        TECH.NONE,
        data,
        filters or { "CHARACTER" }
    )
end

----------------------------------------------------------------------------------------------------
local Utils = require("aab_utils/utils")
function AAB_ActivateSkills(character)
    local SKILLTREE_DEFS

    local function IsActivatedBefore(self, skill)
        return { true }, self.inst.prefab ~= character and skill and SKILLTREE_DEFS[skill]
    end

    AddComponentPostInit("skilltreeupdater", function(self)
        SKILLTREE_DEFS = require("prefabs/skilltree_defs").SKILLTREE_DEFS[character]
        Utils.FnDecorator(self, "IsActivated", IsActivatedBefore)
    end)

    local function Init(inst)
        --偷个懒，这里直接解锁所有技能，也没管解锁先后顺序和技能冲突，如果之后又什么问题就再把冲突的技能排除掉
        for _, data in pairs(SKILLTREE_DEFS) do
            if data.onactivate then
                data.onactivate(inst)
            end
        end
    end

    AddPlayerPostInit(function(inst)
        if inst.prefab == character then return end
        if not TheWorld.ismastersim then return end
        inst:DoTaskInTime(0, Init)
    end)
end

----------------------------------------------------------------------------------------------------

local function OrderByPriority(l, r)
    return (l.action and l.action.priority or 0) > (r.action and r.action.priority or 0)
end

---追加鼠标行为，不方便hook pointspecialactionsfn，伍迪、大力士这种角色会把这个变量清空
---@param getactionfn function (inst, target, pos, useitem, right, bufs)
function AAB_AddClickAction(getactionfn)
    local function NoEquipActivator(bufs, self, pos, target, right)
        --当玩家装备aoetargeting可施法武器的时候，会导致不管是施法还是这个动作都无法执行，我希望最少有一个能执行
        local item = self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if not (item and item.components.aoetargeting and item.components.aoetargeting:IsEnabled()) then
            local useitem = self.inst.replica.inventory and self.inst.replica.inventory:GetActiveItem()
            local act, pos2 = getactionfn(self.inst, target, pos, useitem, right, bufs)
            if act then
                local actions = { act }
                for _, buf in ipairs(self:SortActionList(actions, pos2 or pos)) do
                    table.insert(bufs, buf)
                end
                table.sort(bufs, OrderByPriority) --顺便和原来的一起排个序
            end
        end
    end

    AddComponentPostInit("playeractionpicker", function(self)
        local OldGetLeftClickActions = self.GetLeftClickActions
        self.GetLeftClickActions = function(self, position, target, ...)
            local bufs = OldGetLeftClickActions(self, position, target, ...)
            NoEquipActivator(bufs, self, position, target, false)
            return bufs
        end

        local OldGetRightClickActions = self.GetRightClickActions
        self.GetRightClickActions = function(self, position, target, ...)
            local bufs = OldGetRightClickActions(self, position, target, ...)
            NoEquipActivator(bufs, self, position, target, true)
            return bufs
        end
    end)
end

--- 特效动作
---@param getactionfn function (inst, pos, useitem, right, bufs, usereticulepos)
function AAB_AddSpecialAction(getactionfn)
    AddComponentPostInit("playeractionpicker", function(self)
        local OldGetPointSpecialActions = self.GetPointSpecialActions
        self.GetPointSpecialActions = function(self, pos, useitem, right, usereticulepos, ...)
            local bufs = OldGetPointSpecialActions(self, pos, useitem, right, usereticulepos, ...)
            local actions, pos2 = getactionfn(self.inst, pos, useitem, right, bufs, usereticulepos, ...)
            for _, buf in ipairs(self:SortActionList(actions, usereticulepos and pos2 or pos, useitem)) do
                table.insert(bufs, buf)
            end
            return bufs
        end
    end)
end

----------------------------------------------------------------------------------------------------
modimport "modmain/abilities"
modimport "modmain/debug" -- TODO

----------------------------------------------------------------------------------------------------

local fx = require("fx")
for _, v in ipairs(FX_DATA) do
    v.bank = v.bank or v.name
    v.build = v.build or v.name
    v.anim = v.anim or "idle"

    table.insert(Assets, Asset("ANIM", "anim/" .. v.build .. ".zip"))
    table.insert(fx, v)
end

for actiontype, components in pairs(AAB_COMPONENT_ACTIONS) do
    for component, fns in pairs(components) do
        AddComponentAction(actiontype, component, function(...)
            for _, fn in ipairs(fns) do fn(...) end
        end)
    end
end

local containers = require("containers")
local params = containers.params
for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

----------------------------------------------------------------------------------------------------
