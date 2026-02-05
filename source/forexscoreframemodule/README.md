# forexscoreframemodule

Container module for the ForexScore Playground feature. This is the top layer navigation frame and contains: version management, pair selection and the playground.

## Structure
See `./forexscoreframe.pug`

## Migration Notice

**The main playground grid is being migrated to `forexscoreplayground/`.**

The old `focuspairmodule.coffee` contained inline HTML generation via `innerHTML` and `document.createElement`. This is being refactored to:

1. **Declarative Pug templates** in `forexscoreplayground/components/`
2. **Handle classes** that manage DOM interaction without creating elements
3. **Separated styles** per component

See `sources/source/forexscoreplayground/README.md` for the new architecture.

### Files in this module

| File | Status |
|------|--------|
| `forexscoreframemodule.coffee` | Active - module init, pair selection |
| `forexscoreframe.pug` | Active - includes child modules |
| `focuspairmodule.coffee` | **Deprecated** - kept as reference during migration |
| `comboboxfun.coffee` | Active - reusable combobox logic |
| `scoringmodule.coffee` | Active - calculation engine |
| `styles.styl` | Active - imports component styles |
| `combobox.styl` | Active |
| `focuspair.styl` | Active - grid and cell styles |

### Known Issues

**Style imports:** `focuspair.styl` imports from `components/` but those files are now in `forexscoreplayground/components/`. This needs to be resolved:
- Option A: Move `focuspair.styl` to `forexscoreplayground/`
- Option B: Fix import paths to `../forexscoreplayground/components/`

### After migration

Once `forexscoreplayground/` is complete:
- `focuspairmodule.coffee` can be deleted
- This module will only handle the frame container and pair selection
