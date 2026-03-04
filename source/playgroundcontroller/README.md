# Playground Controller

Central orchestrator for the ForexScore Playground.

## Responsibilities

1. **Working copies of all EconomicAreas** - cloned from originals for user manipulation
2. **ScoreCombinator** - diff curve params + final combination weights + calculation
3. **Update propagation** - notify UI when state changes
4. **Coordination** with forexscoreversion for history/checkpoints

## Data Model

```
playgroundcontroller
├── originalAreas      # Reference to economicareamodule.getAllAreas()
├── liveAreas       # { eurozone: EconomicArea, usa: EconomicArea, ... }
│                      # Cloned copies - user edits happen here
├── ScoreCombinator       # ScoreCombinator instance (see below)
└── updateListeners[]  # Notified on any state change
```

### LiveAreas vs OriginalAreas
While we need a full set to correcly display the any full scoring list, for the purpose of "reseting" to the real original makro-data a separate set which only contains the original makro data is very useful.

### ScoreCombinator

Handles pair-level scoring (diffs + combination). Moved to `scoringmodule/ScoreCombinator.coffee`.

```coffee
ScoreCombinator = {
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
        │    → ScoreCombinator.recalculate()
        │    → ScoreCombinator fires listeners
        │    → ResultBoxHandle/DiffHandle refresh
        │
        └──► Reset → copyFromOriginal(areaKey)
                     → fires updateListeners
```

## API

### State Access

```coffee
getLiveArea(key)      # Get working copy of area
getAllLiveAreas()     # Get all working areas
getScoreCombinator()        # Get ScoreCombinator instance
```

### Focus Pair

```coffee
setFocusPair(baseKey, quoteKey)  # Set current pair, triggers recalculation
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
- Gets working areas via `getLiveArea()`
- Passes areas to UI handles
- Passes ScoreCombinator to ResultBoxHandle/DiffHandle

### uihandles / MakroDataHandle
- Receives EconomicArea instance via `setArea()`
- Displays working area data
- On input: calls `area.updateData()` directly
- Area fires listeners → playgroundcontroller recalculates

### uihandles / ResultBoxHandle / DiffHandle
- Receives ScoreCombinator via `setModel()`
- Displays scoring results
- On input: calls `ScoreCombinator.updateDiffParam()` or `updateFinalWeight()`
- ScoreCombinator fires listeners → handle refreshes

### forexscoreversion
- Reads current state for saving checkpoints
- Provides "reset to last published" by calling reset functions
- Manages history of parameter changes
