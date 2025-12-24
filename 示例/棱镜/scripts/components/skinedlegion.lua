local SkinedLegion = Class(function(self, inst)
	self.inst = inst
	LS_C_Set(self)
end)

------以下均为【服务器、客户端】环境

function SkinedLegion:GetSkin()
	return self.skin
end

------以下均为【服务器】环境

SkinedLegion.SetLinkedSkin = LS_C_SetLinkedSkin
SkinedLegion.SetSkin = LS_C_SetSkin

function SkinedLegion:OnSave()
	if self.skin ~= nil or self.problemskin ~= nil then
		return { skin = self.skin, userid = self.userid, pskin = self.problemskin }
	end
end
SkinedLegion.OnLoad = LS_C_OnLoad

return SkinedLegion
