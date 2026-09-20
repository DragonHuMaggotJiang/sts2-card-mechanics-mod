# Architecture

## Goal

Keep early card development fast while preserving a path to reusable game mechanics. This repository
is deliberately a modular monolith; separate assemblies are introduced only when a boundary has a
real independent lifecycle.

## Modules

| Area | Owns | Must not own |
| --- | --- | --- |
| Bootstrap | Mod initialization and composition | Card gameplay |
| Core | Stable IDs, contracts, small shared primitives | Harmony patches or feature-specific helpers |
| Integration | Loader/game adapters and Harmony patches | Card-pack design |
| Mechanics | Reusable rules, hooks, and mechanic state | Loader bootstrapping |
| Content | Cards and other player-facing content | Version-specific patches |
| UI | Presentation and hover-tip behavior | Authoritative gameplay state |

## STS1 content origin boundary

Ported STS1 content uses dedicated serializable pools and origin metadata. Do not add an STS1 card
to a base-game STS2 pool: combat rewards are selected from exactly one generation according to the
encounter origin. Ancient content is a fourth origin and is never eligible for ordinary combat,
shop, or treasure rewards.

The initial route is configured by `ActContentProfile.Sts1ActsOneAndTwo`: acts 1 and 2 use STS1
content, while act 3 is mixed. Mixed mode initially chooses a whole encounter from one generation;
it does not combine STS1 and STS2 monsters inside one fight.

Raw STS1 visual inputs live under `Sts2CardMechanicsMod/sts1` and are reproducibly imported with
`scripts/Import-Sts1Assets.ps1`. Converted Godot scenes are separate runtime artifacts; code must not
read another game installation at runtime.

## Evolution rule

Start behavior in the content that needs it. Promote it to Mechanics when a second consumer appears,
or immediately when the behavior owns lifecycle hooks or persistent state. Do not pre-build abstract
frameworks for hypothetical mechanics.

## Collaboration rule

Parallel branches should target separate feature packs. Shared hotspots require a dedicated PR and
must land before dependent branches are rebased. A clean textual merge is not enough: architecture
validation, local compilation, and an in-game smoke test are required for gameplay changes.
