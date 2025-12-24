----------------------------------------------------------------------------------------------------------------------------------
--[[

     
     
]]--
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_acceptable = Class(function(self, inst)
    self.inst = inst

    self.DataTable = {}
end,
nil,
{

})



function tbat_com_acceptable:SetOnAcceptFn(fn)
    if type(fn) == "function" then
        self.on_accept_fn = fn
    end
end

function tbat_com_acceptable:OnAccept(item,doer)
    if self.on_accept_fn then
        return self.on_accept_fn(self.inst,item,doer)
    end
end


return tbat_com_acceptable






