############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("scimodule")
#endregion

############################################################
import {
    createValidator, getErrorMessage, 
    STRINGHEX64, STRINGHEX32, STRINGEMAIL, NONEMPTYSTRING, 
    NUMBERORNOTHING, NUMBER
} from "thingy-schema-validate"

############################################################
import { urlAccessManager, urlDatahub } from "./configmodule.js"
# import { getAuthCode } from "./authmodule.js"
import { defaultSymbols } from "./defaultsymbols.js"

############################################################
#region Requet URLs
urlGetData = urlDatahub+"/getEODHLCData"
urlGetSymbolOptions = urlDatahub+"/getSymbolOptions"

urlRegisterAdmin = urlAccessManager+"/registerAdmin"
urlGenerateAdminOTC = urlAccessManager+"/generateAdminOTC"
urlRemoveAdminAccess = urlAccessManager+"/removeAdminAccess"

urlGetUserList = urlAccessManager+"/getUserList"
urlGetUser = urlAccessManager+"/getUser"

#endregion

############################################################
#region Schema Validators
validateGetDataArgs = createValidator({
    authCode: STRINGHEX32,
    dataKey: NONEMPTYSTRING,
    yearsBack: NUMBERORNOTHING
})

validateGetSymbolOptionsArgs = createValidator({
    authCode: STRINGHEX32,
    query: NONEMPTYSTRING,
    limit: NUMBER
})
#endregion

############################################################
waitMS = (ms) -> await new Promise(((rslv) -> setTimeout((() -> rslv()), ms)))

############################################################
request  = (url, args) ->
    log "request"
    if typeof args == "string" then body = args
    else body = JSON.stringify(args)

    options = {
        method: 'POST',  mode: 'cors', body,
        headers: {'Content-Type': 'application/json'}
    }

    try response = await fetch(url, options)
    catch err then throw new Error("Network Error: "+err.message)

    ## return void on 204
    if response.status == 204 then return
    ## return response body on 200 - should always be JSON
    if response.status == 200
        try return await response.json()
        catch err then throw new Error("ResultParsing Error: "+err.message)

        ## Any Error will not be "OK" - and might have an error Messge for us...
    try errorMessage = await response.text()
    catch err then throw new Error("ErrorParsing Error: "+err.message)

    throw new Error(errorMessage)
    return

############################################################
export registerAdmin = (payload) ->
    log "registerAdmin"
    await request(urlRegisterAdmin, payload)
    return

############################################################
export generateAdminOTC = (payload) ->
    log "generateAdminOTC"
    resp = await request(urlGenerateAdminOTC, payload)
    return resp.url

############################################################
export removeAdminAccess = (payload) ->
    log "removeAdminAccess"
    await request(urlRemoveAdminAccess, payload)
    return

############################################################
export getUserList = (payload) ->
    log "getUserList"
    userList =  await request(urlGetUserList, payload)
    return userList

export getUser = (payload) ->
    log "getUser"
    userObj = await request(urlGetUser, payload)
    return userObj

############################################################
#region Maybe deprecated code?

############################################################
export getEodData = (dataKey, yearsBack) ->
    log "getEodData"    
    ## TODO reimplement for Admin

    # authCode = getAuthCode()
    # args = { authCode, dataKey, yearsBack }
    # err = validateGetDataArgs(args)
    # # if err then log getErrorMessage(err)
    # if err then throw new Error("Invalid getData args!")
    # return await request(urlGetData, args)
    # resultSchema: {
    #     meta: {
    #         startDate: NONEMPTYSTRING,
    #         endDate: NONEMPTYSTRING,
    #         interval: "1d",
    #         historyComplete: BOOLEAN
    #     },
    #     data: ARRAY
    # }

############################################################
export getSymbolOptions = (query, limit) ->
    log "getSymbolOptions"   
    ## TODO reimplement for Admin
    # authCode = getAuthCode()
    # args = { authCode, query, limit }
    # err = validateGetSymbolOptionsArgs(args)
    # # if err then log getErrorMessage(err)
    # if err then throw new Error("Invalid getData args!")
    # # return await request(urlGetSymbolOptions, args)
    
    # ## Sample return
    # return await new Promise (rslv) ->
    #     setTimeout((() -> rslv(defaultSymbols)), 500)

#endregion
