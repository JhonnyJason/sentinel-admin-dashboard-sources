############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("ExperimentStore")
#endregion

############################################################
# ExperimentStore - Pure data container for experiment versioning
#
# Manages named experiments, each with a version history of
# parameter snapshots. Tracks current experiment+version,
# published state, and modification detection via snapshot comparison.
#
# No DOM, no listeners, no imports from playground modules.
# All coordination happens in forexscoreversion.coffee.

############################################################
export class ExperimentStore
    constructor: ->
        @experiments = {}       # { name: [snapshot_v0, snapshot_v1, ...] }
        @current = null         # { name, version } or null
        @published = null       # { name, version } or null
        @baseSnapshot = null    # last saved/loaded state
        @liveSnapshot = null    # current working state

    ########################################################
    #region Hydration (from backend)

    # Restore full state from backend data
    # entries: { "Name": [s0, s1, ...], ... }
    # published: { name, version } | null
    hydrate: (entries, published) =>
        @experiments = deepCopy(entries)
        @published = if published? then { name: published.name, version: published.version } else null

        # Open published experiment if it exists, else first experiment
        if @published? and @experiments[@published.name]?
            @current = { name: @published.name, version: @published.version }
        else
            names = Object.keys(@experiments)
            if names.length > 0
                name = names[0]
                versions = @experiments[name]
                @current = { name, version: versions.length - 1 }
            else
                @current = null

        if @current?
            stored = @experiments[@current.name][@current.version]
            @baseSnapshot = deepCopy(stored)
            @liveSnapshot = deepCopy(stored)
        else
            @baseSnapshot = null
            @liveSnapshot = null
        return

    #endregion

    ########################################################
    #region Experiment lifecycle

    # Create new experiment with given snapshot as v0
    createNew: (snapshot) =>
        name = @generateName()
        @experiments[name] = [deepCopy(snapshot)]
        @current = { name, version: 0 }
        @baseSnapshot = deepCopy(snapshot)
        @liveSnapshot = deepCopy(snapshot)
        return name

    # Open an existing experiment at its latest version
    open: (name) =>
        return unless @experiments[name]?
        versions = @experiments[name]
        @current = { name, version: versions.length - 1 }
        stored = versions[@current.version]
        @baseSnapshot = deepCopy(stored)
        @liveSnapshot = deepCopy(stored)
        return

    # Save current params as new version in current experiment
    save: (snapshot) =>
        return unless @current?
        versions = @experiments[@current.name]
        return unless versions?
        versions.push(deepCopy(snapshot))
        @current.version = versions.length - 1
        @baseSnapshot = deepCopy(snapshot)
        @liveSnapshot = deepCopy(snapshot)
        return

    # Select a specific version within current experiment
    selectVersion: (index) =>
        return unless @current?
        versions = @experiments[@current.name]
        return unless versions? and index >= 0 and index < versions.length
        @current.version = index
        stored = versions[index]
        @baseSnapshot = deepCopy(stored)
        @liveSnapshot = deepCopy(stored)
        return

    # Rename current experiment
    rename: (newName) =>
        return unless @current?
        oldName = @current.name
        return if oldName == newName
        return if @experiments[newName]?  # name already taken

        @experiments[newName] = @experiments[oldName]
        delete @experiments[oldName]
        @current.name = newName

        # Update published reference if it pointed to old name
        if @published? and @published.name == oldName
            @published.name = newName
        return

    #endregion

    ########################################################
    #region Publish

    # Mark current experiment+version as published
    publish: =>
        return unless @current?
        @published = { name: @current.name, version: @current.version }
        return

    # Is current experiment+version the published one?
    isAtPublished: =>
        return false unless @current? and @published?
        return @current.name == @published.name and @current.version == @published.version

    getPublishedInfo: => @published

    #endregion

    ########################################################
    #region Modification detection

    # Called on every param change with a fresh snapshot from the controller
    updateLiveSnapshot: (snapshot) =>
        @liveSnapshot = snapshot
        return

    # Compare live state against base (last saved/loaded)
    isModified: =>
        return false unless @baseSnapshot? and @liveSnapshot?
        return JSON.stringify(@baseSnapshot) != JSON.stringify(@liveSnapshot)

    #endregion

    ########################################################
    #region Getters

    getCurrent: => @current

    getCurrentSnapshot: =>
        return null unless @current?
        versions = @experiments[@current.name]
        return null unless versions?
        return deepCopy(versions[@current.version])

    getExperimentNames: => Object.keys(@experiments)

    getVersionCount: =>
        return 0 unless @current?
        return @experiments[@current.name]?.length or 0

    hasExperiment: => @current?

    #endregion

    ########################################################
    #region Name generation

    # "Experiment X" where X is lowest integer > 0 not taken
    generateName: =>
        existing = @experiments
        i = 1
        loop
            name = "Spielwiese#{i}"
            return name unless existing[name]?
            i++

    #endregion

############################################################
deepCopy = (obj) -> JSON.parse(JSON.stringify(obj))
