# Farm Việt V12 iOS

V12 is a SpriteKit + SwiftUI farming game prototype for iPhone/iPad.

Features:
- Large pixel-art farm map
- 30 crop plots with growth
- Character movement and virtual joystick
- NPCs and pets
- Fishing: cast, bite, jerk, reel
- Farm / Village / Market / Fishing / Forest area portals
- Inventory, shop, energy and save
- Day/night mode
- GitHub Actions workflow that builds an unsigned iOS IPA

The workflow copies source/assets into the generated `FarmViet/` resource directory and creates compatibility aliases for animation frames referenced by the Xcode project.


## FarmViet V13 asset expansion

This V13 package adds a separated `Resources/FarmExpansion/` collection.

### Farming 101 Free
- 15 PNG assets from the supplied free version.
- License is included in `Resources/FarmExpansion/Farming101_Free/LICENSE_Farming101.txt`.
- The supplied license allows non-commercial projects and modification, but prohibits redistribution/resale of the assets.

### SuperRetroRanch FreeTier
- 53 PNG assets from the supplied FreeTier.
- All `assets_premium_preview/` content was deliberately excluded.
- License is included in `Resources/FarmExpansion/SuperRetroRanch_FreeTier/LICENSE_SuperRetroRanch_FreeTier.txt`.
- The supplied FreeTier license is for non-commercial projects only and prohibits redistribution/resale of the assets.

### Other supplied free version
- `FREE_free.png` was kept separately because the supplied readme does not state a full usage license. Verify its license before commercial distribution.

These assets are bundled into the Xcode target by the generated project file. They are kept separate from the original FarmViet art so they can be used for future farm, animal, crop, building and environment gameplay.
