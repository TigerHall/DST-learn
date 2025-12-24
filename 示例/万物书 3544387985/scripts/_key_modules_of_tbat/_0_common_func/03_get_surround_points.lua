


function TBAT.FNS:GetSurroundPoints(CMD_TABLE)
        -- local CMD_TABLE = {
        --     target = inst or Vector3(),
        --     range = 8,
        --     num = 8
        -- }
        if CMD_TABLE == nil then
            return
        end
        if CMD_TABLE.pt then
            CMD_TABLE.target = CMD_TABLE.pt
        end
        local theMid = nil
        if CMD_TABLE.target == nil then
            theMid = Vector3( self.inst.Transform:GetWorldPosition() )
        elseif CMD_TABLE.target.x then
            theMid = CMD_TABLE.target
        elseif CMD_TABLE.target.prefab then
            theMid = Vector3( CMD_TABLE.target.Transform:GetWorldPosition() )
        else
            return
        end
        -- --------------------------------------------------------------------------------------------------------------------
        -- -- 8 points
        -- local retPoints = {}
        -- for i = 1, 8, 1 do
        --     local tempDeg = (PI/4)*(i-1)
        --     local tempPoint = theMidPoint + Vector3( Range*math.cos(tempDeg) ,  0  ,  Range*math.sin(tempDeg)    )
        --     table.insert(retPoints,tempPoint)
        -- end
        -- --------------------------------------------------------------------------------------------------------------------
        local num = CMD_TABLE.num or 8
        local range = CMD_TABLE.range or 8
        local retPoints = {}
        for i = 1, num, 1 do
            local tempDeg = (2*PI/num)*(i-1)
            local tempPoint = theMid + Vector3( range*math.cos(tempDeg) ,  0  ,  range*math.sin(tempDeg)    )
            table.insert(retPoints,tempPoint)
        end

        return retPoints


    end


function TBAT.FNS:GetRandomSurroundPoint(CMD_TABLE)
        --- 返回两个： pt , available_points
        -- local CMD_TABLE = {
        --     target = inst or Vector3(),
        --     max_radius = 8,
        --     min_raidus = 0,
        --     delta_raidus = 0,
        --     test = function(pt) return true end,
        --     num_mult = nil or 1,  -- 密度倍数
        -- }
    local the_mid_pt = nil
    if CMD_TABLE.target == nil then
        return nil
    end
    if CMD_TABLE.target.x then
        the_mid_pt = Vector3( CMD_TABLE.target.x,0, CMD_TABLE.target.z )
    elseif CMD_TABLE.target.Transform then
        the_mid_pt = Vector3( CMD_TABLE.target.Transform:GetWorldPosition() )
    end
    if the_mid_pt == nil then
        return nil
    end
    if CMD_TABLE.test == nil then
        return nil
    end
    local current_radius = CMD_TABLE.max_radius
    local end_radius = CMD_TABLE.min_raidus
    local delta_radius = math.max(math.abs(CMD_TABLE.delta_raidus),0.01)
    local available_points = {}
    while current_radius > end_radius do
        local temp_points = TBAT.FNS:GetSurroundPoints({
            target = Vector3(0,0,0),
            range = current_radius,
            num = 10*current_radius*(CMD_TABLE.num_mult or 1),
        })
        for k, offset_pt in pairs(temp_points) do
            local pt = the_mid_pt + offset_pt
            if CMD_TABLE.test(pt) then
                table.insert(available_points,pt)
            end
        end
        current_radius = current_radius - delta_radius
    end
    if #available_points > 0 then
        return available_points[math.random(1,#available_points)] , available_points
    end
    return nil,nil    
end