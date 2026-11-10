"""S1 动画拆帧管线：22 条动画 WebP → PNG 序列 + 帧时长元数据
用法：python split_anim.py   （产出 assets/rat/<动作>/<帧号>.png + anim_meta.json）
"""
import re
import json
from pathlib import Path
from PIL import Image, ImageSequence

SRC = Path(r"C:\Users\ASUS\Downloads\meowart-images-job_a6656c5216c2422c98e1759081734101")
DST = Path(r"D:\deepseekwork\zodiac-fight\assets\rat")

# 序号 → 动作映射（依据资产盘点的逐帧目测结果；a/b 为两个生成变体）
ACTION_MAP = {
    "01": "slash_a", "02": "slash_b",
    "03": "slash64_a", "04": "slash64_b",
    "05": "shoot_a", "06": "shoot_b",
    "07": "burst_a", "08": "burst_b",
    "09": "aim_a", "10": "aim_b",
    "11": "dodge_a", "12": "dodge_b",
    "13": "skill_a", "14": "skill_b",
    "15": "ultimate_a", "16": "ultimate_b",
    "17": "idle_a", "18": "idle_b",
    "19": "run_a", "20": "run_b",
    "21": "walk_a", "22": "walk_b",
}

meta = {}
total = 0
for f in sorted(SRC.glob("*.webp")):
    m = re.match(r"(\d{2})_image-\d{2}_.*\.webp$", f.name)
    if not m:
        continue
    action = ACTION_MAP.get(m.group(1))
    if not action:
        continue
    out_dir = DST / action
    out_dir.mkdir(parents=True, exist_ok=True)
    img = Image.open(f)
    durations = []
    n = 0
    for i, frame in enumerate(ImageSequence.Iterator(img)):
        frame.convert("RGBA").save(out_dir / f"{i:03d}.png")
        durations.append(int(frame.info.get("duration", 100)))
        n += 1
    meta[action] = {
        "source": f.name,
        "frames": n,
        "size": list(img.size),
        "durations_ms": durations,
    }
    print(f"{f.name} -> {action}: {n} 帧 {img.size[0]}x{img.size[1]}")
    total += n

(DST / "anim_meta.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8")
print(f"TOTAL: {total} 帧, {len(meta)} 条动画 -> {DST}")
