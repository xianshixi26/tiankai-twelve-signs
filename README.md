# 《天开·十二相斗》 TWELVE SIGNS

> 十二生肖拟人武者 · 像素横版格斗游戏 Demo —— 单人开发（1 人 + AI 工具链）作品集项目

**A 2D pixel-art fighting game demo** featuring anthropomorphic Chinese Zodiac warriors. Built with Godot 4.7, solo-developed with an AI-assisted pipeline.

![gameplay](docs/screenshots/gameplay.gif)

## ✨ 游戏特色

- **四段重势连击**：连按普攻打出四段连招，末段大动作击飞收招，顿帧/震屏/闪白全套打击感
- **武器定义角色**：子鼠·机关弩首发（弩的装填机制），11 生肖扩展库就绪
- **攻防博弈**：闪避无敌帧、完美格挡弹刀、气槽技能/大招
- **典籍人设**：角色源自《诗经》《周易》《韩诗外传》等典籍的生肖性格（鼠咬天开）

## 🎮 操作（支持键盘 / 手柄）

| 操作 | 键盘 | 手柄 |
|---|---|---|
| 移动 | A / D | 左摇杆 |
| 跳跃 | W / 空格 | A |
| 普攻（四段连按） | J | X |
| 闪避 | K | RB |
| 格挡（前 5 帧=完美格挡） | L（按住） | LB |
| 技能（25 气） | U | Y |
| 大招（100 气） | I | B |

## 🛠 技术栈

- **引擎**：Godot 4.7（GDScript，gl_compatibility 渲染）
- **架构**：意图输入 → 确定性 60fps 战斗核心（为将来 PVP 联机的帧同步预留）
- **管线**：AI 生成像素动画（22 条 / 368 帧）→ 人工修帧对齐 → SpriteFrames → 状态机挂钩
- **手感**：全部参数热调（F1 调参面板），帧数据驱动的命中判定

## 📄 开发文档链

| 文档 | 内容 |
|---|---|
| [DEMO-进度看板.md](DEMO-进度看板.md) | 垂直切片任务板 + 实时进度条（S0~S17） |
| [docs/GDD-v2.0.md](docs/GDD-v2.0.md) | 游戏策划书（Demo 执行版） |
| [docs/PRD.md](docs/PRD.md) | 需求文档（55 条用户故事 + 12 模块） |
| [灰盒实现说明.md](灰盒实现说明.md) | 灰盒原型实现与手感参数 |

## 🗺 路线图

- ✅ 核心战斗灰盒（连击/闪避/格挡/技能/大招/AI/KO）
- ▶ 角色动画接入 → 打击特效 → 音频 → 界面 → 发布
- 🔮 扩展：11 生肖全角色、特殊技、PVP 联机（架构已预留）

## 📜 素材说明

像素素材由 AI 生成（Meowa Studio 付费档，商用所有权归开发者）+ 人工修帧；生成资产授权凭证见 [docs/evidence/](docs/evidence/)。本项目为非商业作品集 Demo。
