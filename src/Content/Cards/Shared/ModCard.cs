using BaseLib.Abstracts;
using BaseLib.Extensions;
using MegaCrit.Sts2.Core.Entities.Cards;
using Sts2CardMechanicsMod.Core;

namespace Sts2CardMechanicsMod.Content.Cards.Shared;

/// <summary>
/// Common presentation behavior for cards in this mod. Gameplay belongs in concrete cards
/// or reusable classes under Mechanics; do not turn this class into a global behavior bucket.
/// </summary>
public abstract class ModCard(int cost, CardType type, CardRarity rarity, TargetType target)
    : CustomCardModel(cost, type, rarity, target)
{
    private string ImageFileName => $"{Id.Entry.RemovePrefix().ToLowerInvariant()}.png";

    public override string PortraitPath =>
        $"{ModConstants.ResourceRoot}/images/card_portraits/{ImageFileName}";

    public override string CustomPortraitPath =>
        $"{ModConstants.ResourceRoot}/images/card_portraits/big/{ImageFileName}";
}

