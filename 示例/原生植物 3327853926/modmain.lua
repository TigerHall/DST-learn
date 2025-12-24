PrefabFiles = {
}
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local LAN_ = GetModConfigData('Language')

TUNING.NPMANTYPE = GetModConfigData('Manuretype')

local function refertilize(self)
	local oldfertilize = self.Fertilize
	self.Fertilize = function(self,fertilizer,doer)
		print(fertilizer.prefab)
		if TUNING.NPMANTYPE == false 
		or fertilizer.prefab == "compostwrap" 
		then
			self.transplanted = false
		end
		oldfertilize(self,fertilizer,doer)
		return true
	end
end

AddComponentPostInit("pickable", refertilize)