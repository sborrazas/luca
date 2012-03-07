# thanks player
# https://github.com/thefrontside/jasmine.backbone.js

json = (object) ->
  JSON.stringify object

msg = (list) ->
  (if list.length isnt 0 then list.join(";") else "")

eventBucket = (model, eventName) ->
  spiedEvents = model.spiedEvents
  spiedEvents = model.spiedEvents = {}  unless spiedEvents
  bucket = spiedEvents[eventName]
  bucket = spiedEvents[eventName] = []  unless bucket
  bucket

triggerSpy = (constructor) ->
  trigger = constructor::trigger
  constructor::trigger = (eventName) ->
    bucket = eventBucket(this, eventName)
    bucket.push Array::slice.call(arguments, 1)
    trigger.apply this, arguments

triggerSpy Backbone.Model
triggerSpy Backbone.Collection

EventMatchers = 
  toHaveTriggered: (eventName) ->
    bucket = eventBucket(@actual, eventName)
    triggeredWith = Array::slice.call(arguments, 1)
    @message = ->
      [ "expected model or collection to have received '" + eventName + "' with " + json(triggeredWith), "expected model not to have received event '" + eventName + "', but it did" ]

    _.detect bucket, (args) ->
      if triggeredWith.length is 0
        true
      else
        jasmine.getEnv().equals_ triggeredWith, args

ModelMatchers =
  toHaveAttributes: (attributes) ->
    keys = []
    values = []
    jasmine.getEnv().equals_ @actual.attributes, attributes, keys, values
    missing = []
    i = 0

    while i < keys.length
      message = keys[i]
      missing.push keys[i]  if message.match(/but missing from/)
      i++
    @message = ->
      [ "model should have at least these attributes(" + json(attributes) + ") " + msg(missing) + " " + msg(values), "model should have none of the following attributes(" + json(attributes) + ") " + msg(keys) + " " + msg(values) ]

    missing.length is 0 and values.length is 0

  toHaveExactlyTheseAttributes: (attributes) ->
    keys = []
    values = []
    equal = jasmine.getEnv().equals_(@actual.attributes, attributes, keys, values)
    @message = ->
      [ "model should match exact attributes, but does not. " + msg(keys) + " " + msg(values), "model has exactly these attributes, but shouldn't :" + json(attributes) ]

    equal

beforeEach ->
  @addMatchers ModelMatchers
  @addMatchers EventMatchers