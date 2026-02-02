############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("navtriggers")
#endregion

############################################################
import * as nav from "navhandler"

############################################################
export toAuth = ->
    log "toAuth"
    return nav.toBase("auth")

export toForexscore = ->
    log "toForexscore"
    return nav.toBase("forexscore")

export toUsermanagement = ->
    log "toUsermanagement"
    return nav.toBase("usermanagement")