############################################################
import { MakroDataHandle } from "./MakroDataHandle.js"
import { ResultBoxHandle } from "./ResultBoxHandle.js"
import { QuadNormHandle } from "./QuadNormHandle.js"
import { LinNormHandle } from "./LinNormHandle.js"
import { CotNormHandle } from "./CotNormHandle.js"
import { DiffHandle } from "./DiffHandle.js"

############################################################
allHandles = {}

############################################################
export initialize = ->
    a = allHandles
    a.baseAreaHandle = new MakroDataHandle(baseArea)
    a.quoteAreaHandle = new MakroDataHandle(quoteArea)
    a.resultBoxHandle = new ResultBoxHandle(resultsArea) # resultsArea.

    a.baseInflNormHandle = new QuadNormHandle(inflNormBase, "infl") # inflNormBase.
    a.quoteInflNormHandle = new QuadNormHandle(inflNormQuote, "infl") # inflNormQuote.
    a.inflDiffHandle = new DiffHandle(inflDiff, "infl") # inflDiff.

    a.baseMrrNormHandle = new LinNormHandle(mrrNormBase, "mrr") # mrrNormBase.
    a.quoteMrrNormHandle = new LinNormHandle(mrrNormQuote, "mrr") # mrrNormQuote.
    a.mrrDiffHandle = new DiffHandle(mrrDiff, "mrr") # mrrDiff.

    a.baseGdpgNormHandle = new QuadNormHandle(gdpgNormBase, "gdpg") # gdpgNormBase.
    a.quoteGdpgNormHandle = new QuadNormHandle(gdpgNormQuote, "gdpg") # gdpgNormQuote.
    a.gdpgDiffHandle = new DiffHandle(gdpgDiff, "gdpg") # gdpgDiff.

    a.baseCotNormHandle = new CotNormHandle(cotNormBase, "cot") # cotNormBase.
    a.quoteCotNormHandle = new CotNormHandle(cotNormQuote, "cot") # cotNormQuote.
    a.cotDiffHandle = new DiffHandle(cotDiff, "cot") # cotDiff.
    return

############################################################
export getHandle = (key) -> allHandles[key]
export getAllHandles = -> allHandles