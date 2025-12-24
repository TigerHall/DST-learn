local HSkipSlot = Class(function(self, inst)
    self.inst = inst
    self.skiplist = nil

    self._skipfrom = net_string(inst.GUID, "hmr_hskipslot_skipfrom")
    self._skipnum = net_shortint(inst.GUID, "hmr_hskipslot_skipnum")
    self._totalslotnum = net_shortint(inst.GUID, "hmr_hskipslot_totalslotnum")
    self._needupdatenormal = net_bool(inst.GUID, "hmr_hskipslot_needupdatenormal", "hmr_hskipslot_needupdatenormal_dirty")
    self.inst:ListenForEvent("hmr_hskipslot_needupdatenormal_dirty", function()
        self:CreateNormalSkipSlots()
        self._needupdatenormal:set(false)
    end)

    self._randomskipslots = net_bytearray(inst.GUID, "hmr_hskipslot_randomskipslots", "hmr_hskipslot_randomskipslots_dirty")
    self.inst:ListenForEvent("hmr_hskipslot_randomskipslots_dirty", function()
        self.skiplist = self._randomskipslots:value()
    end)
end)


function HSkipSlot:UpdateNormalSkipSlots(from, skipnum, totalslotnum)
    self._skipfrom:set(from or "beginning")
    self._skipnum:set(skipnum or 0)
    self._totalslotnum:set(totalslotnum or 0)
    self._needupdatenormal:set(true)
end

function HSkipSlot:CreateNormalSkipSlots()
    local from, skipnum, totalslotnum = self._skipfrom:value(), self._skipnum:value(), self._totalslotnum:value()
    local skiplist = {}
    if from == "beginning" then
        for i = 1, skipnum do
            table.insert(skiplist, i)
        end
    else
        --print("normalskip")
        for i = 1, skipnum do
            table.insert(skiplist, totalslotnum - i + 1)
        end
    end
    self.skiplist = skiplist
end

function HSkipSlot:CreateRandomSkipSlots(skipslots)
    self._randomskipslots:set(skipslots or {})
end

return HSkipSlot