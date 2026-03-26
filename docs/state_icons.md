# State Icons

RomeBots active-state icons use a simple asset-key convention.

## Convention

Set `state_definitions.icon` to the desired icon key, then add a matching file in:

- `app/assets/images/state_icons/`

Examples:

- `app/assets/images/state_icons/veteran_discontent.svg`
- `app/assets/images/state_icons/guard_mobilized.png`

Supported extensions are checked in this order:

- `avif`
- `webp`
- `png`
- `jpg`
- `jpeg`
- `svg`

## Rendering

The active-states panel renders:

1. a matching icon asset when one exists for `StateDefinition.icon`
2. a compact text badge based on the state label when no icon asset exists

## Notes

- This is asset-based only for now; there is no upload flow for state icons in this pass.
- ActiveAdmin now previews state icons when a matching asset exists.
- Current RomeBots state definitions are backfilled to use icon keys matching their state keys.
