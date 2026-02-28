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
        inflParams: { a: 1.111, b: 0.444, c: -0.056 }
        mrrParams: { f: -2.2, n: 2.0, c: 5.5, s: 1.2 }
        gdpgParams: { a: 1.5, b: 0.5, c: -0.125 }
        cotParams: { n: 50, e: 1.6 }

    a.usa = new EconomicArea
        iconHref: "#svg-usa-icon"
        title: "USA"
        key: "usa"
        currencyName: "US-Dollar"
        currencyShort: "USD"
        inflParams: { a: 1.111, b: 0.444, c: -0.056 }
        mrrParams: { f: -1.7, n: 2.7, c: 6.0, s: 1.2 }
        gdpgParams: { a: 1.383, b: 0.494, c: -0.099 }
        cotParams: { n: 50, e: 1.6 }

    a.japan = new EconomicArea
        iconHref: "#svg-japan-icon"
        title: "Japan"
        key: "japan"
        currencyName: "Yen"
        currencyShort: "JPY"
        inflParams: { a: 1.587, b: 0.331, c: -0.066 }
        mrrParams: { f: -1, n: 0.5, c: 3.5, s: 1.2 }
        gdpgParams: { a: 1.875, b: 0.25, c: -0.125 }
        cotParams: { n: 50, e: 1.6 }

    a.uk = new EconomicArea
        iconHref: "#svg-uk-icon"
        title: "Großbritannien"
        key: "uk"
        currencyName: "Pfund"
        currencyShort: "GBP"
        inflParams: { a: 1.111, b: 0.444, c: -0.056 }
        mrrParams: { f: -2, n: 2.5, c: 6.0, s: 1.2 }
        gdpgParams: { a: 1.5, b: 0.5, c: -0.125 }
        cotParams: { n: 50, e: 1.6 }

    a.canada = new EconomicArea
        iconHref: "#svg-canada-icon"
        title: "Kanada"
        key: "canada"
        currencyName: "Canada Dollar"
        currencyShort: "CAD"
        inflParams: { a: 1.111, b: 0.444, c: -0.056 }
        mrrParams: { f: -2, n: 2.5, c: 6.0, s: 1.2 }
        gdpgParams: { a: 1.5, b: 0.5, c: -0.125 }
        cotParams: { n: 50, e: 1.6 }

    a.australia = new EconomicArea
        iconHref: "#svg-australia-icon"
        title: "Australien"
        key: "australia"
        currencyName: "Australia Dollar"
        currencyShort: "AUD"
        inflParams: { a: 0.611, b: 0.556, c: -0.056 }
        mrrParams: { f: -2, n: 2.9, c: 7.0, s: 1.2 }
        gdpgParams: { a: 0.875, b: 0.75, c: -0.125 }
        cotParams: { n: 50, e: 1.6 }

    a.switzerland = new EconomicArea
        iconHref: "#svg-switzerland-icon"
        title: "Schweiz"
        key: "switzerland"
        currencyName: "Franken"
        currencyShort: "CHF"
        inflParams: { a: 1.587, b: 0.331, c: -0.066 }
        mrrParams: { f: -1, n: 0.8, c: 4.0, s: 1.2 }
        gdpgParams: { a: 1.875, b: 0.25, c: -0.125 }
        cotParams: { n: 50, e: 1.6 }

    a.newzealand = new EconomicArea
        iconHref: "#svg-newzealand-icon"
        title: "Neuseeland"
        key: "newzealand"
        currencyName: "New Zealand Dollar"
        currencyShort: "NZD"
        inflParams: { a: 0.611, b: 0.556, c: -0.056 }
        mrrParams: { f: -2, n: 2.9, c: 7.0, s: 1.2 }
        gdpgParams: { a: 0.875, b: 0.75, c: -0.125 }
        cotParams: { n: 50, e: 1.6 }

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