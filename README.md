# Periodic Table

A native macOS periodic table app built with **SwiftUI** — no web tech, no Electron. It compiles to a standalone `.app` that lives in your Dock and runs fully offline.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Language](https://img.shields.io/badge/Swift-6-orange)

## Features

- **All 118 elements**, color-coded by category (alkali, alkaline earth, transition, post-transition, metalloid, reactive nonmetal, halogen, noble gas, lanthanide, actinide).
- **Dense, readable cells** showing atomic number (Z), oxidation-state charges, symbol, name, molar mass, and electronegativity.
- **Charges across the top** — typical ionic charge for each main group, with variable transition-metal charges labeled per element.
- **Search** by name, symbol, or atomic number (`Iron`, `Fe`, `26`) — matches highlight on the table.
- **Click an element** for a full detail panel: mass number, standard atomic weight, natural state (solid/liquid/gas), block, period, group, electron configuration, electron group, electronegativity, melting/boiling points (K and °C), and density.
- **Clickable legend** — click a category to highlight all of its elements; click again to clear.

## Build & run

Requires macOS 13+ and the Swift toolchain (Xcode or the Command Line Tools: `xcode-select --install`).

```sh
./build.sh
open "Periodic Table.app"
```

`build.sh` compiles [`PeriodicTable.swift`](PeriodicTable.swift) with `swiftc`, assembles the `.app` bundle, generates an icon, and ad-hoc code-signs it. To keep it around, drag the built app into `/Applications` (or right-click its Dock icon → Options → Keep in Dock).

## Project layout

| File | Purpose |
|------|---------|
| `PeriodicTable.swift` | Entire app — element dataset, views, and layout in one file. |
| `build.sh` | Compiles the source and assembles `Periodic Table.app`. |

All element data lives in one editable block (`RAW_DATA`) near the top of `PeriodicTable.swift`.

## Notes

- **Mass number (A)** is shown as the rounded standard atomic weight (≈ most common isotope).
- A few synthetic superheavy elements show `—` where physical values are unknown or only predicted.
- The app is **ad-hoc signed** for local use. Distributing it more widely would require an Apple Developer certificate (and the Mac App Store additionally requires sandboxing).
