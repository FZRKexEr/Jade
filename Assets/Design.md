# Chinese Chess macOS App - Design Documentation

## Overview

This document describes the visual design system and assets for the Chinese Chess (Xiangqi) macOS application. The design follows macOS Human Interface Guidelines while incorporating traditional Chinese aesthetic elements.

---

## Brand Philosophy

### Design Concept
The design blends traditional Chinese cultural elements with modern macOS aesthetics:
- **Heritage**: Honoring the ancient game of Xiangqi with traditional typography and motifs
- **Modernity**: Clean, minimalist interfaces that feel native to macOS
- **Harmony**: Balance between Eastern tradition and Western design principles

### Brand Values
- **Accessible**: Easy to learn for beginners, deep enough for masters
- **Authentic**: True to the spirit of traditional Chinese chess
- **Elegant**: Beautiful in both form and function

---

## Color Palette

### Primary Colors

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Primary Red | `#CC0000` | Red pieces, accent highlights |
| Primary Black | `#1A1A1A` | Black pieces, dark mode text |
| Primary Blue | `#007AFF` | Selection, interactive elements |

### Secondary Colors

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Success Green | `#34C759` | Move indicators, success states |
| Warning Orange | `#FF9500` | Last move marker, alerts |
| Error Red | `#FF3B30` | Check warning, errors |
| Purple | `#5856D6` | Secondary actions, hints |

### Neutral Colors

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Light Background | `#F5F5F7` | Light mode background |
| Dark Background | `#1C1C1E` | Dark mode background |
| Light Text | `#FFFFFF` | Dark mode text |
| Dark Text | `#000000` | Light mode text |
| Secondary Text | `#8E8E93` | Subdued text |

### Board Colors

#### Wood Style
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Wood Light | `#E8D4A2` | Light wood squares |
| Wood Dark | `#C4A35A` | Dark wood squares |
| Wood Border | `#8B6914` | Board border |

#### Modern Style
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Modern Light | `#F5F5F7` | Light mode board |
| Modern Dark | `#1C1C1E` | Dark mode board |
| Grid Lines Light | `#8E8E93` | Light mode grid |
| Grid Lines Dark | `#636366` | Dark mode grid |

---

## Typography

### Typefaces

**System Fonts (Primary)**
- Interface: San Francisco (macOS system font)
- Chinese Characters:
  - STHeiti (LiShu style for traditional pieces)
  - PingFang SC (Modern UI text)

**Font Sizes**
| Usage | Size | Weight |
|-------|------|--------|
| Window Title | 13pt | Semibold |
| Body Text | 13pt | Regular |
| Toolbar Labels | 11pt | Regular |
| Piece Characters | 24-48pt | Medium |
| Status Labels | 11pt | Medium |

---

## Iconography

### App Icon

The app icon features a traditional Chinese chess piece ("帅" - Commander/Shuai) rendered in a modern, minimalist style:
- **Background**: Rounded rectangle with subtle gradient from dark gray to slightly lighter gray
- **Foreground**: Red Chinese chess piece with the character "帅" in traditional LiShu script
- **Style**: Flat design with subtle depth through shadows and highlights

### Toolbar Icons

| Icon | Description | Style |
|------|-------------|-------|
| New Game | Plus symbol | SF Symbols style, 2px stroke |
| Undo | Curved back arrow | SF Symbols style, 2px stroke |
| Hint | Lightbulb | SF Symbols style, 2px stroke |
| Settings | Gear/cog | SF Symbols style, 2px stroke |
| Analysis | Chart/graph | SF Symbols style, 2px stroke |

---

## Asset Specifications

### App Icon Sizes

| Size | Usage | Filename |
|------|-------|----------|
| 16x16 | Finder small icons | AppIcon_16x16.png |
| 32x32 | Finder, Spotlight | AppIcon_32x32.png |
| 64x64 | Finder preview | AppIcon_32x32@2x.png |
| 128x128 | Finder large icons | AppIcon_128x128.png |
| 256x256 | Finder, Dock | AppIcon_256x256.png |
| 512x512 | App Store, Dock | AppIcon_512x512.png |
| 1024x1024 | App Store | AppIcon_1024x1024.png |

### Board Styles

| Style | Filename | Description |
|-------|----------|-------------|
| Wood | Board_Wood.png | Traditional wood grain texture |
| Modern Light | Board_Modern_Light.png | Clean light theme |
| Modern Dark | Board_Modern_Dark.png | Clean dark theme |

### Piece Styles

| Style | Directory | Description |
|-------|-----------|-------------|
| Traditional | PieceStyles/Traditional/ | LiShu font, classic design |
| Modern | PieceStyles/Modern/ | Flat design, minimal |

Piece sizes: 64x64, 128x128, 256x256

Naming convention: {Color}_{Index}.png
- Red pieces: 0-6 (帅, 仕, 相, 傌, 俥, 炮, 兵)
- Black pieces: 0-6 (将, 士, 象, 马, 车, 砲, 卒)

---

## Dark Mode Support

All assets support both light and dark modes:
- Board styles: Separate Modern Light and Modern Dark variants
- UI elements: Semi-transparent PNGs adapt to background
- Toolbar icons: Template-ready monochrome designs

---

## File Organization

```
Assets/
├── Design.md                 # This documentation
├── generate_assets.py        # Asset generation script
├── Icons/
│   ├── AppIcon.iconset/      # App icon in all sizes
│   └── AppIcon_1024.png      # Master icon file
├── BoardStyles/
│   ├── Board_Wood.png        # Traditional wood style
│   ├── Board_Modern_Light.png
│   └── Board_Modern_Dark.png
├── PieceStyles/
│   ├── Traditional/          # Classic LiShu style
│   │   ├── 64/
│   │   ├── 128/
│   │   └── 256/
│   └── Modern/                 # Flat design
│       ├── 64/
│       ├── 128/
│       └── 256/
├── Toolbar/
│   ├── NewGame_*.png
│   ├── Undo_*.png
│   ├── Hint_*.png
│   ├── Settings_*.png
│   └── Analysis_*.png
└── UI/
    ├── Selection_Highlight.png
    ├── Move_Indicator.png
    ├── Check_Warning.png
    └── Last_Move_Indicator.png
```

---

## Design Principles Summary

1. **Respect Tradition**: Use authentic Chinese calligraphy (LiShu) for pieces
2. **Embrace Modernity**: Clean, minimalist interfaces that feel native to macOS
3. **Accessibility**: High contrast, clear visual hierarchy, support for dark mode
4. **Scalability**: Vector-ready designs at multiple resolutions for Retina displays
5. **Consistency**: Unified color palette and styling across all assets

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-09 | Initial design documentation and asset generation |

---

*Document generated for Chinese Chess macOS Application*
