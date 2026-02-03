############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("focuspairmodule")
#endregion

############################################################
import { currencyToArea } from "./configmodule.js"
import * as areas from "./economicareasmodule.js"
import * as scoring from "./scoringmodule.js"

############################################################
# DOM references (set after initialize)
baseAreaEl = null
quoteAreaEl = null
resultsAreaEl = null

# Normalization cell references
normCells = {
    inf: { base: null, quote: null, diff: null }
    mrr: { base: null, quote: null, diff: null }
    gdp: { base: null, quote: null, diff: null }
    cot: { base: null, quote: null, diff: null }
}

# Results display references (cached for direct updates)
# Structure per horizon: { scoreEl, trendEl, resultEl, scoringResultEl, scores: {inf, mrr, gdp, cot}, weights: {i, l, g, c} }
resultEls = { st: null, mlt: null, lt: null }

############################################################
currentPair = null

# Working data: cloned from real, modified by user inputs
# Structure: { base: {hicp, mrr, gdpg, cotIndex6, cotIndex36}, quote: {...} }
workingData = { base: null, quote: null }

# Real data snapshot (for comparison and reset)
realData = { base: null, quote: null }

# Working params: cloned from area params, modified by user inputs
# Structure per role: { inflation: {a,b,c}, interest: {a,b}, gdp: {a,b,c}, cot: {f} }
workingParams = { base: null, quote: null }

# Cached DOM refs for norm cells (for live updates without re-rendering)
# Structure: { inf: { base: {elements...}, quote: {elements...} }, gdp: {...} }
normCellEls = {
    inf: { base: null, quote: null }
    gdp: { base: null, quote: null }
}

############################################################
export initialize = ->
    log "initialize"
    # Row 1: Area displays + results
    baseAreaEl = document.getElementById("base-area")
    quoteAreaEl = document.getElementById("quote-area")
    resultsAreaEl = document.getElementById("results-area")

    # Rows 2-5: Normalization and diff cells
    normCells.inf.base = document.getElementById("inf-norm-base")
    normCells.inf.quote = document.getElementById("inf-norm-quote")
    normCells.inf.diff = document.getElementById("inf-diff")

    normCells.mrr.base = document.getElementById("mrr-norm-base")
    normCells.mrr.quote = document.getElementById("mrr-norm-quote")
    normCells.mrr.diff = document.getElementById("mrr-diff")

    normCells.gdp.base = document.getElementById("gdp-norm-base")
    normCells.gdp.quote = document.getElementById("gdp-norm-quote")
    normCells.gdp.diff = document.getElementById("gdp-diff")

    normCells.cot.base = document.getElementById("cot-norm-base")
    normCells.cot.quote = document.getElementById("cot-norm-quote")
    normCells.cot.diff = document.getElementById("cot-diff")

    # Cache result elements for direct updates
    cacheResultElements()

    # Initialize weight inputs with current values and attach handlers
    initializeWeightInputs()

    # Initialize with placeholder content
    initializePlaceholders()
    return

############################################################
# Cache result display elements for each horizon
cacheResultElements = ->
    for horizon in ["st", "mlt", "lt"]
        box = document.getElementById("result-#{horizon}")
        continue unless box

        resultEls[horizon] = {
            scoringResultEl: box.querySelector(".scoring-result")
            scoreEl: box.querySelector(".result-score")
            trendEl: box.querySelector(".trend-text")
            resultEl: box.querySelector(".eq-result")
            # Score constants (colored backgrounds = readonly)
            scores: {
                inf: box.querySelector(".eq-term.inf .eq-score")
                mrr: box.querySelector(".eq-term.mrr .eq-score")
                gdp: box.querySelector(".eq-term.gdp .eq-score")
                cot: box.querySelector(".eq-term.cot .eq-score")
            }
            # Weight inputs (editable)
            weights: {
                i: box.querySelector(".weight-input[data-indicator='i']")
                l: box.querySelector(".weight-input[data-indicator='l']")
                g: box.querySelector(".weight-input[data-indicator='g']")
                c: box.querySelector(".weight-input[data-indicator='c']")
            }
        }
    return

