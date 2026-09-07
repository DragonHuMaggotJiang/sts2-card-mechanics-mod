using BaseLib.Abstracts;
using BaseLib.Utils;
using MegaCrit.Sts2.Core.Combat;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Entities.Cards;
using MegaCrit.Sts2.Core.Entities.Creatures;
using MegaCrit.Sts2.Core.Entities.Players;
using MegaCrit.Sts2.Core.Entities.Relics;
using MegaCrit.Sts2.Core.GameActions.Multiplayer;
using MegaCrit.Sts2.Core.HoverTips;
using MegaCrit.Sts2.Core.Localization.DynamicVars;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Models.Enchantments;
using MegaCrit.Sts2.Core.Models.RelicPools;
using MegaCrit.Sts2.Core.ValueProps;
using Sts2CardMechanicsMod.Content.Cards.Ironclad;
using Sts2CardMechanicsMod.Core;

namespace Sts2CardMechanicsMod.Content.Relics.Ironclad;

[Pool(typeof(IroncladRelicPool))]
public sealed class DemonBlood : CustomRelicModel
{
    public override RelicRarity Rarity => RelicRarity.Ancient;
    public override bool HasUponPickupEffect => true;

    protected override IEnumerable<DynamicVar> CanonicalVars =>
    [
        new DamageVar(3m, ValueProp.Unblockable | ValueProp.Unpowered),
    ];

    protected override IEnumerable<IHoverTip> ExtraHoverTips =>
        HoverTipFactory.FromCardWithCardHoverTips<DeathReaping>()
            .Concat(HoverTipFactory.FromEnchantment<Sown>(1));

    public override string PackedIconPath =>
        $"{ModConstants.ResourceRoot}/images/relics/demon_blood.png";

    protected override string PackedIconOutlinePath =>
        $"{ModConstants.ResourceRoot}/images/relics/outline/demon_blood.png";

    protected override string BigIconPath =>
        $"{ModConstants.ResourceRoot}/images/relics/big/demon_blood.png";

    public override async Task AfterObtained()
    {
        CardModel reaper = Owner.RunState.CreateCard<DeathReaping>(Owner);
        CardCmd.Enchant<Sown>(reaper, 1m);
        CardPileAddResult result = await CardPileCmd.Add(reaper, PileType.Deck);
        CardCmd.PreviewCardPileAdd([result], 2f);
    }

    public override async Task BeforeHandDraw(
        Player player,
        PlayerChoiceContext choiceContext,
        ICombatState combatState)
    {
        if (player != Owner || player.PlayerCombatState is not { TurnNumber: <= 1 })
        {
            return;
        }

        Flash();
        await CreatureCmd.Damage(choiceContext, Owner.Creature, DynamicVars.Damage, null, null, null);
    }

    public override decimal ModifyRestSiteHealAmount(Creature creature, decimal amount)
    {
        return creature.Player == Owner || creature.PetOwner == Owner ? 0m : amount;
    }
}
