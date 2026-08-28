############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("paymentprovidersmodule")
#endregion

############################################################
import * as stripe from "./stripeconnectmodule.js"

############################################################
export initialize = ->
    log "initialize"
    noAccountForm.addEventListener("submit", onAccountCreate)

    #Implement or Remove :-)
    return


############################################################
onAccountCreate = (evnt) ->
    log "onAccountCreate"
    evnt.preventDefault()
    email = accountEmailInput.value
    noAccountForm.classList.add("disabled")
    try await stripe.createAccount(email)
    catch err then console.error(err)
    finally noAccountForm.classList.remove("disabled")
    return

############################################################
export setState = (state) ->
    log "setState"
    olog state
    if state.id == "connected" then stripeManagement.className = "connected"
    if state.id == "onboarding" then stripeManagement.className = "connecting"
    if state.id == "not-connected" then stripeManagement.className = "not-connected"

    alert("set state!")
    return


