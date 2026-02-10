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

        @fInput = @containerEl.querySelector(".f-input")
        @eInput = @containerEl.querySelector(".e-input")

        @coeffFDisplay = @containerEl.querySelector(".coeff-f")
        @coeffEDisplay = @containerEl.querySelector(".coeff-e")
        @c6Display = @containerEl.querySelector(".c6-value")
        @c36Display = @containerEl.querySelector(".c36-value")
        @cot6RawDisplays = @containerEl.querySelectorAll(".cot6-raw")
        @cot36RawDisplays = @containerEl.querySelectorAll(".cot36-raw")
        @c6DerivedDisplay = @containerEl.querySelector(".c6-derived")
        @c36DerivedDisplay = @containerEl.querySelector(".c36-derived")
        @resultDisplay = @containerEl.querySelector(".norm-result")

        @fInput.addEventListener("input", => onParamInput(@))
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

        f = p.f ? 1
        e = p.e ? 1
        cot6 = @area.data.cot6
        cot36 = @area.data.cot36
        c6 = 0.02 * cot6
        c36 = 0.02 * cot36

        @fInput.value = f
        @eInput.value = e

        @coeffFDisplay.textContent = f.toFixed(2)
        @coeffEDisplay.textContent = e.toFixed(2)
        
        @c6Display.textContent = if isNaN(c6) then "--" else c6.toFixed(2)
        @c36Display.textContent = if isNaN(c36) then "--" else c36.toFixed(2)

        for el in @cot6RawDisplays
            el.textContent = if isNaN(cot6) then "--" else cot6
        for el in @cot36RawDisplays
            el.textContent = if isNaN(cot36) then "--" else cot36
        
        @c6DerivedDisplay.textContent = if isNaN(c6) then "--" else c6.toFixed(2)
        @c36DerivedDisplay.textContent = if isNaN(c36) then "--" else c36.toFixed(2)
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
    f = parseFloat(I.fInput.value)
    e = parseFloat(I.eInput.value)
    return if isNaN(f) or isNaN(e)

    p = I.area.params[I.dKey]
    p.f = f
    p.e = e

    # update equation display and result
    I.coeffFDisplay.textContent = f.toFixed(2)
    I.coeffEDisplay.textContent = e.toFixed(2)
    outVal = I.area.normFun[I.dKey]()
    I.resultDisplay.textContent = if isNaN(outVal) then "--" else outVal.toFixed(2)

    fn() for fn in I.onChangeListeners
    return

#endregion
