############################################################
export appVersion = "v0.0.3"
export heartbeatMS = 6_000 # ~12s

############################################################
# export noNetwork = true
# export noKeys = true

############################################################
export urlAccessManager = "https://sentinel-access-manager.dotv.ee"
export urlWebsocketBackend = "https://sentinel-backend.dotv.ee"
export urlDatahub = "https://sentinel-datahub.dotv.ee"

# export urlWebsocketBackend = "wss://sentinel-backend.dotv.ee/"

# local testing
# export urlAccessManager = "https://localhost:6999"
# export urlWebsocketBackend = "http://localhost:3333"
# export urlWebsocketBackend = "wss://localhost:6999/"
# export urlWebsocketBackend = "https://localhost:6999/"

############################################################
export pwdSalt = "holderradio!...<3)()0981salty"
export admSalt =  "eo9pbfr567890pl,+-.,ysw35tltwadh"
export qrScanNoFilter = true

############################################################
# Neutral defaults (UI only - mathematically balanced starting point)
export neutralAreaParams =
    infl: { a: 1.667, b: 0.667, c: -0.083 }
    mrr: { a: -2.5, b: 1.0 }
    gdpg: { a: 2.25, b: 0.75, c: -0.188 }
    cot: { f: 1.0 }

export neutralGlobalParams =
    diffCurves:
        infl: { b: 1.4, d: 0.12 }
        mrr: { b: 0, d: 0.04 }
        gdpg: { b: 1.4, d: 0.12 }
        cot: { b: 0, d: 0.01 }
    weights: { i: 6, l: 9, g: 3, c: 13 }

############################################################
# Mock area data for development (until backend provides real data)
export mockAreaData =
    eurozone:
        key: "eurozone"
        title: "Eurozone"
        currencyShort: "EUR"
        iconHref: "#svg-europe-icon"
        infl: 2.4
        mrr: 4.25
        gdpg: 0.5
        cot6: 42
        cot36: 55
        params:
            infl: { a: 1.667, b: 0.667, c: -0.083 }
            mrr: { a: -2.5, b: 1.0 }
            gdpg: { a: 2.25, b: 0.75, c: -0.188 }
            cot: { f: 1.0 }
    usa:
        key: "usa"
        title: "USA"
        currencyShort: "USD"
        iconHref: "#svg-usa-icon"
        infl: 3.1
        mrr: 5.25
        gdpg: 2.5
        cot6: 68
        cot36: 72
        params:
            infl: { a: 1.667, b: 0.667, c: -0.083 }
            mrr: { a: -3, b: 1.0 }
            gdpg: { a: 2.074, b: 0.741, c: -0.148 }
            cot: { f: 1.0 }
    japan:
        key: "japan"
        title: "Japan"
        currencyShort: "JPY"
        iconHref: "#svg-japan-icon"
        infl: 2.8
        mrr: 0.25
        gdpg: 1.2
        cot6: 28
        cot36: 35
        params:
            infl: { a: 2.38, b: 0.496, c: -0.099 }
            mrr: { a: -0.75, b: 1.5 }
            gdpg: { a: 2.813, b: 0.375, c: -0.188 }
            cot: { f: 0.9 }
    uk:
        key: "uk"
        title: "Großbritannien"
        currencyShort: "GBP"
        iconHref: "#svg-uk-icon"
        infl: 4.0
        mrr: 5.0
        gdpg: 0.1
        cot6: 52
        cot36: 48
        params:
            infl: { a: 1.667, b: 0.667, c: -0.083 }
            mrr: { a: -2.5, b: 1.0 }
            gdpg: { a: 2.25, b: 0.75, c: -0.188 }
            cot: { f: 1.0 }
    canada:
        key: "canada"
        title: "Kanada"
        currencyShort: "CAD"
        iconHref: "#svg-canada-icon"
        infl: 2.9
        mrr: 4.75
        gdpg: 1.1
        cot6: 45
        cot36: 50
        params:
            infl: { a: 1.667, b: 0.667, c: -0.083 }
            mrr: { a: -2.5, b: 1.0 }
            gdpg: { a: 2.25, b: 0.75, c: -0.188 }
            cot: { f: 1.0 }
    australia:
        key: "australia"
        title: "Australien"
        currencyShort: "AUD"
        iconHref: "#svg-australia-icon"
        infl: 3.4
        mrr: 4.35
        gdpg: 1.5
        cot6: 58
        cot36: 62
        params:
            infl: { a: 0.917, b: 0.833, c: -0.083 }
            mrr: { a: -3.0, b: 0.9 }
            gdpg: { a: 1.313, b: 1.125, c: -0.188 }
            cot: { f: 1.0 }
    switzerland:
        key: "switzerland"
        title: "Schweiz"
        currencyShort: "CHF"
        iconHref: "#svg-switzerland-icon"
        infl: 1.3
        mrr: 1.5
        gdpg: 0.8
        cot6: 38
        cot36: 42
        params:
            infl: { a: 2.38, b: 0.496, c: -0.099 }
            mrr: { a: -0.7, b: 1.4 }
            gdpg: { a: 2.813, b: 0.375, c: -0.188 }
            cot: { f: 0.9 }
    newzealand:
        key: "newzealand"
        title: "Neuseeland"
        currencyShort: "NZD"
        iconHref: "#svg-newzealand-icon"
        infl: 4.7
        mrr: 5.5
        gdpg: 0.6
        cot6: 32
        cot36: 40
        params:
            infl: { a: 0.917, b: 0.833, c: -0.083 }
            mrr: { a: -3.0, b: 0.9 }
            gdpg: { a: 1.313, b: 1.125, c: -0.188 }
            cot: { f: 1.0 }

# Currency short to area key mapping
export currencyToArea =
    EUR: "eurozone"
    USD: "usa"
    JPY: "japan"
    GBP: "uk"
    CAD: "canada"
    AUD: "australia"
    CHF: "switzerland"
    NZD: "newzealand"

############################################################
export shownCurrencyPairLabels = [
    "USDJPY",
    "USDCAD",
    "USDCHF",

    "EURUSD",
    "NZDUSD",
    "AUDUSD",
    "GBPUSD",

    ## additional crosspairs
    "EURGBP",
    "EURCHF",
    "EURJPY",
    "EURCAD",
    "EURAUD",
    "EURNZD",

    "GBPCHF",
    "GBPJPY",
    "GBPCAD",
    "GBPAUD",
    "GBPNZD",
    
    "CHFJPY",
    "CADJPY",
    "AUDJPY",
    "NZDJPY",

    "CADCHF",
    "AUDCHF",
    "NZDCHF",

    "AUDCAD",
    "NZDCAD",

    "AUDNZD"
]
