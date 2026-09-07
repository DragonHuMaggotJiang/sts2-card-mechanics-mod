# AI Agent Working Agreement

These rules apply to every AI coding agent, regardless of vendor.

## Repository model

- This is a modular monolith: one mod and one build output, with internal responsibility boundaries.
- Work in a dedicated branch and checkout/worktree. Never let two active agents use the same branch.
- Keep one PR focused on one card pack, mechanic, fix, or infrastructure change.
- Never commit directly to `main`, force-push shared branches, or rewrite another contributor's commits.

## Dependency direction

- `src/Core` contains small, stable contracts and identifiers only. It must not depend on other source modules.
- `src/Mechanics` contains reusable gameplay rules and may depend on Core.
- `src/Content` composes cards and other content from Core/Mechanics.
- `src/UI` contains presentation behavior, not gameplay state.
- Harmony patches and version-specific game integration belong only in `src/Integration` or `src/Bootstrap`.
- A simple card does not justify a new architecture module or directory. Group cards by feature pack.

## Change boundaries

- Do not refactor unrelated code while implementing content.
- Treat `src/Core`, `src/Bootstrap`, `src/Integration`, the project file, and manifest as shared hotspots.
- Propose shared contract changes in a small, dedicated PR before dependent content work when practical.
- Do not hand-edit build outputs or commit `sts2.dll`, `0Harmony.dll`, PCK outputs, game files, or secrets.
- Keep NuGet versions pinned. Dependency upgrades belong in dedicated PRs.

## Card rules

- Use the `Sts2CardMechanicsMod` ID namespace and globally unique model IDs.
- A simple card is normally one C# file in a feature-pack directory.
- Move behavior into `src/Mechanics/<MechanicName>` only when it owns state/hooks or is reused.
- Every card needs English and Simplified Chinese localization, upgrade behavior, and artwork before release.
- Avoid a central hand-written card registry when the loader/BaseLib can discover model types.

## Required checks

- Run `./scripts/Test-Architecture.ps1` before every commit.
- Run `./scripts/Build.ps1` before opening a gameplay PR when the local SDK/game installation is available.
- Smoke-test gameplay changes in Slay the Spire 2 and record the result in the PR.
- Never weaken or bypass a check merely to make a PR pass.

