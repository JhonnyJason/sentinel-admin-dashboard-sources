############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoremodule")
#endregion

############################################################
import { shownCurrencyPairLabels } from "./configmodule.js"
import { Combobox } from "./comboboxfun.js"
import * as focusPairModule from "./focuspairmodule.js"

############################################################
pairCombobox = null

############################################################
export initialize = ->
    log "initialize"

    pairCombobox = new Combobox
        inputEl: pairInput # pairInput. <- needed to fix implicit-dom-connect
        dropdownEl: pairDropdown # pairDropdown. <- needed to fix implicit-dom-connect

    pairCombobox.setOptions(shownCurrencyPairLabels)
    pairCombobox.onSelect(onPairSelected)

    focusPairModule.initialize()

    # Set default focus pair
    pairInput.value = "EURUSD"
    onPairSelected("EURUSD")
    return

############################################################
onPairSelected = (pair) ->
    log "onPairSelected: #{pair}"
    selectedPair.textContent = pair
    focusPairModule.setFocusPair(pair)
    return
