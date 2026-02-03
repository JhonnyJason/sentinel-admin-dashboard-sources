############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("economicareasmodule")
#endregion

############################################################
import M from "mustache"

############################################################
import * as focusPairModule from "./focuspairmodule.js"

############################################################
economicAreaTemplate = null
allAreas = null

############################################################
export initialize = ->
    log "initialize"
    economicAreaTemplate = document.getElementById("economic-area-template").innerHTML
    createAllAreas()
    return

############################################################
class EconomicArea
    constructor:  (o) ->
        @key = o.key
        @title = o.title
        @currencyName = o.currencyName
        @currencyShort = o.currencyShort
        @iconHref = o["icon-href"]
        @updateListeners = []

        @inflationParams = o.inflationParams
        @interestParams = o.interestParams
        @inflationParams = o.inflationParams
        @gdpParams = o.gdpParams
        @cotParams = o.cotParams
        
        @metaData = {
            hicp: {}
            mrr: {}
            gdpg: {}
        }
        @data = {
            hicp: "N/A"
            mrr: "N/A"
            gdpg: "N/A"
            cotIndex36: "N/A"
            cotIndex6: "N/A"
        }

        cObj = {
            "icon-href": o["icon-href"]
            title: o.title
            "inflation": @data.hicp
            "policyRate": @data.mrr
            "gdpg": @data.gdpg
            "cotIndex36": @data.cotIndex36
            "cotIndex6": @data.cotIndex6
        }

        virtualContainer = document.createElement("v")
        olog {virtualContainer}
        html = M.render(economicAreaTemplate, cObj)
        virtualContainer.innerHTML = html.trim()
        log html
        @element = virtualContainer.firstChild
        
        p = @element.getElementsByClassName("inflation-rate")[0]
        @inflationEl = p.getElementsByClassName("value")[0]
        infoButton = p.getElementsByClassName("info-button")[0]
        infoButton.addEventListener("click", @inflationInfoClicked)

        p = @element.getElementsByClassName("refinancing-rate")[0]
        @refinancingEl = p.getElementsByClassName("value")[0]
        infoButton = p.getElementsByClassName("info-button")[0]
        infoButton.addEventListener("click", @refinancingInfoClicked)

        p = @element.getElementsByClassName("gdp-growth")[0]
        @gdpgrowthEl = p.getElementsByClassName("value")[0]
        infoButton = p.getElementsByClassName("info-button")[0]
        infoButton.addEventListener("click", @gdpGrowthInfoClicked)

        p = @element.getElementsByClassName("cot-index-6")[0]
        @cotIndex6El = p.getElementsByClassName("value")[0]
        
        p = @element.getElementsByClassName("cot-index-36")[0]
        @cotIndex36El = p.getElementsByClassName("value")[0]
        
        p = @element.getElementsByClassName("info-display")[0]
        @infoTitleEl = p.getElementsByClassName("info-title")[0]
        @infoDescriptionEl = p.getElementsByClassName("info-description")[0]
        
        closeButton = p.getElementsByClassName("close-button")[0]
        closeButton.addEventListener("click", @resetInfoDisplay)

    ########################################################
    getHICP: => @data.hicp
    getMRR: => @data.mrr
    getGDPG: => @data.gdpg
    getCOTIndex36: => @data.cotIndex36
    getCOTIndex6: => @data.cotIndex6

    ########################################################
    getElement: => @element

    # For cloning/reading by other modules
    getData: => { ...@data }
    getParams: => {
        inflation: { ...@inflationParams }
        interest: { ...@interestParams }
        gdp: { ...@gdpParams }
        cot: { ...@cotParams }
    }
    getInfo: => {
        key: @key
        title: @title
        currencyName: @currencyName
        currencyShort: @currencyShort
        iconHref: @iconHref
    }

    ########################################################
    updateData: (d) =>
        @metaData.hicp = d.hicpMeta ? {}
        @metaData.mrr = d.mrrMeta ? {}
        @metaData.gdpg = d.gdpgMeta ? {}

        @data.hicp = parseFloat(d.hicp)
        @inflationEl.textContent = "#{d.hicp}"
        
        @data.mrr = parseFloat(d.mrr)
        @refinancingEl.textContent = "#{d.mrr}"

        @data.gdpg = parseFloat(d.gdpg)
        @gdpgrowthEl.textContent = "#{d.gdpg}"

        @data.cotIndex36 = parseFloat(d.cotIndex36)
        @cotIndex36El.textContent = "#{Math.round(@data.cotIndex36)}%"
        @cotIndex36El.classList.remove("strong")
        @cotIndex36El.classList.remove("weak")
        if @data.cotIndex36 >= 70 then @cotIndex36El.classList.add("strong")
        if @data.cotIndex36 <= 30 then @cotIndex36El.classList.add("weak")

        @data.cotIndex6 = parseFloat(d.cotIndex6)
        @cotIndex6El.textContent = "#{Math.round(@data.cotIndex6)}%"
        @cotIndex6El.classList.remove("strong")
        @cotIndex6El.classList.remove("weak")
        if @data.cotIndex6 >= 70 then @cotIndex6El.classList.add("strong")
        if @data.cotIndex6 <= 30 then @cotIndex6El.classList.add("weak")

        f() for f in @updateListeners
        return

    ########################################################
    addUpdateListener: (fun) =>
        throw new Error("Not a function!") unless typeof fun == "function" 
        @updateListeners.push(fun)
        return

    removeUpdateListener: (fun) =>
        @updateListeners[i] = null for f,i in @updateListeners when f == fun
        @updateListeners = @updateListeners.filter((el) -> el?)
        return

    ########################################################
    inflationInfoClicked: (evnt) =>
        @element.classList.add("show-info")
        @infoTitleEl.textContent = "Inflation (#{@title})"

        m  = @metaData.hicp
        @infoDescriptionEl.innerHTML = "<p>#{m.dataSet}<br>Quelle: #{m.source}</p><p class='info-date'>@#{m.date}</p>"
        return
    
    refinancingInfoClicked: (evnt) =>
        @element.classList.add("show-info")
        @infoTitleEl.textContent = "Leitzins (#{@title})"
        
        m  = @metaData.mrr
        @infoDescriptionEl.innerHTML = "<p>#{m.dataSet}<br>Quelle: #{m.source}</p><p class='info-date'>@#{(new Date(m.date)).toLocaleDateString()}</p>"
        return

    gdpGrowthInfoClicked: (evnt) =>
        @element.classList.add("show-info")
        @infoTitleEl.textContent = "GDP Wachstum (#{@title})"
        m  = @metaData.gdpg
        @infoDescriptionEl.innerHTML = "<p>#{m.dataSet}<br>Quelle: #{m.source}</p><p class='info-date'>@#{m.date}</p>"
        return

    resetInfoDisplay: =>
        @element.classList.remove("show-info")
        @infoTitleEl.textContent = ""
        @infoDescriptionEl.textContent = ""
        return
    
    ########################################################
    normalizedInflationScore:  ->
        { a, b, c } = @inflationParams
        x = @data.hicp
        n = a + b * x + c * x * x
        if n < 0 then return 0 
        return n

    normalizedInterestScore:  ->
        { a, b } = @interestParams
        x = @data.mrr
        return a + b * x

    normalizedGDPScore:  ->
        { a, b, c } = @gdpParams
        x = @data.gdpg
        n = a + b * x + c * x * x
        if n < 0 then return 0 
        return n

    normalizedCOTScore:  -> 
        f = @cotParams.f
        # c6 = 0.0333 * @data.cotIndex6
        # c32 = 0.0333 * @data.cotIndex36
        c6 = 0.02 * @data.cotIndex6
        c32 = 0.02 * @data.cotIndex36
        return f * (c6 * c32 * c32)

