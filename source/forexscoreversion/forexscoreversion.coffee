############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoreversion")
#endregion

############################################################
import { ExperimentStore } from "./ExperimentStore.js"
import * as controller from "./playgroundcontroller.js"

############################################################
store = null

############################################################
export initialize = ->
    log "initialize"
    store = new ExperimentStore()
    return

############################################################
# Called by playgroundcontroller when any parameter changes
export onParamsChanged = ->
    return unless store?.hasExperiment()
    snapshot = controller.snapshotParams()
    store.updateLiveSnapshot(snapshot)
    # TODO 6.3: update UI (save button state based on store.isModified())
    log "onParamsChanged - isModified: #{store.isModified()}"
    return

############################################################
export getStore = -> store
