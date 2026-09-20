namespace Sts2CardMechanicsMod.Core;

/// <summary>
/// The initial super-mod route: STS1 content is introduced in the first two acts and the final act
/// can combine both generations. Keeping this as data allows other routes without another map patch.
/// </summary>
public sealed record ActContentProfile(
    ContentOrigin Act1,
    ContentOrigin Act2,
    ContentOrigin Act3)
{
    public static ActContentProfile Sts1ActsOneAndTwo { get; } = new(
        ContentOrigin.Sts1,
        ContentOrigin.Sts1,
        ContentOrigin.Mixed);

    public ContentOrigin ForActIndex(int actIndex) => actIndex switch
    {
        0 => Act1,
        1 => Act2,
        2 => Act3,
        _ => throw new ArgumentOutOfRangeException(nameof(actIndex), actIndex, "Only the three main acts are configured."),
    };
}
