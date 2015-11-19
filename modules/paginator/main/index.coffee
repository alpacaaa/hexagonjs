getRange = (selected, visibleCount, pageCount) ->
  start = Math.max(1, selected - Math.floor(visibleCount / 2))
  end = Math.min(start + visibleCount, pageCount + 1)
  start = Math.max(1, end - visibleCount)
  {start: start, end: end}

render = (paginator) ->

  if paginator._.pageCount is undefined
    data = [{
      value: paginator.selected
      selected: true
      dataLength: paginator.selected.toString().length
    }]
  else
    {start, end} = getRange(paginator.selected, paginator._.visibleCount, paginator._.pageCount)

    maxLength = Math.max(start.toString().length, (end - 1).toString().length)
    buttonSize = 30 + (5 * Math.max(0, maxLength - 2))

    # 85 is the width of the back/forward buttons which never changes
    buttonSpace = paginator.container.width() - 81
    maxButtons = Math.floor(buttonSpace / buttonSize)
    visibleCount = Math.min(maxButtons, paginator._.visibleCount)
    visibleCount = Math.max(visibleCount, 1)

    # XXX: Probably shouldn't run this twice every time
    {start, end} = getRange(paginator.selected, visibleCount, paginator._.pageCount)

    data = hx.range(end - start).map (i) ->
      {
        value: start + i
        selected: paginator.selected == start + i
        dataLength: maxLength
      }

  paginator.view.apply(data)

select = (paginator, i, cause) ->
  if paginator._.pageCount is undefined
    newPage = Math.max(i, 1)
  else
    newPage = hx.clamp(1, paginator._.pageCount, i)

  if newPage != paginator.selected
    paginator.selected = newPage
    render(paginator)
    paginator.emit 'change', {cause: cause, selected: paginator.selected}


class Paginator extends hx.EventEmitter
  constructor: (selector) ->
    super

    hx.component.register(selector, this)

    @container = hx.select(selector).classed('hx-paginator', true)
    @_ =
      selector: selector

    self = this

    # go-to-start button
    @container.append('button')
      .attr('type', 'button')
      .class('hx-btn ' + hx.theme.paginator.arrowButton)
        .html('<i class="hx-icon hx-icon-step-backward"></i>')
        .on 'click', 'hx.paginator', ->
          if self._.pageCount is undefined
            select(self, self.selected - 1, 'user')
          else
            select(self, 0, 'user')

    pageButtons = @container.append('span').class('hx-input-group')
    @view = pageButtons.view('.hx-btn', 'button').update (d, e, i) ->
      @text(d.value)
        .attr('type', 'button')
        .classed('hx-paginator-three-digits', d.dataLength is 3)
        .classed('hx-paginator-more-digits', d.dataLength > 3)
        .classed(hx.theme.paginator.defaultButton, not d.selected)
        .classed(hx.theme.paginator.selectedButton, d.selected)
        .classed('hx-no-border', true)
        .on 'click', 'hx.paginator', -> select(self, d.value, 'user')

    # go-to-end button
    @container.append('button')
      .attr('type', 'button')
      .class('hx-btn ' + hx.theme.paginator.arrowButton)
        .html('<i class="hx-icon hx-icon-step-forward"></i>')
        .on 'click', 'hx.paginator', ->
          if self._.pageCount is undefined
            select(self, self.selected + 1, 'user')
          else
            select(self, self._.pageCount, 'user')

    @container.on 'resize', 'hx.paginator', -> render(self)

    @_.visibleCount = 10
    @_.pageCount = 10
    @selected = 1
    render(this)

  page: (i) ->
    if arguments.length > 0
      select(@, i, 'api')
      this
    else
      @selected


  pageCount: (value) ->
    if value?
      @_.pageCount = value
      render(this)
      this
    else
      @_.pageCount

  visibleCount: (value) ->
    if value?
      @_.visibleCount = value
      render(this)
      this
    else
      @_.visibleCount

hx.paginator = (options) ->
  selection = hx.detached('div')
  new Paginator(selection.node(), options)
  selection

hx.Paginator = Paginator