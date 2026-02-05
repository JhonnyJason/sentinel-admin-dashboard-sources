############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("MakroDataHandle")
#endregion

############################################################
# relevant structure files:
#     - components/makro-el.pug
#     - components/makro-data-row.pug 

############################################################
export class MakroDataHandle
    constructor: (@containerEl) ->
        @iconUseEl = @containerEl.querySelector(".icon-use")
        @titleEl = @containerEl.querySelector(".area-title")
        @currencyEl = @containerEl.querySelector(".area-currency")
        
        # Inflation Row
        label = @containerEl.querySelector(".infl-data .data-label")
        label.textContent = "Inflation:" # one-time set the lable
        @inflInput = @containerEl.querySelector(".infl-data .data-input")

        # Leitzins Row
        label = @containerEl.querySelector(".mrr-data .data-label")
        label.textContent = "Leitzins:" # one-time set the lable
        @mrrInput = @containerEl.querySelector(".mrr-data .data-input")

        # GDP Wachstum Row
        label = @containerEl.querySelector(".gdpg-data .data-label")
        label.textContent = "GDP Wachstum:" # one-time set the lable
        @gdpgInput = @containerEl.querySelector(".gdpg-data .data-input")

        # COT Index 6m Row
        label = @containerEl.querySelector(".cot6-data .data-label")
        label.textContent = "COT Index (6m):" # one-time set the lable
        @cot6Input = @containerEl.querySelector(".cot6-data .data-input")
        @cot6Input.setAttribute("step", "1")

        # COT Index 36m Row
        label = @containerEl.querySelector(".cot36-data .data-label")
        label.textContent = "COT Index (36m):" # one-time set the lable
        @cot36Input = @containerEl.querySelector(".cot36-data .data-input")
        @cot36Input.setAttribute("step", "1")

        # Reset Button
        @resetButton = @containerEl.querySelector(".reset-button")
        @resetListeners = []

        I = this
        ## attach Event Listeners
        @inflInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "infl")))
        @mrrInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "mrr")))
        @gdpgInput.addEventListener("input", ((evnt) -> onInput(evnt, I, "gdpg")))
        @cot6Input.addEventListener("input", ((evnt) -> onInput(evnt, I, "cot6")))
        @cot36Input.addEventListener("input", ((evnt) -> onInput(evnt, I, "cot36")))

        @resetButton.addEventListener("click", ((evnt) -> resetClicked(evnt, I)))        
        
    setArea: (area) =>
        @area = area
        info = area.getInfo()
        @iconUseEl.setAttribute("href", info.iconHref)
        @titleEl.textContent = info.title
        @currencyEl.textContent = info.currencyShort

        # wire up updates
        area.addUpdateListener(@refreshUI)
        @refreshUI()
        return

    unsubscribe: =>
        return unless @area?
        @area.removeUpdateListener(@refreshUI)
        #actually nothing else to be done here :-)
        return

    refreshUI: =>
        d = @area.data # direct access is faster than calling functions
        @inflInput.value = d.infl
        @mrrInput.value = d.mrr
        @gdpgInput.value = d.gdpg
        @cot6Input.value = d.cot6
        @cot36Input.value = d.cot36

        @resetButton.classList.toggle("visible", @area.isModified)
        return
    
    addResetListener: (fun) => 
        if typeof fun != "function" then throw new Error("ResetListener is not a function!") 
        @resetListeners.push(fun)
        return

    removeResetListener: (fun) =>
        @resetListeners[i] = null for f,i in @resetListeners when f == fun
        @resetListeners = @resetListeners.filter((el) -> el?)
        return

############################################################
#region Utility Functions which we donot want to expose in the class
# Here I is the specific instance

############################################################
onInput = (evnt, I, dKey) ->
    val = parseFloat(evnt.target.value)
    return if isNaN(val)

    d = I.area.data # actually we donot need a copy here^^...
    d[dKey] = val
    I.area.updateData(d)
    return

############################################################
resetClicked = (evnt, I) ->
    f() for f in I.resetListeners
    return

#endregion
