############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("QuadNormHandle")
#endregion

############################################################
# relevant structure files:
#     - components/quadnorm-el.pug

############################################################
export class QuadNormHandle
    constructor: (@containerEl,  @dKey) ->
        @onChangeListeners = []
        ## TODO cache relevant DOM Elements
        ## TODO wire up input listeners on weight-inputs
        
    setArea: (area) =>
        @area = area

        # wire up updates
        area.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    unsubscribe: =>
        return unless @area?
        @area.removeUpdateListener(@refreshUI)
        return

    refreshUI: =>
        p = @area.params[@dKey]
        inVal = @area.data[@dKey]
        outVal = @area.normFun[@dKey]()
        ## TODO fill inputs with param values
        return
    
    addOnChangeListener: (fun) => 
        if typeof fun != "function" then throw new Error("OnChangeListener is not a function!") 
        @onChangeListeners.push(fun)
        return

    removeOnChangeListener: (fun) =>
        @onChangeListeners[i] = null for f,i in @onChangeListeners when f == fun
        @onChangeListeners = @onChangeListeners.filter((el) -> el?)
        return

############################################################
#region Utility Functions which we donot want to expose in the class
# Here I is the specific instance

############################################################
onInput = (evnt, I, wKey) ->
    val = parseFloat(evnt.target.value)
    return if isNaN(val)

    @area.params[I.dKey][wKey] = val
    f() for f in onChangeListeners
    return

#endregion
