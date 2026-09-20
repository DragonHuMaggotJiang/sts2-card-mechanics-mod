[CmdletBinding()]
param(
    [string]$JarPath = 'D:\Program Files (x86)\Steam\steamapps\common\SlayTheSpire\desktop-1.0.jar',
    [Parameter(Mandatory = $true)]
    [string]$DecompiledRoot,
    [string]$OutputRoot = (Join-Path $PSScriptRoot '..\docs\reference\sts1')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Read-ZipJson {
    param([System.IO.Compression.ZipArchive]$Archive, [string]$EntryName)
    $entry = $Archive.GetEntry($EntryName)
    if ($null -eq $entry) { throw "JAR entry not found: $EntryName" }
    $reader = [System.IO.StreamReader]::new($entry.Open(), [System.Text.Encoding]::UTF8)
    try { return ($reader.ReadToEnd() | ConvertFrom-Json) }
    finally { $reader.Dispose() }
}

function Get-PropertyValue {
    param([object]$Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-MethodBody {
    param([string]$Text, [string]$MethodName)
    $match = [regex]::Match($Text, "(?ms)^    (?:private|protected|public) static void $([regex]::Escape($MethodName))\([^)]*\) \{(?<body>.*?)^    \}")
    if (-not $match.Success) { throw "Method not found: $MethodName" }
    return $match.Groups['body'].Value
}

function Get-ClassFile {
    param([string]$ClassName)
    $matches = @(Get-ChildItem -LiteralPath $DecompiledRoot -Filter "$ClassName.java" -Recurse -File)
    if ($matches.Count -ne 1) { throw "Expected one source file for $ClassName, found $($matches.Count)" }
    return $matches[0]
}

function Get-FirstIntAssignment {
    param([string]$Text, [string]$Field)
    $match = [regex]::Match($Text, "this\.$([regex]::Escape($Field))\s*=\s*(-?\d+)")
    if ($match.Success) { return [int]$match.Groups[1].Value }
    return $null
}

function Render-CardDescription {
    param([object]$Card)
    $text = [string]$Card.description_zh
    if ($null -ne $Card.base_damage) { $text = $text.Replace('!D!', [string]$Card.base_damage) }
    if ($null -ne $Card.base_block) { $text = $text.Replace('!B!', [string]$Card.base_block) }
    if ($null -ne $Card.base_magic) { $text = $text.Replace('!M!', [string]$Card.base_magic) }
    return $text
}

function Convert-Description {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    return ([string]$Value).Replace(' NL ', "`n").Replace(' [E] ', ' [能量] ')
}

function Escape-MarkdownCell {
    param([object]$Value)
    if ($null -eq $Value) { return '' }
    return ([string]$Value).Replace('|', '\|').Replace("`r", '').Replace("`n", '<br>')
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
try {
    $cardsEn = Read-ZipJson $jar 'localization/eng/cards.json'
    $cardsZh = Read-ZipJson $jar 'localization/zhs/cards.json'
    $monstersEn = Read-ZipJson $jar 'localization/eng/monsters.json'
    $monstersZh = Read-ZipJson $jar 'localization/zhs/monsters.json'
}
finally { $jar.Dispose() }

$cardLibraryPath = Join-Path $DecompiledRoot 'com\megacrit\cardcrawl\helpers\CardLibrary.java'
$cardLibrary = Get-Content -LiteralPath $cardLibraryPath -Raw
$groups = [ordered]@{
    ironclad = 'addRedCards'
    silent = 'addGreenCards'
    defect = 'addBlueCards'
    colorless = 'addColorlessCards'
    curse = 'addCurseCards'
}
$watcherGenerated = @(
    'Beta', 'Insight', 'Miracle', 'Omega', 'Safety', 'Smite', 'ThroughViolence',
    'BecomeAlmighty', 'FameAndFortune', 'LiveForever', 'Expunger'
)
$knownBaseOverrides = @{
    GeneticAlgorithm = @{ base_block=1 }
    RitualDagger = @{ base_damage=15 }
    Shiv = @{ base_damage=4 }
}

$cards = [System.Collections.Generic.List[object]]::new()
foreach ($group in $groups.GetEnumerator()) {
    $body = Get-MethodBody $cardLibrary $group.Value
    foreach ($match in [regex]::Matches($body, 'CardLibrary\.add\(new (?<class>[A-Za-z0-9_]+)\(')) {
        $className = $match.Groups['class'].Value
        if ($className -in $watcherGenerated) { continue }
        $file = Get-ClassFile $className
        $source = Get-Content -LiteralPath $file.FullName -Raw
        $idMatch = [regex]::Match($source, 'public static final String ID\s*=\s*"(?<id>[^"]+)"')
        if (-not $idMatch.Success) { throw "Card ID not found: $($file.FullName)" }
        $id = $idMatch.Groups['id'].Value
        $signature = [regex]::Match($source, 'super\((?<args>.*?AbstractCard\.CardType\.(?<type>\w+).*?AbstractCard\.CardColor\.(?<color>\w+).*?AbstractCard\.CardRarity\.(?<rarity>\w+).*?AbstractCard\.CardTarget\.(?<target>\w+).*?)\);', 'Singleline')
        if (-not $signature.Success) { throw "Card constructor signature not found: $($file.FullName)" }
        $costMatch = [regex]::Match($signature.Groups['args'].Value, '^(?:[^,]+,){3}\s*(?<cost>-?\d+)\s*,')
        $upgradeBodyMatch = [regex]::Match($source, '(?ms)public void upgrade\(\) \{(?<body>.*?)^    \}')
        $firstOverride = $source.IndexOf('@Override', [System.StringComparison]::Ordinal)
        $constructorRegion = if ($firstOverride -ge 0) { $source.Substring(0, $firstOverride) } else { $source }
        $upgradeLines = @()
        if ($upgradeBodyMatch.Success) {
            $upgradeLines = @([regex]::Matches($upgradeBodyMatch.Groups['body'].Value, '(?m)^\s*this\.(?<effect>upgrade(?:Damage|Block|MagicNumber|BaseCost)\([^;]+\)|exhaust\s*=\s*(?:true|false)|ethereal\s*=\s*(?:true|false)|isInnate\s*=\s*(?:true|false)|selfRetain\s*=\s*(?:true|false))\s*;') | ForEach-Object { $_.Groups['effect'].Value })
        }
        $en = Get-PropertyValue $cardsEn $id
        $zh = Get-PropertyValue $cardsZh $id
        $relativeSource = $file.FullName.Substring($DecompiledRoot.TrimEnd('\').Length + 1).Replace('\', '/')
        $card = [ordered]@{
            id = $id
            class_name = $className
            category = $group.Key
            name_en = Get-PropertyValue $en 'NAME'
            name_zh = Get-PropertyValue $zh 'NAME'
            type = $signature.Groups['type'].Value
            color = $signature.Groups['color'].Value
            rarity = $signature.Groups['rarity'].Value
            target = $signature.Groups['target'].Value
            cost = if ($costMatch.Success) { [int]$costMatch.Groups['cost'].Value } else { $null }
            description_en = Convert-Description (Get-PropertyValue $en 'DESCRIPTION')
            description_zh = Convert-Description (Get-PropertyValue $zh 'DESCRIPTION')
            upgrade_description_en = Convert-Description (Get-PropertyValue $en 'UPGRADE_DESCRIPTION')
            upgrade_description_zh = Convert-Description (Get-PropertyValue $zh 'UPGRADE_DESCRIPTION')
            base_damage = Get-FirstIntAssignment $source 'baseDamage'
            base_block = Get-FirstIntAssignment $source 'baseBlock'
            base_magic = Get-FirstIntAssignment $source 'baseMagicNumber'
            exhaust = $constructorRegion -match 'this\.exhaust\s*=\s*true'
            ethereal = $constructorRegion -match 'this\.ethereal\s*=\s*true'
            innate = $constructorRegion -match 'this\.isInnate\s*=\s*true'
            retain = $constructorRegion -match 'this\.selfRetain\s*=\s*true'
            upgrade_effects = $upgradeLines
            source_file = $relativeSource
        }
        if ($knownBaseOverrides.ContainsKey($className)) {
            foreach ($field in $knownBaseOverrides[$className].Keys) { $card[$field] = $knownBaseOverrides[$className][$field] }
        }
        $cards.Add($card)
    }
}

$enemySpecs = @(
    @{ Class='Darkling'; Role='normal'; Notes='三只黑暗幼体的遭遇成员；全体同时死亡前可复活。' },
    @{ Class='OrbWalker'; Role='normal'; Notes='球状行者；也用于神秘圆球事件。' },
    @{ Class='Exploder'; Role='normal'; Notes='形状之一；倒计时结束后爆炸。' },
    @{ Class='Repulsor'; Role='normal'; Notes='形状之一；会向抽牌堆加入眩晕。' },
    @{ Class='Spiker'; Role='normal'; Notes='形状之一；具有反伤。' },
    @{ Class='SpireGrowth'; Role='normal'; Notes='塔之增生。' },
    @{ Class='Transient'; Role='normal'; Notes='瞬息；回合结束按本回合所受伤害降低力量。' },
    @{ Class='Maw'; Role='normal'; Notes='巨口。' },
    @{ Class='JawWorm'; Role='normal'; Notes='第三幕以三只颚虫组成虫群遭遇。' },
    @{ Class='SphericGuardian'; Role='normal_crossover'; Notes='球形守卫；原生于第二幕，但会作为“球形守卫和2个形状”遭遇成员进入第三幕强敌池。' },
    @{ Class='WrithingMass'; Role='normal'; Notes='扭曲团块；受攻击后可能改变意图，寄生效果需特别处理。' },
    @{ Class='GiantHead'; Role='elite'; Notes='大头；缓慢递增易伤，并在后期提高攻击。' },
    @{ Class='Nemesis'; Role='elite'; Notes='倏忽魔；每回合获得1层无实体。' },
    @{ Class='Reptomancer'; Role='elite'; Notes='蛇女；战斗中召唤匕首。' },
    @{ Class='SnakeDagger'; Role='summon'; Notes='蛇女召唤物；不是地图独立遭遇。' },
    @{ Class='AwakenedOne'; Role='boss'; Notes='觉醒者；第一阶段死亡后进入第二阶段。' },
    @{ Class='Cultist'; Role='boss_minion'; Notes='觉醒者战斗的两名随从；本体也出现在第一幕。' },
    @{ Class='TimeEater'; Role='boss'; Notes='时间吞噬者；每打出12张牌时强制结束玩家回合。' },
    @{ Class='Donu'; Role='boss'; Notes='甜圈；与八体共同出场。' },
    @{ Class='Deca'; Role='boss'; Notes='八体；与甜圈共同出场。' }
)

$enemies = [System.Collections.Generic.List[object]]::new()
foreach ($spec in $enemySpecs) {
    $file = Get-ClassFile $spec.Class
    $source = Get-Content -LiteralPath $file.FullName -Raw
    $idMatch = [regex]::Match($source, 'public static final String ID\s*=\s*"(?<id>[^"]+)"')
    if (-not $idMatch.Success) { throw "Monster ID not found: $($file.FullName)" }
    $id = $idMatch.Groups['id'].Value
    $en = Get-PropertyValue $monstersEn $id
    $zh = Get-PropertyValue $monstersZh $id
    $constants = [ordered]@{}
    foreach ($constantMatch in [regex]::Matches($source, '(?m)^\s*(?:private|protected|public) static final int (?<name>[A-Z][A-Z0-9_]*)\s*=\s*(?<value>-?\d+);')) {
        $constants[$constantMatch.Groups['name'].Value] = [int]$constantMatch.Groups['value'].Value
    }
    $relativeSource = $file.FullName.Substring($DecompiledRoot.TrimEnd('\').Length + 1).Replace('\', '/')
    $baseHpMatch = [regex]::Match($source, 'super\(\s*NAME\s*,\s*ID\s*,\s*(?<hp>\d+)\s*,')
    $hpAssignments = @([regex]::Matches($source, 'this\.setHp\(\s*(?<min>\d+)\s*(?:,\s*(?<max>\d+)\s*)?\)') | ForEach-Object {
        if ($_.Groups['max'].Success) { "$($_.Groups['min'].Value)-$($_.Groups['max'].Value)" } else { $_.Groups['min'].Value }
    } | Select-Object -Unique)
    $movesEn = @((Get-PropertyValue $en 'MOVES') | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $movesZh = @((Get-PropertyValue $zh 'MOVES') | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $enemies.Add([ordered]@{
        id = $id
        class_name = $spec.Class
        name_en = Get-PropertyValue $en 'NAME'
        name_zh = Get-PropertyValue $zh 'NAME'
        act = 3
        role = $spec.Role
        base_max_hp = if ($baseHpMatch.Success) { [int]$baseHpMatch.Groups['hp'].Value } else { $null }
        hp_assignments = $hpAssignments
        moves_en = $movesEn
        moves_zh = $movesZh
        numeric_constants = $constants
        notes_zh = $spec.Notes
        source_file = $relativeSource
    })
}

$encounters = @(
    [ordered]@{ id='3 Darklings'; tier='weak,strong'; source='map'; members=@(@{monster_id='Darkling';count=3}); notes_zh='弱敌池权重2；强敌池权重1。' },
    [ordered]@{ id='Orb Walker'; tier='weak'; source='map'; members=@(@{monster_id='Orb Walker';count=1}); notes_zh='弱敌池权重2。' },
    [ordered]@{ id='3 Shapes'; tier='weak'; source='map'; members=@(@{monster_pool=@('Exploder','Repulsor','Spiker');count=3}); notes_zh='候选池中每种形状各放2个并无放回抽取；弱敌池权重2。' },
    [ordered]@{ id='Spire Growth'; tier='strong'; source='map'; members=@(@{monster_id='Serpent';count=1}); notes_zh='强敌池权重1。' },
    [ordered]@{ id='Transient'; tier='strong'; source='map'; members=@(@{monster_id='Transient';count=1}); notes_zh='强敌池权重1。' },
    [ordered]@{ id='4 Shapes'; tier='strong'; source='map'; members=@(@{monster_pool=@('Exploder','Repulsor','Spiker');count=4}); notes_zh='候选池中每种形状各放2个并无放回抽取；强敌池权重1。' },
    [ordered]@{ id='Maw'; tier='strong'; source='map'; members=@(@{monster_id='Maw';count=1}); notes_zh='强敌池权重1。' },
    [ordered]@{ id='Sphere and 2 Shapes'; tier='strong'; source='map'; members=@(@{monster_id='SphericGuardian';count=1},@{monster_pool=@('Exploder','Repulsor','Spiker');count=2}); notes_zh='这里的 Sphere 是球形守卫，不是球状行者；两个形状各自从三种形状中等概率独立生成。强敌池权重1。' },
    [ordered]@{ id='Jaw Worm Horde'; tier='strong'; source='map'; members=@(@{monster_id='JawWorm';count=3}); notes_zh='强敌池权重1。' },
    [ordered]@{ id='Writhing Mass'; tier='strong'; source='map'; members=@(@{monster_id='WrithingMass';count=1}); notes_zh='强敌池权重1。' },
    [ordered]@{ id='Giant Head'; tier='elite'; source='map'; members=@(@{monster_id='GiantHead';count=1}); notes_zh='精英池权重2。' },
    [ordered]@{ id='Nemesis'; tier='elite'; source='map'; members=@(@{monster_id='Nemesis';count=1}); notes_zh='精英池权重2。' },
    [ordered]@{ id='Reptomancer'; tier='elite'; source='map'; members=@(@{monster_id='Reptomancer';count=1}); summons=@(@{monster_id='Dagger';maximum_on_field=4}); notes_zh='精英池权重2；蛇女在战斗中召唤匕首。' },
    [ordered]@{ id='Awakened One'; tier='boss'; source='boss'; members=@(@{monster_id='AwakenedOne';count=1},@{monster_id='Cultist';count=2}); notes_zh='觉醒者和两名邪教徒。' },
    [ordered]@{ id='Time Eater'; tier='boss'; source='boss'; members=@(@{monster_id='TimeEater';count=1}); notes_zh='' },
    [ordered]@{ id='Donu and Deca'; tier='boss'; source='boss'; members=@(@{monster_id='Donu';count=1},@{monster_id='Deca';count=1}); notes_zh='' },
    [ordered]@{ id='2 Orb Walkers'; tier='event'; source='Mysterious Sphere'; members=@(@{monster_id='Orb Walker';count=2}); notes_zh='神秘圆球事件选择战斗后的真实遭遇键；不进入地图普通敌人池。' },
    [ordered]@{ id='Mind Bloom Boss Battle'; tier='event'; source='event'; members=@(); notes_zh='心灵绽放事件会重战一名第一幕Boss；不属于第三幕原生敌怪。' }
)

$expectedCardCounts = @{ ironclad=75; silent=75; defect=75; colorless=45; curse=14 }
foreach ($category in $expectedCardCounts.Keys) {
    $actual = @($cards | Where-Object { $_['category'] -eq $category }).Count
    if ($actual -ne $expectedCardCounts[$category]) {
        throw "Unexpected $category card count: expected $($expectedCardCounts[$category]), found $actual"
    }
}
$duplicateCardIds = @($cards | Group-Object { $_['id'] } | Where-Object Count -gt 1)
if ($duplicateCardIds.Count -gt 0) { throw "Duplicate card IDs: $($duplicateCardIds.Name -join ', ')" }
$duplicateEnemyIds = @($enemies | Group-Object { $_['id'] } | Where-Object Count -gt 1)
if ($duplicateEnemyIds.Count -gt 0) { throw "Duplicate enemy IDs: $($duplicateEnemyIds.Name -join ', ')" }
$enemyIds = @($enemies | ForEach-Object { $_['id'] })
foreach ($encounter in $encounters) {
    foreach ($member in $encounter.members) {
        $references = if ($member.ContainsKey('monster_id')) { @($member.monster_id) } else { @($member.monster_pool) }
        foreach ($reference in $references) {
            if ($reference -notin $enemyIds) { throw "Encounter '$($encounter.id)' references unknown enemy ID '$reference'" }
        }
    }
    if ($encounter.Contains('summons')) {
        foreach ($summon in $encounter.summons) {
            if ($summon.monster_id -notin $enemyIds) { throw "Encounter '$($encounter.id)' references unknown summon ID '$($summon.monster_id)'" }
        }
    }
}

New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
$metadata = [ordered]@{
    schema_version = 1
    source = 'Slay the Spire desktop-1.0.jar and decompiled CardLibrary/monster classes'
    watcher_policy = 'Watcher card pool and Watcher-only generated cards are excluded.'
}
([ordered]@{ metadata=$metadata; cards=@($cards) } | ConvertTo-Json -Depth 12) | Set-Content -LiteralPath (Join-Path $OutputRoot 'cards.json') -Encoding utf8
([ordered]@{ metadata=$metadata; enemies=@($enemies); encounters=$encounters } | ConvertTo-Json -Depth 12) | Set-Content -LiteralPath (Join-Path $OutputRoot 'act3-enemies.json') -Encoding utf8

$cardMd = [System.Collections.Generic.List[string]]::new()
$cardMd.Add('# 《杀戮尖塔》卡牌索引（不含观者）')
$cardMd.Add('')
$cardMd.Add('> 由游戏注册表与中英文本地化自动生成。完整字段、升级参数和英文文本见 `cards.json`。')
foreach ($category in $groups.Keys) {
    $categoryCards = @($cards | Where-Object category -eq $category)
    $cardMd.Add('')
    $cardMd.Add("## $category（$($categoryCards.Count)）")
    $cardMd.Add('')
    $cardMd.Add('| 中文名 | 英文名 / ID | 类型 | 稀有度 | 费用 | 基础数值 | 效果 |')
    $cardMd.Add('|---|---|---:|---:|---:|---|---|')
    foreach ($card in $categoryCards | Sort-Object name_zh, id) {
        $stats = @()
        if ($null -ne $card.base_damage) { $stats += "伤害 $($card.base_damage)" }
        if ($null -ne $card.base_block) { $stats += "格挡 $($card.base_block)" }
        if ($null -ne $card.base_magic) { $stats += "魔法数 $($card.base_magic)" }
        $codeId = [char]96 + [string]$card.id + [char]96
        $cardMd.Add("| $(Escape-MarkdownCell $card.name_zh) | $(Escape-MarkdownCell $card.name_en) ($codeId) | $($card.type) | $($card.rarity) | $($card.cost) | $($stats -join '；') | $(Escape-MarkdownCell (Render-CardDescription $card)) |")
    }
}
$cardMd | Set-Content -LiteralPath (Join-Path $OutputRoot 'cards.md') -Encoding utf8

$enemyMd = [System.Collections.Generic.List[string]]::new()
$enemyMd.Add('# 《杀戮尖塔》第三幕敌怪与遭遇索引')
$enemyMd.Add('')
$enemyMd.Add('## 敌怪')
$enemyMd.Add('')
$enemyMd.Add('| 中文名 | 英文名 / ID | 身份 | 招式名 | 备注 |')
$enemyMd.Add('|---|---|---|---|---|')
foreach ($enemy in $enemies) {
    $codeId = [char]96 + [string]$enemy.id + [char]96
    $enemyMd.Add("| $(Escape-MarkdownCell $enemy.name_zh) | $(Escape-MarkdownCell $enemy.name_en) ($codeId) | $($enemy.role) | $(Escape-MarkdownCell ($enemy.moves_zh -join '；')) | $(Escape-MarkdownCell $enemy.notes_zh) |")
}
$enemyMd.Add('')
$enemyMd.Add('## 遭遇')
$enemyMd.Add('')
$enemyMd.Add('| 内部 ID | 层级 | 来源 | 成员 | 备注 |')
$enemyMd.Add('|---|---|---|---|---|')
foreach ($encounter in $encounters) {
    $members = @($encounter.members | ForEach-Object {
        if ($_.ContainsKey('monster_id')) { "$($_.monster_id) ×$($_.count)" }
        else { "[$($_.monster_pool -join '/') 池] ×$($_.count)" }
    }) -join '；'
    $codeId = [char]96 + [string]$encounter.id + [char]96
    $enemyMd.Add("| $codeId | $($encounter.tier) | $($encounter.source) | $(Escape-MarkdownCell $members) | $(Escape-MarkdownCell $encounter.notes_zh) |")
}
$enemyMd.Add('')
$enemyMd.Add('第四幕的塔矛、塔盾与腐化之心不在本目录中。心灵绽放列为事件遭遇，但其第一幕 Boss 不重复列作第三幕敌怪。')
$enemyMd | Set-Content -LiteralPath (Join-Path $OutputRoot 'act3-enemies.md') -Encoding utf8

Write-Host "Generated $($cards.Count) cards, $($enemies.Count) enemies, and $($encounters.Count) encounters in $OutputRoot"
