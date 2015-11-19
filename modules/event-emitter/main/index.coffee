
class BasicEventEmitter

  constructor: ->
    @callbacks = new hx.Map
    @allCallbacks = new hx.List

  # emit an object to all callbacks registered with the name given
  emit: (name, data) ->
    if @callbacks.has(name) then cb(data) for cb in @callbacks.get(name).entries()
    cb(name, data) for cb in @allCallbacks.entries()
    this

  # register a callback against the name given
  on: (name, callback) ->
    if name
      if not @callbacks.has(name)
        @callbacks.set(name, new hx.List)
      @callbacks.get(name).add callback
    else
      @allCallbacks.add callback
    this

  # returns true if emitting an event under the name given will actually call any callbacks
  # this makes it possible to avoid emitting events, when no registered callbacks exist - and
  # avoid the cost of building data that goes with the events. This should only be used in
  # exceptional circumstances where lots of calls to emit have to be done at once.
  has: (name) ->
    @allCallbacks.size > 0 or (@callbacks.has(name) and @callbacks.get(name).size > 0)

  # deregisters a callback
  off: (name, callback) ->
    if callback
      if name
        @callbacks.get(name)?.remove(callback)
      else
        @allCallbacks.remove(callback)
    else
      if name
        @callbacks.set(name, new hx.List)
      else
        @callbacks = new hx.Map
        @allCallbacks = new hx.List
    this

  # lets you pipe events through to another event emitter
  pipe: (eventEmitter, prefix, filter) ->
    filterer = if filter
      (n) -> filter.indexOf(n) isnt -1
    else
      (n) -> true

    if prefix
      @on null, (n, v) ->
        if filterer(n)
          eventEmitter.emit(prefix + '.' + n, v)
    else
      @on null, (n, v) ->
        if filterer(n)
          eventEmitter.emit(n, v)
    this


class EventEmitter
  constructor: ->
    @suppressedMap = new hx.Map
    @emitters = new hx.List
    @emittersMap = new hx.Map
    @global = addEmitter(this, 'default')

  addEmitter = (ee, namespace) ->
    be = new BasicEventEmitter
    ee.emittersMap.set(namespace, be)
    ee.emitters.add(be)
    be

  removeEmitter = (ee, namespace) ->
    if ee.emittersMap.has(namespace)
      ee.emittersMap.delete(namespace)
      ee.emitters.remove(ee)
    ee

  # emit an object to all callbacks registered with the name given
  emit: (name, data) ->
    if not @suppressedMap.get(name)
      if @deprecatedEvents?
        for e of @deprecatedEvents
          if @deprecatedEvents[e].event is name
            @emit e, data

      for emitter in @emitters.entries()
        emitter.emit(name, data)
    this

  # supresses all events of the given name (so calling emit will have no effect until re-enabled)
  suppressed: (name, suppressed) ->
    if arguments.length > 1
      @suppressedMap.set(name, !!suppressed)
      this
    else
      !!@suppressedMap.get(name)

  # register a callback against the name given
  on: (name, namespace, callback) ->

    # XXX: Deprecated event check
    if (dep = @deprecatedEvents?[name])?
      deprecatedEventWarning(dep.module, name, dep.event)
      name = dep.event

    if namespace is 'default'
      hx.consoleWarning('"default" is a reserved namespace. It can not be used as a namespace name.')
      return this

    if hx.isString(namespace)
      ee = @emittersMap.get(namespace)
      if not ee
        ee = addEmitter(this, namespace)
      ee.on(name, callback)
    else
      @global.on(name, namespace)
    this

  has: (name) ->
    if @global.has(name) then return true
    for emitter in @emitters.entries()
      if emitter.has(name) then return true
    return false

  # deregisters a callback
  off: (name, namespace, callback) ->
    if hx.isString(namespace)
      @emittersMap.get(namespace)?.off(name, callback)
    else
      for emitter in @emitters.entries()
        emitter.off(name, callback)
    this

  # lets you pipe events through to another event emitter
  pipe: (eventEmitter, prefix, filter) ->
    @global.pipe(eventEmitter, prefix, filter)
    this

hx.EventEmitter = EventEmitter

deprecatedEventWarning = (module, deprecatedEvent, newEvent) ->
  message = if deprecatedEvent is newEvent
    'Check the docs for alternatives.'
  else
    'Use ' + newEvent + ' instead.'

  hx.deprecatedWarning module + ': ' + deprecatedEvent, message