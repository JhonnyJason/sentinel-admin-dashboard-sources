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
    renderDate, renderCheckbox
} from "./tableutils.js"


############################################################
tableStructure = [
    { label: "E-Mail", key:"email", render: renderEmail, sort: stringCompare}
    # { label: "UserId", key:"userId", render: ((td,d) => (td.textContent = d)), sort: stringCompare }
    { label: "Letzte Aktivität", key: "lastInteraction", render: renderDate, sort: numberCompare }
    # { label: "(depr) Abonnement gültig bis", key: "subscribedUntil", render: renderDate, sort: numberCompare }
    { label: "(depr) Tester", key: "isTester", render: renderCheckbox, sort: booleanCompare }
    { label: "(new) Tester", key:"details.isTester", render: renderCheckbox, sort: booleanCompare }
    # { label: "(new) Abbonement gültig bis", key: "details.subscribedUntil", render: renderDate, sort: numberCompare }
    { label: "(new) Badge", key: "details.registrationBadge", render: ((td,d) => (td.textContent = d)) , sort: numberCompare }
]

############################################################
tableRenderer = null
userList = null
totalUsers = 0

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

    container = userSelectContainer # userSelectContainer.
    optionsLimit = 70
    userSelect = new UserSelect({ container, optionsLimit })
    userSelect.setOnSelectListener(onUserSelect)
    
    # userDetailTemplate.

    return

############################################################
export activate = ->
    log "activate"
    if lastActivation? and lastActivation.getTime() < noRefreshTimeMS then return
    try
        payload = await auth.getSignedPayloadString({auth:{ msg:"imlegit!" }})
        userList = await sci.getUserList(payload)

        # olog userList
        digestSummaryStats()
        tableRenderer.render(userList)
    
        userSelect.setAllOptions(userList.map((el) -> [el.email, el.details?.name || ""]))

    catch err then console.error(err)

    lastActivation = new Date()
    return

############################################################
onUserSelect = (email) ->
    log "onUserSelect"
    for userObj in userList when userObj.email == email
        displayUser(userObj)
        return

    console.error("Selected user not found (by email)!")
    return

############################################################
displayUser = (userObj) ->
    log "displayUser"
    olog userObj
    userDetailsContainer.innerHTML = ""

    selectedUserEmail.textContent = userObj.email
    fragment = document.createDocumentFragment()

    userDetails = extractRelevantDetails(userObj)
    for { label, value } in userDetails
        detailEl = userDetailTemplate.content.cloneNode(true);
        detailEl.querySelector(".user-detail-label").textContent = label;
        detailEl.querySelector(".user-detail-value").textContent = value;
        fragment.appendChild(detailEl)

    userDetailsContainer.replaceChildren(fragment)
    return


############################################################
digestSummaryStats = ->
    log "maryStats"
    totalUsers = userList.length
    
    if summaryTotalUsersDisplay?
        summaryTotalUsersDisplay.textContent = ""+totalUsers
    
    ## TODO add the other stats
    return


extractRelevantDetails = (userObj) ->
    userDetails = []
    
    for label,value of userObj when label != "details"
        userDetails.push({ label, value })
    
    if typeof userObj.details == "object"
        for label,value of userObj.details
            userDetails.push({label, value})

    return userDetails