############################################################
createAllAreas = ->
    log "createAllAreas"

    eurozone = new EconomicArea
        "icon-href": "#svg-europe-icon"
        title: "Eurozone"
        key: "eurozone"
        currencyName: "Euro"
        currencyShort: "EUR"
        inflationParams: { a: 1.667, b: 0.667, c: -0.083 }
        interestParams: { a: -2.5, b: 1.0 }
        gdpParams: { a: 2.25, b: 0.75, c: -0.188 }
        cotParams: { f: 1.0 }

    usa = new EconomicArea
        "icon-href": "#svg-usa-icon"
        title: "USA"
        key: "usa"
        currencyName: "US-Dollar"
        currencyShort: "USD"
        inflationParams: { a: 1.667, b: 0.667, c: -0.083 }
        interestParams: { a: -3, b: 1.0 }
        gdpParams: { a: 2.074, b: 0.741, c: -0.148 }
        cotParams: { f: 1.0 }

    japan = new EconomicArea
        "icon-href": "#svg-japan-icon"
        title: "Japan"
        key: "japan"
        currencyName: "Yen"
        currencyShort: "JPY"
        inflationParams: { a: 2.38, b: 0.496, c: -0.099 }
        interestParams: { a: -0.75, b: 1.5 }
        gdpParams: { a: 2.813, b: 0.375, c: -0.188 }
        cotParams: { f: 0.9 }

    uk = new EconomicArea
        "icon-href": "#svg-uk-icon"
        title: "Großbritannien"
        key: "uk"
        currencyName: "Pfund"
        currencyShort: "GBP"
        inflationParams: { a: 1.667, b: 0.667, c: -0.083 }
        interestParams: { a: -2.5, b: 1.0 }
        gdpParams: { a: 2.25, b: 0.75, c: -0.188 }
        cotParams: { f: 1.0 }

    canada = new EconomicArea
        "icon-href": "#svg-canada-icon"
        title: "Kanada"
        key: "canada"
        currencyName: "Canada Dollar"
        currencyShort: "CAD"
        inflationParams: { a: 1.667, b: 0.667, c: -0.083 }
        interestParams: { a: -2.5, b: 1.0 }
        gdpParams: { a: 2.25, b: 0.75, c: -0.188 }
        cotParams: { f: 1.0 }

    australia = new EconomicArea
        "icon-href": "#svg-australia-icon"
        title: "Australien"
        key: "australia"
        currencyName: "Australia Dollar"
        currencyShort: "AUD"
        inflationParams: { a: 0.917, b: 0.833, c: -0.083 }
        interestParams: { a: -3.0, b: 0.9 }
        gdpParams: { a: 1.313, b: 1.125, c: -0.188 }
        cotParams: { f: 1.0 }

    switzerland = new EconomicArea
        "icon-href": "#svg-switzerland-icon"
        title: "Schweiz"
        key: "switzerland"
        currencyName: "Franken"
        currencyShort: "CHF"
        inflationParams: { a: 2.38, b: 0.496, c: -0.099 }
        interestParams: { a: -0.7, b: 1.4 }
        gdpParams: { a: 2.813, b: 0.375, c: -0.188 }
        cotParams: { f: 0.9 }

    newzealand = new EconomicArea
        "icon-href": "#svg-newzealand-icon"
        title: "Neuseeland"
        key: "newzealand"
        currencyName: "New Zealand Dollar"
        currencyShort: "NZD"
        inflationParams: { a: 0.917, b: 0.833, c: -0.083 }
        interestParams: { a: -3.0, b: 0.9 }
        gdpParams: { a: 1.313, b: 1.125, c: -0.188 }
        cotParams: { f: 1.0 }

    allAreas = { eurozone, usa, japan, uk, canada, australia, switzerland, newzealand }
    return

############################################################
# Accessors
export getArea = (key) -> allAreas?[key]

export getAllAreas = -> allAreas

############################################################
# Bulk update from backend data
export updateAllAreas = (data) ->
    log "updateAllAreas"
    for key, areaData of data
        continue if key.startsWith("_") # skip _params
        area = allAreas[key]
        if area? then area.updateData(areaData)
        else log "No Economic Area by key: #{key}"
        
    # Loaded CurrentPair needs the update
    focusPairModule.refreshCurrentPair()
    return