############################################################
# Initialize weight inputs with current values and attach handlers
initializeWeightInputs = ->
    allWeights = scoring.getWeights()

    for horizon in ["st", "mlt", "lt"]
        els = resultEls[horizon]
        continue unless els?

        horizonWeights = allWeights[horizon]
        for indicator in ["i", "l", "g", "c"]
            input = els.weights[indicator]
            continue unless input?
            input.value = horizonWeights[indicator]
            input.addEventListener("input", handleWeightChange)
    return

############################################################
# Handle weight input changes
handleWeightChange = (event) ->
    input = event.target
    horizon = input.dataset.horizon
    indicator = input.dataset.indicator
    value = parseInt(input.value, 10)

    return if isNaN(value)

    scoring.setWeight(horizon, indicator, value)
    recalculateScore()
    return

############################################################
# Initialize cells with placeholder content
initializePlaceholders = ->
    # Quadratic cells (inf, gdp) - render structure now, populate on pair select
    for key in ["inf", "gdp"]
        label = if key == "inf" then "Inflation" else "GDP"
        for role in ["base", "quote"]
            renderQuadraticNormCell(normCells[key][role], key, role, label)
        # Diff cells - placeholder for now (Step 4d)
        if normCells[key].diff
            normCells[key].diff.innerHTML = """
                <div class="cell-header">#{label} Diff</div>
                <div class="result-display">--</div>
            """

    # MRR and COT - simple placeholders (Step 4b, 4c)
    labels = { mrr: "Leitzins", cot: "COT" }
    for key, label of labels
        if normCells[key].base
            normCells[key].base.innerHTML = """
                <div class="cell-header">#{label} (Base)</div>
                <div class="result-display">--</div>
            """
        if normCells[key].quote
            normCells[key].quote.innerHTML = """
                <div class="cell-header">#{label} (Quote)</div>
                <div class="result-display">--</div>
            """
        if normCells[key].diff
            normCells[key].diff.innerHTML = """
                <div class="cell-header">#{label} Diff</div>
                <div class="result-display">--</div>
            """
    return

############################################################
# Render quadratic normalization cell structure (Inflation, GDP)
renderQuadraticNormCell = (container, indicator, role, label) ->
    return unless container

    roleLabel = if role == "base" then "Base" else "Quote"
    container.innerHTML = """
        <div class="cell-header">#{label} (#{roleLabel}) Normalisierung</div>
        <div class="norm-content">
            <div class="param-row">
                <span class="param-label">Höchstwert bei</span>
                <span class="param-value-wrap">
                    <input type="number" step="0.1" class="param-input peak-input"
                        data-indicator="#{indicator}" data-role="#{role}" data-param="peak">
                    <span class="param-unit">%</span>
                </span>
            </div>
            <div class="param-row">
                <span class="param-label">Flachheit</span>
                <input type="number" step="0.1" min="0.1" class="param-input steepness-input"
                    data-indicator="#{indicator}" data-role="#{role}" data-param="steepness">
            </div>
            <div class="param-row feedback-row">
                <span class="param-label">Nullwerte</span>
                <span class="param-display zero-range">
                    <span class="zero-low">--</span>% und <span class="zero-high">--</span>%
                </span>
            </div>
            <div class="norm-equation">
                <span class="eq-label">n(</span>
                <span class="eq-input-value #{indicator}">--</span>
                <span class="eq-label">) =</span>
                <span class="norm-result">--</span>
            </div>
        </div>
    """

    # Cache element references for live updates
    normCellEls[indicator] ?= {}
    normCellEls[indicator][role] = {
        peakInput: container.querySelector(".peak-input")
        steepnessInput: container.querySelector(".steepness-input")
        zeroLow: container.querySelector(".zero-low")
        zeroHigh: container.querySelector(".zero-high")
        eqInputValue: container.querySelector(".eq-input-value")
        normResult: container.querySelector(".norm-result")
    }

    # Attach input handlers
    els = normCellEls[indicator][role]
    els.peakInput.addEventListener("input", handleQuadraticParamChange)
    els.steepnessInput.addEventListener("input", handleQuadraticParamChange)
    return

