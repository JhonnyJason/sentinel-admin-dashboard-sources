############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("uistatemodule")
#endregion

############################################################
#region imported UI modules
import * as content from "./contentmodule.js"
import * as sideNav from "./sidenavmodule.js"
import * as authFrame from "./authframemodule.js"

#endregion

############################################################
applyBaseState = {}
applyModifier = {}

############################################################
currentBase = null
currentModifier = null
currentContext = null

############################################################
#region Base State Application Functions

applyBaseState["account"] = ->
    content.setAccountState()
    sideNav.setAccountState()
    authFrame.hide()
    header.className = "logged-in"
    return

applyBaseState["paymentproviders"] = ->
    content.setPaymentprovidersState()
    sideNav.setPaymentprovidersState()
    authFrame.hide()
    header.className = "logged-in"
    return

applyBaseState["forexscore"] = ->
    content.setForexscoreState()
    sideNav.setForexscoreState()
    authFrame.hide()
    header.className = "logged-in"
    return

applyBaseState["usermanagement"] = ->
    content.setUsermanagementState()
    sideNav.setUsermanagementState()
    authFrame.hide()
    header.className = "logged-in"
    return

applyBaseState["speciallink"] = ->
    content.setSpeciallinkState()
    sideNav.setSpeciallinkState()
    authFrame.hide()
    header.className = "logged-in"
    return


applyBaseState["auth"] = ->
    content.hide()
    sideNav.hide()
    authFrame.setState()
    header.className = ""
    return

#endregion

############################################################
resetAllModifications = ->
    return

############################################################
#region Modifier State Application Functions

applyModifier["none"] = (ctx) ->
    resetAllModifications()
    return

#endregion


############################################################
#region exported general Application Functions
export applyUIState = (base, modifier, ctx) ->
    log "applyUIState"
    currentContext = ctx

    if base? then applyUIStateBase(base)
    if modifier? then applyUIStateModifier(modifier)
    return

############################################################
export applyUIStateBase = (base) ->
    log "applyUIBaseState #{base}"
    applyBaseFunction = applyBaseState[base]

    if typeof applyBaseFunction != "function" then throw new Error("on applyUIStateBase: base '#{base}' apply function did not exist!")

    currentBase = base
    applyBaseFunction(currentContext)
    return

############################################################
export applyUIStateModifier = (modifier) ->
    log "applyUIStateModifier #{modifier}"
    applyModifierFunction = applyModifier[modifier]

    if typeof applyUIStateModifier != "function" then throw new Error("on applyUIStateModifier: modifier '#{modifier}' apply function did not exist!")

    currentModifier = modifier
    applyModifierFunction(currentContext)
    return

############################################################
export getModifier = -> currentModifier
export getBase = -> currentBase
export getContext = -> currentContext

#endregion