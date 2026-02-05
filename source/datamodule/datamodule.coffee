############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("datamodule")
#endregion

############################################################
import * as cfg from "./configmodule.js"
import * as auth from "./authmodule.js"
import * as areas from "./economicareasmodule.js"

############################################################
# Data state

############################################################
dataReceived = false
socketAuthorized = false

############################################################
socket = null
noNetwork = false

############################################################
export initialize = (cfg) ->
    log "initialize"
    noNetwork = cfg.noNetwork == true
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
        if !dataReceived then loadMockData() ## act as if we received data

        ## Real action when backend supports our updates
        # Request data if authorized but haven't received yet
        # if socketAuthorized and !dataReceived
        #     socket.send("getAllData")
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

        # Authorization approved → request all data
        if data.type == "authorizationApproved"
            log "Authorization approved"
            socketAuthorized = true
            socket.send("getAllData")
            return

        # All data received → propagate to areas
        if data.type == "allData" and !dataReceived
            log "Received allData"
            processAllData(data.payload)
            return

        # Ignore other messages for now
        log "Ignoring message type: #{data.type}"

    catch err then console.error(err)
    return

processAllData = (payload) ->
    log "processAllData"
    areas.updateAllAreas(payload)
    dataReceived = true
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
export startHeartbeat = -> setInterval(heartbeat, cfg.heartbeatMS)

############################################################
#region Admin Actions (stubs - to be wired to backend)

# Save experimental params (unpublished, stored in history)
export saveParams = (areaParams, globalParams, note = "") ->
    log "saveParams (stub)"
    olog { areaParams, globalParams, note }
    # TODO: send via WebSocket
    # { action: "saveParams", areaParams, globalParams, note }
    return { ok: true, historyId: "exp-#{Date.now()}" }

# Publish params (checkpoint, becomes active for all users)
export publishParams = (areaParams, globalParams, note = "") ->
    log "publishParams (stub)"
    olog { areaParams, globalParams, note }
    # TODO: send via WebSocket
    # { action: "publishParams", areaParams, globalParams, note }
    return { ok: true, historyId: "pub-#{Date.now()}", version: new Date().toISOString() }

# Reset to last published checkpoint
export resetToPublished = ->
    log "resetToPublished (stub)"
    ## TODO implement
    ## Notice: we donot need backend connection for this one directly 
    ##    we should have the history, or need to load it if not 
    ##    from the history we know last published data and may reset it.
    ##    Important here is the flow to "apply" this state 
    return 

# Get parameter history
export getHistory = (limit = 20) ->
    log "getHistory (stub)"
    # TODO: send via WebSocket
    # { action: "getHistory", limit }
    return { history: [] }

# Load specific history entry
export loadFromHistory = (historyId) ->
    log "loadFromHistory (stub): #{historyId}"
    # TODO: send via WebSocket
    # { action: "loadFromHistory", historyId }
    return { ok: true }

#endregion

############################################################
#region Mock Data (for development without backend)

# Load mock data into economic areas (simulates backend connection)
export loadMockData = ->
    log "loadMockData"
    areas.updateAllAreas(cfg.mockAreaData)
    dataReceived = true
    return

#endregion
