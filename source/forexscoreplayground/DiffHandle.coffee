############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("DiffHandle")
#endregion

############################################################
import * as nm from "./normmath.js"

############################################################
# relevant structure files:
#     - components/cubdiff-el.pug

############################################################
export class DiffHandle
    constructor: (@containerEl, @dKey) ->
        @onChangeListeners = []
        @getDefaultParams = null
        @getSavedParams = null

        @typeDisplay = @containerEl.querySelector(".diff-type-title")
        @amplificationInput = @containerEl.querySelector(".amplification-input")
        @baseValDisplay = @containerEl.querySelector(".diff-base-val")
        @quoteValDisplay = @containerEl.querySelector(".diff-quote-val")
        @resultDisplay = @containerEl.querySelector(".diff-result")

        @defaultButton = @containerEl.querySelector(".default-button")
        @resetButton = @containerEl.querySelector(".reset-button")

        @amplificationInput.addEventListener("input", => onInput(@))
        @defaultButton.addEventListener("click", => applyRef(@, @getDefaultParams))
        @resetButton.addEventListener("click", => applyRef(@, @getSavedParams))
        @typeDisplay.textContent = @dKey

    setReferenceGetters: (getDefault, getSaved) =>
        @getDefaultParams = getDefault
        @getSavedParams = getSaved
        return

    setModel: (model) =>
        @model = model
        model.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    refreshUI: =>
        p = @model.getDiffParams()[@dKey]
        { baseScore, quoteScore } = @model.getDiffInputs(@dKey)
        r = @model.getDiffResults()[@dKey]

        ampl = nm.coeffsToAmplification(p.b, p.d)

        @amplificationInput.value = ampl

        @baseValDisplay.textContent = if isNaN(baseScore) then "--" else baseScore.toFixed(2)
        @quoteValDisplay.textContent = if isNaN(quoteScore) then "--" else quoteScore.toFixed(2)
        @resultDisplay.textContent = if isNaN(r.score) then "--" else r.score.toFixed(2)

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
# Here I is the specific instance

onInput = (I) ->
    ampl = parseFloat(I.amplificationInput.value)
    return if isNaN(ampl)

    { b, d } =  nm.amplificationToCoeffs(ampl)

    p = I.model.diffParams[I.dKey]
    p.b = b
    p.d = d
    
    fn() for fn in I.onChangeListeners
    return

############################################################
paramsEqual = (a, b) -> JSON.stringify(a) == JSON.stringify(b)

toggleRefButtons = (I) ->
    p = I.model?.diffParams[I.dKey]
    return unless p?
    defP = I.getDefaultParams?()
    savedP = I.getSavedParams?()
    I.defaultButton.classList.toggle("visible", defP? and !paramsEqual(p, defP))
    I.resetButton.classList.toggle("visible", savedP? and !paramsEqual(p, savedP))
    return

applyRef = (I, getter) ->
    ref = getter?()
    return unless ref?
    p = I.model.diffParams[I.dKey]
    p[k] = v for k, v of ref
    fn() for fn in I.onChangeListeners
    return

#endregion
