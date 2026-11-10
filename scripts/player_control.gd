class_name PlayerControl
extends RefCounted

## 玩家输入采集：每物理帧读取一次，输出统一意图结构（与 AI 输出同构）
static func read() -> Dictionary:
	return {
		"move_x": Input.get_axis("move_left", "move_right"),
		"jump": Input.is_action_just_pressed("jump"),
		"attack": Input.is_action_just_pressed("attack"),
		"dodge": Input.is_action_just_pressed("dodge"),
		"block": Input.is_action_pressed("block"),
		"skill": Input.is_action_just_pressed("skill"),
		"ultimate": Input.is_action_just_pressed("ultimate"),
	}
