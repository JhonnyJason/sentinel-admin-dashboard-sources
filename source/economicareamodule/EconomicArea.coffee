############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("EconomicArea")
#endregion

############################################################
import * as nm from "./normmath.js"

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
            infl: @inflScore
            mrr: @mrrScore
            gdpg: @gdpgScore
            cot: @cotScore
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

    ########################################################
    inflScore:  =>
        { a, b, c } = @params.infl
        x = @data.infl
        n = a + b * x + c * x * x
        if n < 0 then return 0
        if n > 2 then return 2
        return n

    mrrScore:  =>
        { f, n, c, s } = @params.mrr
        x = @data.mrr
        if x < n 
            b = 1.0 / (n - f)
            a = (-b) * f
        else
            b = 1.0 / (c - n)
            a = 1 - (b * n)

        n = a + b * x

        res = nm.coeffsToPeakSteepness(@params.infl.a, @params.infl.b, @params.infl.c)
        inflPeak = res.peak
        inflZeroHigh = res.zeroHigh

        inflPivot = inflPeak * s
        inflCutoff = inflZeroHigh * s
        K = (inflZeroHigh - inflPeak) / s
        
        p1 = @data.mrr - @data.infl
        p2 = inflPivot - @data.infl
        p3 = @data.infl / inflCutoff
        if p3 > 1 then p3 = 1
        if p3 < 0  then p3 = 0

        n -= (p1 * p2 * p3) / K

        if n < 0 then return 0
        if n > 2 then return 2
        return n

    gdpgScore:  =>
        { a, b, c } = @params.gdpg
        x = @data.gdpg
        n = a + b * x + c * x * x
        if n < 0 then return 0
        if n > 2 then return 2
        return n

    cotScore:  =>
        n = @params.cot.n || 50
        e = @params.cot.e || 1

        ## = 2^((cot - n) / 50)      ∈ [0.5, 2.0]
        c6 = Math.pow(2, (0.02 * (@data.cot6 - n)))
        c36 = Math.pow(2, (0.02 * (@data.cot36 - n)))
        ## = (c6 × c36^e)^(1/(1+e))    ∈ [0.5, 2.0]
        c = Math.pow((c6 * Math.pow(c36, e)), (1.0 / (1 + e)))
        ## map [0.5, 2.0] -> [0, 2.0]
        n = (c - 0.5) * (2.0 / 1.5)

        olog { c6, c36, c, n }

        ## probably unnecessary but will do no harm :-)
        if n < 0 then return 0
        if n > 2 then return 2
        return n
