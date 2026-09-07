using BaseLib.Utils;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Entities.Cards;
using MegaCrit.Sts2.Core.GameActions.Multiplayer;
using MegaCrit.Sts2.Core.HoverTips;
using MegaCrit.Sts2.Core.Localization.DynamicVars;
using MegaCrit.Sts2.Core.Models.CardPools;
using MegaCrit.Sts2.Core.Models.Powers;
using Sts2CardMechanicsMod.Content.Cards.Shared;
using Sts2CardMechanicsMod.Mechanics.Ikkyuuni;

namespace Sts2CardMechanicsMod.Content.Cards.Colorless;

[Pool(typeof(ColorlessCardPool))]
public sealed class IkkyuuniForm : ModCard
{
    private const decimal AttributeLoss = -999m;

    public override IEnumerable<CardKeyword> CanonicalKeywords =>
    [
        CardKeyword.Ethereal,
    ];

    protected override IEnumerable<DynamicVar> CanonicalVars =>
    [
        new PowerVar<StrengthPower>(AttributeLoss),
        new PowerVar<DexterityPower>(AttributeLoss),
        new PowerVar<FocusPower>(AttributeLoss),
        new PowerVar<IkkyuuniFormPower>(1m),
    ];

    protected override IEnumerable<IHoverTip> ExtraHoverTips =>
    [
        HoverTipFactory.FromPower<StrengthPower>(),
        HoverTipFactory.FromPower<DexterityPower>(),
        HoverTipFactory.FromPower<FocusPower>(),
        HoverTipFactory.FromPower<DoomPower>(),
        HoverTipFactory.FromPower<IkkyuuniFormPower>(),
    ];

    public IkkyuuniForm()
        : base(2, CardType.Power, CardRarity.Rare, TargetType.Self)
    {
    }

    protected override async Task OnPlay(PlayerChoiceContext choiceContext, CardPlay cardPlay)
    {
        await PowerCmd.Apply<StrengthPower>(
            choiceContext,
            Owner.Creature,
            DynamicVars[nameof(StrengthPower)].BaseValue,
            Owner.Creature,
            this);

        await PowerCmd.Apply<DexterityPower>(
            choiceContext,
            Owner.Creature,
            DynamicVars[nameof(DexterityPower)].BaseValue,
            Owner.Creature,
            this);

        await PowerCmd.Apply<FocusPower>(
            choiceContext,
            Owner.Creature,
            DynamicVars[nameof(FocusPower)].BaseValue,
            Owner.Creature,
            this);

        await PowerCmd.Apply<IkkyuuniFormPower>(
            choiceContext,
            Owner.Creature,
            DynamicVars[nameof(IkkyuuniFormPower)].BaseValue,
            Owner.Creature,
            this);
    }

    protected override void OnUpgrade()
    {
        EnergyCost.UpgradeBy(-1);
    }
}
