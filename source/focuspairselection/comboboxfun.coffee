############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("comboboxfun")
#endregion

############################################################
export class Combobox
    constructor: ({ inputEl, dropdownEl, optionsLimit }) ->
        log "Combobox constructor"
        @inputEl = inputEl
        @dropdownEl = dropdownEl
        @optionsLimit = optionsLimit ? 30

        @fullOptions = []
        @currentOptions = []
        @dropdownVisible = false
        @highlightedIndex = -1
        @selectionCallback = null
        @blurTimeoutId = null

        @inputEl.addEventListener("focus", @onFocus)
        @inputEl.addEventListener("input", @onInput)
        @inputEl.addEventListener("keydown", @onKeydown)
        @inputEl.addEventListener("blur", @onBlur)
        @dropdownEl.addEventListener("mousedown", @onDropdownMousedown)

    ############################################################
    #region Public Methods
    onSelect: (callback) ->
        @selectionCallback = callback
        return

    setOptions: (opts) ->
        log "setOptions"
        @fullOptions = opts
        @updateCurrentOptions()
        return
    #endregion

    ############################################################
    #region Event Handlers
    onFocus: =>
        log "onFocus"
        if @blurTimeoutId
            clearTimeout(@blurTimeoutId)
            @blurTimeoutId = null
        @updateCurrentOptions()
        @showDropdown()
        return

    onInput: =>
        log "onInput"
        @updateCurrentOptions()
        @highlightedIndex = if @currentOptions.length > 0 then 0 else -1
        @renderDropdown()
        return

    onKeydown: (e) =>
        return unless @dropdownVisible

        switch e.key
            when "ArrowDown"
                e.preventDefault()
                if @highlightedIndex < @currentOptions.length - 1
                    @highlightedIndex++
                    @renderDropdown()
                    @scrollToHighlighted()
            when "ArrowUp"
                e.preventDefault()
                if @highlightedIndex > 0
                    @highlightedIndex--
                    @renderDropdown()
                    @scrollToHighlighted()
            when "Enter"
                e.preventDefault()
                if @highlightedIndex >= 0 and @currentOptions[@highlightedIndex]
                    @selectOption(@currentOptions[@highlightedIndex])
            when "Escape"
                e.preventDefault()
                @hideDropdown()
                @inputEl.blur()
        return

    onBlur: =>
        log "onBlur"
        @blurTimeoutId = setTimeout((=> @hideDropdown()), 150)
        return

    onDropdownMousedown: (e) =>
        e.preventDefault()
        return
    #endregion

    ############################################################
    #region Internal Methods
    updateCurrentOptions: ->
        query = @inputEl.value.trim().toUpperCase()

        if query.length == 0
            @currentOptions = @fullOptions.slice(0, @optionsLimit)
        else
            @currentOptions = @filterOptions(query)
        return

    filterOptions: (query) ->
        log "filterOptions: #{query}"
        matched = []
        for opt in @fullOptions
            if opt.includes(query)
                matched.push(opt)
        return matched.slice(0, @optionsLimit)

    showDropdown: ->
        return if @dropdownVisible
        @dropdownVisible = true
        @highlightedIndex = if @currentOptions.length > 0 then 0 else -1
        @renderDropdown()
        @dropdownEl.classList.add("visible")
        return

    hideDropdown: ->
        return unless @dropdownVisible
        @dropdownVisible = false
        @highlightedIndex = -1
        @dropdownEl.classList.remove("visible")
        return

    renderDropdown: ->
        html = ""
        for opt, i in @currentOptions
            highlightClass = if i == @highlightedIndex then " highlighted" else ""
            html += """<div class="combobox-option#{highlightClass}" data-index="#{i}">#{opt}</div>"""

        if @currentOptions.length == 0
            html = '<div class="combobox-empty">Keine Ergebnisse</div>'

        @dropdownEl.innerHTML = html

        for optEl in @dropdownEl.querySelectorAll(".combobox-option")
            optEl.addEventListener("click", @onOptionClick)
        return

    scrollToHighlighted: ->
        highlighted = @dropdownEl.querySelector(".highlighted")
        return unless highlighted
        highlighted.scrollIntoView({ block: "nearest" })
        return

    onOptionClick: (e) =>
        index = parseInt(e.currentTarget.dataset.index)
        if @currentOptions[index]
            @selectOption(@currentOptions[index])
        return

    selectOption: (opt) ->
        log "selectOption: #{opt}"
        @inputEl.value = opt
        @hideDropdown()
        @selectionCallback?(opt)
        return
    #endregion
