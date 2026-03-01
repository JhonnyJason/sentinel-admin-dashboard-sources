# Data Module - Data Contract Specification

## Overview

This document defines the data structures for communication between the Admin Dashboard and the Sentinel Backend.

**Connection Flow:**
1. WebSocket connect → `authorizeAdmin <authMessage>`
2. Server responds `authorizationApproved`
3. Client sends `getAllMakroData` → server responds `allMakroData`
4. Client sends `getAllHistory` → server responds `allHistory`
5. Mutation commands during session (save, publish, create, rename)

**Wire Format:**
- No-payload: `socket.send("commandName")`
- With payload: `socket.send("commandName <JSON>")`
- Responses: JSON with `type` field

---

## Commands (Client -> Server)

| Command | Payload | Response Type |
|---------|---------|---------------|
| `getAllMakroData` | -- | `allMakroData` |
| `getAllHistory` | -- | `allHistory` |
| `createEntry` | `{ name, snapshot }` | `createEntryResult` |
| `saveEntry` | `{ name, snapshot }` | `saveEntryResult` |
| `publishEntry` | `{ name, version }` | `publishEntryResult` |
| `renameEntry` | `{ oldName, newName }` | `renameEntryResult` |

---

## getAllMakroData Response

Makro data per economic area.

```json
{
  "type": "allMakroData",
  "payload": {
    "eurozone": {
      "infl": 2.1,
      "inflMeta": { "dataSet": "...", "source": "ECB", "date": "2024-01" },
      "mrr": 4.5,
      "mrrMeta": { "dataSet": "...", "source": "ECB", "date": "2024-01-15" },
      "gdpg": 0.8,
      "gdpgMeta": { "dataSet": "...", "source": "Eurostat", "date": "2024-Q4" },
      "cot6": 45.2,
      "cot36": 62.1
    },
    "usa": { "...same structure..." },
    "...other areas..."
  }
}
```

### Area Keys
- `eurozone`, `usa`, `japan`, `uk`, `canada`, `australia`, `switzerland`, `newzealand`

---

## getAllHistory Response

Full experiment history (all named experiments with version arrays + published state).

```json
{
  "type": "allHistory",
  "entries": {
    "Experiment 1": [ { "areaParams": {}, "globalParams": {} } ],
    "My Setup": [ { "...snapshot v0..." }, { "...snapshot v1..." } ]
  },
  "published": { "name": "Experiment 1", "version": 0 }
}
```

- `entries`: map of experiment name -> array of snapshots (index = version)
- `published`: which experiment+version is currently published, or `null`

### Snapshot Structure
```json
{
  "areaParams": {
    "eurozone": { "infl": {}, "mrr": {}, "gdpg": {}, "cot": {} },
    "...other areas..."
  },
  "globalParams": {
    "diffCurves": { "infl": {}, "mrr": {}, "gdpg": {}, "cot": {} },
    "finalWeights": { "st": {}, "ml": {}, "lt": {} }
  }
}
```

---

## Mutation Commands

All mutations return `{ type: "<commandName>Result", ok: true }` on success or `{ type: "<commandName>Result", ok: false, message: "..." }` on error.

### createEntry
Create a new named experiment with initial snapshot.
```json
{ "name": "Experiment 1", "snapshot": { "areaParams": {}, "globalParams": {} } }
```

### saveEntry
Append a new version to an existing experiment.
```json
{ "name": "Experiment 1", "snapshot": { "areaParams": {}, "globalParams": {} } }
```

### publishEntry
Mark a specific experiment+version as published (active for users).
```json
{ "name": "Experiment 1", "version": 0 }
```

### renameEntry
Rename an existing experiment.
```json
{ "oldName": "Experiment 1", "newName": "My Setup" }
```

---

## WebSocket Update Messages (Server -> Client)

Fine-grained updates after initial load (future).

### Area Data Update
```json
{ "type": "areaData", "key": "eurozone", "data": { "infl": 2.2 } }
```

---

## Mock Mode

When `noNetwork = true`, datamodule skips WebSocket entirely:
- `loadMockData()` feeds mock area data from configmodule
- `downSyncExperimentStore(null)` bootstraps a fresh Experiment 1 with defaults

All mutation commands (`createEntry`, `saveEntry`, etc.) return `{ ok: true }` immediately in mock mode.
