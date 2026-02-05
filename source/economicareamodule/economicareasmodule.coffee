############################################################
#region debugmakrodatahandle
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("economicareasmodule")
#endregion

############################################################
import * as focusPairModule from "./focuspairmodule.js"
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
        inflParams: { a: 1.667, b: 0.667, c: -0.083 }
        mrrParams: { a: -2.5, b: 1.0 }
        gdpgParams: { a: 2.25, b: 0.75, c: -0.188 }
        cotParams: { f: 1.0, e: 1.6 }

    a.usa = new EconomicArea
        iconHref: "#svg-usa-icon"
        title: "USA"
        key: "usa"
        currencyName: "US-Dollar"
        currencyShort: "USD"
        inflParams: { a: 1.667, b: 0.667, c: -0.083 }
        mrrParams: { a: -3, b: 1.0 }
        gdpgParams: { a: 2.074, b: 0.741, c: -0.148 }
        cotParams: { f: 1.0, e: 1.6 }

    a.japan = new EconomicArea
        iconHref: "#svg-japan-icon"
        title: "Japan"
        key: "japan"
        currencyName: "Yen"
        currencyShort: "JPY"
        inflParams: { a: 2.38, b: 0.496, c: -0.099 }
        mrrParams: { a: -0.75, b: 1.5 }
        gdpgParams: { a: 2.813, b: 0.375, c: -0.188 }
        cotParams: { f: 0.9, e: 1.6 }

    a.uk = new EconomicArea
        iconHref: "#svg-uk-icon"
        title: "Großbritannien"
        key: "uk"
        currencyName: "Pfund"
        currencyShort: "GBP"
        inflParams: { a: 1.667, b: 0.667, c: -0.083 }
        mrrParams: { a: -2.5, b: 1.0 }
        gdpgParams: { a: 2.25, b: 0.75, c: -0.188 }
        cotParams: { f: 1.0, e: 1.6 }

    a.canada = new EconomicArea
        iconHref: "#svg-canada-icon"
        title: "Kanada"
        key: "canada"
        currencyName: "Canada Dollar"
        currencyShort: "CAD"
        inflParams: { a: 1.667, b: 0.667, c: -0.083 }
        mrrParams: { a: -2.5, b: 1.0 }
        gdpgParams: { a: 2.25, b: 0.75, c: -0.188 }
        cotParams: { f: 1.0, e: 1.6 }

    a.australia = new EconomicArea
        iconHref: "#svg-australia-icon"
        title: "Australien"
        key: "australia"
        currencyName: "Australia Dollar"
        currencyShort: "AUD"
        inflParams: { a: 0.917, b: 0.833, c: -0.083 }
        mrrParams: { a: -3.0, b: 0.9 }
        gdpgParams: { a: 1.313, b: 1.125, c: -0.188 }
        cotParams: { f: 1.0, e: 1.6 }

    a.switzerland = new EconomicArea
        iconHref: "#svg-switzerland-icon"
        title: "Schweiz"
        key: "switzerland"
        currencyName: "Franken"
        currencyShort: "CHF"
        inflParams: { a: 2.38, b: 0.496, c: -0.099 }
        mrrParams: { a: -0.7, b: 1.4 }
        gdpgParams: { a: 2.813, b: 0.375, c: -0.188 }
        cotParams: { f: 0.9, e: 1.6 }

    a.newzealand = new EconomicArea
        iconHref: "#svg-newzealand-icon"
        title: "Neuseeland"
        key: "newzealand"
        currencyName: "New Zealand Dollar"
        currencyShort: "NZD"
        inflParams: { a: 0.917, b: 0.833, c: -0.083 }
        mrrParams: { a: -3.0, b: 0.9 }
        gdpgParams: { a: 1.313, b: 1.125, c: -0.188 }
        cotParams: { f: 1.0, e: 1.6 }

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