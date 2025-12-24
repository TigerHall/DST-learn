local Room = Class(function(self, inst)
	self.inst = inst

    self.min_size = 10
    self.max_size = 400
    self.current_size = 0
    self.inroom = false

    self.onenterroom = nil
    self.onleaveroom = nil

    self.watch_interval = "phase"
end)

function Room:SetMinRoomSize(size)
    self.min_size = size
end

function Room:SetMaxRoomSize(size)
    self.max_size = size
end

function Room:SetWatchInterval(interval)
    self.watch_interval = interval
end

function Room:SetOnEnterRoom(func)
    self.onenterroom = func
end

function Room:SetOnLeaveRoom(func)
    self.onleaveroom = func
end

function Room:SetOnUpdate(fn)
    self.onupdate = fn
end

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

local function HasDoor(x, z)
    local doors = TheSim:FindEntities(x, 0, z, 0.5, {"door"})
    if doors and #doors > 0 then
        return true
    end
    return false
end

-- 寻找封闭区域
function Room:GetRoomAreas(size)
    local original_x, _, original_z = self.inst.Transform:GetWorldPosition()
    -- 石墙中心是整数+0.5
    original_x = math.floor(original_x) + 0.5
    original_z = math.floor(original_z) + 0.5
    if size == nil then
        size = self.max_size
    else
        size = math.clamp(size, self.min_size, self.max_size)
    end
    size = HMR_UTIL.Round(size)

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

-- 获取房间大小
function Room:GetRoomSize(undersize)
    if undersize == nil then
        undersize = 400
    end
    local already_found_areas = self:GetRoomAreas(undersize)
    if already_found_areas == false then
        return 0
    else
        return #already_found_areas
    end
end

function Room:CollectItemsInRoom()
    local already_found_areas = self:GetRoomAreas(self.max_size)
    if already_found_areas == false or #already_found_areas == 0 then
        return {}
    end

    -- 找到房间内的所有实体
    local entities = {}
    for i = 1, #already_found_areas do
        local x = already_found_areas[i][1]
        local z = already_found_areas[i][2]
        local ents = TheSim:FindEntities(x, 0, z, 1.5 , nil, {"wall", "heavy", "FX", "CLASSFIED"})
        if ents and #ents > 0 then
            for j = 1, #ents do
                table.insert(entities, ents[j])
            end
        end
    end

    return entities
end

function Room:OnEnterRoom()
    local room_areas = self:GetRoomAreas(self.max_size)
    if self.onenterroom ~= nil then
        self.onenterroom(self.inst, room_areas)
    end
end

function Room:OnLeaveRoom()
    if self.onleaveroom ~= nil then
        self.onleaveroom(self.inst)
    end
end

local function Watch(inst)
    local self = inst.components.hmrroom
    local room_size = self:GetRoomSize(self.max_size)
    if room_size ~= self.current_size then
        if room_size >= self.min_size and room_size <= self.max_size then
            if not self.inroom then
                self.inroom = true
                self:OnEnterRoom()
            end
        else
            if self.inroom then
                self.inroom = false
                self:OnLeaveRoom()
            end
        end
        self.inst:PushEvent("room_size_changed", {current = room_size, last = self.current_size})
        self.current_size = room_size
    end
    if self.onupdate ~= nil then
        self.onupdate(self.inst)
    end
end

function Room:StartWatch(interval)
    interval = interval or self.watch_interval
    if type(interval) == "string" then  -- "phase", "cycles", 
        self.inst:WatchWorldState(interval, Watch)
    elseif type(interval) == "number" then
        self.inst:DoPeriodicTask(interval, Watch)
    end
    Watch(self.inst)
end

function Room:OnSave()
    local data =
    {
    }
    return next(data) ~= nil and data or nil
end

function Room:OnLoad(data)
    if data then
    end
end

return Room
