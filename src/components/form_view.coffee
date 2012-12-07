# The FormView component is a special container which provides functionality
# around the components inside which extend from the Luca.core.Field class.
#
# The FormView component integrates well with Luca.Models and can control
# the attributes on that model, respond to validations, and submit changes
# to an API. 
formView = Luca.register        "Luca.components.FormView"

formView.extends                "Luca.core.Container"

formView.mixesIn                "LoadMaskable"

formView.triggers               "before:submit",
                                "before:reset",
                                "before:load",
                                "before:load:new",
                                "before:load:existing",
                                "after:submit",
                                "after:reset",
                                "after:load",
                                "after:load:new",
                                "after:load:existing",
                                "after:submit:success",
                                "after:submit:fatal_error",
                                "after:submit:error"



formView.publicConfiguration
  # should the label display above, or to the
  # side of the fields
  labelAlign: undefined

  # specifying this class gives you the ability
  # to layout the nested fields accordingly.
  fieldLayoutClass: undefined

  # should this form have a legend?
  legend: ""

  # available options are true, false, "top", "bottom", or "both"
  # the component configuration for the toolbar can be controlled
  # by specifying a name of a property that contains a valid
  # component reference ( either hash w/ type reference )
  toolbar: true

  # the name of the property which contains the configuration
  # for the buttons that will go in this toolbar.  Specify
  # a string so it can be lazily evaluated at initialization.
  toolbarConfig: undefined

  # the default toolbar definition that will be created if
  # the form is configured to have a toolbar on it.  this value
  # will be resolved at initialization, so pass a string identifying
  # an object in memory.
  defaultToolbar: "Luca.components.FormView.defaultToolbar"

  # if this form will be submitting values to a RESTful API and you
  # want to show a loading indicator or progress bar, configure the
  # @loadMask property.
  loadMask: true

  # Applies the twitter bootstrap well class to this form.
  # @$el.addClass('well') if @well
  well: false 

  # Applies the twitter bootstrap form-search class to this form.
  # @$el.addClass('form-search') if @searchForm
  searchForm: false

  # Applies the twitter bootstrap horizontal form class to this form.
  # @$el.addClass('form-horizontal') if @horizontalForm
  horizontalForm: false

  # Applies the twitter bootstrap inline form class to this form.
  # @$el.addClass('form-inline') if @inlineForm
  inlineForm: false

formView.privateConfiguration
  tagName: 'form'
  stateful: true
  events:
    "click .submit-button" : "submitHandler"
    "click .reset-button" : "resetHandler"

  bodyClassName: "form-view-body"

