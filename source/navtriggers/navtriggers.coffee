############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("navtriggers")
#endregion

############################################################
import * as nav from "navhandler"

############################################################
export toHome = ->
    log "toHome"
    return nav.toRoot(true)

############################################################
export toAuth = ->
    log "toAuth"
    return nav.toBase("auth")

export toAccount = ->
    log "toAccount"
    return nav.toBase("account")

export toForexscore = ->
    log "toForexscore"
    return nav.toBase("forexscore")

export toUsermanagement = ->
    log "toUsermanagement"
    return nav.toBase("usermanagement")

export toSpeciallink = ->
    log "toSpeciallink"
    return nav.toBase("speciallink")