############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoreframemodule")
#endregion

############################################################
import * as versioning from "./forexscoreversion.js"
import * as focusPairSelection from "./focuspairselection.js"
import * as playground from "./forexscoreplayground.js"

############################################################
export initialize = (cfg) ->
    log "initialize"
    versioning.initialize(cfg)
    focusPairSelection.initialize(cfg)
    playground.initialize(cfg)
    return
