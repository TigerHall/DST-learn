--[[
    作者：晴浅
    日期：2024/12/10
    功能：寻找封闭区域
    声明：以下内容均为原创，引用请注明出处！
]]

-- 四舍五入取整
local function round(num)
    return math.floor(num + 0.5)
end

-- 是否已经找到过
local function IsAlreadyFounded(areas, x, z)
    if type(areas) == "table" then
        for i = 1, #areas do
            if areas[i][1] == x and areas[i][2] == z then
                return true
            end
        end
    end
    return false
end

-- 判断是否有门
local function HasDoor(x, z)
    local doors = TheSim:FindEntities(x, 0, z, 0.5, {"door"})
    if doors and #doors > 0 then
        return true
    end
    return false
end

-- 寻找封闭区域
function FindEnclosedRoom(original_x, original_z, size)
    -- 石墙中心是整数+0.5
    original_x = math.floor(original_x) + 0.5
    original_z = math.floor(original_z) + 0.5
    size = round(size)

    local SETTINGS = {ignorewalls = false, ignorecreep = false, allowocean = false, ignoreLand = false}
    local current_points = {{original_x, original_z}}
    local already_found_areas = {{original_x, original_z}}
    -- 用队列进行广度优先搜索
    while type(current_points) == "table" and #current_points > 0 do
        local x = current_points[1][1]
        local z = current_points[1][2]
        if TheWorld.Pathfinder:IsClear(x, 0, z, x + 1, 0, z, SETTINGS)
                and not HasDoor(x + 1, z)
                and not IsAlreadyFounded(already_found_areas, x + 1, z) then
            table.insert(already_found_areas, {x + 1, z})
            table.insert(current_points, {x + 1, z})
        end
        if TheWorld.Pathfinder:IsClear(x, 0, z, x - 1, 0, z, SETTINGS)
                and not HasDoor(x - 1, z)
                and not IsAlreadyFounded(already_found_areas, x - 1, z) then
            table.insert(already_found_areas, {x - 1, z})
            table.insert(current_points, {x - 1, z})
        end
        if TheWorld.Pathfinder:IsClear(x, 0, z, x, 0, z + 1, SETTINGS)
                and not HasDoor(x, z + 1)
                and not IsAlreadyFounded(already_found_areas, x, z + 1) then
            table.insert(already_found_areas, {x, z + 1})
            table.insert(current_points, {x, z + 1})
        end
        if TheWorld.Pathfinder:IsClear(x, 0, z, x, 0, z - 1, SETTINGS)
                and not HasDoor(x, z - 1)
                and not IsAlreadyFounded(already_found_areas, x, z - 1) then
            table.insert(already_found_areas, {x, z - 1})
            table.insert(current_points, {x, z - 1})
        end

        table.remove(current_points, 1)

        if type(already_found_areas) == "table" and #already_found_areas > size then
            return false
        end
    end

    if #already_found_areas > 0 and #already_found_areas <= size then
        return already_found_areas
    else
        return false
    end
end

