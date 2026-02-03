############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("focuspairmodule")
#endregion

############################################################
import { currencyToArea } from "./configmodule.js"
import * as areas from "./economicareasmodule.js"

############################################################
# DOM references (set after initialize)
baseAreaEl = null
quoteAreaEl = null

############################################################
currentPair = null

# Working data: cloned from real, modified by user inputs
# Structure: { base: {hicp, mrr, gdpg, cotIndex6, cotIndex36}, quote: {...} }
workingData = { base: null, quote: null }

# Real data snapshot (for comparison and reset)
realData = { base: null, quote: null }

############################################################
export initialize = ->
    log "initialize"
    baseAreaEl = document.getElementById("base-area")
    quoteAreaEl = document.getElementById("quote-area")
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
        renderArea(baseAreaEl, getAreaRenderData(baseArea), "base")

    if quoteArea
        realData.quote = cloneAreaData(quoteArea)
        workingData.quote = cloneAreaData(quoteArea)
        renderArea(quoteAreaEl, getAreaRenderData(quoteArea), "quote")

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
# Combine area info and data for rendering
getAreaRenderData = (area) ->
    info = area.getInfo()
    data = area.getData()
    return { ...info, ...data }

############################################################
renderArea = (container, data, role) ->
    return unless container and data

    container.innerHTML = ""
    container.className = "economic-area #{role}-area"

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
