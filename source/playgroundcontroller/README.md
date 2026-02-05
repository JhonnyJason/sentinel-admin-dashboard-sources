# Playground Controller

Central orchestrator for the ForexScore Playground.

## Responsibilities

1. **Working copies of all EconomicAreas** - cloned from originals for user manipulation
2. **ScoringModel** - diff curve params + final combination weights + calculation
3. **Update propagation** - notify UI when state changes
4. **Coordination** with forexscoreversion for history/checkpoints

## Data Model

```
playgroundcontroller
├── originalAreas      # Reference to economicareamodule.getAllAreas()
├── workingAreas       # { eurozone: EconomicArea, usa: EconomicArea, ... }
│                      # Cloned copies - user edits happen here
├── scoringModel       # ScoringModel instance (see below)
└── updateListeners[]  # Notified on any state change
```

### Why copy ALL areas?

Future feature: Display full ranking of all 28 forex pairs with modified parameters.
Each pair uses two areas (base/quote), so all areas must reflect current working state.

### ScoringModel

Handles pair-level scoring (diffs + combination). See `ScoringModel.coffee`.

```coffee
scoringModel = {
    diffParams: {
        infl: { b: 1.0, d: 1.0 }   # cubic diff curve params
        mrr:  { b: 1.0, d: 1.0 }
        gdpg: { b: 1.0, d: 1.0 }
        cot:  { b: 1.0, d: 1.0 }
    }
    finalWeights: {
        st:  { i: 1.0, l: 1.0, g: 1.0, c: 1.0 }  # short term
        ml:  { i: 1.0, l: 1.0, g: 1.0, c: 1.0 }  # medium-long term
        lt:  { i: 1.0, l: 1.0, g: 1.0, c: 1.0 }  # long term
    }
    # + calculated results after recalculate()
}
```

## Data Flow

```
economicareamodule (original backend data)
        │
        ▼
playgroundcontroller.initialize()
        │ clone all areas
        ▼
workingAreas (user manipulates these)
        │
        ├──► UI Handles display working data
        │
        ├──► User edits area data
        │    → EconomicArea.updateData()
        │    → area fires listeners
        │    → playgroundcontroller.onAreaChanged()
        │    → scoringModel.recalculate()
        │    → scoringModel fires listeners
        │    → ResultBoxHandle/DiffHandle refresh
        │
        └──► Reset → copyFromOriginal(areaKey)
                     → fires updateListeners
```

## API

### State Access

```coffee
getWorkingArea(key)      # Get working copy of area
getAllWorkingAreas()     # Get all working areas
getScoringModel()        # Get ScoringModel instance
```

### Focus Pair

```coffee
setFocusPair(baseKey, quoteKey)  # Set current pair, triggers recalculation
getCurrentPair()                  # Get current { base, quote } keys
```

### Reset

```coffee
resetArea(areaKey)       # Copy original → working for one area
resetAllAreas()          # Copy all originals → working
```

### Listeners

```coffee
addUpdateListener(fn)    # Called on any state change
removeUpdateListener(fn)
```

## Interaction with Other Modules

### forexscoreplayground
- Calls `setFocusPair(baseKey, quoteKey)`
- Gets working areas via `getWorkingArea()`
- Passes areas to UI handles
- Passes scoringModel to ResultBoxHandle/DiffHandle

### uihandles / MakroDataHandle
- Receives EconomicArea instance via `setArea()`
- Displays working area data
- On input: calls `area.updateData()` directly
- Area fires listeners → playgroundcontroller recalculates

### uihandles / ResultBoxHandle / DiffHandle
- Receives ScoringModel via `setModel()`
- Displays scoring results
- On input: calls `scoringModel.updateDiffParam()` or `updateFinalWeight()`
- ScoringModel fires listeners → handle refreshes

### forexscoreversion
- Reads current state for saving checkpoints
- Provides "reset to last published" by calling reset functions
- Manages history of parameter changes
