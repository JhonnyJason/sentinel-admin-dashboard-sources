############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("tableutils")
#endregion

############################################################
idCnt = 0
uniqueId = (id) -> id+(idCnt++)

############################################################
appendNew = (tag, rootEl) ->
    newEl = document.createElement(tag)
    rootEl.appendChild(newEl)
    return newEl

############################################################
export accessDeepProp = (obj, key) ->
    tkns = key.split(".")
    prop = obj
    try prop = prop[tk] for tk in tkns
    catch err then console.error("Could not accessDeepProp #{key} in obj: #{JSON.stringify(obj, null, 4)}")
    return prop

############################################################
#region functions for sorting
export stringCompare = (str1, str2, f) ->
    if str1? and !str2? then return -1
    if str2? and !str1? then return 1

    if str1 > str2 then return (-1) * f 
    if str2 > str1 then return f 
    return 0

export numberCompare = (a, b, f) -> 
    if a? and !b? then return -1
    if b? and !a? then return 1
    return (b - a) * f

export booleanCompare = (a, b, f) -> 
    if a? and !b? then return -1
    if b? and !a? then return 1   
    return (+ b - a) * f


#endregion

############################################################
#region cell rendering functions
export renderEmail = (td, d, ctx) ->
    try
        aTag = document.createElement("a")
        aTag.setAttribute("href", "mailto:#{d}")
        aTag.textContent = d

        td.appendChild(aTag)
    catch err
        console.error(err)
        console.error("Data and indices "+JSON.stringify({ d, colIdx: ctx.colIdx, rowIdx: ctx.rowIdx }, null, 4))
    return

export renderCheckbox  = (td, d, ctx) ->
    try
        inputTag = document.createElement("input")
        inputTag.setAttribute("type", "checkbox")
        inputTag.checked = (d == true)
        
        td.appendChild(inputTag)
    catch err
        console.error(err)
        console.error("Data and indices "+JSON.stringify({ d, colIdx: ctx.colIdx, rowIdx: ctx.rowIdx }, null, 4))
    return

export renderDate = (td, d, ctx) ->
    try
        if !d then return # any falsy date like 0 or null etc. nothing to do here... 
        dateObj = new Date(d)
        dateStr = dateObj.toISOString().slice(0, 10)
        [Y,M,D] = dateStr.split("-")
        td.textContent = [D,M,Y].join(".")
    catch err
        console.error(err)
        console.error("Data and indices "+JSON.stringify({ d, colIdx: ctx.colIdx, rowIdx: ctx.rowIdx }, null, 4))
    return

export renderBool = (td, d, ctx) ->
    try
        if !d? then return
        if d then td.textContent = "JA"
        else td.textContent = "NEIN"
    catch err
        console.error(err)
        console.error("Data and indices "+JSON.stringify({ d, colIdx: ctx.colIdx, rowIdx: ctx.rowIdx }, null, 4))
    return

export renderString = (td, d, ctx) ->
    try
        if !d then return # any falsy date like 0 or null etc. nothing to do here... 
        td.textContent = d
    catch err
        console.error(err)
        console.error("Data and indices "+JSON.stringify({ d, colIdx: ctx.colIdx, rowIdx: ctx.rowIdx }, null, 4))
    return

export renderNumber = (td, d, ctx) ->
    try
        if !d? then return # any falsy date like 0 or null etc. nothing to do here... 
        td.textContent = ""+d
    catch err
        console.error(err)
        console.error("Data and indices "+JSON.stringify({ d, colIdx: ctx.colIdx, rowIdx: ctx.rowIdx }, null, 4))
    return

#endregion

############################################################
#region Filter Classes
export class FilterBase 
    constructor: ->
        @onChangeListeners = []
        return
    
    getElement: => @rootEl
    
    notifyChange: =>
        fun() for fun in @onChangeListeners
        return

    addOnChangeListener: (lstnr) => 
        @onChangeListeners.push(lstnr)
        return

    removeOnChangeListener: (toRemove) =>
        newListeners = []
        for fun in @onChangeListeners when fun != toRemove
            newListeners.push(fun)
        @onChangeListeners = newListeners
        return
    
    requiresRecords: => false ## overwrite if a filer needs all records

    passes: => true ## to be overwritten


############################################################
export class StringOptionFilter extends FilterBase
    constructor: ->
        super()
        # @rootEl = document.createElement("div") ## probably donot need this here...
        @rootEl = document.createElement("select")
        @allOption = "* Alle *"
        @rootEl.addEventListener("change", @selectionChanged)
        return

    selectionChanged: (evnt) =>
        log "selectionChanged"
        @chosenOption = @rootEl.value
        
        if @chosenOption == @allOption then @rootEl.classList.remove("active")
        else @rootEl.classList.add("active")

        @notifyChange()
        return

    passes: (str) => 
        if @chosenOption == @allOption then return true
        return @chosenOption == str

    requiresRecords: => true

    processRecords: (records) =>
        optionSet = new Set()
        optionSet.add(recrd) for recrd in records

        if !optionSet.has(@chosenOption) then @chosenOption = @allOption
        
        newElements = []

        optionEl = document.createElement("option")
        optionEl.value = @allOption
        optionEl.textContent = @allOption
        if @chosenOption == @allOption then optionEl.selected = true
        newElements.push(optionEl)
        
        options = Array.from(optionSet)
        for opt in options
            optionEl = document.createElement("option")
            optionEl.value = opt
            optionEl.textContent = opt
            if @chosenOption == opt then optionEl.selected = true
            newElements.push(optionEl)

        @rootEl.replaceChildren(...newElements)
        return

