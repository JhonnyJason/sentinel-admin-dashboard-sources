# forexscoreversion

Version control UI for ForexScore parameter experiments.

## Purpose
Allows the admin to manage named experiments, each with a version history of parameter snapshots. Provides save, publish, open, and version-switch operations.

## Architecture

### Coordination Model

`forexscoreversion.coffee` is the central coordinator. It owns the ExperimentStore,
calls into playgroundcontroller for snapshot/apply, and directly updates its own UI.
No observer/listener pattern on the store — all state transitions flow through
forexscoreversion.coffee which knows what UI to update after each operation.

### ExperimentStore (ExperimentStore.coffee)
Pure data container. No DOM, no imports from playground, no listeners.

**Storage shape:**
```
experiments: { "<name>": [snapshot_v0, snapshot_v1, ...] }
published: { name: "<name>", version: <index> } | null
current: { name: "<name>", version: <index> } | null
baseSnapshot: <snapshot> | null    # last saved/loaded state
liveSnapshot: <snapshot> | null    # current working state (updated on every param change)
```

**Modified detection:** `isModified()` compares `liveSnapshot` against `baseSnapshot`.
No dirty flag — the two snapshots ARE the source of truth.
- On create/open/save/selectVersion: both baseSnapshot and liveSnapshot are set to the same value
- On param change: only liveSnapshot is updated
- isModified() = deep comparison of the two

**Snapshot structure:**
```
{
  areaParams: {
    eurozone: { infl: {a,b,c}, mrr: {a,b}, gdpg: {a,b,c}, cot: {f,e} },
    usa: { ... }, japan: { ... }, ...
  },
  globalParams: {
    diffCurves: { infl: {b,d}, mrr: {b,d}, gdpg: {b,d}, cot: {b,d} },
    finalWeights: { st: {i,l,g,c}, ml: {i,l,g,c}, lt: {i,l,g,c} }
  }
}
```

**Key methods:**
- `createNew(baseSnapshot)` - new experiment with given snapshot as v0, sets base=live=snapshot
- `open(name)` - switch to existing experiment (latest version), sets base=live=stored snapshot
- `save(snapshot)` - append new version to current experiment, sets base=live=snapshot
- `selectVersion(index)` - switch to a specific version, sets base=live=stored snapshot
- `rename(newName)` - rename current experiment
- `publish()` - mark current experiment+version as published
- `updateLiveSnapshot(snapshot)` - called on every param change, updates liveSnapshot only
- `isModified()` - compares liveSnapshot vs baseSnapshot
- `getCurrentSnapshot()` - returns deep copy of stored version snapshot
- `getExperimentNames()` - for the open dropdown
- `getVersionCount()` - for the version dropdown
- `isAtPublished()` - is current experiment+version the published one?
- `getPublishedInfo()` - which experiment+version is published

**Auto-naming:** "Experiment X" where X is the lowest integer > 0 whose name is not taken.

### VersionHandle (in forexscoreversion.coffee)
DOM wiring for the version control bar.

**UI elements:**
- Experiment name input (editable = rename)
- "New" button (create new with defaults)
- "Copy" button (create new from current)
- "Open" select (pick existing experiment)
- "Version" select (pick version within experiment)
- "Save" button (+ blue dot indicator for unsaved changes)
- "Publish" button (+ state indicator)

**Button states:**
| State | Save | Publish |
|-------|------|---------|
| Has unsaved changes (isModified) | enabled + blue dot | disabled |
| Saved, not published version | disabled | enabled |
| At published version | disabled | enabled (special color, no-op) |

### Integration Flows

#### Flow A: User edits a parameter
```
NormHandle changes area param → generalParamChanged (playgroundcontroller)
  → playgroundcontroller calls forexscoreversion.onParamsChanged()
  → forexscoreversion: snapshot = playgroundcontroller.snapshotParams()
  → forexscoreversion: store.updateLiveSnapshot(snapshot)
  → forexscoreversion: updates UI (save button state based on store.isModified())
```
Note: Currently only NormHandle changes are wired to generalParamChanged.
DiffHandle and WeightHandle will be wired the same way when implemented.

#### Flow B: User hits Save
```
forexscoreversion: snapshot = playgroundcontroller.snapshotParams()
  → store.save(snapshot)  // appends version, sets base=live
  → forexscoreversion: updates UI (save disabled, version dropdown updated)
```

#### Flow C: User loads a version (open/selectVersion)
```
forexscoreversion: store.open(name) or store.selectVersion(index)
  → snapshot = store.getCurrentSnapshot()
  → playgroundcontroller.applyParams(snapshot)  // writes to areas + model, triggers recalc
  → forexscoreversion: updates UI (save disabled, version/experiment labels)
```

### Required additions to other modules

**EconomicArea** — add `setParams(p)`: bulk-set normalization params, triggers updateListeners
**ScoringModel** — add `setDiffParams(p)`, `setFinalWeights(w)`: bulk-set global params

**playgroundcontroller** — add:
- `snapshotParams()` — reads all liveAreas.copyParams() + scoringModel params → snapshot
- `applyParams(snapshot)` — writes into all liveAreas + scoringModel, triggers recalc + UI refresh
- `generalParamChanged` calls `forexscoreversion.onParamsChanged()`

### Publish flow
Publish sends a WebSocket command via datamodule. For now we act as if it always succeeds (backend may not understand the command yet, that's fine).

## Storage
In-memory only. No localStorage. Experiments are lost on page refresh. Backend persistence is a future task.

## Not in scope
- "Show full ranking" - separate task
- Backend persistence of experiments
- Multi-user conflict resolution
