# forexscoreplayground

Main grid UI for the ForexScore Parameter Playground. Displays a 3x5 grid of interactive cells for manipulating scoring parameters.

## Architecture

Uses a **Handle pattern** for clean separation:

| Layer | Files | Responsibility |
|-------|-------|----------------|
| Structure | `*.pug` | Static declarative layout |
| Styles | `*.styl` | Visual styling |
| Logic | `*Handle.coffee` | DOM interaction, event handling |

### Why Handles?

Instead of functions that inject HTML via `innerHTML` or `document.createElement`, we:
1. Define structure once in Pug (compiled at build time)
2. Handle classes cache DOM refs and wire events
3. `refreshUI()` methods update display from data model

This keeps file sizes small, logic separated, and structure reusable.

## Grid Layout (3 columns × 5 rows)

```
┌─────────────┬─────────────┬─────────────┐
│ Base Area   │ Quote Area  │ Results     │
│ (makro-el)  │ (makro-el)  │ (result-el) │
├─────────────┼─────────────┼─────────────┤
│ Inf Norm    │ Inf Norm    │ Inf Diff    │
│ (quadnorm)  │ (quadnorm)  │ (cubdiff)   │
├─────────────┼─────────────┼─────────────┤
│ MRR Norm    │ MRR Norm    │ MRR Diff    │
│ (mrrnorm)   │ (mrrnorm)   │ (cubdiff)   │
├─────────────┼─────────────┼─────────────┤
│ GDP Norm    │ GDP Norm    │ GDP Diff    │
│ (quadnorm)  │ (quadnorm)  │ (cubdiff)   │
├─────────────┼─────────────┼─────────────┤
│ COT Norm    │ COT Norm    │ COT Diff    │
│ (cotnorm)   │ (cotnorm)   │ (cubdiff)   │
└─────────────┴─────────────┴─────────────┘
```

## Components

### components/makro-el.pug
Economic area display with editable macro data (Inflation, MRR, GDP, COT).
Handle: `MakroDataHandle`

### components/result-el.pug
Three result boxes (ST, MLT, LT) showing weighted score equations and final results.
Handle: `ResultBoxHandle`

### components/quadnorm-el.pug
Quadratic normalization for Inflation and GDP.
Params: peak, steepness → derived zeros feedback.
Displays full equation: `n(x) = a + b·x + c·x² = result`
Handle: `QuadNormHandle` (implemented)

### components/mrrnorm-el.pug
Linear normalization for interest rate (MRR).
Params: floor, neutral-rate, ceiling, punishment.
Handle: `MrrNormHandle`

### components/cotnorm-el.pug
COT normalization with f-factor.
Handle: `CotNormHandle`

### components/cubdiff-el.pug
Cubic diff curves for weighing base-quote differences.
Params: b, d.
Handle: `DiffHandle`

## Files

```
forexscoreplayground/
├── forexscoreplayground.pug    # Main grid structure
├── forexscoreplayground.coffee # Module logic (being refactored)
├── styles.styl                 # Main styles
├── uihandles.coffee            # Handle instantiation
├── MakroDataHandle.coffee
├── ResultBoxHandle.coffee
├── normmath.coffee             # Pure math: param conversions (peak/steepness ↔ a,b,c)
├── QuadNormHandle.coffee
├── MrrNormHandle.coffee
├── CotNormHandle.coffee
├── DiffHandle.coffee
└── components/
    ├── README.md
    ├── common.styl
    ├── makro-el.pug + .styl
    ├── makro-data-row.pug
    ├── result-el.pug + .styl
    ├── result-inner.pug
    ├── quadnorm-el.pug + .styl
    ├── mrrnorm-el.pug + .styl
    ├── cotnorm-el.pug + .styl
    └── cubdiff-el.pug + .styl
```

## Status

**Complete:**
- All Pug structures defined
- Styles for makro-el and result-el
- `normmath.coffee` - param conversion utilities (extracted from deprecated scoringmodule)
- `QuadNormHandle` - full implementation
- `MrrNormHandle` - full implementation

**In Progress:**
- CotNormHandle, DiffHandle implementations
- Wiring handles into playgroundcontroller

**TODO:**
- Complete remaining Handle implementations
- Remove old render functions from forexscoreplayground.coffee
