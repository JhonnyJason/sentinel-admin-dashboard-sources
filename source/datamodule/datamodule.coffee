############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("datamodule")
#endregion

############################################################
import * as cfg from "./configmodule.js"
import * as auth from "./authmodule.js"
import * as versioning from "./forexscoreversion.js"
import * as areas from "./economicareasmodule.js"

############################################################
dataReceived = false
socketAuthorized = false

############################################################
socket = null
noNetwork = false
pendingRequests = {}  # responseType → { resolve, reject, timer }

############################################################
COMMAND_TIMEOUT_MS = 10000

############################################################
export initialize = (cfg) ->
    log "initialize"
    noNetwork = (cfg.noNetwork == true)
    if noNetwork then return

    createSocket() 
    return

createSocket = ->
    log "createSocket"
    try
        socket = new WebSocket(cfg.urlWebsocketBackend)

        socket.addEventListener("open", socketOpened)
        socket.addEventListener("message", receiveData)
        socket.addEventListener("error", receiveError)
        socket.addEventListener("close", socketClosed)

    catch err then log err
    return

############################################################
export heartbeat = ->
    log "heartbeat"
    if noNetwork and !dataReceived then loadMockData()
    if noNetwork then return

    if !socket? then return createSocket()

    if socket.readyState == WebSocket.OPEN
        ## only used for testing
        # if !dataReceived then loadMockData() ## act as if we received data

        ## Real action when backend supports our updates
        # Request data if authorized but haven't received yet
        if socketAuthorized and !dataReceived
            socket.send("getAllMakroData")
        return

    if socket.readyState == WebSocket.CLOSED
        destroySocket()
        return
    return

############################################################
socketOpened = (evnt) ->
    log "socketOpened"
    authMessage = await auth.getAuthorizationMessage()
    socket.send("authorizeAdmin #{authMessage}")
    return

receiveData = (evnt) ->
    log "receiveData"
    try
        data = JSON.parse(evnt.data)
        olog data

        # Check pending promise-based requests first
        if data.type? and pendingRequests[data.type]?
            pending = pendingRequests[data.type]
            delete pendingRequests[data.type]
            clearTimeout(pending.timer)
            pending.resolve(data)
            return

        # Authorization approved → request all data
        if data.type == "authorizationApproved"
            log "Authorization approved"
            socketAuthorized = true
            socket.send("getAllMakroData")
            return

        # All makro data received → propagate to areas
        if data.type == "allMakroData" and !dataReceived
            log "Received allMakroData"
            processAllMakroData(data.payload)
            return

        # Ignore other messages for now
        log "Ignoring message type: #{data.type}"

    catch err then console.error(err)
    return

processAllMakroData = (payload) ->
    log "processAllMakroData"
    areas.updateAllAreas(payload)
    dataReceived = true
    requestAllHistory()
    return

requestAllHistory = ->
    log "requestAllHistory"
    try
        data = await sendCommand("getSnapshotData", null, "snapshotData")
        log "Received snapshotData"
        versioning.downSyncExperimentStore(data)
    catch err
        log "getAllHistory failed, bootstrapping with defaults"
        console.error(err)
        versioning.downSyncExperimentStore(null)
    return

receiveError = (evnt) ->
    log "receiveError"
    olog evnt
    return

socketClosed = (evnt) ->
    log "socketClosed"
    log evnt.reason
    destroySocket()
    return

destroySocket = ->
    return unless socket?
    socket.removeEventListener("open", socketOpened)
    socket.removeEventListener("message", receiveData)
    socket.removeEventListener("error", receiveError)
    socket.removeEventListener("close", socketClosed)
    socket = null
    return

############################################################
sendCommand = (command, payload, expectedResponseType) ->
    new Promise (resolve, reject) ->
        unless socket? and socket.readyState == WebSocket.OPEN
            reject(new Error("Socket not connected"))
            return

        if payload?
            socket.send("#{command} #{JSON.stringify(payload)}")
        else
            socket.send(command)
        
        requestTimedOut = ->
            if pendingRequests[expectedResponseType]?
                delete pendingRequests[expectedResponseType]
                reject(new Error("Timeout waiting for #{expectedResponseType}"))
            return

        timer = setTimeout(requestTimedOut, COMMAND_TIMEOUT_MS) 

        # overwriting previous requests is fine if we clear the previous timeout
        if pendingRequests[expectedResponseType]? 
            clearTimeout(pendingRequests[expectedResponseType].timer)
        pendingRequests[expectedResponseType] = { resolve, reject, timer }
        return

############################################################
export startHeartbeat = -> setInterval(heartbeat, cfg.heartbeatMS)

############################################################
#region Admin Actionsq
export createEntry = (name, snapshot) ->
    log "createEntry: #{name}"
    if noNetwork then return { ok: true }
    sendCommand("createEntry", {name, snapshot}, "createEntryResult")

export saveEntry = (name, version, snapshot) ->
    log "saveEntry: #{name}"
    if noNetwork then return { ok: true }
    sendCommand("saveEntry", {name, version, snapshot}, "saveEntryResult")

export publishEntry = (name, version) ->
    log "publishEntry: #{name} v#{version}"
    if noNetwork then return { ok: true }
    sendCommand("publishEntry", {name, version}, "publishEntryResult")

export renameEntry = (oldName, newName) ->
    log "renameEntry: #{oldName} → #{newName}"
    if noNetwork then return { ok: true }
    sendCommand("renameEntry", {oldName, newName}, "renameEntryResult")

#endregion

############################################################
#region Mock Data (for development without backend)

# Load mock data into economic areas (simulates backend connection)
export loadMockData = ->
    log "loadMockData"
    areas.updateAllAreas(cfg.mockAreaData)
    versioning.downSyncExperimentStore(null)
    dataReceived = true
    return

#endregion