############################################################
# Handle quadratic param input changes (peak, steepness)
handleQuadraticParamChange = (event) ->
    input = event.target
    indicator = input.dataset.indicator
    role = input.dataset.role
    param = input.dataset.param
    value = parseFloat(input.value)

    return if isNaN(value)
    return unless workingParams[role]?

    # Get current peak/steepness, update the changed one
    els = normCellEls[indicator][role]
    peak = parseFloat(els.peakInput.value)
    steepness = parseFloat(els.steepnessInput.value)

    return if isNaN(peak) or isNaN(steepness) or steepness <= 0

    # Convert to a,b,c coefficients
    paramKey = if indicator == "inf" then "inflation" else "gdp"
    defaultWidth = scoring.defaultWidths[paramKey]
    coeffs = scoring.peakSteepnessToCoeffs(peak, steepness, defaultWidth)

    # Update working params
    workingParams[role][paramKey] = { a: coeffs.a, b: coeffs.b, c: coeffs.c }

    # Update zero feedback display
    els.zeroLow.textContent = coeffs.zeroLow.toFixed(1)
    els.zeroHigh.textContent = coeffs.zeroHigh.toFixed(1)

    # Recalculate and update displays
    recalculateScore()
    return

############################################################
export setFocusPair = (pairLabel) ->
    log "setFocusPair: #{pairLabel}"
    return unless pairLabel?.length == 6

    baseCurrency = pairLabel.substring(0, 3)
    quoteCurrency = pairLabel.substring(3, 6)

    baseKey = currencyToArea[baseCurrency]
    quoteKey = currencyToArea[quoteCurrency]

    unless baseKey and quoteKey
        log "Unknown currency in pair: #{pairLabel}"
        return

    currentPair = { base: baseKey, quote: quoteKey, label: pairLabel }

    baseArea = areas.getArea(baseKey)
    quoteArea = areas.getArea(quoteKey)

    # Clone real data for working state
    if baseArea
        realData.base = cloneAreaData(baseArea)
        workingData.base = cloneAreaData(baseArea)
        workingParams.base = cloneAreaParams(baseArea)
        renderArea(baseAreaEl, getAreaRenderData(baseArea), "base")
        populateQuadraticCells("base")

    if quoteArea
        realData.quote = cloneAreaData(quoteArea)
        workingData.quote = cloneAreaData(quoteArea)
        workingParams.quote = cloneAreaParams(quoteArea)
        renderArea(quoteAreaEl, getAreaRenderData(quoteArea), "quote")
        populateQuadraticCells("quote")

    # Calculate and render score
    if baseArea and quoteArea
        calculateAndRenderScore(baseArea, quoteArea)

    return

############################################################
# Calculate score and render results
calculateAndRenderScore = (baseArea, quoteArea) ->
    return unless workingParams.base? and workingParams.quote?

    result = scoring.calculatePairScore(
        workingData.base,
        workingData.quote,
        workingParams.base,
        workingParams.quote
    )

    log "Score breakdown for #{currentPair.label}:"
    olog result

    renderResults(result)
    return

############################################################
# Recalculate score with current working data and params
recalculateScore = ->
    return unless currentPair?
    return unless workingParams.base? and workingParams.quote?

    result = scoring.calculatePairScore(
        workingData.base,
        workingData.quote,
        workingParams.base,
        workingParams.quote
    )

    log "Recalculated score for #{currentPair.label}:"
    olog result.final

    renderResults(result)
    return

