extends RefCounted


static func traits() -> Array:
	return [
		{"id": "tiger", "name": "破纸虎步", "origin": "虎 · 爆发", "desc": "墨刃伤害更高，闪避冷却更短", "color": Color("d67b4f")},
		{"id": "eagle", "name": "探微鹰瞳", "origin": "鹰 · 远视", "desc": "攻击距离增加，暴击率大幅提高", "color": Color("d8b967")},
		{"id": "bear", "name": "玄裘护体", "origin": "熊 · 保温", "desc": "生命上限增加，受到伤害降低", "color": Color("8cb4b0")},
		{"id": "wolf", "name": "逐墨狼嗅", "origin": "狼 · 追迹", "desc": "显示任务方向，攻击能够吸血", "color": Color("91a9c5")},
		{"id": "chimp", "name": "灵巧猿手", "origin": "猿 · 工具", "desc": "阵眼修复更快，共鸣消耗降低", "color": Color("b89a77")},
		{"id": "horse", "name": "山行马力", "origin": "马 · 耐力", "desc": "移动更快，画灵能量上限增加", "color": Color("b9c879")}
	]



static func chapters() -> Array:
	return [
		{
			"title": "风尘入画", "subtitle": "第一卷 · 失踪的引路人", "image": "res://assets/backgrounds/chapter_01.jpg",
			"accent": Color("d8b66d"), "mode": "dust", "boss": "驮碑墨兽",
			"npc": {"id": "ayan", "name": "阿砚", "title": "纸灵引路人", "color": Color("d8b66d"), "pos": Vector2(1045, 520), "lines": ["我等了你整整一百年。别问为什么你会被卷进来——先把散落的朱印找齐。", "当心那些裂墨。它们原本也是画中人，只是忘了自己的名字。"]},
			"intro": [
				{"id": "ayan", "speaker": "阿砚", "text": "醒醒，守卷人。山河卷已经裂成六层梦境，再迟一步，画中人都会变成裂墨。"},
				{"id": "you", "speaker": "守卷人", "text": "博物馆的火……是我打开了这幅卷？"},
				{"id": "ayan", "speaker": "阿砚", "text": "火只是门。真正烧起来的，是卷中人被遗忘了一百年的怨念。先完成任务，我在画里等你。"},
				{"id": "moyan", "speaker": "？？？", "text": "又一个守卷人。你也会把他们修回那座永不天明的牢笼吗？"}
			],
			"lore": [
				{"title": "驿卒的家书", "text": "纸上只写了三件事：驿马瘦了，母亲的药钱托同乡带回，若明日还能上路，就替邻村捎一包麦种。山河将裂时，他惦记的仍是别人家的春天。"},
				{"title": "无名车夫的账簿", "text": "每一趟运粮的里程、车损和脚钱都记得清楚，最后一页却没有结算。战争写将军姓名，真正把粮送到关前的人只留下半枚指印。"}
			],
			"choices": [
				{"title": "先救出迷途车队", "desc": "让画中人的生命优先于原迹", "delta": {"ink": 1, "heart": 13, "fate": -3}, "fragment": "风尘朱印", "result": "车轮第一次驶出循环。阿砚笑了，却悄悄藏起一块写着你名字的纸。"},
				{"title": "追查裂墨的来源", "desc": "沿敌人留下的痕迹寻找纵火者", "delta": {"ink": 14, "heart": -2, "fate": 3}, "fragment": "逆风墨痕", "result": "你在裂墨深处看见一枚旧守卷印，它属于一位早已死去的人。"},
				{"title": "把朱印交给阿砚", "desc": "暂时相信这位来历不明的引路人", "delta": {"ink": 6, "heart": 7, "fate": 4}, "fragment": "纸灵密约", "result": "朱印融入阿砚的手腕。那一瞬，她的影子竟像完整的山河卷。"}
			]
		},
		{
			"title": "云山夺印", "subtitle": "第二卷 · 同行还是对手", "image": "res://assets/backgrounds/chapter_02.jpg",
			"accent": Color("8dc3bd"), "mode": "mist", "boss": "十三声钟魇",
			"npc": {"id": "shenjin", "name": "沈烬", "title": "另一位守卷人", "color": Color("b96556"), "pos": Vector2(1030, 250), "lines": ["阿砚只告诉你一半真相。修复一卷，现实就会忘掉一个与它有关的人。", "我会拿走钟纹。想阻止我，就先证明你能活着走到山顶。"]},
			"intro": [
				{"id": "ayan", "speaker": "阿砚", "text": "云山寺的钟每晚响十三次，第十四声藏着第二枚卷心。"},
				{"id": "shenjin", "speaker": "沈烬", "text": "别听她的。第十四声不是卷心，是一百年前被抹去的求救。"},
				{"id": "you", "speaker": "守卷人", "text": "你是谁？为什么也有守卷印？"},
				{"id": "shenjin", "speaker": "沈烬", "text": "一个比你早失败过的人。任务结束前，最好别把背后交给任何纸做的人。"}
			],
			"lore": [
				{"title": "山寺斋单", "text": "寺里每日只煮两锅粥，一锅给僧人，一锅留给逃进山里的百姓。粮缸见底后，掌勺僧把自己的名字从斋单上划掉。"},
				{"title": "无名碑拓", "text": "碑上没有王侯功业，只刻着修路者三十七人。最末一句说：山高路险，愿后来赶路的人少崴一次脚。"}
			],
			"choices": [
				{"title": "相信阿砚，封住残钟", "desc": "稳定山河卷，但让求救永远沉默", "delta": {"ink": 14, "heart": -5, "fate": 5}, "fragment": "无声钟纹", "result": "第十四声被你封回寂静。沈烬夺走半枚钟纹，消失在云后。"},
				{"title": "与沈烬追进钟腹", "desc": "冒险查清被抹去的那一夜", "delta": {"ink": 8, "heart": 8, "fate": -7}, "fragment": "第十四声", "result": "钟腹里刻着火灾前的名单。最后一个名字，是阿砚。"},
				{"title": "让山脚村民决定", "desc": "把任务选择交还给画中 NPC", "delta": {"ink": 3, "heart": 14, "fate": 1}, "fragment": "众生回响", "result": "村民选择敲响残钟。群山开裂，却也第一次迎来黎明。"}
			]
		},
		{
			"title": "桥上旧梦", "subtitle": "第三卷 · 修复的代价", "image": "res://assets/backgrounds/chapter_03.jpg",
			"accent": Color("8fb4c9"), "mode": "rain", "boss": "忘川纸傀",
			"npc": {"id": "qiaosheng", "name": "乔生", "title": "无名画师", "color": Color("8fb4c9"), "pos": Vector2(1040, 520), "lines": ["我是画这座桥的人，也是第一个被山河卷忘掉的人。", "每修好一道裂痕，现实就少一个记得我们的人。你还要继续吗？"]},
			"intro": [
				{"id": "qiaosheng", "speaker": "乔生", "text": "别修那座桥。它一旦完整，我在现实中最后一幅署名也会消失。"},
				{"id": "ayan", "speaker": "阿砚", "text": "不修，整卷都会坠进忘川。乔先生，你明明知道。"},
				{"id": "shenjin", "speaker": "沈烬", "text": "她说得很熟练，对吧？因为一百年前，她也这样劝过第一代守卷人。"},
				{"id": "you", "speaker": "守卷人", "text": "完成任务之后，我要听到全部真相。少一个字，我就停笔。"}
			],
			"lore": [
				{"title": "桥匠的欠据", "text": "桥修好那年，县里还欠匠人三个月工钱。领头的老匠只讨来一袋米，分给死在水里的学徒家中，自己空手回家。"},
				{"title": "一把补过七次的伞", "text": "伞骨上写着七个名字。每次洪水，它都被借给更需要的人；原主人最后没等到伞回来，却有人替她把孩子送过了桥。"}
			],
			"choices": [
				{"title": "保住乔生的署名", "desc": "让桥留下裂痕，也留下一个人", "delta": {"ink": 4, "heart": 15, "fate": -6}, "fragment": "未干落款", "result": "桥只修到九成。乔生的名字留在雨里，任务日志第一次标记为“不完美但存活”。"},
				{"title": "完成整座旧桥", "desc": "以个人记忆换取画卷稳定", "delta": {"ink": 16, "heart": -7, "fate": 3}, "fragment": "完整桥印", "result": "旧桥无瑕，乔生却从所有人的话语里消失，只剩你记得他。"},
				{"title": "把桥改成通往画外", "desc": "违背原作，为 NPC 创造出口", "delta": {"ink": 8, "heart": 10, "fate": -9}, "fragment": "画外扁舟", "result": "第一批画中人踏过边界。墨魇没有攻击你，反而向你行了一礼。"}
			]
		},
		{
			"title": "青岚反照", "subtitle": "第四卷 · 引路人的真身", "image": "res://assets/backgrounds/chapter_04.jpg",
			"accent": Color("8fcbb5"), "mode": "fireflies", "boss": "剜心青兽",
			"npc": {"id": "ayan", "name": "阿砚·卷心", "title": "山河卷缺失的灵魂", "color": Color("8fcbb5"), "pos": Vector2(980, 240), "lines": ["对不起。我不是纸灵，我就是被第一代守卷人从画中剜走的卷心。", "墨魇想带所有人逃出去；我想保住这座世界。你必须决定谁才是怪物。"]},
			"intro": [
				{"id": "moyan", "speaker": "墨魇", "text": "看看她的影子。你拼回的每一枚残片，都在让她重新成为这座牢笼的心脏。"},
				{"id": "ayan", "speaker": "阿砚", "text": "他说的是真的。我骗了你——但如果卷心不归位，六卷里的所有人都会死。"},
				{"id": "you", "speaker": "守卷人", "text": "所以博物馆的大火、我的守卷印、这些任务，全都是你安排的？"},
				{"id": "ayan", "speaker": "阿砚", "text": "火不是我放的。放火的人，就站在你身后。"}
			],
			"lore": [
				{"title": "万家灯册", "text": "守夜人挨户记下油灯是否点亮。不是为了征税，而是怕哪户老人病倒无人知道。最后一页写着：今晚全村有光。"},
				{"title": "留白边注", "text": "有人用极小的字写道：这里原本画着一场灾难，画师把它抹掉，不是要遗忘，而是给活下来的人留一处不必解释的地方。"}
			],
			"choices": [
				{"title": "仍然保护阿砚", "desc": "谎言不能抹去她一路救过的人", "delta": {"ink": 4, "heart": 14, "fate": -4}, "fragment": "卷心微光", "result": "你替阿砚挡下剜心一击。沈烬收刀时，眼里第一次有了迟疑。"},
				{"title": "暂时扣住卷心", "desc": "在真相查清前，谁都不能完成山河卷", "delta": {"ink": 13, "heart": 1, "fate": 7}, "fragment": "封心纸匣", "result": "阿砚失去力量，青岚立刻枯萎。你赢得时间，也失去了她的信任。"},
				{"title": "与墨魇谈判", "desc": "要求他停止袭击并交出第一代记录", "delta": {"ink": 9, "heart": 8, "fate": -2}, "fragment": "初代守卷印", "result": "墨魇摘下面具：他就是本该死于百年前的第一代守卷人。"}
			]
		},
		{
			"title": "秋火断归途", "subtitle": "第五卷 · 所有人都输了", "image": "res://assets/backgrounds/chapter_05.jpg",
			"accent": Color("d7824d"), "mode": "leaves", "boss": "焚影将",
			"npc": {"id": "shenjin", "name": "沈烬", "title": "负伤的竞争者", "color": Color("d7824d"), "pos": Vector2(1070, 530), "lines": ["火是我放的。我以为烧掉原卷，就能让被困的人自由。结果只制造了更多裂墨。", "焚影将是我的影子。杀掉它，我也可能回不去。别停手。"]},
			"intro": [
				{"id": "shenjin", "speaker": "沈烬", "text": "别往前。秋火会把你最想回去的地方变成敌人。"},
				{"id": "you", "speaker": "守卷人", "text": "阿砚说，博物馆的火是你放的。"},
				{"id": "shenjin", "speaker": "沈烬", "text": "是。我想救画中人，却烧碎了他们的世界。你若要算账，先活过这一卷。"},
				{"id": "moyan", "speaker": "墨魇", "text": "守卷人从没有赢家。一个守住牢笼，一个烧掉牢笼，而牢里的人永远付代价。"}
			],
			"lore": [
				{"title": "守林人的木牌", "text": "木牌背面刻着：若山火越过第三道沟，不必再救树，先带村里孩子往河边走。守林人没有把自己写进撤退顺序。"},
				{"title": "没有寄出的回信", "text": "老兵写：关已经失了，城也空了，我不知道还守什么。第二天他又添一句：可身后还有赶路的人，所以再守一夜。"}
			],
			"choices": [
				{"title": "救下沈烬", "desc": "放弃部分卷页稳定，把他带出秋火", "delta": {"ink": 2, "heart": 16, "fate": -10}, "fragment": "半命归途", "result": "沈烬活了下来，但第五卷永久缺了一角。他把自己的守卷印交给你。"},
				{"title": "让沈烬完成赎罪", "desc": "尊重他的选择，用牺牲封住秋火", "delta": {"ink": 14, "heart": -3, "fate": 5}, "fragment": "焚尽之印", "result": "沈烬与焚影一同化成灰。火熄灭时，只剩他的刀插在归途中央。"},
				{"title": "三人共同承担秋火", "desc": "你、阿砚与沈烬各失去一部分记忆", "delta": {"ink": 8, "heart": 9, "fate": -4}, "fragment": "三分灰烬", "result": "没有人死去，但你们互相忘记了最初相遇的样子。"}
			]
		},
		{
			"title": "竹影终战", "subtitle": "第六卷 · 谁来写最后一笔", "image": "res://assets/backgrounds/chapter_06.jpg",
			"accent": Color("d99eb5"), "mode": "petals", "boss": "墨魇·初代守卷人",
			"npc": {"id": "moyan", "name": "墨魇", "title": "第一代守卷人", "color": Color("d99eb5"), "pos": Vector2(1020, 250), "lines": ["我等的不是能打败我的人，而是一个见过所有代价后还敢落笔的人。", "来吧。战胜我，卷心就属于你；然后告诉所有画中人，你选择怎样的明天。"]},
			"intro": [
				{"id": "moyan", "speaker": "墨魇", "text": "一百年前，我也站在这里。那时我选择修复原卷，于是阿砚被剜走，所有 NPC 被锁回原位。"},
				{"id": "ayan", "speaker": "阿砚", "text": "他后来后悔了，便把自己变成裂墨，等下一位守卷人推翻他的答案。"},
				{"id": "you", "speaker": "守卷人", "text": "所以最后的任务不是杀死你。是证明我的答案能承受你的反对。"},
				{"id": "moyan", "speaker": "墨魇", "text": "说得好。那就拔出墨刃——让我看看你一路装配出的这条命，够不够资格重写山河。"}
			],
			"lore": [
				{"title": "花农的口诀", "text": "口诀没有玄妙章法，只说哪种花怕霜、哪种竹要留根。写它的人相信，天下再乱，总会有人需要知道明年怎么让花重新开。"},
				{"title": "未完残诗", "text": "诗没有署名，最后两句被水浸去。空白旁挤着许多后来人的小字：有人补故乡，有人补亲人，有人只写了一个“活”字。"}
			],
			"choices": [
				{"title": "修复原卷，但打开画门", "desc": "保留世界，也允许画中人自由进出", "delta": {"ink": 12, "heart": 10, "fate": -3}, "fragment": "共生终笔", "result": "山河归位，边界却不再封闭。阿砚成为第一位走出画外的 NPC。"},
				{"title": "把六卷改写成新世界", "desc": "放弃原作权威，让所有角色共同续画", "delta": {"ink": 5, "heart": 16, "fate": -8}, "fragment": "众生新卷", "result": "古画失去完美，却获得昼夜、衰老和真正的明天。墨魇终于放下守卷印。"},
				{"title": "留下永恒的未完之笔", "desc": "任何守卷人都无权替所有人决定", "delta": {"ink": 10, "heart": 8, "fate": 5}, "fragment": "未落终笔", "result": "最后一笔停在空中。此后每位进入画境的人，都能为山河添上一寸新路。"}
			]
		}
	]
