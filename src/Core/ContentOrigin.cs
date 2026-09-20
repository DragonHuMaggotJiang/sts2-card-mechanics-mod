namespace Sts2CardMechanicsMod.Core;

/// <summary>
/// Identifies the ruleset that owns content and its rewards. This value must remain stable because
/// it is also used by multiplayer-safe run metadata and save data.
/// </summary>
public enum ContentOrigin
{
    Sts1,
    Sts2,
    Mixed,
    Ancient,
}
