# 《杀戮尖塔 1》设计参考库

这套资料用于后续把一代卡牌、敌怪或机制迁移到本 Mod。它是设计与实现参考，不会在运行时被 Mod 加载。

## 文件

- `cards.json`：284 张非观者卡牌的机器可读数据。
- `cards.md`：按铁甲战士、静默猎手、故障机器人、无色牌和诅咒分类的中文速查表。
- `act3-enemies.json`：第三幕相关敌怪（含跨幕成员）、数值常量和遭遇组成。
- `act3-enemies.md`：第三幕敌怪与遭遇的中文速查表。

JSON 是后续代码生成、差异检查和 AI Agent 检索的权威入口；Markdown 只用于人工浏览。

## 收录口径

卡牌以游戏 `CardLibrary` 的实际注册列表为准，而不是按 JAR 中的类名扫描，因此不会混入 `Allocate`、`AxeKick` 等废弃或测试卡。收录铁甲战士、静默猎手、故障机器人、通用无色牌、状态牌、特殊生成牌与诅咒；排除观者牌池，以及 `Insight`、`Miracle`、`Smite`、`Expunger` 等仅服务于观者机制的衍生牌。

第三幕以 `TheBeyond` 的弱敌、强敌、精英和 Boss 池为准，并额外标出：

- 蛇女召唤的匕首与觉醒者携带的邪教徒；
- “球形守卫和2个形状”中跨幕出现的二层球形守卫；
- “神秘圆球”的两只球状行者；
- “心灵绽放”的第一幕 Boss 重战（仅作为事件遭遇说明）；
- 明确排除第四幕的塔矛、塔盾与腐化之心。

敌怪的 `numeric_constants` 保留反编译类中的命名数值，例如基础伤害、进阶伤害、格挡量和生命值。具体行动概率、进阶等级分支和状态机仍应在正式移植某个敌人时对照其游戏类复核。

## 重新生成

生成器不会提交或复制游戏 JAR、图片、音频及反编译源码。需要本机拥有《杀戮尖塔》，并先用 CFR 将以下类反编译到一个临时目录：

- `CardLibrary`；
- `cards.red`、`cards.green`、`cards.blue`、`cards.colorless`、`cards.curses`、`cards.status`、`cards.tempCards`；
- `TheBeyond`、`MonsterHelper`、`monsters.beyond`；
- `monsters.exordium.JawWorm`、`monsters.exordium.Cultist` 与 `monsters.city.SphericGuardian`。

然后在仓库根目录运行：

```powershell
.\scripts\Extract-Sts1Reference.ps1 `
  -JarPath 'D:\Program Files (x86)\Steam\steamapps\common\SlayTheSpire\desktop-1.0.jar' `
  -DecompiledRoot 'D:\temp\sts1-src'
```

生成结果按注册顺序稳定输出。若游戏版本更新，重新生成后应人工抽查 `Reaper`、`Limit Break`、`Spot Weakness`、`Apparition`、`Ascenders Bane`、`Nemesis`、`Reptomancer` 与 `Awakened One`。

## 后续扩展原则

- 不把整个资料库映射成一个巨型注册器；按卡包或机制选取需要实现的条目。
- 一代卡牌文本只能作为语义参考。二代存在多人目标、同一敌人同时攻击和强化等差异，行为实现必须使用二代 API 重新建模。
- 为敌怪补全完整行动状态机时，新增结构化字段并更新生成器，避免只在 Markdown 中写不可检索的说明。
