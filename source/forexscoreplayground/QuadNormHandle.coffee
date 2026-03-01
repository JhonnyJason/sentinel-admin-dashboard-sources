############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("QuadNormHandle")
#endregion

############################################################
import { peakSteepnessToCoeffs, coeffsToPeakSteepness } from "./normmath.js"

############################################################
# relevant structure files:
#     - components/quadnorm-el.pug

############################################################
export class QuadNormHandle
    constructor: (@containerEl,  @dKey) ->
        @onChangeListeners = []
        @getDefaultParams = null
        @getSavedParams = null

        @headerFlag = @containerEl.querySelector(".header-flag")
        @normTypeDisplay = @containerEl.querySelector(".norm-type-title")

        @peakInput = @containerEl.querySelector(".peak-input")
        @steepnessInput = @containerEl.querySelector(".steepness-input")

        @zeroLowDisplay = @containerEl.querySelector(".zero-low")
        @zeroHighDisplay = @containerEl.querySelector(".zero-high")
        @rawValueDisplay = @containerEl.querySelector(".raw-value")
        @resultDisplay = @containerEl.querySelector(".norm-result")

        @defaultButton = @containerEl.querySelector(".default-button")
        @resetButton = @containerEl.querySelector(".reset-button")

        @peakInput.addEventListener("input", => onParamInput(@))
        @steepnessInput.addEventListener("input", => onParamInput(@))

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
        inVal = @area.data[@dKey]
        outVal = @area.normFun[@dKey]()

        # derive peak/steepness/zeros from stored a,b,c
        derived = coeffsToPeakSteepness(p.a, p.b, p.c)
        if derived?
            @peakInput.value = Math.round(derived.peak*10)/10
            @steepnessInput.value = Math.round(derived.steepness*100)/100
            @zeroLowDisplay.textContent = derived.zeroLow.toFixed(1)
            @zeroHighDisplay.textContent = derived.zeroHigh.toFixed(1)
        else
            @peakInput.value = ""
            @steepnessInput.value = ""
            @zeroLowDisplay.textContent = "--"
            @zeroHighDisplay.textContent = "--"

        @rawValueDisplay.textContent = if isNaN(inVal) then "--" else inVal.toFixed(2)
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
    peak = parseFloat(I.peakInput.value)
    steepness = parseFloat(I.steepnessInput.value)
    return if isNaN(peak) or isNaN(steepness) or steepness <= 0

    coeffs = peakSteepnessToCoeffs(peak, steepness)
    p = I.area.params[I.dKey]
    p.a = coeffs.a
    p.b = coeffs.b
    p.c = coeffs.c

    # update feedback display directly (no full refresh needed)
    I.zeroLowDisplay.textContent = coeffs.zeroLow.toFixed(1)
    I.zeroHighDisplay.textContent = coeffs.zeroHigh.toFixed(1)

    # update equation coefficients and result
    outVal = I.area.normFun[I.dKey]()
    I.resultDisplay.textContent = if isNaN(outVal) then "--" else outVal.toFixed(2)

    # update RefButtons visibility
    toggleRefButtons(I)

    f() for f in I.onChangeListeners
    return

############################################################
paramsEqual = (a, b) -> JSON.stringify(a) == JSON.stringify(b)

toggleRefButtons = (I) ->
    log "toggleRefButtons"
    p = I.area?.params[I.dKey]
    return unless p?
    log "I.area.params[#{I.dKey}] exist"
    defP = I.getDefaultParams?()
    savedP = I.getSavedParams?()
    olog { defP, savedP }
    I.defaultButton.classList.toggle("visible", defP? and !paramsEqual(p, defP))
    I.resetButton.classList.toggle("visible", savedP? and !paramsEqual(p, savedP))
    return

applyRef = (I, getter) ->
    ref = getter?()
    return unless ref?
    p = I.area.params[I.dKey]
    p[k] = v for k, v of ref
    f() for f in I.onChangeListeners
    I.refreshUI()
    return

#endregion
