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
        @getDefaultParams = null
        @getSavedParams = null

        @headerFlag = @containerEl.querySelector(".header-flag")
        @normTypeDisplay = @containerEl.querySelector(".norm-type-title")

        @nInput = @containerEl.querySelector(".n-input")
        @eInput = @containerEl.querySelector(".e-input")

        @cot6Display = @containerEl.querySelector(".cot6-value")
        @cot36Display = @containerEl.querySelector(".cot36-value")
        @resultDisplay = @containerEl.querySelector(".norm-result")

        @defaultButton = @containerEl.querySelector(".default-button")
        @resetButton = @containerEl.querySelector(".reset-button")

        @nInput.addEventListener("input", => onParamInput(@))
        @eInput.addEventListener("input", => onParamInput(@))
        @defaultButton.addEventListener("click", => applyRef(@, @getDefaultParams))
        @resetButton.addEventListener("click", => applyRef(@, @getSavedParams))
        @normTypeDisplay.textContent = @dKey

    setArea: (area) =>
        @area = area
        @headerFlag.setAttribute("href", area.iconHref)        

        # wire up updates
        area.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    setReferenceGetters: (getDefault, getSaved) =>
        @getDefaultParams = getDefault
        @getSavedParams = getSaved
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

        # Toggle default/reset button visibility
        toggleRefButtons(@)
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

    # update RefButtons visibility
    toggleRefButtons(I)

    fn() for fn in I.onChangeListeners
    return

############################################################
paramsEqual = (a, b) -> JSON.stringify(a) == JSON.stringify(b)

toggleRefButtons = (I) ->
    p = I.area?.params[I.dKey]
    return unless p?
    defP = I.getDefaultParams?()
    savedP = I.getSavedParams?()
    I.defaultButton.classList.toggle("visible", defP? and !paramsEqual(p, defP))
    I.resetButton.classList.toggle("visible", savedP? and !paramsEqual(p, savedP))
    return

applyRef = (I, getter) ->
    ref = getter?()
    return unless ref?
    p = I.area.params[I.dKey]
    p[k] = v for k, v of ref
    fn() for fn in I.onChangeListeners
    I.refreshUI()
    return

#endregion
