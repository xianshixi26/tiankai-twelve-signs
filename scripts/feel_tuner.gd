class_name FeelTuner
extends CanvasLayer

## 运行时手感调参面板（F1 开关）：所有参数热调即时生效，对应 GameConfig 字段

var main
var font: SystemFont


func setup(p_main) -> void:
	main = p_main
	visible = false
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Segoe UI"])

	var panel := PanelContainer.new()
	panel.position = Vector2(20.0, 90.0)
	panel.custom_minimum_size = Vector2(330.0, 500.0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "手感调参面板（F1 开关，即时生效）"
	title.add_theme_font_override("font", font)
	vbox.add_child(title)

	_add_slider(vbox, "移动极速", "move_speed", 120.0, 480.0)
	_add_slider(vbox, "加速度", "accel", 1000.0, 4000.0)
	_add_slider(vbox, "急停减速度", "stop_decel", 1500.0, 5000.0)
	_add_slider(vbox, "跳跃初速", "jump_velocity", -1000.0, -400.0)
	_add_slider(vbox, "重力", "gravity", 1200.0, 3500.0)
	_add_slider(vbox, "轻击顿帧(s)", "hitstop_short", 0.02, 0.15)
	_add_slider(vbox, "重击顿帧(s)", "hitstop_heavy", 0.05, 0.25)
	_add_slider(vbox, "击退速度", "knockback_speed", 150.0, 500.0)
	_add_slider(vbox, "震屏幅度", "shake_amp", 2.0, 20.0)
	_add_slider(vbox, "伤害倍率", "damage_mult", 0.5, 2.0)
	_add_slider(vbox, "闪避无敌起(s)", "dodge_iframe_start", 0.0, 0.15)
	_add_slider(vbox, "闪避无敌止(s)", "dodge_iframe_end", 0.1, 0.33)
	_add_slider(vbox, "完美格挡窗(s)", "perfect_block_window", 0.03, 0.2)
	_add_slider(vbox, "AI 攻击间隔(s)", "ai_attack_interval", 0.3, 2.0)
	_add_slider(vbox, "AI 格挡概率", "ai_block_chance", 0.0, 0.8)
	_add_slider(vbox, "AI 闪避概率", "ai_dodge_chance", 0.0, 0.8)


func _add_slider(parent: Control, label: String, prop: String, min_v: float, max_v: float) -> void:
	var row := VBoxContainer.new()
	parent.add_child(row)

	var lab := Label.new()
	lab.add_theme_font_override("font", font)
	lab.text = "%s: %.2f" % [label, float(main.cfg.get(prop))]
	row.add_child(lab)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = (max_v - min_v) / 200.0
	slider.value = float(main.cfg.get(prop))
	slider.value_changed.connect(_on_changed.bind(prop, lab, label))
	row.add_child(slider)


func _on_changed(value: float, prop: String, lab: Label, label: String) -> void:
	main.cfg.set(prop, value)
	lab.text = "%s: %.2f" % [label, value]
