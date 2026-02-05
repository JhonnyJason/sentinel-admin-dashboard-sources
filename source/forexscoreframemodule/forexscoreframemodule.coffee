############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoreframemodule")
#endregion

############################################################
import * as focusPairSelection from "./focuspairselection.js"
import * as playground from "./forexscoreplayground.js"

############################################################
export initialize = ->
    log "initialize"
    playground.initialize()
    focusPairSelection.initialize()
    return
