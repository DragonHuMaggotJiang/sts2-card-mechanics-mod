# Card Mechanics Mod for Slay the Spire 2

A collaborative Slay the Spire 2 content mod organized as a modular monolith. The first milestone is
a small card set; the architecture leaves explicit boundaries for reusable mechanics and game API
integration without turning every card into its own module.

## Current compatibility

- Slay the Spire 2: `0.111.0`
- .NET SDK: `9.x`
- Godot .NET SDK: `4.5.1`
- BaseLib: `3.4.5`

The game DLLs are referenced from each developer's local installation and are never committed.

## Local setup

1. Install a .NET 9 SDK. This machine uses the repository-adjacent `D:/STS2Mods/.dotnet` SDK.
2. Copy `local.props.example` to `local.props` and set `Sts2Path` to your game directory.
3. Run `./scripts/Install-BaseLib.ps1` after the first package restore to install the pinned BaseLib
   runtime into the game's `mods` directory.
4. Run `./scripts/Build.ps1` from PowerShell.
5. Start the game, enable the mod, restart when prompted, and smoke-test the changed content.

On this machine, `local.props` already points to:

`D:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2`

## Collaboration

Read `AGENTS.md` before using any coding agent. Each agent works on a separate branch and checkout or
worktree. Shared architecture changes are landed as focused PRs before dependent card work.

The GitHub-hosted workflow validates source boundaries and JSON. Full builds require local game
assemblies, so they run locally unless the repository later gets a private self-hosted runner.

## Project map

- `src/Bootstrap`: mod entry point
- `src/Core`: stable contracts and identifiers
- `src/Integration`: game/loader adapters and patches
- `src/Mechanics`: reusable gameplay mechanics
- `src/Content`: cards and other content grouped by feature
- `src/UI`: presentation-only extensions
- `Sts2CardMechanicsMod`: assets and localization packed into the mod PCK
