############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("forexscoredisplay")
#endregion

############################################################
import M from "mustache"

############################################################
#region DOM cache - fix for buggy implicit-dom-connect
currencyPairTemplate = document.getElementById("currency-pair-template").innerHTML

############################################################
shortTermCol = document.getElementById("short-term-col")
stList = shortTermCol.querySelector(".score-list")
mediumLongTermCol = document.getElementById("medium-long-term-col")
mlList = mediumLongTermCol.querySelector(".score-list")
longTermCol = document.getElementById("long-term-col")
ltList = longTermCol.querySelector(".score-list")

#endregion

############################################################
import * as eaM from "./economicareasmodule.js"
import * as scoreHelper from "./scorehelper.js"

############################################################
allCurrencyPairs = {}
shownCurrencyPairs = []

############################################################
stPairs = []
mlPairs = []
ltPairs = []

############################################################
stSummary = ""
mlSummary = ""
ltSummary = ""

############################################################
aA = null

############################################################
updatePending = false


############################################################
class CurrencyPair

    constructor: (@baseArea, @quoteArea) ->
        @short = @baseArea.currencyShort + @quoteArea.currencyShort
        @score = "N/A"
        @baseArea.addUpdateListener(@updateScore)
        @quoteArea.addUpdateListener(@updateScore)

        ## Short Term Elements
        stObj = {
            short: @short,
            score: @score,
            colorCode: "#eee"
            rightText: "Keine Daten"
        }
        stVirtualContainer = document.createElement("v")
        html = M.render(currencyPairTemplate, stObj)
        stVirtualContainer.innerHTML = html.trim()

        @stElement = stVirtualContainer.firstChild
        @stScoreDisplay = @stElement.getElementsByClassName("score")[0]
        @stTrendTextDisplay = @stElement.getElementsByClassName("trend-text")[0]


        ## Medium Long Term Elements
        mlObj = {
            short: @short,
            score: @score,
            colorCode: "#eee"
            rightText: "Keine Daten"

        }
        mlVirtualContainer = document.createElement("v")
        html = M.render(currencyPairTemplate, mlObj)
        mlVirtualContainer.innerHTML = html.trim()

        @mlElement = mlVirtualContainer.firstChild
        @mlScoreDisplay = @mlElement.getElementsByClassName("score")[0]
        @mlTrendTextDisplay = @mlElement.getElementsByClassName("trend-text")[0]

        ## Long Term Elements
        ltObj = {
            short: @short,
            score: @score,
            colorCode: "#eee"
            rightText: "Keine Daten"

        }
        ltVirtualContainer = document.createElement("v")
        html = M.render(currencyPairTemplate, ltObj)
        ltVirtualContainer.innerHTML = html.trim()

        @ltElement = ltVirtualContainer.firstChild
        @ltScoreDisplay = @ltElement.getElementsByClassName("score")[0]
        @ltTrendTextDisplay = @ltElement.getElementsByClassName("trend-text")[0]

    updateScore: =>
        # log "updateScore #{@short}"
        try
            nInfScoreBase = @baseArea.normFun.infl()
            nInfScoreQuote = @quoteArea.normFun.infl()
            diff = nInfScoreBase - nInfScoreQuote
            infScore = scoreHelper.inflDiffScore(diff)

            nMrrScoreBase = @baseArea.normFun.mrr()
            nMrrScoreQuote = @quoteArea.normFun.mrr()
            diff = nMrrScoreBase - nMrrScoreQuote
            mrrScore = scoreHelper.mrrDiffScore(diff)

            nGdpScoreBase = @baseArea.normFun.gdpg()
            nGdpScoreQuote = @quoteArea.normFun.gdpg()
            diff = nGdpScoreBase - nGdpScoreQuote
            gdpScore = scoreHelper.gdpgDiffScore(diff)

            nCotScoreBase = @baseArea.normFun.cot()
            nCotScoreQuote = @quoteArea.normFun.cot()
            diff = nCotScoreBase - nCotScoreQuote
            cotScore = scoreHelper.cotDiffScore(diff)

            ## catch the problem if there is something wrong...
            if !isNaN(infScore) 
                log "#{@baseArea.currencyShort}#{@quoteArea.currencyShort}"
                olog {
                    infScore,
                    mrrScore,
                    gdpScore,
                    # nCotScoreBase
                    # nCotScoreQuote
                    # diff
                    cotScore
                }

            ## display Short Term Score
            @stScore = scoreHelper.stScore(infScore, mrrScore, gdpScore, cotScore)
            @stScoreDisplay.textContent = scoreHelper.displayableScore(@stScore)
            trend = scoreHelper.getTrendForScore(@stScore)
            @stElement.style.backgroundColor = trend.color
            @stTrendTextDisplay.textContent = trend.text           
                        
            ## display Medium-Long Term Score
            @mlScore = scoreHelper.mlScore(infScore, mrrScore, gdpScore, cotScore)
            @mlScoreDisplay.textContent = scoreHelper.displayableScore(@mlScore)
            trend = scoreHelper.getTrendForScore(@mlScore)
            @mlElement.style.backgroundColor = trend.color
            @mlTrendTextDisplay.textContent = trend.text

            ## display Long Term Score
            @ltScore = scoreHelper.ltScore(infScore, mrrScore, gdpScore, cotScore)
            @ltScoreDisplay.textContent = scoreHelper.displayableScore(@ltScore)
            trend = scoreHelper.getTrendForScore(@ltScore)
            @ltElement.style.backgroundColor = trend.color
            @ltTrendTextDisplay.textContent = trend.text           

        catch err ## then log err
            log err
            log "Error happened on #{@short}"
        return


