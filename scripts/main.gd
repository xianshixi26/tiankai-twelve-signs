extends Node2D

## 主控：世界调度 + 战斗结算 + 打击感（顿帧/震屏/慢镜）+ 游戏流程
## 顿帧实现：hitstop>0 时冻结世界 tick（HUD 照常刷新），比缩放 time_scale 更可控

const FighterClass = preload("res://scripts/fighter.gd")
const HudClass = preload("res://scripts/hud.gd")
const TunerClass = preload("res://scripts/feel_tuner.gd")

enum GameState { FIGHT, OVER }

const SCREEN_W := 1152.0
const SCREEN_H := 648.0

var cfg := GameConfig.new()
var ground_y := 560.0

var p1: Fighter
var p2: Fighter
var ai := AIControl.new()
var hud
var tuner
var camera: Camera2D

var game_state: int = GameState.FIGHT
var timer_left := 90.0
var banner := ""
var hitstop := 0.0
var world_slow := 1.0
var over_slow_time := 0.0
var shake_amp := 0.0
var shake_time := 0.0

var last_p1_key := "tiger"
var last_p2_key := "ox"
var esc_press_time := -10.0


func _ready() -> void:
	_setup_input()
	queue_redraw()

	p1 = FighterClass.new()
	p2 = FighterClass.new()
	add_child(p1)
	add_child(p2)

	var ui_layer := CanvasLayer.new()
	add_child(ui_layer)
	hud = HudClass.new()
	ui_layer.add_child(hud)
	hud.setup(self)

	tuner = TunerClass.new()
	add_child(tuner)
	tuner.setup(self)

	camera = Camera2D.new()
	camera.position = Vector2(SCREEN_W / 2.0, 300.0)
	add_child(camera)
	camera.make_current()

	reset_match(last_p1_key, last_p2_key)


# ── 世界循环 ──────────────────────────────────────
func _physics_process(delta: float) -> void:
	# 顿帧：世界冻结，HUD 照常
	if hitstop > 0.0:
		hitstop -= delta
		hud.queue_redraw()
		return

	var d := delta * world_slow
	if game_state == GameState.FIGHT:
		timer_left -= d
		if timer_left <= 0.0:
			timer_left = 0.0
			_time_over()

	var intent1 := PlayerControl.read()
	var intent2: Dictionary = ai.update(d, cfg, p2, p1)
	p1.tick(d, intent1)
	p2.tick(d, intent2)

	# 震屏
	if shake_time > 0.0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-shake_amp, shake_amp), randf_range(-shake_amp, shake_amp))
		shake_amp = maxf(shake_amp - cfg.shake_decay * delta, 0.0)
		if shake_time <= 0.0:
			camera.offset = Vector2.ZERO

	# KO 慢镜结束
	if over_slow_time > 0.0:
		over_slow_time -= delta
		if over_slow_time <= 0.0:
			world_slow = 1.0

	hud.queue_redraw()


# ── 战斗结算（唯一伤害入口）────────────────────────
func try_hit(attacker: Fighter, defender: Fighter, step: Dictionary) -> void:
	if game_state != GameState.FIGHT:
		return
	if defender.state == Fighter.State.KO or attacker.hit_confirmed:
		return
	if defender.is_invulnerable():
		return
	if not _in_range(attacker, defender, step):
		return

	var dir := 1.0 if defender.position.x >= attacker.position.x else -1.0

	# 格挡分支（只挡正面）
	if defender.is_blocking() and defender.facing == int(signf(attacker.position.x - defender.position.x)):
		if defender.is_perfect_blocking():
			# 完美格挡 → 弹刀：攻方硬直，防方回气
			attacker.state = Fighter.State.HIT
			attacker.state_time = 0.0
			attacker.hitstun_left = 0.25
			attacker.velocity.x = -dir * 180.0
			defender.meter = minf(defender.meter + 10.0, 100.0)
			hitstop = 0.06
			_shake(5.0, 0.12)
			hud.flash_text("完美格挡！", 0.8)
			return
		else:
			attacker.hit_confirmed = true
			var bdmg := CombatData.compute_damage(attacker, step, true)
			defender.receive_hit(step, dir, false, bdmg, true)
			_after_hit(attacker, defender, step, false)
			return

	# 命中
	attacker.hit_confirmed = true
	var launched: bool = step.launch
	var dmg := CombatData.compute_damage(attacker, step, false)
	defender.receive_hit(step, dir, launched, dmg, false)
	_after_hit(attacker, defender, step, launched)


