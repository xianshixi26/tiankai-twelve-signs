class_name AIControl
extends RefCounted

## 简单对战 AI：意图输出与玩家同构（move_x/jump/attack/dodge/block/skill/ultimate）
## 难度由 GameConfig 的 ai_* 参数控制，闯关难度递进只调参数

var rng := RandomNumberGenerator.new()
var think := 0.0

func _init() -> void:
	rng.randomize()

func update(delta: float, cfg: GameConfig, me, foe) -> Dictionary:
	var intent := {
		"move_x": 0.0, "jump": false, "attack": false,
		"dodge": false, "block": false, "skill": false, "ultimate": false,
	}
	if me == null or foe == null or me.state == Fighter.State.KO:
		return intent

	think -= delta
	var dist: float = absf(me.position.x - foe.position.x)
	var foe_attacking: bool = foe.state in [Fighter.State.ATTACK, Fighter.State.SKILL, Fighter.State.ULTIMATE]

	# 受击反应：对手出招且距离近时，按概率闪避或格挡
	if foe_attacking and dist < 170.0 and think <= 0.0:
		var r := rng.randf()
		if r < cfg.ai_dodge_chance:
			intent.dodge = true
			think = cfg.ai_reaction
			return intent
		elif r < cfg.ai_dodge_chance + cfg.ai_block_chance:
			intent.block = true
			think = cfg.ai_reaction * 1.5
			return intent

	# 持续格挡一小会儿
	if me.state == Fighter.State.BLOCK:
		intent.block = rng.randf() < 0.85
		return intent

	# 走位：太远则接近，贴太近偶尔拉开
	if dist > 130.0:
		intent.move_x = signf(foe.position.x - me.position.x)
	elif dist < 70.0 and rng.randf() < 0.02:
		intent.move_x = -signf(foe.position.x - me.position.x)

	# 进攻：进入射程按间隔出招（带随机抖动）
	if dist <= 145.0 and think <= 0.0:
		if me.meter >= 100.0 and rng.randf() < 0.35:
			intent.ultimate = true
			think = cfg.ai_attack_interval
		elif me.meter >= 25.0 and rng.randf() < 0.25:
			intent.skill = true
			think = cfg.ai_attack_interval
		else:
			intent.attack = true
			think = cfg.ai_attack_interval * rng.randf_range(0.7, 1.3)
	return intent
