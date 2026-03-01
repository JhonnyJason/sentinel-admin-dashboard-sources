############################################################
#region debugmakrodatahandle
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("economicareasmodule")
#endregion

############################################################
import * as focusPairModule from "./focuspairmodule.js"
import { areaParams } from "./defaultsnapshot.js"
import { EconomicArea } from "./EconomicArea.js"

############################################################
allAreas = {}

############################################################
export initialize = ->
    log "initialize"
    a = allAreas

    a.eurozone = new EconomicArea
        iconHref: "#svg-europe-icon"
        title: "Eurozone"
        key: "eurozone"
        currencyName: "Euro"
        currencyShort: "EUR"
        inflParams: areaParams["eurozone"].infl
        mrrParams: areaParams["eurozone"].mrr
        gdpgParams: areaParams["eurozone"].gdpg
        cotParams: areaParams["eurozone"].cot

    a.usa = new EconomicArea
        iconHref: "#svg-usa-icon"
        title: "USA"
        key: "usa"
        currencyName: "US-Dollar"
        currencyShort: "USD"
        inflParams: areaParams["usa"].infl
        mrrParams: areaParams["usa"].mrr
        gdpgParams: areaParams["usa"].gdpg
        cotParams: areaParams["usa"].cot

    a.japan = new EconomicArea
        iconHref: "#svg-japan-icon"
        title: "Japan"
        key: "japan"
        currencyName: "Yen"
        currencyShort: "JPY"
        inflParams: areaParams["japan"].infl
        mrrParams: areaParams["japan"].mrr
        gdpgParams: areaParams["japan"].gdpg
        cotParams: areaParams["japan"].cot

    a.uk = new EconomicArea
        iconHref: "#svg-uk-icon"
        title: "Großbritannien"
        key: "uk"
        currencyName: "Pfund"
        currencyShort: "GBP"
        inflParams: areaParams["uk"].infl
        mrrParams: areaParams["uk"].mrr
        gdpgParams: areaParams["uk"].gdpg
        cotParams: areaParams["uk"].cot

    a.canada = new EconomicArea
        iconHref: "#svg-canada-icon"
        title: "Kanada"
        key: "canada"
        currencyName: "Canada Dollar"
        currencyShort: "CAD"
        inflParams: areaParams["canada"].infl
        mrrParams: areaParams["canada"].mrr
        gdpgParams: areaParams["canada"].gdpg
        cotParams: areaParams["canada"].cot

    a.australia = new EconomicArea
        iconHref: "#svg-australia-icon"
        title: "Australien"
        key: "australia"
        currencyName: "Australia Dollar"
        currencyShort: "AUD"
        inflParams: areaParams["australia"].infl
        mrrParams: areaParams["australia"].mrr
        gdpgParams: areaParams["australia"].gdpg
        cotParams: areaParams["australia"].cot

    a.switzerland = new EconomicArea
        iconHref: "#svg-switzerland-icon"
        title: "Schweiz"
        key: "switzerland"
        currencyName: "Franken"
        currencyShort: "CHF"
        inflParams: areaParams["switzerland"].infl
        mrrParams: areaParams["switzerland"].mrr
        gdpgParams: areaParams["switzerland"].gdpg
        cotParams: areaParams["switzerland"].cot

    a.newzealand = new EconomicArea
        iconHref: "#svg-newzealand-icon"
        title: "Neuseeland"
        key: "newzealand"
        currencyName: "New Zealand Dollar"
        currencyShort: "NZD"
        inflParams: areaParams["newzealand"].infl
        mrrParams: areaParams["newzealand"].mrr
        gdpgParams: areaParams["newzealand"].gdpg
        cotParams: areaParams["newzealand"].cot

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