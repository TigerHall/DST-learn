local function Update(inst)
    if not IsEntityDeadOrGhost(inst) then
        local current = inst.components.temperature.current
        if current < 5 then
            inst.components.temperature:DoDelta(1)
        elseif current > 60 then
            inst.components.temperature:DoDelta(-1)
        end
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoPeriodicTask(0, Update)
end)
