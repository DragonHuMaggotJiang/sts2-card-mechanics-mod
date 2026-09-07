using System.Reflection;
using HarmonyLib;
using MegaCrit.Sts2.Core.Commands;
using MegaCrit.Sts2.Core.Events;
using MegaCrit.Sts2.Core.Models;
using MegaCrit.Sts2.Core.Models.Events;
using MegaCrit.Sts2.Core.Models.Relics;
using Sts2CardMechanicsMod.Content.Relics.Ironclad;

namespace Sts2CardMechanicsMod.Integration;

[HarmonyPatch(typeof(Vakuu), "get_Pool2")]
internal static class VakuuDemonBloodPatch
{
    private static readonly MethodInfo RelicOptionMethod = AccessTools.Method(
        typeof(EventModel),
        "RelicOption",
        [typeof(RelicModel), typeof(Func<Task>), typeof(string)])
        ?? throw new MissingMethodException(typeof(EventModel).FullName, "RelicOption");

    private static readonly MethodInfo DoneMethod = AccessTools.Method(
        typeof(AncientEventModel),
        "Done")
        ?? throw new MissingMethodException(typeof(AncientEventModel).FullName, "Done");

    private static void Postfix(Vakuu __instance, ref IEnumerable<EventOption> __result)
    {
        if (FindBloodStarter(__instance) is null)
        {
            return;
        }

        DemonBlood demonBlood = (DemonBlood)ModelDb.Relic<DemonBlood>().ToMutable();
        async Task ChooseDemonBlood()
        {
            RelicModel? starter = FindBloodStarter(__instance);
            if (starter is null)
            {
                return;
            }

            await RelicCmd.Replace(starter, demonBlood);
            DoneMethod.Invoke(__instance, null);
        }

        var option = (EventOption)RelicOptionMethod.Invoke(
            __instance,
            [demonBlood, (Func<Task>)ChooseDemonBlood, "INITIAL"])!;

        __result = __result.Append(option);
    }

    private static RelicModel? FindBloodStarter(Vakuu vakuu)
    {
        return vakuu.Owner?.Relics.FirstOrDefault(relic => relic is BurningBlood or BlackBlood);
    }
}
