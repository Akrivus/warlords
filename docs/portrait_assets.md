# Portrait Assets

RomeBots speaker portraits use a simple fallback chain.

## Lookup Order

The active card UI resolves portraits in this order:

1. uploaded `CardDefinition#portrait_upload`
2. file-based asset lookup from `portrait_key`
3. deterministic placeholder

## Asset Convention

Place portrait files in:

- `app/assets/images/portraits/`

Name each file after the card `portrait_key`:

- `app/assets/images/portraits/caesar.svg`
- `app/assets/images/portraits/agrippa.png`

Supported extensions are checked in this order:

- `avif`
- `webp`
- `png`
- `jpg`
- `jpeg`
- `svg`

If no upload exists and no matching file exists for a card's `portrait_key`, the active card UI renders a deterministic placeholder instead of a broken image.

## Admin Uploads

Portraits can now also be managed directly in ActiveAdmin on `CardDefinition`.

- upload a portrait to override asset-folder lookup
- upload a new file to replace the current portrait
- check the remove box to delete the uploaded portrait and fall back to asset/placeholder rendering again

## Notes

- This keeps portrait support Rails-native with Active Storage plus the regular asset pipeline.
- Portrait uploads are attached directly to `CardDefinition` for the smallest useful admin-managed flow.
- The active card header can safely render cards with or without portrait assets.
