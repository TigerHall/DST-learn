--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[


        local mist_points = {}
        for k, node in pairs(TheWorld.topology.nodes) do
            for kk, tag in pairs(node.tags or {}) do
                if tag == "Mist" then
                    table.insert(mist_points, Vector3(node.x,0,node.y))
                end
            end
        end
        if #mist_points > 0 then
            local avg_x ,avg_z = 0, 0
            for k, pt in pairs(mist_points) do
                avg_x = avg_x + pt.x
                avg_z = avg_z + pt.z
            end
            avg_x = avg_x / #mist_points
            avg_z = avg_z / #mist_points
            ThePlayer.Transform:SetPosition(avg_x,0,avg_z)
        end

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 只能找到中心点。
    function TBAT.FNS:GetGraveyardLocation()
        local mist_points = {}
        for k, node in pairs(TheWorld.topology.nodes) do
            for kk, tag in pairs(node.tags or {}) do
                if tag == "Mist" then
                    table.insert(mist_points, Vector3(node.x,0,node.y))
                end
            end
        end
        if #mist_points > 0 then
            local avg_x ,avg_z = 0, 0
            for k, pt in pairs(mist_points) do
                avg_x = avg_x + pt.x
                avg_z = avg_z + pt.z
            end
            avg_x = avg_x / #mist_points
            avg_z = avg_z / #mist_points
            return Vector3(avg_x,0,avg_z)
        end
        return nil
    end