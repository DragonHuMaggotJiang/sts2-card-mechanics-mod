# Bundled STS1 content inputs

This directory contains the visual inputs used to port the first two Slay the Spire acts into the
Slay the Spire 2 runtime. They are packed into this mod so testers do not need a separate STS1
installation.

`asset-manifest.json` records the original JAR path, byte length, and SHA-256 hash of every file.
Run `scripts/Import-Sts1Assets.ps1` against an owned local installation to reproduce or verify the
import. Original Spine data is retained as a conversion input; STS2 consumes converted Godot scenes,
which live separately from these source-layout files.
