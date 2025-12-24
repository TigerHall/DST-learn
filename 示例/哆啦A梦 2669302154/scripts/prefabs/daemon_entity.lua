--------------------------------
--[[ 全局entity]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-02-14]]
--[[ @updateTime: 2022-02-14]]
--[[ @email: x7430657@163.com]]
--------------------------------

local assets =
{
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddNetwork() -- 必须有
    inst.persists = true
    inst.entity:SetPristine()

    inst:AddTag("NOCLICK") -- 不可点击
    inst:AddTag("NOBLOCK")		--不可被查看	建造不会被遮挡
    inst:AddTag("notarget")		--不能被作为目标
    inst:AddTag("haunted")      --防作祟标签
    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end


return  Prefab(TUNING.DORAEMON_TECH.DAEMON_ENTITY_PREFAB, fn, assets)