############################################################
export class BoolOptionFilter extends FilterBase
    constructor: ->
        super()
        @rootEl = document.createElement("div")

        ## Only True Block
        onlyTrueBlock = appendNew("div", @rootEl)
        @onlyTrueInput = appendNew("input", onlyTrueBlock)

        onlyTrueId = uniqueId("only-true-input")
        @onlyTrueInput.id = onlyTrueId
        # @onlyTrueInput.setAttribute("type", "checkbox")
        @onlyTrueInput.type = "checkbox"

        onlyTrueLabel = appendNew("label", onlyTrueBlock)
        onlyTrueLabel.htmlFor = onlyTrueId
        onlyTrueLabel.textContent = "JA"
        
        @onlyTrue = false
        @onlyTrueInput.checked = false
        @onlyTrueInput.addEventListener("change", @onlyTrueInputChanged)

        ## Only False Block
        onlyFalseBlock = appendNew("div", @rootEl)
        @onlyFalseInput = appendNew("input", onlyFalseBlock)

        onlyFalseId = uniqueId("only-false-input")
        @onlyFalseInput.id = onlyFalseId
        # @onlyFalseInput.setAttribute("type", "checkbox")
        @onlyFalseInput.type = "checkbox"

        onlyFalseLabel = appendNew("label", onlyFalseBlock)
        onlyFalseLabel.htmlFor = onlyFalseId
        onlyFalseLabel.textContent = "NEIN"

        @onlyFalse = false
        @onlyFalseInput.checked = false
        @onlyFalseInput.addEventListener("change", @onlyFalseInputChanged)
        return

    onlyFalseInputChanged: (evnt) =>
        log "onlyFalseInputChanged"
        @onlyFalse = @onlyFalseInput.checked
        log "onlyFalse: "+@onlyFalse
        log "typeof onlyFalse: "+(typeof @onlyFalse)
        if @onlyFalse
            @onlyTrue = false
            @onlyTrueInput.checked = false
        
        if !@onlyFalse and !@onlyTrue then @rootEl.classList.remove("active")
        else @rootEl.classList.add("active")

        @notifyChange()
        return

    onlyTrueInputChanged: (evnt) =>
        log "onlyTrueInputChanged"
        @onlyTrue = @onlyTrueInput.checked
        log "onlyTrue: "+@onlyTrue
        log "typeof onlyTrue: "+(typeof @onlyTrue)
        if @onlyTrue 
            @onlyFalse = false
            @onlyFalseInput.checked = false
        
        if !@onlyFalse and !@onlyTrue then @rootEl.classList.remove("active")
        else @rootEl.classList.add("active")

        @notifyChange()
        return

    passes: (bool) => (!@onlyTrue and !@onlyFalse) || (@onlyTrue and (bool == true)) || (@onlyFalse and (bool == false))

############################################################
export class DateRangeFilter extends FilterBase
    constructor: ->
        super()
        @rootEl = document.createElement("div")

        ## From Date Block
        fromDateBlock = appendNew("div", @rootEl)
        
        fromDateId = uniqueId("from-date-input")
        fromDateLabel = appendNew("label", fromDateBlock)
        fromDateLabel.htmlFor = fromDateId
        fromDateLabel.textContent = "Ab:"
        
        @fromDateInput = appendNew("input", fromDateBlock)
        @fromDateInput.type = "date"
        @fromDateInput.id = fromDateId
        @fromDateInput.addEventListener("change", @fromDateChanged)
        
        # To Date Block
        toDateBlock = appendNew("div", @rootEl)
    
        toDateId = uniqueId("to-date-input")
        toDateLabel = appendNew("label", toDateBlock)
        toDateLabel.htmlFor = toDateId
        toDateLabel.textContent = "Bis:"

        @toDateInput = appendNew("input", toDateBlock)
        @toDateInput.type = "date"
        @toDateInput.id = toDateId
        @toDateInput.addEventListener("change", @toDateChanged)
        return
    
    fromDateChanged: (evnt) =>
        log "fromDateChanged"
        @lowerEnd = @fromDateInput.value
        log "lowerEnd: "+@lowerEnd
        log "typeof lowerEnd: "+(typeof @lowerEnd)

        if @lowerEnd or @upperEnd then @rootEl.classList.add("active")
        else @rootEl.classList.remove("active")

        @notifyChange()
        return

    toDateChanged: (evnt) =>
        log "toDateChanged"
        @upperEnd = @toDateInput.value
        log "upperEnd: "+@upperEnd
        log "typeof upperEnd: "+(typeof @upperEnd)

        if @lowerEnd or @upperEnd then @rootEl.classList.add("active")
        else @rootEl.classList.remove("active")

        @notifyChange()
        return


    passes: (date) =>
        if @lowerEnd and date < @lowerEnd then return false
        if @upperEnd and date > @upperEnd then return false
        return true 

#endregion
