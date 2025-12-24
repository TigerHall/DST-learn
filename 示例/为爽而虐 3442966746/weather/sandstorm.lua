-- local UpvalueHacker = require("tools/upvaluehacker")

AddComponentPostInit("sandstorms", function(self)
    local inst = self.inst
    if inst:HasTag("cave") then return end
    -- Private
    local _sandstormactive = false
    local _issandstormseason = false
    local _iswet = false
    --[[ Private member functions ]]
    local function ShouldActivateSandstorm() return _issandstormseason and not _iswet end
    local function ToggleSandstorm(inst)
        if _sandstormactive ~= ShouldActivateSandstorm() then
            _sandstormactive = not _sandstormactive
            inst:PushEvent("ms_stormchanged", {stormtype = STORM_TYPES.SANDSTORM, setting = _sandstormactive})
        end
    end
    --[[ Private event handlers ]]
    local function OnSeasonTick(inst, data)
        _issandstormseason = data.season ~= SEASONS.WINTER
        -- 尝试使用不妥协提供的类似更改夏季野火生成组件的upvaluehack方法，但没有成功
        -- local _ShouldActivateWildfires
        -- local _CheckValidWildfireStarter
        -- local _ms_startwildfireforplayerfn
        -- local inst = self.inst
        -- -- simplify the for loop by adding [inst] to the end
        -- for k, func in pairs(inst.event_listening["ms_lightwildfireforplayer"][inst]) do
        --     -- check that the upvalue we want to grab is the correct one (i.e the function ShouldActivateWildfires)
        --     if UpvalueHacker.GetUpvalue(func, "ShouldActivateWildfires") then
        --         _ms_startwildfireforplayerfn = func
        --         _ShouldActivateWildfires = UpvalueHacker.GetUpvalue(func, "ShouldActivateWildfires")
        --         _CheckValidWildfireStarter = UpvalueHacker.GetUpvalue(func, "LightFireForPlayer", "CheckValidWildfireStarter")
        --         -- we can break out of the loop now since we found the upvalue we wanted
        --         break
        --     end
        -- end
        -- local ShouldActivateWildfires = function()
        --     return _ShouldActivateWildfires() and TheWorld:HasTag("heatwavestart")
        -- end

        -- --TODO: HOOK.
        -- local CheckValidWildfireStarter = function(obj)
        --     local x, y, z = obj.Transform:GetWorldPosition()
        --     return obj:IsValid() and not obj:HasTag("fireimmune") and (obj:HasTag("plant") or obj:HasTag("tree")) and not checkforcanopyshade(obj) and not (obj.components.witherable ~= nil and obj.components.witherable:IsProtected()) and GetTemperatureAtXZ(x, z) >= TUNING.WILDFIRE_THRESHOLD and not obj:HasTag("structure")
        -- end

        -- UpvalueHacker.SetUpvalue(_ms_startwildfireforplayerfn, ShouldActivateWildfires, "ShouldActivateWildfires")
        -- UpvalueHacker.SetUpvalue(_ms_startwildfireforplayerfn, CheckValidWildfireStarter, "LightFireForPlayer",
        --     "CheckValidWildfireStarter")
        -- -- 非常粗糙的避免秋季沙暴停止的方法，不能防止蚁狮消失
        -- if not (data.wetness and data.wetness > 0) and data.season == SEASONS.AUTUMN then
        --     _sandstormactive = not _sandstormactive  
        -- end
        inst:DoTaskInTime(0.1, ToggleSandstorm)
    end
    local function OnSeasonChanged(inst, season)
        -- 秋天来临时必然下雨
        if season == SEASONS.AUTUMN then
            TheWorld:PushEvent("ms_forceprecipitation")
        end
    end

    local function OnWeatherTick(inst, data)
        _iswet = data.wetness > 0 or data.snowlevel > 0
        inst:DoTaskInTime(0.1, ToggleSandstorm)
    end
    -- Register events
    inst:WatchWorldState("season", OnSeasonChanged)
    inst:ListenForEvent("weathertick", OnWeatherTick)
    inst:ListenForEvent("seasontick", OnSeasonTick)
    -- Component Functions
    local function IsInSandstorm(self, ent)
        return _sandstormactive and ent.components.areaaware ~= nil and ent.components.areaaware:CurrentlyInTag("sandstorm")
    end
    local oldIsInSandstorm = self.IsInSandstorm
    self.IsInSandstorm = function(...) return oldIsInSandstorm(...) or IsInSandstorm(...) end
    local function GetSandstormLevel(self, ent)
        if IsInSandstorm(self, ent) then
            local oasislevel = self:CalcOasisLevel(ent)
            return oasislevel < 1 and math.clamp(self:CalcSandstormLevel(ent) - oasislevel, 0, 1) or 0
        end
        return 0
    end
    local oldGetSandstormLevel = self.GetSandstormLevel
    self.GetSandstormLevel = function(...)
        local level = oldGetSandstormLevel(...)
        if level == 0 then return GetSandstormLevel(...) end
        return level
    end
    local oldIsSandstormActive = self.IsSandstormActive
    self.IsSandstormActive = function(...) return oldIsSandstormActive(...) or _sandstormactive end
end)

-- AddPrefabPostInit(
--     "antlion",
--     function(inst)
--         if not TheWorld.ismastersim then
--             return inst
--         end
--         if inst.components.trader then
--             local oldaccept = inst.components.trader.onaccept
--             inst.components.trader.onaccept = function(inst, giver, item, ...)
--                 if
--                     TheWorld.state.season ~= SEASONS.SUMMER and item.prefab == "heatrock" and
--                         item.currentTempRange ~= nil
--                  then
--                     item.currentTempRange = 3
--                 end
--                 oldaccept(inst, giver, item, ...)
--             end
--         end
--     end
-- )
