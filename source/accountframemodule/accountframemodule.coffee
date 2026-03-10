############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("accountframemodule")
#endregion

############################################################
import * as auth from "./authmodule.js"

############################################################
export initialize = (cfg) ->
    log "initialize"
    migrationButton.addEventListener("click", migrationFlow)
    deletionButton.addEventListener("click", deletionFlow)
    return


############################################################
retrieveNameAndPin = ->
    log "retrieveNameAndPin"
    migrationRetrievalForm.style.display = "block"
    
    return new Promise((resolve) ->
        migrationRetrievalButton.onclick = ->
            migrationRetrievalForm.style.display = "none"
            
            resolve({ 
                name: migrationEmailInput.value, 
                pin: migrationPinInput.value 
            })
            
            migrationEmailInput.value = ""
            migrationPinInput.value = ""
            return
        return
    )

############################################################
migrationFlow = (evnt) ->
    log "migrationFlow"
    evnt.preventDefault()
    ## Retrieve name + PIN
    { name, pin }  = await retrieveNameAndPin()
    log name
    log pin

    auth.migrateCredentials(name, pin)
    return false

deletionFlow = (evnt) ->
    log "deletionFlow"
    evnt.preventDefault()
    auth.deleteCredentials()
    return false
