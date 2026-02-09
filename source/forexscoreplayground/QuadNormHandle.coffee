############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("QuadNormHandle")
#endregion

############################################################
import { peakSteepnessToCoeffs, coeffsToPeakSteepness, defaultWidths } from "./normmath.js"

############################################################
# relevant structure files:
#     - components/quadnorm-el.pug

############################################################
export class QuadNormHandle
    constructor: (@containerEl,  @dKey) ->
        @onChangeListeners = []

        @normTypeDisplay = @containerEl.querySelector(".norm-type-title")

        @peakInput = @containerEl.querySelector(".peak-input")
        @steepnessInput = @containerEl.querySelector(".steepness-input")

        @zeroLowDisplay = @containerEl.querySelector(".zero-low")
        @zeroHighDisplay = @containerEl.querySelector(".zero-high")
        @rawValueDisplay = @containerEl.querySelector(".raw-value")
        @coeffADisplay = @containerEl.querySelector(".coeff-a")
        @coeffBDisplay = @containerEl.querySelector(".coeff-b")
        @coeffCDisplay = @containerEl.querySelector(".coeff-c")
        @resultDisplay = @containerEl.querySelector(".norm-result")

        @peakInput.addEventListener("input", => onParamInput(@))
        @steepnessInput.addEventListener("input", => onParamInput(@))
        @normTypeDisplay.textContent = @dKey

    setArea: (area) =>
        @area = area

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
        inVal = @area.data[@dKey]
        outVal = @area.normFun[@dKey]()

        # derive peak/steepness/zeros from stored a,b,c
        derived = coeffsToPeakSteepness(p.a, p.b, p.c, defaultWidths[@dKey])
        if derived?
            @peakInput.value = derived.peak.toFixed(1)
            @steepnessInput.value = derived.steepness.toFixed(2)
            @zeroLowDisplay.textContent = derived.zeroLow.toFixed(1)
            @zeroHighDisplay.textContent = derived.zeroHigh.toFixed(1)
        else
            @peakInput.value = ""
            @steepnessInput.value = ""
            @zeroLowDisplay.textContent = "--"
            @zeroHighDisplay.textContent = "--"

        @rawValueDisplay.textContent = if isNaN(inVal) then "--" else inVal.toFixed(2)
        @coeffADisplay.textContent = if p.a? then p.a.toFixed(2) else "--"
        @coeffBDisplay.textContent = if p.b? then p.b.toFixed(2) else "--"
        @coeffCDisplay.textContent = if p.c? then p.c.toFixed(2) else "--"
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
    peak = parseFloat(I.peakInput.value)
    steepness = parseFloat(I.steepnessInput.value)
    return if isNaN(peak) or isNaN(steepness) or steepness <= 0

    coeffs = peakSteepnessToCoeffs(peak, steepness, defaultWidths[I.dKey])
    p = I.area.params[I.dKey]
    p.a = coeffs.a
    p.b = coeffs.b
    p.c = coeffs.c

    # update feedback display directly (no full refresh needed)
    I.zeroLowDisplay.textContent = coeffs.zeroLow.toFixed(1)
    I.zeroHighDisplay.textContent = coeffs.zeroHigh.toFixed(1)

    # update equation coefficients and result
    I.coeffADisplay.textContent = coeffs.a.toFixed(2)
    I.coeffBDisplay.textContent = coeffs.b.toFixed(2)
    I.coeffCDisplay.textContent = coeffs.c.toFixed(2)
    outVal = I.area.normFun[I.dKey]()
    I.resultDisplay.textContent = if isNaN(outVal) then "--" else outVal.toFixed(2)

    f() for f in I.onChangeListeners
    return

#endregion
