class_name Fighter
extends Node2D

## 角色状态机：IDLE/WALK/JUMP → ATTACK/SKILL/ULTIMATE/DODGE/BLOCK → HIT → KO
## 玩法层不引用任何美术资源，灰盒方块即最终逻辑，换皮不改代码

enum State { IDLE, WALK, JUMP, ATTACK, SKILL, ULTIMATE, DODGE, BLOCK, HIT, KO }

const BODY_W := 44.0
const BODY_H := 100.0

# ── 引用 ──────────────────────────────────────────
var main            # 主控（动态引用，避免循环依赖）
var cfg: GameConfig
var foe: Fighter
var data: Dictionary = {}
var is_player := true

# ── 属性（数值全部来自 CombatData 配置）──────────────
var max_hp := 1000.0
var hp := 1000.0
var attack_power := 110.0
var speed_mult := 1.0
var meter := 0.0            # 气槽 0~100

# ── 运动 ──────────────────────────────────────────
var velocity := Vector2.ZERO
var grounded := true
var facing := 1             # 1=朝右 -1=朝左（灰盒矢量绘制，无需素材翻转）

# ── 状态 ──────────────────────────────────────────
var state: int = State.IDLE
var state_time := 0.0
var attack_step := 0
var attack_queued := false
var hit_confirmed := false
var attack_buffer := 0.0
var block_time := 0.0
var hitstun_left := 0.0
var flash_time := 0.0
var combo := 0
var combo_timer := 0.0
var dodge_dir := 1
var body_color := Color.WHITE
var trail: Array = []


func setup(p_main, p_cfg: GameConfig, key: String, p_is_player: bool, p_foe: Fighter) -> void:
	main = p_main
	cfg = p_cfg
	is_player = p_is_player
	foe = p_foe
	data = CombatData.ARCHETYPES[key]
	max_hp = data.hp
	hp = max_hp
	attack_power = data.attack
	speed_mult = data.speed
	body_color = data.color
	facing = 1 if p_is_player else -1
	velocity = Vector2.ZERO
	state = State.IDLE
	state_time = 0.0
	combo = 0
	combo_timer = 0.0
	meter = 0.0
	trail.clear()


## 每物理帧由主控调用（顿帧/慢镜由主控在 delta 上处理）
func tick(delta: float, intent: Dictionary) -> void:
	state_time += delta
	flash_time = maxf(flash_time - delta, 0.0)
	combo_timer = maxf(combo_timer - delta, 0.0)
	if combo_timer <= 0.0:
		combo = 0
	meter = minf(meter + 0.5 * delta, 100.0)   # 气槽自然回复 +0.5%/s

	if intent.attack:
		attack_buffer = cfg.attack_buffer
	else:
		attack_buffer = maxf(attack_buffer - delta, 0.0)

	match state:
		State.IDLE, State.WALK, State.JUMP:
			_tick_free(delta, intent)
		State.ATTACK:
			_tick_attack(delta, intent, CombatData.ATTACK_STEPS[attack_step])
		State.SKILL:
			_tick_attack(delta, intent, CombatData.SKILL_STEP)
		State.ULTIMATE:
			_tick_attack(delta, intent, CombatData.ULTIMATE_STEP)
		State.DODGE:
			var t := state_time / cfg.dodge_time
			velocity.x = dodge_dir * cfg.dodge_distance / cfg.dodge_time * (1.0 - t * 0.7)  # 缓出
			trail.push_front({"pos": position})
			if trail.size() > 3:
				trail.pop_back()
			if state_time >= cfg.dodge_time:
				state = State.IDLE
				state_time = 0.0
				trail.clear()
		State.BLOCK:
			block_time += delta
			velocity.x = move_toward(velocity.x, 0.0, cfg.stop_decel * delta)
			if not intent.block:
				state = State.IDLE
				state_time = 0.0
		State.HIT:
			hitstun_left -= delta
			velocity.x = move_toward(velocity.x, 0.0, cfg.knockback_decay * delta)
			if hitstun_left <= 0.0 and grounded:
				state = State.IDLE
				state_time = 0.0
		State.KO:
			velocity.x = move_toward(velocity.x, 0.0, cfg.knockback_decay * 0.5 * delta)

	# ── 物理积分 ──
	if not grounded:
		velocity.y += cfg.gravity * delta
	position += velocity * delta
	if position.y >= main.ground_y:
		position.y = main.ground_y
		grounded = true
		if velocity.y > 0.0:
			velocity.y = 0.0
	else:
		grounded = false

	# 静止时自动面向对手
	if state in [State.IDLE, State.WALK, State.BLOCK] and foe != null:
		facing = 1 if foe.position.x >= position.x else -1

	queue_redraw()


