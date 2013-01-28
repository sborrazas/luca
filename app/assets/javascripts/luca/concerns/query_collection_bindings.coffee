Luca.concerns.QueryCollectionBindings =
  getCollection: ()->
    @collection

  loadModels: (models=[], options={})->
    @getCollection()?.reset(models, options)

  # Private: returns the query that is applied to the underlying collection.
  # accepts the same options as Luca.Collection.query's initial query option.
  getQuery: () ->
    @query

  getRemoteQuery: (options = {}) ->
    @getQuery(options)

  getLocalQuery: (options = {}) ->
    @getQuery(options)

  # Private: returns the query that is applied to the underlying collection.
  # accepts the same options as Luca.Collection.query's initial query option.
  getQueryOptions: (options={})->
    queryOptions = @queryOptions ||= {}

    for optionSource in _( @optionsSources || [] ).compact()
      queryOptions = _.extend(queryOptions, (optionSource(options)||{}) )

    queryOptions

  # Private: returns the models to be rendered.  If the underlying collection
  # responds to @query() then it will use that interface.
  getModels: (options = {})->
    if @collection?.query
      query = @getLocalQuery()

      # TODO
      # Need to write specs for this  
      @collection.query(query, options)
    else
      @collection.models

