############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("speciallinkframemodule")
#endregion

############################################################
import * as sci from "./scimodule.js"
import * as auth from "./authmodule.js"

############################################################
lastActivation = null
noRefreshTimeMS = 10 * 60 * 1000_000 ## 10m

############################################################
linkList = []
nameToLinkObj = Object.create(null)

############################################################
maybeDelete = null

############################################################
urlBase = "https://sentinel.ewag-handelssysteme.de"


############################################################
export initialize = ->
    log "initialize"
    addLinkButton.addEventListener("click", addLinkButtonClicked)
    linkNameInput.addEventListener("keydown", linkNameKeyDowned)
    return

############################################################
linkNameKeyDowned = (evnt) ->
    if evnt.key == 'Enter' then addLinkButtonClicked(evnt)
    return

############################################################
addLinkButtonClicked = (evnt) ->
    log "addLinkButtonClicked"
    name = linkNameInput.value.replaceAll(" ", "")
    linkNameInput.value = ""
    if name == "" then return linkNameInput.focus() 
    # return unless !nameToLinkObj[name]?

    try
        payload = await auth.getSignedPayloadString({auth:{}, args: name})
        await sci.createSpecialLink(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return

############################################################
deleteLink = (name, el) ->
    log "deleteLink "+name
    if name != maybeDelete
        maybeDelete = name
        btns = linkentryList.getElementsByClassName("linkentry-delete-button")
        btn.classList.remove("really") for btn in btns
        el.classList.add("really")
        return

    try
        payload = await auth.getSignedPayloadString({auth:{}, args: name})
        await sci.deleteSpecialLink(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return

############################################################
updateDescription = (name, description) ->
    log "updateDescription (#{name}, #{description})"
    try
        payload = await auth.getSignedPayloadString({auth:{}, args: {name, description}})
        await sci.setSpecialLinkDescription(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return

updatePercentageOff = (name, percentOff) ->
    log "updatePercentageOff (#{name}, #{percentOff})"
    ## ensure percentOff is a number
    percentOff = parseInt(percentOff)
    if percentOff > 100 then percentOff = 100
    if percentOff < 0 then percentOff = 0
    if isNaN(percentOff) then percentOff = undefined

    try
        payload = await auth.getSignedPayloadString({auth:{}, args: {name, percentOff}})
        await sci.setCouponPercentOff(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return

updateFromDate = (name, validFrom) ->
    log "updateFromDate (#{name}, #{validFrom})"
    try
        payload = await auth.getSignedPayloadString({auth:{}, args: {name, validFrom}})
        await sci.setCouponValidFrom(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return

updateToDate = (name, validTo) ->
    log "updateToDate (#{name}, #{validTo})"
    try
        payload = await auth.getSignedPayloadString({auth:{}, args: {name, validTo}})
        await sci.setCouponValidTo(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return


updateFreeAccessDays = (name, freeAccessDays) ->
    log "updateFreeAccessDays (#{name}, #{freeAccessDays})"
    try
        freeAccessDays = parseInt(freeAccessDays)
        if isNaN(freeAccessDays) then args = { name }
        else args = { name, freeAccessDays }
        payload = await auth.getSignedPayloadString({auth:{}, args})
        await sci.setFreeAccessDays(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return

updateFreeAccessUntil = (name, freeAccessUntil) ->
    log "updateFreeAccessUntil (#{name}, #{freeAccessUntil})"
    try
        payload = await auth.getSignedPayloadString({auth:{}, args: {name, freeAccessUntil}})
        await sci.setFreeAccessUntil(payload)
    catch err then console.error(err)
    
    updateLinkList()
    return

############################################################
updateLinkList = ->
    try
        payload = await auth.getSignedPayloadString({auth:{ msg:"imlegit!" }})
        linkList = await sci.getAllSpecialLinks(payload)
        renderLinkList()
    catch err then console.error(err)
    return

############################################################
renderLinkList = ->
    log "renderLinkList"
    maybeDelete = null
    fragment = document.createDocumentFragment()
    for linkObj in linkList
        if !linkObj? then linkObj = { name: "null", description: "" }

        `let name = linkObj.name`
        linkEl = linkentryTemplate.content.cloneNode(true)
        linkEl.querySelector(".linkentry-description").addEventListener("change", (() -> updateDescription(name, this.value)))

        linkEl.querySelector(".linkentry-title").textContent = urlBase+"/"+name
        linkEl.querySelector(".linkentry-description").value = linkObj.description
        linkEl.querySelector(".stat-registered-count").textContent = linkObj.registeredCount
        linkEl.querySelector(".stat-total-count").textContent = linkObj.totalCount
        linkEl.querySelector(".stat-bot-count").textContent = linkObj.botCount
        linkEl.querySelector(".stat-click-count").textContent = linkObj.clickCount

        couponIdEl = linkEl.querySelector(".linkentry-coupon-id")
        percentageOffInput = linkEl.querySelector(".linkentry-percentage-off-input")
        validFromDateInput = linkEl.querySelector(".linkentry-valid-from-date")
        validToDateInput = linkEl.querySelector(".linkentry-valid-to-date")
        freeAccessDaysInput = linkEl.querySelector(".linkentry-free-access-days-input")
        freeAccessUntilInput = linkEl.querySelector(".linkentry-free-access-until-input")

        if linkObj.coupon
            couponIdEl.textContent = linkObj.coupon.id || "(Noch kein Coupon erstellt...)"
            percentageOffInput.value = linkObj.coupon.percentOff || ""
            validFromDateInput.value = linkObj.coupon.validFrom || ""
            validToDateInput.value = linkObj.coupon.validTo || ""
        else
            couponIdEl.textContent = "(Noch kein Coupon erstellt...)"

        freeAccessDaysInput.value = linkObj.freeAccessDays || ""
        freeAccessUntilInput.value = linkObj.freeAccessUntil || ""

        percentageOffInput.addEventListener("change", (() ->  updatePercentageOff(name, this.value)))
        validFromDateInput.addEventListener("change", (() ->  updateFromDate(name, this.value)))
        validToDateInput.addEventListener("change", (() ->  updateToDate(name, this.value)))
        freeAccessDaysInput.addEventListener("change", (() ->  updateFreeAccessDays(name, this.value)))
        freeAccessUntilInput.addEventListener("change", (() ->  updateFreeAccessUntil(name, this.value)))

        linkEl.querySelector(".linkentry-delete-button").addEventListener("click", (() -> deleteLink(name, this)))

        fragment.appendChild(linkEl)


    linkentryList.replaceChildren(fragment)
    return


############################################################
export activate = ->
    log "activate"
    if lastActivation? and lastActivation.getTime() < noRefreshTimeMS then return

    updateLinkList()
    lastActivation = new Date()
    return
