############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("usermanagementmodule")
#endregion

############################################################
import * as sci from "./scimodule.js"
import * as auth from "./authmodule.js"

############################################################
lastActivation = null
noRefreshTimeMS = 10 * 60 * 1000_000 ## 10m

############################################################
import { UserSelect } from "./userselectmodule.js"
import { TableRenderer } from "./tablerendermodule.js"
import { 
    stringCompare, numberCompare, booleanCompare, renderEmail, 
    renderDate, renderCheckbox, renderBool, renderString,
    StringOptionFilter, BoolOptionFilter, DateRangeFilter
} from "./tableutils.js"
import { runBench } from "./benchmarks.js"
import { smallData } from "./testdata.js"

############################################################
## User Object
#  { email, details }
## User Object.details
#  { registrationDate, lastLoginDate, badge, isTester, subscribedUntil,
#    freeAccessUntil, badgeCouponUsed, autoRenew, stripeId }

renderRaw = ((td,d) => (td.textContent = d))
############################################################
tableStructure = [
    # { label: "UserId", key:"userId", render: ((td,d) => (td.textContent = d)), sort: stringCompare }
    { label: "E-Mail", key:"email", render: renderEmail, sort: stringCompare}
    { label: "Badge", key: "details.badge", render: renderString, sort: stringCompare, filter: new StringOptionFilter() }
    { label: "Registrierung", key: "details.registrationDate", render: renderDate, sort: stringCompare, filter: new DateRangeFilter() }
    { label: "Letzter Login", key: "details.lastLoginDate", render: renderDate, sort: stringCompare, filter: new DateRangeFilter() }
    { label: "Tester", key:"details.isTester", render: renderBool, sort: booleanCompare, filter: new BoolOptionFilter() }
    { label: "Gratis Zugang bis", key:"details.freeAccessUntil", render: renderDate, sort: stringCompare, filter: new DateRangeFilter() }
    { label: "Abo gültig bis", key:"details.subscribedUntil", render: renderDate, sort: stringCompare, filter: new DateRangeFilter() }
    { label: "Abo Erneuerung", key:"details.autoRenew", render: renderBool, sort: booleanCompare, filter: new BoolOptionFilter() }
    { label: "Coupon eingelöst", key:"details.badgeCouponUsed", render: renderBool, sort: booleanCompare, filter: new BoolOptionFilter() }
    { label: "Stripe Kunden ID", key:"details.stripeId", render: renderString, sort: stringCompare }
]

############################################################
tableRenderer = null
userList = null
totalUsers = 0

############################################################
originalUserObj = null
selectedUser = null
userChanged = null
deleteLocked = true
deleteLocker = null

############################################################
summaryTotalUsersDisplay = null
summaryActiveUsersDisplay = null
summarySubscribedUsersDisplay = null

############################################################
userSelect = null
defaultSelectedUserEmailString = "Kein Benutzer Gewählt"

selectedUserEmail = document.getElementById("selected-user-email")

############################################################
export initialize = ->
    log "initialize"
    tableRenderer = new TableRenderer(allusers, tableStructure)
    summaryTotalUsersDisplay = userRegisteredCount.querySelector(".stats-value")
    summaryActiveUsersDisplay = usersActiveCount.querySelector(".stats-value")
    summarySubscribedUsersDisplay = usersSubscribedCount.querySelector(".stats-value")

    userEditBadgeInput.addEventListener("change", userBadgeEdited)
    userEditFreeaccessInput.addEventListener("change", userFreeaccessEdited)
    userEditTesterInput.addEventListener("change", userIsTesterEdited)

    deselectUserButton.addEventListener("click", deselectUser)
    userUpdateButton.addEventListener("click",updateUserClicked)
    userDeleteButton.addEventListener("click", deleteUserClicked)

    container = userSelectContainer # userSelectContainer.
    optionsLimit = 70
    userSelect = new UserSelect({ container, optionsLimit })
    userSelect.setOnSelectListener(onUserSelect)
    
    # tableRenderer.updateData(smallData)
    tableRenderer.subscribeRowSelect(onUserSelect)
    # userDetailTemplate.
    # runBench(tableRenderer)
    return

############################################################
export activate = ->
    log "activate"
    # return ## for testing  - do nothing

    if lastActivation? and lastActivation.getTime() < noRefreshTimeMS then return
    try
        payload = await auth.getSignedPayloadString({auth:{ msg:"imlegit!" }})
        userList = await sci.getUserList(payload)

        refreshUI()
    catch err then console.error(err)

    lastActivation = new Date()
    return


refreshUI = ->
    log "refreshUI"
    olog userList
    digestSummaryStats()
    tableRenderer.updateData(userList)
    userSelect.setAllOptions(userList.map((el) -> [el.email, el.details?.name || ""]))
    if selectedUser? then onUserSelect(selectedUser.email)
    return

############################################################
userIsTesterEdited = ->
    log "userIsTesterEdited"
    selectedUser.details.isTester = userEditTesterInput.checked
    refreshUpdateState()
    return

