# Dex Keeper (iOS)

A native SwiftUI rebuild of the Dex Keeper Pokémon team builder. Browse the
full national dex, build a team of up to six, analyze type coverage and
weaknesses for battle prep, and export/import teams as JSON.

## Features

- **National Dex browser** — all 1,025 mainline Pokémon, searchable by name or
  number, filterable by type. Sprites + type badges, powered by
  [PokéAPI](https://pokeapi.co).
- **Pokémon detail** — official artwork, base stats, and full defensive
  matchups (4×/2×/½×/¼×/immune) computed from the Gen 6+ type chart.
- **Team builder** — up to 6 slots, drag to reorder, swipe to delete, rename,
  persisted between launches.
- **Battle Prep / coverage analysis**
  - Shared weaknesses (types that hit 3+ of your team super-effectively)
  - Full defensive table (weak / resist / immune counts per attacking type)
  - Offensive STAB coverage grid + gap detection
- **Export / Import** — share or copy a team as JSON; paste to load on another
  device. Imported teams render offline (types are stored in the export).

## Setup (≈2 minutes)

This is delivered as source files rather than a prebuilt `.xcodeproj`, so you
drop them into a fresh project:

1. Open **Xcode → File → New → Project → iOS → App**.
2. Name it **`DexKeeper`**, Interface **SwiftUI**, Language **Swift**. Set the
   minimum deployment target to **iOS 16.0** or later.
3. Delete the auto-generated `ContentView.swift` and `DexKeeperApp.swift` from
   the new project.
4. Drag the contents of this folder (the `Models`, `Services`, `Views`,
   `Components`, `Extensions` folders and `DexKeeperApp.swift`) into the Xcode
   project navigator. Check **"Copy items if needed"** and add to the
   `DexKeeper` target.
5. Build & run on a simulator or device.

No API key, CocoaPods, or SPM packages required — it uses `URLSession` and
`AsyncImage` against the public PokéAPI over HTTPS (no App Transport Security
exceptions needed).

## Project structure

```
DexKeeper/
├─ DexKeeperApp.swift          # @main entry, injects services
├─ Models/
│  ├─ PokemonType.swift        # 18 types + colors/symbols
│  ├─ Pokemon.swift            # Pokemon, DexEntry, Stat + PokéAPI DTOs
│  └─ Team.swift               # Team & TeamMember (Codable)
├─ Services/
│  ├─ PokeAPIService.swift     # networking + in-memory cache
│  ├─ TypeChart.swift          # type chart + TeamAnalysis
│  └─ TeamStore.swift          # persistence + JSON export/import
├─ Views/
│  ├─ ContentView.swift        # TabView root
│  ├─ DexBrowserView.swift
│  ├─ PokemonDetailView.swift
│  ├─ TeamView.swift
│  ├─ CoverageAnalysisView.swift
│  └─ ImportExportView.swift
├─ Components/
│  ├─ TypeBadge.swift
│  ├─ SpriteImage.swift
│  └─ PokemonRow.swift
└─ Extensions/
   └─ Color+Hex.swift
```

## Notes & next steps

- The type effectiveness chart is bundled statically, so coverage analysis is
  instant and works offline.
- Offensive coverage is STAB-based (uses each Pokémon's own types). If your web
  version tracked actual movesets, that logic can be swapped in.
- Easy additions: ability/item slots, EV/nature notes, abilities affecting type
  matchups (Levitate, etc.), multiple saved teams, and a damage calculator.

If you share the web app's data model or styling, the colors, fields, and
battle-prep rules here can be matched exactly.