############################################################
export initialize = (cfg, allAreas) ->
    log "initialize"
    aA = allAreas || eaM.getAllAreas()

    for lblB,base of aA
        for lblQ,quote of aA when lblB != lblQ
            pair = new CurrencyPair(base, quote)
            allCurrencyPairs[pair.short] = pair

    for label in cfg.shownCurrencyPairLabels
        pair = allCurrencyPairs[label]
        shownCurrencyPairs.push(pair)
        stPairs.push(pair)
        mlPairs.push(pair)
        ltPairs.push(pair)

    return


############################################################
stScoreSort = (el1, el2) ->
    score1 = parseFloat(el1.stScore)
    score2 = parseFloat(el2.stScore)
    return score2 - score1

mlScoreSort = (el1, el2) ->
    score1 = parseFloat(el1.mlScore)
    score2 = parseFloat(el2.mlScore)
    return score2 - score1

ltScoreSort = (el1, el2) ->
    score1 = parseFloat(el1.ltScore)
    score2 = parseFloat(el2.ltScore)
    return score2 - score1

############################################################
stListRender = ->
    log "stListRender"
    stPairs.sort(stScoreSort)
    newSummary = ""
    newSummary += pair.short for pair in stPairs
    
    if newSummary == stSummary then return

    log "we rerender the short-term-list..."
    stSummary = newSummary
    stList.innerHTML = ""
    stList.appendChild(pair.stElement) for pair in stPairs
    return

mlListRender = ->
    log "mlListRender"
    mlPairs.sort(mlScoreSort)
    newSummary = ""
    newSummary += pair.short for pair in mlPairs

    if newSummary == mlSummary then return

    log "we rerender the medium-long-term-list..."
    mlSummary = newSummary
    mlList.innerHTML = ""
    mlList.appendChild(pair.mlElement) for pair in mlPairs
    return

ltListRender = ->
    log "ltListRender"
    ltPairs.sort(ltScoreSort)
    newSummary = ""
    newSummary += pair.short for pair in ltPairs

    if newSummary == ltSummary then return

    log "we rerender the long-term-list..."
    ltSummary = newSummary
    ltList.innerHTML = ""
    ltList.appendChild(pair.ltElement) for pair in ltPairs
    return


############################################################
renderFrame = ->
    log "renderFrame"
    stListRender() 
    mlListRender()
    ltListRender()
    return

############################################################
updateRanking = ->
    log "updateRanking"
    pair.updateScore() for pair in shownCurrencyPairs
    renderFrame()
    return


############################################################
export scheduleRankingUpdate = ->
    return if updatePending
    updatePending = true
    requestAnimationFrame ->
        updatePending = false
        updateRanking()
        return
    return
