############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoreversion")
#endregion

############################################################
import { ExperimentStore } from "./ExperimentStore.js"
import { snapshot as defaultSnapshot } from "./defaultsnapshot.js"
import * as controller from "./playgroundcontroller.js"
import * as data from "./datamodule.js"

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

    resetButton.addEventListener("click", resetClicked)

    playgroundNameInput.addEventListener("change", playgroundNameChanged)
    playgroundVersionSelect.addEventListener("change", playgroundVersionChanged)
    openSelect.addEventListener("change", openSelected)

    return

############################################################
#region Event Listeners

publishClicked = ->
    log "publishClicked"
    return unless store?.hasExperiment()
    { name, version } = store.getCurrent()
    store.publish()
    refreshUI()
    try await data.publishEntry(name, version)
    catch err then console.error("publishEntry failed:", err)
    return

saveClicked = ->
    log "saveClicked"
    return unless store?.hasExperiment()
    snapshot = controller.snapshotParams()
    { name, version } = store.getCurrent()
    store.save(snapshot)
    refreshUI()
    try await data.saveEntry(name, version, snapshot)
    catch err then console.error("saveEntry failed:", err)
    return

resetClicked = ->
    log "resetClicked"
    return unless store?.hasExperiment()
    { version } = store.getCurrent()
    store.selectVersion(version)
    controller.applyParams(store.getCurrentSnapshot())
    refreshUI()
    return

createNewClicked = ->
    log "createNewClicked"
    name = store.createNew(defaultSnapshot)
    snapshot = store.getCurrentSnapshot()
    controller.applyParams(snapshot)
    refreshUI()
    try await data.createEntry(name, snapshot)
    catch err then console.error("createEntry failed:", err)
    return

createCopyClicked = ->
    log "createCopyClicked"
    return unless store?.hasExperiment()
    snapshot = controller.snapshotParams()
    name = store.createNew(snapshot)
    refreshUI()
    try await data.createEntry(name, snapshot)
    catch err then console.error("createEntry failed:", err)
    return

playgroundNameChanged = ->
    log "playgroundNameChanged"
    return unless store?.hasExperiment()
    newName = playgroundNameInput.value.trim().replaceAll(" ","")
    playgroundNameInput.value = newName
    return unless newName
    oldName = store.getCurrent().name
    return if oldName == newName
    store.rename(newName)
    refreshUI()
    try await data.renameEntry(oldName, newName)
    catch err then console.error("renameEntry failed:", err)
    return

playgroundVersionChanged = ->
    log "playgroundVersionChanged"
    return unless store?.hasExperiment()
    index = parseInt(playgroundVersionSelect.value, 10)
    return if isNaN(index)
    store.selectVersion(index)
    controller.applyParams(store.getCurrentSnapshot())
    refreshUI()
    return

openSelected = ->
    log "openSelected"
    name = openSelect.value
    return unless name
    store.open(name)
    controller.applyParams(store.getCurrentSnapshot())
    refreshUI()
    return

#endregion

############################################################
# Central UI update — reads store state, updates all UI elements.
# Called after every action (create, save, publish, open, selectVersion, rename, onParamsChanged).
refreshUI = ->
    unless store?.hasExperiment()
        playgroundNameInput.value = ""
        playgroundNameInput.disabled = true
        playgroundVersionSelect.innerHTML = ""
        playgroundVersionSelect.disabled = true
        saveButton.disabled = true
        publishButton.hidden = true
        publishButton.classList.remove("is-published")
        resetButton.hidden = true
        return

    current = store.getCurrent()
    modified = store.isModified()

    # Name input
    playgroundNameInput.value = current.name
    playgroundNameInput.disabled = false

    # Version select — show "vX*" for current version when modified
    versionCount = store.getVersionCount()
    playgroundVersionSelect.innerHTML = ""
    for i in [0...versionCount]
        opt = document.createElement("option")
        opt.value = i
        label = "v#{i + 1}"
        if i == current.version and modified then label += "*"
        opt.textContent = label
        opt.selected = (i == current.version)
        playgroundVersionSelect.appendChild(opt)
    playgroundVersionSelect.disabled = (versionCount <= 1 and !modified)

    # Open select — all experiment names
    names = store.getExperimentNames()
    openSelect.innerHTML = ""
    placeholder = document.createElement("option")
    placeholder.value = ""
    placeholder.disabled = true
    placeholder.selected = true
    placeholder.textContent = "Spielwiese öffnen"
    openSelect.appendChild(placeholder)
    for name in names
        opt = document.createElement("option")
        opt.value = name
        opt.textContent = name
        openSelect.appendChild(opt)

    # Save button — enabled only when modified
    saveButton.disabled = !modified

    # Reset / Publish toggle — mutually exclusive
    resetButton.hidden = !modified
    publishButton.hidden = modified
    atPublished = store.isAtPublished()
    publishButton.disabled = false
    publishButton.classList.toggle("is-published", atPublished)

    return

############################################################
# Called by the dataModule after getAllHistory response.
# remoteData: { entries, published } or null (no history / mock mode)
export downSyncExperimentStore = (remoteData) ->
    log "downSyncExperimentStore"
    if remoteData?.entries? and Object.keys(remoteData.entries).length > 0
        log "We have data - let's hydrate our data store!"
        store.hydrate(remoteData.entries, remoteData.published)
    else
        log "We donot have data... this should not be true"
        olog remoteData 
        return
        store = new ExperimentStore()
        name = store.createNew(defaultSnapshot)
        try await data.createEntry(name, defaultSnapshot)
        catch err then console.error("@downsyncExperimentStore: data.createEntry failed:", err)

    if store.hasExperiment()
        controller.applyParams(store.getCurrentSnapshot())
    downSynced = true
    refreshUI()
    return

############################################################
# Called by playgroundcontroller when any parameter changes
export onParamsChanged = ->
    return unless store?.hasExperiment()
    snapshot = controller.snapshotParams()
    store.updateLiveSnapshot(snapshot)
    refreshUI()
    return

############################################################
export getStore = -> store
