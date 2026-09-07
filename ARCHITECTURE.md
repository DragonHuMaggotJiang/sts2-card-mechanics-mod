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

## Evolution rule

Start behavior in the content that needs it. Promote it to Mechanics when a second consumer appears,
or immediately when the behavior owns lifecycle hooks or persistent state. Do not pre-build abstract
frameworks for hypothetical mechanics.

## Collaboration rule

Parallel branches should target separate feature packs. Shared hotspots require a dedicated PR and
must land before dependent branches are rebased. A clean textual merge is not enough: architecture
validation, local compilation, and an in-game smoke test are required for gameplay changes.

