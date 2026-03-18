############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("playgroundcontroller")
#endregion

############################################################
import * as uiHandles from "./uihandles.js"
import { getAllAreas } from "./economicareasmodule.js"
import { ScoreCombinator } from "./ScoreCombinator.js"
import * as versionControl from "./forexscoreversion.js"
import { snapshot as defaultSnapshot } from "./defaultsnapshot.js"
import * as scoreHelper from "./scorehelper.js"
import * as display from "./forexscoredisplay.js"

############################################################
originalAreas = {}  # untouched backend data
liveAreas = {}      # clones modified by UI
scoreCombinator = null

############################################################
currentBaseKey = null
currentQuoteKey = null

############################################################
quoteHandles = {}
baseHandles = {}

############################################################
export initialize = (cfg) ->
    log "initialize"

    # Clone all areas: originals stay untouched, live copies for UI
    allAreas = getAllAreas()
    for key, area of allAreas
        originalAreas[key] = area
        liveAreas[key] = area.clone()
        # Listen for backend data changes on originals
        area.addUpdateListener(createOriginalUpdateListener(key))

    scoreCombinator = new ScoreCombinator()
    scoreHelper.setScoreCombinator(scoreCombinator)

    # initialize our display
    display.initialize(cfg, liveAreas)

    # Wiring up all uiHandles that need the scoreCombinator
    resultBoxHandle = uiHandles.getHandle("resultBoxHandle")
    resultBoxHandle.setModel(scoreCombinator)
    resultBoxHandle.addOnChangeListener(paramChanged)
    resultBoxHandle.setReferenceGetters(
        -> defaultSnapshot.globalParams.finalWeights
        -> versionControl.getStore()?.baseSnapshot?.globalParams?.finalWeights
    )

    inflDiffHandle = uiHandles.getHandle("inflDiffHandle")
    inflDiffHandle.setModel(scoreCombinator)
    inflDiffHandle.addOnChangeListener(paramChanged)
    inflDiffHandle.setReferenceGetters(
        -> defaultSnapshot.globalParams.diffCurves.infl
        -> versionControl.getStore()?.baseSnapshot?.globalParams?.diffCurves?.infl
    )

    mrrDiffHandle = uiHandles.getHandle("mrrDiffHandle")
    mrrDiffHandle.setModel(scoreCombinator)
    mrrDiffHandle.addOnChangeListener(paramChanged)
    mrrDiffHandle.setReferenceGetters(
        -> defaultSnapshot.globalParams.diffCurves.mrr
        -> versionControl.getStore()?.baseSnapshot?.globalParams?.diffCurves?.mrr
    )

    gdpgDiffHandle = uiHandles.getHandle("gdpgDiffHandle")
    gdpgDiffHandle.setModel(scoreCombinator)
    gdpgDiffHandle.addOnChangeListener(paramChanged)
    gdpgDiffHandle.setReferenceGetters(
        -> defaultSnapshot.globalParams.diffCurves.gdpg
        -> versionControl.getStore()?.baseSnapshot?.globalParams?.diffCurves?.gdpg
    )

    cotDiffHandle = uiHandles.getHandle("cotDiffHandle")
    cotDiffHandle.setModel(scoreCombinator)
    cotDiffHandle.addOnChangeListener(paramChanged)
    cotDiffHandle.setReferenceGetters(
        -> defaultSnapshot.globalParams.diffCurves.cot
        -> versionControl.getStore()?.baseSnapshot?.globalParams?.diffCurves?.cot
    )

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

    # Wire norm handles to paramChanged
    baseHandles.inflNorm.addOnChangeListener(paramChanged)
    baseHandles.mrrNorm.addOnChangeListener(paramChanged)
    baseHandles.gdpgNorm.addOnChangeListener(paramChanged)
    baseHandles.cotNorm.addOnChangeListener(paramChanged)

    quoteHandles.inflNorm.addOnChangeListener(paramChanged)
    quoteHandles.mrrNorm.addOnChangeListener(paramChanged)
    quoteHandles.gdpgNorm.addOnChangeListener(paramChanged)
    quoteHandles.cotNorm.addOnChangeListener(paramChanged)
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
wireNormGetters = (handles, areaKey) ->
    handles.inflNorm.setReferenceGetters(
        -> defaultSnapshot.areaParams[areaKey]?.infl
        -> versionControl.getStore()?.baseSnapshot?.areaParams?[areaKey]?.infl
    )
    handles.mrrNorm.setReferenceGetters(
        -> defaultSnapshot.areaParams[areaKey]?.mrr
        -> versionControl.getStore()?.baseSnapshot?.areaParams?[areaKey]?.mrr
    )
    handles.gdpgNorm.setReferenceGetters(
        -> defaultSnapshot.areaParams[areaKey]?.gdpg
        -> versionControl.getStore()?.baseSnapshot?.areaParams?[areaKey]?.gdpg
    )
    handles.cotNorm.setReferenceGetters(
        -> defaultSnapshot.areaParams[areaKey]?.cot
        -> versionControl.getStore()?.baseSnapshot?.areaParams?[areaKey]?.cot
    )
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
paramChanged = ->
    log "paramChanged"
    if scoreCombinator? then scoreCombinator.recalculate()
    versionControl.onParamsChanged()
    display.scheduleRankingUpdate()
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
    scoreCombinator.recalculate()
    return

############################################################
onQuoteLiveReset = -> resetArea(currentQuoteKey)
onBaseLiveReset = -> resetArea(currentBaseKey)

############################################################
#region Exported Functions

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

    # Wire reference getters for norm handles (before setArea which triggers refreshUI)
    wireNormGetters(baseHandles, baseKey)
    wireNormGetters(quoteHandles, quoteKey)

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
    scoreCombinator.setAreas(baseLive, quoteLive)

    # Ensure display ranking is rendered (needed for initial data load)
    display.scheduleRankingUpdate()
    return

############################################################
export resetArea = (areaKey) ->
    log "resetArea: #{areaKey}"
    live = liveAreas[areaKey]
    original = originalAreas[areaKey]
    return unless live? and original?

    # Copy original data back to live area (triggers updateListeners)
    live.updateData(original.copyData())

    # Ensure display ranking is rendered (needed for initial data load)
    display.scheduleRankingUpdate()
    return

############################################################
export snapshotParams = ->
    snapshot = { areaParams: {}, globalParams: {} }
    for key, area of liveAreas
        snapshot.areaParams[key] = area.copyParams()
    dp = scoreCombinator.getDiffParams()
    fw = scoreCombinator.getFinalWeights()
    snapshot.globalParams.diffCurves = {
        infl: { ...dp.infl }, mrr: { ...dp.mrr }
        gdpg: { ...dp.gdpg }, cot: { ...dp.cot }
    }
    snapshot.globalParams.finalWeights = {
        st: { ...fw.st }, ml: { ...fw.ml }, lt: { ...fw.lt }
    }
    return snapshot

export applyParams = (snapshot) ->
    log "applyParams"
    # Set global params first (no recalc yet)
    scoreCombinator.setDiffParams(snapshot.globalParams.diffCurves)
    scoreCombinator.setFinalWeights(snapshot.globalParams.finalWeights)

    # Set area params (triggers updateListeners → norm handle refresh + recalculate)
    for key, areaParams of snapshot.areaParams
        liveAreas[key]?.setParams(areaParams)

    # Ensure display ranking is rendered
    display.scheduleRankingUpdate()
    return

############################################################
export getLiveArea = (key) -> liveAreas[key]
export getAllLiveAreas = -> liveAreas

#endregion