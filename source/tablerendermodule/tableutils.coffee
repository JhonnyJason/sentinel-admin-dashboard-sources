############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("tableutils")
#endregion

############################################################
export accessDeepProp = (obj, key) ->
    tkns = key.split(".")
    prop = obj
    try prop = obj[tk] for tk in tkns
    catch err then console.error("Could not accessDeepProp #{key} in obj: #{JSON.stringify(obj, null, 4)}")
    return prop

############################################################
#region functions for sorting
export stringCompare = (str1, str2, f) ->
    if str1 > str2 then return (-1) * f 
    if str1 < str2 then return f 
    return 0

export numberCompare = (a, b, f) -> (b - a) * f

export booleanCompare = (a, b, f) -> (+ b - a) * f


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
        dateObj = new Date(d)
        dateStr = dateObj.toISOString().slice(0, 10)
        [Y,M,D] = dateStr.split("-")
        td.textContent = [D,M,Y].join(".")
    catch err
        console.error(err)
        console.error("Data and indices "+JSON.stringify({ d, colIdx: ctx.colIdx, rowIdx: ctx.rowIdx }, null, 4))
    return

#endregion