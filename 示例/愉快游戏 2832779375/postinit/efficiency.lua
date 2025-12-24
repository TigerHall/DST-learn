

if GetModConfigData("magic_marble") then
    AddPrefabPostInit("marbleshrub", function(inst)
        inst:AddTag("tree")
        if not TheWorld.ismastersim then
            return inst
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("no_stump") then
    local _trees = {
        evergreen = 1,
        deciduoustree = 1,
        twiggytree = 1,
        evergreen_sparse = 1,
        marsh_tree = 1,
        mushtree_tall = 1,
        mushtree_medium = 1,
        mushtree_small = 1,
        mushtree_moon = 1,
        moon_tree = 2,
        palmconetree = 2,
    }

    for k, v in pairs(_trees) do
        AddPrefabPostInit(k, function(inst)
            if not TheWorld.ismastersim then
                return inst
            end

            if inst.components.workable then
                local _onfinish = inst.components.workable.onfinish
                inst.components.workable.onfinish = function(inst, worker)
                    if _onfinish then
                        _onfinish(inst, worker)
                    end
                    for i = 1, v do
                        inst.components.lootdropper:SpawnLootPrefab("log", inst:GetPosition())
                    end
                    inst:DoTaskInTime(0.1, inst.Remove)
                end
            end
        end)
    end
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("tree_stop") then
    local _trees = {"evergreen", "twiggytree", "evergreen_sparse", "deciduoustree", "moon_tree", "marbleshrub", "palmconetree", "oceantree"}
    AddClassPostConstruct("components/growable", function(self)
        local _DoGrowth = self.DoGrowth
        function self:DoGrowth()
            if table.contains(_trees, self.inst.prefab) and self:GetStage() == 3 then
                return
            end
            return _DoGrowth(self)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("auto_drop_rock_avocado_fruit") then
    AddClassPostConstruct("components/growable", function(self)
        local old_SetStage = self.SetStage
        function self:SetStage(stage)
            if self.inst.prefab == "rock_avocado_bush" and stage == 4 then
                self.inst.components.lootdropper:SpawnLootPrefab("rock_avocado_fruit", self.inst:GetPosition())
                self.inst.components.lootdropper:SpawnLootPrefab("rock_avocado_fruit", self.inst:GetPosition())
                self.inst.components.lootdropper:SpawnLootPrefab("rock_avocado_fruit", self.inst:GetPosition())

                if self.inst.components.pickable then
                    self.inst.components.pickable.makeemptyfn(self.inst)
                    self.inst.components.pickable:ConsumeCycles(1)
                    self.inst:DoTaskInTime(FRAMES, function(inst)
                        self.inst.components.pickable.onpickedfn(self.inst)
                    end)
                end
            else
                old_SetStage(self, stage)
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("reed_shoval") then
    AddPrefabPostInit("reeds", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if not inst.components.lootdropper then
            inst:AddComponent("lootdropper")
        end
        if not inst.components.workable then
            inst:AddComponent("workable")
			inst.components.workable:SetWorkAction(ACTIONS.DIG)
			inst.components.workable:SetWorkLeft(1)
			inst.components.workable:SetOnFinishCallback(function(inst, worker)
                if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
                    if inst.components.pickable:CanBePicked() then
                        inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product, inst:GetPosition())
                    end

                    inst.components.lootdropper:SpawnLootPrefab("dug_monkeytail", inst:GetPosition())
                end
                inst:Remove()
            end)
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("banana_shoval") then
    AddPrefabPostInit("cave_banana_tree", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if not inst.components.lootdropper then
            inst:AddComponent("lootdropper")
        end
        inst.components.workable:SetWorkAction(ACTIONS.DIG)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(function(inst, worker)
            if inst.components.pickable ~= nil and inst.components.lootdropper ~= nil then
                if inst.components.pickable:CanBePicked() then
                    inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product, inst:GetPosition())
                end

                inst.components.lootdropper:SpawnLootPrefab("dug_bananabush", inst:GetPosition())
            end
            inst:Remove()
        end)
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("quick_work") then
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PICK, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.HARVEST, "doshortaction"))
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.COOK, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.REPAIR, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.HEAL, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SHAVE, "doshortaction"))
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BUILD, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TAKEITEM, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.FEED, "doshortaction"))
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PET, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.DRAW, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SEW, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SMOTHER, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MANUALEXTINGUISH, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TEACH, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.UPGRADE, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MURDER, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.UNWRAP, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BRUSH, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ACTIVATE, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.FILL, "doshortaction"))
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("one_axe") then
    TUNING.EVERGREEN_CHOPS_SMALL = 1
	TUNING.EVERGREEN_CHOPS_NORMAL = 1
	TUNING.EVERGREEN_CHOPS_TALL = 1
	TUNING.DECIDUOUS_CHOPS_SMALL = 1
	TUNING.DECIDUOUS_CHOPS_NORMAL = 1
	TUNING.DECIDUOUS_CHOPS_TALL = 1
	TUNING.DECIDUOUS_CHOPS_MONSTER = 1
	TUNING.TOADSTOOL_MUSHROOMSPROUT_CHOPS = 1
	TUNING.TOADSTOOL_DARK_MUSHROOMSPROUT_CHOPS = 1
	TUNING.MUSHTREE_CHOPS_SMALL = 1
	TUNING.MUSHTREE_CHOPS_MEDIUM = 1
	TUNING.MUSHTREE_CHOPS_TALL = 1
    TUNING.MOON_TREE_CHOPS_SMALL = 1
    TUNING.MOON_TREE_CHOPS_NORMAL = 1
    TUNING.MOON_TREE_CHOPS_TALL = 1
	TUNING.WINTER_TREE_CHOP_SMALL = 1
	TUNING.WINTER_TREE_CHOP_NORMAL = 1
	TUNING.WINTER_TREE_CHOP_TALL = 1
    TUNING.PALMCONETREE_CHOPS_SMALL = 1
    TUNING.PALMCONETREE_CHOPS_NORMAL = 1
    TUNING.PALMCONETREE_CHOPS_TALL = 1
	local function one_chop(inst)
        if not TheWorld.ismastersim then
            return inst
        end
		if inst.components.workable then
			inst.components.workable:SetWorkLeft(1)
		end
	end
	AddPrefabPostInit("marsh_tree", one_chop)
	AddPrefabPostInit("cave_banana_tree", one_chop)
	AddPrefabPostInit("livingtree", one_chop)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("one_mine") then
	TUNING.ROCKS_MINE = 1
	TUNING.ROCKS_MINE_MED = 1
	TUNING.ROCKS_MINE_LOW = 1

    TUNING.ICE_MINE = 1
	TUNING.SCULPTURE_COVERED_WORK = 1

	TUNING.MARBLETREE_MINE = 1
	-- TUNING.MARBLEPILLAR_MINE = 1
	TUNING.MARBLESHRUB_MINE_SMALL = 1
	TUNING.MARBLESHRUB_MINE_NORMAL = 1
	TUNING.MARBLESHRUB_MINE_TALL = 1

	TUNING.PETRIFIED_TREE_SMALL = 1
	TUNING.PETRIFIED_TREE_NORMAL = 1
	TUNING.PETRIFIED_TREE_TALL = 1

	TUNING.SPILAGMITE_SPAWNER = 1
	TUNING.SPILAGMITE_ROCK = 1

    TUNING.GARGOYLE_MINE = 1
    TUNING.GARGOYLE_MINE_LOW = 1

	TUNING.CAVEIN_BOULDER_MINE = 1
	TUNING.LUNARRIFT_CRYSTAL_MINES = 1

    local function one_mine(inst)
        if not TheWorld.ismastersim then
            return inst
        end
		if inst.components.workable then
			inst.components.workable:SetWorkLeft(1)
		end
	end
    AddPrefabPostInit("ruins_statue_head", one_mine)
    AddPrefabPostInit("ruins_statue_head_nogem", one_mine)
    AddPrefabPostInit("ruins_statue_mage", one_mine)
    AddPrefabPostInit("ruins_statue_mage_nogem", one_mine)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("one_second_fishrod") then
    AddPrefabPostInit("fishingrod", function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if inst.components.fishingrod then
			inst.components.fishingrod:SetWaitTimes(0, 0)
		end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("more_containers") then
    local function more_containerfn(inst)
        if inst.SoundEmitter == nil then
            inst.entity:AddSoundEmitter()
        end

        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = function(inst) inst.replica.container:WidgetSetup("treasurechest") end
            return inst
        end

        if inst.components.container == nil then
            inst:AddComponent("container")
            inst.components.container:WidgetSetup("treasurechest")
            inst.components.container.onopenfn = function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open") end
            inst.components.container.onclosefn = function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close") end
            inst.components.container.skipclosesnd = true
            inst.components.container.skipopensnd = true
        end

        if inst.components.preserver == nil then
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(0)
        end

        if inst.components.fueled then
            local old_depleted = inst.components.fueled.depleted
            inst.components.fueled.depleted = function(inst)
                if inst.components.container then
                    inst.components.container:DropEverything()
                end
                if old_depleted~=nil then
                    old_depleted(inst)
                end
            end
        end
    end
    AddPrefabPostInit("minerhat", more_containerfn)
    AddPrefabPostInit("molehat", more_containerfn)
    AddPrefabPostInit("heatrock", more_containerfn)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("worldtime_faster") then
    local MOD_NAME = "SOME_MODIFICATIONS"
    AddModRPCHandler(MOD_NAME, "timescale", function(player, timeScale)
        local currentTimeScale = TheSim:GetTimeScale()
        currentTimeScale = currentTimeScale + timeScale
        if currentTimeScale <= 0 then
            currentTimeScale = 1
        end
        if currentTimeScale > 10 then
            currentTimeScale = 10
        end
        TheSim:SetTimeScale(currentTimeScale)
        TheNet:Announce("当前世界时间流速为: x" .. currentTimeScale)
    end)
    TheInput:AddKeyHandler(function(key, down)
        if down then
            if key == 91 then -- [
                SendModRPCToServer(MOD_RPC[MOD_NAME]["timescale"], -1)
            elseif key == 93 then -- ]
                SendModRPCToServer(MOD_RPC[MOD_NAME]["timescale"], 1)
            end
        end
    end)
end
--------------------------------------------------------------------------------------------------------------------
if GetModConfigData("stronger") then
    AddPrefabPostInitAny(function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        if inst:HasTag("heavy") and inst.components.equippable ~= nil then
            inst.components.equippable.walkspeedmult = nil
        end
    end)
end

--------------------------------------------------------------------------------------------------------------------


























