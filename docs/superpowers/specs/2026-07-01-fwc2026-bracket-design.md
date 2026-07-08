# FWC2026 Bracket Design

**Date:** 2026-07-01
**Status:** Approved

## Goal

Implémenter le bracket complet FIFA World Cup 2026 dans `FWCBracketView` (actuellement placeholder "Coming Soon"). Le bracket couvre 6 rounds : Seizièmes (R32), Huitièmes (R16), Quarts, Demi-finales, 3e Place, Finale. Layout hybride — canvas scrollable horizontal+vertical avec picker round qui auto-scroll.

---

## Architecture

**Approche : types FWC-spécifiques dans le target `FWC2026`** — isolation totale du target AFCON2025 et de TournamentKit. Aligné avec le design doc FWC2026 : *"BracketView stays in each target"*.

Aucune modification de TournamentKit.

---

## Fichiers à créer

Tous dans `FWC2026/` :

```
FWC2026/
├── Models/
│   └── FWCBracketTypes.swift        enum FWCBracketRound + struct FWCBracketMatch + FWCBracketMatches
├── Data/
│   └── FWCBracketData.swift         données statiques placeholder
├── ViewModels/
│   └── FWCBracketViewModel.swift    @Observable, selectedRound, bracketMatches, isLoading
└── Views/
    └── FWCBracketView.swift          remplace le placeholder actuel
```

---

## Couche Données

### `FWCBracketRound`

```swift
public enum FWCBracketRound: String, CaseIterable {
    case roundOf32    = "Seizièmes"
    case roundOf16    = "Huitièmes"
    case quarterFinals = "Quarts"
    case semiFinals   = "Demi-finales"
    case final        = "Finale"
}
```

### `FWCBracketMatch`

Même structure que `BracketMatch` (TournamentKit) — dupliquée intentionnellement dans le target FWC :

```swift
public struct FWCBracketMatch: Sendable {
    public let id: Int
    public let date: String      // "yyyy-MM-dd"
    public let time: String      // "HH:mm"
    public let team1: String
    public let team2: String
    public let team1Id: Int?
    public let team2Id: Int?
    public let venue: String
    public let score1: Int?
    public let score2: Int?
    public var penalty1: Int?
    public var penalty2: Int?
}
```

### `FWCBracketMatches`

```swift
public struct FWCBracketMatches: Sendable {
    public let roundOf32:     [FWCBracketMatch]   // 16 matchs
    public let roundOf16:     [FWCBracketMatch]   // 8 matchs
    public let quarterFinals: [FWCBracketMatch]   // 4 matchs
    public let semiFinals:    [FWCBracketMatch]   // 2 matchs
    public let final:          FWCBracketMatch
    public let thirdPlace:     FWCBracketMatch
}
```

### `FWCBracketData`

Données statiques placeholder — toutes les équipes à `"TBD"`, dates/stades vides. IDs de match séquentiels à partir de 65 (suite logique après les matchs de groupes FWC). Structure : 16 matchs R32, 8 R16, 4 QF, 2 SF, 1 Final, 1 3e Place.

---

## ViewModel

**`FWCBracketViewModel`** — `@Observable`, singleton `.shared` :

```swift
@Observable
class FWCBracketViewModel {
    static let shared = FWCBracketViewModel()
    var isLoading = false
    var bracketMatches: FWCBracketMatches? = FWCBracketData.placeholderMatches
    var selectedRound: FWCBracketRound = .roundOf32
    var hasInitializedSelectedRound = false

    func determineCurrentRound() -> FWCBracketRound { ... }
}
```

`determineCurrentRound()` retourne le round actif selon la date du jour (comparaison avec les dates FWC2026). Retourne `.roundOf32` par défaut avant le tournoi.

---

## Layout Canvas

### Dimensions

- Canvas : `1380 × 2200 pt`
- Card : `width=160pt`, `height=70pt`
- Espacement vertical R32 : `130pt` entre les tops de cartes (identique AFCON)

### Positions X des colonnes

| Round | x (left edge) |
|-------|---------------|
| R32   | 20            |
| R16   | 300           |
| QF    | 580           |
| SF    | 860           |
| Final | 1140          |

### Positions Y (centres des cartes, `top + cardHeight/2`)

**R32** — 16 matchs, tops à `[60, 190, 320, 450, 580, 710, 840, 970, 1100, 1230, 1360, 1490, 1620, 1750, 1880, 2010]`

**R16** — 8 matchs, centres = moyenne de chaque paire R32 :
`[160, 420, 680, 940, 1200, 1460, 1720, 1980]`

**QF** — 4 matchs :
`[290, 810, 1330, 1850]`

**SF** — 2 matchs :
`[550, 1590]`

**Final** — centre à `1070`

**3e Place** — `final center + 150 = 1220`

### Lignes de connexion (Canvas SwiftUI)

Même pattern bracket-lines que l'AFCON — lignes coudées horizontales reliant chaque paire au round suivant :

| Segment      | Couleur               | Style          |
|--------------|-----------------------|----------------|
| R32 → R16    | `fifaBlue` op. 0.4    | lineWidth 2    |
| R16 → QF     | `fifaBlue` op. 0.4    | lineWidth 2    |
| QF → SF      | `fifaBlue` op. 0.5    | lineWidth 2    |
| SF → Final   | `fifaBlue` op. 0.7    | lineWidth 3    |
| SF → 3e Pl.  | `fifaGold` op. 0.4    | dash [5,5] lw2 |

### Round Picker

Scroll horizontal identique à l'AFCON, couleur active `fifaBlue`. Labels :

```
[Seizièmes]  [Huitièmes]  [Quarts]  [Demi-finales]  [Finale]
```

Auto-scroll vers le round sélectionné via `ScrollViewProxy` + `.id()` anchors sur les premières cartes de chaque round (délai 0.2s, animation `.easeInOut(0.8s)`).

### Match Cards

Réutilisation de `MatchCardView` (TournamentKit / AFCON2025). Paramètre `isFinal: true` sur la carte Finale → border `fifaGold` au lieu de `moroccoRed`.

> **Note :** `MatchCardView` utilise actuellement `Color("moroccoRed")` et `Color("moroccoGreen")` en dur. Pour le FWC, soit on passe les couleurs en paramètre, soit on crée une `FWCMatchCardView` dans le target FWC qui utilise `fifaBlue` / `fifaGold`. À décider à l'implémentation — hors scope de ce spec.

### Header

```
🏆  FIFA World Cup 2026  🏆
USA · Canada · Mexico
11 June – 19 July 2026
```

Couleurs : `fifaBlue` pour l'accent.

---

## Scroll Anchors (IDs SwiftUI)

| Anchor ID             | Cible                         |
|-----------------------|-------------------------------|
| `"r32"`               | Label "Seizièmes"             |
| `"r16"`               | Label "Huitièmes"             |
| `"quarterfinals"`     | Label "Quarts"                |
| `"semifinals_first"`  | Première carte demi-finale    |
| `"final_anchor"`      | Carte Finale                  |
| `"third_place_anchor"`| Carte 3e Place                |

---

## Ce qui n'est PAS dans ce spec

- Intégration API (standings FWC → résolution des pairings réels) — phase suivante
- Couleurs `MatchCardView` adaptées au thème FWC — à adresser séparément
- Données réelles R32 (dates, stades, pairings) — remplacement des placeholders à faire quand disponibles
