############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoreplayground")
#endregion

############################################################
import { currencyToArea } from "./configmodule.js"
import * as areas from "./economicareasmodule.js"
import * as uiHandles from "./uihandles.js"
import * as controller from "./playgroundcontroller.js"

############################################################
export initialize = ->
    log "initialize"
    areas.initialize()
    uiHandles.initialize()
    controller.initialize()
    return

############################################################
currentPairLabel = null

############################################################
export setFocusPair = (pairLabel) ->
    log "setFocusPair: #{pairLabel}"
    return unless pairLabel?.length == 6

    baseCurrency = pairLabel.substring(0, 3)
    quoteCurrency = pairLabel.substring(3, 6)

    baseKey = currencyToArea[baseCurrency]
    quoteKey = currencyToArea[quoteCurrency]

    unless baseKey and quoteKey
        log "Unknown currency in pair: #{pairLabel}"
        return

    currentPairLabel = pairLabel
    controller.setFocusPair(baseKey, quoteKey)
    return

############################################################
export getCurrentPair = ->
    pair = controller.getCurrentPair()
    return { ...pair, label: currentPairLabel }

############################################################
export refreshCurrentPair = ->
    return unless currentPairLabel
    log "refreshCurrentPair: #{currentPairLabel}"
    setFocusPair(currentPairLabel)
    return
