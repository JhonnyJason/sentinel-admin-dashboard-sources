############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("LinNormHandle")
#endregion

############################################################
import { neutralSensitivityToCoeffs, coeffsToNeutralSensitivity } from "./normmath.js"

############################################################
# relevant structure files:
#     - components/linnorm-el.pug

############################################################
export class LinNormHandle
    constructor: (@containerEl, @dKey) ->
        @onChangeListeners = []

        @headerFlag = @containerEl.querySelector(".header-flag")
        @normTypeDisplay = @containerEl.querySelector(".norm-type-title")

        @neutralInput = @containerEl.querySelector(".neutral-input")
        @sensitivityInput = @containerEl.querySelector(".sensitivity-input")

        @rawValueDisplay = @containerEl.querySelector(".raw-value")
        @coeffADisplay = @containerEl.querySelector(".coeff-a")
        @coeffBDisplay = @containerEl.querySelector(".coeff-b")
        @resultDisplay = @containerEl.querySelector(".norm-result")

        @neutralInput.addEventListener("input", => onParamInput(@))
        @sensitivityInput.addEventListener("input", => onParamInput(@))
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
        inVal = @area.data[@dKey]
        outVal = @area.normFun[@dKey]()

        # derive neutralRate/sensitivity from stored a,b
        derived = coeffsToNeutralSensitivity(p.a, p.b)
        @neutralInput.value = derived.neutralRate
        @sensitivityInput.value = derived.sensitivity

        @rawValueDisplay.textContent = if isNaN(inVal) then "--" else inVal.toFixed(2)
        @coeffADisplay.textContent = if p.a? then p.a.toFixed(2) else "--"
        @coeffBDisplay.textContent = if p.b? then p.b.toFixed(2) else "--"
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
    neutralRate = parseFloat(I.neutralInput.value)
    sensitivity = parseFloat(I.sensitivityInput.value)
    return if isNaN(neutralRate) or isNaN(sensitivity)

    coeffs = neutralSensitivityToCoeffs(neutralRate, sensitivity)
    p = I.area.params[I.dKey]
    p.a = coeffs.a
    p.b = coeffs.b

    # update equation coefficients and result
    I.coeffADisplay.textContent = coeffs.a.toFixed(2)
    I.coeffBDisplay.textContent = coeffs.b.toFixed(2)
    outVal = I.area.normFun[I.dKey]()
    I.resultDisplay.textContent = if isNaN(outVal) then "--" else outVal.toFixed(2)

    f() for f in I.onChangeListeners
    return

#endregion