############################################################
# Clone only the editable data fields from an area
cloneAreaData = (area) ->
    data = area.getData()
    return {
        hicp: data.hicp
        mrr: data.mrr
        gdpg: data.gdpg
        cotIndex6: data.cotIndex6
        cotIndex36: data.cotIndex36
    }

############################################################
# Clone area params (deep copy)
cloneAreaParams = (area) ->
    params = area.getParams()
    return {
        inflation: { ...params.inflation }
        interest: { ...params.interest }
        gdp: { ...params.gdp }
        cot: { ...params.cot }
    }

############################################################
# Populate quadratic norm cells with current values
populateQuadraticCells = (role) ->
    return unless workingParams[role]? and workingData[role]?

    for indicator in ["inf", "gdp"]
        paramKey = if indicator == "inf" then "inflation" else "gdp"
        dataKey = if indicator == "inf" then "hicp" else "gdpg"

        els = normCellEls[indicator]?[role]
        continue unless els?

        # Raw value from working data
        rawValue = workingData[role][dataKey]
        els.rawValue.textContent = if typeof rawValue == "number" then rawValue.toFixed(2) else "--"

        # Convert a,b,c to peak + steepness
        params = workingParams[role][paramKey]
        defaultWidth = scoring.defaultWidths[paramKey]
        converted = scoring.coeffsToPeakSteepness(params.a, params.b, params.c, defaultWidth)

        if converted?
            els.peakInput.value = converted.peak.toFixed(1)
            els.steepnessInput.value = converted.steepness.toFixed(2)
            els.zeroLow.textContent = converted.zeroLow.toFixed(1)
            els.zeroHigh.textContent = converted.zeroHigh.toFixed(1)
        else
            els.peakInput.value = ""
            els.steepnessInput.value = ""
            els.zeroLow.textContent = "--"
            els.zeroHigh.textContent = "--"

    return

############################################################
# Combine area info and data for rendering
getAreaRenderData = (area) ->
    info = area.getInfo()
    data = area.getData()
    return { ...info, ...data }

############################################################
renderArea = (container, data, role) ->
    return unless container and data

    container.innerHTML = ""
    container.className = "economic-area grid-cell #{role}-area"

    # Header with flag and title
    topEl = document.createElement("div")
    topEl.className = "area-top"
    topEl.innerHTML = """
        <div class="area-flag"><svg><use href="#{data.iconHref}"></use></svg></div>
        <div class="area-title">#{data.title}</div>
        <div class="area-currency">#{data.currencyShort}</div>
    """
    container.appendChild(topEl)

    # Data rows with editable inputs
    addDataRow(container, "Inflation", "hicp", "%", role)
    addDataRow(container, "Leitzins", "mrr", "%", role)
    addDataRow(container, "GDP Wachstum", "gdpg", "%", role)
    addCotRow(container, "COT Index", role)

    # Reset button (hidden until modified)
    resetBtn = document.createElement("button")
    resetBtn.className = "reset-button"
    resetBtn.textContent = "Reset"
    resetBtn.dataset.role = role
    resetBtn.addEventListener("click", -> resetArea(role))
    container.appendChild(resetBtn)

    return

############################################################
addDataRow = (container, label, field, unit, role) ->
    row = document.createElement("div")
    row.className = "data-row"

    labelEl = document.createElement("span")
    labelEl.className = "data-label"
    labelEl.textContent = label

    valueWrapper = document.createElement("span")
    valueWrapper.className = "data-value"

    input = document.createElement("input")
    input.type = "number"
    input.step = "0.01"
    input.className = "data-input"
    input.dataset.field = field
    input.dataset.role = role
    input.value = workingData[role]?[field] ? ""
    input.addEventListener("input", handleInputChange)

    unitEl = document.createElement("span")
    unitEl.textContent = unit

    valueWrapper.appendChild(input)
    valueWrapper.appendChild(unitEl)
    row.appendChild(labelEl)
    row.appendChild(valueWrapper)
    container.appendChild(row)
    return

