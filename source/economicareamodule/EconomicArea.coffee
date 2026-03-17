############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("EconomicArea")
#endregion

############################################################
import { inflNorm, mrrNorm, gdpgNorm, cotNorm } from "./areanorm.js"

############################################################
export class EconomicArea
    constructor:  (o) ->
        @key = o.key
        @title = o.title
        @currencyName = o.currencyName
        @currencyShort = o.currencyShort
        @iconHref = o.iconHref

        @updateListeners = []
        
        @modified = {
            infl: false
            mrr: false
            gdpg: false
            cot36: false
            cot6: false
        }

        @data = {
            infl: NaN
            mrr: NaN
            gdpg: NaN
            cot36: NaN
            cot6: NaN
        }

        @params = {
            infl: o.inflParams
            mrr: o.mrrParams
            gdpg: o.gdpgParams
            cot: o.cotParams
        }

        @normFun = {
            infl: => inflNorm(@data, @params)
            mrr: => mrrNorm(@data, @params)
            gdpg: => gdpgNorm(@data, @params)
            cot: => cotNorm(@data, @params)
        }

    ########################################################
    isModified: => @modified.infl || @modified.mrr || @modified.gdpg || @modified.cot6 || @modified.cot36

    ########################################################
    getInfl: => @data.infl
    getMrr: => @data.mrr
    getGdpg: => @data.gdpg
    getCot36: => @data.cot36
    getCot6: => @data.cot6

    ########################################################
    # For cloning/reading by other modules
    copyData: => { ...@data }

    copyParams: => {
        infl: { ...@params.infl }
        mrr: { ...@params.mrr }
        gdpg: { ...@params.gdpg }
        cot: { ...@params.cot }
    }

    getInfo: => {
        key: @key
        title: @title
        currencyName: @currencyName
        currencyShort: @currencyShort
        iconHref: @iconHref
    }

    clone: =>
        initOptions = {
            key: @key
            title: @title
            currencyName: @currencyName
            currencyShort: @currencyShort
            iconHref: @iconHref
            inflParams: {...@params.infl}
            mrrParams: {...@params.mrr}
            gdpgParams: {...@params.gdpg}
            cotParams: {...@params.cot}
        }
        newArea = new EconomicArea(initOptions)
        data = @copyData()
        newArea.updateData(data)
        return newArea

    ########################################################
    # Bulk-set normalization params and trigger listeners (for version control apply)
    setParams: (p) =>
        @params.infl = { ...p.infl }
        @params.mrr = { ...p.mrr }
        @params.gdpg = { ...p.gdpg }
        @params.cot = { ...p.cot }
        f() for f in @updateListeners
        return

    ########################################################
    setModifiedAgainst: (other) =>
        @modified.infl = other.data.infl != @data.infl
        @modified.mrr = other.data.mrr != @data.mrr
        @modified.gdpg = other.data.gdpg != @data.gdpg
        @modified.cot36 = other.data.cot36 != @data.cot36
        @modified.cot6 = other.data.cot6 != @data.cot6
        return

    ########################################################
    updateData: (d) =>
        log "updateData"
        infl = d.infl || d.hicp
        if isNaN(infl) then log "@#{@currencyShort} inf is NaN!"
        if !infl then infl = 0
        @data.infl = 0.01 * Math.round(parseFloat(infl) * 100)
        
        if isNaN(d.mrr) then log "@#{@currencyShort} mrr is NaN!"
        @data.mrr = 0.01 * Math.round(parseFloat(d.mrr) * 100)
        
        if isNaN(d.gdpg) then log "@#{@currencyShort} gdpg is NaN!"
        @data.gdpg = 0.01 * Math.round(parseFloat(d.gdpg) * 100)

        cot36 = d.cot36 || d.cotIndex36
        if isNaN(cot36) then log "@#{@currencyShort} cot36 is NaN!"
        if !cot36 then cot36 = 0
        @data.cot36 = Math.round(parseFloat(cot36))
        
        cot6 = d.cot6 || d.cotIndex6
        if isNaN(cot6) then log "@#{@currencyShort} cot6 is NaN!"
        if !cot6 then cot6 = 0
        @data.cot6 = Math.round(parseFloat(cot6))

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

