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
    return nav.toBaseAt("auth", null, 1)

export toAccount = ->
    log "toAccount"
    return nav.toBaseAt("account", null, 1)

export toForexscore = ->
    log "toForexscore"
    return nav.toBaseAt("forexscore", null, 1)

export toUsermanagement = ->
    log "toUsermanagement"
    return nav.toBaseAt("usermanagement", null, 1)

export toSpeciallink = ->
    log "toSpeciallink"
    return nav.toBaseAt("speciallink", null, 1)