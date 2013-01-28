Luca.concerns.Filterable =
  classMethods:
    prepare: (filter = {}, options = {}) ->
      prepared = @prepareRemoteFilter(filter, options)
      @collection.applyFilter(prepared, remote: true)

  __included: (component, module) ->
    _.extend(Luca.Collection::, __filters:{})

  __initializer: (component, module) ->
    if @filterable is false
      return

    @filterable = {} if @filterable is true

    # TEMP HACK
    unless Luca.isBackboneCollection(@collection)
      @collection = Luca.CollectionManager.get?()?.getOrCreate(@collection)

    unless Luca.isBackboneCollection(@collection)
      @debug "Skipping Filterable due to no collection being present on #{ @name || @cid }"
      @debug "Collection", @collection
      return

    module

  prepareRemoteFilter: (filter={}, options={})->
    filter[ Luca.config.apiLimitParameter ] = options.limit if options.limit?
    filter[ Luca.config.apiPageParameter ] = options.page if options.page?
    filter[ Luca.config.apiSortByParameter ] = options.sortBy if options.sortBy?

    filter

  setSortBy: (sortBy, options = {}) ->
    @getFilterState().setOption('sortBy', sortBy, options)

  applyFilter: (filters, options = {}) ->
    @query = filters
    @options = options
    if options.remote is true
      Luca.concerns.Filterable.classMethods.prepare.apply(@, @getRemoteQuery(), options)
    @trigger "data:refresh"
