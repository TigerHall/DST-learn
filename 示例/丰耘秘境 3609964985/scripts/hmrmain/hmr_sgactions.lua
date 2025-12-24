local MOD_NAME = "HMR"

----------------------------------------------------------------------------
---[[actions]]
----------------------------------------------------------------------------
local MOD_ACTIONS = {
    pick = {
        id = "PICK",
        fn = function(act)
            if act.target ~= nil then
                if act.target.components.hpick ~= nil then
                    act.target.components.hpick:Pick(act.doer)
                    return true
                elseif act.target.components.searchable ~= nil then
                    return act.target.components.searchable:Search(act.doer)
                end
            end
        end,
        queue = {
            category = "leftclick",
        }
    },

    repair = {
        id = "REPAIR",
        fn = function(act)
            local target = act.target
            if target ~= nil then
                return act.invobject.components.hmrrepairer:Repair(target, act.doer)
            end
        end,
        queue = {
            category = "allclick",
        }
    },

    cure = {
        id = "CURE",
        fn = function(act)
            if act.target ~= nil and act.target:IsValid() and
                    act.target.components.hcurable ~= nil and
                    (act.target.components.health ~= nil and not act.target.components.health:IsDead() or act.target.components.health == nil) then
                act.target.components.hcurable:DoProjCure(act.doer, act.target)
            end
        end,
        priority = 3,
        canforce = true,
        mount_valid = true,
        invalid_hold_action = true,
        distance = 30,
    },

    givestatue = {
        id = "GIVESTATUE",
        fn = function(act)
            if act.target ~= nil and act.target:IsValid() and not act.target:HasTag("burnt") then
                local item = act.doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
                return act.target.components.hmrstatuedisplayer:GiveStatue(item)
            end
        end,
        priority = 3,
        encumbered_valid=true, -- encumbered_valid能在背负重物时进行动作
    },

    pickstatue = {
        id = "PICKSTATUE",
        fn = function(act)
            if act.target ~= nil and act.target:IsValid() and not act.target:HasTag("burnt") then
                return act.target.components.hmrstatuedisplayer:PickStatue(act.doer)
            end
        end,
    },

    terraform = {
        id = "TERRAFORM",
        fn = function(act)
            if act.invobject ~= nil and act.invobject.components.terraformer ~= nil then
                return act.invobject.components.terraformer:Terraform(act:GetActionPoint(), act.doer)
            end
        end,
        priority = 3,
    },

    transplant = {
        id = "TRANSPLANT",
        fn = function(act)
            if act.target ~= nil and act.invobject ~= nil then
                return act.invobject.components.hmrtransplanter:TransPlant(act.target, act.doer)
            end
        end,
        queue = {
            category = "leftclick",
            init_fn = function(self)
                local POT_PREFABS = {
                    hmr_cherry_flowerpot_item = true,
                }
                local oldGetNewActiveItem = self.GetNewActiveItem
                function self:GetNewActiveItem(prefab)
                    if POT_PREFABS[prefab] then
                        local inventory = self.inst.replica.inventory
                        local body_item = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
                        local backpack = body_item and body_item.replica.container
                        for _, inv in pairs(backpack and {inventory, backpack} or {inventory}) do
                            for slot, item in pairs(inv:GetItems()) do
                                if item and item.prefab == prefab and not item:HasTag("occupied") then
                                    inv:TakeActiveItemFromAllOfSlot(slot)
                                    return item
                                end
                            end
                        end
                    else
                        return oldGetNewActiveItem(self, prefab)
                    end
                end
            end,
        }
    },

    collectgoods = {
        id = "COLLECTGOODS",
        fn = function(act)
            if act.target ~= nil and act.target:IsValid() and act.target.components.hmrfactory ~= nil then
                return act.target.components.hmrfactory:CollectAllTempStorage(act.doer)
            end
        end,
        priority = 3,
        queue = {
            category = "leftclick",
        },
    },
}

local function AddModAction(id, data)
    local action = Action()

    for k, v in pairs(data) do
        action[k] = v
    end

    action.id = id
    action.str = data.str or STRINGS.ACTIONS[id]

    AddAction(action)

    -- 添加行为学队列
    if data.queue ~= nil then
        local success, _ = pcall(require, "components/actionqueuer")
        if AddActionQueuerAction ~= nil then
            AddActionQueuerAction(data.queue.category or "allclick", id, data.queue.testfn or true)
        end

        if data.queue.init_fn ~= nil then
            AddComponentPostInit("actionqueuer", data.queue.init_fn)
        end
    end
end

