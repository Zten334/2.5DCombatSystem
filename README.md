# 2.5DCombatSystem

> Godot 4 的 2.5D 即时战斗系统（3D 场景 + 2D 角色），数据驱动的技能框架。

B站讲解视频（bushi）链接：https://www.bilibili.com/video/BV17puE6kEfx/#reply117046801074676

## 这是什么

一个基于 Godot 的 2.5D 即时战斗框架。场景3D，角色2D，实现了带前摇 / 攻击中 / 后摇的完整攻击流程，并尝试用"数据驱动 + 组件化 + 决策集中"的方式组织战斗逻辑。

## 特性

- **三阶段攻击状态机**：前摇 → 攻击中 → 后摇 → 结束，内置于 `BaseCharacter`，由计时器驱动，支持多个命中检测点（CheckPoint）。
- **数据驱动技能**：攻击数据由 `AttackComponent` 内的 `AbilityInfo`（总时长、前摇时间、攻击中时间、命中检测点）持有，`CombatAbility`（Resource）作为数据源在初始化阶段写入；改数据即改手感。
- **组件化设计（ECS 思路）**：
  - `AttackComponent`（Area3D）：攻击核心组件，持有攻击信息（`AbilityInfo`，按普通攻击 / 能力一 / 二 / 三分组），通过 `excute_attack(index)` 返回对应的攻击数据，并负责命中判定（`check_hit`）；
  - `DynamicBoxCollision`：AttackComponent 下的动态碰撞盒，可动态调整尺寸；
  - `CombatResourceComponent`：技能资源库（暂时保留，攻击数据的读取已拆离至 AttackComponent）；
  - 组件之间互不感知，决策统一收敛在 `BaseCharacter`，职责清晰、耦合低。
- **动画系统**：`AnimationTree` 状态机 + `Ability` 过渡节点，类似 UE 的动画蓝图 / 蒙太奇；`play_montage` 通过 `transition_request` 切换动画。
- **单向依赖**：Character 不需要知道 Controller，Controller 可直接调用 Character 的接口。

## 快速开始

1. 将 `addons/wuxiacombatsystem`（以及演示所需的 `addons/charactercontroller2.5D`）复制到你的项目；
2. 在项目设置中启用插件；
3. 打开 `scenes/character_test.tscn` 运行：WASD 移动，左键攻击。

输入映射：`up / down / left / right / jump / attack`。

## 如何配置一个技能

攻击数据的流转：`CombatAbility` 资源（数据源）→ 初始化时写入 `AttackComponent` 的 `AbilityInfo` → 运行时由 `BaseCharacter` 从 `AttackComponent` 读取并执行。

1. 在 `AttackComponent.init_ability_info()` 中初始化攻击信息：创建 `AbilityInfo`，填写 `total_duration`（总时长）、`front_time`（前摇结束时间点）、`running_time`（攻击中结束时间点）、`hit_check_points`（命中检测时间点，如 `[0.4]` 表示 0.4 秒处判定一次），然后加入对应的分组数组（如 `normal_attack_info`）；
2. 攻击时调用 `BaseCharacter.light_attack()`，内部通过 `attack_component.excute_attack(index)` 读取攻击数据：index 0 为普通攻击，1 / 2 / 3 对应能力一 / 二 / 三，返回对应的 `AbilityInfo` 后按数据驱动攻击流程；
3. 命中判定由 `AttackComponent.check_hit()` 完成，对重叠对象调用 `hurt()`。

> 注意：目前 `init_ability_info()` 中还是硬编码的示例数据（`total_duration = 0.8`、`front_time = 0.1`、`running_time = 0.6`），后续计划由 `CombatAbility` 资源在加载阶段写入。旧的 `CombatResourceComponent`（`current_abilities` + `get_ability()`）暂时保留，之后会逐步移除。

## 架构

```
BaseCharacter（决策 / 时序）
  ├── AttackComponent          （攻击信息 AbilityInfo + 派生选择 excute_attack + 命中判定 check_hit）
  │   ├── AbilityInfo          （total_duration / front_time / running_time / hit_check_points）
  │   └── DynamicBoxCollision  （动态碰撞盒，属于攻击组件）
  ├── CombatResourceComponent  （技能资源库，暂时保留）
  └── Animator                 （AnimationTree 动画驱动）
```

设计要点：角色拥有攻击时序（状态机 + 计时器），组件只提供能力（攻击数据、命中检测、动画播放），数据存放在Resource中，游戏开始时加载（这个还没做）——组件向上提供数据和函数，决策由角色管理。

## 更新记录

- **V0.1.1**：将攻击信息的读取彻底从 `CombatResourceComponent` 拆离。现在 `AttackComponent.excute_attack(index)` 直接返回 `AbilityInfo`，`BaseCharacter` 攻击时只需要依赖 `AttackComponent`。
- **V0.1Alpha**：`AttackComponent` 新增攻击信息参数（`AbilityInfo` 与按技能分组的数据），使其与 `CombatResourceComponent` 职责分离——前者负责游戏中的判定，后者负责加载阶段的数据写入。

## 暂时搁置的技术点

- [ ] 更加灵活的碰撞体积（Godot 并没有自带可动态配置的碰撞箱，每次修改尺寸都必须修改 resource，需要读写磁盘，比较麻烦）
- [ ] 指数上升的加速效果和摩擦力系统，优化手感，而非目前的恒定加速

## 许可证

- 代码：MIT
- 演示素材（`assets/warrior/`）：版权归原作者所有，请遵守原素材许可；如需商用请自行替换。

## 交流

如果你对 2.5D 战斗框架或 Godot 游戏开发感兴趣，欢迎提 Issue 交流。