############################################################
addCotRow = (container, label, role) ->
    row = document.createElement("div")
    row.className = "data-row cot-row"

    labelEl = document.createElement("span")
    labelEl.className = "data-label"
    labelEl.textContent = label

    valueWrapper = document.createElement("span")
    valueWrapper.className = "data-value cot-values"

    input6 = document.createElement("input")
    input6.type = "number"
    input6.step = "1"
    input6.min = "0"
    input6.max = "100"
    input6.className = "data-input cot-input"
    input6.dataset.field = "cotIndex6"
    input6.dataset.role = role
    input6.value = Math.round(workingData[role]?.cotIndex6 ? 0)
    input6.addEventListener("input", handleInputChange)

    sep = document.createElement("span")
    sep.className = "cot-separator"
    sep.textContent = "/"

    input36 = document.createElement("input")
    input36.type = "number"
    input36.step = "1"
    input36.min = "0"
    input36.max = "100"
    input36.className = "data-input cot-input"
    input36.dataset.field = "cotIndex36"
    input36.dataset.role = role
    input36.value = Math.round(workingData[role]?.cotIndex36 ? 0)
    input36.addEventListener("input", handleInputChange)

    pct1 = document.createElement("span")
    pct1.textContent = "%"
    pct2 = document.createElement("span")
    pct2.textContent = "%"

    valueWrapper.appendChild(input6)
    valueWrapper.appendChild(pct1)
    valueWrapper.appendChild(sep)
    valueWrapper.appendChild(input36)
    valueWrapper.appendChild(pct2)
    row.appendChild(labelEl)
    row.appendChild(valueWrapper)
    container.appendChild(row)
    return

############################################################
handleInputChange = (event) ->
    input = event.target
    field = input.dataset.field
    role = input.dataset.role
    value = parseFloat(input.value)

    return unless workingData[role]? and !isNaN(value)

    workingData[role][field] = value
    updateInputModifiedState(input, role, field)
    updateResetButtonVisibility(role)

    # Recalculate score with new values
    recalculateScore()
    return

############################################################
updateInputModifiedState = (input, role, field) ->
    realValue = realData[role]?[field]
    workingValue = workingData[role]?[field]

    # Compare with tolerance for floating point
    isModified = Math.abs(realValue - workingValue) > 0.001
    input.classList.toggle("modified", isModified)
    return

############################################################
updateResetButtonVisibility = (role) ->
    container = if role == "base" then baseAreaEl else quoteAreaEl
    resetBtn = container?.querySelector(".reset-button")
    return unless resetBtn

    hasModifications = isAreaModified(role)
    resetBtn.classList.toggle("visible", hasModifications)
    return

############################################################
isAreaModified = (role) ->
    return false unless realData[role]? and workingData[role]?

    for field in ["hicp", "mrr", "gdpg", "cotIndex6", "cotIndex36"]
        if Math.abs(realData[role][field] - workingData[role][field]) > 0.001
            return true
    return false

############################################################
resetArea = (role) ->
    log "resetArea: #{role}"
    return unless realData[role]?

    # Clone real data back to working
    workingData[role] = { ...realData[role] }

    # Update all inputs in this area
    container = if role == "base" then baseAreaEl else quoteAreaEl
    inputs = container?.querySelectorAll(".data-input")
    inputs?.forEach (input) ->
        field = input.dataset.field
        value = workingData[role][field]
        input.value = if field.startsWith("cot") then Math.round(value) else value
        input.classList.remove("modified")

    updateResetButtonVisibility(role)
    return

############################################################
# Score visualization (matching currencytrendframemodule)
scoreColors = [
    "#33cc00"  # Super Bullish
    "#55d04b"  # Stark Bullish
    "#79d399"  # Bullish
    "#ddd"     # Neutral
    "#eb803d"  # Bearish
    "#db591e"  # Stark Bearish
    "#cc3300"  # Super Bearish
]