userFreeaccessEdited = ->
    log "userFreeaccessEdited"
    selectedUser.details.freeAccessUntil = userEditFreeaccessInput.value
    refreshUpdateState()
    return

userBadgeEdited = ->
    log "userBadgeEdited"
    selectedUser.details.badge = userEditBadgeInput.value
    refreshUpdateState()
    return

refreshUpdateState = ->
    newObj = JSON.stringify(selectedUser)
    userChanged = newObj != originalUserObj
    
    if userChanged then userActionButtonsContainer.classList.add("unsaved-change")
    else userActionButtonsContainer.classList.remove("unsaved-change")
    return

############################################################
deleteUserClicked = ->
    log "deleteUserClicked"
    if !deleteLocked then return deleteSelectedUser()

    deleteLocked = false
    userDeleteButton.classList.add("unlocked")
    deleteLocker = setTimeout(lockDeleteButton, 10000)
    return

lockDeleteButton = ->
    log "lockDeleteButton"
    deleteLocked = true
    deleteLocker = null
    userDeleteButton.classList.remove("unlocked")
    return

deleteSelectedUser = ->
    log "deleteSelectedUser"
    try
        deadUserId = selectedUser.userId
        deselectUser()

        payload = await auth.getSignedPayloadString({auth:{}, args: deadUserId})
        await sci.deleteUser(payload)
        newList = []
        for userObj in userList when userObj.userId != deadUserId
            newList.push(userObj)
        userList = newList
        refreshUI()
    catch err then console.error(err)
    return

############################################################
updateUserClicked = ->
    log "updateUserClicked"
    try
        args = { userId: selectedUser.userId, details: selectedUser.details }
        payload = await auth.getSignedPayloadString({auth:{}, args})
        await sci.updateUser(payload)

        refreshUI()
    catch err then console.error(err)
    return

############################################################
deselectUser = ->
    log "deselectUser"
    usermanagementframe.classList.remove("user-selected")
    userDetailsContainer.innerHTML = ""
    selectedUserEmail.textContent = ""
    userSelect.resetSearch()
    originalUserObj = null
    selectedUser = null
    userChanged =  false

    if deleteLocker then clearTimeout(deleteLocker)
    deleteLocked = true
    deleteLocker = null
    userDeleteButton.classList.remove("unlocked")
    return

############################################################
onUserSelect = (user) ->
    log "onUserSelect"
    if typeof user == "string" # select function selected by email
        for userObj in userList when userObj.email == user
            displayUser(userObj)
            return
        console.error("Selected user not found (by email)!")
        return
    
    if typeof user == "object" # select function selected userObject directly
        displayUser(user)
        return
    
    console.error("Unexpected type of onUserSelect user! (#{typeof user})")
    return

############################################################
displayUser = (userObj) ->
    log "displayUser"
    olog userObj
    originalUserObj = JSON.stringify(userObj)
    selectedUser = userObj
    userChanged = false


    # userDetailsContainer.innerHTML = ""
    usermanagementframe.classList.add("user-selected")
    userActionButtonsContainer.classList.remove("unsaved-change")

    selectedUserEmail.textContent = userObj.email

    ## fill uneditable details container
    fragment = document.createDocumentFragment()

    userDetails = extractRelevantDetails(userObj)
    for { label, value } in userDetails
        detailEl = userDetailTemplate.content.cloneNode(true);
        detailEl.querySelector(".user-detail-label").textContent = label;
        detailEl.querySelector(".user-detail-value").textContent = value;
        fragment.appendChild(detailEl)

    userDetailsContainer.replaceChildren(fragment)
    
    ## fill editable details container
    userEditBadgeInput.value = userObj.details.badge
    userEditTesterInput.checked = userObj.details.isTester == true
    userEditFreeaccessInput.value = userObj.details.freeAccessUntil    
    return


############################################################
digestSummaryStats = ->
    log "digestSummaryStats"
    activeUsers = 0
    payingUsers = 0
    
    dateToday = (new Date()).toISOString().slice(0, 10)
    
    date = new Date()
    date.setDate(date.getDate() - 14)
    dateActiveLimit = date.toISOString().slice(0, 10)
    olog { dateToday, dateActiveLimit }

    for userObj in userList
        activeUsers += (userObj.details.lastLoginDate > dateActiveLimit)
        payingUsers += (userObj.details.subscribedUntil > dateToday) 

    totalUsers = userList.length


    if summaryTotalUsersDisplay?
        summaryTotalUsersDisplay.textContent = ""+totalUsers
    
    if summaryActiveUsersDisplay?
        summaryActiveUsersDisplay.textContent = ""+activeUsers

    if summarySubscribedUsersDisplay?
        summarySubscribedUsersDisplay.textContent = ""+payingUsers

    return


extractRelevantDetails = (userObj) ->
    userDetails = []
    
    for label,value of userObj when label != "details"
        userDetails.push({ label, value })
    
    if typeof userObj.details == "object"
        for label,value of userObj.details
            if label == "badge" then continue
            if label == "freeAccessUntil" then continue
            if label == "isTester" then continue
            userDetails.push({label, value})

    return userDetails