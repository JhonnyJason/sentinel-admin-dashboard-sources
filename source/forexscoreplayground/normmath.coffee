############################################################
# Pure math for normalization parameter conversions.
# No state, no DOM — just conversions between user-friendly
# params (peak/steepness, neutralRate/sensitivity) and
# internal coefficients (a, b, c).

############################################################
# Quadratic: peak + steepness → a, b, c coefficients
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
# Quadratic: a, b, c coefficients → peak + steepness
# Returns { peak, steepness, zeroLow, zeroHigh } or null
export coeffsToPeakSteepness = (a, b, c, defaultWidth) ->
    return null if c >= 0
    width = Math.sqrt(-12 / c)
    steepness = defaultWidth / width
    peak = -b / (2 * c)
    zeroLow = peak - width / 2
    zeroHigh = peak + width / 2
    return { peak, steepness, zeroLow, zeroHigh }

############################################################
# Linear: neutralRate + sensitivity → a, b
export neutralSensitivityToCoeffs = (neutralRate, sensitivity) ->
    a = -sensitivity * neutralRate
    b = sensitivity
    return { a, b }

############################################################
# Linear: a, b → neutralRate + sensitivity
export coeffsToNeutralSensitivity = (a, b) ->
    sensitivity = b
    neutralRate = if b != 0 then -a / b else 0
    return { neutralRate, sensitivity }

############################################################
# Reference widths when steepness = 1.0 (from scoring-design.md)
export defaultWidths = {
    infl: 12  # zeroHigh(10) - zeroLow(-2) for EUR
    gdpg: 8  # zeroHigh(6) - zeroLow(-2) for EUR
}
