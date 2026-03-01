############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("MrrNormHandle")
#endregion

############################################################
import * as nm from "./normmath.js"

############################################################
# relevant structure files:
#     - components/mrrnorm-el.pug

############################################################
export class MrrNormHandle
    constructor: (@containerEl, @dKey) ->
        @onChangeListeners = []
        @getDefaultParams = null
        @getSavedParams = null

        @headerFlag = @containerEl.querySelector(".header-flag")
        @normTypeDisplay = @containerEl.querySelector(".norm-type-title")

        @floorInput = @containerEl.querySelector(".floor-input")
        @neutralInput = @containerEl.querySelector(".neutral-input")
        @ceilingInput = @containerEl.querySelector(".ceiling-input")
        @inflPunishmentInput = @containerEl.querySelector(".infl-punishment-input")

        @rawValueDisplay = @containerEl.querySelector(".raw-value")
        @resultDisplay = @containerEl.querySelector(".norm-result")

        @defaultButton = @containerEl.querySelector(".default-button")
        @resetButton = @containerEl.querySelector(".reset-button")

        @floorInput.addEventListener("input", => onParamInput(@))
        @neutralInput.addEventListener("input", => onParamInput(@))
        @ceilingInput.addEventListener("input", => onParamInput(@))
        @inflPunishmentInput.addEventListener("input", => onParamInput(@))
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

        # derive neutralRate/sensitivity from stored a,b
        @floorInput.value = p.f
        @neutralInput.value = p.n
        @ceilingInput.value = p.c
        @inflPunishmentInput.value = nm.sToPunishment(p.s)

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
    f = parseFloat(I.floorInput.value)
    n = parseFloat(I.neutralInput.value)
    c = parseFloat(I.ceilingInput.value)
    pun = parseFloat(I.inflPunishmentInput.value)
    return if isNaN(f) or isNaN(n) or isNaN(c) or isNaN(pun)

    p = I.area.params[I.dKey]
    p.f = f
    p.n = n
    p.c = c
    p.s = nm.punishmentToS(pun)

    # update equation coefficients and result
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
