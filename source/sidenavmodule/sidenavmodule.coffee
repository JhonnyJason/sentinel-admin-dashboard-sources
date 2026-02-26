############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("sidenavmodule")
#endregion

############################################################
import * as triggers from "./navtriggers.js"

############################################################
export initialize = ->
    log "initialize"
    forexscoreBtn.addEventListener("click", triggers.toForexscore)
    usermanagementBtn.addEventListener("click", triggers.toUsermanagement)
    speciallinkBtn.addEventListener("click", triggers.toSpeciallink)
    return

############################################################
export setForexscoreState = ->
    log "setForexscoreState"
    sidenav.className = "forexscore"
    return

export setUsermanagementState = ->
    log "setUsermanagementState"
    sidenav.className = "usermanagement"
    return

export setSpeciallinkState = ->
    log "setSpeciallinkState"
    sidenav.className = "speciallink"
    return

export hide = ->
    log "hide"
    sidenav.className = "hidden"
    return
