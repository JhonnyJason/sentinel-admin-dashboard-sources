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
        @data.infl = parseFloat(d.infl)
        @data.mrr = parseFloat(d.mrr)
        @data.gdpg = parseFloat(d.gdpg)
        @data.cot36 = parseFloat(d.cot36)
        @data.cot6 = parseFloat(d.cot6)
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

