# Card artwork

The Brazil catalog already points to the final WebP naming convention:

- `brazil/common/brazil_sao_paulo.webp`
- `brazil/rare/brazil_flag.webp`
- `brazil/epic/brazil_jaguar.webp`
- `brazil/legendary/brazil_christ_redeemer.webp`

The folders are split by country and rarity so new catalogs can follow the same
layout without changing card widgets or screens. Flutter registers each rarity
folder separately in `pubspec.yaml`, which keeps asset discovery explicit.

Until final artwork is supplied, the app renders a lightweight, card-specific
placeholder from its category and rarity without trying to load these paths.
The frame, country, official number, name, rarity, category, quantity, and state
are always drawn dynamically by Flutter. After adding an optimized WebP, set
only that card's `isPlaceholderImage` to `false`. The development tool now manages
this through the static `approvedCardArtIds` set in `lib/data/approved_card_art.dart`.

Use the independent generator in `tools/card-image-generator/` to generate,
review, approve, and explicitly apply WebP artwork. See its README for commands.
The default final artwork is 1000 × 1024, with center cropping by `BoxFit.cover`.
Generated and approved review files stay outside the game's asset bundle until
the developer runs `apply`.