for action, data in pairs(MOD_ACTIONS) do
    local id = string.upper(MOD_NAME.."_"..data.id)
    AddModAction(id, data)
end

----------------------------------------------------------------------------
---[[componentactions]]
----------------------------------------------------------------------------
-- SCENE		using an object in the world
-- USEITEM		using an inventory item on an object in the world
-- POINT		using an inventory item on a point in the world
-- EQUIPPED		using an equiped item on yourself or a target object in the world
-- INVENTORY	using an inventory item
local MOD_COMPONENT_ACTIONS = {
    SCENE = --args: inst, doer, actions, right
    {
        hpick = function(inst, doer, actions)
            if inst:HasTag("pickable") and not (inst:HasTag("fire") or inst:HasTag("intense")) then
                table.insert(actions, ACTIONS.HMR_PICK)
            end
        end,

        hcurable = function(inst, doer, actions, right)
            local item = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if item ~= nil and item:HasTag("honor_blowdart_cure") and inst ~= doer then
                if inst:HasTag("player") and inst:IsValid() then
                    table.insert(actions, ACTIONS.HMR_CURE)
                end
            end
        end,

        hmrstatuedisplayer = function(inst, doer, actions, right)
            local item = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)

            if item ~= nil and (item:HasTag("oversized_veggie") or item:HasTag("heavy")) and not inst:HasTag("displayer_occupied") then
                table.insert(actions, ACTIONS.HMR_GIVESTATUE)
            end

            if (item == nil or not item:HasTag("oversized_veggie") or not item:HasTag("heavy")) and inst:HasTag("displayer_occupied") then
                table.insert(actions, ACTIONS.HMR_PICKSTATUE)
            end
        end,

        hmrfactory = function(inst, doer, actions, right)
            if not right and inst and inst:IsValid() and inst.replica.hmrfactory ~= nil and inst.replica.hmrfactory:HasTempStorage() then
                table.insert(actions, ACTIONS.HMR_COLLECTGOODS)
            end
        end,
    },

    USEITEM = --args: inst, doer, target, actions, right
    {
        hmrrepairer = function(inst, doer, target, actions, right)
            if right and target ~= nil and target:IsValid() and target.replica.hmrrepairable ~= nil then
                table.insert(actions, ACTIONS.HMR_REPAIR)
            end
        end,

        hmrtransplanter = function(inst, doer, target, actions, right)
            if inst.replica.hmrtransplanter ~= nil and inst.replica.hmrtransplanter:CanTransplant(target) then
                table.insert(actions, ACTIONS.HMR_TRANSPLANT)
            end
        end
    },

    POINT = --args: inst, doer, pos, actions, right, target
    {
        terraformer = function(inst, doer, pos, actions, right, target)
            if right then
                local x, y, z = pos:Get()
                local carpets = TheSim:FindEntities(x, y, z, 6, {"hmr_carpet"})
                for _, carpet in pairs(carpets) do
                    if carpet:GetDistanceSqToPoint(x, y, z) < carpet.radius * carpet.radius then
                        table.insert(actions, ACTIONS.HMR_TERRAFORM)
                        break
                    end
                end
            end
        end
    },
}

for k, v in orderedPairs(MOD_COMPONENT_ACTIONS) do
    for component, fn in pairs(v) do
        AddComponentAction(k, component, fn)
    end
end

----------------------------------------------------------------------------
---[[sgactions]]
----------------------------------------------------------------------------
local MOD_ACTION_HANDLERS = {
    pick = "doshortaction",

    repair = "dolongaction",

    cure = "blowdart",

    givestatue = "dolongaction",

    pickstatue = "dolongaction",

    terraform = "terraform",

    transplant = "dolongaction",

    collectgoods = "dolongaction",
}

local function AddModStategraphActionHandler(action, data)
    AddStategraphActionHandler("wilson", ActionHandler(action, data.fn))
    if data.clientfn ~= nil then
        AddStategraphActionHandler("wilson_client", ActionHandler(action, data.clientfn))
    end
end

for action_name, stategraph in pairs(MOD_ACTION_HANDLERS) do
    local id = string.upper(MOD_NAME.."_"..action_name)
    local action = ACTIONS[id]

    if action ~= nil then
        local data = {}
        if type(stategraph) == "string" then
            data.fn = stategraph
            data.clientfn = stategraph
        elseif type(stategraph) == "function" then
            data.fn = stategraph
            data.clientfn = stategraph
        elseif type(stategraph) == "table" then
            data.fn = stategraph.server
            data.clientfn = stategraph.client
        end

        AddModStategraphActionHandler(action, data)
    end
end