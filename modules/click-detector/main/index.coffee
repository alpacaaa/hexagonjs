### istanbul ignore next: ignores 'extend' method added by coffeescript ###
class ClickDetector extends hx.EventEmitter
  constructor: ->
    super
    @eventId = hx.randomId()
    @exceptions = new hx.List

    # the original element clicked
    container = undefined

    @downAction = (e) =>
      e = e.event
      container = e.target
      call = true
      for element in @exceptions.entries()
        if element.contains(e.target) then call = false
      if call then @emit('click')

    @upAction = (e) =>
      e = e.event
      call = true
      isInDom = document.documentElement.contains(e.target)
      releasedOutside = container and not container.contains(e.target)
      if releasedOutside or not isInDom
        call = false
      container = undefined
      for element in @exceptions.entries()
        if element.contains(e.target) then call = false
      if call then @emit('click')

    hx.select(document).on('pointerdown', 'hx.click-detector.' + @eventId, @downAction)
    hx.select(document).on('pointerup', 'hx.click-detector.' + @eventId, @upAction)

  addException: (element) ->
    @exceptions.add(element)
    this

  removeAllExceptions: ->
    @exceptions.clear()
    this

  cleanUp: ->
    hx.select(document).off('pointerdown', 'hx.click-detector.' + @eventId, @downAction)
    hx.select(document).off('pointerup', 'hx.click-detector.' + @eventId, @upAction)
    this

hx.ClickDetector = ClickDetector