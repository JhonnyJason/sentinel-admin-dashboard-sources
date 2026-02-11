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
downSynced = false

############################################################
export initialize = ->
    log "initialize"
    store = new ExperimentStore()
    
    # Wiring up UI Event Listeners
    publishButton.addEventListener("click", publishClicked)
    saveButton.addEventListener("click", saveClicked)
    createNewButton.addEventListener("click", createNewClicked)
    createCopyButton.addEventListener("click", createCopyClicked)

    playgroundNameInput.addEventListener("change", playgroundNameChanged)
    playgroundVersionSelect.addEventListener("change", playgroundVersionChanged)
    openSelect.addEventListener("change", openSelected)

    return

############################################################
#region Event Listeners
#TODO implement Listener shells

#endregion

############################################################
# Called by the dataModule when receiving the current full 
# ExperimentStore from the backend.
# May receive null if ExperimentStore of the backend is empty  
export downSyncExperimentStore = (remoteStore) ->
    store = remoteStore
    downSynced = true
    ## TODO: if store is still null, create a new one with default v0
    ## TODO: Set up UI accordingly
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
