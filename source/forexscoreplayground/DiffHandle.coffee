############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("DiffHandle")
#endregion

############################################################
# relevant structure files:
#     - components/cubdiff-el.pug

############################################################
export class DiffHandle
    constructor: (@containerEl,  @dKey) ->
        ## TODO cache relevant DOM Elements
        ## TODO wire up input listeners on weight-inputs
        
    setModel: (model) =>
        @model = model

        # wire up updates
        model.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    refreshUI: =>
        p = @model.getDiffParams(@dKey)
        { baseScore, quoteScore } = @model.getDiffInputs(@dKey)
        ## TODO fill inputs 
        return
    

############################################################
#region Utility Functions which we donot want to expose in the class
# Here I is the specific instance

############################################################
onInput = (evnt, I, wKey) ->
    val = parseFloat(evnt.target.value)
    return if isNaN(val)

    @model.updateDiffParam(@dKey, wKey, val)
    return

#endregion
