############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("stripeconnectmodule")
#endregion

############################################################
import * as cfg from "./configmodule.js"
import * as auth from "./authmodule.js"
import * as paypros from "./paymentprovidersmodule.js"

############################################################
currentState = null
socketAuthorized = false

############################################################
socket = null
pendingRequests = {}  # responseType → { resolve, reject, timer }

############################################################
COMMAND_TIMEOUT_MS = 40_000 # 40s

############################################################
export initialize = ->
    log "initialize"
    createSocket() 
    return

############################################################
createSocket = ->
    log "createSocket"
    try
        socket = new WebSocket(cfg.urlDotVStripe)

        socket.addEventListener("open", socketOpened)
        socket.addEventListener("message", receiveData)
        socket.addEventListener("error", receiveError)
        socket.addEventListener("close", socketClosed)

    catch err then log err
    return

############################################################
export heartbeat = ->
    log "heartbeat"
    if !socket? then return createSocket()

    if socket.readyState == WebSocket.OPEN
        # Request data if authorized but haven't received yet
        if socketAuthorized and !currentState? then requestState()
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
            log "found pending request with type: "+data.type
            pending = pendingRequests[data.type]
            delete pendingRequests[data.type]
            clearTimeout(pending.timer)
            pending.resolve(data.data)
            return

        # Authorization approved → request all data
        if data.type == "authorizationApproved"
            log "Authorization approved"
            socketAuthorized = true
            if !currentState? then requestState()
            return

        # Ignore other messages for now
        log "Ignoring message type: #{data.type}"

    catch err then console.error(err)
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

requestState = ->
    log "requestState"
    if currentState? then return
    try
        currentState = "requesting..."
        currentState = await sendCommand("getStripeState", null, "requestedStripeState")
    catch err
        console.error "@requestState failed: "+err.message
        console.error "Bootstrapping with Mock State and Defaults..."
        currentState = cfg.mockedStripeState
    finally paypros.setState(currentState)
    return

############################################################
export startHeartbeat = -> setInterval(heartbeat, cfg.heartbeatMS)

############################################################
#region Admin Actions
export getOnboardingLink = () ->
    log "getOnboardingLink"
    return await sendCommand("getOnboardingLink", null, "onboardingLinkRetrieval")

export createAccount = (email) ->
    log "createAccount"
    resp = await sendCommand("createStripeAccount", { email }, "accountCreation")
    olog resp
    if resp.success
        currentState = null 
        return requestState()
    else console.error(resp.error)
    return

#endregion
