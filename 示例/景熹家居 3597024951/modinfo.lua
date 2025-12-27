local is_chinese = locale == "zh" or locale == "zht" or locale=="zhr"

name = is_chinese and "景熹家居" or "JingXi Furniture"
description = is_chinese and 
[[让你的庇护所充满生活感！
专为喜欢丰富基地生活的你而设计。
模组内有多款实用复古家电和家具，
让硬核生存多一份居家的温暖与便利！
作者：B站画画的景熹]]
or [[Make your shelter full of vitality! 
Specially designed for players who enjoy 
a rich base life. There are multiple 
practical retro appliances and furniture 
in the module, giving difficult survival 
the warmth and convenience of home! 
Author: Jing Xi, Illustrator from bilibili".]]

author = "B站画画的景熹|驯猫糕手"
version = "25.12.26"
api_version = 10
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true
icon_atlas = "images/modicon.xml"
icon = "modicon.tex"
server_filter_tags = is_chinese and { "景熹家居", } or { "JingXi Furniture", }
configuration_options = {}