extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	assert(game.chapters.size() == 6, "应有六个剧情章节")
	assert(game.traits.size() == 6, "应有六种共生能力")
	for chapter in game.chapters:
		assert(chapter.intro.size() >= 4, "每卷应有完整剧情对话")
		assert(chapter.choices.size() == 3, "每卷应有三个关键抉择")
		assert(chapter.lore.size() == 2, "每卷应有两条人文见闻")

	var exploration_script = load("res://scripts/exploration.gd")
	var arena = exploration_script.new()
	root.add_child(arena)
	arena.size = Vector2(1280, 720)
	var test_traits: Array[String] = ["tiger", "wolf"]
	arena.start_chapter(game.chapters[0], test_traits, game.legacy_stats, 0)
	await process_frame
	var enemy: Dictionary = arena.enemies[0]
	enemy.pos = arena.player_pos + Vector2(45, 0)
	arena.enemies[0] = enemy
	arena.aim_pos = enemy.pos
	var hp_before := float(enemy.hp)
	arena.basic_attack()
	assert(float(arena.enemies[0].hp) < hp_before, "墨刃应能主动伤害敌人")
	assert(arena.attack_anim > 0.0, "墨刃应触发拔剑、挥砍与收势动作")
	var energy_before_dash: float = float(arena.energy)
	arena.dash()
	assert(arena.dash_time > 0.0 and arena.energy < energy_before_dash, "闪避应触发轻功残影并消耗共鸣")
	var health_before_hit: float = float(arena.health)
	arena.damage_cooldown = 0.0
	arena._take_damage(5.0, Vector2.LEFT)
	assert(arena.health < health_before_hit and arena.hurt_anim > 0.0, "受击应扣除生命并触发动作反馈")
	arena.player_pos = arena.lore_points[0].pos
	assert(arena._try_lore(), "应能调查人文见闻")
	assert(arena.lore_found == 1, "见闻计数应更新")
	arena.fragments_found = 3
	arena.nodes_restored = 2
	arena.enemies_defeated = 3
	arena.npc_talked = true
	arena._check_boss_and_portal()
	assert(arena.boss_spawned, "完成前置任务后应生成章节首领")
	var boss_index: int = arena.enemies.size() - 1
	arena._damage_enemy(boss_index, 9999.0, true)
	arena._check_boss_and_portal()
	assert(arena.boss_defeated and arena.portal_open, "击败首领后应开启出口")
	arena.queue_free()
	await process_frame

	game.selected_traits = test_traits.duplicate()
	game.legacy_stats = {"ink": 45, "heart": 45, "fate": 55, "hero": 0, "people": 0}
	game.memory_fragments.clear()
	for index in 6:
		game._clear()
		await process_frame
		game.chapter_index = index
		game.last_report = {"time": 51.0, "health": 72.0, "kills": 5, "lore": 2}
		game.legacy_stats.people = int(game.legacy_stats.people) + 4
		game._build_decision()
		await process_frame
		game._choose_aftermath(0)
		await process_frame
	assert(game.memory_fragments.size() == 6, "六卷应生成六枚记忆印记")
	assert(int(game.legacy_stats.hero) > 0, "高代价选择应积累英雄气")
	assert(int(game.legacy_stats.people) == 24, "十二条见闻应累积民声")
	assert(game._resolve_ending().has("title"), "应生成有效终章")
	print("SMOKE_TEST_PASS chapters=6 combat=ok bosses=6 lore=12 choices=18 endings=3")
	quit(0)
