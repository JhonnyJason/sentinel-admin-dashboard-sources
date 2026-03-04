# forexscoreframemodule

Container module for the ForexScore Playground feature. This is the top layer frame and containing all relevant sub-components: version management, pair selection, the playground and the full display of current configuration ranking.

## Files

- `forexscoreframemodule.coffee`- imports and initializes all components
- `forexscoreframe.pug` - structure of the frame including all components
- `styles.styl` - importing al relevant component styles

### Known Issues

**Style imports:** `focuspair.styl` imports from `components/` but those files are now in `forexscoreplayground/components/`. This needs to be resolved:
- Option A: Move `focuspair.styl` to `forexscoreplayground/`
- Option B: Fix import paths to `../forexscoreplayground/components/`

