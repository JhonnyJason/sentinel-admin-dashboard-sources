import {smallData, mediumData, largeData, veryLargeData } from "./testdata.js"

############################################################
waitMS = (ms) -> new Promise((rslv) -> setTimeout(rslv, ms))

############################################################
results = Object.create(null)

############################################################
trials = Object.create(null)

waitTimeMS = 2000
defaultRenderFun = null
############################################################
export runBench = (renderer) ->
    # return
    console.log("runBench")

    addTrial("renderNew / veryLarge data (1)", () -> renderer.render(veryLargeData))
    addTrial("renderOld / veryLarge data (1)", () -> renderer.renderOld(veryLargeData))
    addTrial("renderNew / veryLarge data (2)", () -> renderer.render(veryLargeData))
    addTrial("renderOld / veryLarge data (2)", () -> renderer.renderOld(veryLargeData))

    addTrial("renderNew / large data (1)", () -> renderer.render(largeData))
    addTrial("renderOld / large data (1)", () -> renderer.renderOld(largeData))
    addTrial("renderNew / large data (2)", () -> renderer.render(largeData))
    addTrial("renderOld / large data (2)", () -> renderer.renderOld(largeData))

    addTrial("renderNew / medium data (1)", () -> renderer.render(mediumData))
    addTrial("renderOld / medium data (1)", () -> renderer.renderOld(mediumData))
    addTrial("renderNew / medium data (2)", () -> renderer.render(mediumData))
    addTrial("renderOld / medium data (2)", () -> renderer.renderOld(mediumData))


    # addTrial("render0 / small data", () -> renderer.render0(smallData))
    # addTrial("render1 / small data", () -> renderer.render1(smallData))
    # addTrial("render2 / small data", () -> renderer.render2(smallData))
    # addTrial("render3 / small data", () -> renderer.render3(smallData))
    # addTrial("render4 / small data", () -> renderer.render4(smallData))

    # addTrial("render0 / medium data", () -> renderer.render0(mediumData))
    # addTrial("render1 / medium data", () -> renderer.render1(mediumData))
    # addTrial("render2 / medium data", () -> renderer.render2(mediumData))
    # addTrial("render3 / medium data", () -> renderer.render3(mediumData))
    # addTrial("render4 / medium data", () -> renderer.render4(mediumData))

    # addTrial("render0 / large data", () -> renderer.render0(largeData))
    # addTrial("render1 / large data", () -> renderer.render1(largeData))
    # addTrial("render2 / large data", () -> renderer.render2(largeData))
    # addTrial("render3 / large data", () -> renderer.render3(largeData))
    # addTrial("render4 / large data", () -> renderer.render4(largeData))

    defaultRenderFun = () -> renderer.render(largeData)
    
    runBenchTrials(18)
    return

############################################################
addTrial = (name, renderFun) ->
    trials[name] = renderFun
    results[name] = { 
        # name, 
        runs: 0, avgRenderingMS: 0, avgFirstFrameMS: 0, 
        avgSecondFrameMS: 0, avgThirdFrameMS: 0,
        sums: {
            renderingMS: 0, firstFrameMS: 0, 
            secondFrameMS: 0, thirdFrameMS: 0
        }
    }
    return


############################################################
runBenchTrials = (count) ->
    names = Object.keys(trials)
    await waitMS(waitTimeMS)    

    ## add warmup round
    names.unshift("noname")
    count++
    names.unshift("noname")
    count++

    ## It seems this type of warmup is not effective at all...
    # # warmup round...
    # for name in names
    #     fun = trials[name]
    #     benchRendering(fun, null)
    #     await waitMS(waitTimeMS)
    # console.log("finshed warmup round... let's go!")
    
    warmupFinished = false
    ## full bench run
    while count--
        for name in names
            fun = trials[name]
            result = results[name]
            benchRendering(fun, result)
            await waitMS(waitTimeMS)

        if warmupFinished then console.log("finshed round... #{count} rounds left")
        else console.log("finshed warmup round... let's go!")
        warmupFinished = true

    delete results[name].sums for name in names when results[name]?

    console.log(JSON.stringify(results, null, 4))
    return

############################################################
benchRendering = (renderFun, result) ->
    if !renderFun? then renderFun = defaultRenderFun

    start = performance.now()
    renderFun()
    renderingMS = performance.now() - start
    await new Promise(requestAnimationFrame)

    firstFrameMS = performance.now() - start
    await new Promise(requestAnimationFrame)

    secondFrameMS = performance.now() - start
    await new Promise(requestAnimationFrame)

    thirdFrameMS = performance.now() - start
    
    return unless result? ## warmup run does not pass result obj
    result.runs++
    sums = result.sums

    sums.renderingMS += renderingMS
    sums.firstFrameMS += firstFrameMS
    sums.secondFrameMS += secondFrameMS
    sums.thirdFrameMS += thirdFrameMS

    result.avgRenderingMS = sums.renderingMS / result.runs
    result.avgFirstFrameMS = sums.firstFrameMS / result.runs
    result.avgSecondFrameMS = sums.secondFrameMS / result.runs
    result.avgThirdFrameMS = sums.thirdFrameMS / result.runs
    return
