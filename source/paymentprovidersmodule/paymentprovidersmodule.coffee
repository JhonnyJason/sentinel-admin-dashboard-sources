############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("paymentprovidersmodule")
#endregion

############################################################
import * as stripe from "./stripeconnectmodule.js"
import * as cfg from "./configmodule.js"

############################################################
urlStripeDashboard = cfg.urlStripeDashboard

############################################################
export initialize = ->
    log "initialize"
    noAccountForm.addEventListener("submit", onAccountCreate)
    
    stripeOnboardButton.addEventListener("click", onboardButtonClicked)
    stripeUpdateButton.addEventListener("click", updateButtonClicked)
    stripeDashboardButton.addEventListener("click", dashboardButtonClicked)
    return


############################################################
onAccountCreate = (evnt) ->
    log "onAccountCreate"
    evnt.preventDefault()
    email = accountEmailInput.value
    stripeManagement.classList.add("disabled")
    try await stripe.createAccount(email)
    catch err then console.error(err)
    finally stripeManagement.classList.remove("disabled")
    return

onboardButtonClicked = (evnt) ->
    log "onboardButtonClicked"
    stripeManagement.classList.add("disabled")
    try urlOnbarding = await stripe.getOnboardingLink()
    catch err then console.error(err)
    finally stripeManagement.classList.remove("disabled")
    ## when we come back to the admin dashboard - we need to login again anyways...
    if urlOnbarding then window.open(urlOnbarding, "_self")
    else console.error("Retrieval of onboarding link has failed!")
    return

dashboardButtonClicked = (evnt) ->
    log "dashboardButtonClicked"
    window.open(urlStripeDashboard)
    return

updateButtonClicked = (evnt) ->
    log "updateButtonClicked"
    stripeManagement.classList.add("disabled")
    try urlUpdate = await stripe.getUpdateLink()
    catch err then console.error(err)
    finally stripeManagement.classList.remove("disabled")
    ## when we come back to the admin dashboard - we need to login again anyways...
    if urlUpdate then window.open(urlUpdate, "_self")
    else console.error("Retrieval of update link has failed!")
    return


############################################################
export setState = (state) ->
    log "setState #{JSON.stringify(state)}"

    switch state.statelabel
        when "not-connected" then stripeManagement.className = "not-connected"
        when "needs-onboarding" then stripeManagement.className = "needs-onboarding"
        when "verifying" then stripeManagement.className = "verifying"
        when "action-required" then stripeManagement.className = "action-required"
        when "blocked" then stripeManagement.className = "blocked"
        when "operational" then stripeManagement.className = "operational"
        else console.error("Unexpected statelabel: #{statelabel}") 

    if !state.capabilities? then return ## no capabilities -> fast return

    if state.capabilities.canCharge then stripeManagement.classList.add("can-charge") 
    if state.capabilities.canPayout then stripeManagement.classList.add("can-payout")
    if state.capabilities.attention then stripeManagement.classList.add("attention")

    if state.capabilities.disabledStr then stripeDisabledReason.textContent = state.capabilities.disabledStr
    return


