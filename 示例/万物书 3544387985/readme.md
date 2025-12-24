


本MOD基础底层框架封装好的API：

    · 一些常用函数：
        前往 scripts\_key_modules_of_tbat\_0_common_func  查看

    · RPC Event 信道：
        1、直接以 PushEvent 的形式发送RPC事件。接收端只需要普通的ListenForEvent即可。
        2、服务端 -> 客户端 : 使用 player.components.tbat_com_rpc_event:PushEvent("XXX",data)
        3、客户端 -> 服务端 : 使用 ThePlayer.replica.tbat_com_rpc_event:PushEvent("XXX",data)
        4、封装了自动识别的函数： 
            TBAT.FNS:RPC_PushEvent(player_or_userid,event_name,data,target_inst,succeed_callback,timeout_callback)
            · 在客户端的时候往server 发送事件。
            · 在服务端的的时候往client 发送事件。
        5、可以给非玩家inst发送事件：target_inst。通常用于界面按钮点击。
        6、data 里不能有inst实体等对象。
        7、封装好的RPC信道有5条，有时候存在阻塞延迟，不要用于大量信息发送。
        8、有失败重发机制。容易丢包的场景的时候注意处理。
        9、用于数据同步的时候，注意消息时间戳。RPC信道的不稳定造成了目标接收可能是乱序的。
        10、【注意】不要用于频繁的数据传送！！非要使用RPC传送大量信息，则自行独立封装新的RPC信道。

    ·  tbat_classified :
        1、玩家身上挂载了独立的classified，用来挂载新增的 netvars 。
        2、用来避免玩家inst身上netvars数量过多,造成溢出（可能显示为客户端常驻启蒙状态）。
        3、使用方法可以和官方的classified使用方法一样，找到prefab直接添加。
        4、推荐用法，参考示例  components.tbat_com_excample_classified
        5、注意处理额外的replica 造成额外的tag问题。
        6、如果不使用replica，则可以往 TBAT.CLASSIFIED_INSTALL_FNS 里insert一个函数,实现tbat_classified里添加指定的netvars和配套API。

    ·  客制化独立tag系统(仅限玩家)：
        1、组件：components.tbat_com_custom_tags
        2、封装为API ： inst:TBATAddTag("XXX")
        3、调用官方的tag API ： inst:HasTag("XXX")  ->  true
        4、通常用于制作栏、客户端的专属tag，能有效避免为了解锁制作栏某些物品的制作而占用官方的tag数量。
        5、有一定的延迟。

    ·  复制官方的debuffable模块：
        1、组件：components.tbat_com_debuffable
        2、基本上和官方的debuffable一样，去掉了玩家死亡瞬间清空debuff的功能。

    ·  通用数据库：components.tbat_data
        1、可以存储任意数据（不包括inst对象）。
        2、注意索引的独特性，不要和其他地方覆盖调用。
        3、玩家身上已经默认自带。
        4、数据会储存到存档。        

    ·  特殊通用数据库：components.tbat_data_to_world
        1、仅限玩家。
        2、储存数据于存档，用来解决换角色后数据丢失的问题。
        3、功能基本和tbat_data一样。

    ·  特殊工作计时器： TheWorld.components.tbat_com_special_timer_for_theworld
        1、只存在于TheWorld
        2、用来执行某些加载范围外的任务函数。

    ·  特殊客户端update函数： TBAT:AddInputUpdateFn(inst,fn,...)
        1、仅限客户端，通常用于界面的刷新。
        2、以30FPS运行，fn不要太复杂。
        3、inst删除的时候，fn会跟着删。对于界面，可以使用例如 front_root.inst 作为绑定。界面Kill的时候，函数跟着注销。

    ·  容器界面HOOK 入口封装： inst:ListenForEvent("tbat_event.container_widget_open",widget_open)
        1、可以在容器prefab里添加监听，触发这个event后，修改容器界面。
        2、具体示例请搜索这个Event已经用于哪些示例。

    ·  通用交互四件套：
        1、通用物品、建筑右键使用：tbat_com_workable
        2、通用物品接受组件：tbat_com_acceptable
        3、通用物品给予组件：tbat_com_item_use_to
        4、通用武器施法组件：tbat_com_point_and_target_spell_caster
            · 【注意】这个手柄兼容不是很好。
        5、以上模块的示例请搜索已有的prefab里。
        6、这4个模块可以解决大部分的交互问题，不用经常注册 components-action。
        7、配合模块 tbat_com_action_fail_reason 可实现交互后角色说话。具体前往查看已有示例。

    ·  客户端数据读取： components.tbat_com_client_side_data
        1、仅限玩家。
        2、具体前往对应的组件查看用法。
        3、使用的RPC信道，不要频繁读写。
        4、客户端一方，可以使用 replica 里更底层的API ： scripts\_key_modules_of_tbat\_0_common_func\01_client_data_api.lua


本MOD额外处理一些事情的笔记:

    · replica 造成的玩家身上额外tag问题：
        · 原因： 注册组件 replica 后，会往实体inst身上挂同名tag，而且必须存在。
        · 造成今后tag占用过多的话，可以使用 TBAT:ReplicaTagRemove(inst,com_name)
        · 这种改动是使用了客制化的tag信道。
        · 角色刚刚生成的前几秒过后，才会切换。并不能完全解决问题，只是有所缓解。

    · 一些往replica注册的参数、函数，可以使用 Event : TBAT_OnEntityReplicated.XXXX
        · 具体前往 scripts\_key_modules_of_tbat\00_others\01_replica_register.lua 查看。
        · 可以有效缓解客户端 inst.OnEntityReplicated 层层叠叠造成的问题。
        · 没洞穴的存档（客户端即服务端）也会触发Event
        · 示例可以参考【通用交互四件套】

    ·  玩家身上的netvars数量过多，造成客户端常驻启蒙状态的处理办法：
        · 同步量不是很频繁的，可以考虑RPC信道。
        · 同步量频繁的，使用 tbat_classified 。如果不想做replica,可以考虑 TBAT.CLASSIFIED_INSTALL_FNS，具体前往prefab查看。
