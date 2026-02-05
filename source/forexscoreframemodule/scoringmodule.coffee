############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("scoringmodule")
#endregion

############################################################
# Weight sets for different time horizons (mutable)
weights = {
    st: { i: 6, l: 9, g: 3, c: 13 }
    ml: { i: 7, l: 11, g: 5, c: 7 }
    lt: { i: 10, l: 6, g: 9, c: 5 }
}

############################################################
# Diff curve parameters (global)
diffParams = {
    infl: { b: 2.78, d: 0.248 }
    mrr: { b: 0, d: 0.05 }
    gdpg: { b: 2.78, d: 0.248 }
    cot: { b: 0, d: 0.05 }
}

############################################################
# Normalization: Quadratic (for inflation, GDP)
# Input: value, params {a, b, c}
# Output: normalized score in [0, 3]
normalizeQuadratic = (value, params) ->
    { a, b, c } = params
    n = a + b * value + c * value * value
    return Math.max(0, Math.min(3, n))

############################################################
# Normalization: Linear (for interest/MRR)
# Input: value, params {a, b}
# Output: normalized score (unbounded)
normalizeLinear = (value, params) ->
    { a, b } = params
    return a + b * value

############################################################
# Normalization: COT
# Input: cot6, cot36, params {f}
# Output: normalized score
normalizeCOT = (cot6, cot36, params) ->
    { f, e } = params
    c6 = 0.02 * cot6
    c36 = 0.02 * cot36
    return f * (c6 * Math.pow(c36, e))

############################################################
# Diff curve: cubic with linear component
# f(diff) = b * diff + d * diff³
diffCurve = (diff, params) ->
    { b, d } = params
    return b * diff + d * diff * diff * diff

############################################################
# Convert peak + steepness to a, b, c coefficients
# steepness = 1.0 means default width
# Returns { a, b, c, zeroLow, zeroHigh }
export peakSteepnessToCoeffs = (peak, steepness, defaultWidth) ->
    width = defaultWidth / steepness
    zeroLow = peak - width / 2
    zeroHigh = peak + width / 2
    k = -12 / (width * width)
    c = k
    b = -k * (zeroLow + zeroHigh)
    a = k * zeroLow * zeroHigh
    return { a, b, c, zeroLow, zeroHigh }

############################################################
# Convert a, b, c coefficients to peak + steepness
# Returns { peak, steepness, zeroLow, zeroHigh }
export coeffsToPeakSteepness = (a, b, c, defaultWidth) ->
    # From c = -12 / width², we get width = sqrt(-12 / c)
    return null if c >= 0
    width = Math.sqrt(-12 / c)
    steepness = defaultWidth / width
    # peak = -b / (2c)
    peak = -b / (2 * c)
    zeroLow = peak - width / 2
    zeroHigh = peak + width / 2
    return { peak, steepness, zeroLow, zeroHigh }

############################################################
# Convert neutralRate + sensitivity to a, b
export neutralSensitivityToCoeffs = (neutralRate, sensitivity) ->
    a = -sensitivity * neutralRate
    b = sensitivity
    return { a, b }

############################################################
# Convert a, b to neutralRate + sensitivity
export coeffsToNeutralSensitivity = (a, b) ->
    sensitivity = b
    neutralRate = if b != 0 then -a / b else 0
    return { neutralRate, sensitivity }

############################################################
# Calculate full scoring breakdown for a currency pair
# Input:
#   baseData: { infl, mrr, gdpg, cot6, cot36 }
#   quoteData: { infl, mrr, gdpg, cot6, cot36 }
#   baseParams: { infl: {a,b,c}, mrr: {a,b}, gdpg: {a,b,c}, cot: {f} }
#   quoteParams: same structure
#   globalDiffParams: optional override for diff curves
# Output: full breakdown object
export calculatePairScore = (baseData, quoteData, baseParams, quoteParams, globalDiffParams = diffParams) ->
    result = {
        base: {}
        quote: {}
        diff: {}
        scores: {}
        final: {}
    }

    # Inflation
    result.base.infNorm = normalizeQuadratic(baseData.infl, baseParams.inflation)
    result.quote.infNorm = normalizeQuadratic(quoteData.infl, quoteParams.inflation)
    result.diff.infl = result.base.infNorm - result.quote.infNorm
    result.scores.infl = diffCurve(result.diff.infl, globalDiffParams.inflation)

    # Interest (MRR)
    result.base.mrrNorm = normalizeLinear(baseData.mrr, baseParams.interest)
    result.quote.mrrNorm = normalizeLinear(quoteData.mrr, quoteParams.interest)
    result.diff.mrr = result.base.mrrNorm - result.quote.mrrNorm
    result.scores.mrr = diffCurve(result.diff.mrr, globalDiffParams.interest)

    # GDP
    result.base.gdpNorm = normalizeQuadratic(baseData.gdpg, baseParams.gdpg)
    result.quote.gdpNorm = normalizeQuadratic(quoteData.gdpg, quoteParams.gdpg)
    result.diff.gdpg = result.base.gdpNorm - result.quote.gdpNorm
    result.scores.gdpg = diffCurve(result.diff.gdpg, globalDiffParams.gdpg)

    # COT
    result.base.cotNorm = normalizeCOT(baseData.cot6, baseData.cot36, baseParams.cot)
    result.quote.cotNorm = normalizeCOT(quoteData.cot6, quoteData.cot36, quoteParams.cot)
    result.diff.cot = result.base.cotNorm - result.quote.cotNorm
    result.scores.cot = diffCurve(result.diff.cot, globalDiffParams.cot)

    # Final combination with weights
    result.final.st = combineWithWeights(result.scores, weights.st)
    result.final.ml = combineWithWeights(result.scores, weights.ml)
    result.final.lt = combineWithWeights(result.scores, weights.lt)

    return result

############################################################
# Combine individual scores with weights
combineWithWeights = (scores, weights) ->
    raw = weights.i * scores.infl +
          weights.l * scores.mrr +
          weights.g * scores.gdpg +
          weights.c * scores.cot
    # Clamp to [-30, 30]
    return Math.max(-30, Math.min(30, raw))

############################################################
# Accessors for weights (for UI display)
export getWeights = -> weights
export getDiffParams = -> diffParams

############################################################
# Update a single weight: horizon = 'st'|'ml'|'lt', indicator = 'i'|'l'|'g'|'c'
export setWeight = (horizon, indicator, value) ->
    return unless weights[horizon]? and weights[horizon][indicator]?
    weights[horizon][indicator] = value
    return

############################################################
# Update diff params (for manipulation)
export setDiffParams = (newParams) ->
    diffParams = { ...diffParams, ...newParams }
    return

############################################################
# Default widths for steepness calculation (from scoring-design.md)
# These are the reference widths when steepness = 1.0
export defaultWidths = {
    infl: 12  # zeroHigh(10) - zeroLow(-2) for EUR
    gdpg: 8         # zeroHigh(6) - zeroLow(-2) for EUR
}
