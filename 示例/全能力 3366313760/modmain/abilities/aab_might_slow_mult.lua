local AAB_MIGHT_SLOW_MULT = GetModConfigData("aab_might_slow_mult") / 100

AddComponentPostInit("mightiness", function(self, inst)
    self.ratemodifiers:SetModifier(inst, AAB_MIGHT_SLOW_MULT, "aab_might_slow_mult")
end)
