if not GetModConfigData("pick_drop_mult") then --避免重复加载，不然就超级加倍了
    modimport("modmain/abilities/pick_drop_mult")
end
