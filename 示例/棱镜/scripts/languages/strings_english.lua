local _G = GLOBAL
local STRINGS = _G.STRINGS

local S_NAMES = STRINGS.NAMES                   --各种对象的名字
local S_RECIPE_DESC = STRINGS.RECIPE_DESC       --科技栏里的描述
local S______GENERIC = STRINGS.CHARACTERS.GENERIC      --威尔逊的台词（如果其他角色没有台词则会默认使用威尔逊的）
local S_______WILLOW = STRINGS.CHARACTERS.WILLOW       --薇洛的台词
local S_____WOLFGANG = STRINGS.CHARACTERS.WOLFGANG     --沃尔夫冈的台词
local S________WENDY = STRINGS.CHARACTERS.WENDY        --温蒂的台词
local S_________WX78 = STRINGS.CHARACTERS.WX78         --WX78的台词
local S_WICKERBOTTOM = STRINGS.CHARACTERS.WICKERBOTTOM --维克伯顿的台词
local S_______WOODIE = STRINGS.CHARACTERS.WOODIE       --伍迪的台词
local S______WAXWELL = STRINGS.CHARACTERS.WAXWELL      --麦克斯韦的台词
local S___WATHGRITHR = STRINGS.CHARACTERS.WATHGRITHR   --瓦丝格蕾的台词
local S_______WEBBER = STRINGS.CHARACTERS.WEBBER       --韦伯的台词
local S_______WINONA = STRINGS.CHARACTERS.WINONA       --薇诺娜的台词
local S________WARLY = STRINGS.CHARACTERS.WARLY        --沃利的台词
local S_______WORTOX = STRINGS.CHARACTERS.WORTOX       --沃拓克斯的台词
local S_____WORMWOOD = STRINGS.CHARACTERS.WORMWOOD     --沃姆伍德的台词
local S_________WURT = STRINGS.CHARACTERS.WURT         --沃特的台词
local S_______WALTER = STRINGS.CHARACTERS.WALTER       --沃尔特的台词
local S________WANDA = STRINGS.CHARACTERS.WANDA        --旺达的台词
local S___CHARACTERS = {
    S______GENERIC, S_______WILLOW, S_____WOLFGANG, S________WENDY, S_________WX78, S_WICKERBOTTOM, S_______WOODIE,
    S______WAXWELL, S___WATHGRITHR, S_______WEBBER, S_______WINONA, S________WARLY, S_______WORTOX, S_____WORMWOOD,
    S_________WURT, S_______WALTER, S________WANDA
}

local function CopyStrActionFail(newkey, key)
    for _, character in ipairs(S___CHARACTERS) do
        character.ACTIONFAIL[newkey] = character.ACTIONFAIL[key] or S______GENERIC.ACTIONFAIL[key]
    end
end
local function CopyStrDescribe(newkey, key)
    for _, character in ipairs(S___CHARACTERS) do
        character.DESCRIBE[newkey] = character.DESCRIBE[key] or S______GENERIC.DESCRIBE[key]
    end
end
-- local function CopyStrBuffTalk(newkey, key)
--     local newstr = "ANNOUNCE_ATTACH_"..newkey
--     local str = "ANNOUNCE_ATTACH_"..key
--     local newstr2 = "ANNOUNCE_DETACH_"..newkey
--     local str2 = "ANNOUNCE_DETACH_"..key
--     for _, character in ipairs(S___CHARACTERS) do
--         character[newstr] = character[str] or S______GENERIC[str]
--         character[newstr2] = character[str2] or S______GENERIC[str2]
--     end
-- end

--------------------------------------------------------------------------
--[[ the little star in the cave ]]--[[ 洞穴里的星光点点 ]]
--------------------------------------------------------------------------

S_NAMES.HAT_LICHEN = "Lichen Hairpin"
S_RECIPE_DESC.HAT_LICHEN = "I have an \"idea\"! Just like in cartoons."
S______GENERIC.DESCRIBE.HAT_LICHEN = "An idea that's taken form!"
S_______WILLOW.DESCRIBE.HAT_LICHEN = "You can't really LIGHT it."
S_____WOLFGANG.DESCRIBE.HAT_LICHEN = "Glowy little gadget."
S________WENDY.DESCRIBE.HAT_LICHEN = "Abigail used to wear a hairpin like this on Sundays..."
S_________WX78.DESCRIBE.HAT_LICHEN = "TEMPORARY ORGANIC SOURCE OF LIGHT."
S_WICKERBOTTOM.DESCRIBE.HAT_LICHEN = "Literally radiant... Pun intended."
S_______WOODIE.DESCRIBE.HAT_LICHEN = "Doesn't really suit me."
S______WAXWELL.DESCRIBE.HAT_LICHEN = "That's such a disgrace!"
--S___WATHGRITHR.DESCRIBE.HAT_LICHEN = ""
S_______WEBBER.DESCRIBE.HAT_LICHEN = "Wendy! Come see our new hairpin!"
S_______WINONA.DESCRIBE.HAT_LICHEN = "For illumination, I'd better put it on for now."
S_____WORMWOOD.DESCRIBE.HAT_LICHEN = "I'dah put a glowy buddy on my head!"
S_________WURT.DESCRIBE.HAT_LICHEN = "Not pretty, so why not eat it?"

--------------------------------------------------------------------------
--[[ the power of flowers ]]--[[ 花香四溢 ]]
--------------------------------------------------------------------------

S_NAMES.ROSORNS = "Rosorns" --带刺蔷薇
S______GENERIC.DESCRIBE.ROSORNS = "I am so defenseless in front of love."
-- S_______WILLOW.DESCRIBE.ROSORNS = ""
-- S_____WOLFGANG.DESCRIBE.ROSORNS = ""
S________WENDY.DESCRIBE.ROSORNS = "Love is also a form of torment."
-- S_________WX78.DESCRIBE.ROSORNS = ""
-- S_WICKERBOTTOM.DESCRIBE.ROSORNS = ""
-- S_______WOODIE.DESCRIBE.ROSORNS = ""
-- S______WAXWELL.DESCRIBE.ROSORNS = ""
S___WATHGRITHR.DESCRIBE.ROSORNS = "This emotion is irresistible."
-- S_______WEBBER.DESCRIBE.ROSORNS = ""
S_______WINONA.DESCRIBE.ROSORNS = "A rose's fragrance always strikes me deep in my heart."
S_______WORTOX.DESCRIBE.ROSORNS = "What a beautiful and natural weapon."
S_____WORMWOOD.DESCRIBE.ROSORNS = "To prick bad guys!"
-- S________WARLY.DESCRIBE.ROSORNS = ""
-- S_________WURT.DESCRIBE.ROSORNS = ""
S_______WALTER.DESCRIBE.ROSORNS = "I'm most afraid of getting stabbed."
-- S________WANDA.DESCRIBE.ROSORNS = ""

S_NAMES.LILEAVES = "Lileaves" --蹄莲翠叶
S______GENERIC.DESCRIBE.LILEAVES = "Love's poison makes me helpless."
-- S_______WILLOW.DESCRIBE.LILEAVES = ""
S_____WOLFGANG.DESCRIBE.LILEAVES = "Wolfgang doesn't want to experience the feeling of muscle weakness."
S________WENDY.DESCRIBE.LILEAVES = "I don't need mercy, I need redemption."
-- S_________WX78.DESCRIBE.LILEAVES = ""
S_WICKERBOTTOM.DESCRIBE.LILEAVES = "The sap of the plant carries toxicity that can weaken muscles."
-- S_______WOODIE.DESCRIBE.LILEAVES = ""
-- S______WAXWELL.DESCRIBE.LILEAVES = ""
S___WATHGRITHR.DESCRIBE.LILEAVES = "This will result in an unfair battle."
-- S_______WEBBER.DESCRIBE.LILEAVES = ""
-- S_______WINONA.DESCRIBE.LILEAVES = ""
S_______WORTOX.DESCRIBE.LILEAVES = "Weakening your enemies is a good solution."
S_____WORMWOOD.DESCRIBE.LILEAVES = "Toxic."
-- S________WARLY.DESCRIBE.LILEAVES = ""
-- S_________WURT.DESCRIBE.LILEAVES = ""
-- S_______WALTER.DESCRIBE.LILEAVES = ""
S________WANDA.DESCRIBE.LILEAVES = "Time is like poison, most people will slowly become poisoned."

S_NAMES.ORCHITWIGS = "Orchitwigs" --兰草花穗
S______GENERIC.DESCRIBE.ORCHITWIGS = "A flower with a renowned reputation."
-- S_______WILLOW.DESCRIBE.ORCHITWIGS = ""
-- S_____WOLFGANG.DESCRIBE.ORCHITWIGS = ""
-- S________WENDY.DESCRIBE.ORCHITWIGS = ""
-- S_________WX78.DESCRIBE.ORCHITWIGS = ""
-- S_WICKERBOTTOM.DESCRIBE.ORCHITWIGS = ""
S_______WOODIE.DESCRIBE.ORCHITWIGS = "I just like these understated flowers."
-- S______WAXWELL.DESCRIBE.ORCHITWIGS = ""
S___WATHGRITHR.DESCRIBE.ORCHITWIGS = "Splashing petals can also hit nearby enemies."
-- S_______WEBBER.DESCRIBE.ORCHITWIGS = ""
-- S_______WINONA.DESCRIBE.ORCHITWIGS = ""
S_______WORTOX.DESCRIBE.ORCHITWIGS = "Too many flowers, my eyes are blurred."
S_____WORMWOOD.DESCRIBE.ORCHITWIGS = "Flowers!"
-- S________WARLY.DESCRIBE.ORCHITWIGS = ""
-- S_________WURT.DESCRIBE.ORCHITWIGS = ""
-- S_______WALTER.DESCRIBE.ORCHITWIGS = ""
-- S________WANDA.DESCRIBE.ORCHITWIGS = ""

S_NAMES.HAT_WHISPEROSE = "Whisperose" --语夜玫瑰
S______GENERIC.DESCRIBE.HAT_WHISPEROSE = "Through these night roses, I can see through everything!"
-- S_______WILLOW.DESCRIBE.HAT_WHISPEROSE = ""
S_____WOLFGANG.DESCRIBE.HAT_WHISPEROSE = "These pricks caused Wolfgang a headache."
S________WENDY.DESCRIBE.HAT_WHISPEROSE = "It always whispers at night."
-- S_________WX78.DESCRIBE.HAT_WHISPEROSE = ""
S_WICKERBOTTOM.DESCRIBE.HAT_WHISPEROSE = "Its hallucinogenic effect can make people see through things."
S_______WOODIE.DESCRIBE.HAT_WHISPEROSE = "I'm already crazy enough to put thorns on my head."
S______WAXWELL.DESCRIBE.HAT_WHISPEROSE = "I am too fragile to withstand its torment."
S___WATHGRITHR.DESCRIBE.HAT_WHISPEROSE = "The flowers of the Night Goddess can help me discover the weaknesses of enemies."
S_______WEBBER.DESCRIBE.HAT_WHISPEROSE = "The wreath of dark magic."
-- S_______WINONA.DESCRIBE.HAT_WHISPEROSE = ""
S_______WORTOX.DESCRIBE.HAT_WHISPEROSE = "The blood I shed is the price it takes."
S_____WORMWOOD.DESCRIBE.HAT_WHISPEROSE = "Is there anything you want to tell me?"
S________WARLY.DESCRIBE.HAT_WHISPEROSE = "A scavenger who doesn't know how to hunt is not a good chef."
-- S_________WURT.DESCRIBE.HAT_WHISPEROSE = ""
S_______WALTER.DESCRIBE.HAT_WHISPEROSE = "Hey, won't it prick my head?"
-- S________WANDA.DESCRIBE.HAT_WHISPEROSE = ""

S_NAMES.ROSEBUSH = "Rose Bush"
S_NAMES.ROSEBUSH_WAXED = "Fuel-Woven Rose Bush"
S_NAMES.ROSEBUSH_ITEM_WAXED = "Fuel-Woven Rose Bush"
S______GENERIC.DESCRIBE.ROSEBUSH = {
    BARREN = "She can't get through this on her own.",
    WITHERED = "Her beauty shrinks with her under the blazing sunlight.",
    GENERIC = "Beautiful, but spikey.",
    PICKED = "No one knows her beauty.",
    BURNING = "It's beauty is going up in smoke!"
}

S_NAMES.DUG_ROSEBUSH = "Rose Bush"
S______GENERIC.DESCRIBE.DUG_ROSEBUSH = "Although a rose is beautiful, it still has thorns."
S_______WILLOW.DESCRIBE.DUG_ROSEBUSH = "After digging it out, it can burn more thoroughly."
-- S_____WOLFGANG.DESCRIBE.DUG_ROSEBUSH = ""
-- S________WENDY.DESCRIBE.DUG_ROSEBUSH = ""
S_________WX78.DESCRIBE.DUG_ROSEBUSH = "LACK OF GROWTH SUBSTRATE."

S_NAMES.CUTTED_ROSEBUSH = "Rose Twigs"
S______GENERIC.DESCRIBE.CUTTED_ROSEBUSH = "This is a very common way of propagating plants."

S_NAMES.LILYBUSH = "Lily Bush"
S_NAMES.LILYBUSH_WAXED = "Fuel-Woven Lily Bush"
S_NAMES.LILYBUSH_ITEM_WAXED = "Fuel-Woven Lily Bush"
S______GENERIC.DESCRIBE.LILYBUSH = {
    BARREN = "It can't recover without my help.",
    WITHERED = "She is no longer beauteous.",
    GENERIC = "She's so different!",
    PICKED = "No one knows her beauty.",
    BURNING = "It's beauty is going up in smoke!"
}

S_NAMES.DUG_LILYBUSH = "Lily Bush"
S______GENERIC.DESCRIBE.DUG_LILYBUSH = "I can't wait to see it bloom once again."

S_NAMES.CUTTED_LILYBUSH = "Lily Sprout"
S______GENERIC.DESCRIBE.CUTTED_LILYBUSH = "This is a very common way of propagating plants."

S_NAMES.ORCHIDBUSH = "Orchid Bush"
S_NAMES.ORCHIDBUSH_WAXED = "Fuel-Woven Orchid Bush"
S_NAMES.ORCHIDBUSH_ITEM_WAXED = "Fuel-Woven Orchid Bush"
S______GENERIC.DESCRIBE.ORCHIDBUSH = {
    BARREN = "It can't recover without my help.",
    WITHERED = "She is no longer beauteous.",
    GENERIC = "She's so different!",
    PICKED = "No one knows her beauty.",
    BURNING = "It's beauty is going up in smoke!"
}

S_NAMES.DUG_ORCHIDBUSH = "Orchid Bush"
S______GENERIC.DESCRIBE.DUG_ORCHIDBUSH = "How dainty."

S_NAMES.CUTTED_ORCHIDBUSH = "Orchid Seeds"
S______GENERIC.DESCRIBE.CUTTED_ORCHIDBUSH = "This is a very common way of propagating plants."

S_NAMES.NEVERFADEBUSH = "Neverfade Bush"
S_NAMES.NEVERFADEBUSH_WAXED = "Fuel-Woven Neverfade Bush"
S_NAMES.NEVERFADEBUSH_ITEM_WAXED = "Fuel-Woven Neverfade Bush"
S______GENERIC.DESCRIBE.NEVERFADEBUSH = {
    --BARREN = "",
    --WITHERED = "",
    GENERIC = "I knew it would never fade!",
    PICKED = "It's regaining the grace of nature.",
    --BURNING = ""
}

S_NAMES.NEVERFADE = "Neverfade" --永不凋零
S_RECIPE_DESC.NEVERFADE = "The power of flowers!"
S______GENERIC.DESCRIBE.NEVERFADE = "Divity... purity... and power!"
--S_______WILLOW.DESCRIBE.NEVERFADE = ""
--S_____WOLFGANG.DESCRIBE.NEVERFADE = ""
S________WENDY.DESCRIBE.NEVERFADE = "It's not love, but it still is eternal..."
--S_________WX78.DESCRIBE.NEVERFADE = ""
--S_WICKERBOTTOM.DESCRIBE.NEVERFADE = ""
--S_______WOODIE.DESCRIBE.NEVERFADE = ""
S______WAXWELL.DESCRIBE.NEVERFADE = "Hm... this is something created by another force in the world."
--S___WATHGRITHR.DESCRIBE.NEVERFADE = ""
--S_______WEBBER.DESCRIBE.NEVERFADE = ""
--S_______WINONA.DESCRIBE.NEVERFADE = ""
S_____WORMWOOD.DESCRIBE.NEVERFADE = "Strong friend."

S_NAMES.BUFF_L_BUTTERFLYBLESS = "Butterfly's Blessings"

S_NAMES.NIGHTROSEBUSH = "Night Rose Bush" --夜玫瑰花丛
S_NAMES.NIGHTROSEBUSH_WAXED = "Fuel-Woven Night Rose Bush"
S_NAMES.NIGHTROSEBUSH_ITEM_WAXED = "Fuel-Woven Night Rose Bush"
S______GENERIC.DESCRIBE.NIGHTROSEBUSH = {
    BARREN = "A little fertilizer can make it return to the shadows.",
    WITHERED = "It's not that special, it's still withered.",
    GENERIC = "It grew in the shadows and became a dark color.",
    PICKED = "Is it making a face at me?",
    BURNING = "The strong flames dispersed the darkness."
}

S_NAMES.DUG_NIGHTROSEBUSH = "Night Rose Bush" --夜玫瑰花丛
S______GENERIC.DESCRIBE.DUG_NIGHTROSEBUSH = "It wants me to plant it in the dark soil."
-- S_______WILLOW.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_____WOLFGANG.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S________WENDY.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_________WX78.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_WICKERBOTTOM.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_______WOODIE.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S______WAXWELL.DESCRIBE.DUG_NIGHTROSEBUSH = ""
S___WATHGRITHR.DESCRIBE.DUG_NIGHTROSEBUSH = "Who dug up the flower bush that the night goddess loves the most!"
S_______WEBBER.DESCRIBE.DUG_NIGHTROSEBUSH = "It looks like it has small eyes looking at me."
-- S_______WINONA.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_______WORTOX.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_____WORMWOOD.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S________WARLY.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_________WURT.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S_______WALTER.DESCRIBE.DUG_NIGHTROSEBUSH = ""
-- S________WANDA.DESCRIBE.DUG_NIGHTROSEBUSH = ""

S_NAMES.CUTTED_NIGHTROSEBUSH = "Night Rose Fruit" --夜玫瑰棘果
S_RECIPE_DESC.CUTTED_NIGHTROSEBUSH = "The favorite of the night goddess in the world garden!"
S______GENERIC.DESCRIBE.CUTTED_NIGHTROSEBUSH = "A fruit of the night rose."
-- S_______WILLOW.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S_____WOLFGANG.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
S________WENDY.DESCRIBE.CUTTED_NIGHTROSEBUSH = "The crystallization of the night."
-- S_________WX78.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S_WICKERBOTTOM.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S_______WOODIE.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S______WAXWELL.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S___WATHGRITHR.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S_______WEBBER.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
S_______WINONA.DESCRIBE.CUTTED_NIGHTROSEBUSH = "Don't get pricked by the fruit."
-- S_______WORTOX.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S_____WORMWOOD.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S________WARLY.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S_________WURT.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S_______WALTER.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""
-- S________WANDA.DESCRIBE.CUTTED_NIGHTROSEBUSH = ""

S_NAMES.SACHET = "Sachet" --香包
S_RECIPE_DESC.SACHET = "Hides your scent."
S______GENERIC.DESCRIBE.SACHET = "Should I smell like flowers?"
--S_______WILLOW.DESCRIBE.SACHET = ""
S_____WOLFGANG.DESCRIBE.SACHET = "To be honest, this is too feminine..."
--S________WENDY.DESCRIBE.SACHET = ""
--S_________WX78.DESCRIBE.SACHET = ""
--S_WICKERBOTTOM.DESCRIBE.SACHET = ""
--S_______WOODIE.DESCRIBE.SACHET = ""
--S______WAXWELL.DESCRIBE.SACHET = ""
--S___WATHGRITHR.DESCRIBE.SACHET = ""
S_______WEBBER.DESCRIBE.SACHET = "Great! We smell sweet!"
--S_______WINONA.DESCRIBE.SACHET = ""
S_____WORMWOOD.DESCRIBE.SACHET = "Friend inside?"

S______GENERIC.ANNOUNCE_PICK_ROSEBUSH = "I wish I could help you."
-- S_______WILLOW.ANNOUNCE_PICK_ROSEBUSH = ""
-- S_____WOLFGANG.ANNOUNCE_PICK_ROSEBUSH = ""
-- S________WENDY.ANNOUNCE_PICK_ROSEBUSH = ""
S_________WX78.ANNOUNCE_PICK_ROSEBUSH = "A DAMAGING PLANT..."
-- S_WICKERBOTTOM.ANNOUNCE_PICK_ROSEBUSH = ""
-- S_______WOODIE.ANNOUNCE_PICK_ROSEBUSH = ""
S______WAXWELL.ANNOUNCE_PICK_ROSEBUSH = "You switched to this body?"
-- S___WATHGRITHR.ANNOUNCE_PICK_ROSEBUSH = ""
-- S_______WEBBER.ANNOUNCE_PICK_ROSEBUSH = ""
S_______WINONA.ANNOUNCE_PICK_ROSEBUSH = "One day I will be with you."
-- S_______WORTOX.ANNOUNCE_PICK_ROSEBUSH = ""
-- S________WARLY.ANNOUNCE_PICK_ROSEBUSH = ""

S_NAMES.FOLIAGEATH = "Foliageath" --青枝绿叶
-- S_RECIPE_DESC.FOLIAGEATH = "Silent foliage, guard fragrance."
S______GENERIC.DESCRIBE.FOLIAGEATH = {
    MERGED = "Seems like I found it's purpose.",
    GENERIC = "Who or what is it waiting for?"
}
-- S_______WILLOW.DESCRIBE.FOLIAGEATH = ""
-- S_____WOLFGANG.DESCRIBE.FOLIAGEATH = ""
-- S________WENDY.DESCRIBE.FOLIAGEATH = ""
-- S_________WX78.DESCRIBE.FOLIAGEATH = ""
-- S_WICKERBOTTOM.DESCRIBE.FOLIAGEATH = ""
-- S_______WOODIE.DESCRIBE.FOLIAGEATH = ""
-- S______WAXWELL.DESCRIBE.FOLIAGEATH = ""
-- S___WATHGRITHR.DESCRIBE.FOLIAGEATH = ""
-- S_______WEBBER.DESCRIBE.FOLIAGEATH = ""
-- S_______WINONA.DESCRIBE.FOLIAGEATH = ""
-- S________WARLY.DESCRIBE.FOLIAGEATH = ""
-- S_______WORTOX.DESCRIBE.FOLIAGEATH = ""
-- S_____WORMWOOD.DESCRIBE.FOLIAGEATH =
-- S_________WURT.DESCRIBE.FOLIAGEATH = ""

--入鞘失败的台词
S______GENERIC.ACTIONFAIL.INTOSHEATH_L = {
    NOSWORD = "I need a sword first!",
    WRONGSWORD = "This is not what the scabbard expected!"
}
-- S_______WILLOW.ACTIONFAIL.INTOSHEATH_L =
-- S_____WOLFGANG.ACTIONFAIL.INTOSHEATH_L =
-- S________WENDY.ACTIONFAIL.INTOSHEATH_L =
-- S_________WX78.ACTIONFAIL.INTOSHEATH_L =
-- S_WICKERBOTTOM.ACTIONFAIL.INTOSHEATH_L =
-- S_______WOODIE.ACTIONFAIL.INTOSHEATH_L =
-- S______WAXWELL.ACTIONFAIL.INTOSHEATH_L =
-- S___WATHGRITHR.ACTIONFAIL.INTOSHEATH_L =
-- S_______WEBBER.ACTIONFAIL.INTOSHEATH_L =
-- S_______WINONA.ACTIONFAIL.INTOSHEATH_L =
-- S_______WORTOX.ACTIONFAIL.INTOSHEATH_L =
-- S_____WORMWOOD.ACTIONFAIL.INTOSHEATH_L =
-- S________WARLY.ACTIONFAIL.INTOSHEATH_L =
-- S_________WURT.ACTIONFAIL.INTOSHEATH_L =
-- S_______WALTER.ACTIONFAIL.INTOSHEATH_L =
-- S________WANDA.ACTIONFAIL.INTOSHEATH_L =

CopyStrActionFail("INTOSHEATH_L2", "INTOSHEATH_L")
CopyStrActionFail("ITEMINTOSHEATH_L", "INTOSHEATH_L")
CopyStrActionFail("ITEMINTOSHEATH_L2", "INTOSHEATH_L")

S_NAMES.FOLIAGEATH_MYLOVE = "Cyan Blades" --青锋剑
S______GENERIC.DESCRIBE.FOLIAGEATH_MYLOVE = "Under these cyan blades, who is hiding the love words."

--------------------------------------------------------------------------
--[[ superb cuisine ]]--[[ 美味佳肴 ]]
--------------------------------------------------------------------------

S_NAMES.PETALS_ROSE = "Rose Petals" --蔷薇花瓣
S______GENERIC.DESCRIBE.PETALS_ROSE = "A rose is a rose, and it blooms for no one but itself."
-- S_______WILLOW.DESCRIBE.PETALS_ROSE = ""
S_____WOLFGANG.DESCRIBE.PETALS_ROSE = "A rose is a rose, just like everybody knows."
S________WENDY.DESCRIBE.PETALS_ROSE = "After the thorns are removed, it becomes just a flower."
-- S_________WX78.DESCRIBE.PETALS_ROSE = ""
-- S_WICKERBOTTOM.DESCRIBE.PETALS_ROSE = ""
-- S_______WOODIE.DESCRIBE.PETALS_ROSE = ""
S______WAXWELL.DESCRIBE.PETALS_ROSE = "Wise men don't believe in roses!"
-- S___WATHGRITHR.DESCRIBE.PETALS_ROSE = ""
-- S_______WEBBER.DESCRIBE.PETALS_ROSE = ""
S_______WINONA.DESCRIBE.PETALS_ROSE = "I believe I will find her."
-- S_______WORTOX.DESCRIBE.PETALS_ROSE = ""
S_____WORMWOOD.DESCRIBE.PETALS_ROSE = "Bright red friend."
-- S________WARLY.DESCRIBE.PETALS_ROSE = ""
-- S_________WURT.DESCRIBE.PETALS_ROSE = ""
-- S_______WALTER.DESCRIBE.PETALS_ROSE = ""
S________WANDA.DESCRIBE.PETALS_ROSE = "Timeless romance."

S_NAMES.PETALS_LILY = "Lily Petals" --蹄莲花瓣
S______GENERIC.DESCRIBE.PETALS_LILY = "Pure yet sorrowful flowers, what am I thinking."
S_______WILLOW.DESCRIBE.PETALS_LILY = "If the ground below us turned to dust, will anyone come to find me?"
-- S_____WOLFGANG.DESCRIBE.PETALS_LILY = ""
S________WENDY.DESCRIBE.PETALS_LILY = "I don't have time to mourn, I only have memories left."
-- S_________WX78.DESCRIBE.PETALS_LILY = ""
S_WICKERBOTTOM.DESCRIBE.PETALS_LILY = "Some slightly poisonous white flowers."
S_______WOODIE.DESCRIBE.PETALS_LILY = "When Lucy was sick in bed, I gave her this kind of flower."
-- S______WAXWELL.DESCRIBE.PETALS_LILY = ""
-- S___WATHGRITHR.DESCRIBE.PETALS_LILY = ""
-- S_______WEBBER.DESCRIBE.PETALS_LILY = ""
-- S_______WINONA.DESCRIBE.PETALS_LILY = ""
S_______WORTOX.DESCRIBE.PETALS_LILY = "A white lie, to make up my bravado."
S_____WORMWOOD.DESCRIBE.PETALS_LILY = "Pure white friend."
-- S________WARLY.DESCRIBE.PETALS_LILY = ""
-- S_________WURT.DESCRIBE.PETALS_LILY = ""
-- S_______WALTER.DESCRIBE.PETALS_LILY = ""
-- S________WANDA.DESCRIBE.PETALS_LILY = ""

S_NAMES.PETALS_ORCHID = "Orchid Petals" --兰草花瓣
S______GENERIC.DESCRIBE.PETALS_ORCHID = "The lingering fragrance of flowers is refreshing to the soul."
-- S_______WILLOW.DESCRIBE.PETALS_ORCHID = ""
-- S_____WOLFGANG.DESCRIBE.PETALS_ORCHID = ""
S________WENDY.DESCRIBE.PETALS_ORCHID = "Living in seclusion is what it pursues."
-- S_________WX78.DESCRIBE.PETALS_ORCHID = ""
-- S_WICKERBOTTOM.DESCRIBE.PETALS_ORCHID = ""
-- S_______WOODIE.DESCRIBE.PETALS_ORCHID = ""
S______WAXWELL.DESCRIBE.PETALS_ORCHID = "This flower doesn't match my high-profile personality."
-- S___WATHGRITHR.DESCRIBE.PETALS_ORCHID = ""
-- S_______WEBBER.DESCRIBE.PETALS_ORCHID = ""
-- S_______WINONA.DESCRIBE.PETALS_ORCHID = ""
S_______WORTOX.DESCRIBE.PETALS_ORCHID = "A gentleman's actions are like orchids."
S_____WORMWOOD.DESCRIBE.PETALS_ORCHID = "Blue and white friend."
-- S________WARLY.DESCRIBE.PETALS_ORCHID = ""
-- S_________WURT.DESCRIBE.PETALS_ORCHID = ""
-- S_______WALTER.DESCRIBE.PETALS_ORCHID = ""
-- S________WANDA.DESCRIBE.PETALS_ORCHID = ""

S_NAMES.PETALS_NIGHTROSE = "Night Rose Petals" --夜玫瑰花瓣
S______GENERIC.DESCRIBE.PETALS_NIGHTROSE = "Blue roses, draped in the color of night."
-- S_______WILLOW.DESCRIBE.PETALS_NIGHTROSE = ""
-- S_____WOLFGANG.DESCRIBE.PETALS_NIGHTROSE = ""
S________WENDY.DESCRIBE.PETALS_NIGHTROSE = "These world weary flowers choose to be beautiful alone at night."
-- S_________WX78.DESCRIBE.PETALS_NIGHTROSE = ""
S_WICKERBOTTOM.DESCRIBE.PETALS_NIGHTROSE = "Rose stained with shadows."
-- S_______WOODIE.DESCRIBE.PETALS_NIGHTROSE = ""
S______WAXWELL.DESCRIBE.PETALS_NIGHTROSE = "It's definitely not the style Charlie likes."
S___WATHGRITHR.DESCRIBE.PETALS_NIGHTROSE = "I want to dedicate them to the night goddess!"
S_______WEBBER.DESCRIBE.PETALS_NIGHTROSE = "That's really cool, with a faint fluorescence."
-- S_______WINONA.DESCRIBE.PETALS_NIGHTROSE = ""
S_______WORTOX.DESCRIBE.PETALS_NIGHTROSE = "The sky will eventually turn dark, and people will eventually part ways."
S_____WORMWOOD.DESCRIBE.PETALS_NIGHTROSE = "Night blue friend."
-- S________WARLY.DESCRIBE.PETALS_NIGHTROSE = ""
-- S_________WURT.DESCRIBE.PETALS_NIGHTROSE = ""
-- S_______WALTER.DESCRIBE.PETALS_NIGHTROSE = ""
-- S________WANDA.DESCRIBE.PETALS_NIGHTROSE = ""

S_NAMES.DISH_CHILLEDROSEJUICE = "Chilled Rose Juice" --蔷薇冰果汁
STRINGS.UI.COOKBOOK.DISH_CHILLEDROSEJUICE = "Plants flower at random"
S______GENERIC.DESCRIBE.DISH_CHILLEDROSEJUICE = "Gives a flowery feeling."
--S_______WILLOW.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S_____WOLFGANG.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S________WENDY.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S_________WX78.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S_______WOODIE.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S______WAXWELL.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S___WATHGRITHR.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S_______WEBBER.DESCRIBE.DISH_CHILLEDROSEJUICE = ""
--S_______WINONA.DESCRIBE.DISH_CHILLEDROSEJUICE = ""

S_NAMES.DISH_TWISTEDROLLLILY = "Twisted Lily Roll" --蹄莲花卷
STRINGS.UI.COOKBOOK.DISH_TWISTEDROLLLILY = "Calls a butterfly at random"
S______GENERIC.DESCRIBE.DISH_TWISTEDROLLLILY = "To be a butterfly, fluttering and dancing in the breeze."
--S_______WILLOW.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S_____WOLFGANG.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S________WENDY.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S_________WX78.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S_______WOODIE.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S______WAXWELL.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S___WATHGRITHR.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S_______WEBBER.DESCRIBE.DISH_TWISTEDROLLLILY = ""
--S_______WINONA.DESCRIBE.DISH_TWISTEDROLLLILY = ""

S_NAMES.DISH_ORCHIDCAKE = "Orchid Cake" --兰花糕
STRINGS.UI.COOKBOOK.DISH_ORCHIDCAKE = "Produces a comfortable temperature"
S______GENERIC.DESCRIBE.DISH_ORCHIDCAKE = "I seemed to hear a quiet voice that calmed me."
--S_______WILLOW.DESCRIBE.DISH_ORCHIDCAKE = ""
--S_____WOLFGANG.DESCRIBE.DISH_ORCHIDCAKE = ""
--S________WENDY.DESCRIBE.DISH_ORCHIDCAKE = ""
--S_________WX78.DESCRIBE.DISH_ORCHIDCAKE = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_ORCHIDCAKE = ""
--S_______WOODIE.DESCRIBE.DISH_ORCHIDCAKE = ""
--S______WAXWELL.DESCRIBE.DISH_ORCHIDCAKE = ""
--S___WATHGRITHR.DESCRIBE.DISH_ORCHIDCAKE = ""
--S_______WEBBER.DESCRIBE.DISH_ORCHIDCAKE = ""
--S_______WINONA.DESCRIBE.DISH_ORCHIDCAKE = ""

S_NAMES.DISH_FLESHNAPOLEON = "Flesh Napoleon" --真果拿破仑
STRINGS.UI.COOKBOOK.DISH_FLESHNAPOLEON = "Gives off a healthy glow steadily"
S______GENERIC.DESCRIBE.DISH_FLESHNAPOLEON = "The brightest star in the night sky is coming!"
--S_______WILLOW.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S_____WOLFGANG.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S________WENDY.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S_________WX78.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S_______WOODIE.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S______WAXWELL.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S___WATHGRITHR.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S_______WEBBER.DESCRIBE.DISH_FLESHNAPOLEON = ""
--S_______WINONA.DESCRIBE.DISH_FLESHNAPOLEON = ""

S_NAMES.BUFF_L_RADIANTSKIN = "Radiant Skin"

S_NAMES.DISH_BEGGINGMEAT = "Begging Meat" --叫花焖肉
STRINGS.UI.COOKBOOK.DISH_BEGGINGMEAT = "Extra hunger in an emergency"
S______GENERIC.DESCRIBE.DISH_BEGGINGMEAT = "For the moment, at least I don't have to beg for survival."
--S_______WILLOW.DESCRIBE.DISH_BEGGINGMEAT = ""
--S_____WOLFGANG.DESCRIBE.DISH_BEGGINGMEAT = ""
--S________WENDY.DESCRIBE.DISH_BEGGINGMEAT = ""
--S_________WX78.DESCRIBE.DISH_BEGGINGMEAT = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_BEGGINGMEAT = ""
--S_______WOODIE.DESCRIBE.DISH_BEGGINGMEAT = ""
--S______WAXWELL.DESCRIBE.DISH_BEGGINGMEAT = ""
--S___WATHGRITHR.DESCRIBE.DISH_BEGGINGMEAT = ""
--S_______WEBBER.DESCRIBE.DISH_BEGGINGMEAT = ""
--S_______WINONA.DESCRIBE.DISH_BEGGINGMEAT = ""

S_NAMES.DISH_FRENCHSNAILSBAKED = "French Snails Baked" --法式焗蜗牛
STRINGS.UI.COOKBOOK.DISH_FRENCHSNAILSBAKED = "Gives it a spark and it'll explode"
S______GENERIC.DESCRIBE.DISH_FRENCHSNAILSBAKED = "I hope there's no fire in my stomach!"
-- S_______WILLOW.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S_____WOLFGANG.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S________WENDY.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S_________WX78.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S_WICKERBOTTOM.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S_______WOODIE.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S______WAXWELL.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S___WATHGRITHR.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S_______WEBBER.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""
-- S_______WINONA.DESCRIBE.DISH_FRENCHSNAILSBAKED = ""

S_NAMES.DISH_NEWORLEANSWINGS = "New Orleans Wings" --新奥尔良烤翅
STRINGS.UI.COOKBOOK.DISH_NEWORLEANSWINGS = "Absorb vibrations"
S______GENERIC.DESCRIBE.DISH_NEWORLEANSWINGS = "Why did I suddenly think of a man in a bat suit?"
--S_______WILLOW.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S_____WOLFGANG.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S________WENDY.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S_________WX78.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S_______WOODIE.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S______WAXWELL.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S___WATHGRITHR.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S_______WEBBER.DESCRIBE.DISH_NEWORLEANSWINGS = ""
--S_______WINONA.DESCRIBE.DISH_NEWORLEANSWINGS = ""

S_NAMES.DISH_FISHJOYRAMEN = "Fishjoy Ramen" --鱼乐拉面
STRINGS.UI.COOKBOOK.DISH_FISHJOYRAMEN = "Accidentally inhale something"
S______GENERIC.DESCRIBE.DISH_FISHJOYRAMEN = "Don't slurp your soup, be polite!"
--S_______WILLOW.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S_____WOLFGANG.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S________WENDY.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S_________WX78.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S_______WOODIE.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S______WAXWELL.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S___WATHGRITHR.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S_______WEBBER.DESCRIBE.DISH_FISHJOYRAMEN = ""
--S_______WINONA.DESCRIBE.DISH_FISHJOYRAMEN = ""

S_NAMES.DISH_ROASTEDMARSHMALLOWS = "Roasted Marshmallows" --烤棉花糖
S______GENERIC.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = "It reminds me of my old days camping with my friends."
--S_______WILLOW.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = ""
--S_____WOLFGANG.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = ""
S________WENDY.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = "Reminding me of my childhood camping with Abigail."
S_________WX78.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = "IT REMINDED ME OF PYRO!"
--S_WICKERBOTTOM.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = ""
S_______WOODIE.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = "I almost forgot, the time I spent camping with Lucy."
--S______WAXWELL.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = ""
--S___WATHGRITHR.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = ""
S_______WEBBER.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = "It reminds us of our childhood camping with our family."
--S_______WINONA.DESCRIBE.DISH_ROASTEDMARSHMALLOWS = ""

S_NAMES.DISH_POMEGRANATEJELLY = "Pomegranate Jelly" --石榴子果冻
S______GENERIC.DESCRIBE.DISH_POMEGRANATEJELLY = "It's children's stuff, I'm not naive any more."
--S_______WILLOW.DESCRIBE.DISH_POMEGRANATEJELLY = ""
--S_____WOLFGANG.DESCRIBE.DISH_POMEGRANATEJELLY = ""
--S________WENDY.DESCRIBE.DISH_POMEGRANATEJELLY = ""
--S_________WX78.DESCRIBE.DISH_POMEGRANATEJELLY = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_POMEGRANATEJELLY = ""
--S_______WOODIE.DESCRIBE.DISH_POMEGRANATEJELLY = ""
--S______WAXWELL.DESCRIBE.DISH_POMEGRANATEJELLY = ""
--S___WATHGRITHR.DESCRIBE.DISH_POMEGRANATEJELLY = ""
S_______WEBBER.DESCRIBE.DISH_POMEGRANATEJELLY = "We like Jellys!"
--S_______WINONA.DESCRIBE.DISH_POMEGRANATEJELLY = ""

S_NAMES.DISH_MEDICINALLIQUOR = "Medicinal Liquor" --药酒
STRINGS.UI.COOKBOOK.DISH_MEDICINALLIQUOR = "Strengthening muscles"
S______GENERIC.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "Maybe you can get drunk after drinking.",
    DRUNK = "I'm not drunk!"
}
S_______WILLOW.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "This can add fire to my strength.",
    DRUNK = "That's it?"
}
S_____WOLFGANG.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "Wolfgang loves drinking.",
    DRUNK = "Wolfgang won't get drunk."
}
S________WENDY.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "I don't want to drink this.",
    DRUNK = "I shouldn't have drunk this."
}
S_________WX78.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "A LIQUID THAT CAN SIMULATE A HANGOVER STATE.",
    DRUNK = "THE HANGOVER STATE IS ON... OH, IT'S OVER IN A MILLISECOND."
}
S_WICKERBOTTOM.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "It has almost no alcohol, but its efficacy can be intoxicating.",
    DRUNK = "I'm starting to get drunk."
}
--S_______WOODIE.DESCRIBE.DISH_MEDICINALLIQUOR =
--S______WAXWELL.DESCRIBE.DISH_MEDICINALLIQUOR =
S___WATHGRITHR.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "Feel no pain! Fight to the death!",
    DRUNK = "Oh, just water!"
}
S_______WEBBER.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "My mom warned me not to drink before.",
    DRUNK = "Mom, We are so sleeeeee..."
}
-- S_______WINONA.DESCRIBE.DISH_MEDICINALLIQUOR =
-- S_______WORTOX.DESCRIBE.DISH_MEDICINALLIQUOR =
S_____WORMWOOD.DESCRIBE.DISH_MEDICINALLIQUOR = {
    GENERIC = "A spicy potion.",
    DRUNK = "Not dizzy at all."
}
-- S________WARLY.DESCRIBE.DISH_MEDICINALLIQUOR =
-- S_________WURT.DESCRIBE.DISH_MEDICINALLIQUOR =
-- S_______WALTER.DESCRIBE.DISH_MEDICINALLIQUOR =
-- S________WANDA.DESCRIBE.DISH_MEDICINALLIQUOR =

S_NAMES.DISH_BANANAMOUSSE = "Banana Mousse" --香蕉慕斯
STRINGS.UI.COOKBOOK.DISH_BANANAMOUSSE = "Stops picky eating"
S______GENERIC.DESCRIBE.DISH_BANANAMOUSSE = "An appetizing dessert. Yummy..."
--S_______WILLOW.DESCRIBE.DISH_BANANAMOUSSE = ""
--S_____WOLFGANG.DESCRIBE.DISH_BANANAMOUSSE = ""
--S________WENDY.DESCRIBE.DISH_BANANAMOUSSE = ""
--S_________WX78.DESCRIBE.DISH_BANANAMOUSSE = ""
--S_WICKERBOTTOM.DESCRIBE.DISH_BANANAMOUSSE = ""
--S_______WOODIE.DESCRIBE.DISH_BANANAMOUSSE = ""
--S______WAXWELL.DESCRIBE.DISH_BANANAMOUSSE = ""
--S___WATHGRITHR.DESCRIBE.DISH_BANANAMOUSSE = ""
--S_______WEBBER.DESCRIBE.DISH_BANANAMOUSSE = ""
--S_______WINONA.DESCRIBE.DISH_BANANAMOUSSE = ""
S________WARLY.DESCRIBE.DISH_BANANAMOUSSE = "If you like, I will also make another banana dessert."

S_NAMES.DISH_RICEDUMPLING = "Rice Dumpling" --金黄香粽
STRINGS.UI.COOKBOOK.DISH_RICEDUMPLING = "Fills your stomach, you'll like it"
S______GENERIC.DESCRIBE.DISH_RICEDUMPLING = "It has a natural smell."
--S_______WILLOW.DESCRIBE.DISH_RICEDUMPLING = ""
--S_____WOLFGANG.DESCRIBE.DISH_RICEDUMPLING = ""
--S________WENDY.DESCRIBE.DISH_RICEDUMPLING = ""
--S_________WX78.DESCRIBE.DISH_RICEDUMPLING = ""
S_WICKERBOTTOM.DESCRIBE.DISH_RICEDUMPLING = "Maybe I should throw it into the river to feed the fish."
--S_______WOODIE.DESCRIBE.DISH_RICEDUMPLING = ""
S______WAXWELL.DESCRIBE.DISH_RICEDUMPLING = "My stomach doesn't feel well when I see this."
--S___WATHGRITHR.DESCRIBE.DISH_RICEDUMPLING = ""
--S_______WEBBER.DESCRIBE.DISH_RICEDUMPLING = ""
--S_______WINONA.DESCRIBE.DISH_RICEDUMPLING = ""

S_NAMES.DISH_DURIANTARTARE = "Durian Tartare"    --怪味鞑靼
STRINGS.UI.COOKBOOK.DISH_DURIANTARTARE = "Gives monsters extra recovery"
S______GENERIC.DESCRIBE.DISH_DURIANTARTARE = "Brutal, bloody and yucky..."
S_______WILLOW.DESCRIBE.DISH_DURIANTARTARE = "What a mess! Needs a fire!"
--S_____WOLFGANG.DESCRIBE.DISH_DURIANTARTARE = "Wolfgang can eat in one bite!"
--S________WENDY.DESCRIBE.DISH_DURIANTARTARE = "I used to eat these with Abigail..."
--S_________WX78.DESCRIBE.DISH_DURIANTARTARE = "STICK ADDON INSTALLED"
S_WICKERBOTTOM.DESCRIBE.DISH_DURIANTARTARE = "Umm... the meat is still raw, and it stinks."
--S_______WOODIE.DESCRIBE.DISH_DURIANTARTARE = "I'd prefer maple taffy..."
--S______WAXWELL.DESCRIBE.DISH_DURIANTARTARE = "Hm... I don't know what I was expecting."
--S___WATHGRITHR.DESCRIBE.DISH_DURIANTARTARE = "I've somehow found a way to make it even LESS appealing!"
S_______WEBBER.DESCRIBE.DISH_DURIANTARTARE = "A lump of raw meat, cool!"
--S_______WINONA.DESCRIBE.DISH_DURIANTARTARE = "Great to cool off after some hard physical labor."
S_______WORTOX.DESCRIBE.DISH_DURIANTARTARE = "Whose flesh is this, a yummy little remnant of it's soul remains."

S_NAMES.DISH_MERRYCHRISTMASSALAD = "Merry Christmas Salad" --圣诞快乐沙拉
STRINGS.UI.COOKBOOK.DISH_MERRYCHRISTMASSALAD = "Produces a gift"
S______GENERIC.DESCRIBE.DISH_MERRYCHRISTMASSALAD = "Look at the Christmas tree, now eat the christmas tree."
-- S_______WILLOW.DESCRIBE.DISH_MERRYCHRISTMASSALAD = ""
S_____WOLFGANG.DESCRIBE.DISH_MERRYCHRISTMASSALAD = "Wolfgang wants a gift Santa Claus, please."
--S________WENDY.DESCRIBE.DISH_MERRYCHRISTMASSALAD = ""
--S_________WX78.DESCRIBE.DISH_MERRYCHRISTMASSALAD = ""
-- S_WICKERBOTTOM.DESCRIBE.DISH_MERRYCHRISTMASSALAD = ""
S_______WOODIE.DESCRIBE.DISH_MERRYCHRISTMASSALAD = "Now I'm not the only one who can eat trees."
--S______WAXWELL.DESCRIBE.DISH_MERRYCHRISTMASSALAD = ""
--S___WATHGRITHR.DESCRIBE.DISH_MERRYCHRISTMASSALAD = ""
S_______WEBBER.DESCRIBE.DISH_MERRYCHRISTMASSALAD = "Should I eat from the star or from the trunk?"
S_______WINONA.DESCRIBE.DISH_MERRYCHRISTMASSALAD = "Merry Christmas! Hah."

S_NAMES.DISH_MURMURANANAS = "Murmur Ananas" --松萝咕咾肉
S______GENERIC.DESCRIBE.DISH_MURMURANANAS = "Sour and sweet meat, I like it!"
-- S_______WILLOW.DESCRIBE.DISH_MURMURANANAS = ""
S_____WOLFGANG.DESCRIBE.DISH_MURMURANANAS = "Wolfgang loves it so much that he wants to eat it again!"
-- S________WENDY.DESCRIBE.DISH_MURMURANANAS = ""
-- S_________WX78.DESCRIBE.DISH_MURMURANANAS = ""
-- S_WICKERBOTTOM.DESCRIBE.DISH_MURMURANANAS = ""
-- S_______WOODIE.DESCRIBE.DISH_MURMURANANAS = ""
S______WAXWELL.DESCRIBE.DISH_MURMURANANAS = "This cuisine will never disappear on the menu of Chinatown restaurants."
-- S___WATHGRITHR.DESCRIBE.DISH_MURMURANANAS = ""
-- S_______WEBBER.DESCRIBE.DISH_MURMURANANAS = ""
-- S_______WINONA.DESCRIBE.DISH_MURMURANANAS = ""
-- S_______WORTOX.DESCRIBE.DISH_MURMURANANAS = ""

S_NAMES.DISH_SHYERRYJAM = "Shyerry Jam" --颤栗果酱
STRINGS.UI.COOKBOOK.DISH_SHYERRYJAM = "Self-healing in moderation"
S______GENERIC.DESCRIBE.DISH_SHYERRYJAM = "I'd love to pour it over scones or make a pie with it."
-- S_______WILLOW.DESCRIBE.DISH_SHYERRYJAM = ""
-- S_____WOLFGANG.DESCRIBE.DISH_SHYERRYJAM = ""
-- S________WENDY.DESCRIBE.DISH_SHYERRYJAM = ""
S_________WX78.DESCRIBE.DISH_SHYERRYJAM = "NO DESSERT, JUST EAT IT DIRECTLY."
-- S_WICKERBOTTOM.DESCRIBE.DISH_SHYERRYJAM = ""
-- S_______WOODIE.DESCRIBE.DISH_SHYERRYJAM = ""
-- S______WAXWELL.DESCRIBE.DISH_SHYERRYJAM = ""
-- S___WATHGRITHR.DESCRIBE.DISH_SHYERRYJAM = ""
-- S_______WEBBER.DESCRIBE.DISH_SHYERRYJAM = ""
-- S_______WINONA.DESCRIBE.DISH_SHYERRYJAM = ""
-- S_______WORTOX.DESCRIBE.DISH_SHYERRYJAM = ""

S_NAMES.BUFF_L_HEALTHSTORAGE = "Health Storage"

S_NAMES.DISH_SUGARLESSTRICKMAKERCUPCAKES = "Sugarless Trickster Cupcakes" --无糖捣蛋鬼纸杯蛋糕
STRINGS.UI.COOKBOOK.DISH_SUGARLESSTRICKMAKERCUPCAKES = "Naughty elves will help you"
S______GENERIC.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "Trick or treat!",
    TRICKED = "Scared me silly.",
    TREAT = "Here's your candy."
}
-- S_______WILLOW.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = ""
S_____WOLFGANG.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "Wolfgang only wants sugar, not to play tricks.",
    TRICKED = "It scared Wolfgang too much.",
    TREAT = "Wolfgang will share the happiness."
}
S________WENDY.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "Maybe I'm too mature to ask for sugar.",
    TRICKED = "Scared me silly.",
    TREAT = "Would Abigail want candy, too?"
}
S_________WX78.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "MY BODY CRAVES DEOXYRIBOSE.",
    TRICKED = "SUDDEN WARNING!",
    TREAT = "I'LL JUST GIVE YOU SOMTHING I DON'T WANT."
}
S_WICKERBOTTOM.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "I believe it's a trick.",
    TRICKED = "That's not allowed in a library!",
    TREAT = "Here's your candy."
}
-- S_______WOODIE.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = ""
-- S______WAXWELL.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = ""
-- S___WATHGRITHR.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = ""
S_______WEBBER.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "We just want sweety sugar and candy!",
    TRICKED = "You made everyone laugh.",
    TREAT = "We're the ones who want the sugar."
}
-- S_______WINONA.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = ""
S_______WORTOX.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "Hey, don't steal my thunder!!!",
    TRICKED = "Hah, small trick.",
    TREAT = "What if I don't give sugar."
}
S_____WORMWOOD.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "Nectar, please?",
    TRICKED = "It made my leaves tremble.",
    TREAT = "Is today the pollination day?"
}
S________WARLY.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = {
    GENERIC = "What a timely snack!",
    TRICKED = "It made my pot shake.",
    TREAT = "This chef is going to treat the guests well."
}
-- S_________WURT.DESCRIBE.DISH_SUGARLESSTRICKMAKERCUPCAKES = ""

S_NAMES.BUFF_L_PANICVOLCANO = "Troubler Scare"

S_NAMES.DISH_L_MOONCAKE = "Moon Cake" --月饼
STRINGS.UI.COOKBOOK.DISH_L_MOONCAKE = "Using moonlight to protect oneself"
S______GENERIC.DESCRIBE.DISH_L_MOONCAKE = "The missing in the cake makes me fearless of darkness."
-- S_______WILLOW.DESCRIBE.DISH_L_MOONCAKE = ""
-- S_____WOLFGANG.DESCRIBE.DISH_L_MOONCAKE = ""
S________WENDY.DESCRIBE.DISH_L_MOONCAKE = "Abigail, enjoy the moon with me!"
S_________WX78.DESCRIBE.DISH_L_MOONCAKE = "IS THIS...? THE EMOTIONAL COMPONENT IS UNRESPONSIVE."
-- S_WICKERBOTTOM.DESCRIBE.DISH_L_MOONCAKE = ""
-- S_______WOODIE.DESCRIBE.DISH_L_MOONCAKE = ""
S______WAXWELL.DESCRIBE.DISH_L_MOONCAKE = "I just want to make it all right, Charlie."
S___WATHGRITHR.DESCRIBE.DISH_L_MOONCAKE = "It has been immersed in the strong missing of the Moon Goddess."
S_______WEBBER.DESCRIBE.DISH_L_MOONCAKE = "Recalling happy moments, let us no longer fear."
-- S_______WINONA.DESCRIBE.DISH_L_MOONCAKE = ""
S_______WORTOX.DESCRIBE.DISH_L_MOONCAKE = "No matter where we are, we can always look at the moon and miss our loved ones."
S_____WORMWOOD.DESCRIBE.DISH_L_MOONCAKE = "It expresses the missing of friends."
S________WARLY.DESCRIBE.DISH_L_MOONCAKE = "A Chinese cake that sets off a strong festive atmosphere."
S_________WURT.DESCRIBE.DISH_L_MOONCAKE = "Curse makes me forget, forgetting makes me irritable."
-- S_______WALTER.DESCRIBE.DISH_L_MOONCAKE = ""
S________WANDA.DESCRIBE.DISH_L_MOONCAKE = "Everything I am familiar with passes away with time, and I cannot forget it."

S_NAMES.DISH_L_FLOWERBUN = "Flower Bun" --花儿粑
STRINGS.UI.COOKBOOK.DISH_L_FLOWERBUN = "Borrowing moonlight to protect oneself"
S______GENERIC.DESCRIBE.DISH_L_FLOWERBUN = "Fragrant bun!"
-- S_______WILLOW.DESCRIBE.DISH_L_FLOWERBUN = ""
-- S_____WOLFGANG.DESCRIBE.DISH_L_FLOWERBUN = ""
-- S________WENDY.DESCRIBE.DISH_L_FLOWERBUN = ""
-- S_________WX78.DESCRIBE.DISH_L_FLOWERBUN = ""
-- S_WICKERBOTTOM.DESCRIBE.DISH_L_FLOWERBUN = ""
S_______WOODIE.DESCRIBE.DISH_L_FLOWERBUN = "There is a familiar smell of madness inside."
S______WAXWELL.DESCRIBE.DISH_L_FLOWERBUN = "This food has been influenced by the moon."
S___WATHGRITHR.DESCRIBE.DISH_L_FLOWERBUN = "The cate has been blessed by the Moon Goddess."
-- S_______WEBBER.DESCRIBE.DISH_L_FLOWERBUN = ""
-- S_______WINONA.DESCRIBE.DISH_L_FLOWERBUN = ""
S_______WORTOX.DESCRIBE.DISH_L_FLOWERBUN = "It reminds me of the tranquility of wind, flowers, snow, and moon."
S_____WORMWOOD.DESCRIBE.DISH_L_FLOWERBUN = "It smells good."
S________WARLY.DESCRIBE.DISH_L_FLOWERBUN = "When steaming it, moonlight shines on it."
S_________WURT.DESCRIBE.DISH_L_FLOWERBUN = "Glorph! I really like the floral flavor."
-- S_______WALTER.DESCRIBE.DISH_L_FLOWERBUN = ""
-- S________WANDA.DESCRIBE.DISH_L_FLOWERBUN = ""

S_NAMES.BUFF_L_PLANARDEFENSE = "Stable Planar"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = "My body... has developed resistance to Planar."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_PLANARDEFENSE = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = "My body is no longer stable in Planar waves."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_PLANARDEFENSE = ""

S_NAMES.BUFF_L_PLANARATTACK = "Undulant Planar"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = "My body... exudes a power of Planar."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = "A bit of Planar power! I must have been blessed."
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_PLANARATTACK = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = "Planar power has dried up in the body."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_PLANARATTACK = ""

S_NAMES.BUFF_L_LUNARRESIST = "Lunar Resist"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = "My body... can withstand the damage of the moon."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = "The Moon Goddess will bear the damage from the moon for me!"
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_LUNARRESIST = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = "My body will be exposed in the moonlight."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = "The Moon Goddess no longer illuminates me."
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_LUNARRESIST = ""

S_NAMES.BUFF_L_SHADOWRESIST = "Shadow Resist"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = "My body... can withstand the damage of the shadow."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = "The night goddess will bear the damage from the darkness for me!"
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_SHADOWRESIST = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = "My body will be shrouded in darkness."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = "The night goddess no longer protects me."
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_SHADOWRESIST = ""

S_NAMES.BUFF_L_DISSIPATESHADOW = "Dissipate Shadow"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = "Moon, help me dispel darkness!"
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = "The Moon Goddess will fight against darkness with me!"
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_DISSIPATESHADOW = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = "The moonlight in my hand dimmed."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = "The Moon Goddess has left, and darkness is about to strike."
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_DISSIPATESHADOW = ""

S_NAMES.BUFF_L_DIMMOONLIGHT = "Dim Moonlight"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = "Shadow, cover the moon for me!"
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = "The night goddess will fight against the moon with me!"
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_DIMMOONLIGHT = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = "The shadow in my hand became clear."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = "The night goddess disappeared, and the moonlight shone again."
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_DIMMOONLIGHT = ""

S_NAMES.DISH_FAREWELLCUPCAKE = "Farewell Cupcake" --临别的纸杯蛋糕
STRINGS.UI.COOKBOOK.DISH_FAREWELLCUPCAKE = "Say goodbye to my life"
S______GENERIC.DESCRIBE.DISH_FAREWELLCUPCAKE = "So easy to be careless, but takes courage to care."
-- S_______WILLOW.DESCRIBE.DISH_FAREWELLCUPCAKE = ""
-- S_____WOLFGANG.DESCRIBE.DISH_FAREWELLCUPCAKE = ""
S________WENDY.DESCRIBE.DISH_FAREWELLCUPCAKE = "Failures, let everyone down, including ourselves."
-- S_________WX78.DESCRIBE.DISH_FAREWELLCUPCAKE = ""
S_WICKERBOTTOM.DESCRIBE.DISH_FAREWELLCUPCAKE = "Unfortunately, some lack the self-awareness to not make this decision."
S_______WOODIE.DESCRIBE.DISH_FAREWELLCUPCAKE = "People are alienated from each other with a broken heart."
S______WAXWELL.DESCRIBE.DISH_FAREWELLCUPCAKE = "My life is not worth mentioning."
S___WATHGRITHR.DESCRIBE.DISH_FAREWELLCUPCAKE = "Don't you have enough?"
S_______WEBBER.DESCRIBE.DISH_FAREWELLCUPCAKE = "It's not my decision to make, we have to decide together."
-- S_______WINONA.DESCRIBE.DISH_FAREWELLCUPCAKE = ""
S_______WORTOX.DESCRIBE.DISH_FAREWELLCUPCAKE = "Sorry, it may be painful to be alive but I'm not done yet."
-- S_____WORMWOOD.DESCRIBE.DISH_FAREWELLCUPCAKE = ""
-- S________WARLY.DESCRIBE.DISH_FAREWELLCUPCAKE = ""
S_________WURT.DESCRIBE.DISH_FAREWELLCUPCAKE = "To deliberately believe in lies while knowing their false."
-- S_______WALTER.DESCRIBE.DISH_FAREWELLCUPCAKE = ""

S_NAMES.DISH_BRAISEDMEATWITHFOLIAGES = "Braised Meat With Foliages" --蕨叶扣肉
S______GENERIC.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = "Looks so greasy, just one piece of meat, please."
-- S_______WILLOW.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
S_____WOLFGANG.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = "Wolfgang loves it!"
-- S________WENDY.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S_________WX78.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S_WICKERBOTTOM.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
S_______WOODIE.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = "It goes well with rice."
-- S______WAXWELL.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S___WATHGRITHR.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S_______WEBBER.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S_______WINONA.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S_______WORTOX.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S_____WORMWOOD.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
S________WARLY.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = "It's not easy to make fat meat not greasy."
-- S_________WURT.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""
-- S_______WALTER.DESCRIBE.DISH_BRAISEDMEATWITHFOLIAGES = ""

S_NAMES.DISH_WRAPPEDSHRIMPPASTE = "Wrapped Mushrimp" --白菇虾滑卷
STRINGS.UI.COOKBOOK.DISH_WRAPPEDSHRIMPPASTE = "Enhances resistance"
S______GENERIC.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = "Great! The outer layer locks well the shrimp essence."
-- S_______WILLOW.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
-- S_____WOLFGANG.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
-- S________WENDY.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
-- S_________WX78.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
-- S_WICKERBOTTOM.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
S_______WOODIE.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = "So delicious. Can I have the wooden dish, too?"
-- S______WAXWELL.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
-- S___WATHGRITHR.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
-- S_______WEBBER.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
S_______WINONA.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = "A smooth and delicate taste, it's just not me."
-- S_______WORTOX.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""
S_____WORMWOOD.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = "Beautiful friend, making a beautiful meal."
S________WARLY.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = "Ah, the mushroom, the shrimp, my life has reached the peak!"
S_________WURT.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = "It's cruel, glort."
-- S_______WALTER.DESCRIBE.DISH_WRAPPEDSHRIMPPASTE = ""

S_NAMES.DISH_SOSWEETJARKFRUIT = "So Sweet Jarkfruit" --甜到裂开的松萝蜜
S______GENERIC.DESCRIBE.DISH_SOSWEETJARKFRUIT = "It was so sweet that I got flustered."
S_______WILLOW.DESCRIBE.DISH_SOSWEETJARKFRUIT = "Too sweet, chef."
-- S_____WOLFGANG.DESCRIBE.DISH_SOSWEETJARKFRUIT = ""
S________WENDY.DESCRIBE.DISH_SOSWEETJARKFRUIT = "There's two of them, one for me and one for Abigail."
S_________WX78.DESCRIBE.DISH_SOSWEETJARKFRUIT = "FUEL DETECTION: EXCESSIVE HEAT."
S_WICKERBOTTOM.DESCRIBE.DISH_SOSWEETJARKFRUIT = "I shouldn't eat such unhealthy food."
-- S_______WOODIE.DESCRIBE.DISH_SOSWEETJARKFRUIT = ""
-- S______WAXWELL.DESCRIBE.DISH_SOSWEETJARKFRUIT = ""
-- S___WATHGRITHR.DESCRIBE.DISH_SOSWEETJARKFRUIT = ""
S_______WEBBER.DESCRIBE.DISH_SOSWEETJARKFRUIT = "So sweet, I'm in heaven!"
S_______WINONA.DESCRIBE.DISH_SOSWEETJARKFRUIT = "Did no one notice a crack in the bottle?"
S_______WORTOX.DESCRIBE.DISH_SOSWEETJARKFRUIT = "Love is to sugar, as sweet is to sadness."
S_____WORMWOOD.DESCRIBE.DISH_SOSWEETJARKFRUIT = "Crack!"
S________WARLY.DESCRIBE.DISH_SOSWEETJARKFRUIT = "I have an appointment with a sweet lady."
-- S_________WURT.DESCRIBE.DISH_SOSWEETJARKFRUIT = ""
S_______WALTER.DESCRIBE.DISH_SOSWEETJARKFRUIT = "Not a perfect dish because it's cracked."

S_NAMES.DISH_FRIEDFISHWITHPUREE = "Fried Fish With Puree" --果泥香煎鱼
STRINGS.UI.COOKBOOK.DISH_FRIEDFISHWITHPUREE = "Can't stop the flow"
S______GENERIC.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "So crisp, so luscious, so nice!"
S_______WILLOW.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "The flame makes it look good."
S_____WOLFGANG.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "Delicious is best."
-- S________WENDY.DESCRIBE.DISH_FRIEDFISHWITHPUREE = ""
-- S_________WX78.DESCRIBE.DISH_FRIEDFISHWITHPUREE = ""
S_WICKERBOTTOM.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "Honestly, the fish looks suspicious."
S_______WOODIE.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "I want to finish it quickly, I have work to do."
-- S______WAXWELL.DESCRIBE.DISH_FRIEDFISHWITHPUREE = ""
S___WATHGRITHR.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "Why not try it."
-- S_______WEBBER.DESCRIBE.DISH_FRIEDFISHWITHPUREE = ""
-- S_______WINONA.DESCRIBE.DISH_FRIEDFISHWITHPUREE = ""
S_______WORTOX.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "Hmm, this seems like a trick. Kind of funny."
-- S_____WORMWOOD.DESCRIBE.DISH_FRIEDFISHWITHPUREE = ""
S________WARLY.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "With years of cooking experience, I emplore you to not eat it!"
S_________WURT.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "Those who eat fish will be punished by it."
-- S_______WALTER.DESCRIBE.DISH_FRIEDFISHWITHPUREE = ""
S________WANDA.DESCRIBE.DISH_FRIEDFISHWITHPUREE = "Haha, not only your time is passing."

S_NAMES.BUFF_L_BATDISGUISE = "Bat Disguise" --buff本身是不需要名字的，为了兼容能力勋章的buff显示而写的
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = "I won't be detected by bats for now."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = "Bat ultrasound cannot recognize me."
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = "We are pretending to be bats."
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = "Make friends with bats."
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_BATDISGUISE = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = "Bats will eventually be my enemy."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = "Now I can't confuse bats anymore."
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = "The bat disguise is over."
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = "I can't be friends with bats."
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_BATDISGUISE = ""

S_NAMES.BUFF_L_BESTAPPETITE = "Best Appetite"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = "Suddenly, I want to have a big meal."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_BESTAPPETITE = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = "My appetite has returned to normal."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_BESTAPPETITE = ""

S_NAMES.BUFF_L_HUNGERRETARDER = "Feeling Full"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = "No appetite at all."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = "This food boosts my satiety."
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = "Not good for my old stomach."
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = "The less hungry you are, the better you can work."
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_HUNGERRETARDER = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = "Good luck comes when you have an appetite."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = "Hunger returns to normal."
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = "My stomach feels better at last."
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
S_______WINONA.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = "Even if you're hungry, you have to keep working."
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_HUNGERRETARDER = ""

S_NAMES.BUFF_L_HOLDBACKPOOP = "Hold Back Poop"

S_NAMES.BUFF_L_STRENGTHENHANCER = "Strength Up"
-- S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_STRENGTHENHANCER = "" --属于药酒的buff，但是药酒已经会让玩家说话了，所以这里不再重复说
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "The power enhancement effect has faded."
S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "The burning of muscles is over."
S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "Wolfgang felt the disappearance of brute force."
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = ""
S_________WX78.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "OVERLOAD OPERATION IS OVER."
S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "The power gained by a shortcut doesn't last long after all."
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = ""
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "This power dissipated after all."
S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "Our little hands have become weak again."
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = ""
S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "I wish my strength could've lasted 10000 years."
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = ""
S________WARLY.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "Extra power has been completely digested."
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = ""
S________WANDA.ANNOUNCE_DETACH_BUFF_L_STRENGTHENHANCER = "I should go back and regain my strength."

S_NAMES.BUFF_L_OILFLOW = "Oil Diarrhea"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "Seems nothing happened."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = ""
S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "Wolfgang want to go to the bathroom."
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = ""
S_________WX78.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "UNKNOWN LEAK IN FUEL SYSTEM!"
S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "I think I'll need adult diapers."
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = ""
S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "I have a bad feeling in my stomach."
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = ""
S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "Stomach is going to cry, but we can't cry."
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = ""
S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "A self mischief is coming."
S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "Come on!"
S________WARLY.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "Is that how curious I am?"
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = ""
S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "Walter has to be adventurous."
S________WANDA.ANNOUNCE_ATTACH_BUFF_L_OILFLOW = "There is no going back!"
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Oh, finally, now I just want to find a hole to hide in."
S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "I don't want to talk to anyone right now!"
S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Wolfgang is finished."
S________WENDY.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Do you think this will happen to me?"
S_________WX78.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "FUEL SYSTEM HAS BEEN REPAIRED."
S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Fortunately, no one saw it. There's no shame."
S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "It should be used. We can't waste it."
S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Where is my dignity?!"
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "This has nothing to do with the glory of fighter."
S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Oh, that's too bad. I'll be scolded by mom."
S_______WINONA.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "It's over. There's a lot to clean up."
S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Amazing, I feel like my soul was about to be pulled out."
S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "A wonderful experience."
S________WARLY.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "Curiosity killed the cat."
S_________WURT.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "So funny, I used to have beefalos that did this."
S_______WALTER.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "This will be a stain on my life."
S________WANDA.ANNOUNCE_DETACH_BUFF_L_OILFLOW = "I regret it, truely."
--
S______GENERIC.BUFF_L_OILFLOW = {
    "OMG...", "...", "... ...", "......", "This is embarrassing.", "Don't look at me.", "Oh, no!",
    "When does it stop?", "Am I having a nightmare?", "Crazy...", "Stop!", "No...", "Where is the toilet?!",
    "I just want to die.", "No.", "Stop, stop, stop!", "This...", "I'm collapsing.", "No!", "...!",
    "I'm so sorry.", "Sorry...", "Sorry!", "Ah...",
}
-- S_______WILLOW.BUFF_L_OILFLOW = ""
-- S_____WOLFGANG.BUFF_L_OILFLOW = ""
-- S________WENDY.BUFF_L_OILFLOW = ""
-- S_________WX78.BUFF_L_OILFLOW = ""
S_WICKERBOTTOM.BUFF_L_OILFLOW = {
    "I knew it.", "Something was wrong with that dish.", "Where's the bathroom.", "No!", "...!", "...", "... ...",
    "No...", "This...", "Don't look at me, don't look at me...", "Learn from my mistakes.", "I can't bear it.", "......",
    "I'm not old enough for this to be happening to me.", "Nature calls...", "Maybe we can look at this like medicine...", "I think I know why...",
    "Chill, lady!", "It's no big deal.", "Why do I have to suffer so much?", "This moment is devoid of elegance.",
}
-- S_______WOODIE.BUFF_L_OILFLOW = ""
S______WAXWELL.BUFF_L_OILFLOW = {
    "I knew it.", "Something was wrong with that food.", "There's no bathroom.", "No!", "...!", "...", "... ...",
    "No...", "This...", "Don't look at me, don't look at me...", "Learn from my mistakes.", "I can't bear it.", "......",
    "I'm not old enough for this to be happening to me.", "Nature calls...", "What can I do?!", "I think I know why...",
    "Calm down!", "It's no big deal.", "What a disgrace!", "Why do I have to suffer so much?",
    "This moment is devoid of class.",
}
-- S___WATHGRITHR.BUFF_L_OILFLOW = ""
-- S_______WEBBER.BUFF_L_OILFLOW = ""
-- S_______WINONA.BUFF_L_OILFLOW = ""
S_______WORTOX.BUFF_L_OILFLOW = {
    "Hello, little thing. Heh.", "Oh well.", "What are you looking at?!", "Hello!", "...!", "...", "... ...", "......",
    "No...", "This...", "Hi...", "Hmm.", "Well...", "Well.", "What a vulgar prank!", "Funny!",
    "Not funny at all.", "Haha, haha, so embarrassing.", "Embarrassing.", "Excuse me, where is the bathroom?",
    "Hmm...", "I'm doing good for the lawn.", "Hey! There's nothing.", "A careless person would be sad.",
    "I should slip away.", "Sorry...", "Go away! Haven't you seen a demon poop?",
}
S_____WORMWOOD.BUFF_L_OILFLOW = {
    "Strange.", "But it's good.", "Not bad for me.", "Can't stop?", "...", "... ...", "......", "Haha.", "This...",
    "Now my friends have something good.", "Great.", "I'm getting hungry.", "Ah...", "Not bad.", "Interesting.",
}
-- S________WARLY.BUFF_L_OILFLOW = ""
-- S_________WURT.BUFF_L_OILFLOW = ""
-- S_______WALTER.BUFF_L_OILFLOW = ""
-- S________WANDA.BUFF_L_OILFLOW = ""

S_NAMES.DISH_TOMAHAWKSTEAK = "Steak Tomahawk" --牛排战斧
STRINGS.UI.COOKBOOK.DISH_TOMAHAWKSTEAK = "Favorite axe of the king of one-upmanship"
S______GENERIC.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "Would anyone like a steak that was fried hard and brown?",
    CHOP = "Cut it down!",
    ATK = "Come and fight!",
}
S_______WILLOW.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "What kind of idiot wastes food to make such things!",
    CHOP = "Take my hits!",
    ATK = "One-on-one is the real deal!",
}
S_____WOLFGANG.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "It's not edible, unfortunately.",
    CHOP = "The force of Wolfgang's axe is great!",
    ATK = "Wolfgang is an undefeated one-on-one legend!",
}
-- S________WENDY.DESCRIBE.DISH_TOMAHAWKSTEAK = ""
-- S_________WX78.DESCRIBE.DISH_TOMAHAWKSTEAK = ""
S_WICKERBOTTOM.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "A special fragrance and perhaps a surprising function.",
    CHOP = "Just cut at the perfect angle.",
    ATK = "We can have a battle of wits!",
}
S_______WOODIE.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "Nature's favorite, meat-scented axe.",
    CHOP = "A treeless world is about to be reached.",
    ATK = "Other troublemakers leave me be!",
}
-- S______WAXWELL.DESCRIBE.DISH_TOMAHAWKSTEAK = ""
S___WATHGRITHR.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "I already expected the enemy to fight me with drooling mouths.",
    CHOP = "I am invincible, er, in terms of chopping.",
    ATK = "A showdown that's all about you and me!",
}
-- S_______WEBBER.DESCRIBE.DISH_TOMAHAWKSTEAK = ""
S_______WINONA.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "An axe that cannot be used as a gourmet food is not a good weapon.",
    CHOP = "Not bad for meat!",
    ATK = "How about a fair match?",
}
S_______WORTOX.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "The allure of food.",
    CHOP = "No matter how thick the trunk it will fall to my crispy axe!",
    ATK = "I have unilaterally issued a challenge to you!",
}
S_____WORMWOOD.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "Fragrance, ah no, bad bad!",
    CHOP = "Gently, without pain.",
    ATK = "Come, come, come!",
}
S________WARLY.DESCRIBE.DISH_TOMAHAWKSTEAK = {
    GENERIC = "A challenge to the natural taste buds.",
    CHOP = "As easy as chopping vegetables.",
    ATK = "Have you eaten? If not, eat my axe!",
}
-- S_________WURT.DESCRIBE.DISH_TOMAHAWKSTEAK = ""
-- S_______WALTER.DESCRIBE.DISH_TOMAHAWKSTEAK = ""
-- S________WANDA.DESCRIBE.DISH_TOMAHAWKSTEAK = ""

S_NAMES.DISH_LOVINGROSECAKE = "Loving Rose Shortcake" --倾心玫瑰酥
STRINGS.UI.COOKBOOK.DISH_LOVINGROSECAKE = "Build love with heart"
S______GENERIC.DESCRIBE.DISH_LOVINGROSECAKE = "Be sure to let someone I love taste it in person!"
S_______WILLOW.DESCRIBE.DISH_LOVINGROSECAKE = "Fire is not the only thing that gets me."
-- S_____WOLFGANG.DESCRIBE.DISH_LOVINGROSECAKE = ""
S________WENDY.DESCRIBE.DISH_LOVINGROSECAKE = "Inexplicable feelings, who will take it away?"
-- S_________WX78.DESCRIBE.DISH_LOVINGROSECAKE = ""
S_WICKERBOTTOM.DESCRIBE.DISH_LOVINGROSECAKE = "There is something to do, to love, to expect."
S_______WOODIE.DESCRIBE.DISH_LOVINGROSECAKE = "I would give it to Lucy, but she only eats wood."
S______WAXWELL.DESCRIBE.DISH_LOVINGROSECAKE = "A love trick for children."
-- S___WATHGRITHR.DESCRIBE.DISH_LOVINGROSECAKE = ""
S_______WEBBER.DESCRIBE.DISH_LOVINGROSECAKE = "It would be great to have someone play with me."
-- S_______WINONA.DESCRIBE.DISH_LOVINGROSECAKE = ""
S_______WORTOX.DESCRIBE.DISH_LOVINGROSECAKE = "Where there is love, theres always wishes."
S_____WORMWOOD.DESCRIBE.DISH_LOVINGROSECAKE = "I don't understand it, but it's delicious!"
S________WARLY.DESCRIBE.DISH_LOVINGROSECAKE = "It's better to share it with your lover rather than eat it yourself."
-- S_________WURT.DESCRIBE.DISH_LOVINGROSECAKE = ""
-- S_______WALTER.DESCRIBE.DISH_LOVINGROSECAKE = ""
S________WANDA.DESCRIBE.DISH_LOVINGROSECAKE = "I don't have the time so I can only enjoy myself."

S_NAMES.DISH_MUSHEDEGGS = "Double-Mushed Eggs" --双菇烩蛋
STRINGS.UI.COOKBOOK.DISH_MUSHEDEGGS = "Effort will pay off"
S______GENERIC.DESCRIBE.DISH_MUSHEDEGGS = "Tasting it will bring good things to happen, really?"
S_______WILLOW.DESCRIBE.DISH_MUSHEDEGGS = "The benefits of cooking fire."
S_____WOLFGANG.DESCRIBE.DISH_MUSHEDEGGS = "Wolfgang's good days are coming!"
S________WENDY.DESCRIBE.DISH_MUSHEDEGGS = "It is as persistent as me."
S_________WX78.DESCRIBE.DISH_MUSHEDEGGS = "IS THIS SCIENTIFIC STATISTICS OR MAGIC? I CAN'T ANALYZE IT."
S_WICKERBOTTOM.DESCRIBE.DISH_MUSHEDEGGS = "Magical cuisine with some statistical logic, interesting!"
S_______WOODIE.DESCRIBE.DISH_MUSHEDEGGS = "This is to keep me persevering and doing it."
S______WAXWELL.DESCRIBE.DISH_MUSHEDEGGS = "If I could retrieve my previous magic, I wouldn't even need this."
S___WATHGRITHR.DESCRIBE.DISH_MUSHEDEGGS = "Luck is a part of your strength."
S_______WEBBER.DESCRIBE.DISH_MUSHEDEGGS = "Try more, we can get the toys we want!"
S_______WINONA.DESCRIBE.DISH_MUSHEDEGGS = "This is a great encouragement for hardworking people!"
S_______WORTOX.DESCRIBE.DISH_MUSHEDEGGS = "These ingredients I struggled to find will give me lucky magic."
S_____WORMWOOD.DESCRIBE.DISH_MUSHEDEGGS = "Is there any lucky poop?"
S________WARLY.DESCRIBE.DISH_MUSHEDEGGS = "Magical cuisine not only fills the stomach, but also brings good luck."
S_________WURT.DESCRIBE.DISH_MUSHEDEGGS = "Getting along with Mermfolk needs some luck, florp."
S_______WALTER.DESCRIBE.DISH_MUSHEDEGGS = "With it, I can complete any collection task!"
S________WANDA.DESCRIBE.DISH_MUSHEDEGGS = "Good luck can help me reduce my dependence on time."

S_NAMES.DISH_MUSHEDKOI = "Double-Mushed Koi" --菌鱼双鲜堡
CopyStrDescribe("DISH_MUSHEDKOI", "DISH_MUSHEDEGGS")

S_NAMES.DISH_MUSHEDMILK = "Double-Mushed Milk" --香蕈双峰
CopyStrDescribe("DISH_MUSHEDMILK", "DISH_MUSHEDEGGS")

S_NAMES.BUFF_L_EFFORTLUCK = "Effort Luck"
S______GENERIC.ANNOUNCE_BUFF_L_EFFORTLUCK = {
    ATTACH = "My luck is up! There are {luck} lucky points.",
    COST = "Good luck time! {luck} lucky points left.",
    DETACH = "Looking forward to good luck next time!",
    CHECK = "Hah. I still have {luck} lucky points."
}
-- S_______WILLOW.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
-- S_____WOLFGANG.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
S________WENDY.ANNOUNCE_BUFF_L_EFFORTLUCK = {
    ATTACH = "Sometimes stubbornness can bring good luck. {luck} lucky points.",
    COST = "Fate brings good news! Luck remaining {luck}.",
    DETACH = "Good luck is short-lived.",
    CHECK = "Current {luck} luck, but it may be different in the future."
}
-- S_________WX78.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
S_WICKERBOTTOM.ANNOUNCE_BUFF_L_EFFORTLUCK = {
    ATTACH = "Fortune doesn't favor fools. I have {luck} lucky points.",
    COST = "Take fortune when it comes. {luck} lucky points left.",
    DETACH = "My luck has run out.",
    CHECK = "Sure, I have {luck} lucky points."
}
-- S_______WOODIE.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
-- S______WAXWELL.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
-- S___WATHGRITHR.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
S_______WEBBER.ANNOUNCE_BUFF_L_EFFORTLUCK = {
    ATTACH = "We are about to have new toys! We have {luck} luck.",
    COST = "Okay! Got it. {luck} luck left.",
    DETACH = "Out of luck. We haven't had enough fun yet.",
    CHECK = "How amusing! We have {luck} luck."
}
S_______WINONA.ANNOUNCE_BUFF_L_EFFORTLUCK = {
    ATTACH = "Diligence redeems stupidity. There are {luck} lucky points.",
    COST = "Aha! I still have {luck} lucky points left.",
    DETACH = "Without luck, I will continue to work diligently!",
    CHECK = "There are {luck} lucky points."
}
-- S_______WORTOX.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
S_____WORMWOOD.ANNOUNCE_BUFF_L_EFFORTLUCK = {
    ATTACH = "Lucky break. {luck} luck.",
    COST = "Great! {luck} luck left.",
    DETACH = "Luck is gone.",
    CHECK = "{luck} luck."
}
-- S________WARLY.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
-- S_________WURT.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
-- S_______WALTER.ANNOUNCE_BUFF_L_EFFORTLUCK = ""
-- S________WANDA.ANNOUNCE_BUFF_L_EFFORTLUCK = ""

S_NAMES.BUFF_L_GOLDENLOOT = "Golden Loot"
S_NAMES.BUFF_L_GOLDENLOOT_INF = "Infinite Golden Loot"

S_NAMES.BUFF_L_MERCIFUL = "Mercy"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = "I suddenly feel that the enemies are all very pitiful."
S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = "I have lost my temper, only mercy."
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
S________WENDY.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = "Will they feel better if I apologize?"
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_MERCIFUL = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = "I have no mercy towards the enemy!"
S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = "My anger is burning again!"
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
S________WENDY.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = "There is nothing left, no mercy!"
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_MERCIFUL = ""

S_NAMES.DISH_BEANCONGEE = "Cold Bean Congee" --清豆粥
STRINGS.UI.COOKBOOK.DISH_BEANCONGEE = "Quickly cools the body"
S______GENERIC.DESCRIBE.DISH_BEANCONGEE = "Cold beans, mild Congee."
S_______WILLOW.DESCRIBE.DISH_BEANCONGEE = "Because of it, my appetite has cooled down too much."
-- S_____WOLFGANG.DESCRIBE.DISH_BEANCONGEE = ""
S________WENDY.DESCRIBE.DISH_BEANCONGEE = "Like my fleeting and eternal emotions."
-- S_________WX78.DESCRIBE.DISH_BEANCONGEE = ""
S_WICKERBOTTOM.DESCRIBE.DISH_BEANCONGEE = "Some substances in congee become blue due to oxidation."
S_______WOODIE.DESCRIBE.DISH_BEANCONGEE = "People who do physical labor cannot just eat this."
S______WAXWELL.DESCRIBE.DISH_BEANCONGEE = "The taste is light, but it doesn't require much chewing."
S___WATHGRITHR.DESCRIBE.DISH_BEANCONGEE = "The taste is bland, I never eat it."
-- S_______WEBBER.DESCRIBE.DISH_BEANCONGEE = ""
-- S_______WINONA.DESCRIBE.DISH_BEANCONGEE = ""
S_______WORTOX.DESCRIBE.DISH_BEANCONGEE = "Eating too much makes eaters fart loudly, which is suitable for me."
S_____WORMWOOD.DESCRIBE.DISH_BEANCONGEE = "Cold and sticky."
S________WARLY.DESCRIBE.DISH_BEANCONGEE = "Cool Congee for clearing away heat."
-- S_________WURT.DESCRIBE.DISH_BEANCONGEE = ""
-- S_______WALTER.DESCRIBE.DISH_BEANCONGEE = ""
-- S________WANDA.DESCRIBE.DISH_BEANCONGEE = ""

S_NAMES.DISH_SEEDSCONGEE = "Sprouting-Joy Congee" --春来多喜粥
STRINGS.UI.COOKBOOK.DISH_SEEDSCONGEE = "Promotes germination"
S______GENERIC.DESCRIBE.DISH_SEEDSCONGEE = "This food contains the chef's best wishes."
-- S_______WILLOW.DESCRIBE.DISH_SEEDSCONGEE = ""
S_____WOLFGANG.DESCRIBE.DISH_SEEDSCONGEE = "Wolfgang also likes this sweet and delicious taste."
S________WENDY.DESCRIBE.DISH_SEEDSCONGEE = "A dish not made for me."
-- S_________WX78.DESCRIBE.DISH_SEEDSCONGEE = ""
S_WICKERBOTTOM.DESCRIBE.DISH_SEEDSCONGEE = "Rich in nutrients required for plant growth, but must be digested by the stomach."
S_______WOODIE.DESCRIBE.DISH_SEEDSCONGEE = "A good breakfast suitable for people doing physical labor."
S______WAXWELL.DESCRIBE.DISH_SEEDSCONGEE = "It's easy to eat, and the taste is surprisingly good."
S___WATHGRITHR.DESCRIBE.DISH_SEEDSCONGEE = "It's cooked with heart, but it's not in my heart."
-- S_______WEBBER.DESCRIBE.DISH_SEEDSCONGEE = ""
-- S_______WINONA.DESCRIBE.DISH_SEEDSCONGEE = ""
-- S_______WORTOX.DESCRIBE.DISH_SEEDSCONGEE = ""
S_____WORMWOOD.DESCRIBE.DISH_SEEDSCONGEE = "Best paste!"
S________WARLY.DESCRIBE.DISH_SEEDSCONGEE = "Oh, sweet congee tailored for Wormwood."
-- S_________WURT.DESCRIBE.DISH_SEEDSCONGEE = ""
-- S_______WALTER.DESCRIBE.DISH_SEEDSCONGEE = ""
-- S________WANDA.DESCRIBE.DISH_SEEDSCONGEE = ""

--------------------------------------------------------------------------
--[[ the sacrifice of rain ]]--[[ 祈雨祭 ]]
--------------------------------------------------------------------------

S_NAMES.RAINDONATE = "Raindonate"    --雨蝇
S______GENERIC.DESCRIBE.RAINDONATE = {
    GENERIC = "Elders said that the killing of it would cause rain.",
    HELD = "Look, a blue winged insect!",
}
S_______WILLOW.DESCRIBE.RAINDONATE = {
    GENERIC = "A little bug named rain. I want to see if it can be ignited.",
    HELD = "Watching you curl up, I decided not to burn you.",
}
S_____WOLFGANG.DESCRIBE.RAINDONATE = {
    GENERIC = "Thin arms and legs. You must train like me!",
    HELD = "Eat more eggs and exercise your legs, little bug.",
}
S________WENDY.DESCRIBE.RAINDONATE = {
    GENERIC = "You're always in fields and ponds...",
    HELD = "I shouldn't have caught you, you always let me fall into sad memories.",
}
-- S_________WX78.DESCRIBE.RAINDONATE = ""
-- S_WICKERBOTTOM.DESCRIBE.RAINDONATE = ""
-- S_______WOODIE.DESCRIBE.RAINDONATE = ""
-- S______WAXWELL.DESCRIBE.RAINDONATE = ""
-- S___WATHGRITHR.DESCRIBE.RAINDONATE = ""
S_______WEBBER.DESCRIBE.RAINDONATE = {
    GENERIC = "Hey, fly to our hands!",
    HELD = "See! A piece of cake.",
}
-- S_______WINONA.DESCRIBE.RAINDONATE = ""
-- S_______WORTOX.DESCRIBE.RAINDONATE = ""
-- S_____WORMWOOD.DESCRIBE.RAINDONATE = ""
-- S________WARLY.DESCRIBE.RAINDONATE = ""
-- S_________WURT.DESCRIBE.RAINDONATE = ""
-- S_______WALTER.DESCRIBE.RAINDONATE = ""
S________WANDA.DESCRIBE.RAINDONATE = {
    GENERIC = "Don't fly away. I'm not interested in you.",
    HELD = "Let me take a moment to think about whether to let you go.",
}

S_NAMES.MONSTRAIN = "Monstrain" --雨竹
S_NAMES.MONSTRAIN_WAXED = "Fuel-Woven Monstrain"
S_NAMES.MONSTRAIN_ITEM_WAXED = "Fuel-Woven Monstrain"
S______GENERIC.DESCRIBE.MONSTRAIN = {
    SUMMER = "The water at the bottom fled.",
    WINTER = "The water at the bottom solidified.",
    GENERIC = "Careful! Don't touch the juice of it!",
    PICKED = "I'll just take a look."
}
S_____WORMWOOD.DESCRIBE.MONSTRAIN = {
    SUMMER = "Hot! She's asleep.",
    WINTER = "Cold! She's asleep.",
    GENERIC = "Friend likes water very much.",
    PICKED = "Should I comfort her?"
}

S_NAMES.MONSTRAIN_WIZEN = "Monstrain Tuber" --雨竹块茎
S______GENERIC.DESCRIBE.MONSTRAIN_WIZEN = "Water, water, help!"
S_______WILLOW.DESCRIBE.MONSTRAIN_WIZEN = "More water? It's so troublesome. Just burn it."
-- S_____WOLFGANG.DESCRIBE.MONSTRAIN_WIZEN = ""
-- S________WENDY.DESCRIBE.MONSTRAIN_WIZEN = ""
S_________WX78.DESCRIBE.MONSTRAIN_WIZEN = "WATER IS NECESSARY FOR LIFE."
S_WICKERBOTTOM.DESCRIBE.MONSTRAIN_WIZEN = "This plant is extremely dependent on water."
S_______WOODIE.DESCRIBE.MONSTRAIN_WIZEN = "It's strange that it doesn't want poop."
-- S______WAXWELL.DESCRIBE.MONSTRAIN_WIZEN = ""
-- S___WATHGRITHR.DESCRIBE.MONSTRAIN_WIZEN = ""
S_______WEBBER.DESCRIBE.MONSTRAIN_WIZEN = "Water it!"
-- S_______WINONA.DESCRIBE.MONSTRAIN_WIZEN = ""
S_______WORTOX.DESCRIBE.MONSTRAIN_WIZEN = "If I don't water it, it will die in front of me."
S_____WORMWOOD.DESCRIBE.MONSTRAIN_WIZEN = "Water my friend right now!"
-- S________WARLY.DESCRIBE.MONSTRAIN_WIZEN = ""
-- S_________WURT.DESCRIBE.MONSTRAIN_WIZEN = ""
-- S_______WALTER.DESCRIBE.MONSTRAIN_WIZEN = ""
-- S________WANDA.DESCRIBE.MONSTRAIN_WIZEN = ""

S_NAMES.DUG_MONSTRAIN = "Monstrain Tuber" --雨竹块茎
S______GENERIC.DESCRIBE.DUG_MONSTRAIN = "So easy to dig? Why couldn't I dig it before?"
-- S_______WILLOW.DESCRIBE.DUG_MONSTRAIN = ""
S_____WOLFGANG.DESCRIBE.DUG_MONSTRAIN = "A poisonous taro. Wolfgang won't eat it."
-- S________WENDY.DESCRIBE.DUG_MONSTRAIN = ""
-- S_________WX78.DESCRIBE.DUG_MONSTRAIN = ""
S_WICKERBOTTOM.DESCRIBE.DUG_MONSTRAIN = "Look at the eggs at the root of it. It's a wonderful symbiosis."
-- S_______WOODIE.DESCRIBE.DUG_MONSTRAIN = ""
-- S______WAXWELL.DESCRIBE.DUG_MONSTRAIN = ""
-- S___WATHGRITHR.DESCRIBE.DUG_MONSTRAIN = ""
-- S_______WEBBER.DESCRIBE.DUG_MONSTRAIN = ""
-- S_______WINONA.DESCRIBE.DUG_MONSTRAIN = ""
S_______WORTOX.DESCRIBE.DUG_MONSTRAIN = "Toxic. Why do I know? I observed it from my friends."
S_____WORMWOOD.DESCRIBE.DUG_MONSTRAIN = "A water friend."
S________WARLY.DESCRIBE.DUG_MONSTRAIN = "Maybe I can make it into konjac."
-- S_________WURT.DESCRIBE.DUG_MONSTRAIN = ""
-- S_______WALTER.DESCRIBE.DUG_MONSTRAIN = ""
S________WANDA.DESCRIBE.DUG_MONSTRAIN = "I have seen many people poisoned by it."

S_NAMES.SQUAMOUSFRUIT = "Squamous Fruit"    --鳞果
S______GENERIC.DESCRIBE.SQUAMOUSFRUIT = "Wow, an edible pinecone."
-- S_______WILLOW.DESCRIBE.SQUAMOUSFRUIT = ""
-- S_____WOLFGANG.DESCRIBE.SQUAMOUSFRUIT = ""
-- S________WENDY.DESCRIBE.SQUAMOUSFRUIT = ""
-- S_________WX78.DESCRIBE.SQUAMOUSFRUIT = ""
-- S_WICKERBOTTOM.DESCRIBE.SQUAMOUSFRUIT = ""
S_______WOODIE.DESCRIBE.SQUAMOUSFRUIT = "A pinecone that can't grow up."
-- S______WAXWELL.DESCRIBE.SQUAMOUSFRUIT = ""
-- S___WATHGRITHR.DESCRIBE.SQUAMOUSFRUIT = ""
S_______WEBBER.DESCRIBE.SQUAMOUSFRUIT = "Wow, a pinecone with our favorite color."
-- S_______WINONA.DESCRIBE.SQUAMOUSFRUIT = ""
-- S_______WORTOX.DESCRIBE.SQUAMOUSFRUIT = ""
-- S_____WORMWOOD.DESCRIBE.SQUAMOUSFRUIT = ""
S________WARLY.DESCRIBE.SQUAMOUSFRUIT = "You wouldn't imagine that it can be eaten."
-- S_________WURT.DESCRIBE.SQUAMOUSFRUIT = ""
-- S_______WALTER.DESCRIBE.SQUAMOUSFRUIT = ""
-- S________WANDA.DESCRIBE.SQUAMOUSFRUIT = ""

S_NAMES.MONSTRAIN_LEAF = "Monstrain Leaf"    --雨竹叶
S______GENERIC.DESCRIBE.MONSTRAIN_LEAF = "When I eat it, it eats me."
-- S_______WILLOW.DESCRIBE.MONSTRAIN_LEAF = ""
S_____WOLFGANG.DESCRIBE.MONSTRAIN_LEAF = "Wolfgang doesn't eat strange leaves."
-- S________WENDY.DESCRIBE.MONSTRAIN_LEAF = ""
-- S_________WX78.DESCRIBE.MONSTRAIN_LEAF = ""
S_WICKERBOTTOM.DESCRIBE.MONSTRAIN_LEAF = "High temperature heating can eliminate its toxicity."
-- S_______WOODIE.DESCRIBE.MONSTRAIN_LEAF = ""
-- S______WAXWELL.DESCRIBE.MONSTRAIN_LEAF = ""
-- S___WATHGRITHR.DESCRIBE.MONSTRAIN_LEAF = ""
-- S_______WEBBER.DESCRIBE.MONSTRAIN_LEAF = ""
-- S_______WINONA.DESCRIBE.MONSTRAIN_LEAF = ""
-- S_______WORTOX.DESCRIBE.MONSTRAIN_LEAF = ""
-- S_____WORMWOOD.DESCRIBE.MONSTRAIN_LEAF = ""
S________WARLY.DESCRIBE.MONSTRAIN_LEAF = "More cooking can eliminate the toxicity."
S_________WURT.DESCRIBE.MONSTRAIN_LEAF = "The books lady told me not to eat it, but it smells delicious."
-- S_______WALTER.DESCRIBE.MONSTRAIN_LEAF = ""
-- S________WANDA.DESCRIBE.MONSTRAIN_LEAF = ""

S_NAMES.BOOK_WEATHER = "Changing Clouds"    --多变的云
S_RECIPE_DESC.BOOK_WEATHER = "Stir the clouds with your heart."
S______GENERIC.DESCRIBE.BOOK_WEATHER = "When clouds cover the sun... when sunlight penetrates the clouds..."
--S_______WILLOW.DESCRIBE.BOOK_WEATHER = "This is the opposite of burning."
--S_____WOLFGANG.DESCRIBE.BOOK_WEATHER = "Wolfgang can eat in one bite!"
--S________WENDY.DESCRIBE.BOOK_WEATHER = "I used to eat these with Abigail..."
--S_________WX78.DESCRIBE.BOOK_WEATHER = "STICK ADDON INSTALLED"
S_WICKERBOTTOM.DESCRIBE.BOOK_WEATHER = "Well, I can forecast the weather correctly now."
--S_______WOODIE.DESCRIBE.BOOK_WEATHER = "I'd prefer maple taffy..."
S______WAXWELL.DESCRIBE.BOOK_WEATHER = "Hm... I can forecast the weather correctly now."
--S___WATHGRITHR.DESCRIBE.BOOK_WEATHER = "I've somehow found a way to make it even LESS appealing!"
--S_______WEBBER.DESCRIBE.BOOK_WEATHER = "Yaaay! Popsicle, popsicle!"
--S_______WINONA.DESCRIBE.BOOK_WEATHER = "Great to cool off after some hard physical labor."
--
S______GENERIC.ANNOUNCE_READ_BOOK.BOOK_WEATHER = "Wait, isn't it just Wurt who reads?"
-- S_______WILLOW.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_____WOLFGANG.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S________WENDY.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_________WX78.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_WICKERBOTTOM.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_______WOODIE.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S______WAXWELL.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S___WATHGRITHR.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_______WEBBER.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_______WINONA.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_______WORTOX.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S_____WORMWOOD.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
-- S________WARLY.ANNOUNCE_READ_BOOK.BOOK_WEATHER = ""
S_________WURT.ANNOUNCE_READ_BOOK.BOOK_WEATHER_SUNNY = "Arid, dry, waterless, blablabla..."
S_________WURT.ANNOUNCE_READ_BOOK.BOOK_WEATHER_RAINY = "Drizzle, sprinkle, downpour, that's sweet."

S_NAMES.MERM_SCALES = "Drippy Scales"  --鱼鳞
S______GENERIC.DESCRIBE.MERM_SCALES = "Ewwwwwwww, such smell a strong fish smell."
--S_______WILLOW.DESCRIBE.MERM_SCALES = "This is the opposite of burning."
--S_____WOLFGANG.DESCRIBE.MERM_SCALES = "Wolfgang can eat in one bite!"
--S________WENDY.DESCRIBE.MERM_SCALES = "Contrary to Ms Squid's magic."
--S_________WX78.DESCRIBE.MERM_SCALES = "STICK ADDON INSTALLED"
--S_WICKERBOTTOM.DESCRIBE.MERM_SCALES = "Well, isn't that refreshing?"
--S_______WOODIE.DESCRIBE.MERM_SCALES = "I'd prefer maple taffy..."
--S______WAXWELL.DESCRIBE.MERM_SCALES = "Hm... I don't know what I was expecting."
--S___WATHGRITHR.DESCRIBE.MERM_SCALES = "I've somehow found a way to make it even LESS appealing!"
S_______WEBBER.DESCRIBE.MERM_SCALES = "And how about the one with the drippy nose?"
--S_______WINONA.DESCRIBE.MERM_SCALES = "Great to cool off after some hard physical labor."

S_NAMES.HAT_MERMBREATHING = "Breathing Gills"  --鱼之息
S_RECIPE_DESC.HAT_MERMBREATHING = "Breathing like a merm."
S______GENERIC.DESCRIBE.HAT_MERMBREATHING = "I hope I won't jump into the sea and disappear."
--S_______WILLOW.DESCRIBE.HAT_MERMBREATHING = ""
--S_____WOLFGANG.DESCRIBE.HAT_MERMBREATHING = ""
S________WENDY.DESCRIBE.HAT_MERMBREATHING = "Contrary to Ms Squid's magic."
--S_________WX78.DESCRIBE.HAT_MERMBREATHING = ""
--S_WICKERBOTTOM.DESCRIBE.HAT_MERMBREATHING = ""
--S_______WOODIE.DESCRIBE.HAT_MERMBREATHING = ""
--S______WAXWELL.DESCRIBE.HAT_MERMBREATHING = ""
--S___WATHGRITHR.DESCRIBE.HAT_MERMBREATHING = ""
S_______WEBBER.DESCRIBE.HAT_MERMBREATHING = "I can swim freely! er... nevermind I need a fish tail."
--S_______WINONA.DESCRIBE.HAT_MERMBREATHING = ""

S_NAMES.AGRONSSWORD = "Agron's Sword" --艾力冈的剑
S_NAMES.AGRONSSWORD_ITEM_WAXED = "Fuel-Woven Agron's Sword"
S______GENERIC.DESCRIBE.AGRONSSWORD = "I'll fight to be a free man!"
S_______WILLOW.DESCRIBE.AGRONSSWORD = "A single faith can start a freedom fire."
S_____WOLFGANG.DESCRIBE.AGRONSSWORD = "It fills Wolfgang with courage!"
S________WENDY.DESCRIBE.AGRONSSWORD = "If I leave here, Abigail will leave me."
S_________WX78.DESCRIBE.AGRONSSWORD = "YEARN FOR HUMAN NATURE BUT... FEAR TO POSSESS IT."
S_WICKERBOTTOM.DESCRIBE.AGRONSSWORD = "Do not shed tears."
S_______WOODIE.DESCRIBE.AGRONSSWORD = "Lucy comforts me, so I believe I can escape from here one day."
S______WAXWELL.DESCRIBE.AGRONSSWORD = "There is no greater victory than to fall from this world as a free man."
S___WATHGRITHR.DESCRIBE.AGRONSSWORD = "When the Bringer of Rain died, even Valhalla was moved."
S_______WEBBER.DESCRIBE.AGRONSSWORD = "If I could, I would be out of this world with my legion!"
S_______WINONA.DESCRIBE.AGRONSSWORD = "I am a laborer, not a slave, I'm my own!"

S_NAMES.GIANTSFOOT = "Giant's Foot" --巨人之脚
S_RECIPE_DESC.GIANTSFOOT = "Let giants rule your stuff."
S______GENERIC.DESCRIBE.GIANTSFOOT = "Giants stand on the shoulders of me."
--S_______WILLOW.DESCRIBE.GIANTSFOOT = "This is the opposite of burning."
--S_____WOLFGANG.DESCRIBE.GIANTSFOOT = "Wolfgang can eat in one bite!"
S________WENDY.DESCRIBE.GIANTSFOOT = "Er... Have I seen it somewhere?"
--S_________WX78.DESCRIBE.GIANTSFOOT = "STICK ADDON INSTALLED"
--S_WICKERBOTTOM.DESCRIBE.GIANTSFOOT = "Well, isn't that refreshing?"
--S_______WOODIE.DESCRIBE.GIANTSFOOT = "I'd prefer maple taffy..."
--S______WAXWELL.DESCRIBE.GIANTSFOOT = "Hm... I don't know what I was expecting."
--S___WATHGRITHR.DESCRIBE.GIANTSFOOT = "I've somehow found a way to make it even LESS appealing!"
--S_______WEBBER.DESCRIBE.GIANTSFOOT = "I can swim freely! er... need a fish tail."
--S_______WINONA.DESCRIBE.GIANTSFOOT = "Great to cool off after some hard physical labor."

S_NAMES.REFRACTEDMOONLIGHT = "MoonRefracted" --月折宝剑
S_NAMES.REFRACTEDMOONLIGHT_ITEM_WAXED = "Fuel-Woven MoonRefracted"
S______GENERIC.DESCRIBE.REFRACTEDMOONLIGHT = "Oh my glob! A powerful sword from the Land of Ooo?"
-- S_______WILLOW.DESCRIBE.REFRACTEDMOONLIGHT = ""
-- S_____WOLFGANG.DESCRIBE.REFRACTEDMOONLIGHT = ""
S________WENDY.DESCRIBE.REFRACTEDMOONLIGHT = "No amount of power can save the past."
-- S_________WX78.DESCRIBE.REFRACTEDMOONLIGHT = ""
S_WICKERBOTTOM.DESCRIBE.REFRACTEDMOONLIGHT = "Only a person of integrity can control its power."
-- S_______WOODIE.DESCRIBE.REFRACTEDMOONLIGHT = ""
S______WAXWELL.DESCRIBE.REFRACTEDMOONLIGHT = "Only those who are healthy can wield its power."
-- S___WATHGRITHR.DESCRIBE.REFRACTEDMOONLIGHT = ""
S_______WEBBER.DESCRIBE.REFRACTEDMOONLIGHT = "Do aliens also use such simple weapons?"
S_______WINONA.DESCRIBE.REFRACTEDMOONLIGHT = "A treasure on the moon?"
-- S_______WORTOX.DESCRIBE.REFRACTEDMOONLIGHT = ""
S_____WORMWOOD.DESCRIBE.REFRACTEDMOONLIGHT = "Big sword!"
S________WARLY.DESCRIBE.REFRACTEDMOONLIGHT = "Have you eaten? Eat my sword!"
-- S_________WURT.DESCRIBE.REFRACTEDMOONLIGHT = ""
-- S_______WALTER.DESCRIBE.REFRACTEDMOONLIGHT = ""
-- S________WANDA.DESCRIBE.REFRACTEDMOONLIGHT = ""

S_NAMES.MOONDUNGEON = "Moon Oubliette" --月的地下城
S______GENERIC.DESCRIBE.MOONDUNGEON = {
    SLEEP = "Is that a fossilized... fossil?",
    GENERIC = "Someone burned up their whole life and built it into this."
}
S_______WILLOW.DESCRIBE.MOONDUNGEON = {
    SLEEP = "Open the door! I know there's something in it!",
    GENERIC = "Fire attack doesn't work here."
}
S______WAXWELL.DESCRIBE.MOONDUNGEON = {
    SLEEP = "The old shadow King arrived, why did no one go out to greet him?!",
    GENERIC = "I didn't recognize it as a trap castle."
}
S___WATHGRITHR.DESCRIBE.MOONDUNGEON = {
    SLEEP = "An old palace.",
    GENERIC = "It's totally different from the palace style of Pandia."
}

S_NAMES.HIDDENMOONLIGHT = "MoonHidden" --月藏宝匣
S______GENERIC.DESCRIBE.HIDDENMOONLIGHT = "As empty as the Milky way."
-- S_______WILLOW.DESCRIBE.HIDDENMOONLIGHT = ""
S_____WOLFGANG.DESCRIBE.HIDDENMOONLIGHT = "Look! There are stars blinking at Wolfgang."
S________WENDY.DESCRIBE.HIDDENMOONLIGHT = "Light moonlight, somewhere in my heart."
-- S_________WX78.DESCRIBE.HIDDENMOONLIGHT = ""
S_WICKERBOTTOM.DESCRIBE.HIDDENMOONLIGHT = "The flow of time in this box is slower than on the outside."
-- S_______WOODIE.DESCRIBE.HIDDENMOONLIGHT = ""
S______WAXWELL.DESCRIBE.HIDDENMOONLIGHT = "Such a waste to use it like that."
-- S___WATHGRITHR.DESCRIBE.HIDDENMOONLIGHT = ""
S_______WEBBER.DESCRIBE.HIDDENMOONLIGHT = "Yeah! Reach in and grab anything you want."
-- S_______WINONA.DESCRIBE.HIDDENMOONLIGHT = ""
-- S_______WORTOX.DESCRIBE.HIDDENMOONLIGHT = ""
S_____WORMWOOD.DESCRIBE.HIDDENMOONLIGHT = "Hollow, like me."
S________WARLY.DESCRIBE.HIDDENMOONLIGHT = "Save my ingredients better!"
S_________WURT.DESCRIBE.HIDDENMOONLIGHT = "Why is there no sound of waves coming out, florp?"
-- S_______WALTER.DESCRIBE.HIDDENMOONLIGHT = ""
S________WANDA.DESCRIBE.HIDDENMOONLIGHT = "I won't bring yesterday's food to today."

S_NAMES.HIDDENMOONLIGHT_INF = "Infinite MoonHidden" --月藏宝匣·无限
S______GENERIC.DESCRIBE.HIDDENMOONLIGHT_INF = "As empty as the Milky way, as vast as the universe."
-- S_______WILLOW.DESCRIBE.HIDDENMOONLIGHT_INF = ""
S_____WOLFGANG.DESCRIBE.HIDDENMOONLIGHT_INF = "Wolfgang's eyes were dazzled."
S________WENDY.DESCRIBE.HIDDENMOONLIGHT_INF = "So bright, so cold."
-- S_________WX78.DESCRIBE.HIDDENMOONLIGHT_INF = ""
S_WICKERBOTTOM.DESCRIBE.HIDDENMOONLIGHT_INF = "Unlimited capacity, unlimited time, it's amazing."
-- S_______WOODIE.DESCRIBE.HIDDENMOONLIGHT_INF = ""
S______WAXWELL.DESCRIBE.HIDDENMOONLIGHT_INF = "Has a more mysterious moon magic."
-- S___WATHGRITHR.DESCRIBE.HIDDENMOONLIGHT_INF = ""
S_______WEBBER.DESCRIBE.HIDDENMOONLIGHT_INF = "We can't touch it all, our hands will disappear inside."
-- S_______WINONA.DESCRIBE.HIDDENMOONLIGHT_INF = ""
-- S_______WORTOX.DESCRIBE.HIDDENMOONLIGHT_INF = ""
S_____WORMWOOD.DESCRIBE.HIDDENMOONLIGHT_INF = "A hollow box."
S________WARLY.DESCRIBE.HIDDENMOONLIGHT_INF = "Many people ask the chef why the ingredients are so fresh, shh!"
-- S_________WURT.DESCRIBE.HIDDENMOONLIGHT_INF = ""
-- S_______WALTER.DESCRIBE.HIDDENMOONLIGHT_INF = ""
-- S________WANDA.DESCRIBE.HIDDENMOONLIGHT_INF = ""

S_NAMES.HIDDENMOONLIGHT_ITEM = "MoonHidden Kit" --月藏宝匣套件
S_RECIPE_DESC.HIDDENMOONLIGHT_ITEM = "Hiding dainties between moon and stars."
S______GENERIC.DESCRIBE.HIDDENMOONLIGHT_ITEM = "Seems to be an upgrade kit for food storage."
-- S_______WILLOW.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
S_____WOLFGANG.DESCRIBE.HIDDENMOONLIGHT_ITEM = "Was this also a secret fridge in ancient times?"
-- S________WENDY.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
-- S_________WX78.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
-- S_WICKERBOTTOM.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
-- S_______WOODIE.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
S______WAXWELL.DESCRIBE.HIDDENMOONLIGHT_ITEM = "A box powered by moonlight."
S___WATHGRITHR.DESCRIBE.HIDDENMOONLIGHT_ITEM = "Hope it's not Pandora's box."
-- S_______WEBBER.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
S_______WINONA.DESCRIBE.HIDDENMOONLIGHT_ITEM = "The inspiration of moon!"
S_______WORTOX.DESCRIBE.HIDDENMOONLIGHT_ITEM = "I can feel it calling for food."
-- S_____WORMWOOD.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
S________WARLY.DESCRIBE.HIDDENMOONLIGHT_ITEM = "Great, I'm still short of this."
-- S_________WURT.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
-- S_______WALTER.DESCRIBE.HIDDENMOONLIGHT_ITEM = ""
S________WANDA.DESCRIBE.HIDDENMOONLIGHT_ITEM = "Its function is just ordinary to me."

S_NAMES.REVOLVEDMOONLIGHT = "MoonRevolved" --月轮宝盘
S______GENERIC.DESCRIBE.REVOLVEDMOONLIGHT = "The inside is as soft as the moonlight."
-- S_______WILLOW.DESCRIBE.REVOLVEDMOONLIGHT = ""
S_____WOLFGANG.DESCRIBE.REVOLVEDMOONLIGHT = "Nevermind, I figured it out."
S________WENDY.DESCRIBE.REVOLVEDMOONLIGHT = "Soft moonlight, no trace of temperature."
-- S_________WX78.DESCRIBE.REVOLVEDMOONLIGHT = ""
S_WICKERBOTTOM.DESCRIBE.REVOLVEDMOONLIGHT = "Add more yellow gems and you can use it as a night light."
-- S_______WOODIE.DESCRIBE.REVOLVEDMOONLIGHT = ""
S______WAXWELL.DESCRIBE.REVOLVEDMOONLIGHT = "What a waste of Moonlight."
-- S___WATHGRITHR.DESCRIBE.REVOLVEDMOONLIGHT = ""
S_______WEBBER.DESCRIBE.REVOLVEDMOONLIGHT = "Beautiful shiny little toy!"
S_______WINONA.DESCRIBE.REVOLVEDMOONLIGHT = "It can also be loaded with yellow gems to improve it's brightness."
-- S_______WORTOX.DESCRIBE.REVOLVEDMOONLIGHT = ""
-- S_____WORMWOOD.DESCRIBE.REVOLVEDMOONLIGHT = ""
-- S________WARLY.DESCRIBE.REVOLVEDMOONLIGHT = ""
-- S_________WURT.DESCRIBE.REVOLVEDMOONLIGHT = ""
S_______WALTER.DESCRIBE.REVOLVEDMOONLIGHT = "Shining like a badge."
S________WANDA.DESCRIBE.REVOLVEDMOONLIGHT = "It's really a waste of moon magic to do this."

S_NAMES.REVOLVEDMOONLIGHT_ITEM = "MoonRevolved Kit" --月轮宝盘套件
S_RECIPE_DESC.REVOLVEDMOONLIGHT_ITEM = "Moon and shadow revolve and the afterglow leaks."
S______GENERIC.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "Seems to be an upgrade kit for certain backpacks."
-- S_______WILLOW.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
S_____WOLFGANG.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "Can anyone tell Wolfgang how to use it?"
-- S________WENDY.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
S_________WX78.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "BACKPACK UPDATER."
S_WICKERBOTTOM.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "It fits perfectly with some backpacks."
-- S_______WOODIE.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
S______WAXWELL.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "I don't want to judge this stuff anymore."
-- S___WATHGRITHR.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
S_______WEBBER.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "It should be able to shine."
S_______WINONA.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "Based on my experience, It is for certain backpacks."
-- S_______WORTOX.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
-- S_____WORMWOOD.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
-- S________WARLY.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
-- S_________WURT.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""
S_______WALTER.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = "Maybe I can use it to play Frisbee game with Woby."
-- S________WANDA.DESCRIBE.REVOLVEDMOONLIGHT_ITEM = ""

S_NAMES.SIMMEREDMOONLIGHT = "MoonSimmered" --月炆宝炊
S_NAMES.SIMMEREDMOONLIGHT_PRO = "Portable MoonSimmered" --便携月炆宝炊
S_NAMES.SIMMEREDMOONLIGHT_PRO_ITEM = S_NAMES.SIMMEREDMOONLIGHT_PRO
S______GENERIC.DESCRIBE.SIMMEREDMOONLIGHT = "It uses lunar flame to cook dishes."
S_______WILLOW.DESCRIBE.SIMMEREDMOONLIGHT = "Lunar flame is also fire!"
-- S_____WOLFGANG.DESCRIBE.SIMMEREDMOONLIGHT = ""
S________WENDY.DESCRIBE.SIMMEREDMOONLIGHT = "These foods are roasted in indifference..."
-- S_________WX78.DESCRIBE.SIMMEREDMOONLIGHT = ""
S_WICKERBOTTOM.DESCRIBE.SIMMEREDMOONLIGHT = "It's amazing that lunar flame keeps cooking food."
S_______WOODIE.DESCRIBE.SIMMEREDMOONLIGHT = "Suspicious cookware, is the food inside edible?"
S______WAXWELL.DESCRIBE.SIMMEREDMOONLIGHT = "I have to say, this magic is not bad."
S___WATHGRITHR.DESCRIBE.SIMMEREDMOONLIGHT = "A pot blessed by an ancient god."
S_______WEBBER.DESCRIBE.SIMMEREDMOONLIGHT = "Now we just need to throw a bunch of food inside..."
S_______WINONA.DESCRIBE.SIMMEREDMOONLIGHT = "It doesn't involve physics or chemistry."
S_______WORTOX.DESCRIBE.SIMMEREDMOONLIGHT = "It must have been conceived by a mortal."
S_____WORMWOOD.DESCRIBE.SIMMEREDMOONLIGHT = "Make a lot of good food."
S________WARLY.DESCRIBE.SIMMEREDMOONLIGHT = "It can constantly turn my cooking ideas into reality!"
-- S_________WURT.DESCRIBE.SIMMEREDMOONLIGHT = ""
-- S_______WALTER.DESCRIBE.SIMMEREDMOONLIGHT = ""
S________WANDA.DESCRIBE.SIMMEREDMOONLIGHT = "Making more lunch at once can save me a lot of time."

S_NAMES.SIMMEREDMOONLIGHT_INF = "Infinite MoonSimmered" --月炆宝炊·无限
S_NAMES.SIMMEREDMOONLIGHT_PRO_INF = "Infinite Portable MoonSimmered" --便携月炆宝炊·无限
S_NAMES.SIMMEREDMOONLIGHT_PRO_INF_ITEM = S_NAMES.SIMMEREDMOONLIGHT_PRO_INF
S______GENERIC.DESCRIBE.SIMMEREDMOONLIGHT_INF = "It can cook delicious dishes with lunar flame."
S_______WILLOW.DESCRIBE.SIMMEREDMOONLIGHT_INF = "I can feel the infinite lunar flame in the pot."
-- S_____WOLFGANG.DESCRIBE.SIMMEREDMOONLIGHT_INF = ""
S________WENDY.DESCRIBE.SIMMEREDMOONLIGHT_INF = "These foods are constantly roasted and tormented in the cold..."
-- S_________WX78.DESCRIBE.SIMMEREDMOONLIGHT_INF = ""
S_WICKERBOTTOM.DESCRIBE.SIMMEREDMOONLIGHT_INF = "The infinite lunar flame will cook infinite dishes, amazing."
S_______WOODIE.DESCRIBE.SIMMEREDMOONLIGHT_INF = "These foods really smell good... as long as they can be eaten."
S______WAXWELL.DESCRIBE.SIMMEREDMOONLIGHT_INF = "It has to be said that the moon magic was used to the fullest extent."
S___WATHGRITHR.DESCRIBE.SIMMEREDMOONLIGHT_INF = "Did ancient gods use it to cook delicious dishes?"
S_______WEBBER.DESCRIBE.SIMMEREDMOONLIGHT_INF = "We can have a bi...g meal."
S_______WINONA.DESCRIBE.SIMMEREDMOONLIGHT_INF = "It only involves pure magic, and I don't even need to do anything."
S_______WORTOX.DESCRIBE.SIMMEREDMOONLIGHT_INF = "Only mortals will try their best in cooking."
S_____WORMWOOD.DESCRIBE.SIMMEREDMOONLIGHT_INF = "Use it to make endless good food!"
S________WARLY.DESCRIBE.SIMMEREDMOONLIGHT_INF = "Infinite cuisine, infinite possibilities!"
-- S_________WURT.DESCRIBE.SIMMEREDMOONLIGHT_INF = ""
-- S_______WALTER.DESCRIBE.SIMMEREDMOONLIGHT_INF = ""
S________WANDA.DESCRIBE.SIMMEREDMOONLIGHT_INF = "Like me, trapped in a time loop."

S_NAMES.SIMMEREDMOONLIGHT_ITEM = "MoonSimmered Kit" --月炆宝炊套件
S_RECIPE_DESC.SIMMEREDMOONLIGHT_ITEM = "Moonlight makes you cook without fire."
S______GENERIC.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "It seems to be an upgraded kit for cooking pots."
-- S_______WILLOW.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = ""
-- S_____WOLFGANG.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = ""
S________WENDY.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "An indifferent chef will use cold cookware to make tasteless dishes."
-- S_________WX78.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = ""
S_WICKERBOTTOM.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "A kit for upgrading cooking pots."
S_______WOODIE.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "A very suspicious kit, don't try to deceive me."
S______WAXWELL.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "Some kind of moon magic product, possibly for cooking pots."
-- S___WATHGRITHR.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = ""
-- S_______WEBBER.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = ""
S_______WINONA.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "Used to cast magic on cookware."
S_______WORTOX.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "It's just a human need."
S_____WORMWOOD.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "First, find a pot."
S________WARLY.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "With it, I can even open my own restaurant."
-- S_________WURT.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = ""
-- S_______WALTER.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = ""
S________WANDA.DESCRIBE.SIMMEREDMOONLIGHT_ITEM = "I will try my best to obtain it in every timeline."

S_NAMES.POND_L_SMOKE = "Smoked Hot Spring" --气熏温泉
S______GENERIC.DESCRIBE.POND_L_SMOKE = "How could there be such tempting hot springs in this wilderness!"
S_______WILLOW.DESCRIBE.POND_L_SMOKE = "No one would want to take a bath in such a smelly pool, would they."
S_____WOLFGANG.DESCRIBE.POND_L_SMOKE = "It is tempting, but there won't be any monsters in it, right?"
S________WENDY.DESCRIBE.POND_L_SMOKE = "It's quite shallow and can't make me drown."
S_________WX78.DESCRIBE.POND_L_SMOKE = "THERE IS A HUGE RISK OF WATER INGRESS!"
S_WICKERBOTTOM.DESCRIBE.POND_L_SMOKE = "Both temperature and minerals such as sulfur are very helpful to the human body."
S_______WOODIE.DESCRIBE.POND_L_SMOKE = "Lucy and I have long been accustomed to this muddy smell."
S______WAXWELL.DESCRIBE.POND_L_SMOKE = "I'll take a bath when I'm alone."
S___WATHGRITHR.DESCRIBE.POND_L_SMOKE = "The Gaia Spring can wash away the fatigue of every warrior."
S_______WEBBER.DESCRIBE.POND_L_SMOKE = "It makes me miss every comfortable night of bathing."
S_______WINONA.DESCRIBE.POND_L_SMOKE = "Stinky hot spring."
S_______WORTOX.DESCRIBE.POND_L_SMOKE = "Stinky water is not really dirty, taking a bath is really refreshing."
S_____WORMWOOD.DESCRIBE.POND_L_SMOKE = "Warm and smell good!"
S________WARLY.DESCRIBE.POND_L_SMOKE = "The water temperature can make Onsen Tamago."
S_________WURT.DESCRIBE.POND_L_SMOKE = "Glorph, I really want to take a bath inside!"
S_______WALTER.DESCRIBE.POND_L_SMOKE = "I seem to have seen this kind of hot spring with a muddy smell in a book."
S________WANDA.DESCRIBE.POND_L_SMOKE = "I will try my best to take some time to take a bath."

S______GENERIC.SOAK_L = {
    NOSPACE = {
        "No! There is no place for me.",
        "I'm late...",
        "The suitable place is gone.",
        "Unfortunately, there is out of space.",
        "No place left?"
    },
    REFUSE = { "I don't want to take a bath!" },
    REFUSE_WATER = {
        "I'm too damp.",
        "I'm very wet and not suitable for taking a bath.",
        "I'm completely soaked, I don't want to soak anymore.",
        "I'm already wet enough, aren't I?",
        "I don't want to touch water anymore!",
        "I can really sink down if I soak again!"
    },
    DIZZY1 = {
        "I feel a little dizzy.",
        "Although it's comfortable, soaking for too long is not good.",
        "Let's soak for a while longer.",
        "I seem to have been soaking for a while now...",
        "My body tells me that I can soak for a while longer.",
        "I want to soak for a while longer."
    },
    DIZZY2 = {
        "I feel a bit dizzy...",
        "I'm almost dizzy.",
        "I seem to have been soaking for quite some time.",
        "After soaking for so long, it's time to end!",
        "My body tells me I can't continue.",
        "I feel drowsy..."
    },
    DIZZY3 = {
        "I'm already feeling dizzy...",
        "I feel dizzy.",
        "It's been soaking for too long.",
        "My head feels so dizzy...",
        "Dizzy and disoriented...",
        "I could fall asleep anytime..."
    },
    COSY = {
        "Comfortable and cozy.",
        "My tense nerves have relaxed.",
        "Emptying myself...",
        "It's so pleasant.",
        "Sometimes relax yourself, there's nothing wrong with it.",
        "My body and mind have been healed.",
        "My wound doesn't hurt as much anymore.",
        "My muscles are not as sore anymore...",
        "Washing away my exhaustion..."
    },
    WARM = {
        "It's really heartwarming and relaxing.",
        "Waves of warmth surround me...",
        "A warm feeling.",
        "Warm and cozy...",
        "So warm...",
        "My chill has been dispelled.",
        "Warmth and healing flow in the water."
    },
    COOL = {
        "It's really comfortable and relaxing.",
        "Waves of coolness surround me.",
        "A cool feeling.",
        "Cool and cozy...",
        "It's so cool.",
        "My anger has been dispelled.",
        "Comfort and healing flow in the water."
    }
}
-- S_______WILLOW.SOAK_L = ""
-- S_____WOLFGANG.SOAK_L = ""
-- S________WENDY.SOAK_L = ""
S_________WX78.SOAK_L = {
    NOSPACE = {
        "DAMN FLESHSACKS ARE TAKING MY PLACE!",
        "NO SUITABLE SEATING POINT.",
        "THE OBJECT IS OCCUPIED, TRY AGAIN LATER."
    },
    REFUSE = {
        "I WOULDN'T HAVE THIS IDEA UNLESS MY CHIP IS BROKEN.",
        "I'M CONSIDERING...",
        "WARNING: HIGH RISK OF WATER INGRESS.",
        "IF I WERE COMPLETELY WATERPROOF, I WOULD TRY.",
        "I DON'T HAVE A WATERPROOF MODULE."
    },
    REFUSE_WATER = {
        "WARNING: THE HUMIDITY IS ABOUT TO REACH ITS UPPER LIMIT!",
        "TOO WET...",
        "NO WAY! THE HUMIDITY IS TOO HIGH.",
        "THE RISK IS TOO HIGH!",
        "I MAY GET SEVERELY WATERLOGGED IF I SOAK AGAIN."
    },
    DIZZY1 = {
        "WONDERFUL EXPERIENCE, BUT THERE IS A RISK OF WATER INGRESS.",
        "AFTER ANALYSIS, I CAN SOAK FOR A WHILE LONGER...",
        "MY BODY CAN WITHSTAND IT FOR A WHILE LONGER.",
        "CURRENTLY NO WATER INGRESS.",
        "I'LL SOAK FOR A WHILE.",
        "CONTINUE SOAKING..."
    },
    DIZZY2 = {
        "EXPOSED TO WATER FOR TOO LONG...",
        "THERE IS A SMALL AMOUNT OF WATER VAPOR IN THE VISUAL MODULE.",
        "WARNING: SOME WATER VAPOR.",
        "AFTER ANALYSIS, IT'S CLOSE TO THE CRITICAL POINT OF WATER VAPOR.",
        "WATER VAPOR CONTINUES TO INVADE...",
        "THE WATERPROOF MODULE SHOULDN'T OPERATE AT OVERLOAD FOR TOO LONG!"
    },
    DIZZY3 = {
        "WATER VAPOR HAS ENTERED MY BODY IN LARGE QUANTITIES...",
        "THIS SITUATION IS SIMILAR TO THE \"DIZZINESS\" OF FLESHSACKS.",
        "A LARGE AMOUNT OF WATER VAPOR HAS INVADED MY VISUAL MODULE.",
        "WATER VAPOR GREATLY AFFECTS THE OPERATION OF MACHINERY.",
        "ERROR: RUNNING EFFICIENCY IS TOO LOW.",
        "MY SYSTEM MALFUNCTIONED DUE TO WATER INGRESS..."
    },
    COSY = {
        "THIS IS WHAT FLESHSACKS CALL \"COMFORT\".",
        "I SEEM TO HAVE A COMFORTABLE FEELING...",
        "MY BODY IS OPERATING NORMALLY...",
        "WHAT'S THIS... FEELING?",
        "THE WATERPROOF MODULE IS RUNNING NORMALLY!",
        "SELF CLEANING MODE IS RUNNING...",
        "MY CORE MODULE IS RESTING..."
    },
    WARM = {
        "THE WATER TEMPERATURE IS HIGH, BUT IT HAS NO BAD EFFECTS.",
        "WARM...",
        "WARM WATER...",
        "MY BODY IS VERY SUITABLE FOR THIS HEAT.",
        "THE WATER IS ASSISTING IN RESTORING MY INTERNAL TEMPERATURE.",
        "THE EFFICIENCY OF THE INSULATION MODULE HAS BEEN IMPROVED BY 100%!"
    },
    COOL = {
        "THE WATER TEMPERATURE IS LOW, BUT IT HAS NO BAD EFFECTS.",
        "COOL...",
        "COLD WATER...",
        "MY BODY IS VERY SUITABLE FOR THIS COLD.",
        "THE WATER IS ASSISTING IN DISSIPATING MY CORE HEAT.",
        "THE EFFICIENCY OF THE HEAT-DISSIPATION MODULE HAS BEEN IMPROVED BY 100%!"
    }
}
-- S_WICKERBOTTOM.SOAK_L = ""
-- S_______WOODIE.SOAK_L = ""
-- S______WAXWELL.SOAK_L = ""
-- S___WATHGRITHR.SOAK_L = ""
-- S_______WEBBER.SOAK_L = ""
-- S_______WINONA.SOAK_L = ""
-- S_______WORTOX.SOAK_L = ""
S_____WORMWOOD.SOAK_L = {
    NOSPACE = { "No place.", "Some friends are here.", "One step late.", "No..." },
    REFUSE = { "No!", "I don't want.", "Nah..." },
    REFUSE_WATER = {
        "So wet...",
        "No, I'm soaked through.",
        "Too much water.",
        "Too much water is not good for my flower.",
        "I am not a water-resistant plant..."
    },
    DIZZY1 = {
        "Soaking for too long is not good...",
        "Still able to soak.",
        "Little dizzy.",
        "I've been soaking for a while.",
        "Good soaking.",
        "Soaking..."
    },
    DIZZY2 = {
        "It's time to leave.",
        "My wooden head is getting dizzy...",
        "Very sleepy...",
        "I'm going to feel dizzy.",
        "I feel a little sleepy...",
        "Let's end it!"
    },
    DIZZY3 = {
        "Soaking in it made my head dizzy...",
        "I feel weak...",
        "I feel so dizzy...",
        "I can fall asleep quickly.",
        "Confused...",
        "My head is dizzy..."
    },
    COSY = {
        "Cosy...",
        "Relax myself...",
        "I'm being cured...",
        "I love water the most!",
        "My branches and leaves no longer hurt.",
        "Wash and brush..."
    },
    WARM = {
        "Soaking in warm water...",
        "Warmth.",
        "The water is so warm...",
        "Cold, go away!",
        "Bloom.",
        "Cloud...",
        "Blooming..."
    },
    COOL = {
        "Soaking in cool water...",
        "Cold.",
        "The water is so cool...",
        "Heat, go away!",
        "Breeze...",
        "Leaves.",
        "Flowering..."
    }
}
-- S________WARLY.SOAK_L = ""
-- S_________WURT.SOAK_L = ""
-- S_______WALTER.SOAK_L = ""
-- S________WANDA.SOAK_L = ""

S_NAMES.BUFF_L_WARM = "Warm"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_WARM = "I feel so warm."
S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_WARM = "The heat in my heart is rising!"
S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_WARM = "Wolfgang is not afraid of the cold anymore."
S________WENDY.ANNOUNCE_ATTACH_BUFF_L_WARM = "I have a little warmth in my heart..."
S_________WX78.ANNOUNCE_ATTACH_BUFF_L_WARM = "THE POWER OF THE HEATING MODULE HAS BEEN INCREASED!"
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_WARM = "It seems a bit hot."
S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_WARM = "Warm up!"
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_WARM = ""
S________WANDA.ANNOUNCE_ATTACH_BUFF_L_WARM = "I had this heat when I was young."
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_WARM = "I suddenly feel less warm."
S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_WARM = "The heat in my heart has extinguished."
S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_WARM = "Wolfgang suddenly felt chilly."
S________WENDY.ANNOUNCE_DETACH_BUFF_L_WARM = "That warmth has dissipated with the wind."
S_________WX78.ANNOUNCE_DETACH_BUFF_L_WARM = "THE POWER OF THE HEATING MODULE HAS RETURNED TO NORMAL."
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_WARM = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_WARM = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_WARM = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_WARM = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_WARM = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_WARM = ""
S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_WARM = "I suddenly trembled with the cold."
S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_WARM = "It's a bit cold."
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_WARM = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_WARM = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_WARM = ""
S________WANDA.ANNOUNCE_DETACH_BUFF_L_WARM = "With the increase of experience, I have become even more indifferent."

S_NAMES.BUFF_L_COOL = "Cool"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_COOL = "It's getting cooler now..."
S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_COOL = "I suddenly felt that the flames were not so hot anymore."
S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_COOL = "Wolfgang is not afraid of the heat anymore."
S________WENDY.ANNOUNCE_ATTACH_BUFF_L_COOL = "The whole world is no longer hot."
S_________WX78.ANNOUNCE_ATTACH_BUFF_L_COOL = "THE POWER OF THE COOLING MODULE HAS BEEN INCREASED!"
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_COOL = "I don't feel hot at all."
S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_COOL = "Not hot anymore."
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_COOL = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_COOL = "My body suddenly became less cool."
S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_COOL = "My heat has intensified."
S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_COOL = "Wolfgang suddenly felt a little hot."
S________WENDY.ANNOUNCE_DETACH_BUFF_L_COOL = "The world is getting hot."
S_________WX78.ANNOUNCE_DETACH_BUFF_L_COOL = "THE POWER OF THE COOLING MODULE HAS RETURNED TO NORMAL."
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_COOL = ""
S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_COOL = "It's so hot that I'm sweating a bit."
S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_COOL = "It's a bit hot."
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_COOL = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_COOL = ""

S_NAMES.BUFF_L_BATH = "After Bathing"
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_BATH = "The good time after bathing is over."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_BATH = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_BATH = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_BATH = ""
S_________WX78.ANNOUNCE_DETACH_BUFF_L_BATH = "THIS IS A VERY UNIQUE WATERPROOF TESTING EXPERIENCE."
S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_BATH = "After taking a shower, my mind is at its clearest."
S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_BATH = "My most handsome time after taking a shower has passed."
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_BATH = ""
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_BATH = "The fighter has taken a bath and is waiting for commendation."
S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_BATH = "We will miss the next shower."
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_BATH = ""
-- S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_BATH = ""
S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_BATH = "The soaking time has ended."
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_BATH = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_BATH = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_BATH = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_BATH = ""

S_NAMES.BUFF_L_SOFTSKIN = "Soft Skin"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "My skin has become soft."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
S________WENDY.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "My skin is as fragile as my heart."
S_________WX78.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "WARNING: THERE IS AN ERROR IN THE SURFACE PROTECTIVE LAYER."
S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "My skin has been soaked and softened."
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "Now I look older."
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "Now is my vulnerable moment."
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "My fur has split apart, hmm."
S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = "My face feels so soft..."
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_SOFTSKIN = ""
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "I feel like my skin isn't as soft anymore."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "Wolfgang's skin is finally not wrinkled anymore."
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
S_________WX78.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "THE SURFACE PROTECTIVE LAYER HAS REGAINED ITS TOUGHNESS."
S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "Wrinkled skin looks old, don't soak for too long in the next bath."
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "It's really troublesome to take care of my skin."
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "My skin is once again as hard as my will."
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "Hair is difficult to completely dry out when it gets wet."
S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = "My face has hardened."
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_SOFTSKIN = ""

S_NAMES.BUFF_L_DIZZY = "Dizzy Head"
S_NAMES.BUFF_L_WORKUP = "Efficient Worker"
S_NAMES.BUFF_L_ATTACK = "Strength"
S_NAMES.BUFF_L_DEFENSE = "Health Resistance"
S_NAMES.BUFF_L_ANTIACID = "Acid Protection"

S_NAMES.FERN_L = "Acid-fast Fern"
S_NAMES.FERN_L_WAXED = "Fuel-Woven Acid-fast Fern"
S_NAMES.FERN_L_ITEM_WAXED = "Fuel-Woven Acid-fast Fern"
S______GENERIC.DESCRIBE.FERN_L = "A plant that is resistant to acid."
-- S_______WILLOW.DESCRIBE.FERN_L = ""
-- S_____WOLFGANG.DESCRIBE.FERN_L = ""
S________WENDY.DESCRIBE.FERN_L = "Growing up in a barren land must be very lonely."
S_________WX78.DESCRIBE.FERN_L = "WHY DO PLANTS HAVE TO BE EVERYWHERE."
S_WICKERBOTTOM.DESCRIBE.FERN_L = "This is a fern that can grow tenaciously in acidic soil."
-- S_______WOODIE.DESCRIBE.FERN_L = ""
-- S______WAXWELL.DESCRIBE.FERN_L = ""
-- S___WATHGRITHR.DESCRIBE.FERN_L = ""
-- S_______WEBBER.DESCRIBE.FERN_L = ""
S_______WINONA.DESCRIBE.FERN_L = "Very tenacious."
-- S_______WORTOX.DESCRIBE.FERN_L = ""
S_____WORMWOOD.DESCRIBE.FERN_L = "Friend, be strong."
-- S________WARLY.DESCRIBE.FERN_L = ""
-- S_________WURT.DESCRIBE.FERN_L = ""
-- S_______WALTER.DESCRIBE.FERN_L = ""
-- S________WANDA.DESCRIBE.FERN_L = ""

S_NAMES.ICELEGUME_L = "Ice Legume" --冰皂草
S_NAMES.ICELEGUME_L_WAXED = "Fuel-Woven Ice Legume"
S_NAMES.ICELEGUME_L_ITEM_WAXED = "Fuel-Woven Ice Legume"
S______GENERIC.DESCRIBE.ICELEGUME_L = "A plant that is not afraid of cold."
S_______WILLOW.DESCRIBE.ICELEGUME_L = "I hate cold plant the most."
-- S_____WOLFGANG.DESCRIBE.ICELEGUME_L = ""
-- S________WENDY.DESCRIBE.ICELEGUME_L = ""
-- S_________WX78.DESCRIBE.ICELEGUME_L = ""
S_WICKERBOTTOM.DESCRIBE.ICELEGUME_L = "Cold resistant leguminous plants."
S_______WOODIE.DESCRIBE.ICELEGUME_L = "There must have been prey that left feces with seeds here."
S______WAXWELL.DESCRIBE.ICELEGUME_L = "There must be a reason for growing here."
-- S___WATHGRITHR.DESCRIBE.ICELEGUME_L = ""
-- S_______WEBBER.DESCRIBE.ICELEGUME_L = ""
-- S_______WINONA.DESCRIBE.ICELEGUME_L = ""
S_______WORTOX.DESCRIBE.ICELEGUME_L = "Very timely, this world lacks beans."
S_____WORMWOOD.DESCRIBE.ICELEGUME_L = "Snow friend!"
S________WARLY.DESCRIBE.ICELEGUME_L = "Great, it's the beans I've been searching for for a long time!"
-- S_________WURT.DESCRIBE.ICELEGUME_L = ""
-- S_______WALTER.DESCRIBE.ICELEGUME_L = ""
-- S________WANDA.DESCRIBE.ICELEGUME_L = ""

S_NAMES.BEAN_L_ICE = "Ice Beans" --冰皂豆
S______GENERIC.DESCRIBE.BEAN_L_ICE = "Some cold beans."
S_______WILLOW.DESCRIBE.BEAN_L_ICE = "I hate cold food the most."
-- S_____WOLFGANG.DESCRIBE.BEAN_L_ICE = ""
-- S________WENDY.DESCRIBE.BEAN_L_ICE = ""
-- S_________WX78.DESCRIBE.BEAN_L_ICE = ""
S_WICKERBOTTOM.DESCRIBE.BEAN_L_ICE = "The oil contained in these beans can be used to make soap base."
-- S_______WOODIE.DESCRIBE.BEAN_L_ICE = ""
S______WAXWELL.DESCRIBE.BEAN_L_ICE = "My teeth can't stand it."
-- S___WATHGRITHR.DESCRIBE.BEAN_L_ICE = ""
S_______WEBBER.DESCRIBE.BEAN_L_ICE = "Very cold beans."
-- S_______WINONA.DESCRIBE.BEAN_L_ICE = ""
S_______WORTOX.DESCRIBE.BEAN_L_ICE = "Eat a few first to calm down."
S_____WORMWOOD.DESCRIBE.BEAN_L_ICE = "Snow child?"
S________WARLY.DESCRIBE.BEAN_L_ICE = "I instantly thought of many dishes made with beans!"
-- S_________WURT.DESCRIBE.BEAN_L_ICE = ""
S_______WALTER.DESCRIBE.BEAN_L_ICE = "Too small and brittle, not suitable as slingshot ammunition."
-- S________WANDA.DESCRIBE.BEAN_L_ICE = ""

S_NAMES.PEBBLEITEM_L_NITRE = "Gravel Fragments" --碎石块
S_RECIPE_DESC.PEBBLEITEM_L_NITRE = "Crush nitre and throw them on the ground."
S______GENERIC.DESCRIBE.PEBBLEITEM_L_NITRE = "Simple gravel decoration."
S_______WILLOW.DESCRIBE.PEBBLEITEM_L_NITRE = "Not good-looking."
-- S_____WOLFGANG.DESCRIBE.PEBBLEITEM_L_NITRE = ""
S________WENDY.DESCRIBE.PEBBLEITEM_L_NITRE = "Being treated as decoration is not its fault."
-- S_________WX78.DESCRIBE.PEBBLEITEM_L_NITRE = ""
S_WICKERBOTTOM.DESCRIBE.PEBBLEITEM_L_NITRE = "Simply being a decoration may not have much meaning."
S_______WOODIE.DESCRIBE.PEBBLEITEM_L_NITRE = "Will it not prick my feet?"
-- S______WAXWELL.DESCRIBE.PEBBLEITEM_L_NITRE = ""
-- S___WATHGRITHR.DESCRIBE.PEBBLEITEM_L_NITRE = ""
-- S_______WEBBER.DESCRIBE.PEBBLEITEM_L_NITRE = ""
S_______WINONA.DESCRIBE.PEBBLEITEM_L_NITRE = "I need to have enough aesthetics to use it better."
S_______WORTOX.DESCRIBE.PEBBLEITEM_L_NITRE = "Hmph, the raw materials for gunpowder are used as decorations."
S_____WORMWOOD.DESCRIBE.PEBBLEITEM_L_NITRE = "Bitter decor."
-- S________WARLY.DESCRIBE.PEBBLEITEM_L_NITRE = ""
-- S_________WURT.DESCRIBE.PEBBLEITEM_L_NITRE = ""
-- S_______WALTER.DESCRIBE.PEBBLEITEM_L_NITRE = ""
-- S________WANDA.DESCRIBE.PEBBLEITEM_L_NITRE = ""

S_NAMES.ROCK_L_NITRE = S_NAMES.NITRE_FORMATION or "Nitre Formation" --硝石堆
S______GENERIC.DESCRIBE.ROCK_L_NITRE = "A pile of pale yellow stones."
-- S_______WILLOW.DESCRIBE.ROCK_L_NITRE = ""
-- S_____WOLFGANG.DESCRIBE.ROCK_L_NITRE = ""
-- S________WENDY.DESCRIBE.ROCK_L_NITRE = ""
-- S_________WX78.DESCRIBE.ROCK_L_NITRE = ""
S_WICKERBOTTOM.DESCRIBE.ROCK_L_NITRE = "Nitre precipitated from acidic soil in a humid environment."
-- S_______WOODIE.DESCRIBE.ROCK_L_NITRE = ""
-- S______WAXWELL.DESCRIBE.ROCK_L_NITRE = ""
-- S___WATHGRITHR.DESCRIBE.ROCK_L_NITRE = ""
S_______WEBBER.DESCRIBE.ROCK_L_NITRE = "Interesting broken stones."
-- S_______WINONA.DESCRIBE.ROCK_L_NITRE = ""
-- S_______WORTOX.DESCRIBE.ROCK_L_NITRE = ""
S_____WORMWOOD.DESCRIBE.ROCK_L_NITRE = "Sour rocks."
-- S________WARLY.DESCRIBE.ROCK_L_NITRE = ""
-- S_________WURT.DESCRIBE.ROCK_L_NITRE = ""
-- S_______WALTER.DESCRIBE.ROCK_L_NITRE = ""
-- S________WANDA.DESCRIBE.ROCK_L_NITRE = ""

S_NAMES.PONDBLDG_SOAK = "Bubble-Soaking Shell" --澡花壳
S_RECIPE_DESC.PONDBLDG_SOAK = "Add some ingredients while bathing."
S_NAMES.PONDBLDG_SOAK_BLUEPRINT = "Bubble-Soaking Shell Blueprint"
S_RECIPE_DESC.NPC_BEEF_PONDBLDG_SOAK = "I haven't taken a shower in a long time..."
S______GENERIC.DESCRIBE.PONDBLDG_SOAK = "I need to put somethings for soaking inside."
-- S_______WILLOW.DESCRIBE.PONDBLDG_SOAK = ""
S_____WOLFGANG.DESCRIBE.PONDBLDG_SOAK = "Wolfgang's muscles are suitable for soaking in cold water."
-- S________WENDY.DESCRIBE.PONDBLDG_SOAK = ""
-- S_________WX78.DESCRIBE.PONDBLDG_SOAK = ""
S_WICKERBOTTOM.DESCRIBE.PONDBLDG_SOAK = "Many items can be put in to regulate our body, which is very useful..."
S_______WOODIE.DESCRIBE.PONDBLDG_SOAK = "Lucy asked me to put some very fragrant things."
-- S______WAXWELL.DESCRIBE.PONDBLDG_SOAK = ""
-- S___WATHGRITHR.DESCRIBE.PONDBLDG_SOAK = ""
S_______WEBBER.DESCRIBE.PONDBLDG_SOAK = "Let me reminisce about the past."
S_______WINONA.DESCRIBE.PONDBLDG_SOAK = "After a busy day, I want to add some petals and take a bath."
S_______WORTOX.DESCRIBE.PONDBLDG_SOAK = "Are we going to stew ourselves, hah."
S_____WORMWOOD.DESCRIBE.PONDBLDG_SOAK = "I want to add poop!"
S________WARLY.DESCRIBE.PONDBLDG_SOAK = "I'm soaking in water and adding ingredients to it, it's like making soup."
S_________WURT.DESCRIBE.PONDBLDG_SOAK = "I will eventually get used to the feeling of swimming."
-- S_______WALTER.DESCRIBE.PONDBLDG_SOAK = ""
-- S________WANDA.DESCRIBE.PONDBLDG_SOAK = ""

S_NAMES.PONDBLDG_FISH = "Fish-Farming Shell" --鱼栖壳
S_RECIPE_DESC.PONDBLDG_FISH = "The fish love living in it."
S_NAMES.PONDBLDG_FISH_BLUEPRINT = "Fish-Farming Shell Blueprint"
S_RECIPE_DESC.NPC_BEEF_PONDBLDG_FISH = "I prefer bartering to fish farming..."
S______GENERIC.DESCRIBE.PONDBLDG_FISH = "Fish farming is also a good choice."
S_______WILLOW.DESCRIBE.PONDBLDG_FISH = "The fish pond belongs to this girl, me!"
-- S_____WOLFGANG.DESCRIBE.PONDBLDG_FISH = ""
-- S________WENDY.DESCRIBE.PONDBLDG_FISH = ""
-- S_________WX78.DESCRIBE.PONDBLDG_FISH = ""
S_WICKERBOTTOM.DESCRIBE.PONDBLDG_FISH = "Feeding high-quality feed, regulating water environment, with many details."
-- S_______WOODIE.DESCRIBE.PONDBLDG_FISH = ""
-- S______WAXWELL.DESCRIBE.PONDBLDG_FISH = ""
S___WATHGRITHR.DESCRIBE.PONDBLDG_FISH = "Fish-farming is much easier than hunting."
S_______WEBBER.DESCRIBE.PONDBLDG_FISH = "We want to raise a super large fish!"
-- S_______WINONA.DESCRIBE.PONDBLDG_FISH = ""
S_______WORTOX.DESCRIBE.PONDBLDG_FISH = "Fish-farming comes first, fish-eating comes later."
S_____WORMWOOD.DESCRIBE.PONDBLDG_FISH = "Get a lot of fish..."
S________WARLY.DESCRIBE.PONDBLDG_FISH = "Big and fat fish are all kept inside."
S_________WURT.DESCRIBE.PONDBLDG_FISH = "Can I live in, flort?"
-- S_______WALTER.DESCRIBE.PONDBLDG_FISH = ""
-- S________WANDA.DESCRIBE.PONDBLDG_FISH = ""

--------------------------------------------------------------------------
--[[ legends of the fall ]]--[[ 丰饶传说 ]]
--------------------------------------------------------------------------

S_NAMES.PINEANANAS = "Pineananas" --松萝
S______GENERIC.DESCRIBE.PINEANANAS = "Eating it raw may numb my mouth."
-- S_______WILLOW.DESCRIBE.PINEANANAS = ""
-- S_____WOLFGANG.DESCRIBE.PINEANANAS = ""
-- S________WENDY.DESCRIBE.PINEANANAS = ""
-- S_________WX78.DESCRIBE.PINEANANAS = ""
-- S_WICKERBOTTOM.DESCRIBE.PINEANANAS = ""
-- S_______WOODIE.DESCRIBE.PINEANANAS = ""
-- S______WAXWELL.DESCRIBE.PINEANANAS = ""
-- S___WATHGRITHR.DESCRIBE.PINEANANAS = ""
-- S_______WEBBER.DESCRIBE.PINEANANAS = ""
-- S_______WINONA.DESCRIBE.PINEANANAS = ""
-- S_______WORTOX.DESCRIBE.PINEANANAS = ""
-- S_____WORMWOOD.DESCRIBE.PINEANANAS = ""
-- S________WARLY.DESCRIBE.PINEANANAS = ""
-- S_________WURT.DESCRIBE.PINEANANAS = ""
-- S_______WALTER.DESCRIBE.PINEANANAS = ""

S_NAMES.PINEANANAS_COOKED = "Roasted Pineananas" --烤松萝
S______GENERIC.DESCRIBE.PINEANANAS_COOKED = "It tastes much better after roasted."
-- S_______WILLOW.DESCRIBE.PINEANANAS_COOKED = ""
-- S_____WOLFGANG.DESCRIBE.PINEANANAS_COOKED = ""
-- S________WENDY.DESCRIBE.PINEANANAS_COOKED = ""
-- S_________WX78.DESCRIBE.PINEANANAS_COOKED = ""
-- S_WICKERBOTTOM.DESCRIBE.PINEANANAS_COOKED = ""
-- S_______WOODIE.DESCRIBE.PINEANANAS_COOKED = ""
-- S______WAXWELL.DESCRIBE.PINEANANAS_COOKED = ""
-- S___WATHGRITHR.DESCRIBE.PINEANANAS_COOKED = ""
-- S_______WEBBER.DESCRIBE.PINEANANAS_COOKED = ""
-- S_______WINONA.DESCRIBE.PINEANANAS_COOKED = ""
-- S_______WORTOX.DESCRIBE.PINEANANAS_COOKED = ""
-- S_____WORMWOOD.DESCRIBE.PINEANANAS_COOKED = ""
-- S________WARLY.DESCRIBE.PINEANANAS_COOKED = ""
-- S_________WURT.DESCRIBE.PINEANANAS_COOKED = ""
-- S_______WALTER.DESCRIBE.PINEANANAS_COOKED = ""

S_NAMES.PINEANANAS_SEEDS = "Chimeric Seeds" --嵌合种子
S______GENERIC.DESCRIBE.PINEANANAS_SEEDS = "I'm not sure if it should be a pinecone or pineapple seed."
-- S_______WILLOW.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_____WOLFGANG.DESCRIBE.PINEANANAS_SEEDS = ""
-- S________WENDY.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_________WX78.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_WICKERBOTTOM.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_______WOODIE.DESCRIBE.PINEANANAS_SEEDS = ""
-- S______WAXWELL.DESCRIBE.PINEANANAS_SEEDS = ""
-- S___WATHGRITHR.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_______WEBBER.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_______WINONA.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_______WORTOX.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_____WORMWOOD.DESCRIBE.PINEANANAS_SEEDS = ""
-- S________WARLY.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_________WURT.DESCRIBE.PINEANANAS_SEEDS = ""
-- S_______WALTER.DESCRIBE.PINEANANAS_SEEDS = ""

S_NAMES.PINEANANAS_OVERSIZED = "Giant Pineananas" --巨型松萝
S______GENERIC.DESCRIBE.PINEANANAS_OVERSIZED = "What a big orange pinecone!"
-- S_______WILLOW.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_____WOLFGANG.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S________WENDY.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_________WX78.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_WICKERBOTTOM.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_______WOODIE.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S______WAXWELL.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S___WATHGRITHR.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_______WEBBER.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_______WINONA.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_______WORTOX.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_____WORMWOOD.DESCRIBE.PINEANANAS_OVERSIZED = ""
S________WARLY.DESCRIBE.PINEANANAS_OVERSIZED = "I think of many sweet memori... err, dishes!"
-- S_________WURT.DESCRIBE.PINEANANAS_OVERSIZED = ""
-- S_______WALTER.DESCRIBE.PINEANANAS_OVERSIZED = ""

S_NAMES.PINEANANAS_OVERSIZED_ROTTEN = "Giant Rotting Pineananas"
S_NAMES.FARM_PLANT_PINEANANAS = "Pineananas Tree"
S_NAMES.KNOWN_PINEANANAS_SEEDS = "Pineananas Seeds"
STRINGS.UI.PLANTREGISTRY.DESCRIPTIONS.PINEANANAS = "A straight foot is not afraid of a crooked shoe. -W"

-----

S_NAMES.CROPGNAT = "Pest Swarm"    --植害虫群
S______GENERIC.DESCRIBE.CROPGNAT = "Hey, stay away from my crops, you pests!"
S_______WILLOW.DESCRIBE.CROPGNAT = "Do they like fire, too?"
S_____WOLFGANG.DESCRIBE.CROPGNAT = "Fortunately, they don't bite Wolfgang."
-- S________WENDY.DESCRIBE.CROPGNAT = ""
-- S_________WX78.DESCRIBE.CROPGNAT = ""
S_WICKERBOTTOM.DESCRIBE.CROPGNAT = "Find ways to kill them early, or we'll get nothing!"
-- S_______WOODIE.DESCRIBE.CROPGNAT = ""
-- S______WAXWELL.DESCRIBE.CROPGNAT = ""
-- S___WATHGRITHR.DESCRIBE.CROPGNAT = ""
S_______WEBBER.DESCRIBE.CROPGNAT = "I broke my neighbours neighbor's window before and they called me a pest."
-- S_______WINONA.DESCRIBE.CROPGNAT = ""
-- S_______WORTOX.DESCRIBE.CROPGNAT = ""
S_____WORMWOOD.DESCRIBE.CROPGNAT = "Some friends who would hurt a plant friend."
-- S________WARLY.DESCRIBE.CROPGNAT = ""
-- S_________WURT.DESCRIBE.CROPGNAT = ""
-- S_______WALTER.DESCRIBE.CROPGNAT = ""
-- S________WANDA.DESCRIBE.CROPGNAT = ""

S_NAMES.CROPGNAT_INFESTER = "Gnat Swarm"    --叮咬虫群
S______GENERIC.DESCRIBE.CROPGNAT_INFESTER = "Be careful, these bugs bite."
S_______WILLOW.DESCRIBE.CROPGNAT_INFESTER = "Stupid bugs will be attracted by my fire."
S_____WOLFGANG.DESCRIBE.CROPGNAT_INFESTER = "Ouch! these little monsters bite!"
-- S________WENDY.DESCRIBE.CROPGNAT_INFESTER = ""
S_________WX78.DESCRIBE.CROPGNAT_INFESTER = "THEY EVEN BITE IRON?"
S_WICKERBOTTOM.DESCRIBE.CROPGNAT_INFESTER = "Aggressive and can be attracted by light."
-- S_______WOODIE.DESCRIBE.CROPGNAT_INFESTER = ""
-- S______WAXWELL.DESCRIBE.CROPGNAT_INFESTER = ""
-- S___WATHGRITHR.DESCRIBE.CROPGNAT_INFESTER = ""
-- S_______WEBBER.DESCRIBE.CROPGNAT_INFESTER = ""
S_______WINONA.DESCRIBE.CROPGNAT_INFESTER = "Oh my, the noise is terrible."
S_______WORTOX.DESCRIBE.CROPGNAT_INFESTER = "Hah, you have to get used to this in the wild."
S_____WORMWOOD.DESCRIBE.CROPGNAT_INFESTER = "Some friends who would bite a friend."
-- S________WARLY.DESCRIBE.CROPGNAT_INFESTER = ""
-- S_________WURT.DESCRIBE.CROPGNAT_INFESTER = ""
-- S_______WALTER.DESCRIBE.CROPGNAT_INFESTER = ""
-- S________WANDA.DESCRIBE.CROPGNAT_INFESTER = ""

S_NAMES.AHANDFULOFWINGS = "Broken Insect Wings" --虫翅碎片
S______GENERIC.DESCRIBE.AHANDFULOFWINGS = "I wonder what kind of bug wings these are."
S_______WILLOW.DESCRIBE.AHANDFULOFWINGS = "Cruel and disgusting."
-- S_____WOLFGANG.DESCRIBE.AHANDFULOFWINGS = ""
-- S________WENDY.DESCRIBE.AHANDFULOFWINGS = ""
S_________WX78.DESCRIBE.AHANDFULOFWINGS = "THE WING PART OF SOME INSECT'S REMAINS."
S_WICKERBOTTOM.DESCRIBE.AHANDFULOFWINGS = "Why pull the wings of insects off?"
-- S_______WOODIE.DESCRIBE.AHANDFULOFWINGS = ""
-- S______WAXWELL.DESCRIBE.AHANDFULOFWINGS = ""
S___WATHGRITHR.DESCRIBE.AHANDFULOFWINGS = "It's easy to sort them out."
-- S_______WEBBER.DESCRIBE.AHANDFULOFWINGS = ""
-- S_______WINONA.DESCRIBE.AHANDFULOFWINGS = ""
S_______WORTOX.DESCRIBE.AHANDFULOFWINGS = "Even these little ones have souls."
-- S_____WORMWOOD.DESCRIBE.AHANDFULOFWINGS = ""
-- S________WARLY.DESCRIBE.AHANDFULOFWINGS = ""
-- S_________WURT.DESCRIBE.AHANDFULOFWINGS = ""
-- S_______WALTER.DESCRIBE.AHANDFULOFWINGS = ""
-- S________WANDA.DESCRIBE.AHANDFULOFWINGS = ""

S_NAMES.INSECTSHELL_L = "Broken Insect Shells" --虫甲碎片
S______GENERIC.DESCRIBE.INSECTSHELL_L = "I wonder what kind of bug shells these are."
-- S_______WILLOW.DESCRIBE.INSECTSHELL_L = ""
-- S_____WOLFGANG.DESCRIBE.INSECTSHELL_L = ""
-- S________WENDY.DESCRIBE.INSECTSHELL_L = ""
S_________WX78.DESCRIBE.INSECTSHELL_L = "THE EXOSKELETON OF SOME INSECT'S REMAINS."
S_WICKERBOTTOM.DESCRIBE.INSECTSHELL_L = "Why collect insect shells separately?"
-- S_______WOODIE.DESCRIBE.INSECTSHELL_L = ""
-- S______WAXWELL.DESCRIBE.INSECTSHELL_L = ""
S___WATHGRITHR.DESCRIBE.INSECTSHELL_L = "It's easy to sort them out."
-- S_______WEBBER.DESCRIBE.INSECTSHELL_L = ""
-- S_______WINONA.DESCRIBE.INSECTSHELL_L = ""
S_______WORTOX.DESCRIBE.INSECTSHELL_L = "Even these small ones have souls."
-- S_____WORMWOOD.DESCRIBE.INSECTSHELL_L = ""
-- S________WARLY.DESCRIBE.INSECTSHELL_L = ""
-- S_________WURT.DESCRIBE.INSECTSHELL_L = ""
-- S_______WALTER.DESCRIBE.INSECTSHELL_L = ""
-- S________WANDA.DESCRIBE.INSECTSHELL_L = ""

S_NAMES.BOLTWINGOUT = "Boltwing-out"    --脱壳之翅
S_RECIPE_DESC.BOLTWINGOUT = "Make a bolt for it."
S______GENERIC.DESCRIBE.BOLTWINGOUT = "Bolt out of threats."
-- S_______WILLOW.DESCRIBE.BOLTWINGOUT = ""
-- S_____WOLFGANG.DESCRIBE.BOLTWINGOUT = ""
-- S________WENDY.DESCRIBE.BOLTWINGOUT = ""
-- S_________WX78.DESCRIBE.BOLTWINGOUT = ""
-- S_WICKERBOTTOM.DESCRIBE.BOLTWINGOUT = ""
-- S_______WOODIE.DESCRIBE.BOLTWINGOUT = ""
S______WAXWELL.DESCRIBE.BOLTWINGOUT = "Learning the way of insect survival."
S___WATHGRITHR.DESCRIBE.BOLTWINGOUT = "Tsk-tsk! A real warrior never runs away!"
-- S_______WEBBER.DESCRIBE.BOLTWINGOUT = ""
S_______WINONA.DESCRIBE.BOLTWINGOUT = "I just wanna run and hide away!"
S_______WORTOX.DESCRIBE.BOLTWINGOUT = "Meh, I can do the same thing with souls."
-- S_____WORMWOOD.DESCRIBE.BOLTWINGOUT = ""
-- S________WARLY.DESCRIBE.BOLTWINGOUT = ""
-- S_________WURT.DESCRIBE.BOLTWINGOUT = ""
-- S_______WALTER.DESCRIBE.BOLTWINGOUT = ""
-- S________WANDA.DESCRIBE.BOLTWINGOUT = ""

S_NAMES.BOLTWINGOUT_SHUCK = "Post-Eclosion Shuck"  --羽化后的壳
S______GENERIC.DESCRIBE.BOLTWINGOUT_SHUCK = "Hah! Most creatures don't know it's just a shuck."
S_______WILLOW.DESCRIBE.BOLTWINGOUT_SHUCK = "What a big fake bug, I can burn it!"
-- S_____WOLFGANG.DESCRIBE.BOLTWINGOUT_SHUCK = ""
-- S________WENDY.DESCRIBE.BOLTWINGOUT_SHUCK = ""
S_________WX78.DESCRIBE.BOLTWINGOUT_SHUCK = "A CRAFTY BUG!"
-- S_WICKERBOTTOM.DESCRIBE.BOLTWINGOUT_SHUCK = ""
-- S_______WOODIE.DESCRIBE.BOLTWINGOUT_SHUCK = ""
S______WAXWELL.DESCRIBE.BOLTWINGOUT_SHUCK = "For the weak, escape is the best policy."
-- S___WATHGRITHR.DESCRIBE.BOLTWINGOUT_SHUCK = ""
S_______WEBBER.DESCRIBE.BOLTWINGOUT_SHUCK = "We'll not want our old skin after molting."
S_______WINONA.DESCRIBE.BOLTWINGOUT_SHUCK = "The shuck is not a shuck."
-- S_______WORTOX.DESCRIBE.BOLTWINGOUT_SHUCK = ""
S_____WORMWOOD.DESCRIBE.BOLTWINGOUT_SHUCK = "Hey friend, are you still here?"
-- S________WARLY.DESCRIBE.BOLTWINGOUT_SHUCK = ""
-- S_________WURT.DESCRIBE.BOLTWINGOUT_SHUCK = ""
-- S_______WALTER.DESCRIBE.BOLTWINGOUT_SHUCK = ""
-- S________WANDA.DESCRIBE.BOLTWINGOUT_SHUCK = ""

S_NAMES.MINT_L = "Catmint" --猫薄荷
S______GENERIC.DESCRIBE.MINT_L = "It smells clean and natural."
-- S_______WILLOW.DESCRIBE.MINT_L = ""
S_____WOLFGANG.DESCRIBE.MINT_L = "Wolfgang misses chewing gum."
-- S________WENDY.DESCRIBE.MINT_L = ""
S_________WX78.DESCRIBE.MINT_L = "JUST SOME COMMON WEED LEAVES."
S_WICKERBOTTOM.DESCRIBE.MINT_L = "Seriously, mint is not the same plant as catmint."
-- S_______WOODIE.DESCRIBE.MINT_L = ""
-- S______WAXWELL.DESCRIBE.MINT_L = ""
-- S___WATHGRITHR.DESCRIBE.MINT_L = ""
S_______WEBBER.DESCRIBE.MINT_L = "How about feeding it to catcoons in the forest?"
-- S_______WINONA.DESCRIBE.MINT_L = ""
S_______WORTOX.DESCRIBE.MINT_L = "Nah, I don't like it."
S_____WORMWOOD.DESCRIBE.MINT_L = "Hello, fragrant friend."
S________WARLY.DESCRIBE.MINT_L = "I wish I could use it as a spice."
S_________WURT.DESCRIBE.MINT_L = "Good for vegetarianism, good for me."
-- S_______WALTER.DESCRIBE.MINT_L = ""
-- S________WANDA.DESCRIBE.MINT_L = ""

S_NAMES.CATTENBALL = "Cat Wool Ball" --猫线球
S_RECIPE_DESC.NPC_BEEF_CATTENBALL = "When playing with cats, they may spit out this..."
S______GENERIC.DESCRIBE.CATTENBALL = "Although it was vomited up, it's lovely."
-- S_______WILLOW.DESCRIBE.CATTENBALL = ""
-- S_____WOLFGANG.DESCRIBE.CATTENBALL = ""
-- S________WENDY.DESCRIBE.CATTENBALL = ""
S_________WX78.DESCRIBE.CATTENBALL = "SMELLS LIKE A CAT."
-- S_WICKERBOTTOM.DESCRIBE.CATTENBALL = ""
-- S_______WOODIE.DESCRIBE.CATTENBALL = ""
-- S______WAXWELL.DESCRIBE.CATTENBALL = ""
-- S___WATHGRITHR.DESCRIBE.CATTENBALL = ""
S_______WEBBER.DESCRIBE.CATTENBALL = "We must have a toy show!"
S_______WINONA.DESCRIBE.CATTENBALL = "Maybe it can be used to knit sweaters."
S_______WORTOX.DESCRIBE.CATTENBALL = "Look! The same lovable color as me."
-- S_____WORMWOOD.DESCRIBE.CATTENBALL = ""
-- S________WARLY.DESCRIBE.CATTENBALL = ""
S_________WURT.DESCRIBE.CATTENBALL = "A witch living in the desert mirage would love this!"
-- S_______WALTER.DESCRIBE.CATTENBALL = ""
-- S________WANDA.DESCRIBE.CATTENBALL = ""

S_NAMES.SIVING_ROCKS = "Siving Stone"   --子圭石
S______GENERIC.DESCRIBE.SIVING_ROCKS = "A lively power is roaming inside."
S_______WILLOW.DESCRIBE.SIVING_ROCKS = "Weird, I don't want to burn it at all."
S_____WOLFGANG.DESCRIBE.SIVING_ROCKS = "Pretty little stone."
S________WENDY.DESCRIBE.SIVING_ROCKS = "I'm wasting my time, I got nothing to do."
S_________WX78.DESCRIBE.SIVING_ROCKS = "LIKE ME, NON-CARBON BASED LIFE."
S_WICKERBOTTOM.DESCRIBE.SIVING_ROCKS = "I'm shocked that this ore has life activity!"
S_______WOODIE.DESCRIBE.SIVING_ROCKS = "It looks like a leaf."
S______WAXWELL.DESCRIBE.SIVING_ROCKS = "Is this the legendary..."
S___WATHGRITHR.DESCRIBE.SIVING_ROCKS = "Is it fallen leaves of the world tree?!"
S_______WEBBER.DESCRIBE.SIVING_ROCKS = "Hee hee, our rare stones collection has increased!"
S_______WINONA.DESCRIBE.SIVING_ROCKS = "I feel like it's looking back at me."
S_______WORTOX.DESCRIBE.SIVING_ROCKS = "Really unusual for this to be in this world."
S_____WORMWOOD.DESCRIBE.SIVING_ROCKS = "Part of a stone friend."
S________WARLY.DESCRIBE.SIVING_ROCKS = "If it doesn't involve my field, I won't say more."
S_________WURT.DESCRIBE.SIVING_ROCKS = "I've seen this in my hometown."
S_______WALTER.DESCRIBE.SIVING_ROCKS = "Aha, species discovery!"
S________WANDA.DESCRIBE.SIVING_ROCKS = "It's dazzling in the sun."

S_NAMES.SIVING_DERIVANT_ITEM = "Siving Derivant"  --子圭奇型岩
S______GENERIC.DESCRIBE.SIVING_DERIVANT_ITEM = "I'd like to see what it'll look like."
-- S_______WILLOW.DESCRIBE.SIVING_DERIVANT_ITEM = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_DERIVANT_ITEM = ""
-- S________WENDY.DESCRIBE.SIVING_DERIVANT_ITEM = ""
-- S_________WX78.DESCRIBE.SIVING_DERIVANT_ITEM = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_DERIVANT_ITEM = "It's worth studying after planting."
-- S_______WOODIE.DESCRIBE.SIVING_DERIVANT_ITEM = ""
S______WAXWELL.DESCRIBE.SIVING_DERIVANT_ITEM = "It's rare. Don't let me down."
S___WATHGRITHR.DESCRIBE.SIVING_DERIVANT_ITEM = "Is it a derivant of the world tree?!"
-- S_______WEBBER.DESCRIBE.SIVING_DERIVANT_ITEM = ""
-- S_______WINONA.DESCRIBE.SIVING_DERIVANT_ITEM = ""
S_______WORTOX.DESCRIBE.SIVING_DERIVANT_ITEM = "Bad memories flooded into my mind."
S_____WORMWOOD.DESCRIBE.SIVING_DERIVANT_ITEM = "Stone friend's child is still sleeping."
-- S________WARLY.DESCRIBE.SIVING_DERIVANT_ITEM = ""
S_________WURT.DESCRIBE.SIVING_DERIVANT_ITEM = "This is it's seed, which needs to be planted in the soil."
-- S_______WALTER.DESCRIBE.SIVING_DERIVANT_ITEM = ""
-- S________WANDA.DESCRIBE.SIVING_DERIVANT_ITEM = ""

S_NAMES.SIVING_DERIVANT = "Siving Derivant" --子圭奇型岩
S_NAMES.SIVING_DERIVANT_WAXED = "Fuel-Woven Siving Derivant"
S_NAMES.SIVING_DERIVANT_ITEM_WAXED = "Fuel-Woven Siving Derivant"
S______GENERIC.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "It's going to take some time.",
    LV1 = "Great, it's finally grown up a little.",
    LV2 = "That's great, it looks good.",
    LV3 = "The stone grows luxuriantly.",
    NOTTHIS = "It requires the energy of life and light."
}
S_______WILLOW.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "Doesn't burn. I don't like it.",
    LV1 = "Doesn't burn. I don't like it.",
    LV2 = "Doesn't burn. I don't like it.",
    LV3 = "Doesn't burn. I don't like it.",
    NOTTHIS = "No? So what."
}
S________WENDY.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "Full of hope.",
    LV1 = "Full of hope.",
    LV2 = "Full of hope.",
    LV3 = "Full of hope.",
    NOTTHIS = "It longs for life and pursues light."
}
S_WICKERBOTTOM.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "It's worth studying.",
    LV1 = "Worth watching for sure.",
    LV2 = "I will continue to study it.",
    LV3 = "Should be its final form.",
    NOTTHIS = "The purified energy of life and light is what it can absorb."
}
S_______WOODIE.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "It's a bit like a tree stump.",
    LV1 = "Axes don't seem to do anything to it.",
    LV2 = "Axes don't seem to do anything to it.",
    LV3 = "Lucy naively thought it was a tree.",
    NOTTHIS = "What does a tree need for growth?"
}
S___WATHGRITHR.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "I hope it can grow into a world tree.",
    LV1 = "I hope it can grow into a world tree.",
    LV2 = "I hope it can grow into a world tree.",
    LV3 = "It seems that it won't grow as big as a world tree.",
    NOTTHIS = "It is an honor for you to accept the gift of a warrior."
}
S_______WORTOX.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "There is a tragic and mysterious history about it.",
    LV1 = "That happened thousands of years ago, I heard it from an old lady.",
    LV2 = "The green fire meteor swept across the sky, accompanied by a huge earthquake, and it came.",
    LV3 = "This thing thrives on life, so the Crab Man decides to destroy it.",
    NOTTHIS = "I have an ominous premonition."
}
S_____WORMWOOD.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "Stone friend's child wakes up.",
    LV1 = "Growing steadily.",
    LV2 = "It's taller than me!",
    LV3 = "Its heart has changed.",
    NOTTHIS = "It doesn't want this."
}
S________WARLY.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "Strange.",
    LV1 = "Strange.",
    LV2 = "Strange.",
    LV3 = "Strange.",
    NOTTHIS = "This stone tree is as picky eater as I am."
}
S_________WURT.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "Just wait for it, glorp.",
    LV1 = "I've never planted it alive, florpt!",
    LV2 = "I've never planted it alive, florpt!",
    LV3 = "Deep in the forest of my hometown there's lots of these.",
    NOTTHIS = "What exactly do you want?"
}
S________WANDA.DESCRIBE.SIVING_DERIVANT = {
    GENERIC = "It takes more than a little time.",
    LV1 = "It needs more than just a little more time to grow.",
    LV2 = "Almost time no time at all for me.",
    LV3 = "It's amazing, but I'm also not surprised.",
    NOTTHIS = "I still have many opportunities to try and make mistakes."
}

S_NAMES.SIVING_THETREE = "Siving Alpha" --子圭神木岩
S_NAMES.SIVING_THETREE_WAXED = "Fuel-Woven Siving Alpha"
S_NAMES.SIVING_THETREE_ITEM_WAXED = "Fuel-Woven Siving Alpha"
S______GENERIC.DESCRIBE.SIVING_THETREE = {
    GENERIC = "My life bows to its mysterious majesty.",
    NEEDALL = "It says it needs the energy of vitality and light.",
    NEEDLIGHT = "It says it still needs the energy of light.",
    NEEDHEALTH = "It says it still needs the energy of vitality.",
    NONEED = "It seems that everything is ready.",
    NOTTHIS = "It doesn't want this."
}
S_______WILLOW.DESCRIBE.SIVING_THETREE = {
    GENERIC = "It cannot burn, but it can burn the fire of life.",
    NEEDALL = "Hum, it unexpectedly asked me for the energy of vitality and light.",
    NEEDLIGHT = "It even needs such precious the energy of light.",
    NEEDHEALTH = "My hand hurts for the energy of vitality, but it still needs it?!",
    NONEED = "Girl's mission is finally over.",
    NOTTHIS = "Forget it."
}
S_____WOLFGANG.DESCRIBE.SIVING_THETREE = {
    GENERIC = "Wolfgang shouldn't be so close to Kryptonite.",
    NEEDALL = "It wants Wolfgang's the energy of vitality and light.",
    NEEDLIGHT = "It still wants Wolfgang's the energy of light.",
    NEEDHEALTH = "It still wants Wolfgang's the energy of vitality.",
    NONEED = "It no longer needs Wolfgang.",
    NOTTHIS = "Does it despise Wolfgang's items?"
}
S________WENDY.DESCRIBE.SIVING_THETREE = {
    GENERIC = "Leading me to death peacefully, what a relief.",
    NEEDALL = "The sacrificial ceremony needs the energy of vitality and light.",
    NEEDLIGHT = "The energy of light is also needed in the sacrifice process.",
    NEEDHEALTH = "The energy of vitality is also needed in the sacrifice process.",
    NONEED = "Everything is ready. Let's start the ceremony.",
    NOTTHIS = "This is a useless sacrifice."
}
S_________WX78.DESCRIBE.SIVING_THETREE = {
    GENERIC = "EAGER TO TAKE LIFE.",
    NEEDALL = "WHY DOES IT WANT THE ENERGY OF VITALITY AND LIGHT?",
    NEEDLIGHT = "THE ENERGY OF LIGHT. WHY SHOULD I GIVE IT THIS.",
    NEEDHEALTH = "THE ENERGY OF VITALITY. WHY SHOULD I GIVE IT THIS.",
    NONEED = "I HOPE IT CAN GIVE ME MORE POWERFUL CHIPS.",
    NOTTHIS = "USELESS."
}
S_WICKERBOTTOM.DESCRIBE.SIVING_THETREE = {
    GENERIC = "DANGER! It has a life attraction like a black hole.",
    NEEDALL = "The energy of vitality and light, it can actually telepathize with me.",
    NEEDLIGHT = "It also needs the energy of light. I don't understand the intention of this alien.",
    NEEDHEALTH = "It also needs the energy of vitality. I don't understand the intention of this alien.",
    NONEED = "That's it. I hope what follows is a feast of knowledge.",
    NOTTHIS = "I don't need this."
}
S_______WOODIE.DESCRIBE.SIVING_THETREE = {
    GENERIC = "Lucy, don't try to chop it down.",
    NEEDALL = "The energy of vitality and light, should I follow the instructions, Lucy?",
    NEEDLIGHT = "It's really demanding. It still needs the energy of light.",
    NEEDHEALTH = "It's really demanding. It still needs the energy of vitality.",
    NONEED = "Finished. Will it create a forest for me to chop?",
    NOTTHIS = "It doesn't want this."
}
S______WAXWELL.DESCRIBE.SIVING_THETREE = {
    GENERIC = "It doesn't look like Charlie's work.",
    NEEDALL = "The mysterious tree needs the energy of vitality and light. It's really suspicious.",
    NEEDLIGHT = "Suspicious tree also need the energy of light.",
    NEEDHEALTH = "Suspicious tree also need the energy of vitality.",
    NONEED = "It's over.",
    NOTTHIS = "Not this one."
}
S___WATHGRITHR.DESCRIBE.SIVING_THETREE = {
    GENERIC = "Ode to Yggdrasill!",
    NEEDALL = "Yggdrasil wants the energy of vitality and light. I'll find it right away.",
    NEEDLIGHT = "Yggdrasil also needs the energy of light.",
    NEEDHEALTH = "Yggdrasil also needs the energy of vitality.",
    NONEED = "I'm ready to accept the gift of Yggdrasil!",
    NOTTHIS = "The requirements of Yggdrasil are very clear."
}
S_______WEBBER.DESCRIBE.SIVING_THETREE = {
    GENERIC = "We really want to climb up and play.",
    NEEDALL = "The energy of vitality and light, what are these two?",
    NEEDLIGHT = "The energy of light is hard to find. Want more?",
    NEEDHEALTH = "It's hard to make the energy of vitality. Want more?",
    NONEED = "It's done. We'll have a nice adventure time!",
    NOTTHIS = "Can't we use other items?"
}
S_______WINONA.DESCRIBE.SIVING_THETREE = {
    GENERIC = "What beautiful lines.",
    NEEDALL = "The energy of vitality and light. It has its own requirements?!",
    NEEDLIGHT = "It still wants to absorb the energy of light.",
    NEEDHEALTH = "It still wants to absorb the energy of vitality.",
    NONEED = "What will happen after the transformation?",
    NOTTHIS = "It won't want it."
}
S_______WORTOX.DESCRIBE.SIVING_THETREE = {
    GENERIC = "This thing wants my vitality, but my soul is too strong for it.",
    NEEDALL = "This thing told me that it wants the energy of vitality and light.",
    NEEDLIGHT = "This thing said it also wanted the energy of light.",
    NEEDHEALTH = "This thing said it also wanted the energy of vitality.",
    NONEED = "I was deceived. I've got to run away!",
    NOTTHIS = "Dear, this is wrong."
}
S_____WORMWOOD.DESCRIBE.SIVING_THETREE = {
    GENERIC = "Is this still a friend?",
    NEEDALL = "It wants light and vital energy.",
    NEEDLIGHT = "It wants light.",
    NEEDHEALTH = "It wants vital energy",
    NONEED = "Trees help trees.",
    NOTTHIS = "No."
}
S________WARLY.DESCRIBE.SIVING_THETREE = {
    GENERIC = "My vitality is as delicious as my cooking.",
    NEEDALL = "It said that the energy of vitality and light are the secret recipe of luxury feast.",
    NEEDLIGHT = "The luxury feast also needs the energy of light.",
    NEEDHEALTH = "The luxury feast also needs the energy of vitality.",
    NONEED = "What will the luxury feast look like? I'm so curious!",
    NOTTHIS = "I'm not here to make trouble."
}
S_________WURT.DESCRIBE.SIVING_THETREE = {
    GENERIC = "Why isn't it as safe as home, glorp?",
    NEEDALL = "I should have seen the energy of vitality and light somewhere.",
    NEEDLIGHT = "It's asking me for the energy of light, glort.",
    NEEDHEALTH = "It's asking me for the energy of vitality, glort.",
    NONEED = "It says to show me the greatness of life, flort.",
    NOTTHIS = "Grrr, it's wrong."
}
S_______WALTER.DESCRIBE.SIVING_THETREE = {
    GENERIC = "The closer to the truth, the more dangerous it is.",
    NEEDALL = "It needs the energy of vitality and light. Is it giving me orders?",
    NEEDLIGHT = "It said it needed the energy of light to save it.",
    NEEDHEALTH = "It said it needed the energy of vitality to save it.",
    NONEED = "I saved you. Remember to send me a medal.",
    NOTTHIS = "I shouldn't have made such a mistake."
}
S________WANDA.DESCRIBE.SIVING_THETREE = {
    GENERIC = "As soon as I got close to it, I felt that my time was speeding up.",
    NEEDALL = "I know what it wants, the energy of vitality and light!",
    NEEDLIGHT = "The energy of light. I'll make the same mistake again.",
    NEEDHEALTH = "The energy of vitality. I just want to try another ending.",
    NONEED = "I have been ready many times.",
    NOTTHIS = "I don't think so."
}

S_NAMES.SIVING_SOIL_ITEM = "Siving-Soil"   --未放置的子圭·垄
S_RECIPE_DESC.SIVING_SOIL_ITEM = "An unusual soil bursting with vitality energy."
S______GENERIC.DESCRIBE.SIVING_SOIL_ITEM = "Put it down, and plant a seed."
-- S_______WILLOW.DESCRIBE.SIVING_SOIL_ITEM = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_SOIL_ITEM = ""
S________WENDY.DESCRIBE.SIVING_SOIL_ITEM = "Traps seeds souls in the cage of vitality."
-- S_________WX78.DESCRIBE.SIVING_SOIL_ITEM = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_SOIL_ITEM = "It can provide an environment for plant regeneration."
-- S_______WOODIE.DESCRIBE.SIVING_SOIL_ITEM = ""
-- S______WAXWELL.DESCRIBE.SIVING_SOIL_ITEM = ""
S___WATHGRITHR.DESCRIBE.SIVING_SOIL_ITEM = "I don't really need this, but my friends do."
-- S_______WEBBER.DESCRIBE.SIVING_SOIL_ITEM = ""
-- S_______WINONA.DESCRIBE.SIVING_SOIL_ITEM = ""
S_______WORTOX.DESCRIBE.SIVING_SOIL_ITEM = "Living soil, how unusual."
-- S_____WORMWOOD.DESCRIBE.SIVING_SOIL_ITEM = ""
S________WARLY.DESCRIBE.SIVING_SOIL_ITEM = "Fresh ingredients grower."
S_________WURT.DESCRIBE.SIVING_SOIL_ITEM = "I'm interested, florp."
-- S_______WALTER.DESCRIBE.SIVING_SOIL_ITEM = ""
-- S________WANDA.DESCRIBE.SIVING_SOIL_ITEM = ""

S_NAMES.SIVING_SOIL = "Siving-Soil"    --子圭·垄
S______GENERIC.DESCRIBE.SIVING_SOIL = "First step of planting, one big step of being stuffed."
S_______WILLOW.DESCRIBE.SIVING_SOIL = "Sow, germinate, mature, burn!"
S_____WOLFGANG.DESCRIBE.SIVING_SOIL = "My industrious hands are ready."
S________WENDY.DESCRIBE.SIVING_SOIL = "I'm still considering whether to continue."
S_________WX78.DESCRIBE.SIVING_SOIL = "THIS CAN BE A SOURCE OF CLEAN FUEL."
S_WICKERBOTTOM.DESCRIBE.SIVING_SOIL = "The regeneration environment has been placed."
S_______WOODIE.DESCRIBE.SIVING_SOIL = "Who remembers when I was just an ordinary lumberjack..."
S______WAXWELL.DESCRIBE.SIVING_SOIL = "Even if I have to do this, I have to be a decent farmer."
S___WATHGRITHR.DESCRIBE.SIVING_SOIL = "I prefer a wonderful battle."
S_______WEBBER.DESCRIBE.SIVING_SOIL = "What time is it? It's Cultivation time!"
S_______WINONA.DESCRIBE.SIVING_SOIL = "Nothing to say about sowing."
S_______WORTOX.DESCRIBE.SIVING_SOIL = "You must reap what you have sown."
S_____WORMWOOD.DESCRIBE.SIVING_SOIL = "Baby's cradle, advanced edition!"
S________WARLY.DESCRIBE.SIVING_SOIL = "Now you just need to sow some seeds."
S_________WURT.DESCRIBE.SIVING_SOIL = "I'm so excited. What should I plant."
S_______WALTER.DESCRIBE.SIVING_SOIL = "This will get me the planting medal."
S________WANDA.DESCRIBE.SIVING_SOIL = "Will the crops fall into the cycle of time?"

S_NAMES.SIVING_CTLWATER_ITEM = "Siving-Irrigator" --未放置的子圭·利川
S_RECIPE_DESC.SIVING_CTLWATER_ITEM = "It can control moisture after being placed."
S______GENERIC.DESCRIBE.SIVING_CTLWATER_ITEM = "It can control moisture after being placed."
-- S_______WILLOW.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S________WENDY.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_________WX78.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_______WOODIE.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S______WAXWELL.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_______WEBBER.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_______WINONA.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_______WORTOX.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_____WORMWOOD.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S________WARLY.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_________WURT.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S_______WALTER.DESCRIBE.SIVING_CTLWATER_ITEM = ""
-- S________WANDA.DESCRIBE.SIVING_CTLWATER_ITEM = ""

S_NAMES.SIVING_CTLWATER = "Siving-Irrigator" --子圭·利川
S______GENERIC.DESCRIBE.SIVING_CTLWATER = {
    GENERIC = "It can transport water to the surrounding soil.",
    ISFULL = "It's full.",
    REFUSE = "It has too little moisture."
}
-- S_______WILLOW.DESCRIBE.SIVING_CTLWATER = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_CTLWATER = ""
-- S________WENDY.DESCRIBE.SIVING_CTLWATER = ""
-- S_________WX78.DESCRIBE.SIVING_CTLWATER = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_CTLWATER = ""
-- S_______WOODIE.DESCRIBE.SIVING_CTLWATER = ""
-- S______WAXWELL.DESCRIBE.SIVING_CTLWATER = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_CTLWATER = ""
-- S_______WEBBER.DESCRIBE.SIVING_CTLWATER = ""
-- S_______WINONA.DESCRIBE.SIVING_CTLWATER = ""
-- S_______WORTOX.DESCRIBE.SIVING_CTLWATER = ""
-- S_____WORMWOOD.DESCRIBE.SIVING_CTLWATER = ""
-- S________WARLY.DESCRIBE.SIVING_CTLWATER = ""
-- S_________WURT.DESCRIBE.SIVING_CTLWATER = ""
-- S_______WALTER.DESCRIBE.SIVING_CTLWATER = ""
-- S________WANDA.DESCRIBE.SIVING_CTLWATER = ""

S_NAMES.SIVING_CTLDIRT_ITEM = "Siving-Fertilizer" --未放置的子圭·益矩
S_RECIPE_DESC.SIVING_CTLDIRT_ITEM = "It can control nutrients in the soil after being placed."
S______GENERIC.DESCRIBE.SIVING_CTLDIRT_ITEM = "It can control nutrients after being placed."
-- S_______WILLOW.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S________WENDY.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_________WX78.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_______WOODIE.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S______WAXWELL.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_______WEBBER.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_______WINONA.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_______WORTOX.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_____WORMWOOD.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S________WARLY.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_________WURT.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S_______WALTER.DESCRIBE.SIVING_CTLDIRT_ITEM = ""
-- S________WANDA.DESCRIBE.SIVING_CTLDIRT_ITEM = ""

S_NAMES.SIVING_CTLDIRT = "Siving-Fertilizer" --子圭·益矩
S______GENERIC.DESCRIBE.SIVING_CTLDIRT = {
    GENERIC = "It can transport nutrients to the surrounding soil.",
    ISFULL = "It's full.",
    REFUSE = "It cannot be turned into nutrients."
}
-- S_______WILLOW.DESCRIBE.SIVING_CTLDIRT = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_CTLDIRT = ""
-- S________WENDY.DESCRIBE.SIVING_CTLDIRT = ""
-- S_________WX78.DESCRIBE.SIVING_CTLDIRT = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_CTLDIRT = ""
-- S_______WOODIE.DESCRIBE.SIVING_CTLDIRT = ""
-- S______WAXWELL.DESCRIBE.SIVING_CTLDIRT = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_CTLDIRT = ""
-- S_______WEBBER.DESCRIBE.SIVING_CTLDIRT = ""
-- S_______WINONA.DESCRIBE.SIVING_CTLDIRT = ""
-- S_______WORTOX.DESCRIBE.SIVING_CTLDIRT = ""
-- S_____WORMWOOD.DESCRIBE.SIVING_CTLDIRT = ""
-- S________WARLY.DESCRIBE.SIVING_CTLDIRT = ""
-- S_________WURT.DESCRIBE.SIVING_CTLDIRT = ""
-- S_______WALTER.DESCRIBE.SIVING_CTLDIRT = ""
-- S________WANDA.DESCRIBE.SIVING_CTLDIRT = ""

S_NAMES.SIVING_CTLALL_ITEM = "Siving-Agriculture" --未放置的子圭·崇溟
S_RECIPE_DESC.SIVING_CTLALL_ITEM = "It can control moisture and nutrients in the soil after being placed."
S______GENERIC.DESCRIBE.SIVING_CTLALL_ITEM = "It can control moisture and nutrients after being placed."
-- S_______WILLOW.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S________WENDY.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_________WX78.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_______WOODIE.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S______WAXWELL.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_______WEBBER.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_______WINONA.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_______WORTOX.DESCRIBE.SIVING_CTLALL_ITEM = ""
S_____WORMWOOD.DESCRIBE.SIVING_CTLALL_ITEM = "I can take good care of my friends!"
-- S________WARLY.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_________WURT.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S_______WALTER.DESCRIBE.SIVING_CTLALL_ITEM = ""
-- S________WANDA.DESCRIBE.SIVING_CTLALL_ITEM = ""

S_NAMES.SIVING_CTLALL = "Siving-Agriculture" --子圭·崇溟
S______GENERIC.DESCRIBE.SIVING_CTLALL = {
    GENERIC = "It can transport water and nutrients to the surrounding soil.",
    ISFULL = "It's full.",
    REFUSE = "It can't absorb it."
}
-- S_______WILLOW.DESCRIBE.SIVING_CTLALL = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_CTLALL = ""
-- S________WENDY.DESCRIBE.SIVING_CTLALL = ""
-- S_________WX78.DESCRIBE.SIVING_CTLALL = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_CTLALL = ""
-- S_______WOODIE.DESCRIBE.SIVING_CTLALL = ""
-- S______WAXWELL.DESCRIBE.SIVING_CTLALL = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_CTLALL = ""
-- S_______WEBBER.DESCRIBE.SIVING_CTLALL = ""
-- S_______WINONA.DESCRIBE.SIVING_CTLALL = ""
-- S_______WORTOX.DESCRIBE.SIVING_CTLALL = ""
S_____WORMWOOD.DESCRIBE.SIVING_CTLALL = {
    GENERIC = "Who will take care of me.",
    ISFULL = "Too full.",
    REFUSE = "It doesn't want it!"
}
-- S________WARLY.DESCRIBE.SIVING_CTLALL = ""
-- S_________WURT.DESCRIBE.SIVING_CTLALL = ""
-- S_______WALTER.DESCRIBE.SIVING_CTLALL = ""
-- S________WANDA.DESCRIBE.SIVING_CTLALL = ""

S_NAMES.FISHHOMINGTOOL_NORMAL = "Fish-Homing Bait Maker" --简易打窝饵制作器
S_RECIPE_DESC.FISHHOMINGTOOL_NORMAL = "Disposable aquatic animal bait maker."
S______GENERIC.DESCRIBE.FISHHOMINGTOOL_NORMAL = "It's said that every good angler has their own unique recipe."
-- S_______WILLOW.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S_____WOLFGANG.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S________WENDY.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S_________WX78.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S_WICKERBOTTOM.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S_______WOODIE.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S______WAXWELL.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S___WATHGRITHR.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S_______WEBBER.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
S_______WINONA.DESCRIBE.FISHHOMINGTOOL_NORMAL = "Shoddy craftsmanship."
-- S_______WORTOX.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S_____WORMWOOD.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
S________WARLY.DESCRIBE.FISHHOMINGTOOL_NORMAL = "Even as a fish cook, I'm the best!"
S_________WURT.DESCRIBE.FISHHOMINGTOOL_NORMAL = "Find their preferences for each fish, flurph!"
-- S_______WALTER.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""
-- S________WANDA.DESCRIBE.FISHHOMINGTOOL_NORMAL = ""

S_NAMES.FISHHOMINGTOOL_AWESOME = "Pro Fish-Homing Bait Maker" --专业打窝饵制作器
S_RECIPE_DESC.FISHHOMINGTOOL_AWESOME = "Professional aquatic animal bait maker."
S______GENERIC.DESCRIBE.FISHHOMINGTOOL_AWESOME = "It's said that every good angler has their own unique recipe."
-- S_______WILLOW.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S_____WOLFGANG.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S________WENDY.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S_________WX78.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S_WICKERBOTTOM.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S_______WOODIE.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S______WAXWELL.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S___WATHGRITHR.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S_______WEBBER.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
S_______WINONA.DESCRIBE.FISHHOMINGTOOL_AWESOME = "Amazing craftsmanship."
-- S_______WORTOX.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
-- S_____WORMWOOD.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
S________WARLY.DESCRIBE.FISHHOMINGTOOL_AWESOME = "I won't just cook fish, I'll cook the entire ocean."
S_________WURT.DESCRIBE.FISHHOMINGTOOL_AWESOME = "A tool to find the preferences of my sea friends, flurph!"
-- S_______WALTER.DESCRIBE.FISHHOMINGTOOL_AWESOME = ""
S________WANDA.DESCRIBE.FISHHOMINGTOOL_AWESOME = "It's better to build a fishing net directly."

STRINGS.FISHHOMING1_LEGION = {
    HARDY = "Hardy ",
    PASTY = "Pasty ",
    DUSTY = "Powdery "
}
STRINGS.FISHHOMING2_LEGION = {
    MEAT = "Meat ",
    VEGGIE = "Veggie ",
    MONSTER = "Weird "
}
STRINGS.FISHHOMING3_LEGION = {
    LUCKY = "Lucky ", --金锦鲤、花锦鲤
    FROZEN = "Frozen ", --冰鲷鱼
    HOT = "Hot ", --炽热太阳鱼
    STICKY = "Sticky ", --甜味鱼
    SLIPPERY = "Slippery ", --口水鱼
    FRAGRANT = "Fragrant ", --花朵金枪鱼
    WRINKLED = "Wrinkled ", --落叶比目鱼
    COMICAL = "Comical ", --爆米花鱼、玉米鳕鱼
    SHINY = "Shiny ", --鱿鱼
    BLOODY = "Bloody ", --岩石大白鲨
    WHISPERING = "Whispering ", --一角鲸
    ROTTEN = "Rotten ", --龙虾
    RUSTY = "Rusty ", --月光龙虾
    SHAKING = "Shaking ", --海黾
    GRASSY = "Grassy ", --草鳄鱼
    EVIL = "Evil ", --邪天翁
    FRIZZY = "Frizzy ", --海鹦鹉
    SALTY = "Briny " --饼干切割机
}
STRINGS.FISHHOMING3_INFO_LEGION = {
    lucky = { fish = S_NAMES.OCEANFISH_MEDIUM_7_INV..", "..S_NAMES.OCEANFISH_MEDIUM_6_INV, chance = 0.1 },
    frozen = { fish = S_NAMES.OCEANFISH_MEDIUM_8_INV, chance = 0.01 },
    hot = { fish = S_NAMES.OCEANFISH_SMALL_8_INV, chance = 0.01 },
    sticky = { fish = S_NAMES.OCEANFISH_MEDIUM_9_INV, chance = 0.1 },
    slippery = { fish = S_NAMES.OCEANFISH_SMALL_9_INV, chance = 0.1 },
    fragrant = { fish = S_NAMES.OCEANFISH_SMALL_7_INV, chance = 0.01 },
    wrinkled = { fish = S_NAMES.OCEANFISH_SMALL_6_INV, chance = 0.01 },
    comical = { fish = S_NAMES.OCEANFISH_SMALL_5_INV..", "..S_NAMES.OCEANFISH_MEDIUM_5_INV, chance = 0.2 },
    shiny = { fish = S_NAMES.SQUID, chance = 0.02 },
    bloody = { fish = S_NAMES.SHARK, chance = 0.02 },
    whispering = { fish = S_NAMES.GNARWAIL, chance = 0.04 },
    rotten = { fish = S_NAMES.WOBSTER_SHELLER_LAND, chance = 0.1 },
    rusty = { fish = S_NAMES.WOBSTER_MOONGLASS, chance = 0.1 },
    shaking = { fish = S_NAMES.SPIDER_WATER, chance = 0.1 },
    grassy = { fish = S_NAMES.GRASSGATOR, chance = 0.04 },
    evil = { fish = S_NAMES.MALBATROSS, chance = 0.09 },
    frizzy = { fish = S_NAMES.PUFFIN, chance = 0.06 },
    salty = { fish = S_NAMES.COOKIECUTTER, chance = 0.09 }
}

S_NAMES.FISHHOMINGBAIT = "Fish-Homing Bait" --打窝饵
S______GENERIC.DESCRIBE.FISHHOMINGBAIT = "Throw it into water to attract fish."
-- S_______WILLOW.DESCRIBE.FISHHOMINGBAIT = ""
-- S_____WOLFGANG.DESCRIBE.FISHHOMINGBAIT = ""
-- S________WENDY.DESCRIBE.FISHHOMINGBAIT = ""
S_________WX78.DESCRIBE.FISHHOMINGBAIT = "STUPID AQUATIC CREATURES!"
S_WICKERBOTTOM.DESCRIBE.FISHHOMINGBAIT = "Suits the appetite of aquatic organisms."
-- S_______WOODIE.DESCRIBE.FISHHOMINGBAIT = ""
-- S______WAXWELL.DESCRIBE.FISHHOMINGBAIT = ""
-- S___WATHGRITHR.DESCRIBE.FISHHOMINGBAIT = ""
-- S_______WEBBER.DESCRIBE.FISHHOMINGBAIT = ""
-- S_______WINONA.DESCRIBE.FISHHOMINGBAIT = ""
-- S_______WORTOX.DESCRIBE.FISHHOMINGBAIT = ""
S_____WORMWOOD.DESCRIBE.FISHHOMINGBAIT = "Fish, food, mermmerm..."
S________WARLY.DESCRIBE.FISHHOMINGBAIT = "Hey fishies, here comes food!"
S_________WURT.DESCRIBE.FISHHOMINGBAIT = "Flurph, which lovely fish will be attracted by it today?"
S_______WALTER.DESCRIBE.FISHHOMINGBAIT = "I remember a man who said he went fishing but never opened his bait bag."
S________WANDA.DESCRIBE.FISHHOMINGBAIT = "Well, someone just wants to waste time fishing, right?"

S_NAMES.PLANT_CORN_L = "Corn Straw"
S_NAMES.PLANT_PUMPKIN_L = "Pumpkin Rack"
S_NAMES.PLANT_EGGPLANT_L = "Eggplant Nest"
S_NAMES.PLANT_DURIAN_L = "Durian Willow"
S_NAMES.PLANT_POMEGRANATE_L = "Pomegranate Tree"
S_NAMES.PLANT_DRAGONFRUIT_L = "Dragon Fruit Tree"
S_NAMES.PLANT_WATERMELON_L = "Watermelon Grass"
S_NAMES.PLANT_PINEANANAS_L = "Pineananas Tree"
S_NAMES.PLANT_ONION_L = "Onion Ring"
S_NAMES.PLANT_PEPPER_L = "Pepper Mint"
S_NAMES.PLANT_POTATO_L = "Tripotato"
S_NAMES.PLANT_GARLIC_L = "Feather Garlic"
S_NAMES.PLANT_TOMATO_L = "Thormato"
S_NAMES.PLANT_ASPARAGUS_L = "Asparagus Clump"
S_NAMES.PLANT_MANDRAKE_L = "Planted Mandrake"
S_NAMES.PLANT_GOURD_L = "Gourd Vine"

S______GENERIC.DESCRIBE.PLANT_CROP_L = {
    WITHERED = "It will be born again when spring breeze blows...",
    GROWING = "I will wait until the day when the horn of harvest blows...",
    BLOOMY = "Flowering is a good time to attract bees and butterflies...",
    READY = "Thank nature for its generous gifts!",
}

S______GENERIC.DESCRIBE.SEEDS_CROP_L = "After special environmental catalysis, it has mutated."
-- S_______WILLOW.DESCRIBE.SEEDS_CROP_L = ""
-- S_____WOLFGANG.DESCRIBE.SEEDS_CROP_L = ""
-- S________WENDY.DESCRIBE.SEEDS_CROP_L = ""
-- S_________WX78.DESCRIBE.SEEDS_CROP_L = ""
S_WICKERBOTTOM.DESCRIBE.SEEDS_CROP_L = "Variation makes it more inorganic."
-- S_______WOODIE.DESCRIBE.SEEDS_CROP_L = ""
-- S______WAXWELL.DESCRIBE.SEEDS_CROP_L = ""
-- S___WATHGRITHR.DESCRIBE.SEEDS_CROP_L = ""
S_______WEBBER.DESCRIBE.SEEDS_CROP_L = "Don't worry, we won't look at it differently."
-- S_______WINONA.DESCRIBE.SEEDS_CROP_L = ""
-- S_______WORTOX.DESCRIBE.SEEDS_CROP_L = ""
S_____WORMWOOD.DESCRIBE.SEEDS_CROP_L = "Baby, different."
-- S________WARLY.DESCRIBE.SEEDS_CROP_L = ""
-- S_________WURT.DESCRIBE.SEEDS_CROP_L = ""
-- S_______WALTER.DESCRIBE.SEEDS_CROP_L = ""
-- S________WANDA.DESCRIBE.SEEDS_CROP_L = ""

S_NAMES.SIVING_TURN = "Siving-Mutator" --子圭·育
S_RECIPE_DESC.SIVING_TURN = "An odd thing that transforms giant crops. Yesterday a giant crop flourishing and tomorrow full of wonder."
S______GENERIC.DESCRIBE.SIVING_TURN = {
    GENERIC = "Is this the time shuttle?",
    DONE = "The transformation is finished. I can take it down now.",
    DOING = "It's wrapped in unidentified fragments.",
    NOENERGY = "It's out of energy. I need to recharge it."
}
-- S_______WILLOW.DESCRIBE.SIVING_TURN = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_TURN = ""
-- S________WENDY.DESCRIBE.SIVING_TURN = ""
-- S_________WX78.DESCRIBE.SIVING_TURN = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_TURN = {
    GENERIC = "Contains a gravitational device, which seems to be able to hold some objects.",
    DONE = "Transformation is finished. It kinda looks like a cocoon.",
    DOING = "It is carrying out some special gene transformation.",
    NOENERGY = "It's energy is exhausted, but it's composition is it's energy."
}
-- S_______WOODIE.DESCRIBE.SIVING_TURN = ""
-- S______WAXWELL.DESCRIBE.SIVING_TURN = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_TURN = ""
-- S_______WEBBER.DESCRIBE.SIVING_TURN = ""
-- S_______WINONA.DESCRIBE.SIVING_TURN = ""
-- S_______WORTOX.DESCRIBE.SIVING_TURN = ""
S_____WORMWOOD.DESCRIBE.SIVING_TURN = {
    GENERIC = "Wheel wheel?",
    DONE = "Strange baby, inside!",
    DOING = "Spinning...",
    NOENERGY = "It's hungry."
}
-- S________WARLY.DESCRIBE.SIVING_TURN = ""
-- S_________WURT.DESCRIBE.SIVING_TURN = ""
-- S_______WALTER.DESCRIBE.SIVING_TURN = ""
-- S________WANDA.DESCRIBE.SIVING_TURN = ""

S_NAMES.SIVING_FEATHER_REAL = "Siving-Plume" --子圭·翰
S_RECIPE_DESC.SIVING_FEATHER_REAL = "Sharp feather after thoroughly tempered."
S______GENERIC.DESCRIBE.SIVING_FEATHER_REAL = "I can't wait to pierce something with it."
S_______WILLOW.DESCRIBE.SIVING_FEATHER_REAL = "Feather split!"
S_____WOLFGANG.DESCRIBE.SIVING_FEATHER_REAL = "A sharp fly-cutter."
S________WENDY.DESCRIBE.SIVING_FEATHER_REAL = "So sharp that it can cut my hand."
-- S_________WX78.DESCRIBE.SIVING_FEATHER_REAL = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_FEATHER_REAL = "With a rocky texture, it's sharper than it looks."
-- S_______WOODIE.DESCRIBE.SIVING_FEATHER_REAL = ""
-- S______WAXWELL.DESCRIBE.SIVING_FEATHER_REAL = ""
S___WATHGRITHR.DESCRIBE.SIVING_FEATHER_REAL = "A thousand cuts is just the prelude."
S_______WEBBER.DESCRIBE.SIVING_FEATHER_REAL = "Do you want to do it?!"
-- S_______WINONA.DESCRIBE.SIVING_FEATHER_REAL = ""
S_______WORTOX.DESCRIBE.SIVING_FEATHER_REAL = "It eats away at my soul, not something easy to use."
-- S_____WORMWOOD.DESCRIBE.SIVING_FEATHER_REAL = ""
S________WARLY.DESCRIBE.SIVING_FEATHER_REAL = "I'll cut them into thin slices!"
-- S_________WURT.DESCRIBE.SIVING_FEATHER_REAL = ""
S_______WALTER.DESCRIBE.SIVING_FEATHER_REAL = "Better than my slingshot."
S________WANDA.DESCRIBE.SIVING_FEATHER_REAL = "I wish it could cut away this nightmare."

S_NAMES.SIVING_FEATHER_FAKE = "Siving Feather" --子圭玄鸟绒羽
S______GENERIC.DESCRIBE.SIVING_FEATHER_FAKE = "I'm going to slap people! All of you!"
S_______WILLOW.DESCRIBE.SIVING_FEATHER_FAKE = "Feather throw!"
S_____WOLFGANG.DESCRIBE.SIVING_FEATHER_FAKE = "A throwing knife that is not all that sharp."
-- S________WENDY.DESCRIBE.SIVING_FEATHER_FAKE = ""
-- S_________WX78.DESCRIBE.SIVING_FEATHER_FAKE = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_FEATHER_FAKE = ""
-- S_______WOODIE.DESCRIBE.SIVING_FEATHER_FAKE = ""
S______WAXWELL.DESCRIBE.SIVING_FEATHER_FAKE = "As wild as magic!"
S___WATHGRITHR.DESCRIBE.SIVING_FEATHER_FAKE = "Can it be called a party without a fight?"
S_______WEBBER.DESCRIBE.SIVING_FEATHER_FAKE = "Better than toy darts."
-- S_______WINONA.DESCRIBE.SIVING_FEATHER_FAKE = ""
S_______WORTOX.DESCRIBE.SIVING_FEATHER_FAKE = "I'd love to try it out and see who's faster."
-- S_____WORMWOOD.DESCRIBE.SIVING_FEATHER_FAKE = ""
-- S________WARLY.DESCRIBE.SIVING_FEATHER_FAKE = ""
-- S_________WURT.DESCRIBE.SIVING_FEATHER_FAKE = ""
S_______WALTER.DESCRIBE.SIVING_FEATHER_FAKE = "Oh fun! I want to try it now!"
-- S________WANDA.DESCRIBE.SIVING_FEATHER_FAKE = ""

S_NAMES.SIVING_FEATHER_LINE = "Silked Away" --牵羽牵寻
S______GENERIC.DESCRIBE.SIVING_FEATHER_LINE = "Hidden threads, tugging at one end of each feather."
S_______WILLOW.DESCRIBE.SIVING_FEATHER_LINE = "Like the queen of blades."
-- S_____WOLFGANG.DESCRIBE.SIVING_FEATHER_LINE = ""
S________WENDY.DESCRIBE.SIVING_FEATHER_LINE = "I wonder if Abigail is controlled by me like this."
-- S_________WX78.DESCRIBE.SIVING_FEATHER_LINE = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_FEATHER_LINE = "Every time it reciprocates, a thread can break."
S_______WOODIE.DESCRIBE.SIVING_FEATHER_LINE = "Lucy and I are too familiar with this trick."
S______WAXWELL.DESCRIBE.SIVING_FEATHER_LINE = "These puppet like feathers are used to hurt rather than entertain."
S___WATHGRITHR.DESCRIBE.SIVING_FEATHER_LINE = "Valkyries should also learn this!"
S_______WEBBER.DESCRIBE.SIVING_FEATHER_LINE = "It's like a yoyo."
S_______WINONA.DESCRIBE.SIVING_FEATHER_LINE = "Sharp feathers will shuttle back and forth under my command."
S_______WORTOX.DESCRIBE.SIVING_FEATHER_LINE = "The red string of fate will entangle you and me."
S_____WORMWOOD.DESCRIBE.SIVING_FEATHER_LINE = "Tug of war."
S________WARLY.DESCRIBE.SIVING_FEATHER_LINE = "This technique is also used to cut meat."
-- S_________WURT.DESCRIBE.SIVING_FEATHER_LINE = ""
S_______WALTER.DESCRIBE.SIVING_FEATHER_LINE = "I tried to add this to slingshot, but never succeeded."
-- S________WANDA.DESCRIBE.SIVING_FEATHER_LINE = ""

S_NAMES.SIVING_MASK = "Siving-Leakage" --子圭·汲
S_RECIPE_DESC.SIVING_MASK = "What is the price of wearing life."
S______GENERIC.DESCRIBE.SIVING_MASK = "A stone mask that draws blood."
S_______WILLOW.DESCRIBE.SIVING_MASK = "Burn your lives for me, humble servants!"
-- S_____WOLFGANG.DESCRIBE.SIVING_MASK = ""
S________WENDY.DESCRIBE.SIVING_MASK = "Luckily it won't harm Abigail."
-- S_________WX78.DESCRIBE.SIVING_MASK = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_MASK = "A magic, difficult to control. Improper use will make you hurt yourself."
-- S_______WOODIE.DESCRIBE.SIVING_MASK = ""
S______WAXWELL.DESCRIBE.SIVING_MASK = "Maybe I can live a little longer behind this mask."
S___WATHGRITHR.DESCRIBE.SIVING_MASK = "Only despicable losers would enjoy such tricks."
S_______WEBBER.DESCRIBE.SIVING_MASK = "We all think this is wrong!" --因为蜘蛛是群居生物，韦伯善良，所以都不想使用这个装备
-- S_______WINONA.DESCRIBE.SIVING_MASK = ""
S_______WORTOX.DESCRIBE.SIVING_MASK = "Disguised as a vampire who doesn't need to be invited into the house, ahahahaha!"
S_____WORMWOOD.DESCRIBE.SIVING_MASK = "It rarely becomes hostile to friends."
S________WARLY.DESCRIBE.SIVING_MASK = "Eat what sates you, right?"
-- S_________WURT.DESCRIBE.SIVING_MASK = ""
-- S_______WALTER.DESCRIBE.SIVING_MASK = ""
S________WANDA.DESCRIBE.SIVING_MASK = "Time will also slowly take away the lives of all in a similar way."

S_NAMES.SIVING_MASK_GOLD = "Siving-Thaumaturgy" --子圭·歃
S_RECIPE_DESC.SIVING_MASK_GOLD = "Calls for lives."
S______GENERIC.DESCRIBE.SIVING_MASK_GOLD = "A mask of exquisite broken gold that plays with life."
S_______WILLOW.DESCRIBE.SIVING_MASK_GOLD = "Give your lives for the queen of flames, humble servants!"
S_____WOLFGANG.DESCRIBE.SIVING_MASK_GOLD = "Wolfgang is willing to give of himself to save others."
S________WENDY.DESCRIBE.SIVING_MASK_GOLD = "Tried to resurrect Abigail with it and failed, as always."
S_________WX78.DESCRIBE.SIVING_MASK_GOLD = "I ACTUALLY FELT A LITTLE WARMTH WHEN I WAS SAVED BY IT."
S_WICKERBOTTOM.DESCRIBE.SIVING_MASK_GOLD = "More mature control of life magic without hurting yourself."
S_______WOODIE.DESCRIBE.SIVING_MASK_GOLD = "If only it would have been possible to get Lucy back."
S______WAXWELL.DESCRIBE.SIVING_MASK_GOLD = "I'll hide my identity until the victory comes."
S___WATHGRITHR.DESCRIBE.SIVING_MASK_GOLD = "The lord of fallen excels in such tactics."
S_______WEBBER.DESCRIBE.SIVING_MASK_GOLD = "We only get more disgusted with this stuff!"
S_______WINONA.DESCRIBE.SIVING_MASK_GOLD = "I am the master of my destiny!"
S_______WORTOX.DESCRIBE.SIVING_MASK_GOLD = "Incarnate as the fleshless Dracula, yah ha ha!"
S_____WORMWOOD.DESCRIBE.SIVING_MASK_GOLD = "It doesn't feel right."
S________WARLY.DESCRIBE.SIVING_MASK_GOLD = "Eats grass, produces superb milk!"
-- S_________WURT.DESCRIBE.SIVING_MASK_GOLD = ""
-- S_______WALTER.DESCRIBE.SIVING_MASK_GOLD = ""
S________WANDA.DESCRIBE.SIVING_MASK_GOLD = "More efficient and cruel than the magic of time."

S_NAMES.SIVING_SUIT = "Siving-Vengeance" --子圭·庇
S_RECIPE_DESC.SIVING_SUIT = "The price of a tooth for a tooth."
S______GENERIC.DESCRIBE.SIVING_SUIT = "Repay my suffering with the blood of the enemy."
S_______WILLOW.DESCRIBE.SIVING_SUIT = "I need to fight back! Those who have hurt me."
-- S_____WOLFGANG.DESCRIBE.SIVING_SUIT = ""
-- S________WENDY.DESCRIBE.SIVING_SUIT = ""
-- S_________WX78.DESCRIBE.SIVING_SUIT = ""
-- S_WICKERBOTTOM.DESCRIBE.SIVING_SUIT = ""
-- S_______WOODIE.DESCRIBE.SIVING_SUIT = ""
-- S______WAXWELL.DESCRIBE.SIVING_SUIT = ""
-- S___WATHGRITHR.DESCRIBE.SIVING_SUIT = ""
-- S_______WEBBER.DESCRIBE.SIVING_SUIT = ""
-- S_______WINONA.DESCRIBE.SIVING_SUIT = ""
-- S_______WORTOX.DESCRIBE.SIVING_SUIT = ""
-- S_____WORMWOOD.DESCRIBE.SIVING_SUIT = ""
-- S________WARLY.DESCRIBE.SIVING_SUIT = ""
-- S_________WURT.DESCRIBE.SIVING_SUIT = ""
-- S_______WALTER.DESCRIBE.SIVING_SUIT = ""
-- S________WANDA.DESCRIBE.SIVING_SUIT = ""

S_NAMES.SIVING_SUIT_GOLD = "Siving-Cauldron" --子圭·釜
S_RECIPE_DESC.SIVING_SUIT_GOLD = "Breaking a cauldron avoids sinking a boat."
S______GENERIC.DESCRIBE.SIVING_SUIT_GOLD = "This is not a pot for cooking."
S_______WILLOW.DESCRIBE.SIVING_SUIT_GOLD = "Wear this, the villain who provoked me will disappear!"
S_____WOLFGANG.DESCRIBE.SIVING_SUIT_GOLD = "Wolfgang hopes to wear it without getting stuck."
-- S________WENDY.DESCRIBE.SIVING_SUIT_GOLD = ""
-- S_________WX78.DESCRIBE.SIVING_SUIT_GOLD = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_SUIT_GOLD = "Amazing. The damage to the enemy will become my armor."
S_______WOODIE.DESCRIBE.SIVING_SUIT_GOLD = "I thought it was a pot."
S______WAXWELL.DESCRIBE.SIVING_SUIT_GOLD = "I like the counterattack magic."
-- S___WATHGRITHR.DESCRIBE.SIVING_SUIT_GOLD = ""
S_______WEBBER.DESCRIBE.SIVING_SUIT_GOLD = "Is this about putting the pot on the body?"
S_______WINONA.DESCRIBE.SIVING_SUIT_GOLD = "You have to put in effort to get its reward."
S_______WORTOX.DESCRIBE.SIVING_SUIT_GOLD = "I have never been the scapegoat."
S_____WORMWOOD.DESCRIBE.SIVING_SUIT_GOLD = "Bowl?"
S________WARLY.DESCRIBE.SIVING_SUIT_GOLD = "The cooker will explode!"
-- S_________WURT.DESCRIBE.SIVING_SUIT_GOLD = ""
-- S_______WALTER.DESCRIBE.SIVING_SUIT_GOLD = ""
-- S________WANDA.DESCRIBE.SIVING_SUIT_GOLD = ""

S_NAMES.SIVING_EGG = "Siving Phoenix Egg" --子圭石子
S______GENERIC.DESCRIBE.SIVING_EGG = "Should I break it or let it hatch?"
-- S_______WILLOW.DESCRIBE.SIVING_EGG = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_EGG = ""
S________WENDY.DESCRIBE.SIVING_EGG = "Even before its birth, it's ready to die."
-- S_________WX78.DESCRIBE.SIVING_EGG = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_EGG = "If it's born, it will probably be another hard battle."
S_______WOODIE.DESCRIBE.SIVING_EGG = "My advice is to nip it in the bud!"
-- S______WAXWELL.DESCRIBE.SIVING_EGG = ""
S___WATHGRITHR.DESCRIBE.SIVING_EGG = "Great warriors should have compassion."
S_______WEBBER.DESCRIBE.SIVING_EGG = "An interesting stone egg."
-- S_______WINONA.DESCRIBE.SIVING_EGG = ""
S_______WORTOX.DESCRIBE.SIVING_EGG = "An egg that's between life and death."
S_____WORMWOOD.DESCRIBE.SIVING_EGG = "Rocky egg."
S________WARLY.DESCRIBE.SIVING_EGG = "Be obedient, or I'll make you into fried eggs."
-- S_________WURT.DESCRIBE.SIVING_EGG = ""
-- S_______WALTER.DESCRIBE.SIVING_EGG = ""
S________WANDA.DESCRIBE.SIVING_EGG = "Seriously, it will start it's cycle of life again."

S_NAMES.SIVING_PHOENIX = "Siving Phoenix" --子圭玄鸟
S______GENERIC.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "A rock can also give birth to life? That's a major scientific discovery!",
    GRIEF = "It has people thoughts!"
}
S_______WILLOW.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "This bird can't burn, it's giving me a headache.",
    GRIEF = "Now you are alone."
}
S_____WOLFGANG.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "Wolfgang wants to touch it.",
    GRIEF = "Stone bird is angry!"
}
S________WENDY.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "This is not what I expected.",
    GRIEF = "Maybe the ceremony is not over yet."
}
S_________WX78.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "THAT TREE IS NOT WORTH COOPERATING WITH.",
    GRIEF = "THAT'S THE PRICE FOR LYING TO ME!"
}
S_WICKERBOTTOM.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "This is the highest form of life of siving!",
    GRIEF = "They seem to have the same thoughts and feelings as us."
}
S_______WOODIE.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "Don't blame me for being too cruel, stupid birds.",
    GRIEF = "There's one left!"
}
S______WAXWELL.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "This isn't the first time. I'm so gullible.",
    GRIEF = "I will pay for my stupidity."
}
S___WATHGRITHR.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "A great test of the sacred tree to the warriors!",
    GRIEF = "The trial is coming to an end."
}
S_______WEBBER.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "They don't seem to want to play with us.",
    GRIEF = "This isn't our intention. Sorry."
}
S_______WINONA.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "Very interesting. It's a bird shaped statue that can move!",
    GRIEF = "This statue is crazy."
}
S_______WORTOX.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "I can tell their gender.",
    GRIEF = "Where's its partner?"
}
S_____WORMWOOD.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "One rock bird, two rock birds.",
    GRIEF = "One rock bird, mad."
}
S________WARLY.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "Deception! I'll teach you a lesson.",
    GRIEF = "I feel a little sorry for it."
}
S_________WURT.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "Their existence moves me.",
    GRIEF = "I definitely didn't do it. Please spare me, flort."
}
S_______WALTER.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "Hello, can I take a rock feather as a medal?",
    GRIEF = "You're not happy. I'll ask you about the medal later."
}
S________WANDA.DESCRIBE.SIVING_PHOENIX = {
    GENERIC = "I've never completely defeated it in our countless battles.",
    GRIEF = "It fell into grief and indignation, as always."
}

S_NAMES.BUFF_L_MAGICWARBLE = "Magic Warble"
S_NAMES.BUFF_L_TREEHALO = "Siving Halo"

S_NAMES.SIVING_BOSS_FLOWER = "Siving Petalsite" --子圭寄生花
S______GENERIC.DESCRIBE.SIVING_BOSS_FLOWER = "It grew out of my head. How terrible."
S_______WILLOW.DESCRIBE.SIVING_BOSS_FLOWER = "I'm going to tear it up!"
-- S_____WOLFGANG.DESCRIBE.SIVING_BOSS_FLOWER = ""
S________WENDY.DESCRIBE.SIVING_BOSS_FLOWER = "It thrives in silent killing."
S_________WX78.DESCRIBE.SIVING_BOSS_FLOWER = "THE IRONMAN IN BLOSSOM."
S_WICKERBOTTOM.DESCRIBE.SIVING_BOSS_FLOWER = "Note that this flower will heal the bird."
S_______WOODIE.DESCRIBE.SIVING_BOSS_FLOWER = "Lucy told me to destroy it quickly."
S______WAXWELL.DESCRIBE.SIVING_BOSS_FLOWER = "Neet... Hah... I can tell dry jokes too."
S___WATHGRITHR.DESCRIBE.SIVING_BOSS_FLOWER = "My life is my endless fighting spirit. I don't need such tricks."
S_______WEBBER.DESCRIBE.SIVING_BOSS_FLOWER = "Maybe the watermelon seeds I ate grew out of my head?"
-- S_______WINONA.DESCRIBE.SIVING_BOSS_FLOWER = ""
S_______WORTOX.DESCRIBE.SIVING_BOSS_FLOWER = "Bloodletting can't cure my soul."
S_____WORMWOOD.DESCRIBE.SIVING_BOSS_FLOWER = "A bad guy."
S________WARLY.DESCRIBE.SIVING_BOSS_FLOWER = "It's made me very weak, but my appetite has increased greatly."
S_________WURT.DESCRIBE.SIVING_BOSS_FLOWER = "Parasite, no, smelly petalsite!"
S_______WALTER.DESCRIBE.SIVING_BOSS_FLOWER = "If only all injuries could be so painless."
S________WANDA.DESCRIBE.SIVING_BOSS_FLOWER = "My time isn't the water in the sponge for you to squeeze!"

S_NAMES.SIVING_BOSSFEA_REAL = "Delicate Siving Darther" --精致子圭翎羽(Dart + Feather)
S______GENERIC.DESCRIBE.SIVING_BOSSFEA_REAL = "Shiny rocky feather with extremely sharp edges."
-- S_______WILLOW.DESCRIBE.SIVING_BOSSFEA_REAL = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_BOSSFEA_REAL = ""
-- S________WENDY.DESCRIBE.SIVING_BOSSFEA_REAL = ""
S_________WX78.DESCRIBE.SIVING_BOSSFEA_REAL = "INJURY AND EXPLOSION WARNING!"
S_WICKERBOTTOM.DESCRIBE.SIVING_BOSSFEA_REAL = "Additional unstable energy is attached to this feather."
S_______WOODIE.DESCRIBE.SIVING_BOSSFEA_REAL = "A bright arrow hurled by the bird."
-- S______WAXWELL.DESCRIBE.SIVING_BOSSFEA_REAL = ""
S___WATHGRITHR.DESCRIBE.SIVING_BOSSFEA_REAL = "A sharp blade of light."
S_______WEBBER.DESCRIBE.SIVING_BOSSFEA_REAL = "We saw it coming like a dart. It was terrible."
-- S_______WINONA.DESCRIBE.SIVING_BOSSFEA_REAL = ""
S_______WORTOX.DESCRIBE.SIVING_BOSSFEA_REAL = "It's too conspicuous. It won't hurt me."
S_____WORMWOOD.DESCRIBE.SIVING_BOSSFEA_REAL = "Glowing dagger!"
S________WARLY.DESCRIBE.SIVING_BOSSFEA_REAL = "It would be cool to use it as a kitchen knife."
-- S_________WURT.DESCRIBE.SIVING_BOSSFEA_REAL = ""
-- S_______WALTER.DESCRIBE.SIVING_BOSSFEA_REAL = ""
S________WANDA.DESCRIBE.SIVING_BOSSFEA_REAL = "Great lethality, but low hit rate."

S_NAMES.SIVING_BOSSFEA_FAKE = "Siving Darther" --子圭翎羽
S______GENERIC.DESCRIBE.SIVING_BOSSFEA_FAKE = "Rocky feather with sharp edges."
-- S_______WILLOW.DESCRIBE.SIVING_BOSSFEA_FAKE = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_BOSSFEA_FAKE = ""
-- S________WENDY.DESCRIBE.SIVING_BOSSFEA_FAKE = ""
S_________WX78.DESCRIBE.SIVING_BOSSFEA_FAKE = "INJURY WARNING!"
S_WICKERBOTTOM.DESCRIBE.SIVING_BOSSFEA_FAKE = "A common feather used as a weapon."
S_______WOODIE.DESCRIBE.SIVING_BOSSFEA_FAKE = "A stabbing arrow thrown by the bird."
-- S______WAXWELL.DESCRIBE.SIVING_BOSSFEA_FAKE = ""
S___WATHGRITHR.DESCRIBE.SIVING_BOSSFEA_FAKE = "A sharp blade."
S_______WEBBER.DESCRIBE.SIVING_BOSSFEA_FAKE = "We saw it coming like a dart."
-- S_______WINONA.DESCRIBE.SIVING_BOSSFEA_FAKE = ""
S_______WORTOX.DESCRIBE.SIVING_BOSSFEA_FAKE = "It can't hurt me if I teleport fast enough."
S_____WORMWOOD.DESCRIBE.SIVING_BOSSFEA_FAKE = "Dagger!"
S________WARLY.DESCRIBE.SIVING_BOSSFEA_FAKE = "If only it could be used as a kitchen knife."
-- S_________WURT.DESCRIBE.SIVING_BOSSFEA_FAKE = ""
-- S_______WALTER.DESCRIBE.SIVING_BOSSFEA_FAKE = ""
S________WANDA.DESCRIBE.SIVING_BOSSFEA_FAKE = "Not all that high of lethality and a low hit rate."

S_NAMES.SIVING_BOSS_ROOT = "Siving Root Spike" --子圭突触
S______GENERIC.DESCRIBE.SIVING_BOSS_ROOT = "Death from below!"
-- S_______WILLOW.DESCRIBE.SIVING_BOSS_ROOT = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_BOSS_ROOT = ""
-- S________WENDY.DESCRIBE.SIVING_BOSS_ROOT = ""
-- S_________WX78.DESCRIBE.SIVING_BOSS_ROOT = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_BOSS_ROOT = "Observe carefully, or..."
S_______WOODIE.DESCRIBE.SIVING_BOSS_ROOT = "Ugh. I need pickaxe now."
-- S______WAXWELL.DESCRIBE.SIVING_BOSS_ROOT = ""
S___WATHGRITHR.DESCRIBE.SIVING_BOSS_ROOT = "Hah, this is easy."
S_______WEBBER.DESCRIBE.SIVING_BOSS_ROOT = "Our bare feet can easily feel the dangers from under the ground."
S_______WINONA.DESCRIBE.SIVING_BOSS_ROOT = "It not only raided, but also blocked my way."
S_______WORTOX.DESCRIBE.SIVING_BOSS_ROOT = "Be careful to not have your butt pricked!"
S_____WORMWOOD.DESCRIBE.SIVING_BOSS_ROOT = "A pointed root."
-- S________WARLY.DESCRIBE.SIVING_BOSS_ROOT = ""
S_________WURT.DESCRIBE.SIVING_BOSS_ROOT = "Grrr, it makes sneak attack!"
-- S_______WALTER.DESCRIBE.SIVING_BOSS_ROOT = ""
-- S________WANDA.DESCRIBE.SIVING_BOSS_ROOT = ""

S_NAMES.HAT_ELEPHEETLE = "Elepheetle Helmet" --犀金胄甲
S_RECIPE_DESC.HAT_ELEPHEETLE = "Provides protection and the insect's super power."
S______GENERIC.DESCRIBE.HAT_ELEPHEETLE = "Fortunately, it's not worm-shaped."
S_______WILLOW.DESCRIBE.HAT_ELEPHEETLE = "Bah, I hate it!"
S_____WOLFGANG.DESCRIBE.HAT_ELEPHEETLE = "It's easier to do physical work while wearing it."
-- S________WENDY.DESCRIBE.HAT_ELEPHEETLE = ""
-- S_________WX78.DESCRIBE.HAT_ELEPHEETLE = ""
S_WICKERBOTTOM.DESCRIBE.HAT_ELEPHEETLE = "This is the knowledge learned from the unicorn beetle."
S_______WOODIE.DESCRIBE.HAT_ELEPHEETLE = "It looks like a big bug."
S______WAXWELL.DESCRIBE.HAT_ELEPHEETLE = "I don't want to look at it, I don't want to wear it."
-- S___WATHGRITHR.DESCRIBE.HAT_ELEPHEETLE = ""
S_______WEBBER.DESCRIBE.HAT_ELEPHEETLE = "Hee hee, it's as different as us."
S_______WINONA.DESCRIBE.HAT_ELEPHEETLE = "Practicality is on the line, it's appearance is not important."
S_______WORTOX.DESCRIBE.HAT_ELEPHEETLE = "This power is most suitable for farming work."
S_____WORMWOOD.DESCRIBE.HAT_ELEPHEETLE = "Scary."
S________WARLY.DESCRIBE.HAT_ELEPHEETLE = "I prefer the super power that is cooking."
-- S_________WURT.DESCRIBE.HAT_ELEPHEETLE = ""
S_______WALTER.DESCRIBE.HAT_ELEPHEETLE = "Looks like this year's Halloween costume is decided!"
S________WANDA.DESCRIBE.HAT_ELEPHEETLE = "I don't need the power of bugs."

S_NAMES.ARMOR_ELEPHEETLE = "Elepheetle Armor" --犀金护甲
S_RECIPE_DESC.ARMOR_ELEPHEETLE = "Provides resistance and the insect's extreme defense."
S______GENERIC.DESCRIBE.ARMOR_ELEPHEETLE = "It's much heavier than it looks."
S_______WILLOW.DESCRIBE.ARMOR_ELEPHEETLE = "Disgusting. I'd better burn it."
S_____WOLFGANG.DESCRIBE.ARMOR_ELEPHEETLE = "Wolfgang likes the strong sense of weightiness."
-- S________WENDY.DESCRIBE.ARMOR_ELEPHEETLE = ""
-- S_________WX78.DESCRIBE.ARMOR_ELEPHEETLE = ""
S_WICKERBOTTOM.DESCRIBE.ARMOR_ELEPHEETLE = "This is the wisdom learned from the elephant beetle."
S_______WOODIE.DESCRIBE.ARMOR_ELEPHEETLE = "After wearing it, there is a big bug."
S______WAXWELL.DESCRIBE.ARMOR_ELEPHEETLE = "I'd rather wear something actually decent."
-- S___WATHGRITHR.DESCRIBE.ARMOR_ELEPHEETLE = ""
S_______WEBBER.DESCRIBE.ARMOR_ELEPHEETLE = "We like it alot, but it's too heavy."
S_______WINONA.DESCRIBE.ARMOR_ELEPHEETLE = "Just use it. The shape is not important."
S_______WORTOX.DESCRIBE.ARMOR_ELEPHEETLE = "Wear the thickest armor to withstand the most vicious blows."
S_____WORMWOOD.DESCRIBE.ARMOR_ELEPHEETLE = "Scary."
S________WARLY.DESCRIBE.ARMOR_ELEPHEETLE = "I still prefer cooking as opposed to extreme defense."
-- S_________WURT.DESCRIBE.ARMOR_ELEPHEETLE = ""
S_______WALTER.DESCRIBE.ARMOR_ELEPHEETLE = "Looks like this year's Halloween costume is decided!"
S________WANDA.DESCRIBE.ARMOR_ELEPHEETLE = "This amount of heft mixed with my limited time doesn't match well at all!"

S_NAMES.LANCE_CARROT_L = "Carrot Lance" --胡萝卜长枪
S______GENERIC.DESCRIBE.LANCE_CARROT_L = "Using food as weapons isn't new."
-- S_______WILLOW.DESCRIBE.LANCE_CARROT_L = ""
-- S_____WOLFGANG.DESCRIBE.LANCE_CARROT_L = ""
S________WENDY.DESCRIBE.LANCE_CARROT_L = "A rabbit's weapon."
-- S_________WX78.DESCRIBE.LANCE_CARROT_L = ""
S_WICKERBOTTOM.DESCRIBE.LANCE_CARROT_L = "A carrot stick that's as hard as bamboo."
S_______WOODIE.DESCRIBE.LANCE_CARROT_L = "I just want to ask if this can be eaten."
-- S______WAXWELL.DESCRIBE.LANCE_CARROT_L = ""
S___WATHGRITHR.DESCRIBE.LANCE_CARROT_L = "When you are incisive enough, even food can be a weapon."
S_______WEBBER.DESCRIBE.LANCE_CARROT_L = "Tasty and funny long carrot!"
-- S_______WINONA.DESCRIBE.LANCE_CARROT_L = ""
-- S_______WORTOX.DESCRIBE.LANCE_CARROT_L = ""
S_____WORMWOOD.DESCRIBE.LANCE_CARROT_L = "Very long."
S________WARLY.DESCRIBE.LANCE_CARROT_L = "Unfortunately, it has hardened and cannot be eaten."
S_________WURT.DESCRIBE.LANCE_CARROT_L = "Ha, I think it suits me very well."
-- S_______WALTER.DESCRIBE.LANCE_CARROT_L = ""
S________WANDA.DESCRIBE.LANCE_CARROT_L = "Nothing new."

S_NAMES.PLANT_PLANTMEAT_L = "Vase Herb" --巨食草(生长阶段的)
S______GENERIC.DESCRIBE.PLANT_PLANTMEAT_L = {
    GROWING = "Look at this pink cherry mouth, it's really cute.",
    READY = "Matured.", WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S_______WILLOW.DESCRIBE.PLANT_PLANTMEAT_L = ""
S_____WOLFGANG.DESCRIBE.PLANT_PLANTMEAT_L = {
    GROWING = "Look! A big mouth flower.",
    READY = "Matured.", WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S________WENDY.DESCRIBE.PLANT_PLANTMEAT_L = ""
-- S_________WX78.DESCRIBE.PLANT_PLANTMEAT_L = ""
S_WICKERBOTTOM.DESCRIBE.PLANT_PLANTMEAT_L = {
    GROWING = "The predatory organs of carnivorous plants are developing.",
    READY = "Matured.", WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S_______WOODIE.DESCRIBE.PLANT_PLANTMEAT_L = ""
-- S______WAXWELL.DESCRIBE.PLANT_PLANTMEAT_L = ""
-- S___WATHGRITHR.DESCRIBE.PLANT_PLANTMEAT_L = ""
S_______WEBBER.DESCRIBE.PLANT_PLANTMEAT_L = {
    GROWING = "Is this the flower it blooms?",
    READY = "Matured.", WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S_______WINONA.DESCRIBE.PLANT_PLANTMEAT_L = ""
S_______WORTOX.DESCRIBE.PLANT_PLANTMEAT_L = {
    GROWING = "Oh, my friend, you're really hungry.",
    READY = "Matured.", WITHERED = "Withered.", BLOOMY = "Blooming."
}
S_____WORMWOOD.DESCRIBE.PLANT_PLANTMEAT_L = {
    GROWING = "My friend's mouth is not big enough to eat insects.",
    READY = "Matured.", WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S________WARLY.DESCRIBE.PLANT_PLANTMEAT_L = ""
-- S_________WURT.DESCRIBE.PLANT_PLANTMEAT_L = ""
-- S_______WALTER.DESCRIBE.PLANT_PLANTMEAT_L = ""
-- S________WANDA.DESCRIBE.PLANT_PLANTMEAT_L = ""

S_NAMES.PLANT_NEPENTHES_L = "Vase Herb" --巨食草(成熟阶段的)
S______GENERIC.DESCRIBE.PLANT_NEPENTHES_L = "What a big insect eating plant!"
-- S_______WILLOW.DESCRIBE.PLANT_NEPENTHES_L = ""
S_____WOLFGANG.DESCRIBE.PLANT_NEPENTHES_L = "Wolfgang's farm has been saved."
S________WENDY.DESCRIBE.PLANT_NEPENTHES_L = "When will the struggle between insects and plants end."
S_________WX78.DESCRIBE.PLANT_NEPENTHES_L = "LET'S MARCH TOWARDS THE PESTS!"
S_WICKERBOTTOM.DESCRIBE.PLANT_NEPENTHES_L = "Its digestive juices can decompose most materials."
S_______WOODIE.DESCRIBE.PLANT_NEPENTHES_L = "I haven't seen this before."
-- S______WAXWELL.DESCRIBE.PLANT_NEPENTHES_L = ""
-- S___WATHGRITHR.DESCRIBE.PLANT_NEPENTHES_L = ""
S_______WEBBER.DESCRIBE.PLANT_NEPENTHES_L = "It must be a great place for hide and seek!"
S_______WINONA.DESCRIBE.PLANT_NEPENTHES_L = "Fantastic plants and where to find them?"
S_______WORTOX.DESCRIBE.PLANT_NEPENTHES_L = "My friend, I know you have bold ideas."
S_____WORMWOOD.DESCRIBE.PLANT_NEPENTHES_L = "Very reliable friend!"
S________WARLY.DESCRIBE.PLANT_NEPENTHES_L = "It doesn't eat me, and I don't eat it either."
-- S_________WURT.DESCRIBE.PLANT_NEPENTHES_L = ""
S_______WALTER.DESCRIBE.PLANT_NEPENTHES_L = "It eats everything, even more gluttonous than Woby."
S________WANDA.DESCRIBE.PLANT_NEPENTHES_L = "The ones I've seen before aren't that big."

S_NAMES.PLANT_LOG_L = "Cloud Pinus" --云青松
S______GENERIC.DESCRIBE.PLANT_LOG_L = {
    GROWING = "Its magical tree roots are connected to other same kind.",
    READY = "It is lush and the top branches are particularly tender.",
    WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S_______WILLOW.DESCRIBE.PLANT_LOG_L = ""
-- S_____WOLFGANG.DESCRIBE.PLANT_LOG_L = ""
-- S________WENDY.DESCRIBE.PLANT_LOG_L = ""
-- S_________WX78.DESCRIBE.PLANT_LOG_L = ""
-- S_WICKERBOTTOM.DESCRIBE.PLANT_LOG_L = ""
S_______WOODIE.DESCRIBE.PLANT_LOG_L = {
    GROWING = "Be patient, Lucy, we still have to wait.",
    READY = "It's really lush, my Lucy can't wait anymore.",
    WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S______WAXWELL.DESCRIBE.PLANT_LOG_L = ""
-- S___WATHGRITHR.DESCRIBE.PLANT_LOG_L = ""
-- S_______WEBBER.DESCRIBE.PLANT_LOG_L = ""
-- S_______WINONA.DESCRIBE.PLANT_LOG_L = ""
-- S_______WORTOX.DESCRIBE.PLANT_LOG_L = ""
S_____WORMWOOD.DESCRIBE.PLANT_LOG_L = {
    GROWING = "This tree friend can store my belongings.",
    READY = "I wish I could grow this big too.",
    WITHERED = "Withered.", BLOOMY = "Blooming."
}
-- S________WARLY.DESCRIBE.PLANT_LOG_L = ""
-- S_________WURT.DESCRIBE.PLANT_LOG_L = ""
-- S_______WALTER.DESCRIBE.PLANT_LOG_L = ""
-- S________WANDA.DESCRIBE.PLANT_LOG_L = ""

S_NAMES.PLANT_BERRIES_L = "Jabuticaba" --果攀树
S______GENERIC.DESCRIBE.PLANT_BERRIES_L = {
    GROWING = "A tall shrub.",
    READY = "Berries covered the trunk of the tree.",
    WITHERED = "Who raised it to death, it's not me anyway.",
    BLOOMY = "Orange flowers bloom all over the tree trunk."
}
-- S_______WILLOW.DESCRIBE.PLANT_BERRIES_L = ""
-- S_____WOLFGANG.DESCRIBE.PLANT_BERRIES_L = ""
-- S________WENDY.DESCRIBE.PLANT_BERRIES_L = ""
-- S_________WX78.DESCRIBE.PLANT_BERRIES_L = ""
S_WICKERBOTTOM.DESCRIBE.PLANT_BERRIES_L = {
    GROWING = "There is enough space left on the trunk to bear fruit.",
    READY = "If it is mature enough, the fruit will be harder and more durable.",
    WITHERED = "As long as the root does not die, it will be saved.",
    BLOOMY = "The fruit trees in their flowering period are the most charming."
}
-- S_______WOODIE.DESCRIBE.PLANT_BERRIES_L = ""
-- S______WAXWELL.DESCRIBE.PLANT_BERRIES_L = ""
-- S___WATHGRITHR.DESCRIBE.PLANT_BERRIES_L = ""
-- S_______WEBBER.DESCRIBE.PLANT_BERRIES_L = ""
-- S_______WINONA.DESCRIBE.PLANT_BERRIES_L = ""
-- S_______WORTOX.DESCRIBE.PLANT_BERRIES_L = ""
S_____WORMWOOD.DESCRIBE.PLANT_BERRIES_L = {
    GROWING = "A fruiting little tree friend.",
    READY = "My friend has a lot of fruit on his neck.",
    WITHERED = "My friend is just tired.",
    BLOOMY = "My friend has many flowers blooming around his neck."
}
-- S________WARLY.DESCRIBE.PLANT_BERRIES_L = ""
-- S_________WURT.DESCRIBE.PLANT_BERRIES_L = ""
-- S_______WALTER.DESCRIBE.PLANT_BERRIES_L = ""
-- S________WANDA.DESCRIBE.PLANT_BERRIES_L = ""

S_NAMES.PLANT_CACTUS_MEAT_L = "Cactaceae" --仙人柱
S______GENERIC.DESCRIBE.PLANT_CACTUS_MEAT_L = {
    GROWING = "It adds a touch of desert charm to this place.",
    READY = "I really want to take a bite of this fresh and juicy leaf flesh.",
    WITHERED = "Can this be raised to death!",
    BLOOMY = "I didn't expect this bald plant to still bloom."
}
-- S_______WILLOW.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S_____WOLFGANG.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S________WENDY.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S_________WX78.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
S_WICKERBOTTOM.DESCRIBE.PLANT_CACTUS_MEAT_L = {
    GROWING = "A cactus plant.",
    READY = "This cactus plant is edible.",
    WITHERED = "Watering may restore vitality.",
    BLOOMY = "If it were in summer, its flowers would bloom even more vigorously."
}
-- S_______WOODIE.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S______WAXWELL.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S___WATHGRITHR.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S_______WEBBER.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S_______WINONA.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
S_______WORTOX.DESCRIBE.PLANT_CACTUS_MEAT_L = {
    GROWING = "See if you can prick me.",
    READY = "When I'm almost thirsty, I'll come find you.",
    WITHERED = "Most likely dead.",
    BLOOMY = "Brilliant like summer flowers."
}
S_____WORMWOOD.DESCRIBE.PLANT_CACTUS_MEAT_L = {
    GROWING = "A friend in desert style.",
    READY = "Really strong.",
    WITHERED = "It's my turn to take care of you.",
    BLOOMY = "Desert flowers."
}
-- S________WARLY.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S_________WURT.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S_______WALTER.DESCRIBE.PLANT_CACTUS_MEAT_L = ""
-- S________WANDA.DESCRIBE.PLANT_CACTUS_MEAT_L = ""

S_NAMES.PLANT_CARROT_L = "Carrot Cluster" --芾萝卜
S______GENERIC.DESCRIBE.PLANT_CARROT_L = {
    GROWING = "This? Is it really a carrot?",
    READY = "Look at this plump and red rhizome, it's already ripe.",
    WITHERED = "After withering, it becomes very hard.",
    BLOOMY = "Blooming."
}
-- S_______WILLOW.DESCRIBE.PLANT_CARROT_L = ""
-- S_____WOLFGANG.DESCRIBE.PLANT_CARROT_L = ""
-- S________WENDY.DESCRIBE.PLANT_CARROT_L = ""
-- S_________WX78.DESCRIBE.PLANT_CARROT_L = ""
-- S_WICKERBOTTOM.DESCRIBE.PLANT_CARROT_L = ""
-- S_______WOODIE.DESCRIBE.PLANT_CARROT_L = ""
-- S______WAXWELL.DESCRIBE.PLANT_CARROT_L = ""
S___WATHGRITHR.DESCRIBE.PLANT_CARROT_L = {
    GROWING = "A longer and harder one can be used as a weapon.",
    READY = "Maybe I can pick a few to use as weapons.",
    WITHERED = "Although it looks hard, it's too brittle.",
    BLOOMY = "Blooming."
}
-- S_______WEBBER.DESCRIBE.PLANT_CARROT_L = ""
-- S_______WINONA.DESCRIBE.PLANT_CARROT_L = ""
-- S_______WORTOX.DESCRIBE.PLANT_CARROT_L = ""
S_____WORMWOOD.DESCRIBE.PLANT_CARROT_L = {
    GROWING = "Are you a carrot friend?",
    READY = "One after another.",
    WITHERED = "My friends are still alive underground.",
    BLOOMY = "Blooming."
}
-- S________WARLY.DESCRIBE.PLANT_CARROT_L = ""
-- S_________WURT.DESCRIBE.PLANT_CARROT_L = ""
-- S_______WALTER.DESCRIBE.PLANT_CARROT_L = ""
-- S________WANDA.DESCRIBE.PLANT_CARROT_L = ""

S_NAMES.PLANT_LIGHTBULB_L = "Night Bright Flower" --夜盏花
S______GENERIC.DESCRIBE.PLANT_LIGHTBULB_L = {
    GROWING = "It will bloom interesting glowing flowers.",
    READY = "It's matured and really bright.",
    WITHERED = "You are still the most shining in my heart.",
    BLOOMY = "Its flowers are really eye-catching."
}
S_______WILLOW.DESCRIBE.PLANT_LIGHTBULB_L = {
    GROWING = "I want to see how this grass shines like fire.",
    READY = "It's matured and really bright.",
    WITHERED = "It looks like this, why not burn it.",
    BLOOMY = "Although it's bright, it's not hot enough."
}
-- S_____WOLFGANG.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S________WENDY.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S_________WX78.DESCRIBE.PLANT_LIGHTBULB_L = ""
S_WICKERBOTTOM.DESCRIBE.PLANT_LIGHTBULB_L = {
    GROWING = "It doesn't rely on photosynthesis, and sunlight can actually hinder its growth.",
    READY = "It's matured and really bright.",
    WITHERED = "Its withering is temporary.",
    BLOOMY = "Its flowers contain a large amount of luminescent substances."
}
-- S_______WOODIE.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S______WAXWELL.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S___WATHGRITHR.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S_______WEBBER.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S_______WINONA.DESCRIBE.PLANT_LIGHTBULB_L = ""
S_______WORTOX.DESCRIBE.PLANT_LIGHTBULB_L = {
    GROWING = "Light up quickly, little flower.",
    READY = "It's matured and really bright.",
    WITHERED = "Wake up, and go back to sleep.",
    BLOOMY = "Wow, it's so bright that it can make you blind."
}
S_____WORMWOOD.DESCRIBE.PLANT_LIGHTBULB_L = {
    GROWING = "Friend doesn't like sunlight.",
    READY = "So dazzling.",
    WITHERED = "Friend is tired.",
    BLOOMY = "It's great to have a bright friend!"
}
-- S________WARLY.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S_________WURT.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S_______WALTER.DESCRIBE.PLANT_LIGHTBULB_L = ""
-- S________WANDA.DESCRIBE.PLANT_LIGHTBULB_L = ""

S______GENERIC.DESCRIBE.TISSUE_L = "This fresh plant tissue can be used for research."
-- S_______WILLOW.DESCRIBE.TISSUE_L = ""
-- S_____WOLFGANG.DESCRIBE.TISSUE_L = ""
-- S________WENDY.DESCRIBE.TISSUE_L = ""
-- S_________WX78.DESCRIBE.TISSUE_L = ""
S_WICKERBOTTOM.DESCRIBE.TISSUE_L = "It can be used as a sample for xeeds transformation."
-- S_______WOODIE.DESCRIBE.TISSUE_L = ""
S______WAXWELL.DESCRIBE.TISSUE_L = "Even magic requires samples to study."
-- S___WATHGRITHR.DESCRIBE.TISSUE_L = ""
-- S_______WEBBER.DESCRIBE.TISSUE_L = ""
-- S_______WINONA.DESCRIBE.TISSUE_L = ""
-- S_______WORTOX.DESCRIBE.TISSUE_L = ""
S_____WORMWOOD.DESCRIBE.TISSUE_L = "A part of a friend."
-- S________WARLY.DESCRIBE.TISSUE_L = ""
-- S_________WURT.DESCRIBE.TISSUE_L = ""
-- S_______WALTER.DESCRIBE.TISSUE_L = ""
-- S________WANDA.DESCRIBE.TISSUE_L = ""

S_NAMES.TISSUE_L_CACTUS = "Living Tissue of Cactus" --仙人掌活性组织
S_NAMES.TISSUE_L_LUREPLANT = "Living Tissue of Lureplant" --食人花活性组织
S_NAMES.TISSUE_L_BERRIES = "Living Tissue of Berry Bush" --浆果丛活性组织
S_NAMES.TISSUE_L_LIGHTBULB = "Living Tissue of Light Flowers" --荧光花活性组织

S_NAMES.OINTMENT_L_SIVBLOODREDUCE = "Weak Skin Ointment" --弱肤药膏
S_RECIPE_DESC.OINTMENT_L_SIVBLOODREDUCE = "Applying it can weaken biological activity."
S______GENERIC.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = "This thing actually smells a bit."
-- S_______WILLOW.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
-- S_____WOLFGANG.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
-- S________WENDY.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
-- S_________WX78.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
S_WICKERBOTTOM.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = "The crab tribe has found a good solution after paying a huge price."
-- S_______WOODIE.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
S______WAXWELL.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = "This is not magic."
-- S___WATHGRITHR.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
-- S_______WEBBER.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
-- S_______WINONA.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
S_______WORTOX.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = "It's very serious, I'm not joking."
S_____WORMWOOD.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = "I don't want to smear."
-- S________WARLY.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
-- S_________WURT.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
-- S_______WALTER.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = ""
S________WANDA.DESCRIBE.OINTMENT_L_SIVBLOODREDUCE = "What a coincidence it takes for them to create this thing."

S_NAMES.BUFF_L_SIVBLOODREDUCE = "Dead Skin"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = "I feel my skin is very uncomfortable."
-- S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_________WX78.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = ""
S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = "Weakening the surface activity of the skin to protect the interior."
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = ""
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = "This bit of skin bitterness is nothing."
S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = "Our fuzz feels like it's almost shedding."
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = ""
S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = "I hope it won't make me lose my hair."
S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE = "I'm starting to peel off."
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE =
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE =
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE =
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_SIVBLOODREDUCE =
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = "The discomfort on the skin has disappeared."
-- S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_________WX78.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = ""
S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = "Great, my soft hair is back."
S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE = "I won't peel off now."
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE =
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE =
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE =
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_SIVBLOODREDUCE =

S_NAMES.CUTTED_LUMPYEVERGREEN = "The Tender Branche of Lumpy Evergreen" --臃肿常青树嫩枝
S______GENERIC.DESCRIBE.CUTTED_LUMPYEVERGREEN = "The wonder of plants is that they can reproduce without seeds."
S_______WILLOW.DESCRIBE.CUTTED_LUMPYEVERGREEN = "Burn it, I won't think so much."
-- S_____WOLFGANG.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S________WENDY.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_________WX78.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_WICKERBOTTOM.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_______WOODIE.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S______WAXWELL.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S___WATHGRITHR.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_______WEBBER.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_______WINONA.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_______WORTOX.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
S_____WORMWOOD.DESCRIBE.CUTTED_LUMPYEVERGREEN = "A part of friend."
-- S________WARLY.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_________WURT.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S_______WALTER.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""
-- S________WANDA.DESCRIBE.CUTTED_LUMPYEVERGREEN = ""

S_NAMES.BOXOPENER_L = "Cloud Pinut"
S_RECIPE_DESC.BOXOPENER_L = "The seed leading to the heart of the tree."
S______GENERIC.DESCRIBE.BOXOPENER_L = "Through the gaps, one can peek inside."
S_______WILLOW.DESCRIBE.BOXOPENER_L = "I really want to sneak through and burn down that area."
-- S_____WOLFGANG.DESCRIBE.BOXOPENER_L = ""
S________WENDY.DESCRIBE.BOXOPENER_L = "Who did you give your heart to."
-- S_________WX78.DESCRIBE.BOXOPENER_L = ""
S_WICKERBOTTOM.DESCRIBE.BOXOPENER_L = "It has a certain connection with Cloud Pinus."
S_______WOODIE.DESCRIBE.BOXOPENER_L = "Seeds that do not germinate must have other uses."
S______WAXWELL.DESCRIBE.BOXOPENER_L = "There is no privacy at all in this."
-- S___WATHGRITHR.DESCRIBE.BOXOPENER_L = ""
-- S_______WEBBER.DESCRIBE.BOXOPENER_L = ""
S_______WINONA.DESCRIBE.BOXOPENER_L = "Maybe I should put some commonly used tools inside."
S_______WORTOX.DESCRIBE.BOXOPENER_L = "The body of this seed is here, and the heart is elsewhere."
S_____WORMWOOD.DESCRIBE.BOXOPENER_L = "Heart to heart!"
-- S________WARLY.DESCRIBE.BOXOPENER_L = ""
-- S_________WURT.DESCRIBE.BOXOPENER_L = ""
S_______WALTER.DESCRIBE.BOXOPENER_L = "I have done a interesting task of collecting tree seeds before."
-- S________WANDA.DESCRIBE.BOXOPENER_L = ""

S_NAMES.SIVING_BOXOPENER = "Siving-Nexus"
S_RECIPE_DESC.SIVING_BOXOPENER = "The roots of seeds and trees, intertwined with each other."
S______GENERIC.DESCRIBE.SIVING_BOXOPENER = "Even though we are far and wide, we are no longer alone."
-- S_______WILLOW.DESCRIBE.SIVING_BOXOPENER = ""
-- S_____WOLFGANG.DESCRIBE.SIVING_BOXOPENER = ""
S________WENDY.DESCRIBE.SIVING_BOXOPENER = "Just like a tree hole, someone will listen to your voice."
-- S_________WX78.DESCRIBE.SIVING_BOXOPENER = ""
S_WICKERBOTTOM.DESCRIBE.SIVING_BOXOPENER = "It has a very deep connection with Cloud Pinus."
-- S_______WOODIE.DESCRIBE.SIVING_BOXOPENER = ""
S______WAXWELL.DESCRIBE.SIVING_BOXOPENER = "It's too similar to my space magic."
-- S___WATHGRITHR.DESCRIBE.SIVING_BOXOPENER = ""
-- S_______WEBBER.DESCRIBE.SIVING_BOXOPENER = ""
S_______WINONA.DESCRIBE.SIVING_BOXOPENER = "I really need a cross space storage device."
-- S_______WORTOX.DESCRIBE.SIVING_BOXOPENER = ""
S_____WORMWOOD.DESCRIBE.SIVING_BOXOPENER = "Our hearts are connected!"
-- S________WARLY.DESCRIBE.SIVING_BOXOPENER = ""
-- S_________WURT.DESCRIBE.SIVING_BOXOPENER = ""
-- S_______WALTER.DESCRIBE.SIVING_BOXOPENER = ""
S________WANDA.DESCRIBE.SIVING_BOXOPENER = "It's not just time that connects us."

--------------------------------------------------------------------------
--[[ flash and crush ]]--[[ 电闪雷鸣 ]]
--------------------------------------------------------------------------

S_NAMES.ELECOURMALINE = "Elecourmaline"    --电气重铸台
S______GENERIC.DESCRIBE.ELECOURMALINE = "It contains the power of electricity and creation."
--S_______WILLOW.DESCRIBE.ELECOURMALINE = "Oh! So cute, like my Bernie."
--S_____WOLFGANG.DESCRIBE.ELECOURMALINE = "Wolfgang can eat in one bite!"
--S________WENDY.DESCRIBE.ELECOURMALINE = "Baby's always so cute, grown one's not."
S_________WX78.DESCRIBE.ELECOURMALINE = "I CAN CHARGE MYSELF WITH JUST A LITTLE PIECE."
S_WICKERBOTTOM.DESCRIBE.ELECOURMALINE = "I heard that the stone will discharge when heated."
--S_______WOODIE.DESCRIBE.ELECOURMALINE = "The axe that can't chop is not a good axe."
S______WAXWELL.DESCRIBE.ELECOURMALINE = "Another of Them is coming. Great."
--S___WATHGRITHR.DESCRIBE.ELECOURMALINE = "I've somehow found a way to make it even LESS appealing!"
--S_______WEBBER.DESCRIBE.ELECOURMALINE = "We don't want to grow up, do you?"
--S_______WINONA.DESCRIBE.ELECOURMALINE = "Great to cool off after some hard physical labor."

S_NAMES.ELECOURMALINE_KEYSTONE = "Key Stone"    --要石
S______GENERIC.DESCRIBE.ELECOURMALINE_KEYSTONE = "Natural creativity."
--S_______WILLOW.DESCRIBE.ELECOURMALINE_KEYSTONE = "Oh! So cute, like my Bernie."
--S_____WOLFGANG.DESCRIBE.ELECOURMALINE_KEYSTONE = "Wolfgang can eat in one bite!"
--S________WENDY.DESCRIBE.ELECOURMALINE_KEYSTONE = "Baby's always so cute, grown one's not."
--S_________WX78.DESCRIBE.ELECOURMALINE_KEYSTONE = "STICK ADDON INSTALLED"
--S_WICKERBOTTOM.DESCRIBE.ELECOURMALINE_KEYSTONE = "Well, isn't that refreshing?"
S_______WOODIE.DESCRIBE.ELECOURMALINE_KEYSTONE = "Hah. Not as funny as Chaplin."
--S______WAXWELL.DESCRIBE.ELECOURMALINE_KEYSTONE = "Hm... No Monster child, no future trouble."
--S___WATHGRITHR.DESCRIBE.ELECOURMALINE_KEYSTONE = "I've somehow found a way to make it even LESS appealing!"
--S_______WEBBER.DESCRIBE.ELECOURMALINE_KEYSTONE = "We don't want to grow up, do you?"
S_______WINONA.DESCRIBE.ELECOURMALINE_KEYSTONE = "Neither the Keystone, nor a key thing."

S_NAMES.FIMBUL_AXE = "Fimbul's Axe"    --芬布尔斧
-- S_RECIPE_DESC.FIMBUL_AXE = "Flash and crush!" --这个不能制作
S______GENERIC.DESCRIBE.FIMBUL_AXE = "BOOM SHAKA LAKA!"
--S_______WILLOW.DESCRIBE.FIMBUL_AXE = "This is the opposite of burning."
--S_____WOLFGANG.DESCRIBE.FIMBUL_AXE = "Wolfgang can eat in one bite!"
--S________WENDY.DESCRIBE.FIMBUL_AXE = "I used to eat these with Abigail..."
--S_________WX78.DESCRIBE.FIMBUL_AXE = "STICK ADDON INSTALLED"
--S_WICKERBOTTOM.DESCRIBE.FIMBUL_AXE = "Well, isn't that refreshing?"
S_______WOODIE.DESCRIBE.FIMBUL_AXE = "An axe that can't chop is not a good axe."
--S______WAXWELL.DESCRIBE.FIMBUL_AXE = "Hm... I don't know what I was expecting."
--S___WATHGRITHR.DESCRIBE.FIMBUL_AXE = "I've somehow found a way to make it even LESS appealing!"
--S_______WEBBER.DESCRIBE.FIMBUL_AXE = "Yaaay! Popsicle, popsicle!"
--S_______WINONA.DESCRIBE.FIMBUL_AXE = "Great to cool off after some hard physical labor."

S_NAMES.HAT_COWBOY = "Stetson"    --牛仔帽
S_RECIPE_DESC.HAT_COWBOY = "Do you want to be a master of taming?"
S______GENERIC.DESCRIBE.HAT_COWBOY = "Aha! let's riiiiiiide!"
-- S_______WILLOW.DESCRIBE.HAT_COWBOY = ""
-- S_____WOLFGANG.DESCRIBE.HAT_COWBOY = ""
-- S________WENDY.DESCRIBE.HAT_COWBOY = ""
-- S_________WX78.DESCRIBE.HAT_COWBOY = ""
-- S_WICKERBOTTOM.DESCRIBE.HAT_COWBOY = ""
-- S_______WOODIE.DESCRIBE.HAT_COWBOY = ""
-- S______WAXWELL.DESCRIBE.HAT_COWBOY = ""
-- S___WATHGRITHR.DESCRIBE.HAT_COWBOY = ""
-- S_______WEBBER.DESCRIBE.HAT_COWBOY = ""
-- S_______WINONA.DESCRIBE.HAT_COWBOY = ""

S_NAMES.DUALWRENCH = "Dual-Wrench"    --扳手-双用型
S_RECIPE_DESC.DUALWRENCH = "Definitely the wrong way to use it."
S______GENERIC.DESCRIBE.DUALWRENCH = "This is definitely the wrong way to use it."
--S_______WILLOW.DESCRIBE.DUALWRENCH = "This is the opposite of burning."
--S_____WOLFGANG.DESCRIBE.DUALWRENCH = "Wolfgang can eat in one bite!"
S________WENDY.DESCRIBE.DUALWRENCH = "I hope I won't wrench my hand any more."
--S_________WX78.DESCRIBE.DUALWRENCH = "STICK ADDON INSTALLED"
--S_WICKERBOTTOM.DESCRIBE.DUALWRENCH = "Well, isn't that refreshing?"
--S_______WOODIE.DESCRIBE.DUALWRENCH = "I'd prefer maple taffy..."
--S______WAXWELL.DESCRIBE.DUALWRENCH = "Hm... I don't know what I was expecting."
S___WATHGRITHR.DESCRIBE.DUALWRENCH = "A weapon for workmen, smash!"
S_______WEBBER.DESCRIBE.DUALWRENCH = "Let's not wrench our hands again."
S_______WINONA.DESCRIBE.DUALWRENCH = "My, my! my best wrench!"

S_NAMES.ELECARMET = "Elecarmet"    --莱克阿米特
S______GENERIC.DESCRIBE.ELECARMET = "I thought it was the end, but just the beginning."
--S_______WILLOW.DESCRIBE.ELECARMET = "This is the opposite of burning."
--S_____WOLFGANG.DESCRIBE.ELECARMET = "Wolfgang can eat in one bite!"
--S________WENDY.DESCRIBE.ELECARMET = "I used to eat these with Abigail..."
--S_________WX78.DESCRIBE.ELECARMET = "STICK ADDON INSTALLED"
--S_WICKERBOTTOM.DESCRIBE.ELECARMET = "Well, isn't that refreshing?"
--S_______WOODIE.DESCRIBE.ELECARMET = "I'd prefer maple taffy..."
--S______WAXWELL.DESCRIBE.ELECARMET = "Hm... I don't know what I was expecting."
S___WATHGRITHR.DESCRIBE.ELECARMET = "My greatest enemy, a Fimbul."
--S_______WEBBER.DESCRIBE.ELECARMET = "Yaaay! Popsicle, popsicle!"
--S_______WINONA.DESCRIBE.ELECARMET = "Great to cool off after some hard physical labor."

S_NAMES.TOURMALINECORE = "Tourmaline" --电气石
S_RECIPE_DESC.TOURMALINECORE = "Used to store the main energy of the electrical age."
S______GENERIC.DESCRIBE.TOURMALINECORE = "Oh my, can I touch it?"
S_______WILLOW.DESCRIBE.TOURMALINECORE = "I prefer Red Gems."
--S_____WOLFGANG.DESCRIBE.TOURMALINECORE = ""
--S________WENDY.DESCRIBE.TOURMALINECORE = ""
S_________WX78.DESCRIBE.TOURMALINECORE = "THE CORE OF ENERGY, THE ENERGY OF ME!"
S_WICKERBOTTOM.DESCRIBE.TOURMALINECORE = "A crystal that can collect charges."
-- S_______WOODIE.DESCRIBE.TOURMALINECORE = ""
S______WAXWELL.DESCRIBE.TOURMALINECORE = "Cyan brings thunder and lightning."
--S___WATHGRITHR.DESCRIBE.TOURMALINECORE = ""
S_______WEBBER.DESCRIBE.TOURMALINECORE = "Rub it."
S_______WINONA.DESCRIBE.TOURMALINECORE = "It's very useful for me!"
S________WARLY.DESCRIBE.TOURMALINECORE = "I'm a little interested in this stone now."
-- S_______WORTOX.DESCRIBE.TOURMALINECORE = ""
S_____WORMWOOD.DESCRIBE.TOURMALINECORE = "Crackle!"
-- S_________WURT.DESCRIBE.TOURMALINECORE = ""
S_______WALTER.DESCRIBE.TOURMALINECORE = "Can I collect it, can I! Is it okay?"
-- S________WANDA.DESCRIBE.TOURMALINECORE = ""
-- STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.TOURMALINECORE = "这可以用作我机器人的能源核心！"

S_NAMES.TOURMALINESHARD = "Elecourmaline Shard" --带电的晶石
S_RECIPE_DESC.NPC_BEEF_TOURMALINESHARD = "I won't tell you where I found it..."
S______GENERIC.DESCRIBE.TOURMALINESHARD = "I bet a crystal is hidden in this stone."
-- S_______WILLOW.DESCRIBE.TOURMALINESHARD = ""
-- S_____WOLFGANG.DESCRIBE.TOURMALINESHARD = ""
-- S________WENDY.DESCRIBE.TOURMALINESHARD = ""
-- S_________WX78.DESCRIBE.TOURMALINESHARD = ""
S_WICKERBOTTOM.DESCRIBE.TOURMALINESHARD = "A special stone with a weak current."
-- S_______WOODIE.DESCRIBE.TOURMALINESHARD = ""
-- S______WAXWELL.DESCRIBE.TOURMALINESHARD = ""
-- S___WATHGRITHR.DESCRIBE.TOURMALINESHARD = ""
-- S_______WEBBER.DESCRIBE.TOURMALINESHARD = ""
S_______WINONA.DESCRIBE.TOURMALINESHARD = "I need to polish off the useless layer of stones on the outside."
S_______WORTOX.DESCRIBE.TOURMALINESHARD = "An uncut gem goes not sparkle."
-- S_____WORMWOOD.DESCRIBE.TOURMALINESHARD = ""
S________WARLY.DESCRIBE.TOURMALINESHARD = "I am not at all interested in studying stones."
-- S_________WURT.DESCRIBE.TOURMALINESHARD = ""
S_______WALTER.DESCRIBE.TOURMALINESHARD = "Keep the beautiful stone for now."
-- S________WANDA.DESCRIBE.TOURMALINESHARD = ""

S_NAMES.ICIRE_ROCK = "Icire Stone" --鸳鸯石
S_NAMES.ICIRE_ROCK_ITEM_WAXED = "Fuel-Woven Icire Stone"
S_RECIPE_DESC.ICIRE_ROCK = "Heat and cold, two sides of the same coin."
S______GENERIC.DESCRIBE.ICIRE_ROCK = {
    FROZEN = "Such coldness still cannot withstand the scorching summer heat.",
    COLD = "I seem to feel the coolness of autumn.",
    GENERIC = "A precious stone, neither a gem, nor a rock.",
    WARM = "The most comfortable heat won't last long.",
    HOT = "The scorching heat still cannot withstand the severe winter."
}
-- S_______WILLOW.DESCRIBE.ICIRE_ROCK = ""
-- S_____WOLFGANG.DESCRIBE.ICIRE_ROCK = ""
-- S________WENDY.DESCRIBE.ICIRE_ROCK = ""
-- S_________WX78.DESCRIBE.ICIRE_ROCK = ""
-- S_WICKERBOTTOM.DESCRIBE.ICIRE_ROCK = ""
-- S_______WOODIE.DESCRIBE.ICIRE_ROCK = ""
-- S______WAXWELL.DESCRIBE.ICIRE_ROCK = ""
-- S___WATHGRITHR.DESCRIBE.ICIRE_ROCK = ""
-- S_______WEBBER.DESCRIBE.ICIRE_ROCK = ""
-- S_______WINONA.DESCRIBE.ICIRE_ROCK = ""
S_______WORTOX.DESCRIBE.ICIRE_ROCK = {
    FROZEN = "Does anyone want to lick the surface? Giggle...",
    COLD = "Very cool temperature.",
    GENERIC = "A beautiful stone with some practical use.",
    WARM = "It reminds me of those sunny days.",
    HOT = "Very hot, but won't burn hair."
}
S_____WORMWOOD.DESCRIBE.ICIRE_ROCK = {
    FROZEN = "The stone is too cold.",
    COLD = "Cool stone.",
    GENERIC = "Nice stone.",
    WARM = "A warm stone.",
    HOT = "This is a hot stone."
}
S________WARLY.DESCRIBE.ICIRE_ROCK = {
    FROZEN = "Well, it looks like it just came out of the cold storage.",
    COLD = "The temperature is like ice cream, very wonderful.",
    GENERIC = "Like cold food, very ordinary.",
    WARM = "It emits the temperature of noodles soup and warms my stomach.",
    HOT = "If the temperature is higher, I can even fry somethings."
}
-- S_________WURT.DESCRIBE.ICIRE_ROCK = ""
-- S_______WALTER.DESCRIBE.ICIRE_ROCK = ""
-- S________WANDA.DESCRIBE.ICIRE_ROCK = ""

S_NAMES.GUITAR_MIGUEL = "Miguel's guitar"    --米格尔的吉他
S_RECIPE_DESC.GUITAR_MIGUEL = "Become a legendary guitarist."
S______GENERIC.DESCRIBE.GUITAR_MIGUEL = "I'll cross life and death to make you remember me!"
--S_______WILLOW.DESCRIBE.GUITAR_MIGUEL = "This is the opposite of burning."
--S_____WOLFGANG.DESCRIBE.GUITAR_MIGUEL = "Wolfgang can eat in one bite!"
-- S________WENDY.DESCRIBE.GUITAR_MIGUEL = "Hello from the other side, Abigail."
S_________WX78.DESCRIBE.GUITAR_MIGUEL = "IT IS NOT MY FUNCTION TO IMPRESS OTHERS."
--S_WICKERBOTTOM.DESCRIBE.GUITAR_MIGUEL = "Well, isn't that refreshing?"
--S_______WOODIE.DESCRIBE.GUITAR_MIGUEL = "I'd prefer maple taffy..."
--S______WAXWELL.DESCRIBE.GUITAR_MIGUEL = "Hm... I don't know what I was expecting."
-- S___WATHGRITHR.DESCRIBE.GUITAR_MIGUEL = "A weapon for workmen, smash!"
-- S_______WEBBER.DESCRIBE.GUITAR_MIGUEL = "Let's not wrench our hands again."
-- S_______WINONA.DESCRIBE.GUITAR_MIGUEL = "My, my! my best wrench!"

S_NAMES.WEB_HUMP_ITEM = "Territory Mark"    --蛛网标记，物品
S_RECIPE_DESC.WEB_HUMP_ITEM = "Swear your territorial sovereignty!"
S______GENERIC.DESCRIBE.WEB_HUMP_ITEM = "It's not something I would want to use."
-- S_______WILLOW.DESCRIBE.WEB_HUMP_ITEM = "This is the opposite of burning."
-- S_____WOLFGANG.DESCRIBE.WEB_HUMP_ITEM = "Wolfgang can eat in one bite!"
-- S________WENDY.DESCRIBE.WEB_HUMP_ITEM = "Hello from the other side, Abigail."
S_________WX78.DESCRIBE.WEB_HUMP = "OBJECT CLASS: THAUMIEL"
-- S_WICKERBOTTOM.DESCRIBE.WEB_HUMP_ITEM = "Well, isn't that refreshing?"
-- S_______WOODIE.DESCRIBE.WEB_HUMP_ITEM = "I'd prefer maple taffy..."
-- S______WAXWELL.DESCRIBE.WEB_HUMP_ITEM = "Hm... I don't know what I was expecting."
-- S___WATHGRITHR.DESCRIBE.WEB_HUMP_ITEM = "A weapon for workmen, smash!"
S_______WEBBER.DESCRIBE.WEB_HUMP_ITEM = "Indeed, we have too little territory."
-- S_______WINONA.DESCRIBE.WEB_HUMP_ITEM = "My, my! my best wrench!"

S_NAMES.WEB_HUMP = "Territory Mark"    --蛛网标记
S______GENERIC.DESCRIBE.WEB_HUMP =
{
    GENERIC = "That really is too much, spiders!",
    TRYDIGUP = "It's not easy to get rid of this.",
}
-- S_______WILLOW.DESCRIBE.WEB_HUMP = "This is the opposite of burning."
-- S_____WOLFGANG.DESCRIBE.WEB_HUMP = "Wolfgang can eat in one bite!"
-- S________WENDY.DESCRIBE.WEB_HUMP = "Hello from the other side, Abigail."
S_________WX78.DESCRIBE.WEB_HUMP = 
{
    GENERIC = "SPECIAL CONTAINMENT PROCEDURES.",
    TRYDIGUP = "IT CAN NOT BE RELOCATED.",
}
-- S_WICKERBOTTOM.DESCRIBE.WEB_HUMP = "Well, isn't that refreshing?"
-- S_______WOODIE.DESCRIBE.WEB_HUMP = "I'd prefer maple taffy..."
-- S______WAXWELL.DESCRIBE.WEB_HUMP = "Hm... I don't know what I was expecting."
-- S___WATHGRITHR.DESCRIBE.WEB_HUMP = "A weapon for workmen, smash!"
S_______WEBBER.DESCRIBE.WEB_HUMP =
{
    GENERIC = "We are very popular with the residents here.",
    TRYDIGUP = "We got this!",
}
-- S_______WINONA.DESCRIBE.WEB_HUMP = "My, my! my best wrench!"

S_NAMES.TRIPLESHOVELAXE = "Triple-shovelaxe" --斧铲-三用型
S_RECIPE_DESC.TRIPLESHOVELAXE = "A low-cost multi-functional tool."
S______GENERIC.DESCRIBE.TRIPLESHOVELAXE = "Oh my, this tool is soooooo good!"
-- S_______WILLOW.DESCRIBE.TRIPLESHOVELAXE = ""
-- S_____WOLFGANG.DESCRIBE.TRIPLESHOVELAXE = ""
-- S________WENDY.DESCRIBE.TRIPLESHOVELAXE = ""
S_________WX78.DESCRIBE.TRIPLESHOVELAXE = "IT'S JUST A COMBINATION TOOL."
-- S_WICKERBOTTOM.DESCRIBE.TRIPLESHOVELAXE = ""
S_______WOODIE.DESCRIBE.TRIPLESHOVELAXE = "Even the best axe can't replace Lucy."
-- S______WAXWELL.DESCRIBE.TRIPLESHOVELAXE = ""
-- S___WATHGRITHR.DESCRIBE.TRIPLESHOVELAXE = ""
-- S_______WEBBER.DESCRIBE.TRIPLESHOVELAXE = ""
-- S_______WINONA.DESCRIBE.TRIPLESHOVELAXE = ""
-- S_______WORTOX.DESCRIBE.TRIPLESHOVELAXE = ""
S_____WORMWOOD.DESCRIBE.TRIPLESHOVELAXE = "Ugh, a sharp weapon of the nature destroyer."
-- S________WARLY.DESCRIBE.TRIPLESHOVELAXE = ""
-- S_________WURT.DESCRIBE.TRIPLESHOVELAXE = ""
-- S_______WALTER.DESCRIBE.TRIPLESHOVELAXE = ""
S________WANDA.DESCRIBE.TRIPLESHOVELAXE = "I will prepare what I need another time."

S_NAMES.TRIPLEGOLDENSHOVELAXE = "Snazzy Triple-shovelaxe" --斧铲-黄金三用型
S_RECIPE_DESC.TRIPLEGOLDENSHOVELAXE = "Extremely durable multi-functional tool."
S______GENERIC.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "Oh my, this tool is soooooo perfect!"
-- S_______WILLOW.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
S_____WOLFGANG.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "Wolfgang is ready to make a big splash!"
-- S________WENDY.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
-- S_________WX78.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
S_WICKERBOTTOM.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "What a conveniant wilderness survival tool!"
S_______WOODIE.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "It's amazing! Oh, I hope Lucy didn't hear it."
-- S______WAXWELL.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
-- S___WATHGRITHR.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
-- S_______WEBBER.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
S_______WINONA.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "I should have more of these in my toolbox."
-- S_______WORTOX.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
S_____WORMWOOD.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "Cursed, throw it away!"
S________WARLY.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "Devours natural resources like a cake!"
-- S_________WURT.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
-- S_______WALTER.DESCRIBE.TRIPLEGOLDENSHOVELAXE = ""
S________WANDA.DESCRIBE.TRIPLEGOLDENSHOVELAXE = "I don't mind taking one with me."

S_NAMES.HAT_ALBICANS_MUSHROOM = "Albicans Funcap"    --素白蘑菇帽
S_RECIPE_DESC.HAT_ALBICANS_MUSHROOM = "Let lots of antibiotics stick to your head."
S______GENERIC.DESCRIBE.HAT_ALBICANS_MUSHROOM = {
    GENERIC = "A hat made of antibiotic-rich fungi.",
    HUNGER = "I'm too hungry, I don't have the energy to do this."
}
-- S_______WILLOW.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
-- S_____WOLFGANG.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
-- S________WENDY.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
S_________WX78.DESCRIBE.HAT_ALBICANS_MUSHROOM = {
    GENERIC = "SOME CREATURES CROWD OUT OTHERS.",
    HUNGER = "I HAVE RUN OUT OF FUEL!"
}
S_WICKERBOTTOM.DESCRIBE.HAT_ALBICANS_MUSHROOM = {
    GENERIC = "It has a good resistance to harmful bacteria.",
    HUNGER = "What if someone is allergic to antibiotics."
}
-- S_______WOODIE.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
-- S______WAXWELL.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
-- S___WATHGRITHR.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
S_______WEBBER.DESCRIBE.HAT_ALBICANS_MUSHROOM = {
    GENERIC = "The head shakes and the disease escapes.",
    HUNGER = "We are so hungry."
}
-- S_______WINONA.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
-- S_______WORTOX.DESCRIBE.HAT_ALBICANS_MUSHROOM = ""
S_____WORMWOOD.DESCRIBE.HAT_ALBICANS_MUSHROOM = {
    GENERIC = "My friends, we are saved.",
    HUNGER = "My stomach is empty!"
}
S________WARLY.DESCRIBE.HAT_ALBICANS_MUSHROOM = {
    GENERIC = "Can I break a piece and cook it?",
    HUNGER = "Nothing magic is ever done on an empty stomach!"
}
S_________WURT.DESCRIBE.HAT_ALBICANS_MUSHROOM = {
    GENERIC = "Maybe it can treat plants infected with fungi.",
    HUNGER = "I need fresh food!"
}

S_NAMES.BUFF_L_SPORERESISTANCE = "Spore Resistance"

S_NAMES.ALBICANS_CAP = "Albicans Cap" --采摘的素白菇
S______GENERIC.DESCRIBE.ALBICANS_CAP = "It's the first time I've seen such delicacies."
-- S_______WILLOW.DESCRIBE.ALBICANS_CAP = ""
-- S_____WOLFGANG.DESCRIBE.ALBICANS_CAP = ""
-- S________WENDY.DESCRIBE.ALBICANS_CAP = ""
-- S_________WX78.DESCRIBE.ALBICANS_CAP = ""
S_WICKERBOTTOM.DESCRIBE.ALBICANS_CAP = "Strange, it should grow deep in the bamboo forest."
-- S_______WOODIE.DESCRIBE.ALBICANS_CAP = ""
-- S______WAXWELL.DESCRIBE.ALBICANS_CAP = ""
-- S___WATHGRITHR.DESCRIBE.ALBICANS_CAP = ""
S_______WEBBER.DESCRIBE.ALBICANS_CAP = "A mushroom wearing a skirt!"
-- S_______WINONA.DESCRIBE.ALBICANS_CAP = ""
S_______WORTOX.DESCRIBE.ALBICANS_CAP = "A sacred mushroom like this doesn't belong here."
S_____WORMWOOD.DESCRIBE.ALBICANS_CAP = "Beautiful dress friend."
S________WARLY.DESCRIBE.ALBICANS_CAP = "I need to think carefully about what dish to make it into."
-- S_________WURT.DESCRIBE.ALBICANS_CAP = ""
S_______WALTER.DESCRIBE.ALBICANS_CAP = "I have only found black truffles in the forest."
S________WANDA.DESCRIBE.ALBICANS_CAP = "Very uncommon mushrooms."

S_NAMES.ALBICANS_CAP_COOKED = "Cooked Albicans Cap" --熟素白菇
S______GENERIC.DESCRIBE.ALBICANS_CAP_COOKED = "Simple processed rare mushrooms."
S_______WILLOW.DESCRIBE.ALBICANS_CAP_COOKED = "It's good that it hasn't been roasted to ashes."
-- S_____WOLFGANG.DESCRIBE.ALBICANS_CAP_COOKED = ""
-- S________WENDY.DESCRIBE.ALBICANS_CAP_COOKED = ""
-- S_________WX78.DESCRIBE.ALBICANS_CAP_COOKED = ""
S_WICKERBOTTOM.DESCRIBE.ALBICANS_CAP_COOKED = "This mushroom is easy to rot, it's best to process it early."
-- S_______WOODIE.DESCRIBE.ALBICANS_CAP_COOKED = ""
S______WAXWELL.DESCRIBE.ALBICANS_CAP_COOKED = "It would be even better if it were made into a dish."
-- S___WATHGRITHR.DESCRIBE.ALBICANS_CAP_COOKED = ""
-- S_______WEBBER.DESCRIBE.ALBICANS_CAP_COOKED = ""
-- S_______WINONA.DESCRIBE.ALBICANS_CAP_COOKED = ""
-- S_______WORTOX.DESCRIBE.ALBICANS_CAP_COOKED = ""
S_____WORMWOOD.DESCRIBE.ALBICANS_CAP_COOKED = "Cooked, Why?"
S________WARLY.DESCRIBE.ALBICANS_CAP_COOKED = "The processing is poor, but the flavor is still retained."
-- S_________WURT.DESCRIBE.ALBICANS_CAP_COOKED = ""
-- S_______WALTER.DESCRIBE.ALBICANS_CAP_COOKED = ""
S________WANDA.DESCRIBE.ALBICANS_CAP_COOKED = "I won't get tired of eating it no matter how many times."

S_NAMES.SOUL_CONTRACTS = "Soul Contracts" --灵魂契约
S_RECIPE_DESC.SOUL_CONTRACTS = "Sign a contract to further shackle souls."
S______GENERIC.DESCRIBE.SOUL_CONTRACTS = {
    GENERIC = "It's completely a standard devilish style.",
    SIGN = "My soul is no longer kind.",
    TERMINATE = "I have freed myself from the shackles of demons.",
    WRONG = "Where is the problem?",
    NOTMINE = "It's not something I can manipulate.",
    SOULLESS = "There is no soul left.",
    OWNERSOULLESS = "I have no soul left in my hands.",
    NOBOOK = "There are no other Soul Contracts nearby.",
    BOOKISFULL = "Other contracts don't require our help.",
    BOOKISHIGH = "Other contracts don't need us to impart soul maps.",
    RECORDED = "This creature has been engraved into soul maps.",
    NOTRECORDED = "Contracts still yearn for their soul map!"
}
-- S_______WILLOW.DESCRIBE.SOUL_CONTRACTS = ""
-- S_____WOLFGANG.DESCRIBE.SOUL_CONTRACTS = ""
S________WENDY.DESCRIBE.SOUL_CONTRACTS = {
    GENERIC = "The souls in the book are struggling and crying...",
    SIGN = "I know it's evil, but I have to try various ways.",
    TERMINATE = "I will always remember what I did.",
    WRONG = "Things always go against my expectations.",
    NOTMINE = "Someone stepped into hell ahead of schedule.",
    SOULLESS = "Do you also have moments of exhaustion.",
    OWNERSOULLESS = "I have exhausted my souls.",
    NOBOOK = "There is no one around us who is as corrupt as us.",
    BOOKISFULL = "They don't need souls for now.",
    BOOKISHIGH = "The transmission between evil has been completed.",
    RECORDED = "Already corrupted by evil.",
    NOTRECORDED = "They have not been tainted by evil."
}
-- S_________WX78.DESCRIBE.SOUL_CONTRACTS =
-- S_WICKERBOTTOM.DESCRIBE.SOUL_CONTRACTS = ""
-- S_______WOODIE.DESCRIBE.SOUL_CONTRACTS = ""
S______WAXWELL.DESCRIBE.SOUL_CONTRACTS = {
    GENERIC = "Don't play with powers you don't understand.",
    SIGN = "With my experience, I will never be manipulated by it.",
    TERMINATE = "Fortunately, I am still safe and sound.",
    WRONG = "Something the matter!",
    NOTMINE = "It has been signed and no longer belongs to me.",
    SOULLESS = "The soul in the contracts has been exhausted.",
    OWNERSOULLESS = "Who has souls in their hands? I am not a demon.",
    NOBOOK = "The operation of magic requires at least another Soul Contracts.",
    BOOKISFULL = "The souls in other contracts are sufficient.",
    BOOKISHIGH = "The ceremony of imparting the soul maps has ended.",
    RECORDED = "Their soul maps are depicted perfectly.",
    NOTRECORDED = "We need to find a way to obtain their soul maps."
}
-- S___WATHGRITHR.DESCRIBE.SOUL_CONTRACTS =
S_______WEBBER.DESCRIBE.SOUL_CONTRACTS = {
    GENERIC = "This book, is so cool!",
    SIGN = "Is this a game? But there seems to be something wrong.",
    TERMINATE = "We understand that this is not a game.",
    WRONG = "Something went wrong.",
    NOTMINE = "It's not our book.",
    SOULLESS = "The soul in the book has been used up.",
    OWNERSOULLESS = "We've used up all the souls in our hands.",
    NOBOOK = "There are no other books around.",
    BOOKISFULL = "All other books are full of soul.",
    BOOKISHIGH = "The atlas of other books is complete.",
    RECORDED = "We have their soul atlas.",
    NOTRECORDED = "There is currently no soul atlas for them."
}
-- S_______WINONA.DESCRIBE.SOUL_CONTRACTS = ""
S_______WORTOX.DESCRIBE.SOUL_CONTRACTS = {
    GENERIC = "Hah, I can better imprison my souls!",
    SIGN = "I'm not inherently kind, but I'm not that bad either.",
    TERMINATE = "Hmph, someone will know that I am ultimately kind.",
    WRONG = "A new problem has emerged.",
    NOTMINE = "Someone took the lead. No!",
    SOULLESS = "My contract is so thin that it doesn't look like a book anymore.",
    OWNERSOULLESS = "Soul is empty, head is buzzing.",
    NOBOOK = "It seems that I am the only demon.",
    BOOKISFULL = "Demons no longer need help from their own kind.",
    BOOKISHIGH = "There is still a lot of information sharing between demons.",
    RECORDED = "They are already in my soul collection.",
    NOTRECORDED = "Their souls are not only delicious, but also beautiful."
}
S_____WORMWOOD.DESCRIBE.SOUL_CONTRACTS = {
    GENERIC = "Scary book.",
    SIGN = "What is soul?",
    TERMINATE = "It's over.",
    WRONG = "Wrong!",
    NOTMINE = "Not mine.",
    SOULLESS = "Scary book has no soul.",
    OWNERSOULLESS = "I have no soul left.",
    NOBOOK = "No other scary books around.",
    BOOKISFULL = "Souls are enough.",
    BOOKISHIGH = "Soul maps are enough.",
    RECORDED = "I have seen it in scary book.",
    NOTRECORDED = "Not in scary book."
}
-- S________WARLY.DESCRIBE.SOUL_CONTRACTS = ""
-- S_________WURT.DESCRIBE.SOUL_CONTRACTS =
S_______WALTER.DESCRIBE.SOUL_CONTRACTS = {
    GENERIC = "Woby, look, this book seems to want to talk to me.",
    SIGN = "Let's give it a try, there shouldn't be any danger.",
    TERMINATE = "Woby, we've done a lot of bad things, haven't we?",
    WRONG = "I don't know what's wrong.",
    NOTMINE = "It doesn't want to talk to me anymore.",
    SOULLESS = "No soul left. Woby, let's go find some souls.",
    OWNERSOULLESS = "I have no soul left to give you.",
    NOBOOK = "This kind of book requires two books.",
    BOOKISFULL = "Their souls have stored enough.",
    BOOKISHIGH = "The portraits of souls have been given to them.",
    RECORDED = "Their soul portraits are already in the book.",
    NOTRECORDED = "A new soul portrait needs to be depicted!"
}
-- S________WANDA.DESCRIBE.SOUL_CONTRACTS = ""

STRINGS.COMMANDS_SOUL_CONTRACTS = {
    SIGN = "Sign It", TERMINATE = "Terminate It",
    EXTRACT_SOULS = "Extract Souls", STORE_SOULS = "Store Souls",
    SHARE_SOULS = "Share Souls", SHARE_LEVEL = "Share Levels",
    STAYSTILL = "Stay Still", FOLLOWME = "Follow Me",
    LIFE_INSURANCE = "Enable Life Care", LIFE_INSURANCE_BAN = "Enable Life Care (Banned)",
    LIFE_IGNORE = "Disable Life Care"
}

S_NAMES.EXPLODINGFRUITCAKE = "Exploding Fruitcake" --爆炸水果蛋糕
S_RECIPE_DESC.EXPLODINGFRUITCAKE = "Sweet bomb-bomb, bite or light!"
S______GENERIC.DESCRIBE.EXPLODINGFRUITCAKE = "A gift full of malice."
S_______WILLOW.DESCRIBE.EXPLODINGFRUITCAKE = "It's a firesnacker!"
-- S_____WOLFGANG.DESCRIBE.EXPLODINGFRUITCAKE = ""
S________WENDY.DESCRIBE.EXPLODINGFRUITCAKE = "I did it, so what..."
S_________WX78.DESCRIBE.EXPLODINGFRUITCAKE = "AFTER ANALYSIS: CAN I MAKE THIS?"
S_WICKERBOTTOM.DESCRIBE.EXPLODINGFRUITCAKE = "How to detonate, light it or bite it?"
-- S_______WOODIE.DESCRIBE.EXPLODINGFRUITCAKE = ""
S______WAXWELL.DESCRIBE.EXPLODINGFRUITCAKE = "The world between us..."
S___WATHGRITHR.DESCRIBE.EXPLODINGFRUITCAKE = "Fighting fair and square is my style!"
S_______WEBBER.DESCRIBE.EXPLODINGFRUITCAKE = "Wow, a cake!"
S_______WINONA.DESCRIBE.EXPLODINGFRUITCAKE = "No tact at all. The leads are so obvious!?"
S_______WORTOX.DESCRIBE.EXPLODINGFRUITCAKE = "I wouldn't do a prank that would kill someone!"
S_____WORMWOOD.DESCRIBE.EXPLODINGFRUITCAKE = "Ooo, Sweets!"
S________WARLY.DESCRIBE.EXPLODINGFRUITCAKE = "A sugarcoated bullet, be careful."
-- S_________WURT.DESCRIBE.EXPLODINGFRUITCAKE = ""
-- S_______WALTER.DESCRIBE.EXPLODINGFRUITCAKE = ""
S________WANDA.DESCRIBE.EXPLODINGFRUITCAKE = "Fortunately, I have time to stop this tragedy."

S_NAMES.CHESTUPGRADER_L = "Primitive Elastispacer" --月石角撑
S_RECIPE_DESC.CHESTUPGRADER_L = "Lift up a piece of space inside a box."
S______GENERIC.DESCRIBE.CHESTUPGRADER_L = "It can expand my toolbox."
-- S_______WILLOW.DESCRIBE.CHESTUPGRADER_L = ""
-- S_____WOLFGANG.DESCRIBE.CHESTUPGRADER_L = ""
S________WENDY.DESCRIBE.CHESTUPGRADER_L = "Make the heart of the box bigger."
-- S_________WX78.DESCRIBE.CHESTUPGRADER_L = ""
S_WICKERBOTTOM.DESCRIBE.CHESTUPGRADER_L = "The combination of three types of magic produces the effect of expanding space."
-- S_______WOODIE.DESCRIBE.CHESTUPGRADER_L = ""
S______WAXWELL.DESCRIBE.CHESTUPGRADER_L = "Use its magic to create more space."
S___WATHGRITHR.DESCRIBE.CHESTUPGRADER_L = "Now there is a place to put my countless treasures."
-- S_______WEBBER.DESCRIBE.CHESTUPGRADER_L = ""
S_______WINONA.DESCRIBE.CHESTUPGRADER_L = "My box can hold more parts now."
S_______WORTOX.DESCRIBE.CHESTUPGRADER_L = "Shh, my secret base needs some spatial improvement."
S_____WORMWOOD.DESCRIBE.CHESTUPGRADER_L = "Bigger!"
S________WARLY.DESCRIBE.CHESTUPGRADER_L = "Who doesn't want their refrigerator to be bigger."
-- S_________WURT.DESCRIBE.CHESTUPGRADER_L = ""
S_______WALTER.DESCRIBE.CHESTUPGRADER_L = "It looks like a trophy, don't you think?"
-- S________WANDA.DESCRIBE.CHESTUPGRADER_L = ""

--------------------------------------------------------------------------
--[[ desert secret ]]--[[ 尘市蜃楼 ]]
--------------------------------------------------------------------------

S_NAMES.SHIELD_L_SAND = "Desert Defense" --砂之抵御
S_RECIPE_DESC.SHIELD_L_SAND = "Use the power of the earth to fight back."
S______GENERIC.DESCRIBE.SHIELD_L_SAND = {
    GENERIC = "I can feel the power of the earth!",
    WEAK = "Maybe I can't use it in the rain?",
    INSANE = "Maybe I'm too insane?"
}
S_______WILLOW.DESCRIBE.SHIELD_L_SAND = "It's just a delicate piece of stone."
S_____WOLFGANG.DESCRIBE.SHIELD_L_SAND = "The stone shield is not heavy at all."
S________WENDY.DESCRIBE.SHIELD_L_SAND = "I can't always escape, I have to face everything."
S_________WX78.DESCRIBE.SHIELD_L_SAND = "FIREWALL, START!"
S_WICKERBOTTOM.DESCRIBE.SHIELD_L_SAND = "Its magic can protect me from lightning and sandstorms."
-- S_______WOODIE.DESCRIBE.SHIELD_L_SAND = ""
S______WAXWELL.DESCRIBE.SHIELD_L_SAND = "The earth power is one of the native magic of this world."
S___WATHGRITHR.DESCRIBE.SHIELD_L_SAND = "Be my mirror, my sword and my shield!"
S_______WEBBER.DESCRIBE.SHIELD_L_SAND = "The shield made of sand is so cool!"
-- S_______WINONA.DESCRIBE.SHIELD_L_SAND = ""
S_______WORTOX.DESCRIBE.SHIELD_L_SAND = "I can feel the magical connection between it and the earth."
S_____WORMWOOD.DESCRIBE.SHIELD_L_SAND = "The earth is helping me."
-- S________WARLY.DESCRIBE.SHIELD_L_SAND = ""
-- S_________WURT.DESCRIBE.SHIELD_L_SAND = ""
-- S_______WALTER.DESCRIBE.SHIELD_L_SAND = ""
-- S________WANDA.DESCRIBE.SHIELD_L_SAND = ""

S_NAMES.SHYERRYTREE = "Treembling" --颤栗树
S_NAMES.SHYERRYTREE_WAXED = "Fuel-Woven Treembling"
S_NAMES.SHYERRYTREE_ITEM_WAXED = "Fuel-Woven Treembling"
S______GENERIC.DESCRIBE.SHYERRYTREE = {
    BURNING = "It's on fire!",
    GENERIC = "Is that a tree with only one or two leaves?"
}
-- S_______WILLOW.DESCRIBE.SHYERRYTREE = ""
-- S_____WOLFGANG.DESCRIBE.SHYERRYTREE = ""
-- S________WENDY.DESCRIBE.SHYERRYTREE = ""
S_________WX78.DESCRIBE.SHYERRYTREE = {
    BURNING = "IT'S BURNING.",
    GENERIC = "LARGE PLANT BODIES WERE DETECTED UNDERGROUND."
}
S_WICKERBOTTOM.DESCRIBE.SHYERRYTREE = {
    BURNING = "Don't worry. The fire won't burn the part underground.",
    GENERIC = "In fact, it's not really the trunk that grows outside."
}
S_______WOODIE.DESCRIBE.SHYERRYTREE = {
    BURNING = "After burning, there are other trees that can be cut down.",
    GENERIC = "Let me chop down such a strange tree."
}
-- S______WAXWELL.DESCRIBE.SHYERRYTREE = ""
-- S___WATHGRITHR.DESCRIBE.SHYERRYTREE = ""
-- S_______WEBBER.DESCRIBE.SHYERRYTREE = ""
-- S_______WINONA.DESCRIBE.SHYERRYTREE = ""
S_______WORTOX.DESCRIBE.SHYERRYTREE = {
    BURNING = "It's okay if the tip burns, the real body is hidden underground.",
    GENERIC = "Growing up in rows, this tree can fix sand."
}
S_____WORMWOOD.DESCRIBE.SHYERRYTREE = {
    BURNING = "Wood friend's foot is on fire!",
    GENERIC = "They are all wood friends' feet."
}
-- S________WARLY.DESCRIBE.SHYERRYTREE = ""
-- S_________WURT.DESCRIBE.SHYERRYTREE = ""
-- S_______WALTER.DESCRIBE.SHYERRYTREE = ""
-- S________WANDA.DESCRIBE.SHYERRYTREE = ""

S_NAMES.SHYERRYCORE_PLANTED = "Abnormal Treembling Heart" --不正常的颤栗树之心
S______GENERIC.DESCRIBE.SHYERRYCORE_PLANTED = {
    BURNING = "Oh my, everything is over.",
    WEAK = "It is too weak and will only expand a small area around it.",
    GROWING = "I need to fertilize and water it more so that it can grow bigger.",
    STRONG = "Why is it different from what I saw in the desert?"
}
-- S_______WILLOW.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S_____WOLFGANG.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S________WENDY.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S_________WX78.DESCRIBE.SHYERRYCORE_PLANTED = ""
S_WICKERBOTTOM.DESCRIBE.SHYERRYCORE_PLANTED = {
    BURNING = "The research sample is on fire!",
    WEAK = "Propagated from the Treembling Heart.",
    GROWING = "I should continue to cultivate it, it can still grow.",
    STRONG = "It seems that the Treembling Heart cannot truly reproduce."
}
-- S_______WOODIE.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S______WAXWELL.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S___WATHGRITHR.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S_______WEBBER.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S_______WINONA.DESCRIBE.SHYERRYCORE_PLANTED = ""
S_______WORTOX.DESCRIBE.SHYERRYCORE_PLANTED = {
    BURNING = "Urgent rescue is needed!",
    WEAK = "Even if you don't succeed, I will still take care of you.",
    GROWING = "This stage requires sufficient fertilizer and water.",
    STRONG = "You look very different from your mother!"
}
S_____WORMWOOD.DESCRIBE.SHYERRYCORE_PLANTED = {
    BURNING = "Fire! Afraid.",
    WEAK = "Ha, wood friend's mini version.",
    GROWING = "Hurry up!",
    STRONG = "Bear fruit!"
}
S________WARLY.DESCRIBE.SHYERRYCORE_PLANTED = {
    BURNING = "The aroma of burnt wood wafted in.",
    WEAK = "Planting in spring, can we harvest in autumn?",
    GROWING = "I can almost smell the aroma of some top-notch ingredient.",
    STRONG = "Bear more delicious ingredient! I'm waiting to use them."
}
-- S_________WURT.DESCRIBE.SHYERRYCORE_PLANTED = ""
-- S_______WALTER.DESCRIBE.SHYERRYCORE_PLANTED = ""
S________WANDA.DESCRIBE.SHYERRYCORE_PLANTED = {
    BURNING = "How bad can it be.",
    WEAK = "Every attempt starts from here.",
    GROWING = "It cannot grow normally in the environment of this world.",
    STRONG = "It grows abnormally and cannot grow into the mother tree."
}

S_NAMES.SHYERRYFLOWER = "Abloom Treembling" --颤栗花
S_NAMES.SHYERRYFLOWER_WAXED = "Fuel-Woven Abloom Treembling"
S_NAMES.SHYERRYFLOWER_ITEM_WAXED = "Fuel-Woven Abloom Treembling"
S______GENERIC.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "A precious flower in burning!",
    GENERIC = "It blooms in such a harsh environment.",
    SHY = "No! It slipped away."
}
-- S_______WILLOW.DESCRIBE.SHYERRYFLOWER = ""
-- S_____WOLFGANG.DESCRIBE.SHYERRYFLOWER = ""
-- S________WENDY.DESCRIBE.SHYERRYFLOWER = ""
S_________WX78.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "IT DIDN'T ANTICIPATE THIS SITUATION.",
    GENERIC = "AN ENERGY STORAGE ORGAN THAT COMBINES A RISK AVOIDANCE MECHANISM.",
    SHY = "NOTE: PAY ATTENTION NEXT TIME."
}
S_WICKERBOTTOM.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "The nutritional organs are on fire!",
    GENERIC = "It is not a real flower, it is an organ that stores nutrients.",
    SHY = "I think there should be a way to get closer to it."
}
-- S_______WOODIE.DESCRIBE.SHYERRYFLOWER = ""
-- S______WAXWELL.DESCRIBE.SHYERRYFLOWER = ""
-- S___WATHGRITHR.DESCRIBE.SHYERRYFLOWER = ""
S_______WEBBER.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "Is this the last one?",
    GENERIC = "Interesting! We want to get closer and take a closer look.",
    SHY = "How did it disappear? We haven't seen it clearly yet."
}
-- S_______WINONA.DESCRIBE.SHYERRYFLOWER = ""
S_______WORTOX.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "Hmph. This prank is really wasteful.",
    GENERIC = "A witch once gave it to me to eat, and the deliciousness was unforgettable.",
    SHY = "Next time, I'll teleport over and grab it with one claw!"
}
S_____WORMWOOD.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "Wood friend's efforts were in vain.",
    GENERIC = "Wood friend's snacks.",
    SHY = "Aren't we friends?"
}
S________WARLY.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "My top-notch fruit is about to be burned out.",
    GENERIC = "A top-notch ingredient is right in front of us, who wouldn't be tempted?",
    SHY = "The cunning plant makes my mouth water."
}
-- S_________WURT.DESCRIBE.SHYERRYFLOWER = ""
-- S_______WALTER.DESCRIBE.SHYERRYFLOWER = ""
S________WANDA.DESCRIBE.SHYERRYFLOWER = {
    BURNING = "Don't worry, new ones will grow.",
    GENERIC = "Nutritious parts have grown out.",
    SHY = "My mistake, I have to dilute my scent first."
}

S_NAMES.SHYERRY = "Shyerry" --颤栗果
S______GENERIC.DESCRIBE.SHYERRY = "Wow, what a big blueberry!"
-- S_______WILLOW.DESCRIBE.SHYERRY = ""
-- S_____WOLFGANG.DESCRIBE.SHYERRY = ""
-- S________WENDY.DESCRIBE.SHYERRY = ""
-- S_________WX78.DESCRIBE.SHYERRY = ""
S_WICKERBOTTOM.DESCRIBE.SHYERRY = "Rich in nutrition, good for your health."
-- S_______WOODIE.DESCRIBE.SHYERRY = ""
-- S______WAXWELL.DESCRIBE.SHYERRY = ""
-- S___WATHGRITHR.DESCRIBE.SHYERRY = ""
S_______WEBBER.DESCRIBE.SHYERRY = "It's too soft, otherwise it could be played as a bowling ball."
-- S_______WINONA.DESCRIBE.SHYERRY = ""
-- S_______WORTOX.DESCRIBE.SHYERRY = ""
S_____WORMWOOD.DESCRIBE.SHYERRY = "A wood friend's snack."
S________WARLY.DESCRIBE.SHYERRY = "Taste even more fruity than fruit, this is definitely a top-notch ingredient!"
-- S_________WURT.DESCRIBE.SHYERRY = ""
-- S_______WALTER.DESCRIBE.SHYERRY = ""
S________WANDA.DESCRIBE.SHYERRY = "I stole the fruit of the mother tree."

S_NAMES.SHYERRY_COOKED = "Roasted Shyerry" --烤颤栗果
S______GENERIC.DESCRIBE.SHYERRY_COOKED = "Wow, it looks like a blue orange!"
S_______WILLOW.DESCRIBE.SHYERRY_COOKED = "Now you are just an ordinary roasted fruit."
-- S_____WOLFGANG.DESCRIBE.SHYERRY_COOKED = ""
-- S________WENDY.DESCRIBE.SHYERRY_COOKED = ""
-- S_________WX78.DESCRIBE.SHYERRY_COOKED = ""
S_WICKERBOTTOM.DESCRIBE.SHYERRY_COOKED = "Well, the nutrients were all decomposed."
-- S_______WOODIE.DESCRIBE.SHYERRY_COOKED = ""
-- S______WAXWELL.DESCRIBE.SHYERRY_COOKED = ""
-- S___WATHGRITHR.DESCRIBE.SHYERRY_COOKED = ""
-- S_______WEBBER.DESCRIBE.SHYERRY_COOKED = ""
-- S_______WINONA.DESCRIBE.SHYERRY_COOKED = ""
-- S_______WORTOX.DESCRIBE.SHYERRY_COOKED = ""
S_____WORMWOOD.DESCRIBE.SHYERRY_COOKED = "About to cry."
S________WARLY.DESCRIBE.SHYERRY_COOKED = "The heat of fire took away all its unique flavors."
-- S_________WURT.DESCRIBE.SHYERRY_COOKED = ""
-- S_______WALTER.DESCRIBE.SHYERRY_COOKED = ""
S________WANDA.DESCRIBE.SHYERRY_COOKED = "The most incorrect approach."

S_NAMES.SHYERRYLOG = "Big Plancon" --宽大的木墩
S______GENERIC.DESCRIBE.SHYERRYLOG = "Suitable for woodworking."
-- S_______WILLOW.DESCRIBE.SHYERRYLOG = ""
-- S_____WOLFGANG.DESCRIBE.SHYERRYLOG = ""
-- S________WENDY.DESCRIBE.SHYERRYLOG = ""
-- S_________WX78.DESCRIBE.SHYERRYLOG = ""
-- S_WICKERBOTTOM.DESCRIBE.SHYERRYLOG = ""
S_______WOODIE.DESCRIBE.SHYERRYLOG = "Very elastic wood."
-- S______WAXWELL.DESCRIBE.SHYERRYLOG = ""
-- S___WATHGRITHR.DESCRIBE.SHYERRYLOG = ""
-- S_______WEBBER.DESCRIBE.SHYERRYLOG = ""
S_______WINONA.DESCRIBE.SHYERRYLOG = "Carpets, plant pots, stakes, carvings, too many uses."
-- S_______WORTOX.DESCRIBE.SHYERRYLOG = ""
-- S_____WORMWOOD.DESCRIBE.SHYERRYLOG = ""
-- S________WARLY.DESCRIBE.SHYERRYLOG = ""
-- S_________WURT.DESCRIBE.SHYERRYLOG = ""
-- S_______WALTER.DESCRIBE.SHYERRYLOG = ""
-- S________WANDA.DESCRIBE.SHYERRYLOG = ""

S_NAMES.SHYERRYCORE = "Treembling Heart" --颤栗树之心
S_NAMES.SHYERRYCORE_WAXED = "Fuel-Woven Treembling Heart"
S_NAMES.SHYERRYCORE_ITEM_WAXED = "Fuel-Woven Treembling Heart"
S______GENERIC.DESCRIBE.SHYERRYCORE = {
    BURNING = "This will be a big fire.",
    WEAK = "It is the mother tree, the source of Treemblings.",
    GROWING = "The mother tree needs more watering and fertilization to grow stronger.",
    STRONG = "Now you really have the appearance of a mother tree."
}
S_______WILLOW.DESCRIBE.SHYERRYCORE = {
    BURNING = "I can save you!",
    WEAK = "Hah, you are the shortest tree in this strange forest.",
    GROWING = "Before I burn you, you'd better grow up quickly.",
    STRONG = "Your fruits will repay my kindness of not burning."
}
-- S_____WOLFGANG.DESCRIBE.SHYERRYCORE = ""
-- S________WENDY.DESCRIBE.SHYERRYCORE = ""
S_________WX78.DESCRIBE.SHYERRYCORE = {
    BURNING = "I DON'T MIND.",
    WEAK = "THE ABOVEGROUND PART IS JUST THE TIP OF THE ICEBERG.",
    GROWING = "DID YOU CAUSE THE DESERTIFICATION HERE?",
    STRONG = "THE UNDERGROUND ROOT SYSTEM IS LARGER THAN THE ABOVEGROUND TRUNK PARTS."
}
S_WICKERBOTTOM.DESCRIBE.SHYERRYCORE = {
    BURNING = "Hurry up and put out the fire!",
    WEAK = "The aboveground part is too small and underdeveloped.",
    GROWING = "It requires more abundant nutrients and water.",
    STRONG = "Its roots spread all around, and this forest is actually the same tree."
}
-- S_______WOODIE.DESCRIBE.SHYERRYCORE = ""
-- S______WAXWELL.DESCRIBE.SHYERRYCORE = ""
-- S___WATHGRITHR.DESCRIBE.SHYERRYCORE = ""
S_______WEBBER.DESCRIBE.SHYERRYCORE = {
    BURNING = "No!",
    WEAK = "Even small ones are very cute.",
    GROWING = "What a chubby tree, can it be even fatter.",
    STRONG = "We really want to climb up and overlook the entire desert."
}
-- S_______WINONA.DESCRIBE.SHYERRYCORE = ""
-- S_______WORTOX.DESCRIBE.SHYERRYCORE = ""
S_____WORMWOOD.DESCRIBE.SHYERRYCORE = {
    BURNING = "The fire hurts my friend!",
    WEAK = "Wood friend, chubby little one.",
    GROWING = "Wood friend needs poop to grow taller.",
    STRONG = "Wood friend said I can take its snacks at will."
}
-- S________WARLY.DESCRIBE.SHYERRYCORE = ""
-- S_________WURT.DESCRIBE.SHYERRYCORE = ""
-- S_______WALTER.DESCRIBE.SHYERRYCORE = ""
S________WANDA.DESCRIBE.SHYERRYCORE = {
    BURNING = "The flames cannot burn it all.",
    WEAK = "Pitiful, growing up in such a barren desert.",
    GROWING = "I can get what it needs, and it can help me in the future.",
    STRONG = "It is so strong now that I don't need to worry about it anymore."
}

S_NAMES.SHYERRYCORE_ITEM = "Treembling Seedball" --颤栗树心芽
S______GENERIC.DESCRIBE.SHYERRYCORE_ITEM = "The seedball of the Treembling Heart."
-- S_______WILLOW.DESCRIBE.SHYERRYCORE_ITEM = ""
S_____WOLFGANG.DESCRIBE.SHYERRYCORE_ITEM = "It has powerful energy!"
-- S________WENDY.DESCRIBE.SHYERRYCORE_ITEM = ""
S_________WX78.DESCRIBE.SHYERRYCORE_ITEM = "THE IMPULSE TO REPRODUCE IS LOCKED IN THE DNA OF ORGANISMS."
S_WICKERBOTTOM.DESCRIBE.SHYERRYCORE_ITEM = "Find a suitable place to plant it, I want to research it."
-- S_______WOODIE.DESCRIBE.SHYERRYCORE_ITEM = ""
-- S______WAXWELL.DESCRIBE.SHYERRYCORE_ITEM = ""
S___WATHGRITHR.DESCRIBE.SHYERRYCORE_ITEM = "The child of the giant tree monster."
S_______WEBBER.DESCRIBE.SHYERRYCORE_ITEM = "A chubby seed of the chubby tree."
-- S_______WINONA.DESCRIBE.SHYERRYCORE_ITEM = ""
S_______WORTOX.DESCRIBE.SHYERRYCORE_ITEM = "I have high expectations for it."
S_____WORMWOOD.DESCRIBE.SHYERRYCORE_ITEM = "Wood friend's child!"
S________WARLY.DESCRIBE.SHYERRYCORE_ITEM = "As long as I plant it, top-notch ingredients will no longer be rare."
-- S_________WURT.DESCRIBE.SHYERRYCORE_ITEM = ""
-- S_______WALTER.DESCRIBE.SHYERRYCORE_ITEM = ""
S________WANDA.DESCRIBE.SHYERRYCORE_ITEM = "The mother tree gave birth to another deformed seed."

-- S_NAMES.FENCE_SHYERRY = "Pastoral Fence" --田园栅栏
-- S______GENERIC.DESCRIBE.FENCE_SHYERRY = "Disappointing, it's no different from ordinary fences."

-- S_NAMES.FENCE_SHYERRY_ITEM = "Pastoral Fence" --田园栅栏 item
-- S_RECIPE_DESC.FENCE_SHYERRY_ITEM = "Surround your farmland."
-- S______GENERIC.DESCRIBE.FENCE_SHYERRY_ITEM = "Will the place surrounded by it become farmland?"

S_NAMES.GUITAR_WHITEWOOD = "White Wood Guitar" --白木吉他
S_RECIPE_DESC.GUITAR_WHITEWOOD = "A guitar, waiting to be played."
S______GENERIC.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "I really just want to play to you.",
    FAILED = "Oops, slow down a beat.",
    HUNGRY = "Too tired to play.",
}
-- S_______WILLOW.DESCRIBE.GUITAR_WHITEWOOD = ""
-- S_____WOLFGANG.DESCRIBE.GUITAR_WHITEWOOD = ""
S________WENDY.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "Abigail tried, but she didn't have that talent, hah.",
    FAILED = "It's about the consistency of the beat.",
    HUNGRY = "Hunger affects my melody.",
}
S_________WX78.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "THOSE PRIMITIVE CREATURES LOVE IT.",
    FAILED = "WHY AM I THE ONE TO COOPERATE WITH.",
    HUNGRY = "LOW POWER, LIMITED FUNCTION.",
}
S_WICKERBOTTOM.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "Only four strings? Not enough to play it alone.",
    FAILED = "My cooperation is not perfect.",
    HUNGRY = "Not in the mood for this.",
}
-- S_______WOODIE.DESCRIBE.GUITAR_WHITEWOOD = ""
S______WAXWELL.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "The violin is more elegant.",
    FAILED = "Well, I'm an assistant now?",
    HUNGRY = "Now, time for me to eat, the others can play.",
}
-- S___WATHGRITHR.DESCRIBE.GUITAR_WHITEWOOD = ""
-- S_______WEBBER.DESCRIBE.GUITAR_WHITEWOOD = ""
S_______WINONA.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "It's missing the scale.",
    FAILED = "Sorry I didn't catch up, try again?",
    HUNGRY = "How can you work if you are hungry!",
}
S_______WORTOX.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "Hee hee, that's why humans interest me so much.",
    FAILED = "Hah, this is so funny.",
    HUNGRY = "Hey! that's not what's pressing.",
}
-- S_____WORMWOOD.DESCRIBE.GUITAR_WHITEWOOD = ""
-- S________WARLY.DESCRIBE.GUITAR_WHITEWOOD = ""
-- S_________WURT.DESCRIBE.GUITAR_WHITEWOOD = ""
S_______WALTER.DESCRIBE.GUITAR_WHITEWOOD =
{
    GENERIC = "You'll be surprised. I could play it when I was three.",
    FAILED = "Don't give up. I'll get it right next time.",
    HUNGRY = "And that's the dinner bell.",
}

-- S_NAMES.TOY_SPONGEBOB = "Spongebob Toy"    --玩具小海绵
-- S______GENERIC.DESCRIBE.TOY_SPONGEBOB = "Who is it waiting for?"
-- S_______WILLOW.DESCRIBE.TOY_SPONGEBOB = ""
-- S_____WOLFGANG.DESCRIBE.TOY_SPONGEBOB = ""
-- S________WENDY.DESCRIBE.TOY_SPONGEBOB = "The flower falls, the spring goes."
-- S_________WX78.DESCRIBE.TOY_SPONGEBOB = ""
-- S_WICKERBOTTOM.DESCRIBE.TOY_SPONGEBOB = "It says that there is no place to vent one's enthusiasm."
-- S_______WOODIE.DESCRIBE.TOY_SPONGEBOB = "It also looks forward to the future, that embracing day."
-- S______WAXWELL.DESCRIBE.TOY_SPONGEBOB = "Life is so long, used to be with loneliness."
-- S___WATHGRITHR.DESCRIBE.TOY_SPONGEBOB = "I'm not looking for somebody with some superhuman gifts."
-- S_______WEBBER.DESCRIBE.TOY_SPONGEBOB = "Love it."
-- S_______WINONA.DESCRIBE.TOY_SPONGEBOB = ""
-- S_______WORTOX.DESCRIBE.TOY_SPONGEBOB = ""
-- S_____WORMWOOD.DESCRIBE.TOY_SPONGEBOB = ""
-- S________WARLY.DESCRIBE.TOY_SPONGEBOB = "Just something I can turn to, somebody I can kiss."
-- S_________WURT.DESCRIBE.TOY_SPONGEBOB = ""
-- S_______WALTER.DESCRIBE.TOY_SPONGEBOB = ""

-- S_NAMES.TOY_PATRICKSTAR = "Patrickstar Toy"    --玩具小海星
-- S______GENERIC.DESCRIBE.TOY_PATRICKSTAR = "Moving towards its goal."
-- S_______WILLOW.DESCRIBE.TOY_PATRICKSTAR = ""
-- S_____WOLFGANG.DESCRIBE.TOY_PATRICKSTAR = ""
-- S________WENDY.DESCRIBE.TOY_PATRICKSTAR = "Someone I miss is far away."
-- S_________WX78.DESCRIBE.TOY_PATRICKSTAR = ""
-- S_WICKERBOTTOM.DESCRIBE.TOY_PATRICKSTAR = "It says that time always fades everything."
-- S_______WOODIE.DESCRIBE.TOY_PATRICKSTAR = "It is also full of contradictions, sometimes at a loss."
-- S______WAXWELL.DESCRIBE.TOY_PATRICKSTAR = "Life is so short, hard and ordinary."
-- S___WATHGRITHR.DESCRIBE.TOY_PATRICKSTAR = ""
-- S_______WEBBER.DESCRIBE.TOY_PATRICKSTAR = "Adore it."
-- S_______WINONA.DESCRIBE.TOY_PATRICKSTAR = ""
-- S_______WORTOX.DESCRIBE.TOY_PATRICKSTAR = ""
-- S_____WORMWOOD.DESCRIBE.TOY_PATRICKSTAR = ""
-- S________WARLY.DESCRIBE.TOY_PATRICKSTAR = ""
-- S_________WURT.DESCRIBE.TOY_PATRICKSTAR = ""
-- S_______WALTER.DESCRIBE.TOY_PATRICKSTAR = ""

S_NAMES.PINKSTAFF = "Illusion Staff"    --幻象法杖
S_RECIPE_DESC.PINKSTAFF = "Illusion can provide eternal beauty."
S______GENERIC.DESCRIBE.PINKSTAFF = "Is this real? It might be an illusion."
-- S_______WILLOW.DESCRIBE.PINKSTAFF = ""
-- S_____WOLFGANG.DESCRIBE.PINKSTAFF = ""
-- S________WENDY.DESCRIBE.PINKSTAFF = ""
-- S_________WX78.DESCRIBE.PINKSTAFF = ""
-- S_WICKERBOTTOM.DESCRIBE.PINKSTAFF = ""
-- S_______WOODIE.DESCRIBE.PINKSTAFF = ""
-- S______WAXWELL.DESCRIBE.PINKSTAFF = ""
-- S___WATHGRITHR.DESCRIBE.PINKSTAFF = ""
-- S_______WEBBER.DESCRIBE.PINKSTAFF = ""
-- S_______WINONA.DESCRIBE.PINKSTAFF = ""
-- S_______WORTOX.DESCRIBE.PINKSTAFF = ""
-- S_____WORMWOOD.DESCRIBE.PINKSTAFF = ""
-- S________WARLY.DESCRIBE.PINKSTAFF = ""
-- S_________WURT.DESCRIBE.PINKSTAFF = ""
-- S_______WALTER.DESCRIBE.PINKSTAFF = ""

S_NAMES.THEEMPERORSCROWN = "The Emperor's Crown"  --皇帝的王冠
S_RECIPE_DESC.THEEMPERORSCROWN = "The symbol of sagacity."
S______GENERIC.DESCRIBE.THEEMPERORSCROWN = "A wise man won't believe this symbol."
-- S_______WILLOW.DESCRIBE.THEEMPERORSCROWN = ""
-- S_____WOLFGANG.DESCRIBE.THEEMPERORSCROWN = ""
-- S________WENDY.DESCRIBE.THEEMPERORSCROWN = ""
-- S_________WX78.DESCRIBE.THEEMPERORSCROWN = ""
-- S_WICKERBOTTOM.DESCRIBE.THEEMPERORSCROWN = ""
-- S_______WOODIE.DESCRIBE.THEEMPERORSCROWN = ""
-- S______WAXWELL.DESCRIBE.THEEMPERORSCROWN = ""
-- S___WATHGRITHR.DESCRIBE.THEEMPERORSCROWN = ""
-- S_______WEBBER.DESCRIBE.THEEMPERORSCROWN = ""
-- S_______WINONA.DESCRIBE.THEEMPERORSCROWN = ""
-- S_______WORTOX.DESCRIBE.THEEMPERORSCROWN = ""
-- S_____WORMWOOD.DESCRIBE.THEEMPERORSCROWN = ""
-- S________WARLY.DESCRIBE.THEEMPERORSCROWN = ""
-- S_________WURT.DESCRIBE.THEEMPERORSCROWN = ""
-- S_______WALTER.DESCRIBE.THEEMPERORSCROWN = ""

S_NAMES.THEEMPERORSMANTLE = "The Emperor's Mantle"    --皇帝的披风
S_RECIPE_DESC.THEEMPERORSMANTLE = "The symbol of gallantry."
S______GENERIC.DESCRIBE.THEEMPERORSMANTLE = "A fearless man won't believe this symbol."
-- S_______WILLOW.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_____WOLFGANG.DESCRIBE.THEEMPERORSMANTLE = ""
-- S________WENDY.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_________WX78.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_WICKERBOTTOM.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_______WOODIE.DESCRIBE.THEEMPERORSMANTLE = ""
-- S______WAXWELL.DESCRIBE.THEEMPERORSMANTLE = ""
-- S___WATHGRITHR.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_______WEBBER.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_______WINONA.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_______WORTOX.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_____WORMWOOD.DESCRIBE.THEEMPERORSMANTLE = ""
-- S________WARLY.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_________WURT.DESCRIBE.THEEMPERORSMANTLE = ""
-- S_______WALTER.DESCRIBE.THEEMPERORSMANTLE = ""

S_NAMES.THEEMPERORSSCEPTER = "The Emperor's Scepter"  --皇帝的权杖
S_RECIPE_DESC.THEEMPERORSSCEPTER = "The symbol of a dignitary."
S______GENERIC.DESCRIBE.THEEMPERORSSCEPTER = "A guileless man won't believe this symbol."
-- S_______WILLOW.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_____WOLFGANG.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S________WENDY.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_________WX78.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_WICKERBOTTOM.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_______WOODIE.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S______WAXWELL.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S___WATHGRITHR.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_______WEBBER.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_______WINONA.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_______WORTOX.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_____WORMWOOD.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S________WARLY.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_________WURT.DESCRIBE.THEEMPERORSSCEPTER = ""
-- S_______WALTER.DESCRIBE.THEEMPERORSSCEPTER = ""

S_NAMES.THEEMPERORSPENDANT = "The Emperor's Pendant" --皇帝的吊坠
S_RECIPE_DESC.THEEMPERORSPENDANT = "The symbol of will."
S______GENERIC.DESCRIBE.THEEMPERORSPENDANT = "A determined man won't believe this symbol."
-- S_______WILLOW.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_____WOLFGANG.DESCRIBE.THEEMPERORSPENDANT = ""
-- S________WENDY.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_________WX78.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_WICKERBOTTOM.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_______WOODIE.DESCRIBE.THEEMPERORSPENDANT = ""
-- S______WAXWELL.DESCRIBE.THEEMPERORSPENDANT = ""
-- S___WATHGRITHR.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_______WEBBER.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_______WINONA.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_______WORTOX.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_____WORMWOOD.DESCRIBE.THEEMPERORSPENDANT = ""
-- S________WARLY.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_________WURT.DESCRIBE.THEEMPERORSPENDANT = ""
-- S_______WALTER.DESCRIBE.THEEMPERORSPENDANT = ""

S_NAMES.MAT_WHITEWOOD_ITEM = "White Wood Chip" --白木地片
S_RECIPE_DESC.MAT_WHITEWOOD_ITEM = "Gives your feet a nice woody feel."
S______GENERIC.DESCRIBE.MAT_WHITEWOOD_ITEM = "White wood chips for decorating the ground."
-- S_______WILLOW.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_____WOLFGANG.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S________WENDY.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_________WX78.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_WICKERBOTTOM.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_______WOODIE.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
S______WAXWELL.DESCRIBE.MAT_WHITEWOOD_ITEM = "A layer of cushion makes me feel more down-to-earth."
-- S___WATHGRITHR.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_______WEBBER.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_______WINONA.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_______WORTOX.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_____WORMWOOD.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S________WARLY.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_________WURT.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S_______WALTER.DESCRIBE.MAT_WHITEWOOD_ITEM = ""
-- S________WANDA.DESCRIBE.MAT_WHITEWOOD_ITEM = ""

S_NAMES.CARPET_WHITEWOOD = "White Wood Mat" --白木地垫
S_RECIPE_DESC.CARPET_WHITEWOOD = "A simple wooden mat."

S_NAMES.CARPET_WHITEWOOD_BIG = "White Wood Carpet" --白木地毯
S_RECIPE_DESC.CARPET_WHITEWOOD_BIG = "A large wooden carpet."

S_NAMES.CARPET_PLUSH = "Plush Mat" --线绒地垫
S_RECIPE_DESC.CARPET_PLUSH = "A simple fluffy mat."

S_NAMES.CARPET_PLUSH_BIG = "Plush Carpet" --线绒地毯
S_RECIPE_DESC.CARPET_PLUSH_BIG = "A large fluffy carpet."

S_NAMES.CARPET_SIVING = "Hard Rock Mat" --棱石地垫
S_RECIPE_DESC.CARPET_SIVING = "A rocky mat."

S_NAMES.CARPET_SIVING_BIG = "Hard Rock Carpet" --棱石地毯
S_RECIPE_DESC.CARPET_SIVING_BIG = "A large rocky carpet."

S_NAMES.CHEST_WHITEWOOD = "White Wood Cabinet" --白木展示台
S_RECIPE_DESC.CHEST_WHITEWOOD = "A container that can display its belongings."
S______GENERIC.DESCRIBE.CHEST_WHITEWOOD = {
    GENERIC = "A simple and elegant white cabinet.",
    BURNT = "Unfortunately."
}
S_______WILLOW.DESCRIBE.CHEST_WHITEWOOD = {
    GENERIC = "The more beautiful wooden products burn, the more I am pleased.",
    BURNT = "A perfect charcoal product."
}
-- S_____WOLFGANG.DESCRIBE.CHEST_WHITEWOOD = ""
-- S________WENDY.DESCRIBE.CHEST_WHITEWOOD = ""
-- S_________WX78.DESCRIBE.CHEST_WHITEWOOD = ""
-- S_WICKERBOTTOM.DESCRIBE.CHEST_WHITEWOOD = ""
S_______WOODIE.DESCRIBE.CHEST_WHITEWOOD = {
    GENERIC = "This work is very easy for Lucy and me.",
    BURNT = "A tragic fate."
}
-- S______WAXWELL.DESCRIBE.CHEST_WHITEWOOD = ""
-- S___WATHGRITHR.DESCRIBE.CHEST_WHITEWOOD = ""
-- S_______WEBBER.DESCRIBE.CHEST_WHITEWOOD = ""
-- S_______WINONA.DESCRIBE.CHEST_WHITEWOOD = ""
S_______WORTOX.DESCRIBE.CHEST_WHITEWOOD = {
    GENERIC = "Aren't you afraid of being stolen for a box that's too flashy?",
    BURNT = "The box is destroyed, and the contents inside are also gone."
}
S_____WORMWOOD.DESCRIBE.CHEST_WHITEWOOD = {
    GENERIC = "A beautiful friend product.",
    BURNT = "Cannot accept!"
}
S________WARLY.DESCRIBE.CHEST_WHITEWOOD = {
    GENERIC = "Sometimes it is also used to display exquisite cuisine.",
    BURNT = "Flame can bring delicious food, but it can also take everything away."
}
-- S_________WURT.DESCRIBE.CHEST_WHITEWOOD = ""
-- S_______WALTER.DESCRIBE.CHEST_WHITEWOOD = ""
-- S________WANDA.DESCRIBE.CHEST_WHITEWOOD = ""

S_NAMES.CHEST_WHITEWOOD_INF = "Infinite White Wood Cabinet" --白木展示台·无限
S______GENERIC.DESCRIBE.CHEST_WHITEWOOD_INF = "Powerful in function and elegant in appearance."
-- S_______WILLOW.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S_____WOLFGANG.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S________WENDY.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S_________WX78.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S_WICKERBOTTOM.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S_______WOODIE.DESCRIBE.CHEST_WHITEWOOD_INF = ""
S______WAXWELL.DESCRIBE.CHEST_WHITEWOOD_INF = "The magic of moonlight has affected it."
-- S___WATHGRITHR.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S_______WEBBER.DESCRIBE.CHEST_WHITEWOOD_INF = ""
S_______WINONA.DESCRIBE.CHEST_WHITEWOOD_INF = "Adding quantity also adds price."
S_______WORTOX.DESCRIBE.CHEST_WHITEWOOD_INF = "Wow, what an exquisite unlimited capacity cabinet!"
-- S_____WORMWOOD.DESCRIBE.CHEST_WHITEWOOD_INF = ""
S________WARLY.DESCRIBE.CHEST_WHITEWOOD_INF = "Legendary Infinite Kitchenware Box, Got it!"
-- S_________WURT.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S_______WALTER.DESCRIBE.CHEST_WHITEWOOD_INF = ""
-- S________WANDA.DESCRIBE.CHEST_WHITEWOOD_INF = ""

S_NAMES.CHEST_WHITEWOOD_BIG = "White Wood Showcase" --白木展示柜
S_RECIPE_DESC.CHEST_WHITEWOOD_BIG = "A large container that can display its belongings."
S______GENERIC.DESCRIBE.CHEST_WHITEWOOD_BIG = {
    GENERIC = "A simple and elegant white showcase.",
    BURNT = "What a pity."
}
S_______WILLOW.DESCRIBE.CHEST_WHITEWOOD_BIG = {
    GENERIC = "The more beautiful wooden products burn, the more they make me happy.",
    BURNT = "A perfect charcoal product."
}
-- S_____WOLFGANG.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S________WENDY.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S_________WX78.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S_WICKERBOTTOM.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
S_______WOODIE.DESCRIBE.CHEST_WHITEWOOD_BIG = {
    GENERIC = "Just spend a little more time, this is very easy for Lucy and me.",
    BURNT = "A tragic fate."
}
-- S______WAXWELL.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S___WATHGRITHR.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S_______WEBBER.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S_______WINONA.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
S_______WORTOX.DESCRIBE.CHEST_WHITEWOOD_BIG = {
    GENERIC = "Aren't you afraid of being targeted by bad guys for such a flamboyant showcase?",
    BURNT = "I will feel sorry for it for a second."
}
S_____WORMWOOD.DESCRIBE.CHEST_WHITEWOOD_BIG = {
    GENERIC = "A huge and beautiful friend product.",
    BURNT = "Noooo! Cannot accept!"
}
S________WARLY.DESCRIBE.CHEST_WHITEWOOD_BIG = {
    GENERIC = "Put the dishes I cooked inside, and it will look like a restaurant.",
    BURNT = "The flame brought delicious food and also took away my little dream."
}
-- S_________WURT.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S_______WALTER.DESCRIBE.CHEST_WHITEWOOD_BIG = ""
-- S________WANDA.DESCRIBE.CHEST_WHITEWOOD_BIG = ""

S_NAMES.CHEST_WHITEWOOD_BIG_INF = "Infinite White Wood Showcase" --白木展示柜·无限
S______GENERIC.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = "More powerful in function and elegant in appearance."
-- S_______WILLOW.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S_____WOLFGANG.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S________WENDY.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S_________WX78.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S_WICKERBOTTOM.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S_______WOODIE.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
S______WAXWELL.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = "Moonlight magic has improved it."
-- S___WATHGRITHR.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S_______WEBBER.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
S_______WINONA.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = "Adding quantity also adds price."
S_______WORTOX.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = "Wow, what an exquisite unlimited capacity showcase!"
-- S_____WORMWOOD.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
S________WARLY.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = "Legendary Infinite Kitchenware Box, Got it!"
-- S_________WURT.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S_______WALTER.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""
-- S________WANDA.DESCRIBE.CHEST_WHITEWOOD_BIG_INF = ""

S_NAMES.OINTMENT_L_FIREPROOF = "Fireproof Liquid" --防火漆
S_RECIPE_DESC.OINTMENT_L_FIREPROOF = "A liquid that can prevent fire after application."
S______GENERIC.DESCRIBE.OINTMENT_L_FIREPROOF = "I will apply some on important things."
S_______WILLOW.DESCRIBE.OINTMENT_L_FIREPROOF = "Fire is interesting, I don't understand this thing."
-- S_____WOLFGANG.DESCRIBE.OINTMENT_L_FIREPROOF = ""
S________WENDY.DESCRIBE.OINTMENT_L_FIREPROOF = "This is rejecting the invitation of flames."
S_________WX78.DESCRIBE.OINTMENT_L_FIREPROOF = "TEMPORARY FIREPROOF COATING."
-- S_WICKERBOTTOM.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S_______WOODIE.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S______WAXWELL.DESCRIBE.OINTMENT_L_FIREPROOF = ""
S___WATHGRITHR.DESCRIBE.OINTMENT_L_FIREPROOF = "A bowl of water blessed by Loki."
-- S_______WEBBER.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S_______WINONA.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S_______WORTOX.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S_____WORMWOOD.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S________WARLY.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S_________WURT.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S_______WALTER.DESCRIBE.OINTMENT_L_FIREPROOF = ""
-- S________WANDA.DESCRIBE.OINTMENT_L_FIREPROOF = ""

S_NAMES.BUFF_L_FIREPROOF = "Fire Resistant Skin"
S______GENERIC.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = "Afterwards, the flames couldn't harm me."
S_______WILLOW.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = "Flames never hurt me at all."
-- S_____WOLFGANG.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
-- S________WENDY.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
S_________WX78.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = "THE FIREPROOF COATING HAS BEEN INSTALLED."
-- S_WICKERBOTTOM.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
-- S_______WOODIE.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
-- S______WAXWELL.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
S___WATHGRITHR.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = "Loki, please protect me..."
-- S_______WEBBER.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
-- S_______WINONA.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
S_______WORTOX.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = "Fire is extremely good and bad for people."
-- S_____WORMWOOD.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF = ""
-- S________WARLY.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF =
-- S_________WURT.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF =
-- S_______WALTER.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF =
-- S________WANDA.ANNOUNCE_ATTACH_BUFF_L_FIREPROOF =
--
S______GENERIC.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = "From now on, I have to stay away from the fire."
S_______WILLOW.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = "Ha, let me burn again!"
-- S_____WOLFGANG.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = ""
-- S________WENDY.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = ""
S_________WX78.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = "THE FIREPROOF COATING HAS FAILED."
-- S_WICKERBOTTOM.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = ""
-- S_______WOODIE.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = ""
-- S______WAXWELL.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = ""
S___WATHGRITHR.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = "The protection of the Fire God has dissipated."
-- S_______WEBBER.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = ""
-- S_______WINONA.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = ""
S_______WORTOX.ANNOUNCE_DETACH_BUFF_L_FIREPROOF = "Be careful of candles when things are dry."
-- S_____WORMWOOD.ANNOUNCE_DETACH_BUFF_L_FIREPROOF =
-- S________WARLY.ANNOUNCE_DETACH_BUFF_L_FIREPROOF =
-- S_________WURT.ANNOUNCE_DETACH_BUFF_L_FIREPROOF =
-- S_______WALTER.ANNOUNCE_DETACH_BUFF_L_FIREPROOF =
-- S________WANDA.ANNOUNCE_DETACH_BUFF_L_FIREPROOF =

S_NAMES.ACC_L_SHADOWMIRROR = "Mirror of Shadow Capture" --捉影之镜
S______GENERIC.DESCRIBE.ACC_L_SHADOWMIRROR = "A magical mirror that can weave shadows into entities."
-- S_______WILLOW.DESCRIBE.ACC_L_SHADOWMIRROR = ""
-- S_____WOLFGANG.DESCRIBE.ACC_L_SHADOWMIRROR = ""
S________WENDY.DESCRIBE.ACC_L_SHADOWMIRROR = "It reflects a false eternity, while the real is fleeting."
-- S_________WX78.DESCRIBE.ACC_L_SHADOWMIRROR = ""
-- S_WICKERBOTTOM.DESCRIBE.ACC_L_SHADOWMIRROR = ""
-- S_______WOODIE.DESCRIBE.ACC_L_SHADOWMIRROR = ""
S______WAXWELL.DESCRIBE.ACC_L_SHADOWMIRROR = "This mirror has a low-level shadow copying function."
-- S___WATHGRITHR.DESCRIBE.ACC_L_SHADOWMIRROR = ""
-- S_______WEBBER.DESCRIBE.ACC_L_SHADOWMIRROR = ""
-- S_______WINONA.DESCRIBE.ACC_L_SHADOWMIRROR = ""
S_______WORTOX.DESCRIBE.ACC_L_SHADOWMIRROR = "The trick of a raccoon changing the crown prince!"
S_____WORMWOOD.DESCRIBE.ACC_L_SHADOWMIRROR = "Make fake friends."
-- S________WARLY.DESCRIBE.ACC_L_SHADOWMIRROR = ""
-- S_________WURT.DESCRIBE.ACC_L_SHADOWMIRROR = ""
-- S_______WALTER.DESCRIBE.ACC_L_SHADOWMIRROR = ""
S________WANDA.DESCRIBE.ACC_L_SHADOWMIRROR = "If only I could bring something over from another timeline, that would be great."

--非植物类的影织道具的检查台词
S______GENERIC.DESCRIBE.WAXED_ITEM_L = "A replica made of shadows."
S_______WILLOW.DESCRIBE.WAXED_ITEM_L = "A deceitful thing."
-- S_____WOLFGANG.DESCRIBE.WAXED_ITEM_L = ""
S________WENDY.DESCRIBE.WAXED_ITEM_L = "This phantom has been seen through by me."
S_________WX78.DESCRIBE.WAXED_ITEM_L = "HOLOGRAPHIC PROJECTION TECHNOLOGY?"
S_WICKERBOTTOM.DESCRIBE.WAXED_ITEM_L = "If I had this technology, I could hold a museum of all things."
-- S_______WOODIE.DESCRIBE.WAXED_ITEM_L = ""
S______WAXWELL.DESCRIBE.WAXED_ITEM_L = "It's just a useless shadow."
-- S___WATHGRITHR.DESCRIBE.WAXED_ITEM_L = ""
-- S_______WEBBER.DESCRIBE.WAXED_ITEM_L = ""
S_______WINONA.DESCRIBE.WAXED_ITEM_L = "This is a photo made with a magic camera, probably?"
S_______WORTOX.DESCRIBE.WAXED_ITEM_L = "It has mixed a false side with reality."
S_____WORMWOOD.DESCRIBE.WAXED_ITEM_L = "Shadow, fake."
S________WARLY.DESCRIBE.WAXED_ITEM_L = "It can only show off its appearance and has no practical use."
-- S_________WURT.DESCRIBE.WAXED_ITEM_L = ""
-- S_______WALTER.DESCRIBE.WAXED_ITEM_L = ""
-- S________WANDA.DESCRIBE.WAXED_ITEM_L = ""

S_NAMES.POT_WHITEWOOD = "Nutritional Pot" --稀有基质培植盆
S_NAMES.POT_WHITEWOOD_WAXED = "Fuel-Woven Nutritional Pot"
S_NAMES.POT_WHITEWOOD_ITEM_WAXED = "Fuel-Woven Nutritional Pot"
S_RECIPE_DESC.POT_WHITEWOOD = "Let those picky plants and fungi take root here."
S______GENERIC.DESCRIBE.POT_WHITEWOOD = {
    GENERIC = "I should plant some uncommon plants or fungi inside.",
    BARREN = "It doesn't require ordinary fertilizers.",
    ALITTLE = "You're still very young, you need to grow up.",
    SOME = "Growing very well, but there is still room for growth!",
    LOTS = "The pot is filled with plants!",
    WRONGITEM = "This doesn't work.",
    NONEED = "No need, it's perfect."
}
-- S_______WILLOW.DESCRIBE.POT_WHITEWOOD = ""
-- S_____WOLFGANG.DESCRIBE.POT_WHITEWOOD = ""
S________WENDY.DESCRIBE.POT_WHITEWOOD = {
    GENERIC = "This pot of soil will soon become a cage for plants.",
    BARREN = "The cage of plants require special care.",
    ALITTLE = "Poor thing, imprisoned in this pot.",
    SOME = "Even if you grow up, you can't escape.",
    LOTS = "It is both beautiful and fragile, like a canary in a cage.",
    WRONGITEM = "It's not what I thought",
    NONEED = "It's perfect now, don't add too much."
}
-- S_________WX78.DESCRIBE.POT_WHITEWOOD = ""
S_WICKERBOTTOM.DESCRIBE.POT_WHITEWOOD = {
    GENERIC = "The soil matrix is very suitable for some cave plants or fungi.",
    BARREN = "Barren soil requires high-quality fertilizer!",
    ALITTLE = "Just transplanted, let it grow.",
    SOME = "The growth is going very smoothly, and it is about to mature.",
    LOTS = "Look at it! It's really lush.",
    WRONGITEM = "Useless.",
    NONEED = "No need, it's better to maintain the status quo."
}
-- S_______WOODIE.DESCRIBE.POT_WHITEWOOD = ""
-- S______WAXWELL.DESCRIBE.POT_WHITEWOOD = ""
-- S___WATHGRITHR.DESCRIBE.POT_WHITEWOOD = ""
S_______WEBBER.DESCRIBE.POT_WHITEWOOD = {
    GENERIC = "This is very similar to the flower pots on my balcony before.",
    BARREN = "I have to prepare special fertilizer for it like my mom did.",
    ALITTLE = "My mom used to enjoy tinkering with these things.",
    SOME = "It's becoming more and more similar to what I remember.",
    LOTS = "My mom can also raise such lush potted plants.",
    WRONGITEM = "It's not something that a flowerpot needs.",
    NONEED = "It's no longer needed now."
}
-- S_______WINONA.DESCRIBE.POT_WHITEWOOD = ""
S_______WORTOX.DESCRIBE.POT_WHITEWOOD = {
    GENERIC = "I can actually teleport to places with special plants at any time.",
    BARREN = "Okay, I need to fertilize it. Can the poop be used?",
    ALITTLE = "It's quite interesting to watch the little life gradually become stronger.",
    SOME = "This growth is average.",
    LOTS = "What time is it now, the time to harvest!",
    WRONGITEM = "I'm really overthinking it.",
    NONEED = "No?... Okay."
}
S_____WORMWOOD.DESCRIBE.POT_WHITEWOOD = {
    GENERIC = "I can meet my distant friends often now!",
    BARREN = "No fertilizer left, I have a solution!",
    ALITTLE = "Just arrived at the new home, my friend needs to adapt.",
    SOME = "My friend has taken root in the new home.",
    LOTS = "Too many friends, we need to arrange it.",
    WRONGITEM = "Wrong.",
    NONEED = "Unwanted."
}
-- S________WARLY.DESCRIBE.POT_WHITEWOOD = ""
-- S_________WURT.DESCRIBE.POT_WHITEWOOD = ""
-- S_______WALTER.DESCRIBE.POT_WHITEWOOD = ""
-- S________WANDA.DESCRIBE.POT_WHITEWOOD = ""

S_NAMES.SHADOWBRUSH_L = "Brush of Shadow Detail" --细微之触
S_RECIPE_DESC.SHADOWBRUSH_L = "Alter details in subtle places."
S______GENERIC.DESCRIBE.SHADOWBRUSH_L = "Let shadow paint change the appearance of something."
S_______WILLOW.DESCRIBE.SHADOWBRUSH_L = "Things created by shadows always have strange shapes."
-- S_____WOLFGANG.DESCRIBE.SHADOWBRUSH_L = ""
S________WENDY.DESCRIBE.SHADOWBRUSH_L = "Changing unimportant details is meaningless."
-- S_________WX78.DESCRIBE.SHADOWBRUSH_L = ""
-- S_WICKERBOTTOM.DESCRIBE.SHADOWBRUSH_L = ""
-- S_______WOODIE.DESCRIBE.SHADOWBRUSH_L = ""
S______WAXWELL.DESCRIBE.SHADOWBRUSH_L = "Shadows always do boring things on some details."
-- S___WATHGRITHR.DESCRIBE.SHADOWBRUSH_L = ""
S_______WEBBER.DESCRIBE.SHADOWBRUSH_L = "This brush can fully unleash our imagination!"
S_______WINONA.DESCRIBE.SHADOWBRUSH_L = "Painting requires attention to detail..."
-- S_______WORTOX.DESCRIBE.SHADOWBRUSH_L = ""
S_____WORMWOOD.DESCRIBE.SHADOWBRUSH_L = "Drawing?"
-- S________WARLY.DESCRIBE.SHADOWBRUSH_L = ""
-- S_________WURT.DESCRIBE.SHADOWBRUSH_L = ""
-- S_______WALTER.DESCRIBE.SHADOWBRUSH_L = ""
-- S________WANDA.DESCRIBE.SHADOWBRUSH_L = ""

--------------------------------------------------------------------------
--[[ other ]]--[[ 其他 ]]
--------------------------------------------------------------------------

S_NAMES.BACKCUB = "Back Cub"    --靠背熊
S______GENERIC.DESCRIBE.BACKCUB = "Hey, I think it likes my back."
S_______WILLOW.DESCRIBE.BACKCUB = "Oh! So cute, like my Bernie."
--S_____WOLFGANG.DESCRIBE.BACKCUB = ""
S________WENDY.DESCRIBE.BACKCUB = "It's babies are always so cute, now the adults are a different story."
--S_________WX78.DESCRIBE.BACKCUB = ""
--S_WICKERBOTTOM.DESCRIBE.BACKCUB = ""
--S_______WOODIE.DESCRIBE.BACKCUB = ""
S______WAXWELL.DESCRIBE.BACKCUB = "Hm... with no monster child there'd be no future trouble..."
--S___WATHGRITHR.DESCRIBE.BACKCUB = ""
S_______WEBBER.DESCRIBE.BACKCUB = "We don't want to grow up, do you?"
-- S_______WINONA.DESCRIBE.BACKCUB = ""
-- S_______WORTOX.DESCRIBE.BACKCUB = ""
-- S_____WORMWOOD.DESCRIBE.BACKCUB = ""

S_NAMES.SHIELD_L_LOG = "Log Shield" --木盾
S_RECIPE_DESC.SHIELD_L_LOG = "The first attempt at defense and counterattack."
S______GENERIC.DESCRIBE.SHIELD_L_LOG = "What a humble shield. It may work."
-- S_______WILLOW.DESCRIBE.SHIELD_L_LOG = ""
S_____WOLFGANG.DESCRIBE.SHIELD_L_LOG = "The pattern on it is a little artistic."
-- S________WENDY.DESCRIBE.SHIELD_L_LOG = ""
-- S_________WX78.DESCRIBE.SHIELD_L_LOG = ""
-- S_WICKERBOTTOM.DESCRIBE.SHIELD_L_LOG = ""
S_______WOODIE.DESCRIBE.SHIELD_L_LOG = "Not too handy."
S______WAXWELL.DESCRIBE.SHIELD_L_LOG = "I'm not going to wave around this ridiculous shield."
S___WATHGRITHR.DESCRIBE.SHIELD_L_LOG = "A new fighting idea for a warrior!"
-- S_______WEBBER.DESCRIBE.SHIELD_L_LOG = ""
-- S_______WINONA.DESCRIBE.SHIELD_L_LOG = ""
S_______WORTOX.DESCRIBE.SHIELD_L_LOG = "I just slip away when I can't hide, so I don't need this."
S_____WORMWOOD.DESCRIBE.SHIELD_L_LOG = "Friends' body has become my barrier."
-- S________WARLY.DESCRIBE.SHIELD_L_LOG = ""
-- S_________WURT.DESCRIBE.SHIELD_L_LOG = ""
-- S_______WALTER.DESCRIBE.SHIELD_L_LOG = ""
-- S________WANDA.DESCRIBE.SHIELD_L_LOG = ""

STRINGS.ACTIONS_LEGION = {
    PLAYGUITAR = "Play", --弹琴
    PULLOUTSWORD = "Pull out", --拔剑出鞘
    USE_UPGRADEKIT = "Assemble upgrade", --升级套件的升级动作
    MAKE = "Make", --打窝器容器的按钮名字
    ATTACK_SHIELD_L = "Shield up", --盾牌类道具通用动作
    REMOVE_CARPET_L = "Fork away", --移除地毯
    RUB_L = "Rub", --电气石摩擦
    SMEAR_L = "Smear", --涂抹类道具使用时
    SCABBARD = "Put into", --青枝绿叶放入武器
    WAX_L = "Weave New", WAX_RIGHT_L = "Weave", --打蜡动作
    WAXCLUSTER_L = "Adjust Cluster", --影织异种的簇栽
    SOULBOOK_CONTROL = "Control", --打开契约的按钮轮盘
    SOULBOOK_STOPCONTROL = "Stop Control", --关闭契约的按钮轮盘
    SOULBOOK_SIGN = "Sign/Terminate It",
    SOULBOOK_EXTRACT_SOULS = "Extract Souls",
    SOULBOOK_STORE_SOULS = "Store Souls",
    SOULBOOK_SHARE_SOULS = "Share Souls",
    SOULBOOK_SHARE_LEVEL = "Share Levels",
    SOAK_L = "Soak in",
    ROAST = "Roast",
    CLEARCOL = "Clear This Column",
    CLEARROW = "Clear This Row",
    CLEARALL = "Clear All Items",
    REDETAIL_L = "Alter Details"
}
STRINGS.ACTIONS.PICK.GENETRANS = "Take down" --收获子圭·育的动作

STRINGS.ACTIONS.OPEN_CRAFTING.RECAST = "Brainstorm with" --靠近解锁时的前置提示。名字与AddPrototyperDef里的action_str一致
STRINGS.ACTIONS.OPEN_CRAFTING.SIVING = "Whisper with"
STRINGS.UI.CRAFTING_STATION_FILTERS.RECAST = "Recast"

STRINGS.UI.CRAFTING_FILTERS.RECAST = "Recast"
STRINGS.UI.CRAFTING_FILTERS.SIVING = "Siving"
STRINGS.UI.CRAFTING_FILTERS.LEGION = "Legion"

--NEEDS..新tech的名字
STRINGS.UI.CRAFTING.NEEDSELECOURMALINE_ONE = "Find the Elecourmaline to build this!"
STRINGS.UI.CRAFTING.NEEDSELECOURMALINE_TWO = "It seems that this stone is not fully activated!"
STRINGS.UI.CRAFTING.NEEDSELECOURMALINE_THREE = "Find the activated Elecourmaline to build this!"

STRINGS.UI.CRAFTING.NEEDSSIVING_ONE = "Whisper to the Siving Alpha to build a prototype!"
STRINGS.UI.CRAFTING.NEEDSSIVING_TWO = "It seems that the Siving Alpha has lost faith in you!"
STRINGS.UI.CRAFTING.NEEDSSIVING_THREE = "Use a Siving-Sacrifice to build a prototype!"

STRINGS.ACTIONS.REPAIR_LEGION = {
    GENERIC = "Repair",
    MERGE = "Merge",
    EMBED = "Embed",
    CHARGE = "Charge",
    CONTRACTS = "Expand"
}
S______GENERIC.ACTIONFAIL.REPAIR_LEGION = {
    GUITAR = "There's nothing to fix.",
    FUNGUS = "It's fresh and doesn't need to be repaired.",
    MAT = "Already the biggest it can be.",
    YELLOWGEM = "It's already full of gems.",
    ELEC = "It is already full of energy!"
}
S_______WEBBER.ACTIONFAIL.REPAIR_LEGION = {
    GUITAR = "It's none of our business.",
    FUNGUS = "We can't see what's wrong even with our several eyes.",
    MAT = "OK, that's good.",
    YELLOWGEM = "It seems that not everything can be infinite.",
    ELEC = "Enough for us to use for a long time."
}
S_______WINONA.ACTIONFAIL.REPAIR_LEGION = {
    GUITAR = "Perfect as ever.",
    FUNGUS = "It's perfect.",
    MAT = "I think that's as big as it's going to get.",
    YELLOWGEM = "Enough.",
    ELEC = "I think it's fully charged."
}

STRINGS.CROP_LEGION = {
    SEED = "Planted {crop} Seed",
    SPROUT = "{crop} Sprout",
    SMALL = "{crop} Shoot",
    GROWING = "Growing {crop}",
    GROWN = "Mature {crop}",
    HUGE = "Huge Mature {crop}",
    ROT = "Withered {crop}",
    HUGE_ROT = "Huge Rotten {crop}",
}
CopyStrActionFail("POUR_WATER_LEGION", "POUR_WATER_GROUNDTILE")

STRINGS.ACTIONS.PLANTSOIL_LEGION = {
    GENERIC = "Plant",
    DISPLAY = "Replant",
    CLUSTERED = "Clustered Plant"
}

S______GENERIC.ACTIONFAIL.PLANTSOIL_LEGION = {
    NOTMATCH_C = "Different varieties can't be planted together.",
    ISMAXED_C = "It has reached its maximum planting density."
}
-- S_______WILLOW.ACTIONFAIL.PLANTSOIL_LEGION = ""
S_____WOLFGANG.ACTIONFAIL.PLANTSOIL_LEGION = {
    NOTMATCH_C = "Not a family, not a door.",
    ISMAXED_C = "There is no place to continue planting."
}
-- S________WENDY.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S_________WX78.ACTIONFAIL.PLANTSOIL_LEGION = ""
S_WICKERBOTTOM.ACTIONFAIL.PLANTSOIL_LEGION = {
    NOTMATCH_C = "They need the same genes to grow together!",
    ISMAXED_C = "I'm curious whether it can grow in such a dense environment?"
}
-- S_______WOODIE.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S______WAXWELL.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S___WATHGRITHR.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S_______WEBBER.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S_______WINONA.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S________WARLY.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S_______WORTOX.ACTIONFAIL.PLANTSOIL_LEGION = ""
S_____WORMWOOD.ACTIONFAIL.PLANTSOIL_LEGION = {
    NOTMATCH_C = "Only the same kind is welcome.",
    ISMAXED_C = "Full!"
}
-- S_________WURT.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S_______WALTER.ACTIONFAIL.PLANTSOIL_LEGION = ""
-- S________WANDA.ACTIONFAIL.PLANTSOIL_LEGION = ""

STRINGS.ACTIONS.GENETRANS = {
    GENERIC = "Put On",
    CHARGE = "Charge",
}
S______GENERIC.ACTIONFAIL.GENETRANS = {
    NOGENE = "It needs to obtain samples before transforming this.",
    GROWING = "Something is already here.",
    ENERGYOUT = "Needs to be charged before it can start.",
    WRONGITEM = "This isn't what it can transform.",
    ENERGYMAX = "Already full of life energy.",
    WRONGKEY = "This can't be used as a sample.",
    HASKEY = "It already has this sample."
}
-- S_______WILLOW.ACTIONFAIL.GENETRANS =
-- S_____WOLFGANG.ACTIONFAIL.GENETRANS =
-- S________WENDY.ACTIONFAIL.GENETRANS =
-- S_________WX78.ACTIONFAIL.GENETRANS =
-- S_WICKERBOTTOM.ACTIONFAIL.GENETRANS =
-- S_______WOODIE.ACTIONFAIL.GENETRANS =
-- S______WAXWELL.ACTIONFAIL.GENETRANS =
-- S___WATHGRITHR.ACTIONFAIL.GENETRANS =
-- S_______WEBBER.ACTIONFAIL.GENETRANS =
-- S_______WINONA.ACTIONFAIL.GENETRANS =
-- S_______WORTOX.ACTIONFAIL.GENETRANS =
-- S_____WORMWOOD.ACTIONFAIL.GENETRANS =
S________WARLY.ACTIONFAIL.GENETRANS = {
    NOGENE = "It needs a recipe to know how to do it.",
    GROWING = "A pot can only cook one dish at same time!",
    NOENERGY = "This stove is out of fuel.",
    WRONGITEM = "Wrong ingredients.",
    ENERGYMAX = "Maximum power has been reached.",
    WRONGKEY = "This is not the recipe it needs.",
    HASKEY = "It already has this recipe."
}
-- S_________WURT.ACTIONFAIL.GENETRANS =
-- S_______WALTER.ACTIONFAIL.GENETRANS =
-- S________WANDA.ACTIONFAIL.GENETRANS =

STRINGS.ACTIONS.RC_SKILL_L = {
    GENERIC = "Spell",
    FEATHERTHROW = "Feather Split",
    FEATHERPULL = "Feather Retrieve"
}

STRINGS.ACTIONS.LIFEBEND = {
    GENERIC = "Rejuvenate",
    REVIVE = "Resurrect",
    CURE = "Heal",
    GIVE = "Deliver Life"
}
S______GENERIC.ACTIONFAIL.LIFEBEND = {
    NOLIFE = "I'm out of life.",
    GHOST = "It's soul is crippled beyond repair.",
    NOTHURT = "Your health is already topped off!",
    NOWITHERED = "It's growing nicely!"
}
-- S_______WILLOW.ACTIONFAIL.LIFEBEND =
-- S_____WOLFGANG.ACTIONFAIL.LIFEBEND =
S________WENDY.ACTIONFAIL.LIFEBEND = {
    NOLIFE = "I have reached the end of my life.",
    GHOST = "Many attempts, but I don't want to give up yet.",
    NOTHURT = "You don't need me anymore, do you?",
    NOWITHERED = "Still in perfect health."
}
S_________WX78.ACTIONFAIL.LIFEBEND = {
    NOLIFE = "WARNING: LOW LIFE ENERGY!",
    GHOST = "RESURRECTING A LONE GHOST? NO!",
    NOTHURT = "SCAN: NORMAL FUNCTION.",
    NOWITHERED = "SCAN: NORMAL STATUS."
}
-- S_WICKERBOTTOM.ACTIONFAIL.LIFEBEND =
-- S_______WOODIE.ACTIONFAIL.LIFEBEND =
-- S______WAXWELL.ACTIONFAIL.LIFEBEND =
-- S___WATHGRITHR.ACTIONFAIL.LIFEBEND =
-- S_______WEBBER.ACTIONFAIL.LIFEBEND =
-- S_______WINONA.ACTIONFAIL.LIFEBEND =
-- S________WARLY.ACTIONFAIL.LIFEBEND =
-- S_______WORTOX.ACTIONFAIL.LIFEBEND =
S_____WORMWOOD.ACTIONFAIL.LIFEBEND = {
    NOLIFE = "Not enough nutrients.",
    GHOST = "No response.",
    NOTHURT = "Healthy.",
    NOWITHERED = "Thriving!"
}
-- S_________WURT.ACTIONFAIL.LIFEBEND =
-- S_______WALTER.ACTIONFAIL.LIFEBEND =
-- S________WANDA.ACTIONFAIL.LIFEBEND =

S______GENERIC.ACTIONFAIL.REMOVE_CARPET_L = {
    GENERIC = "There is no carpet to fork away."
}
-- S_______WILLOW.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_____WOLFGANG.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S________WENDY.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_________WX78.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_WICKERBOTTOM.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_______WOODIE.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S______WAXWELL.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S___WATHGRITHR.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_______WEBBER.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_______WINONA.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S________WARLY.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_______WORTOX.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_____WORMWOOD.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_________WURT.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S_______WALTER.ACTIONFAIL.REMOVE_CARPET_L = ""
-- S________WANDA.ACTIONFAIL.REMOVE_CARPET_L = ""

STRINGS.ACTIONS.MOONSURGE_L = {
    GENERIC = "Moonlight Surge",
    LACK = "Surge"
}

S______GENERIC.ACTIONFAIL.RUB_L = {
    NOUSE = "No response...",
    NOENERGY = "The battery is low.",
    NONEED = "It doesn't need it at the moment.",
    REFUSE = "It is currently unable to charge."
}
-- S_______WILLOW.ACTIONFAIL.RUB_L = ""
-- S_____WOLFGANG.ACTIONFAIL.RUB_L = ""
-- S________WENDY.ACTIONFAIL.RUB_L = ""
S_________WX78.ACTIONFAIL.RUB_L = {
    NOUSE = "NOT APPLICABLE! ONLY FOOLISH HUMANS CANNOT SEE IT.",
    NOENERGY = "ENERGY WILL ALSO BE DEPLETED.",
    NONEED = "DON'T WASTE ENERGY!",
    REFUSE = "THE CHARGING INTERFACE IS NOT RESPONDING."
}
-- S_WICKERBOTTOM.ACTIONFAIL.RUB_L = ""
-- S_______WOODIE.ACTIONFAIL.RUB_L = ""
-- S______WAXWELL.ACTIONFAIL.RUB_L = ""
-- S___WATHGRITHR.ACTIONFAIL.RUB_L = ""
-- S_______WEBBER.ACTIONFAIL.RUB_L = ""
S_______WINONA.ACTIONFAIL.RUB_L = {
    NOUSE = "That's not how it's used!",
    NOENERGY = "The battery is low, I will try charging it.",
    NONEED = "I don't need to do anything else.",
    REFUSE = "It is in a state where it cannot conduct electricity."
}
-- S________WARLY.ACTIONFAIL.RUB_L = ""
-- S_______WORTOX.ACTIONFAIL.RUB_L = ""
S_____WORMWOOD.ACTIONFAIL.RUB_L = {
    NOUSE = "It's useless.",
    NOENERGY = "There is no power.",
    NONEED = "Not now.",
    REFUSE = "Can't do it, what's the problem?"
}
-- S_________WURT.ACTIONFAIL.RUB_L = ""
-- S_______WALTER.ACTIONFAIL.RUB_L = ""
-- S________WANDA.ACTIONFAIL.RUB_L = ""

S______GENERIC.ACTIONFAIL.SMEAR_L = {
    NOUSE = "It's not used like this.",
    NONEED = "It has already been done."
}
-- S_______WILLOW.ACTIONFAIL.SMEAR_L = ""
-- S_____WOLFGANG.ACTIONFAIL.SMEAR_L = ""
-- S________WENDY.ACTIONFAIL.SMEAR_L = ""
-- S_________WX78.ACTIONFAIL.SMEAR_L = ""
-- S_WICKERBOTTOM.ACTIONFAIL.SMEAR_L = ""
-- S_______WOODIE.ACTIONFAIL.SMEAR_L = ""
-- S______WAXWELL.ACTIONFAIL.SMEAR_L = ""
-- S___WATHGRITHR.ACTIONFAIL.SMEAR_L = ""
-- S_______WEBBER.ACTIONFAIL.SMEAR_L = ""
-- S_______WINONA.ACTIONFAIL.SMEAR_L = ""
-- S________WARLY.ACTIONFAIL.SMEAR_L = ""
-- S_______WORTOX.ACTIONFAIL.SMEAR_L = ""
-- S_____WORMWOOD.ACTIONFAIL.SMEAR_L = ""
-- S_________WURT.ACTIONFAIL.SMEAR_L = ""
-- S_______WALTER.ACTIONFAIL.SMEAR_L = ""
-- S________WANDA.ACTIONFAIL.SMEAR_L = ""

STRINGS.UI_L = {
    OPTBUTTON = "Legion Client Settings",
    DRAGTIP = "Right click and hold to move.",
    KEYBOUND = "Currently Bound Key",
    KEYNONE = "No",
    DRAGABLEUI = {
        TITLE = "Movable UI:",
        TIP = "After activation, all container UI (such as backpacks, chests) can be movable while holding down the right mouse button.\n▷Please note that this option no longer works when the \"Functional Medal\" mod is enabled."
    },
    RESETUIPOS = {
        TITLE = "Reset UI Position:",
        TIP = "After activation and closing the current Legion settings page, the code will clear the cache of UI and reset all UI positions.\n▷Please note that this option no longer works when the \"Functional Medal\" mod is enabled."
    },
    SHIELDKEY = {
        TITLE = "Shortcut Key for Shield:",
        TIP = "After binding a button, the shield lifting action can be triggered through that button."
    },
    SHIELDMOUSE = {
        TITLE = "Mouse to Lift Shield:",
        TIP = "After activation, the shield lifting action can be triggered by right clicking the mouse."
    },
    SIVMASKMOUSE = {
        TITLE = "Mouse to Use Siving Mask:",
        TIP = "After activation, you can trigger the skill of \"Siving-Thaumaturgy\" by right clicking the mouse."
    },
    MOUSEINFOCLIENT = {
        TITLE = "Mouse Hover Display Info:",
        TIP = "After activation, when the mouse points to some items, it displays special info about that item.\n▷Please note that if the server settings turn off \"Mouse Hover Display Info\", this option will no longer be effective."
    },
}

STRINGS.NAMEDETAIL_L = {
    PROBLEMSKIN = "SkinError ({sk})",
    DEALPROBLEMSKIN1 = "[{doer}] There are no expired skins in the current world.",
    DEALPROBLEMSKIN2 = "[{doer}] All expired skins in the current world have been restored.",
    DEALPROBLEMSKIN3 = "[{doer}] The current world's expired skins have been partially restored. Please check the ownership of those failed skins.",
    FIREPROOF = "Fireproof",
    MOONTREASURE = "Moon Treasure {lvl}/{lvlmax}",
    SMEARED = {
        MONSTRAIN = "Raindonate-Production Stops",
        POT = "Reactivity Decreases",
        POT_FUNGUS = "Spore-Production Stops",
        POT_WORMLIGHT = "Shining Stops"
    },
    SIVTT = "Energy (Light {i1} Vitality {i2})\nLife Counter {heal}, Excavation {work}/{wmax}\nConquest Times {con}\n{sta} State",
    SIVDT = "Energy (Light {i1} Vitality {i2})",
    SIVMASK = "Life Counter {v}/{vmax}\nBlood Steal {st}, Healing Power {h}",
    SIVSUIT = "Counteratk Max {cmax}\nBlood Clot {bc}%, Armor Loss {ac}%",
    SIVEQUIP_MODE = { "Bitter Mode", "Pure Mode", "Blank Mode" },
    VASEHERB_MODE = { "Restless", "Tame" },
    SIVTT_MODE = { [0] = "Withered", [1] = "Normal", [2] = "Energetic" },
    SIVCTL = {
        "Moi. {mo}/{momax}",
        "Nut. (Formula {n1} Compost {n2} Manure {n3}) /{nmax}",
        "Nut. (Formula {n1} Compost {n2} Manure {n3}) /{nmax}\nMoi. {mo}/{momax}"
    },
    BLOOMY = "Bloomy",
    WITHERED = "Withered",
    UNHAPPY = "Bored",
    THIRSTY = "Dry",
    FEEBLE = "Feeble",
    WAXED = "Fuel-Woven",
    SPACE = ", ", PERIOD = ". ", SECOND = "sec",
    SIVPLANT = "{des}{st}/{stmax}Stage, {li}/{limax}Days, {gr}%Rate\nNut. (Formula {n1} Cure {n2} Need {n3}) /{nmax}\nMoi.{mo}/{momax}, Pollen{pl}/{plmax}, Pest{sk}%, Infest{it}/{itmax}\nSatisfaction {np}/5",
    SIVPLANT2 = "{des}{st}/{stmax}Stage, {li}/{limax}Days, {gr}%Rate\nNut. (Formula {n1} Cure {n2} Need {n3}) /{nmax}\nMoi.{mo}/{momax}, Pollen{pl}/{plmax}, Pest{sk}%, Infest{it}/{itmax}\nSummary (Nut. {nn} Moi. {nm} Tend {nt})",
    XPLANT = "ClusterLvl.{c}/{cmax}\n{des}{st}/{stmax}Stage, {li}/{limax}Days, {gr}%Rate\nPollen {pl}/{plmax}, Infest {it}/{itmax}",
    XEEDS = " Xeeds",
    DIGEST = "[{doer}] fed {items} to the {eater}.",
    DIGESTSELF = "{eater} digested {items}.",
    VASEHERB = "ClusterLvl.{c}/{cmax}, Eated {ea}/80\nSwallow(Rad.{d_s} Num.{n_s} CD.{t_s}sec), Lure Rad.{d_l}",
    CLOUDPINE = "ClusterLvl.{c}/{cmax}\n{st}/{stmax} Stage, Infest {it}/{itmax}",
    GENETRANS1 = "{s} (Doing {n1} Done {n2})\nCurrent {gr}/{grmax} Days, {mt}% Rate\nPoints (Energy {e} SpeedUp {ft}) /{emax}",
    GENETRANS2 = "Points (Energy {e} SpeedUp {ft}) /{emax}",
    SOULBOOK1 = "Souls {us}/{usmax}, Unsigned",
    SOULBOOK2 = "Souls {us}/{usmax}, Signatory [{ow}]",
    FISHHOMINGBAIT1 = "Lure Times {ti}",
    FISHHOMINGBAIT2 = "Special Lure ({dt})\nLure Times {ti}",
    FISHHOMING = "{fi} {ch}%",
    SHYERRYCORE_PLANTED = "Stage{st}/3, Moi.{mo}/{momax}\nNut. (①{n1} ②{n2} ③{n3}) /{nmax}\nGrowth.{gr}/{grmax}, Fruit.{ft}/16",
    SHYERRYCORE = "Stage{st}/3, Moi.{mo}/{momax}\nNut. (①{n1} ②{n2} ③{n3}) /{nmax}\nGrowth.{gr}/{grmax}, Fruit.{ft}/16\nConquest Times {con}",
    POT_WHITEWOOD = {
        "{sc}, {st}/{stmax}Stage, {gt}Days\nFertility {ft}/{ftmax}, Yield {fn}",
        "Fertility {ft}/{ftmax}",
        "Growth stops, need special fertilizer!"
    },
    MONSTRAIN_WAXED = { "Summer Withered", "Frozen Withered", "Mature" },
    SIVING_DERIVANT_WAXED = { "Stage 1/4", "Stage 2/4", "Stage 3/4", "Stage 4/4" },
    FRUITS = { "Many Fruits", "Normal Fruits", "Few Fruits" },
    SIVING_THETREE_WAXED = "Energetic State",
    WORLDSWORD_WAXED = { "Revolt Surge State", "Moon Surge State" },
    FORM = "Form",
    BARREN = "Barren",
    UNPLANTED = "Unplanted",
    STAGE = "Stage",
    CLUSTERLVL = "ClusterLvl.",
    FULLBLOOM = "FullBloom",
    ABNORMAL = "Abnormal",
    FRUIT = "Fruit.",
    SMALLER = "Smaller",
    ICIRE_ROCK_WAXED = { "Frozen", "Cold", "Average", "Warm", "Hot" },
    BUFFCYCLE = "-sec Cycle",
    BLDG_SOAK = "Health {hea}, Sanity {san}, Moi. {moi}, Nut. {mul}, Temp. {tp1} ({tp2}~{tp3})",
    SHADOWBRUSH_MODE = { "Random Mode", "Stage Sequence Mode", "Sequence Mode" }
}

-- STRINGS.LEGION_TIPS = {
-- }

STRINGS.ACTIONS.SETMODE_L = {
    GENERIC = "Switch",
    MYSTERY = "Whisper",
    TOUCH = "Pet"
}

CopyStrActionFail("BOXOPENER_L", "RUMMAGE")

S_NAMES.SEEDS_BERRIES_L = S_NAMES.PLANT_BERRIES_L..STRINGS.NAMEDETAIL_L.XEEDS
