class_name GameConfig
extends RefCounted

## 手感参数：全部可热调（F1 调参面板），初始值按 GAME-FEEL.md 换算到像素尺度（1u≈32px）

# ── 移动 ──────────────────────────────────────────
var move_speed := 280.0          # 移动极速 px/s（可调 150~480）
var accel := 2400.0              # 起步加速度 px/s²（1000~4000）
var stop_decel := 3200.0         # 急停减速度 px/s²（1500~5000）

# ── 跳跃 ──────────────────────────────────────────
var jump_velocity := -720.0      # 跳跃初速 px/s（-1000~-400）
var gravity := 2100.0            # 重力 px/s²（1200~3500）
var jump_buffer := 0.15          # 跳跃输入缓冲 s

# ── 打击反馈（手感核心）────────────────────────────
var hitstop_short := 0.06        # 轻击顿帧 s（0.02~0.15）
var hitstop_heavy := 0.10        # 重击顿帧 s
var hitstop_ultimate := 0.15     # 大招顿帧 s
var knockback_speed := 320.0     # 击退速度 px/s（150~500）
var knockback_decay := 1400.0    # 击退衰减 px/s²
var hit_flash := 0.08            # 受击闪白 s
var shake_amp := 8.0             # 震屏幅度 px（2~20）
var shake_decay := 30.0          # 震屏衰减 px/s
var damage_mult := 1.0           # 全局伤害倍率（0.5~2.0，调参用）

# ── 连段与防御 ────────────────────────────────────
var attack_buffer := 0.20        # 攻击输入缓冲 s（≈12 帧）
var dodge_time := 0.33           # 闪避全程 s
var dodge_iframe_start := 0.05   # 无敌帧起点 s
var dodge_iframe_end := 0.23     # 无敌帧终点 s
var dodge_distance := 180.0      # 闪避位移距离 px
var block_reduction := 0.7       # 格挡减伤比例（0.5~0.85）
var perfect_block_window := 0.083 # 完美格挡窗口 s（≈5 帧）
var combo_window := 2.0          # 连击计数保持时间 s

# ── AI 难度参数（闯关难度就调这四行）────────────────
var ai_attack_interval := 0.85   # 攻击间隔基准 s
var ai_block_chance := 0.22      # 格挡概率（受击反应）
var ai_dodge_chance := 0.15      # 闪避概率（受击反应）
var ai_reaction := 0.25          # 反应时间 s
