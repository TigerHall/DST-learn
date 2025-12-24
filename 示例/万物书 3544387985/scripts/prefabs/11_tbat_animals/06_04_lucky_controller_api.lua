------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    inst  为 宠物 本身

]]--
local wlist = require "util/weighted_list"
local bufflist = {
    tbat_kill_get_drop = 3,
    tbat_make_half = 3,
    tbat_double_drop = 3,
    tbat_one_shot = 3,
    tbat_double_collect = 43,
    tbat_food_double_recover = 43,
}
local bufflist2 = {
    tbat_kill_get_drop2 = 3,
    tbat_make_half2 = 3,
    tbat_double_drop2 = 3,
    tbat_one_shot2 = 3,
    tbat_double_collect2 = 43,
    tbat_food_double_recover2 = 43,
}
local luckybufflist = wlist(bufflist)
------------------------------------------------------------------------------------------------------------------------------------------------
--- 玩家触摸雕像，领取 鹤 的瞬间执行。仅限触摸的一瞬。
local function pet_start_following_player(inst, player)
    if player and player:IsValid() then
        -- 先清buff（不管有时间还是无限时间）
        for k, v in pairs(bufflist) do
            if player:HasDebuff(k) then
                player:RemoveDebuff(k)
            end
        end
        for k, v in pairs(bufflist2) do
            if player:HasDebuff(k) then
                player:RemoveDebuff(k)
            end
        end
        -- 按权重添加buff
        local buffname = luckybufflist:getChoice(math.random() * luckybufflist:getTotalWeight())
        player:AddDebuff(buffname, buffname)
    end

    -- TheNet:Announce("四叶草鹤开始跟随玩家")
end

------------------------------------------------------------------------------------------------------------------------------------------------
--- 正在跟随玩家的期间，存档读取（或穿越洞穴）后，执行。
    local function pet_onload_pst_fn(inst,player)
        -- TheNet:Announce("四叶草鹤 ： Onload")
    end
------------------------------------------------------------------------------------------------------------------------------------------------
---- 特殊持续执行
    -- 这条API 只会执行一次，以下条件任意一个达到就会执行，并在玩家离开存档之前，不会再重复执行。
    -- 这个API 运行的时候，鹤已经跟着玩家。
    -- 1、触摸雕像领养的瞬间
    -- 2、存档读取（或穿越洞穴）后，
    local function on_following_player(inst,player)
        -- TheNet:Announce("四叶草鹤 ： 正在跟随玩家 , 开始计时")
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 正在跟随玩家、每秒都会执行
    local function pet_following_player_timer_update(inst,player,remain_time)
        -- print("四叶草鹤 ： 跟随玩家计时器更新,剩余时间:",inst.GUID,remain_time)
    end
------------------------------------------------------------------------------------------------------------------------------------------------
--- 离开玩家的时候执行。
local function pet_on_leave_fn(inst, player)
    -- TheNet:Announce("四叶草鹤 ： 离开玩家")
    -- 清buff（只清无限时间的就行）
    if player and player:IsValid() then
        for k, v in pairs(bufflist) do
            if player:HasDebuff(k) then
                player:RemoveDebuff(k)
            end
        end
    end
end
------------------------------------------------------------------------------------------------------------------------------------------------
return {
    pet_start_following_player = pet_start_following_player,
    pet_onload_pst_fn = pet_onload_pst_fn,
    on_following_player = on_following_player,
    pet_following_player_timer_update = pet_following_player_timer_update,
    pet_on_leave_fn = pet_on_leave_fn,
}
