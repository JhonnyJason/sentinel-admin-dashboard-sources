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
        @rowSelectListeners = []
        @cellSelectListeners = []

        @sortKey = @structure[0].key
        @sortAscending = false
        @keyToColInfo = Object.create(null)
        @keyToColInfo[info.key] = info for info in @structure
        @table.classList.add("table-renderer-table")
        @renderHead()

        if opts?
            if opts.sortKey? then @setSort(opts.sortKey, opts.sortAscending) 
            ## TODO: digest more options?
            if opts.data? then @updateData(opts.data)
        return

    log: (arg) => log("TableRenderer "+arg)

    prepareFilters : =>
        @log ".prepareFilters"
        for colInfo in @structure when colInfo.filter?.requiresRecords()
            records = @data.map((dataObj) -> access(dataObj, colInfo.key))
            colInfo.filter.processRecords(records)
        return

    setSort: (key, asc) =>
        @log ".setSort"
        headCellEl = @keyToColInfo[key]?.headCellEl
        if !headCellEl? then return console.error("TableRenderer.setSort - key has no associated colInfo Obj! ("+key+")")

        if key != @sortKey ## we change the column to sort
            oldHeadCellEl = @keyToColInfo[@sortKey]?.headCellEl
            if !oldHeadCellEl? then return console.error("TableRenderer.setSort - old key has no associated colInfo Obj! ("+@sortKey+")")

            oldHeadCellEl.classList.remove("sorted")
            oldHeadCellEl.classList.remove("asc")
            
            @sortKey = key
            headCellEl.classList.add("sorted")

        return unless typeof asc == "boolean"
        
        if asc then headCellEl.classList.add("asc")
        else headCellEl.classList.remove("asc")

        @sortAscending = asc
        return

    doSort: =>
        @log ".doSort"
        cmpFun = @keyToColInfo[@sortKey].sort
        return unless typeof cmpFun == "function"

        key = @sortKey
        if @sortAscending then f = -1
        else f = 1
        olog { key, f }

        sortFun = (el1, el2) -> cmpFun(access(el1, key), access(el2, key), f)
        @log "sorting..."

        # @displayedData.sort(sortFun)
        # return

        data = [...@displayedData]
        data.sort(sortFun)
        @displayedData = data
        return

    doFilter: =>
        @log ".doFilter"
        @displayedData = []
        return unless Array.isArray(@data)

        for dataObj in @data
            passed = true
            
            for colInfo in @structure when colInfo.filter?
                key = colInfo.key
                d = access(dataObj, key)
                if colInfo.filter.passes(d) then continue
                passed = false
                break
            
            if passed then @displayedData.push(dataObj)

        return

    updateStructure: (structure) =>
        @log ".updateStructure"

        if Array.isArray(@structure)
            for colInfo in @structure when colInfo.filter?
                colInfo.filter.removeOnChangeListener(@updateData)

        if Array.isArray(structure) then @structure = structure
        @renderHead()
        @updateData()
        return

    updateData: (data) =>
        @log ".updateData"
        if Array.isArray(data) then @data = data
        @prepareFilters()
        @doFilter()
        @doSort()
        @renderBody()
        return

    renderHead: =>
        @log ".renderHead"
        tableRenderer = this
        
        thead = document.createElement("thead")

        ## Render Header Row -> Column Titles + sort state
        headerRow = document.createElement("tr")
        thead.appendChild(headerRow)

        for colInfo in @structure
            th = document.createElement("th")
            headerRow.appendChild(th)
            
            label = colInfo.label
            key = colInfo.key
            sort = colInfo.sort #|| defaultSort

            th.innerHTML = label
            
            if key?
                colInfo.headCellEl = th
                th.dataset.key = key
                if typeof sort == "function" then th.classList.add("sortable") 
                if key == @sortKey
                    th.classList.add("sorted")
                    th.classList.add("asc") unless !@sortAscending 
                th.addEventListener("click", () -> onSortHeadClick(this, tableRenderer))

        ## Render Filter Row -> Render filter elements if present
        filterRow = document.createElement("tr")
        thead.appendChild(filterRow)

        for colInfo in @structure
            th = document.createElement("th")
            filterRow.appendChild(th)
            th.classList.add("filter")
            filter = colInfo.filter
            olog filter

            if filter?
                th.appendChild(filter.getElement())
                filter.addOnChangeListener(@updateData)
            

        if @thead? then @thead.replaceWith(thead)
        else @table.appendChild(thead)
        
        @thead = thead
        return

    renderBody: =>
        @log ".renderBody"
        tableRenderer = this

        ## Render Table Body
        tbody = document.createElement("tbody")

        for rowObj, rowIdx in @displayedData
            `let lettedRowIdx = rowIdx`
            row = document.createElement("tr")
            tbody.appendChild(row)
            row.addEventListener("click", () -> onDataRowClicked(this, lettedRowIdx, tableRenderer))

            for colInfo, colIdx in @structure
                td = document.createElement("td")
                row.appendChild(td)

                key = colInfo.key
                render = colInfo.render #|| defaultRender
                # log "accessing key: "+key
                d = access(rowObj, key)
                # log "resulting Data is: "+d
                ctx = { tableRenderer, colIdx, rowIdx }

                if typeof render == "function" then render(td, d, ctx)
                else console.error("Structure Error in column #{colIdx}. 'render' is not a function!")

        if @tbody? then @tbody.replaceWith(tbody)
        else @table.appendChild(tbody) 
            
        @tbody = tbody
        return

    subscribeRowSelect: (lstnr) =>
        @log "subscribeRowSelect"
        @rowSelectListeners.push(lstnr)        
        return

    unsubscribeRowSelect: (lstnr) =>
        @log "subscribeRowSelect"
        newListeners = []
        for fun in @rowSelectListeners when run != lstnr
            newListeners.push(fun)

        @rowSelectListeners = newListeners
        return

    notifyRowSelect: (rowIdx) =>
        @log ".notifyRowSelect "+rowIdx
        dataObj = @displayedData[rowIdx]
        olog dataObj
        fun(dataObj) for fun in @rowSelectListeners
        return

    # renderOld: (data) => ## this one is surprisingly fast for actually having 2 mistakes...
    #     log "render"
    #     @data = data unless @data? and !data?
    #     @doSort()

    #     tableRenderer = this

    #     @table.innerHTML = ""
        
    #     ## Render Table Head
    #     thead = document.createElement("thead")
    #     @table.appendChild(thead)
    #     headerRow = document.createElement("tr")

    #     for colInfo in @structure
    #         th = document.createElement("th")
    #         headerRow.appendChild(th)
            
    #         key = colInfo.key
    #         label = colInfo.label
    #         sort = colInfo.sort #|| defaultSort

    #         th.innerHTML = label

    #         if key?
    #             th.dataset.key = key
    #             if typeof sort == "function" then th.classList.add("sortable") 
    #             if key == @sortKey
    #                 th.classList.add("sorted")
    #                 th.classList.add("asc") unless !@sortAscending 
    #             th.addEventListener("click", () -> onSortHeadClick(this, tableRenderer))

    #     # filterRow = document.create

    #     ## append at last to only trigger one repaint
    #     thead.appendChild(headerRow)

    #     ## Render Table Body
    #     tbody = document.createElement("tbody")

    #     for rowObj, rowIdx in @data
    #         row = document.createElement("tr")
    #         tbody.appendChild(row)
            
    #         for colInfo, colIdx in @structure
    #             td = document.createElement("td")
    #             row.appendChild(td)

    #             key = colInfo.key
    #             render = colInfo.render #|| defaultRender
    #             log "accessing key: "+key
    #             d = access(rowObj, key)
    #             log "resulting Data is: "+d
    #             ctx = { tableRenderer, colIdx, rowIdx }

    #             if typeof render == "function" then render(td, d, ctx)
    #             else console.error("Structure Error in column #{colIdx}. 'render' is not a function!")
    #     ## append at last to only trigger one repaint
    #     @table.appendChild(tbody)
    #     return

onDataCellClicked = (el, colIdx, rowIdx, tableRenderer) ->
    log "onDataCellClicked"
    return

onDataRowClicked = (el, rowIdx, tableRenderer) ->
    log "onDataRowClicked "+rowIdx
    tableRenderer.notifyRowSelect(rowIdx)
    return

onSortHeadClick = (el, tableRenderer) ->
    log "onSortHeadClick"
    key = el.getAttribute("data-key")
    sortAscending = el.classList.toggle("asc")
    tableRenderer.setSort(key, sortAscending)
    tableRenderer.updateData()
    return

# defaultRender = (td, d, ctx) ->
#     switch (typeof d)
#         when 

# stringFilter
# dateRangeFilter
# boolFilter