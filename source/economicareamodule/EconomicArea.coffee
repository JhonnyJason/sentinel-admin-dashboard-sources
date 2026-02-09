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
        mrr: { ...@params.infl }
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
        return n

    mrrScore:  =>
        { a, b } = @params.mrr
        x = @data.mrr
        return a + b * x

    gdpgScore:  =>
        { a, b, c } = @params.gdpg
        x = @data.gdpg
        n = a + b * x + c * x * x
        if n < 0 then return 0 
        return n

    cotScore:  =>
        f = @params.cot.f
        e = @params.cot.e || 1

        # c6 = 0.0333 * @data.cot6
        # c32 = 0.0333 * @data.cot36
        c6 = 0.02 * @data.cot6
        c32 = 0.02 * @data.cot36
        return f * (c6 * Math.pow(c32, e))