# ── 自由态：移动/跳跃/起手 ─────────────────────────
func _tick_free(delta: float, intent: Dictionary) -> void:
	var target: float = intent.move_x * cfg.move_speed * speed_mult   # Variant 需显式类型
	var rate: float = cfg.accel if absf(intent.move_x) > 0.1 else cfg.stop_decel
	velocity.x = move_toward(velocity.x, target, rate * delta)
	if grounded and absf(intent.move_x) > 0.1:
		state = State.WALK
	elif state == State.WALK and absf(intent.move_x) <= 0.1:
		state = State.IDLE

	if intent.jump and grounded:
		velocity.y = cfg.jump_velocity
		grounded = false
		state = State.JUMP

	# 优先级：闪避 > 格挡 > 攻击 > 技能 > 大招
	if intent.dodge and grounded:
		dodge_dir = int(signf(intent.move_x)) if absf(intent.move_x) > 0.1 else -facing  # 无方向输入=向后闪
		state = State.DODGE
		state_time = 0.0
		trail.clear()
		return
	if intent.block and grounded:
		state = State.BLOCK
		block_time = 0.0
		state_time = 0.0
		return
	if attack_buffer > 0.0:
		attack_buffer = 0.0
		_start_attack(0)
		return
	if intent.skill and meter >= 25.0:
		meter -= 25.0
		state = State.SKILL
		state_time = 0.0
		hit_confirmed = false
		velocity.x = 0.0
		return
	if intent.ultimate and meter >= 100.0:
		meter = 0.0
		state = State.ULTIMATE
		state_time = 0.0
		hit_confirmed = false
		velocity.x = 0.0
		return


# ── 攻击态推进（普攻段/技能/大招共用）───────────────
func _tick_attack(delta: float, intent: Dictionary, step: Dictionary) -> void:
	var active_end: float = step.windup + step.active
	var total: float = active_end + step.recover
	velocity.x = move_toward(velocity.x, 0.0, cfg.stop_decel * delta)

	# 判定帧：交给主控做命中检测（一次攻击只命中一次）
	if not hit_confirmed and state_time >= step.windup and state_time <= active_end:
		main.try_hit(self, foe, step)

	# 后摇期间按攻击 → 排队下一段（12 帧缓冲）
	if state_time >= active_end and intent.attack:
		attack_queued = true

	if state_time >= total:
		if attack_queued and state == State.ATTACK and attack_step < CombatData.ATTACK_STEPS.size() - 1:
			_start_attack(attack_step + 1)   # 连下一段（第 4 段不可再接）
		else:
			state = State.IDLE
			state_time = 0.0


func _start_attack(step: int) -> void:
	state = State.ATTACK
	attack_step = step
	state_time = 0.0
	attack_queued = false
	hit_confirmed = false
	velocity.x = float(facing) * 90.0   # 出招小幅前压


# ── 判定查询（主控用）──────────────────────────────
func is_invulnerable() -> bool:
	return state == State.DODGE and state_time >= cfg.dodge_iframe_start and state_time <= cfg.dodge_iframe_end

func is_blocking() -> bool:
	return state == State.BLOCK

func is_perfect_blocking() -> bool:
	return state == State.BLOCK and block_time <= cfg.perfect_block_window

func _current_step() -> Dictionary:
	match state:
		State.ATTACK: return CombatData.ATTACK_STEPS[attack_step]
		State.SKILL: return CombatData.SKILL_STEP
		State.ULTIMATE: return CombatData.ULTIMATE_STEP
	return CombatData.ATTACK_STEPS[0]


# ── 受击 ──────────────────────────────────────────
func receive_hit(step: Dictionary, dir: float, launched: bool, dmg: float, blocked: bool) -> void:
	hp = maxf(hp - dmg, 0.0)
	flash_time = cfg.hit_flash
	if hp <= 0.0:
		state = State.KO
		velocity.x = dir * step.kb * 1.2
		velocity.y = -320.0
		grounded = false
		return
	state = State.HIT
	state_time = 0.0
	hitstun_left = step.hitstun * (0.5 if blocked else (1.25 if launched else 1.0))
	velocity.x = dir * step.kb * (0.5 if blocked else 1.0)
	if launched and not blocked:
		velocity.y = -430.0
		grounded = false


# ── 灰盒绘制（纯色图元，换皮不改逻辑）───────────────
func _draw() -> void:
	var w := BODY_W
	var h := BODY_H

	# 闪避残影
	for i in range(trail.size()):
		var g: Dictionary = trail[i]
		var alpha := 0.22 * (1.0 - float(i) / 4.0)
		draw_rect(Rect2(g.pos - position + Vector2(-w / 2.0, -h), Vector2(w, h)), Color(body_color, alpha))

	# 身体 + 头
	var body_rect := Rect2(-w / 2.0, -h, w, h)
	draw_rect(body_rect, body_color)
	draw_rect(Rect2(-w / 2.0 + 6.0, -h - 26.0, w - 12.0, 26.0), body_color.lightened(0.15))

	# 武器（出招时伸长）
	var attacking := state in [State.ATTACK, State.SKILL, State.ULTIMATE]
	var weapon_len := 62.0 if attacking else 44.0
	draw_rect(Rect2(float(facing) * w / 2.0, -h * 0.68, float(facing) * weapon_len, 10.0), Color(0.85, 0.85, 0.9))

	# 攻击判定可视化（发生帧显示半透明黄框）
	if attacking:
		var step := _current_step()
		if state_time >= step.windup and state_time <= step.windup + step.active:
			draw_rect(Rect2(float(facing) * w / 2.0, -h * 0.95, float(facing) * step.range, h * 0.8), Color(1.0, 0.9, 0.3, 0.35))

	# 格挡盾
	if state == State.BLOCK:
		var shield_color := Color(0.4, 0.85, 1.0, 0.65) if is_perfect_blocking() else Color(0.3, 0.6, 0.9, 0.55)
		draw_rect(Rect2(float(facing) * (w / 2.0 + 2.0), -h * 0.9, float(facing) * 12.0, h * 0.75), shield_color)

	# 受击闪白
	if flash_time > 0.0:
		draw_rect(body_rect, Color(1, 1, 1, clampf(flash_time / cfg.hit_flash, 0.0, 1.0) * 0.85))
