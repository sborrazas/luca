Luca.components.Toolbar = Luca.core.Container.extend
  className: 'luca-ui-toolbar'
  
  position: 'bottom'

  initialize: (@options={})->
    Luca.core.Container.prototype.initialize.apply @, arguments

  prepareComponents: ()->
    _( @components ).each (component)=> 
      component.container = @el

  render: ()->
    console.log "Rendering Toolbar", $(@el), $(@container)
    $(@container).append(@el)


Luca.register "toolbar", "Luca.components.Toolbar"