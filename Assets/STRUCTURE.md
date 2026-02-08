# Assets Directory Structure Documentation

## Current Directory Structure

```
Assets/
├── Design.md                 # Design specification and color palette
├── STRUCTURE.md             # This file - directory structure documentation
├── generate_assets.py       # Python script to generate all assets
│
├── BoardStyles/             # Chess board textures and backgrounds
│   ├── Board_Wood.png       # Traditional wood grain style
│   ├── Board_Modern_Light.png
│   └── Board_Modern_Dark.png
│
├── Icons/                   # Application icons
│   ├── AppIcon_1024.png     # Master icon file (1024x1024)
│   └── AppIcon.iconset/     # macOS iconset with all required sizes
│       ├── AppIcon_16x16.png
│       ├── AppIcon_16x16@2x.png
│       ├── AppIcon_32x32.png
│       ├── AppIcon_32x32@2x.png
│       ├── AppIcon_128x128.png
│       ├── AppIcon_128x128@2x.png
│       ├── AppIcon_256x256.png
│       ├── AppIcon_256x256@2x.png
│       ├── AppIcon_512x512.png
│       └── AppIcon_512x512@2x.png
│
├── PieceStyles/             # Chess piece designs
│   ├── Modern/              # Flat design style
│   │   ├── 64/              # 64x64 pixels
│   │   ├── 128/             # 128x128 pixels
│   │   └── 256/             # 256x256 pixels
│   └── Traditional/         # Classic LiShu style
│       ├── 64/
│       ├── 128/
│       └── 256/
│           # Piece naming: {Color}_{Index}.png
           # Index mapping:
           # 0: 帅/将 (King/General)
           # 1: 仕/士 (Advisor)
           # 2: 相/象 (Elephant)
           # 3: 傌/马 (Horse/Knight)
           # 4: 俥/车 (Rook/Chariot)
           # 5: 炮/砲 (Cannon)
           # 6: 兵/卒 (Pawn/Soldier)
│
├── Toolbar/                 # Toolbar icons
│   ├── Analysis_18x18.png
│   ├── Analysis_18x18@2x.png
│   ├── Analysis_24x24.png
│   ├── Hint_18x18.png
│   ├── Hint_18x18@2x.png
│   ├── Hint_24x24.png
│   ├── NewGame_18x18.png
│   ├── NewGame_18x18@2x.png
│   ├── NewGame_24x24.png
│   ├── Settings_18x18.png
│   ├── Settings_18x18@2x.png
│   ├── Settings_24x24.png
│   ├── Undo_18x18.png
│   ├── Undo_18x18@2x.png
│   └── Undo_24x24.png
│
├── UI/                      # UI elements and indicators
│   ├── Check_Warning.png    # Red pulsing ring for check warning
│   ├── Last_Move_Indicator.png
│   ├── Move_Indicator.png   # Green dot for valid moves
│   └── Selection_Highlight.png
│
└── LaunchScreen/            # App launch screen backgrounds
    ├── LaunchScreen_800x600.png
    ├── LaunchScreen_1024x768.png
    ├── LaunchScreen_1200x800.png
    └── LaunchScreen_1600x1000.png
```

## File Naming Conventions

### App Icons
- Format: `AppIcon_{width}x{height}[@2x].png`
- Examples: `AppIcon_16x16.png`, `AppIcon_16x16@2x.png`

### Board Styles
- Format: `Board_{Style}.png`
- Examples: `Board_Wood.png`, `Board_Modern_Light.png`

### Chess Pieces
- Format: `{Color}_{Index}.png`
- Color: `Red` or `Black`
- Index: 0-6 (对应 帅/将, 仕/士, 相/象, 傌/马, 俥/车, 炮/砲, 兵/卒)
- Size directories: `64/`, `128/`, `256/`

### Toolbar Icons
- Format: `{Name}_{width}x{height}[@2x].png`
- Examples: `NewGame_18x18.png`, `Undo_18x18@2x.png`

### UI Elements
- Format: `{Element_Name}.png`
- Examples: `Selection_Highlight.png`, `Move_Indicator.png`

### Launch Screen
- Format: `LaunchScreen_{width}x{height}.png`
- Examples: `LaunchScreen_800x600.png`, `LaunchScreen_1024x768.png`

## Asset Specifications

### Icon Sizes (macOS)
| Size | Usage |
|------|-------|
| 16x16 | Finder small icons |
| 32x32 | Finder, Spotlight |
| 128x128 | Finder large icons |
| 256x256 | Finder, Dock |
| 512x512 | App Store, Dock |
| 1024x1024 | App Store (2x) |

### Piece Sizes
| Size | Usage |
|------|-------|
| 64x64 | Small boards, thumbnail view |
| 128x128 | Standard board size |
| 256x256 | Retina displays, large boards |

### Board Texture
| Size | Usage |
|------|-------|
| 1024x1024 | Full board background, scalable |

## Notes for Future Restructuring

When the architect's complete design is available, consider the following potential changes:

1. **Xcode Asset Catalog Integration**: Move icons to `Assets.xcassets/AppIcon.appiconset/`
2. **Bundle Resource Organization**: Consider grouping by feature (e.g., `Board/`, `Pieces/`, `UI/`)
3. **Localization**: Add `lproj` directories for localized assets if needed
4. **Dark Mode Variants**: Consider adding explicit dark mode variants as `-dark` suffixes

## Current Status

- **Total PNG Files**: 121
- **Total Size**: ~900KB
- **Script**: `generate_assets.py` can regenerate all assets
- **Documentation**: Complete with `Design.md` and `STRUCTURE.md`