func _after_hit(attacker: Fighter, defender: Fighter, step: Dictionary, launched: bool) -> void:
	attacker.combo += 1
	attacker.combo_timer = cfg.combo_window
	attacker.meter = minf(attacker.meter + 3.0, 100.0)   # 命中 +3%
	defender.meter = minf(defender.meter + 2.0, 100.0)   # 受击 +2%

	# 打击感：顿帧 + 震屏（重击更强）
	if step.dmg >= 3.0:
		hitstop = cfg.hitstop_ultimate
	elif launched:
		hitstop = cfg.hitstop_heavy
	else:
		hitstop = cfg.hitstop_short
	_shake(cfg.shake_amp * (2.0 if launched else 1.0), 0.15)

	if defender.hp <= 0.0:
		_ko(attacker, defender)


func _in_range(a: Fighter, b: Fighter, step: Dictionary) -> bool:
	var reach: float = step.range + Fighter.BODY_W / 2.0
	return absf(a.position.x - b.position.x) <= reach and absf(a.position.y - b.position.y) <= 115.0


# ── 流程：KO / 时间到 / 重开 ───────────────────────
func _ko(winner: Fighter, loser: Fighter) -> void:
	game_state = GameState.OVER
	banner = "K.O.！"
	hitstop = 0.35
	world_slow = 0.25
	over_slow_time = 1.2
	_shake(14.0, 0.4)
	hud.flash_text("K.O.！", 2.0)


func _time_over() -> void:
	game_state = GameState.OVER
	var r1 := p1.hp / p1.max_hp
	var r2 := p2.hp / p2.max_hp
	if absf(r1 - r2) < 0.001:
		banner = "时间到！平局"
	else:
		banner = "时间到！%s 胜" % (p1.data.name if r1 > r2 else p2.data.name)
	hud.flash_text(banner + "（按 R 再来）", 3.0)


func _shake(amp: float, time: float) -> void:
	shake_amp = maxf(shake_amp, amp)
	shake_time = maxf(shake_time, time)


func reset_match(p1_key: String = "tiger", p2_key: String = "ox") -> void:
	last_p1_key = p1_key
	last_p2_key = p2_key
	p1.setup(self, cfg, p1_key, true, p2)
	p2.setup(self, cfg, p2_key, false, p1)
	p1.position = Vector2(400.0, ground_y)
	p2.position = Vector2(752.0, ground_y)
	timer_left = 90.0
	game_state = GameState.FIGHT
	banner = ""
	world_slow = 1.0
	over_slow_time = 0.0
	hitstop = 0.0
	shake_time = 0.0
	camera.offset = Vector2.ZERO
	hud.flash_text("%s  VS  %s" % [p1.data.name, p2.data.name], 1.5)


# ── 全局按键（重开/选人/调参/退出）──────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		reset_match(last_p1_key, last_p2_key)
	elif event.is_action_pressed("toggle_tuner"):
		tuner.visible = not tuner.visible
	elif event.is_action_pressed("quit"):
		# 防误触：1.5 秒内连按两次 Esc 才退出（单按 Esc 只提示，防止"闪退"错觉）
		if Time.get_ticks_msec() * 0.001 - esc_press_time < 1.5:
			print("[quit] 双击 Esc 退出")
			get_tree().quit()
		else:
			esc_press_time = Time.get_ticks_msec() * 0.001
			hud.flash_text("再按一次 Esc 退出游戏", 1.5)
	elif event.is_action_pressed("sel_tiger"):
		reset_match("tiger", last_p2_key)
	elif event.is_action_pressed("sel_ox"):
		reset_match("ox", last_p2_key)
	elif event.is_action_pressed("sel_horse"):
		reset_match("horse", last_p2_key)


# ── 输入映射（代码注册，避免配置文件格式坑）──────────
func _setup_input() -> void:
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_bind_keys("attack", [KEY_J])
	_bind_keys("dodge", [KEY_K])
	_bind_keys("block", [KEY_L])
	_bind_keys("skill", [KEY_U])
	_bind_keys("ultimate", [KEY_I])
	_bind_keys("restart", [KEY_R])
	_bind_keys("toggle_tuner", [KEY_F1])
	_bind_keys("quit", [KEY_ESCAPE])
	_bind_keys("sel_tiger", [KEY_1])
	_bind_keys("sel_ox", [KEY_2])
	_bind_keys("sel_horse", [KEY_3])


func _bind_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


# ── 灰盒场景（静态，一次性绘制）────────────────────
func _draw() -> void:
	draw_rect(Rect2(0, 0, SCREEN_W, 560.0), Color(0.10, 0.12, 0.20))       # 夜空
	draw_rect(Rect2(0, 440.0, SCREEN_W, 120.0), Color(0.14, 0.16, 0.26))   # 远景
	draw_rect(Rect2(0, 560.0, SCREEN_W, 88.0), Color(0.22, 0.20, 0.28))    # 地面
	draw_rect(Rect2(0, 556.0, SCREEN_W, 4.0), Color(0.45, 0.42, 0.55))     # 地平线
