# Club Room Creator Development Progress

This document tracks progress on developing the Club Room Creator Openplanet plugin.
It will be updated as new features are implemented following the steps outlined in
`PluginDevDoc.md`.

## Initial Setup
- Repository initialized with a minimal plugin skeleton.
- `info.toml` contains basic metadata for the plugin.
- `ClubRoomCreator.as` defined `RenderMenu()` for a simple menu entry.

## Progress Made
- Added `Main()` to request authentication tokens from `NadeoServices`.
- Implemented a basic `Render()` window that displays a placeholder message.
- Updated `info.toml` with a dependency on `NadeoServices`.

## Next Steps
1. Expand the UI in `Render()` to allow setting room name and game mode.
2. Implement track selection features (search, random selection, local map listing).
3. Add functions to create the room via Nadeo Live Services API.
4. Document setup instructions for local development (Openplanet installation, enabling Developer mode, using pnpm for any build steps).

Further progress will be documented in this file as the plugin evolves.
