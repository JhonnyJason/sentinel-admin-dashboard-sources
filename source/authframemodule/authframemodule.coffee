############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authframemodule")
#endregion

############################################################
import * as auth from "./authmodule.js"

############################################################
currentState = null

############################################################
export initialize = ->
    log "initialize"
    return

############################################################
export setState = ->
    log "setState"
    state = auth.getAuthenticationState()
    log "auth state: #{state}"
    applyInternalState(state)
    return

############################################################
applyInternalState = (state) ->
    return if state == currentState
    currentState = state
    log "applying internal state: #{state}"
    switch state
        when "keySetup" then setRequestPin()
        when "keyLocked" then setRequestQrCode()
        when "inaccessible" then setInaccessible()
        when "keyUnlocked"
            # Authenticated - this should trigger nav away from auth
            log "key unlocked - should navigate to app"
    return

############################################################
setInaccessible = ->
    authframe.className = "inaccessible"
    return

############################################################
setRequestPin = ->
    authframe.className = "request-pin"
    pinInput.addEventListener("keypress", onPinInputKeypress)
    acceptPinButton.addEventListener("click", onAcceptPin)
    pinInput.focus()
    return

############################################################
onPinInputKeypress = (e) ->
    if e.key == "Enter" then onAcceptPin()
    return

############################################################
onAcceptPin = ->
    pin = pinInput.value
    return unless pin and pin.length == 4
    pinInput.removeEventListener("keypress", onPinInputKeypress)
    acceptPinButton.removeEventListener("click", onAcceptPin)
    authframe.classList.remove("request-pin")
    
    try await auth.createNewCredentials(pin)
    catch err then setInaccessible()
    return

############################################################
setRequestQrCode = ->
    try await auth.unlockKey()
    catch err then setInaccessible()
    return

############################################################
export hide = ->
    log "hide"
    authframe.className = ""
    return