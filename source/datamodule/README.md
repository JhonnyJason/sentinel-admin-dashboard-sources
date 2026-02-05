# Data Module - Data Contract Specification

## Overview

This document defines the data structures for communication between the Admin Dashboard and the Sentinel Backend.

**Data Flow:**
- `getAllData` - Initial load (when no data present)
- WebSocket messages - Fine-grained updates during session
- Admin actions - Parameter changes pushed to server

---

## getAllData Response

Extended to include parameters alongside makro data.

```json
{
  "eurozone": {
    "infl": 2.1,
    "inflMeta": { "dataSet": "...", "source": "ECB", "date": "2024-01" },
    "mrr": 4.5,
    "mrrMeta": { "dataSet": "...", "source": "ECB", "date": "2024-01-15" },
    "gdpg": 0.8,
    "gdpgMeta": { "dataSet": "...", "source": "Eurostat", "date": "2024-Q4" },
    "cot6": 45.2,
    "cot36": 62.1,
    "params": {
      "inflation": { "a": 1.667, "b": 0.667, "c": -0.083 },
      "interest": { "a": -2.5, "b": 1.0 },
      "gdp": { "a": 2.25, "b": 0.75, "c": -0.188 },
      "cot": { "f": 1.0 }
    }
  },
  "usa": { "...same structure..." },
  "japan": { "..." },
  "uk": { "..." },
  "canada": { "..." },
  "australia": { "..." },
  "switzerland": { "..." },
  "newzealand": { "..." },

  "_params": {
    "diffCurves": {
      "inflation": { "b": 1.4, "d": 0.12 },
      "interest": { "b": 0, "d": 0.04 },
      "gdp": { "b": 1.4, "d": 0.12 },
      "cot": { "b": 0, "d": 0.01 }
    },
    "weights": { "i": 6, "l": 9, "g": 3, "c": 13 },
    "version": "2024-01-15T10:30:00Z",
    "isPublished": true
  }
}
```

### Area Keys
- `eurozone`, `usa`, `japan`, `uk`, `canada`, `australia`, `switzerland`, `newzealand`

### Area Params Structure
| Category | Params | Formula |
|----------|--------|---------|
| `inflation` | `{ a, b, c }` | `a + b*x + c*x²` (clamped ≥0) |
| `interest` | `{ a, b }` | `a + b*x` |
| `gdp` | `{ a, b, c }` | `a + b*x + c*x²` (clamped ≥0) |
| `cot` | `{ f }` | `f * (c6 * c32²)` where c6/c32 = 0.02 * index |

### Global Params Structure
| Category | Params | Usage |
|----------|--------|-------|
| `diffCurves.*` | `{ b, d }` | `b*diff + d*diff³` |
| `weights` | `{ i, l, g, c }` | `i*infScore + l*intScore + g*gdpScore + c*cotScore` |

---

## WebSocket Update Messages (Server → Client)

Fine-grained updates after initial load.

### Area Data Update
Makro values changed (new data from sources).
```json
{
  "type": "areaData",
  "key": "eurozone",
  "data": {
    "infl": 2.2,
    "inflMeta": { "dataSet": "...", "source": "ECB", "date": "2024-02" }
  }
}
```
*Note: Only changed fields included.*

### Area Params Update
Admin changed normalization params for an area.
```json
{
  "type": "areaParams",
  "key": "eurozone",
  "params": {
    "inflation": { "a": 1.7, "b": 0.65, "c": -0.08 }
  }
}
```

### Global Params Update
Admin changed diff curves or weights.
```json
{
  "type": "globalParams",
  "params": {
    "weights": { "i": 7, "l": 8, "g": 4, "c": 12 }
  }
}
```

---

## Admin Push Messages (Client → Server)

### Save Experimental (Unpublished)
Saves current params to history without publishing to users.
```json
{
  "action": "saveParams",
  "areaParams": {
    "eurozone": { "inflation": { "a": 1.7, "b": 0.65, "c": -0.08 } }
  },
  "globalParams": {
    "weights": { "i": 7, "l": 8, "g": 4, "c": 12 }
  },
  "note": "Testing higher inflation weight"
}
```
*Response:*
```json
{ "ok": true, "historyId": "exp-2024-01-15T14:22:00Z" }
```

### Publish (Checkpoint)
Saves and publishes params - becomes active for all users.
```json
{
  "action": "publishParams",
  "areaParams": { "...full or partial..." },
  "globalParams": { "..." },
  "note": "Q1 2024 calibration"
}
```
*Response:*
```json
{ "ok": true, "historyId": "pub-2024-01-15T14:30:00Z", "version": "2024-01-15T14:30:00Z" }
```

### Reset to Last Published
Discards experimental changes, reverts to last checkpoint.
```json
{
  "action": "resetToPublished"
}
```
*Response: Server sends full params via `areaParams` + `globalParams` messages.*

### Get History
Retrieve recent parameter history.
```json
{
  "action": "getHistory",
  "limit": 20
}
```
*Response:*
```json
{
  "history": [
    {
      "id": "pub-2024-01-15T14:30:00Z",
      "timestamp": "2024-01-15T14:30:00Z",
      "type": "published",
      "note": "Q1 2024 calibration",
      "params": { "...snapshot..." }
    },
    {
      "id": "exp-2024-01-15T14:22:00Z",
      "timestamp": "2024-01-15T14:22:00Z",
      "type": "experimental",
      "note": "Testing higher inflation weight",
      "params": { "...snapshot..." }
    }
  ]
}
```

### Load from History
Load a specific history entry (for comparison/restore).
```json
{
  "action": "loadFromHistory",
  "historyId": "exp-2024-01-15T14:22:00Z"
}
```
*Response: Server sends params via update messages (does not publish).*

---

## Defaults (UI-Only)

Neutral balanced defaults are calculated and stored in `configmodule.coffee`.
These are not relevant to the server - used only for local "reset to neutral" in the playground.

See `configmodule.coffee` for `neutralAreaParams` and `neutralGlobalParams`.

---

## History Entry Types

| Type | Prefix | Description |
|------|--------|-------------|
| `experimental` | `exp-` | Saved but not active for users |
| `published` | `pub-` | Checkpoint, active for all users |

Server maintains history with:
- Timestamp
- Type (experimental/published)
- Note (admin description)
- Full params snapshot
