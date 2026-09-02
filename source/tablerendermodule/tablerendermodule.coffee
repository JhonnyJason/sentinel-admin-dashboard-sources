############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("tablerendermodule")
#endregion

############################################################
import { accessDeepProp as access } from "./tableutils.js"

############################################################
export class TableRenderer
    constructor: (@table, @structure, opts) ->
        @sortKey = @structure[0].key
        @sortAscending = false
        @keyToColInfo = Object.create(null)
        @keyToColInfo[info.key] = info for info in @structure
        @table.classList.add("table-renderer-table")

        return unless opts?

        if opts.sortKey? then @sortKey = opts.sortKey
        if opts.sortAscending? then @sortAscending = opts.sortAscending
        ## TODO: digest more options?
        
        if opts.data? then @render(opts.data)
        return
    
    setSort: (key, asc) =>
        log "setSort"
        @sortKey = key
        @sortAscending = asc
        return

    doSort: =>
        log "doSort"
        cmpFun = @keyToColInfo[@sortKey].sort
        return unless typeof cmpFun == "function"

        key = @sortKey
        if @sortAscending then f = -1
        else f = 1
        olog { key, f }

        sortFun = (el1, el2) -> cmpFun(access(el1, key), access(el2, key), f)
        log "sorting..."

        # @data.sort(sortFun)

        data = [...@data]
        data.sort(sortFun)
        @data = data
        return

    render: (data) =>
        log "render"
        @data = data unless @data? and !data?
        @doSort()
        tableRenderer = this

        @table.innerHTML = ""
        
        ## Render Table Head
        thead = document.createElement("thead")
        @table.appendChild(thead)
        headerRow = document.createElement("tr")
        thead.appendChild(headerRow)

        for colInfo in @structure
            th = document.createElement("th")
            headerRow.appendChild(th)
            
            key = colInfo.key
            label = colInfo.label
            sort = colInfo.sort

            th.innerHTML = label

            if key?
                th.dataset.key = key
                if typeof sort == "function" then th.classList.add("sortable") 
                if key == @sortKey
                    th.classList.add("sorted")
                    th.classList.add("asc") unless !@sortAscending 
                th.addEventListener("click", () -> onSortHeadClick(this, tableRenderer))

        ## Render Table Body
        tbody = document.createElement("tbody")
        @table.appendChild(tbody)

        for rowObj, rowIdx in @data
            row = document.createElement("tr")
            tbody.appendChild(row)
            
            for colInfo, colIdx in @structure
                td = document.createElement("td")
                row.appendChild(td)

                key = colInfo.key
                render = colInfo.render
                    
                d = access(rowObj, key)
                ctx = { tableRenderer: this, colIdx, rowIdx }

                if typeof render == "function" then render(td, d, ctx)
                else console.error("Structure Error in column #{colIdx}. 'render' is not a function!")
        return


onSortHeadClick = (el, tableRenderer) ->
    log "onSortHeadClick"
    key = el.getAttribute("data-key")
    sortAscending = el.classList.toggle("asc")
    tableRenderer.setSort(key, sortAscending)
    tableRenderer.render()
    return