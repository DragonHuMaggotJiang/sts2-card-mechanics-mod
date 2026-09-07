using BaseLib.Utils;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Entities.Cards;
using MegaCrit.Sts2.Core.GameActions.Multiplayer;
using MegaCrit.Sts2.Core.HoverTips;
using MegaCrit.Sts2.Core.Localization.DynamicVars;
using MegaCrit.Sts2.Core.Models.CardPools;
using MegaCrit.Sts2.Core.Models.Powers;
using Sts2CardMechanicsMod.Content.Cards.Shared;

namespace Sts2CardMechanicsMod.Content.Cards.Ironclad;

/// <summary>
/// Grants Strength when the selected enemy has any attacking component in its current intent.
/// MonsterModel.IntendsToAttack intentionally supports STS2 composite intents such as attack + buff.
/// </summary>
[Pool(typeof(IroncladCardPool))]
public sealed class SpotWeakness : ModCard
{
    protected override bool ShouldGlowGoldInternal =>
        CombatState?.HittableEnemies.Any(enemy => enemy.Monster?.IntendsToAttack == true) == true;

    protected override IEnumerable<DynamicVar> CanonicalVars =>
    [
        new PowerVar<StrengthPower>(3m),
    ];

    protected override IEnumerable<IHoverTip> ExtraHoverTips =>
    [
        HoverTipFactory.FromPower<StrengthPower>(),
    ];

    public SpotWeakness()
        : base(1, CardType.Skill, CardRarity.Uncommon, TargetType.AnyEnemy)
    {
    }

    protected override async Task OnPlay(PlayerChoiceContext choiceContext, CardPlay cardPlay)
    {
        ArgumentNullException.ThrowIfNull(cardPlay.Target);

        if (cardPlay.Target.Monster?.IntendsToAttack == true)
        {
            await PowerCmd.Apply<StrengthPower>(
                choiceContext,
                Owner.Creature,
                DynamicVars.Strength.BaseValue,
                Owner.Creature,
                this);
        }
    }

    protected override void OnUpgrade()
    {
        DynamicVars.Strength.UpgradeValueBy(1m);
    }
}
