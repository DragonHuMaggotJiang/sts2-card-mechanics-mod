using BaseLib.Abstracts;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Entities.Cards;
using MegaCrit.Sts2.Core.Entities.Creatures;
using MegaCrit.Sts2.Core.Entities.Powers;
using MegaCrit.Sts2.Core.GameActions.Multiplayer;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Models.Powers;
using MegaCrit.Sts2.Core.ValueProps;
using Sts2CardMechanicsMod.Core;

namespace Sts2CardMechanicsMod.Mechanics.Ikkyuuni;

/// <summary>
/// Converts the owner's post-block HP loss into Doom while empowering the owner's other teammates.
/// The pending fields bridge the game's synchronous HP-loss modifier and its awaited post-hook.
/// </summary>
public sealed class IkkyuuniFormPower : CustomPowerModel
{
    public const decimal AllyDamageMultiplier = 3m;
    public const decimal IncomingDamageMultiplier = 1.75m;
    public const decimal TeamDoomAmount = 99999m;

    private decimal _pendingDoom;
    private Creature? _pendingDealer;
    private CardModel? _pendingCardSource;
    private bool _doomThresholdTriggered;

    public override PowerType Type => PowerType.Buff;

    public override PowerStackType StackType => PowerStackType.Single;

    public override string CustomPackedIconPath =>
        $"{ModConstants.ResourceRoot}/images/powers/ikkyuuni_form_power.png";

    public override string CustomBigIconPath =>
        $"{ModConstants.ResourceRoot}/images/powers/big/ikkyuuni_form_power.png";

    public override decimal ModifyDamageMultiplicative(
        Creature? target,
        decimal amount,
        ValueProp props,
        Creature? dealer,
        CardModel? cardSource,
        CardPlay? cardPlay)
    {
        decimal multiplier = 1m;

        if (target == Owner)
        {
            multiplier *= IncomingDamageMultiplier;
        }

        if (dealer is not null && dealer != Owner && IsOwnersTeammate(dealer))
        {
            multiplier *= AllyDamageMultiplier;
        }

        return multiplier;
    }

    public override decimal ModifyHpLostBeforeOsty(
        Creature target,
        decimal amount,
        ValueProp props,
        Creature? dealer,
        CardModel? cardSource)
    {
        if (target != Owner || amount <= 0m)
        {
            return amount;
        }

        // CreatureCmd awaits AfterModifyingHpLostBeforeOsty before it subtracts HP. Storing the
        // latest value keeps this synchronous hook side-effect free while preserving the amount.
        _pendingDoom = amount;
        _pendingDealer = dealer;
        _pendingCardSource = cardSource;
        return 0m;
    }

    public override async Task AfterModifyingHpLostBeforeOsty()
    {
        decimal doomToApply = _pendingDoom;
        Creature? dealer = _pendingDealer;
        CardModel? cardSource = _pendingCardSource;
        ClearPendingConversion();

        if (doomToApply <= 0m || Owner.IsDead)
        {
            return;
        }

        PlayerChoiceContext context = new ThrowingPlayerChoiceContext();
        await PowerCmd.Apply<DoomPower>(
            context,
            Owner,
            doomToApply,
            dealer,
            cardSource);
    }

    public override async Task AfterApplied(Creature? applier, CardModel? cardSource)
    {
        await CheckDoomThreshold(new ThrowingPlayerChoiceContext());
    }

    public override async Task AfterPowerAmountChanged(
        PlayerChoiceContext choiceContext,
        PowerModel power,
        decimal delta,
        Creature? applier,
        CardModel? cardSource)
    {
        if (power is DoomPower && power.Owner == Owner)
        {
            await CheckDoomThreshold(choiceContext);
        }
    }

    private async Task CheckDoomThreshold(PlayerChoiceContext choiceContext)
    {
        DoomPower? doom = Owner.GetPower<DoomPower>();

        if (doom is null || doom.Amount <= Owner.CurrentHp)
        {
            _doomThresholdTriggered = false;
            return;
        }

        if (_doomThresholdTriggered)
        {
            return;
        }

        _doomThresholdTriggered = true;

        var combatState = Owner.CombatState;
        if (combatState is null)
        {
            return;
        }

        Creature[] livingTeammates = combatState
            .GetTeammatesOf(Owner)
            .Where(creature => creature != Owner && creature.IsAlive)
            .ToArray();

        await PowerCmd.Apply<DoomPower>(
            choiceContext,
            livingTeammates,
            TeamDoomAmount,
            Owner,
            null);
    }

    private bool IsOwnersTeammate(Creature creature)
    {
        var combatState = Owner.CombatState;
        return combatState is not null && combatState.GetTeammatesOf(Owner).Contains(creature);
    }

    private void ClearPendingConversion()
    {
        _pendingDoom = 0m;
        _pendingDealer = null;
        _pendingCardSource = null;
    }

}
