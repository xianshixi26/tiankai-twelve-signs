class_name CombatData
extends RefCounted

## 数值配置：策划改这里即可，不改代码（与 GDD 3.6/3.7 对齐）

## 角色原型（灰盒 3 选；全 12 生肖后续按此结构扩展）
const ARCHETYPES := {
	"tiger": {"name": "寅虎·平衡", "color": Color(0.86, 0.36, 0.20), "hp": 1050.0, "attack": 110.0, "speed": 1.0},
	"ox":    {"name": "丑牛·力量", "color": Color(0.55, 0.45, 0.30), "hp": 1250.0, "attack": 125.0, "speed": 0.85},
	"horse": {"name": "午马·速度", "color": Color(0.78, 0.26, 0.16), "hp": 950.0,  "attack": 100.0, "speed": 1.25},
}

## 四段普攻：windup=前摇 active=判定 recover=后摇（秒）；dmg=攻击力系数；kb=击退 px/s
## 第 4 段 = 重势收招：大动作、大伤害、必定击飞（GDD 3.2 张力要求）
const ATTACK_STEPS := [
	{"windup": 0.08, "active": 0.06, "recover": 0.16, "dmg": 0.35, "range": 78.0,  "hitstun": 0.18, "kb": 240.0, "launch": false},
	{"windup": 0.08, "active": 0.06, "recover": 0.18, "dmg": 0.35, "range": 78.0,  "hitstun": 0.18, "kb": 260.0, "launch": false},
	{"windup": 0.12, "active": 0.08, "recover": 0.22, "dmg": 0.50, "range": 88.0,  "hitstun": 0.24, "kb": 320.0, "launch": false},
	{"windup": 0.20, "active": 0.10, "recover": 0.40, "dmg": 0.90, "range": 100.0, "hitstun": 0.50, "kb": 420.0, "launch": true},
]

## 技能（气槽 25%）与大招（气槽 100%）
const SKILL_STEP    := {"windup": 0.15, "active": 0.12, "recover": 0.35, "dmg": 1.2, "range": 130.0, "hitstun": 0.35, "kb": 380.0, "launch": false}
const ULTIMATE_STEP := {"windup": 0.30, "active": 0.15, "recover": 0.55, "dmg": 3.5, "range": 170.0, "hitstun": 0.80, "kb": 520.0, "launch": true}

## 连击伤害衰减：max(0.6, 1 − 0.03 × (连击数 − 5))（GDD 3.7 公式）
static func combo_decay(combo: int) -> float:
	return maxf(0.6, 1.0 - 0.03 * maxf(0.0, float(combo) - 5.0))

## 伤害公式：攻击 × 系数 × (1+0.02×连击) × 衰减 × 浮空1.1 × 格挡0.3 × 全局倍率
static func compute_damage(attacker, step: Dictionary, blocked: bool) -> float:
	var dmg: float = attacker.attack_power * step.dmg
	dmg *= 1.0 + 0.02 * float(attacker.combo)
	dmg *= combo_decay(attacker.combo)
	if step.launch:
		dmg *= 1.1
	if blocked:
		dmg *= 0.3
	dmg *= attacker.cfg.damage_mult
	return roundf(dmg)
