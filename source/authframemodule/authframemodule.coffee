############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authframemodule")
#endregion

############################################################
# TODO: Implement admin auth UI

############################################################
export initialize = ->
    log "initialize"
    return

############################################################
export show = ->
    log "show"
    authframe.className = ""
    return

export hide = ->
    log "hide"
    authframe.className = "hidden"
    return