formView.privateMethods
  initialize: (@options={})->
    @loadMask = Luca.config.enableBoostrap unless @loadMask?

    Luca.core.Container::initialize.apply @, arguments

    @components ||= @fields

    _.bindAll @, "submitHandler", "resetHandler", "renderToolbars"

    @setupHooks( @hooks )

    @applyStyleClasses()

    Luca.components.FormView.setupToolbar.call(@)


  getDefaultToolbar: ()->
    config = @toolbarConfig || @defaultToolbar
    Luca.util.resolve( Luca.util.read(config) )

  applyStyleClasses: ()->
    if Luca.config.enableBoostrap
      @applyBootstrapStyleClasses()

    @$el.addClass( "label-align-#{ @labelAlign }") if @labelAlign
    @$el.addClass( @fieldLayoutClass ) if @fieldLayoutClass

  applyBootstrapStyleClasses: ()->
    @inlineForm = true if @labelAlign is "left"

    @$el.addClass('well') if @well
    @$el.addClass('form-search') if @searchForm
    @$el.addClass('form-horizontal') if @horizontalForm
    @$el.addClass('form-inline') if @inlineForm

  resetHandler: (e)->
    me = my = $( e?.target )
    @trigger "before:reset", @
    @reset()
    @trigger "after:reset", @

  submitHandler: (e)->
    me = my = $( e?.target )
    @trigger "before:submit", @
    @trigger "enable:loadmask", @ if @loadMask is true
    @submit() if @hasModel()

  afterComponents: ()->
    Luca.core.Container::afterComponents?.apply(@, arguments)

    form = @
    @eachField (field)->
      field.getForm = ()=> form 
      field.getModel = ()=> form.currentModel()

  eachField: (iterator)->
    _( @getFields() ).map( iterator )

  getField: (name)->
    passOne = _( @getFields('name', name) ).first()
    return passOne if passOne?

    _( @getFields('input_name', name) ).first()

  getFields: (attr,value)->
    fields = @selectByAttribute("isField", true, true)

    if attr? and value?
      fields = _(fields).select (field)->
        property  = field[ attr ]
        property  = property.call(field) if _.isFunction(property)
        property is value

    fields

  loadModel: (@current_model)->
    form = @
    fields = @getFields()

    @trigger "before:load", @, @current_model

    if @current_model
      @current_model.beforeFormLoad?.apply(@current_model, @)

      event = "before:load:#{ (if @current_model.isNew() then "new" else "existing")}"
      @trigger event, @, @current_model

    @setValues(@current_model)

    @trigger "after:load", @, @current_model

    if @current_model
      @trigger "after:load:#{ (if @current_model.isNew() then "new" else "existing")}", @, @current_model

  reset: ()->
    @loadModel( @current_model ) if @current_model?

  clear: ()->
    @current_model = if @defaultModel? then @defaultModel() else undefined

    _( @getFields() ).each (field)=>
      try
        field.setValue('')
      catch e
        console.log "Error Clearing", @, field

  # set the values on the form
  # without syncing
  setValues: (source, options={})->
    source ||= @currentModel()
    fields = @getFields()

    _( fields ).each (field) =>
      field_name = field.input_name || field.name

      if value = source[field_name]
        if _.isFunction(value)
          value = value.apply(@)

      if !value and Luca.isBackboneModel(source)
        value = source.get(field_name)

      field?.setValue( value ) unless field.readOnly is true

    @syncFormWithModel() unless options.silent? is true

  # Public: returns a hash of values for the form fields in this view.
  #
  # options - An options Hash to control the behavior of values returned (default: {}):
  #           reject_blank: don't include values which are blank (default: true)
  #           skip_buttons: don't include button fields (default: true)
  #           blanks: an inverse alias for reject_blank (default: false)
  getValues: (options={})->
    options.reject_blank = true unless options.reject_blank?
    options.skip_buttons = true unless options.skip_buttons?
    options.reject_blank = true if options.blanks is false
    options.reject_blank = false if options.blanks is true

    values = _( @getFields() ).inject (memo,field)=>
      value   = field.getValue()
      key     = field.input_name || field.name

      valueIsBlank      = !!(_.str.isBlank( value ) || _.isUndefined( value ))

      allowBlankValues  = not options.reject_blank and not field.send_blanks

      if options.debug
        console.log "#{ key } Options", options, "Value", value, "Value Is Blank?", valueIsBlank, "Allow Blanks?", allowBlankValues

      if options.skip_buttons and field.isButton
        skip = true
      else
        if valueIsBlank and allowBlankValues is false
          skip = true

        if field.input_name is "id" and valueIsBlank is true
          skip = true

      if options.debug
        console.log "Skip is true on #{ key }"

      if skip isnt true
        memo[ key ] = value

      memo

    , (options.defaults || {})

    values

  submit_success_handler: (model, response, xhr)->
    @trigger "after:submit", @, model, response
    @trigger "disable:loadmask", @ if @loadMask is true

    if response and response?.success is true
      @trigger "after:submit:success", @, model, response
    else
      @trigger "after:submit:error", @, model, response

  submit_fatal_error_handler: (model, response, xhr)->
    @trigger "after:submit", @, model, response
    @trigger "after:submit:fatal_error", @, model, response

  submit: (save=true, saveOptions={})->
    _.bindAll @, "submit_success_handler", "submit_fatal_error_handler"

    saveOptions.success ||= @submit_success_handler
    saveOptions.error ||= @submit_fatal_error_handler

    @syncFormWithModel()
    return unless save
    @current_model.save( @current_model.toJSON(), saveOptions )

  hasModel: ()->
    @current_model?

  currentModel: (options={})->
    if options is true or options?.refresh is true
      @syncFormWithModel()

    @current_model

  syncFormWithModel: (options)->
    @current_model?.set( @getValues(), options )

  setLegend: (@legend)->
    $('fieldset legend', @el).first().html(@legend)

  flash: (message)->
    if @$('.toolbar-container.top').length > 0
      @$('.toolbar-container.top').after(message)
    else
      @$bodyEl().prepend(message)

  successFlashDelay: 1500

  successMessage: (message)->
    @$('.alert.alert-success').remove()
    @flash Luca.template("components/form_alert", className:"alert alert-success", message: message)
    _.delay ()=>
      @$('.alert.alert-success').fadeOut()
    , @successFlashDelay || 0

  errorMessage: (message)->
    @$('.alert.alert-error').remove()
    @flash Luca.template("components/form_alert", className:"alert alert-error", message: message)

formView.classInterface
  setupToolbar: ()->
    if @toolbar isnt false and (not @topToolbar and not @bottomToolbar)
      if @toolbar is "both" or @toolbar is "top"
        @topToolbar = _.clone( @getDefaultToolbar() )

      unless @toolbar is "top"
        @bottomToolbar = _.clone( @getDefaultToolbar() )

  defaultToolbar:
    buttons:[
      icon:"remove-sign"
      label: "Reset"
      eventId: "click:reset"
      className:"reset-button"
      align: 'right'
    ,
      icon:"ok-sign"
      white: true
      label: "Save Changes"
      eventId: "click:submit"
      color: "success"
      className: 'submit-button'
      align: 'right'
    ]

formView.defines
  version: 2

