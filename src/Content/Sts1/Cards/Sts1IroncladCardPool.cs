using BaseLib.Abstracts;
using Godot;

namespace Sts2CardMechanicsMod.Content.Sts1.Cards;

/// <summary>
/// Serializable reward pool for Ironclad cards ported from STS1. It deliberately remains separate
/// from the STS2 Ironclad pool so an encounter can select exactly one generation of rewards.
/// </summary>
public sealed class Sts1IroncladCardPool : CustomCardPoolModel
{
    public override string Title => "sts1_ironclad";
    public override string EnergyColorName => "ironclad";
    public override string CardFrameMaterialPath => "card_frame_red";
    public override Color DeckEntryCardColor => new("D62000");
    public override Color EnergyOutlineColor => new("802020");
    public override bool IsColorless => false;
    public override bool SeenByDefault => true;
}
