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
setNavState = (navState) ->
    log "setNavState"
    baseState = navState.base
    modifier = navState.modifier
    context = navState.context

    if !auth.isAuthenticated() and baseState != "auth"
        log "not authenticated!"
        return triggers.toAuth()

    if auth.isAuthenticated() and baseState == "auth"
        log "already authenticated, redirecting to default"
        return triggers.toForexscore()

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
