############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("focuspairselection")
#endregion

############################################################
import { shownCurrencyPairLabels } from "./configmodule.js"
import { Combobox } from "./comboboxfun.js"
import * as playground from "./forexscoreplayground.js"

############################################################
pairCombobox = null

############################################################
export initialize = ->
    log "initialize"

    pairCombobox = new Combobox
        inputEl: pairInput
        dropdownEl: pairDropdown # pairDropdown. <- this comment is required!

    pairCombobox.setOptions(shownCurrencyPairLabels)
    pairCombobox.onSelect(onPairSelected)

    # Set default focus pair
    pairInput.value = "EURUSD"
    onPairSelected("EURUSD")
    return

############################################################
onPairSelected = (pair) ->
    log "onPairSelected: #{pair}"
    selectedPair.textContent = pair
    playground.setFocusPair(pair)
    return
