############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("CotNormHandle")
#endregion

############################################################
# relevant structure files:
#     - components/cotnorm-el.pug

############################################################
export class CotNormHandle
    constructor: (@containerEl, @dKey) ->
        @onChangeListeners = []

        @headerFlag = @containerEl.querySelector(".header-flag")
        @normTypeDisplay = @containerEl.querySelector(".norm-type-title")

        @nInput = @containerEl.querySelector(".n-input")
        @eInput = @containerEl.querySelector(".e-input")

        @cot6Display = @containerEl.querySelector(".cot6-value")
        @cot36Display = @containerEl.querySelector(".cot36-value")
        @resultDisplay = @containerEl.querySelector(".norm-result")

        @nInput.addEventListener("input", => onParamInput(@))
        @eInput.addEventListener("input", => onParamInput(@))
        @normTypeDisplay.textContent = @dKey

    setArea: (area) =>
        @area = area
        @headerFlag.setAttribute("href", area.iconHref)        

        # wire up updates
        area.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    unsubscribe: =>
        return unless @area?
        @area.removeUpdateListener(@refreshUI)
        return

    refreshUI: =>
        p = @area.params[@dKey]
        outVal = @area.normFun[@dKey]()

        n = p.n ? 50
        e = p.e ? 1
        cot6 = @area.data.cot6
        cot36 = @area.data.cot36
        
        @nInput.value = n
        @eInput.value = e
        
        @cot6Display.textContent = if isNaN(cot6) then "--" else cot6
        @cot36Display.textContent = if isNaN(cot36) then "--" else cot36
        
        @resultDisplay.textContent = if isNaN(outVal) then "--" else outVal.toFixed(2)
        return

    addOnChangeListener: (fun) =>
        if typeof fun != "function" then throw new Error("OnChangeListener is not a function!")
        @onChangeListeners.push(fun)
        return

    removeOnChangeListener: (fun) =>
        @onChangeListeners[i] = null for f,i in @onChangeListeners when f == fun
        @onChangeListeners = @onChangeListeners.filter((el) -> el?)
        return

############################################################
#region Utility Functions which we donot want to expose in the class

onParamInput = (I) ->
    n = parseFloat(I.nInput.value)
    e = parseFloat(I.eInput.value)
    return if isNaN(n) or isNaN(e)

    p = I.area.params[I.dKey]
    p.n = n
    p.e = e

    # update equation display and result
    outVal = I.area.normFun[I.dKey]()
    I.resultDisplay.textContent = if isNaN(outVal) then "--" else outVal.toFixed(2)

    fn() for fn in I.onChangeListeners
    return

#endregion
