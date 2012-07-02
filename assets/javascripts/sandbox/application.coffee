_.def('Sandbox.Application').extends('Luca.Application').with

  autoBoot: true

  name: 'SandboxApp'

  router: "Sandbox.Router"

  el: '#viewport'

  fluid: true

  topNav:'top_navigation'

  useKeyRouter: true

  keyEvents:
    meta:
      forwardslash: "developmentConsole"

  collectionManager:
    initialCollections: ["components"]

  components:[
    ctype: 'controller'
    name: 'pages'
    components:[
      name: "main"
      className:"marketing-content"
      bodyTemplate: 'main'
    ,
      name: "build"
      ctype: "builder"
    ]
  ]

  developmentConsole: ()->
    @developmentConsole = Luca "coffeescript-console", ()->
      new Luca.tools.DevelopmentConsole(name:"coffeescript-console")

    unless @consoleContainerAppended
      container = @make("div",{id:"devtools-console-wrapper",class:"devtools-console-container modal",style:"width:1000px"}, @developmentConsole.el)
      $('body').append( container )
      @consoleContainerAppended = true
      @developmentConsole.render()

    $('#devtools-console-wrapper').modal(backdrop:false,show:true)

$ -> 
  new Sandbox.Application()