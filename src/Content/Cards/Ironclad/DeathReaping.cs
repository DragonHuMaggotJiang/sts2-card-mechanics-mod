using BaseLib.Utils;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Entities.Cards;
using MegaCrit.Sts2.Core.GameActions.Multiplayer;
using MegaCrit.Sts2.Core.Localization.DynamicVars;
using MegaCrit.Sts2.Core.Models.CardPools;
using MegaCrit.Sts2.Core.ValueProps;
using Sts2CardMechanicsMod.Content.Cards.Shared;

namespace Sts2CardMechanicsMod.Content.Cards.Ironclad;

/// <summary>
/// The Ironclad rare from the first game: damage every enemy, then heal for the
/// total HP actually removed by the attack.
/// </summary>
[Pool(typeof(IroncladCardPool))]
public sealed class DeathReaping : ModCard
{
    protected override IEnumerable<DynamicVar> CanonicalVars =>
    [
        new DamageVar(4m, ValueProp.Move),
    ];

    public override IEnumerable<CardKeyword> CanonicalKeywords =>
    [
        CardKeyword.Exhaust,
    ];

    public DeathReaping()
        : base(2, CardType.Attack, CardRarity.Rare, TargetType.AllEnemies)
    {
    }

    protected override async Task OnPlay(PlayerChoiceContext choiceContext, CardPlay cardPlay)
    {
        var combatState = CombatState
            ?? throw new InvalidOperationException("Death Reaping cannot be played outside combat.");

        var attack = await DamageCmd
            .Attack(DynamicVars.Damage.BaseValue)
            .FromCard(this, cardPlay)
            .TargetingAllOpponents(combatState)
            .WithHitFx("vfx/vfx_giant_horizontal_slash")
            .Execute(choiceContext);

        decimal healing = attack.Results
            .SelectMany(hit => hit)
            .Sum(result => result.UnblockedDamage);

        if (healing > 0m)
        {
            await CreatureCmd.Heal(Owner.Creature, healing);
        }
    }

    protected override void OnUpgrade()
    {
        DynamicVars.Damage.UpgradeValueBy(1m);
    }
}
