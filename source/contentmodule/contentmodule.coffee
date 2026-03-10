############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("contentmodule")
#endregion

############################################################
export setAccountState = ->
    log "setAccountState"
    content.className = "account"
    return

export setForexscoreState = ->
    log "setForexscoreState"
    content.className = "forexscore"
    return

export setUsermanagementState = ->
    log "setUsermanagementState"
    content.className = "usermanagement"
    return

export setSpeciallinkState = ->
    log "setSpeciallinkState"
    content.className = "speciallink"
    return

export hide = ->
    log "hide"
    content.className = "hidden"
    return