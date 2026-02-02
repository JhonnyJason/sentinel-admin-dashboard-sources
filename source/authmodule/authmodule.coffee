############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authmodule")
#endregion

############################################################
# TODO: Implement admin authentication
# This will be different from user auth

############################################################
export initialize = ->
    log "initialize"
    return

############################################################
export isAuthenticated = ->
    # TODO: Implement proper auth check
    # For now, return false to show auth screen
    return false

############################################################
export getAuthCode = ->
    # TODO: Implement when auth is ready
    return null