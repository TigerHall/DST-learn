AddRecipePostInitAny(function(v)
    v.min_spacing = 0
end)

-- 这个不能改，不然船放不下来
-- for k, v in pairs(DEPLOYSPACING_RADIUS) do
--     DEPLOYSPACING_RADIUS[k] = 0
-- end

require "components/map"
Map.IsDeployPointClear = function() return true end
