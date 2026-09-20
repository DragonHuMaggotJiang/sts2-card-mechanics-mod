# 《杀戮尖塔》第三幕敌怪与遭遇索引

## 敌怪

| 中文名 | 英文名 / ID | 身份 | 招式名 | 备注 |
|---|---|---|---|---|
| 小黑 | Darkling (`Darkling`) | normal | 啊呜！啊呜！ | 三只黑暗幼体的遭遇成员；全体同时死亡前可复活。 |
| 圆球行者 | Orb Walker (`Orb Walker`) | normal | 强化 | 球状行者；也用于神秘圆球事件。 |
| 爆炸机 | Exploder (`Exploder`) | normal |  | 形状之一；倒计时结束后爆炸。 |
| 反冲机 | Repulsor (`Repulsor`) | normal |  | 形状之一；会向抽牌堆加入眩晕。 |
| 钉刺机 | Spiker (`Spiker`) | normal |  | 形状之一；具有反伤。 |
| 塔内增生组织 | Spire Growth (`Serpent`) | normal |  | 塔之增生。 |
| 倏忽魔 | Transient (`Transient`) | normal |  | 瞬息；回合结束按本回合所受伤害降低力量。 |
| 巨口 | The Maw (`Maw`) | normal |  | 巨口。 |
| 大颚虫 | Jaw Worm (`JawWorm`) | normal | 咆哮；抽打 | 第三幕以三只颚虫组成虫群遭遇。 |
| 圆球守护者 | Spheric Guardian (`SphericGuardian`) | normal_crossover |  | 球形守卫；原生于第二幕，但会作为“球形守卫和2个形状”遭遇成员进入第三幕强敌池。 |
| 扭曲团块 | Writhing Mass (`WrithingMass`) | normal |  | 扭曲团块；受攻击后可能改变意图，寄生效果需特别处理。 |
| 大脑袋 | Giant Head (`GiantHead`) | elite |  | 大头；缓慢递增易伤，并在后期提高攻击。 |
| 天罚 | Nemesis (`Nemesis`) | elite |  | 倏忽魔；每回合获得1层无实体。 |
| 拜蛇术士 | Reptomancer (`Reptomancer`) | elite |  | 蛇女；战斗中召唤匕首。 |
| 匕首 | Dagger (`Dagger`) | summon |  | 蛇女召唤物；不是地图独立遭遇。 |
| 觉醒者 | Awakened One (`AwakenedOne`) | boss | 灵魂攻击；黑暗回音；净化；污泥 | 觉醒者；第一阶段死亡后进入第二阶段。 |
| 邪教徒 | Cultist (`Cultist`) | boss_minion | 念咒 | 觉醒者战斗的两名随从；本体也出现在第一幕。 |
| 时间吞噬者 | Time Eater (`TimeEater`) | boss |  | 时间吞噬者；每打出12张牌时强制结束玩家回合。 |
| 甜圈 | Donu (`Donu`) | boss | 力量之环 | 甜圈；与八体共同出场。 |
| 八体 | Deca (`Deca`) | boss |  | 八体；与甜圈共同出场。 |

## 遭遇

| 内部 ID | 层级 | 来源 | 成员 | 备注 |
|---|---|---|---|---|
| `3 Darklings` | weak,strong | map | Darkling ×3 | 弱敌池权重2；强敌池权重1。 |
| `Orb Walker` | weak | map | Orb Walker ×1 | 弱敌池权重2。 |
| `3 Shapes` | weak | map | [Exploder/Repulsor/Spiker 池] ×3 | 候选池中每种形状各放2个并无放回抽取；弱敌池权重2。 |
| `Spire Growth` | strong | map | Serpent ×1 | 强敌池权重1。 |
| `Transient` | strong | map | Transient ×1 | 强敌池权重1。 |
| `4 Shapes` | strong | map | [Exploder/Repulsor/Spiker 池] ×4 | 候选池中每种形状各放2个并无放回抽取；强敌池权重1。 |
| `Maw` | strong | map | Maw ×1 | 强敌池权重1。 |
| `Sphere and 2 Shapes` | strong | map | SphericGuardian ×1；[Exploder/Repulsor/Spiker 池] ×2 | 这里的 Sphere 是球形守卫，不是球状行者；两个形状各自从三种形状中等概率独立生成。强敌池权重1。 |
| `Jaw Worm Horde` | strong | map | JawWorm ×3 | 强敌池权重1。 |
| `Writhing Mass` | strong | map | WrithingMass ×1 | 强敌池权重1。 |
| `Giant Head` | elite | map | GiantHead ×1 | 精英池权重2。 |
| `Nemesis` | elite | map | Nemesis ×1 | 精英池权重2。 |
| `Reptomancer` | elite | map | Reptomancer ×1 | 精英池权重2；蛇女在战斗中召唤匕首。 |
| `Awakened One` | boss | boss | AwakenedOne ×1；Cultist ×2 | 觉醒者和两名邪教徒。 |
| `Time Eater` | boss | boss | TimeEater ×1 |  |
| `Donu and Deca` | boss | boss | Donu ×1；Deca ×1 |  |
| `2 Orb Walkers` | event | Mysterious Sphere | Orb Walker ×2 | 神秘圆球事件选择战斗后的真实遭遇键；不进入地图普通敌人池。 |
| `Mind Bloom Boss Battle` | event | event |  | 心灵绽放事件会重战一名第一幕Boss；不属于第三幕原生敌怪。 |

第四幕的塔矛、塔盾与腐化之心不在本目录中。心灵绽放列为事件遭遇，但其第一幕 Boss 不重复列作第三幕敌怪。
