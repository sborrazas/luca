#### Luca Base View
Luca.View = Backbone.View.extend
  base: 'Luca.View'

# The Luca.View class adds some very commonly used patterns
# and functionality to the stock Backbone.View class. Features
# such as auto event binding, the facilitation of deferred rendering
# against a Backbone.Model or Backbone.Collection reset event, Caching
# views into a global Component Registry, and more.

Luca.View.originalExtend = Backbone.View.extend

# By overriding Backbone.View.extend we are able to intercept
# some method definitions and add special behavior around them
# mostly related to render()
Luca.View.extend = (definition)->
  #### Rendering 
  #
  # Our base view class wraps the defined render() method
  # of the views which inherit from it, and does things like
  # trigger the before and after render events automatically.
  # In addition, if the view has a deferrable property on it
  # then it will make sure that the render method doesn't get called
  # until.

  _base = definition.render

  _base ||= ()->
    return unless $(@container) and $(@el) 
      $(@container).append( $(@el) )

  definition.render = ()->
    if @deferrable
      @trigger "before:render", @
      
      @deferrable.bind @deferrable_event, _.once ()=>
        _base.apply(@, arguments)
        @trigger "after:render", @
     
      # we might not want to fetch immediately upon 
      # rendering, so we can pass a deferrable_trigger
      # event and not fire the fetch until this event
      # occurs
      if !@deferrable_trigger
        @immediate_trigger = true
      
      if @immediate_trigger is true
        @deferrable[ @deferrable_action ]()
      else
        @bind @deferrable_trigger, _.once ()=>
          @deferrable[ @deferrable_action ]()

    else
      @trigger "before:render", @
      _base.apply(@, arguments)
      @trigger "after:render", @

  Luca.View.originalExtend.apply @, [definition]

_.extend Luca.View.prototype,
  debug: ()->
    return unless @debugMode or window.LucaDebugMode?
    console.log [(@name || @cid),message] for message in arguments

  trigger: (@event)->
    Backbone.View.prototype.trigger.apply @, arguments

  # Hooks are event triggers which will automatically be bound to 
  # methods with similar names, e.g. "after:initialize" => afterInitialize()
  hooks:[
    "after:initialize"
    "before:render"
    "after:render"
    "first:activation"
    "activation"
    "deactivation"
  ]
  
  #### Deferrable Rendering
  #
  # If you want to defer rendering of a view until a collection
  # is loaded, you can pass that collection as a @deferrable property 
  # on your view, and Luca will take care of the process for you.
  deferrable: undefined 

  # By default, a deferrable will be a collection but it coul dbe anything.
  deferrable_action: "fetch"  
  deferrable_event: "reset"

  # If you don't specify a trigger, then the binding / action firing process
  # will happen immediately on the call to render.  Otherwise, if you want to
  # delay the action firing which would trigger the event, you can specify
  # which trigger you want to listen to on your view before that happens.  A 
  # classic example would be having a bunch of views nested in a tab view
  # or card view container, and you don't want to fetch the collection unless
  # the tab is activated.  

  # So you would set @deferrable_trigger to "first:activation"
  deferrable_trigger: undefined

  initialize: (@options={})->
    @cid = _.uniqueId(@name) if @name?

    _.extend @, @options

    #### View Caching
    #
    # Luca.View(s) which get created get stored in a global cache by their
    # component id.  This allows us to re-use views when it makes sense
    Luca.cache( @cid, @ )
    
    unique = _( Luca.View.prototype.hooks.concat( @hooks ) ).uniq()
    
    @setupHooks( unique )

    @trigger "after:initialize", @

  #### Hooks or Auto Event Binding
  # 
  # views which inherit from Luca.View can define hooks
  # or events which can be emitted from them.  Automatically,
  # any functions on the view which are named according to the
  # convention will automatically get run.  
  #
  # by default, all Luca.View classes come with the following:
  #
  # before:render     : beforeRender()
  # after:render      : afterRender()
  # after:initialize  : afterInitialize()
  # first:activation  : firstActivation()
  setupHooks: (set)->
    set ||= @hooks
    
    _(set).each (event)=>
      parts = event.split(':')
      prefix = parts.shift()
      
      parts = _( parts ).map (p)-> _.capitalize(p)
      fn = prefix + parts.join('')
      
      @bind event, ()=> @[fn].apply @, arguments if @[fn]
