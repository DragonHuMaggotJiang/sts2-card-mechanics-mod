# Contributing

1. Pull the latest `main`.
2. Create a focused branch such as `card/dragonmaggot-flame-strike` or `mechanic/friend-momentum`.
3. Give each human/AI pair its own clone or Git worktree and branch.
4. Keep changes inside the assigned feature area; isolate shared architecture changes in their own PR.
5. Run `./scripts/Test-Architecture.ps1` and `./scripts/Build.ps1`.
6. Push the branch and open a pull request using the repository template.
7. Merge only after checks pass, review is resolved, and the branch is current with `main`.

Prefer squash merge for ordinary feature branches. Never resolve a semantic conflict by blindly
choosing "ours" or "theirs"; re-run local build and in-game smoke tests after conflict resolution.

