local stack_size = GetModConfigData("STACK_SIZE")

GLOBAL.TUNING.STACK_SIZE_LARGEITEM = stack_size
GLOBAL.TUNING.STACK_SIZE_MEDITEM = stack_size
GLOBAL.TUNING.STACK_SIZE_SMALLITEM = stack_size
GLOBAL.TUNING.STACK_SIZE_TINYITEM = stack_size
GLOBAL.TUNING.WORTOX_MAX_SOULS = stack_size
GLOBAL.TUNING.STACK_SIZE_PELLET = stack_size > 120 and stack_size or 120


local function OnStackSizeDirty(inst)
	local self = inst.replica.stackable
	if not self then
		return
	end

	self:ClearPreviewStackSize()
	inst:PushEvent("inventoryitem_stacksizedirty")
end
	
local mod_stackable_replica = GLOBAL.require("components/stackable_replica")

mod_stackable_replica._ctor = function(self, inst)
	self.inst = inst
	self._stacksize = GLOBAL.net_int(inst.GUID, "stackable._stacksize", "stacksizedirty")
	self._stacksizeupper = GLOBAL.net_int(inst.GUID, "stackable._stacksizeupper", "stacksizedirty")
	self._ignoremaxsize = GLOBAL.net_bool(inst.GUID, "stackable._ignoremaxsize")
	self._maxsize = GLOBAL.net_int(inst.GUID, "stackable._maxsize")
	
	if not GLOBAL.TheWorld.ismastersim then
		inst:ListenForEvent("stacksizedirty", OnStackSizeDirty)
	end
end


-- 定义堆叠大小单位常量（2的16次方）
local MAX_STACK_SIZE_UNIT = 65536
-- 引入 stackable_replica 组件
local stackable_replica = require("components/stackable_replica")

-- 获取堆叠物品当前大小
stackable_replica.StackSize = function(self)
    return self:GetPreviewStackSize() or (self._stacksizeupper:value() * MAX_STACK_SIZE_UNIT + 1 + self._stacksize:value())
end

-- 设置堆叠大小网络变量值
local function setStackSizeValues(self, upper, lower)
    self._stacksizeupper:set(upper)
    self._stacksize:set_local(lower)
    self._stacksize:set(lower)
end

-- 设置堆叠物品的大小
stackable_replica.SetStackSize = function(self, stacksize)
    stacksize = stacksize - 1
    if stacksize < MAX_STACK_SIZE_UNIT then
        setStackSizeValues(self, 0, stacksize)
    else
        local upper = math.floor(stacksize / MAX_STACK_SIZE_UNIT)
        local lower = stacksize - upper * MAX_STACK_SIZE_UNIT
        setStackSizeValues(self, upper, lower)
    end
end


-- 获取全局 tostring 函数
local tostring = GLOBAL.tostring
-- 引入 widgets/text 模块
local Text = GLOBAL.require("widgets/text")

-- 根据物品数量获取合适字体大小
local function getFontSize(quantity)
    if quantity <= 999 then return 42 end
    if quantity <= 9999 then return 36 end
    if quantity <= 99999 then return 34 end
    if quantity <= 999999 then return 32 end
    return 30
end

-- 重写 ItemTile 类的 SetQuantity 方法
AddClassPostConstruct("widgets/controls", function ()
    local ItemTile = require("widgets/itemtile")
    function ItemTile:SetQuantity(quantity)
        if self.onquantitychangedfn and self:onquantitychangedfn(quantity) then
            if self.quantity then
                self.quantity = self.quantity:Kill()
            end
            return
        elseif not self.quantity then
            self.quantity = self:AddChild(Text(GLOBAL.NUMBERFONT, 42))
        end
        local size = getFontSize(quantity)
        local quantityStr = tostring(quantity)
        self.quantity:SetSize(size)
        self.quantity:SetPosition(2, 16, 0)
        self.quantity:SetString(quantityStr)
    end
end)