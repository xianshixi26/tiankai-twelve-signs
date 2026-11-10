class_name Hud
extends Control

## 灰盒 HUD：血条/气槽/计时/连击数/横幅（纯 draw，无皮肤）
## 中文用 SystemFont 保证字形（fallback 字体缺 CJK）

var main
var font: SystemFont
var flash_msg := ""
var flash_time := 0.0


func setup(p_main) -> void:
	main = p_main
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Segoe UI"])
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(1152.0, 648.0)


func flash_text(msg: String, dur: float) -> void:
	flash_msg = msg
	flash_time = dur


func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time -= delta
	queue_redraw()


func _draw() -> void:
	# ── 血条 ──
	_bar(Vector2(40, 28), 420, 26, main.p1.hp / main.p1.max_hp, Color(0.85, 0.25, 0.25))
	_bar(Vector2(692, 28), 420, 26, main.p2.hp / main.p2.max_hp, Color(0.85, 0.25, 0.25))
	_text(Vector2(40, 22), main.p1.data.name, 18, Color.WHITE)
	_text(Vector2(692, 22), main.p2.data.name, 18, Color.WHITE)

	# ── 气槽（25% 技能 / 100% 大招点亮提示）──
	_bar(Vector2(40, 62), 300, 12, main.p1.meter / 100.0, Color(0.95, 0.8, 0.25))
	_bar(Vector2(812, 62), 300, 12, main.p2.meter / 100.0, Color(0.95, 0.8, 0.25))
	if main.p1.meter >= 25.0:
		_text(Vector2(348, 72), "U技能" + ("·I大招!" if main.p1.meter >= 100.0 else ""), 14, Color(1.0, 0.9, 0.4))
	if main.p2.meter >= 100.0:
		_text(Vector2(692, 72), "敌方气满!", 14, Color(1.0, 0.6, 0.4))

	# ── 计时 ──
	var t := int(ceil(main.timer_left))
	_text(Vector2(556, 30), str(t), 34, Color(1, 0.3, 0.3) if t <= 10 else Color.WHITE)

	# ── 连击数 ──
	if main.p1.combo >= 2:
		_text(Vector2(120, 130), "%d 连击!" % main.p1.combo, 28, Color(1.0, 0.85, 0.3))
	if main.p2.combo >= 2:
		_text(Vector2(900, 130), "%d 连击!" % main.p2.combo, 28, Color(1.0, 0.55, 0.35))

	# ── 高闪横幅 ──
	if flash_time > 0.0:
		_text(Vector2(576 - float(flash_msg.length()) * 11.0, 240), flash_msg, 36, Color(1, 1, 1, clampf(flash_time, 0.0, 1.0)))

	# ── 操作说明 ──
	var help := "A/D 移动  W 跳跃  J 普攻(连按四段)  K 闪避  L 格挡  U 技能(25气)  I 大招(100气)  1/2/3 换角色  F1 调参  R 重开"
	_text(Vector2(24, 620), help, 15, Color(0.75, 0.78, 0.88))
	_text(Vector2(24, 596), "灰盒原型：方块=角色 黄框=攻击判定 蓝盾=格挡 残影=闪避", 15, Color(0.55, 0.6, 0.72))


func _bar(pos: Vector2, w: float, h: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.08, 0.12, 0.9))
	draw_rect(Rect2(pos, Vector2(w * clampf(ratio, 0.0, 1.0), h)), color)


func _text(pos: Vector2, s: String, size: int, color: Color) -> void:
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
