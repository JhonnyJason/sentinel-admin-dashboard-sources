############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("ResultBoxHandle")
#endregion

############################################################
# relevant structure files:
#     - components/result-el.pug
#     - components/result-inner.pug

############################################################
import * as sH from "./scorehelper.js"

############################################################
export class ResultBoxHandle
    constructor: (@containerEl) ->
        ## short term score 
        # resultSt should be available through implicit DOM connect
        @stInflScoreDisplay = resultSt.querySelector(".infl .eq-score")
        @stInflWeightInput = resultSt.querySelector(".infl .weight-input")

        @stMrrScoreDisplay = resultSt.querySelector(".mrr .eq-score")
        @stMrrWeightInput = resultSt.querySelector(".mrr .weight-input")

        @stGdpgScoreDisplay = resultSt.querySelector(".gdpg .eq-score")
        @stGdpgWeightInput = resultSt.querySelector(".gdpg .weight-input")

        @stCotScoreDisplay = resultSt.querySelector(".cot .eq-score")
        @stCotWeightInput = resultSt.querySelector(".cot .weight-input")

        @stResultFrame = resultSt.querySelector(".scoring-result")
        @stResultDisplay = resultSt.querySelector(".result-score")
        @stTrendDisplay = resultSt.querySelector(".trend-text")

        ## medium long term score
        # resultMl should be available through implicit DOM connect
        @mlInflScoreDisplay = resultMl.querySelector(".infl .eq-score")
        @mlInflWeightInput = resultMl.querySelector(".infl .weight-input")

        @mlMrrScoreDisplay = resultMl.querySelector(".mrr .eq-score")
        @mlMrrWeightInput = resultMl.querySelector(".mrr .weight-input")

        @mlGdpgScoreDisplay = resultMl.querySelector(".gdpg .eq-score")
        @mlGdpgWeightInput = resultMl.querySelector(".gdpg .weight-input")

        @mlCotScoreDisplay = resultMl.querySelector(".cot .eq-score")
        @mlCotWeightInput = resultMl.querySelector(".cot .weight-input")

        @mlResultFrame = resultMl.querySelector(".scoring-result")
        @mlResultDisplay = resultMl.querySelector(".result-score")
        @mlTrendDisplay = resultMl.querySelector(".trend-text")

        ## long term score
        # resultLt should be available through implicit DOM connect
        @ltInflScoreDisplay = resultLt.querySelector(".infl .eq-score")
        @ltInflWeightInput = resultLt.querySelector(".infl .weight-input")

        @ltMrrScoreDisplay = resultLt.querySelector(".mrr .eq-score")
        @ltMrrWeightInput = resultLt.querySelector(".mrr .weight-input")

        @ltGdpgScoreDisplay = resultLt.querySelector(".gdpg .eq-score")
        @ltGdpgWeightInput = resultLt.querySelector(".gdpg .weight-input")

        @ltCotScoreDisplay = resultLt.querySelector(".cot .eq-score")
        @ltCotWeightInput = resultLt.querySelector(".cot .weight-input")

        @ltResultFrame = resultLt.querySelector(".scoring-result")
        @ltResultDisplay = resultLt.querySelector(".result-score")
        @ltTrendDisplay = resultLt.querySelector(".trend-text")

        I = this
        ## attach Event Listeners
        @stInflWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "st", "i")))
        @mlInflWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "ml", "i")))
        @ltInflWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "lt", "i")))

        @stMrrWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "st", "l")))
        @mlMrrWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "ml", "l")))
        @ltMrrWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "lt", "l")))

        @stGdpgWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "st", "g")))
        @mlGdpgWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "ml", "g")))
        @ltGdpgWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "lt", "g")))

        @stCotWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "st", "c")))
        @mlCotWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "ml", "c")))
        @ltCotWeightInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "lt", "c")))

    setModel: (model) =>
        @model = model
        # wire up updates
        @model.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    refreshUI: =>
        params = @model.getFinalWeights()
        diffResults = @model.getDiffResults()
        endResults = @model.getEndResults()

        ## short term elements
        @stInflWeightInput.value = params.st.i
        @stInflScoreDisplay.textContent = diffResults.infl.score.toFixed(2)

        @stMrrWeightInput.value = params.st.l
        @stMrrScoreDisplay.textContent = diffResults.mrr.score.toFixed(2)

        @stGdpgWeightInput.value = params.st.g
        @stGdpgScoreDisplay.textContent = diffResults.gdpg.score.toFixed(2)

        @stCotWeightInput.value = params.st.c
        @stCotScoreDisplay.textContent = diffResults.cot.score.toFixed(2)

        score = Math.round(endResults.st.clampedScore)
        color = sH.getColorForScore(score)
        @stResultFrame.style.backgroundColor = color
        @stResultDisplay.textContent = score
        @stTrendDisplay.textContent = sH.getTrendTextForScore(score)

        ## medium longer term elements
        @mlInflWeightInput.value = params.ml.i
        @mlInflScoreDisplay.textContent = diffResults.infl.score.toFixed(2)

        @mlMrrWeightInput.value = params.ml.l
        @mlMrrScoreDisplay.textContent = diffResults.mrr.score.toFixed(2)

        @mlGdpgWeightInput.value = params.ml.g
        @mlGdpgScoreDisplay.textContent = diffResults.gdpg.score.toFixed(2)

        @mlCotWeightInput.value = params.ml.c
        @mlCotScoreDisplay.textContent = diffResults.cot.score.toFixed(2)

        score = Math.round(endResults.ml.clampedScore)
        color = sH.getColorForScore(score)
        @mlResultFrame.style.backgroundColor = color
        @mlResultDisplay.textContent = score
        @mlTrendDisplay.textContent = sH.getTrendTextForScore(score)

        ## longer term elements
        @ltInflWeightInput.value = params.lt.i
        @ltInflScoreDisplay.textContent = diffResults.infl.score.toFixed(2)

        @ltMrrWeightInput.value = params.lt.l
        @ltMrrScoreDisplay.textContent = diffResults.mrr.score.toFixed(2)

        @ltGdpgWeightInput.value = params.lt.g
        @ltGdpgScoreDisplay.textContent = diffResults.gdpg.score.toFixed(2)

        @ltCotWeightInput.value = params.lt.c
        @ltCotScoreDisplay.textContent = diffResults.cot.score.toFixed(2)

        score = Math.round(endResults.lt.clampedScore)
        color = sH.getColorForScore(score)
        @ltResultFrame.style.backgroundColor = color
        @ltResultDisplay.textContent = score
        @ltTrendDisplay.textContent = sH.getTrendTextForScore(score)
        return
    
############################################################
#region Utility Functions which we donot want to expose in the class
# Here I is the specific instance

############################################################
onInput = (evnt, I, tKey, wKey) ->
    val = parseFloat(evnt.target.value)
    return if isNaN(val)

    #replaces scoring.setWeight(tKey, wKey, val)
    I.model.updateFinalWeight(tKey, wKey, val)
    return


#endregion
