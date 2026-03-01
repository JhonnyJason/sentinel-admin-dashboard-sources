############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoreframemodule")
#endregion

############################################################
import * as focusPairSelection from "./focuspairselection.js"
import * as playground from "./forexscoreplayground.js"
import * as versioning from "./forexscoreversion.js"

############################################################
export initialize = (cfg) ->
    log "initialize"
    playground.initialize(cfg)
    focusPairSelection.initialize(cfg)
    versioning.initialize(cfg)
    return
