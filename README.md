# 2.5DCombatSystem

> Godot 4 的 2.5D 即时战斗系统（3D 场景 + 2D 角色），数据驱动的技能框架。

## 这是什么

一个基于 Godot 的 2.5D 即时战斗框架。场景完全使用 3D，角色使用 2D 精灵（纸片人），实现了带前摇 / 攻击中 / 后摇的完整攻击流程，并尝试用"数据驱动 + 组件化 + 决策集中"的方式组织战斗逻辑。

## 特性

- **三阶段攻击状态机**：前摇 → 攻击中 → 后摇 → 结束，内置于 `BaseCharacter`，由计时器驱动，支持多个命中检测点（CheckPoint）。
- **数据驱动技能**：`CombatAbility`（Resource）定义攻击的总时长、前摇时间、攻击中时间、命中检测点；改数据即改手感。
- **组件化设计（ECS 思路）**：
  - `AttackComponent`（Area3D）：攻击判定范围，负责命中检测（`check_hit`）；
  - `DynamicBoxCollision`：AttackComponent 下的动态碰撞盒，可动态调整尺寸；
  - `CombatResourceComponent`：技能资源库，持有技能数组；
  - 组件之间互不感知，决策统一收敛在 `BaseCharacter`，职责清晰、耦合低。
- **动画系统**：`AnimationTree` 状态机 + `Ability` 过渡节点，类似 UE 的动画蓝图 / 蒙太奇；`play_montage` 通过 `transition_request` 切换动画。
- **单向依赖**：Character 不需要知道 Controller，Controller 可直接调用 Character 的接口。

## 快速开始

1. 将 `addons/wuxiacombatsystem`（以及演示所需的 `addons/charactercontroller2.5D`）复制到你的项目；
2. 在项目设置中启用插件；
3. 打开 `scenes/character_test.tscn` 运行：WASD 移动，左键攻击。

输入映射：`up / down / left / right / jump / attack`。

## 如何配置一个技能

1. 在 `resources/wuxia_abilities/` 下新建 `CombatAbility` 资源；
2. 填写参数：`total_duration`（总时长）、`front_time`（前摇结束时间点）、`running_time`（攻击中结束时间点）、`hit_check_points`（命中检测时间点，如 `[0.4]` 表示 0.4 秒处判定一次）；
3. 把资源拖入角色的 `CombatResourceComponent.current_abilities` 数组；
4. 代码中调用 `light_attack()`，即可按 index 读取技能数据并执行。

## 架构

```
BaseCharacter（决策 / 时序）
  ├── AttackComponent          （Area3D 命中判定）
  │   └── DynamicBoxCollision  （动态碰撞盒，属于攻击组件）
  ├── CombatResourceComponent  （技能资源库）
  └── Animator                 （AnimationTree 动画驱动）
```

设计要点：角色拥有攻击时序（状态机 + 计时器），组件只提供能力（命中检测、动画播放），数据存放在 Resource 中——组件向上提供数据和函数，决策由角色统一管理，避免组件之间相互耦合。

## 暂时搁置的技术点

- [ ] 更加灵活的碰撞体积（Godot并没有自带可动态配置的碰撞箱，每次修改尺寸都必须修改resouce，需要读写磁盘，比较麻烦）

## 许可证

- 代码：MIT
- 演示素材（`assets/warrior/`）：版权归原作者所有，请遵守原素材许可；如需商用请自行替换。

## 交流

如果你对 2.5D 战斗框架或 Godot 游戏开发感兴趣，欢迎提 Issue 交流。