--[[测试
AddPlayerPostInit(function(player)
    if not TheWorld.ismastersim then return end
    player:DoPeriodicTask(5, function()
        local x, y, z = player.Transform:GetWorldPosition()

        local areas = FindEnclosedRoom(x, z, 50)
        print("Areas: ", areas, "Size: ", type(areas) == "table" and #areas or 0)
        if areas ~= false and type(areas) == "table" then
            for i = 1, #areas do
                local x1 = areas[i][1]
                local z1 = areas[i][2]
                local ent = SpawnPrefab("ash")
                ent.Transform:SetPosition(x1, 0, z1)
            end
        end
    end)
end)]]




--[[ 显示围墙是否围城封闭区域
local MaxDeleteCount = 100      -- 最大删除循环次数
local NearByRadius = 1.42       -- 包含斜相邻（根号2）

-- 删除未封闭的围墙
local function DeleteSingleWall(walls)
    for _, wall in ipairs(walls) do
        if wall:HasTag("hmr_already_found") then
            wall:RemoveTag("hmr_already_found")
        end
    end

    -- 循环删除未封闭的围墙，直到所有未封闭的围墙都被删除或至多循环100次
    for count = 1, MaxDeleteCount do
        local newwalls = {}
        for _, wall in ipairs(walls) do
            local x, _, z = wall.Transform:GetWorldPosition()
            local nearbywalls = TheSim:FindEntities(x, 0, z, NearByRadius, {"wall"}, {"hmr_already_found"})
            if #nearbywalls < 3 then -- 自己也算进去了
                -- 未组成空间的围墙标注红色高光
                if wall.AnimState then
                    wall.AnimState:SetMultColour(1, 0, 0, 1)
                end
                -- 标记为已找到
                if not wall:HasTag("hmr_already_found") then
                    wall:AddTag("hmr_already_found")
                end
            else    -- 记录当前可能已封闭的围墙
                table.insert(newwalls, wall)
            end
        end
        if newwalls and walls and #newwalls == #walls then
            break
        else
            walls = newwalls
        end
    end
end

-- 判定点是否在区域内
function IsPointInArea(x, z)
    local radius = 100
    local walls = TheSim:FindEntities(x, 0, z, radius, {"wall"})

    for _, wall in ipairs(walls) do
        if wall.AnimState then
            wall.AnimState:SetMultColour(1, 1, 1, 1)
        end
    end

    local nodes = {}
    walls = DeleteSingleWall(walls)
    if not walls or #walls == 0 then return false end

    for _, wall in ipairs(walls) do
        local wx, _, wz = wall.Transform:GetWorldPosition()
        if wall.AnimState then
            wall.AnimState:SetMultColour(0, 1, 0, 1)
        end
        table.insert(nodes, {wx, wz})
    end

    return TheSim:WorldPointInPoly(x, z, nodes)
end]]


--[[ 递归方式进行深度优先搜索，会导致寻找不完全，暂时弃用
function FindEnclosedRoom(original_x, original_z, size)
    local current_size = 0
    local already_found_areas = {}

    original_x = math.floor(original_x) + 0.5
    original_z = math.floor(original_z) + 0.5
    size = round(size)

    local SETTINGS = {ignorewalls = false, ignorecreep = false, allowocean = false}

    local function FindNearby(x, z)
        if current_size > size then
            print("outofsize, current_size: ", current_size, "size: ", size)
            return false
        end

        local current_areas = {}

        if TheWorld.Pathfinder:IsClear(original_x, 0, original_z, x + 1, 0, z, SETTINGS)
                and not IsAlreadyFounded(already_found_areas, x + 1, z) then
            current_size = current_size + 1
            table.insert(already_found_areas, {x + 1, z})
            table.insert(current_areas, {x + 1, z})
        end

        if TheWorld.Pathfinder:IsClear(original_x, 0, original_z, x - 1, 0, z, SETTINGS)
                and not IsAlreadyFounded(already_found_areas, x - 1, z) then
            current_size = current_size + 1
            table.insert(already_found_areas, {x - 1, z})
            table.insert(current_areas, {x - 1, z})
        end

        if TheWorld.Pathfinder:IsClear(original_x, 0, original_z, x, 0, z + 1, SETTINGS)
                and not IsAlreadyFounded(already_found_areas, x, z + 1) then
            current_size = current_size + 1
            table.insert(already_found_areas, {x, z + 1})
            table.insert(current_areas, {x, z + 1})
        end

        if TheWorld.Pathfinder:IsClear(original_x, 0, original_z, x, 0, z - 1, SETTINGS)
                and not IsAlreadyFounded(already_found_areas, x, z - 1) then
            current_size = current_size + 1
            table.insert(already_found_areas, {x, z - 1})
            table.insert(current_areas, {x, z - 1})
        end

        if type(current_areas) == "table" and #current_areas > 0 then
            for i = 1, #current_areas do
                local x1 = current_areas[i][1]
                local z1 = current_areas[i][2]
                FindNearby(x1, z1)
            end
        end

        if #already_found_areas > 0 and #already_found_areas <= size then
            return already_found_areas
        else
            return false
        end
    end

    return FindNearby(original_x, original_z)
end]]
