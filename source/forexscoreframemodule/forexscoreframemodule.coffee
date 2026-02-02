############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoremodule")
#endregion

############################################################
import { shownCurrencyPairLabels } from "./configmodule.js"
import { Combobox } from "./comboboxfun.js"

############################################################
pairCombobox = null
focusPair = null

############################################################
# pairInput = document.getElementById("pair-input")

############################################################
export initialize = ->
    log "initialize"

    pairCombobox = new Combobox
        inputEl: pairInput # pairInput. < fixes dom-connect bug
        dropdownEl: pairDropdown # pairDropdown. < fixes dom-connect bug

    pairCombobox.setOptions(shownCurrencyPairLabels)
    pairCombobox.onSelect(onPairSelected)
    return

############################################################
onPairSelected = (pair) ->
    log "onPairSelected: #{pair}"
    focusPair = pair
    selectedPair.textContent = pair
    return
