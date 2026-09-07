using System.Reflection;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Modding;
using Sts2CardMechanicsMod.Core;

namespace Sts2CardMechanicsMod.Bootstrap;

[ModInitializer(nameof(Initialize))]
public partial class ModEntry : Node
{
    public static MegaCrit.Sts2.Core.Logging.Logger Logger { get; } =
        new(ModConstants.Id, MegaCrit.Sts2.Core.Logging.LogType.Generic);

    public static void Initialize()
    {
        Assembly assembly = Assembly.GetExecutingAssembly();
        Harmony harmony = new(ModConstants.Id);
        harmony.PatchAll(assembly);
        Logger.Info($"{ModConstants.Id} initialized.");
    }
}

