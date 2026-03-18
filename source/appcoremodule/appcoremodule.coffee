############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("appcoremodule")
#endregion

############################################################
import * as nav from "navhandler"
import * as triggers from "./navtriggers.js"
import * as uiState from "./uistatemodule.js"
import * as auth from "./authmodule.js"

############################################################
import { appVersion } from "./configmodule.js"

############################################################
defaultBaseState = "forexscore"

############################################################
appBaseState = "forexscore"
appUIMod = "none"
appContext = {}

############################################################
#region DOM Cache fix
currentVersion = document.getElementById("current-version")

#endregion

############################################################
export initialize = ->
    log "initialize"
    nav.initialize(setNavState, setNavState)
    currentVersion.textContent = appVersion
    return


############################################################
handleOTCInURL =  ->
    log "handleOTCInURL"
    urlParams = new URLSearchParams(window.location.search)
    otc = urlParams.get("otc")
    if otc
        log "OTC found in URL"
        auth.setOTC(otc)
        # Clear OTC from URL to prevent re-use on refresh
        history.replaceState(null, "", window.location.pathname)
        return true
    
    return false

############################################################
setNavState = (navState) ->
    log "setNavState"
    baseState = navState.base
    modifier = navState.modifier
    context = navState.context

    hasOTC = handleOTCInURL()
    if hasOTC and baseState != "auth" 
        log 'OTC available but we are not in "auth" state -> toAuth()'
        return triggers.toAuth()
    
    authState = auth.getAuthenticationState()
    if authState == "keyUnlocked" and baseState == "auth"
        log "already authenticated, redirecting to default"
        return triggers.toForexscore()

    if authState != "keyUnlocked" and baseState != "auth"
        log 'Not authenticated and not in "auth" state -> toAuth()'
        return triggers.toAuth()
    
    if baseState == "RootState" then baseState = defaultBaseState

    setAppState(baseState, modifier, context)
    return

setAppState = (base, mod, ctx) ->
    log "setAppState"
    if base then appBaseState = base
    if mod then appUIMod = mod
    log "#{appBaseState}:#{appUIMod}"

    uiState.applyUIState(appBaseState, appUIMod)
    return
