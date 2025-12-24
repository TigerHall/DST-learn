--创建一个传送的Action, 可以右键触发，优先级10，
local TRAVEL = GLOBAL.Action({}, 10, false, true)
TRAVEL.id = "TRAVEL"
TRAVEL.str = "传送"
TRAVEL.fn = function(act)
    local tar = act.target
	local traveller = act.doer
    if tar and tar.components.travelable and traveller then
		tar:DoTaskInTime(
			.2,
			function()
				tar.components.travelable:OnSelect(traveller)
			end
		)
		return true
	end
end


AddAction(TRAVEL)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(TRAVEL, "give"))


AddPrefabPostInit("homesign", function(inst)
    inst:AddComponent("travelable")
end)