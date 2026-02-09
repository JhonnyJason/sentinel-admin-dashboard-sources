############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("playgroundcontroller")
#endregion

############################################################
import * as uiHandles from "./uihandles.js"
import { getAllAreas } from "./economicareasmodule.js"
import { ScoringModel } from "./ScoringModel.js"

############################################################
# Central orchestrator for the ForexScore Playground
# - Manages original and live copies of EconomicAreas
# - Holds ScoringModel (diff params + final weights + calculation)
# - Wires UI handles to data with correct listener ordering
# - Triggers recalculation on changes

############################################################
originalAreas = {}  # untouched backend data
liveAreas = {}      # clones modified by UI
scoringModel = null

############################################################
currentBaseKey = null
currentQuoteKey = null

############################################################
quoteHandles = {}
baseHandles = {}

############################################################
export initialize = ->
    log "initialize"

    # Clone all areas: originals stay untouched, live copies for UI
    allAreas = getAllAreas()
    for key, area of allAreas
        originalAreas[key] = area
        liveAreas[key] = area.clone()
        # Listen for backend data changes on originals
        area.addUpdateListener(createOriginalUpdateListener(key))

    scoringModel = new ScoringModel()

    # Wiring up all uiHandles that need the scoringModel    
    resultBoxHandle = uiHandles.getHandle("resultBoxHandle")
    resultBoxHandle.setModel(scoringModel)
    
    inflDiffHandle = uiHandles.getHandle("inflDiffHandle")
    inflDiffHandle.setModel(scoringModel)

    mrrDiffHandle = uiHandles.getHandle("mrrDiffHandle")
    mrrDiffHandle.setModel(scoringModel)

    gdpgDiffHandle = uiHandles.getHandle("gdpgDiffHandle")
    gdpgDiffHandle.setModel(scoringModel)

    cotDiffHandle = uiHandles.getHandle("cotDiffHandle")
    cotDiffHandle.setModel(scoringModel)

    # just sorting the Handles and keeping them handy
    baseHandles.makroData = uiHandles.getHandle("baseAreaHandle")
    baseHandles.inflNorm = uiHandles.getHandle("baseInflNormHandle")
    baseHandles.mrrNorm = uiHandles.getHandle("baseMrrNormHandle")
    baseHandles.gdpgNorm = uiHandles.getHandle("baseGdpgNormHandle")
    baseHandles.cotNorm =  uiHandles.getHandle("baseCotNormHandle")

    quoteHandles.makroData = uiHandles.getHandle("quoteAreaHandle")
    quoteHandles.inflNorm = uiHandles.getHandle("quoteInflNormHandle")
    quoteHandles.mrrNorm = uiHandles.getHandle("quoteMrrNormHandle")
    quoteHandles.gdpgNorm = uiHandles.getHandle("quoteGdpgNormHandle")
    quoteHandles.cotNorm =  uiHandles.getHandle("quoteCotNormHandle")

    # Wire reset listeners only on makro data handle
    baseHandles.makroData.addResetListener(onBaseLiveReset)
    quoteHandles.makroData.addResetListener(onQuoteLiveReset)

    # Wire Other UiHandles directly to generalParamChanged
    baseHandles.inflNorm.addOnChangeListener(generalParamChanged)
    baseHandles.mrrNorm.addOnChangeListener(generalParamChanged)
    baseHandles.gdpgNorm.addOnChangeListener(generalParamChanged)
    baseHandles.cotNorm.addOnChangeListener(generalParamChanged)

    quoteHandles.inflNorm.addOnChangeListener(generalParamChanged)
    quoteHandles.mrrNorm.addOnChangeListener(generalParamChanged)
    quoteHandles.gdpgNorm.addOnChangeListener(generalParamChanged)
    quoteHandles.cotNorm.addOnChangeListener(generalParamChanged)
    return

############################################################
export setFocusPair = (baseKey, quoteKey) ->
    log "setFocusPair: #{baseKey}/#{quoteKey}"
    # Disconnet from old Areas
    baseLive = liveAreas[baseKey]
    quoteLive = liveAreas[quoteKey]

    unless baseLive and quoteLive
        log "Unknown area key: #{baseKey} or #{quoteKey}"
        return

    unwireLiveAreas()
    currentBaseKey = baseKey
    currentQuoteKey = quoteKey

    # Wire controller listeners FIRST (before setArea adds UI listener)
    # This ensures: controller update → UI update (correct order)
    baseLive.addUpdateListener(onBaseLiveUpdate)
    quoteLive.addUpdateListener(onQuoteLiveUpdate)

    # Wire handles to live areas (adds UI listeners second)
    for key, handles of baseHandles
        handles.setArea(baseLive)
    for key, handles of quoteHandles
        handles.setArea(quoteLive)

    # Wire scoring model to result box
    scoringModel.setAreas(baseLive, quoteLive)
    return

############################################################
unwireLiveAreas = ->
    baseLive = liveAreas[currentBaseKey]
    quoteLive = liveAreas[currentQuoteKey]

    if baseLive? then baseLive.removeUpdateListener(onBaseLiveUpdate)
    if quoteLive? then quoteLive.removeUpdateListener(onQuoteLiveUpdate)

    #disconnect uiHandles first
    for key, handles of baseHandles
        handles.unsubscribe()
    for key, handles of quoteHandles
        handles.unsubscribe()
    return

############################################################
# Creates a listener for original area updates (backend data changes)
# Syncs to live clone if not modified by user
createOriginalUpdateListener = (key) -> ->
    live = liveAreas[key]
    original = originalAreas[key]
    return unless live? and original?

    # Only sync if user hasn't modified this area
    return if live.isModified()

    # Sync original data to live clone (triggers live's listeners → UI update)
    live.updateData(original.copyData())
    return

############################################################
generalParamChanged = ->
    log "generalParamChanged"
    if scoringModel? then scoringModel.recalculate()
    return 

############################################################
onQuoteLiveUpdate = -> onAreaUpdate(currentQuoteKey)
onBaseLiveUpdate = -> onAreaUpdate(currentBaseKey)

############################################################
onAreaUpdate = (areaKey) ->
    live = liveAreas[areaKey]
    original = originalAreas[areaKey]
    return unless live? and original? 

    # recognize what is modified agains the original data
    live.setModifiedAgainst(original)

    # Trigger recalculation
    scoringModel.recalculate()
    return

############################################################
onQuoteLiveReset = -> resetArea(currentQuoteKey)
onBaseLiveReset = -> resetArea(currentBaseKey)

############################################################
export resetArea = (areaKey) ->
    log "resetArea: #{areaKey}"
    live = liveAreas[areaKey]
    original = originalAreas[areaKey]
    return unless live? and original?

    # Copy original data back to live area (triggers updateListeners)
    live.updateData(original.copyData())
    return

############################################################
export getWorkingArea = (key) -> liveAreas[key]
export getScoringModel = -> scoringModel
export getCurrentPair = -> { base: currentBaseKey, quote: currentQuoteKey }
