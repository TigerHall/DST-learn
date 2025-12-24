local prefs = {}

local function OnLandedClient_new(self, ...)
    if self.OnLandedClient_legion ~= nil then
        self.OnLandedClient_legion(self, ...)
    end
    if self.floatparam_l ~= nil then
        self.inst.AnimState:SetFloatParams(self.floatparam_l, 1, self.bob_percent)
    end
end
local function SetFloatable(inst, float)
    MakeInventoryFloatable(inst, float[2], float[3], float[4])
    if float[1] ~= nil then
        local floater = inst.components.floater
        if floater.OnLandedClient_legion == nil then
            floater.OnLandedClient_legion = floater.OnLandedClient
            floater.OnLandedClient = OnLandedClient_new
        end
        floater.floatparam_l = float[1]
    end
end
local function MakeTest(data)
    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank(data.bank)
        inst.AnimState:SetBuild(data.build or data.bank)
        inst.AnimState:PlayAnimation(data.anim or "idle", data.isloop)
        inst.Transform:SetTwoFaced()
        SetFloatable(inst, data.float)

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "petals_rose"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/petals_rose.xml"

        return inst
    end, nil, nil))
end

--------------------------------------------------------------------------
--[[ xxx ]]
--------------------------------------------------------------------------

MakeTest({ name = "animtest_l1",
    bank = "simmeredmoonlight", build = nil, anim = "idle_item", isloop = nil,
    float = { -0.05, "small", 0.15, 1.3 },
    fn_common = function(inst)
    end
})
MakeTest({ name = "animtest_l2",
    bank = "simmeredmoonlight", build = nil, anim = "idle_pro_item", isloop = nil,
    float = { -0.05, "small", 0.15, 1.3 },
    fn_common = function(inst)
        inst.AnimState:OverrideSymbol("snow", "snow_legion", "emptysnow")
    end
})
MakeTest({ name = "animtest_l3",
    bank = "healingsalve_acid", build = nil, anim = nil, isloop = nil,
    float = { -0.05, "small", 0.05, 0.95 },
    fn_common = function(inst)
    end
})
MakeTest({ name = "animtest_l4",
    bank = "spices", build = nil, anim = nil, isloop = nil,
    float = { 0.07, "med", 0.25, 0.65 },
    fn_common = function(inst)
        inst.AnimState:OverrideSymbol("swap_spice", "spices", "spice_salt")
    end
})

--------------------
--------------------

return unpack(prefs)