trendTexts = [
    "Super Bullish"
    "Stark Bullish"
    "Bullish"
    "Neutral"
    "Bearish"
    "Stark Bearish"
    "Super Bearish"
]

maxScore = 30
minScore = -30
scoreRange = maxScore - minScore

############################################################
# Get color for score (-30 to 30)
getScoreColor = (score) ->
    return scoreColors[0] if score > maxScore
    return scoreColors[scoreColors.length - 1] if score < minScore

    regionSize = scoreRange / scoreColors.length
    shifted = score - minScore
    region = Math.floor(shifted / regionSize)
    region = Math.min(region, scoreColors.length - 1)
    region = Math.max(region, 0)
    region = scoreColors.length - 1 - region  # invert: higher score = lower index
    return scoreColors[region]

############################################################
# Get trend text for score (-30 to 30)
getTrendText = (score) ->
    return trendTexts[0] if score > maxScore
    return trendTexts[trendTexts.length - 1] if score < minScore

    regionSize = scoreRange / trendTexts.length
    shifted = score - minScore
    region = Math.floor(shifted / regionSize)
    region = Math.min(region, trendTexts.length - 1)
    region = Math.max(region, 0)
    region = trendTexts.length - 1 - region
    return trendTexts[region]

############################################################
# Render results by updating cached elements (no DOM replacement)
renderResults = (result) ->
    { scores } = result
    { st, mlt, lt } = result.final

    updateResultBox("st", st, scores)
    updateResultBox("mlt", mlt, scores)
    updateResultBox("lt", lt, scores)

    # Update quadratic norm cell results (Inf, GDP)
    updateQuadraticNormResults(result)
    return

############################################################
# Update normalized results in quadratic cells
updateQuadraticNormResults = (result) ->
    for indicator in ["inf", "gdp"]
        normKey = if indicator == "inf" then "infNorm" else "gdpNorm"

        for role in ["base", "quote"]
            els = normCellEls[indicator]?[role]
            continue unless els?

            normValue = result[role]?[normKey]
            if typeof normValue == "number"
                els.normResult.textContent = normValue.toFixed(2)
            else
                els.normResult.textContent = "--"

        # Also update raw values (in case data changed)
        dataKey = if indicator == "inf" then "hicp" else "gdpg"
        for role in ["base", "quote"]
            els = normCellEls[indicator]?[role]
            continue unless els?
            rawValue = workingData[role]?[dataKey]
            if typeof rawValue == "number"
                els.rawValue.textContent = rawValue.toFixed(2)

    return

############################################################
# Update a single result box with new values
updateResultBox = (horizon, finalScore, scores) ->
    els = resultEls[horizon]
    return unless els?

    # Update main score display
    bgColor = getScoreColor(finalScore)
    trendText = getTrendText(finalScore)

    els.scoringResultEl.style.background = bgColor
    els.scoreEl.textContent = Math.round(finalScore)
    els.trendEl.textContent = trendText

    # Update score constants (colored backgrounds indicate readonly)
    els.scores.inf.textContent = scores.inf.toFixed(2)
    els.scores.mrr.textContent = scores.mrr.toFixed(2)
    els.scores.gdp.textContent = scores.gdp.toFixed(2)
    els.scores.cot.textContent = scores.cot.toFixed(2)

    # Update equation result (unrounded)
    els.resultEl.textContent = finalScore.toFixed(2)
    return

############################################################
getCotClass = (index) ->
    if index >= 70 then return "strong"
    if index <= 30 then return "weak"
    return ""

############################################################
export getCurrentPair = -> currentPair
export getBaseArea = -> areas.getArea(currentPair?.base) if currentPair
export getQuoteArea = -> areas.getArea(currentPair?.quote) if currentPair

############################################################
# Re-render current pair (call after data arrives)
export refreshCurrentPair = ->
    return unless currentPair
    log "refreshCurrentPair: #{currentPair.label}"
    setFocusPair(currentPair.label)
    return
