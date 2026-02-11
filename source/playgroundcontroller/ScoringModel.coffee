############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("ScoringModel")
#endregion

############################################################
# ScoringModel - Pair-level scoring engine
#
# Handles:
# - Diff curve parameters (b, d for each indicator)
# - Final combination weights (per time horizon)
# - Calculation: normalized scores → diffs → final scores
# - Update listeners for UI refresh
#
# Usage:
#   model = new ScoringModel()
#   model.setAreas(baseArea, quoteArea)
#   model.addUpdateListener(refreshUI)
#   # later: model.updateDiffParam("infl", "b", 2.5)

############################################################
export class ScoringModel
    constructor: ->
        @updateListeners = []
        @baseArea = null
        @quoteArea = null

        # Diff curve parameters: f(diff) = b * diff + d * diff³
        @diffParams = {
            infl: { b: 2.78, d: 0.248 }
            mrr:  { b: 0, d: 0.05 }
            gdpg: { b: 2.78, d: 0.248 }
            cot:  { b: 0, d: 0.05 }
        }

        # Final combination weights per time horizon
        @finalWeights = {
            st: { i: 6, l: 9, g: 3, c: 13 }   # short term
            ml: { i: 7, l: 11, g: 5, c: 7 }   # medium-long term
            lt: { i: 10, l: 6, g: 9, c: 5 }   # long term
        }

        # Calculated results (populated by recalculate)
        @diffResults = {
            infl: { baseNorm: 0, quoteNorm: 0, diff: 0, score: 0 }
            mrr:  { baseNorm: 0, quoteNorm: 0, diff: 0, score: 0 }
            gdpg: { baseNorm: 0, quoteNorm: 0, diff: 0, score: 0 }
            cot:  { baseNorm: 0, quoteNorm: 0, diff: 0, score: 0 }
        }

        @endResults = {
            st: { rawScore: 0, clampedScore: 0 }
            ml: { rawScore: 0, clampedScore: 0 }
            lt: { rawScore: 0, clampedScore: 0 }
        }

    ########################################################
    # Set the areas to score (called when focus pair changes)
    setAreas: (baseArea, quoteArea) =>
        @baseArea = baseArea
        @quoteArea = quoteArea
        @recalculate()
        return

    ########################################################
    # Main calculation - call when anything changes
    recalculate: =>
        return unless @baseArea and @quoteArea

        # Get normalized scores from areas
        baseInfl = @baseArea.normFun.infl.call(@baseArea)
        quoteInfl = @quoteArea.normFun.infl.call(@quoteArea)
        baseMrr = @baseArea.normFun.mrr.call(@baseArea)
        quoteMrr = @quoteArea.normFun.mrr.call(@quoteArea)
        baseGdpg = @baseArea.normFun.gdpg.call(@baseArea)
        quoteGdpg = @quoteArea.normFun.gdpg.call(@quoteArea)
        baseCot = @baseArea.normFun.cot.call(@baseArea)
        quoteCot = @quoteArea.normFun.cot.call(@quoteArea)

        # Calculate diffs and apply diff curves
        @diffResults.infl = @calcDiff(baseInfl, quoteInfl, @diffParams.infl)
        @diffResults.mrr = @calcDiff(baseMrr, quoteMrr, @diffParams.mrr)
        @diffResults.gdpg = @calcDiff(baseGdpg, quoteGdpg, @diffParams.gdpg)
        @diffResults.cot = @calcDiff(baseCot, quoteCot, @diffParams.cot)

        # Calculate final scores for each time horizon
        scores = {
            infl: @diffResults.infl.score
            mrr: @diffResults.mrr.score
            gdpg: @diffResults.gdpg.score
            cot: @diffResults.cot.score
        }

        @endResults.st = @calcFinal(scores, @finalWeights.st)
        @endResults.ml = @calcFinal(scores, @finalWeights.ml)
        @endResults.lt = @calcFinal(scores, @finalWeights.lt)

        # Notify listeners
        f() for f in @updateListeners
        return

    ########################################################
    # Calculate diff and apply diff curve
    # Returns { baseNorm, quoteNorm, diff, score }
    calcDiff: (baseNorm, quoteNorm, params) ->
        diff = baseNorm - quoteNorm
        # Cubic diff curve: f(diff) = b * diff + d * diff³
        score = params.b * diff + params.d * diff * diff * diff
        return { baseNorm, quoteNorm, diff, score }

    ########################################################
    # Calculate final weighted score
    # Returns { rawScore, clampedScore }
    calcFinal: (scores, weights) ->
        raw = weights.i * scores.infl +
              weights.l * scores.mrr +
              weights.g * scores.gdpg +
              weights.c * scores.cot
        clamped = Math.max(-30, Math.min(30, raw))
        return { rawScore: raw, clampedScore: clamped }

    ########################################################
    #region Getters

    getDiffParams: => @diffParams
    getFinalWeights: => @finalWeights
    getDiffResults: => @diffResults
    getEndResults: => @endResults

    # For DiffHandle - get inputs for a specific indicator
    getDiffInputs: (dKey) =>
        r = @diffResults[dKey]
        return { baseScore: r.baseNorm, quoteScore: r.quoteNorm }

    #endregion

    ########################################################
    #region Mutations

    # Update a diff param: type = 'infl'|'mrr'|'gdpg'|'cot', key = 'b'|'d'
    # No recalculate — caller triggers via paramChanged
    updateDiffParam: (type, key, value) =>
        return unless @diffParams[type]?
        @diffParams[type][key] = value
        return

    # Update a final weight: horizon = 'st'|'ml'|'lt', key = 'i'|'l'|'g'|'c'
    # No recalculate — caller triggers via paramChanged
    updateFinalWeight: (horizon, key, value) =>
        return unless @finalWeights[horizon]?
        @finalWeights[horizon][key] = value
        return

    # Bulk-set diff params (for version control apply)
    setDiffParams: (p) =>
        for type in ["infl", "mrr", "gdpg", "cot"]
            @diffParams[type] = { ...p[type] } if p[type]?
        return

    # Bulk-set final weights (for version control apply)
    setFinalWeights: (w) =>
        for horizon in ["st", "ml", "lt"]
            @finalWeights[horizon] = { ...w[horizon] } if w[horizon]?
        return

    #endregion

    ########################################################
    #region Listeners

    addUpdateListener: (fn) =>
        throw new Error("Not a function!") unless typeof fn == "function"
        @updateListeners.push(fn)
        return

    removeUpdateListener: (fn) =>
        @updateListeners[i] = null for f,i in @updateListeners when f == fn
        @updateListeners = @updateListeners.filter((el) -> el?)
        return

    #endregion
