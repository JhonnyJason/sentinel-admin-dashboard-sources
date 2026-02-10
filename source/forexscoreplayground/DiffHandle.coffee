############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("DiffHandle")
#endregion

############################################################
# relevant structure files:
#     - components/cubdiff-el.pug

############################################################
export class DiffHandle
    constructor: (@containerEl, @dKey) ->
        @typeDisplay = @containerEl.querySelector(".diff-type-title")
        @bInput = @containerEl.querySelector(".b-input")
        @dInput = @containerEl.querySelector(".d-input")
        @coeffBDisplay = @containerEl.querySelector(".coeff-b")
        @coeffDDisplay = @containerEl.querySelector(".coeff-d")
        @baseValDisplay = @containerEl.querySelector(".diff-base-val")
        @quoteValDisplay = @containerEl.querySelector(".diff-quote-val")
        @resultDisplay = @containerEl.querySelector(".diff-result")

        @bInput.addEventListener("input", (e) => onInput(e, @, "b"))
        @dInput.addEventListener("input", (e) => onInput(e, @, "d"))
        @typeDisplay.textContent = @dKey

    setModel: (model) =>
        @model = model
        model.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    refreshUI: =>
        p = @model.getDiffParams()[@dKey]
        { baseScore, quoteScore } = @model.getDiffInputs(@dKey)
        r = @model.getDiffResults()[@dKey]

        # Skip input update while user is actively editing (avoids "1." → "1" mid-typing)
        if document.activeElement != @bInput then @bInput.value = p.b
        if document.activeElement != @dInput then @dInput.value = p.d

        @coeffBDisplay.textContent = p.b.toFixed(2)
        @coeffDDisplay.textContent = p.d.toFixed(3)
        @baseValDisplay.textContent = if isNaN(baseScore) then "--" else baseScore.toFixed(2)
        @quoteValDisplay.textContent = if isNaN(quoteScore) then "--" else quoteScore.toFixed(2)
        @resultDisplay.textContent = if isNaN(r.score) then "--" else r.score.toFixed(2)
        return

############################################################
#region Utility Functions which we donot want to expose in the class
# Here I is the specific instance

onInput = (evnt, I, wKey) ->
    val = parseFloat(evnt.target.value)
    return if isNaN(val)
    I.model.updateDiffParam(I.dKey, wKey, val)
    return

#endregion
