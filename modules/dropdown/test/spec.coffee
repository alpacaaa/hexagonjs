describe 'hx-dropdown', ->

  windowSize = 1000
  savedHxLoop = undefined
  button = undefined
  content = '<div style="padding:10px; width: 100px">Content</div>'
  id = '#button'

  fixture = undefined
  clock = undefined

  getWindowMeasurement = (horizontal, scroll) ->
    if scroll then 0
    else windowSize

  # Fixes firefox's unexplained decimal test failures
  roundAll = (box) ->
    for key, value of box
      box[key] = Math.round value
    box

  getSpacing = (dd) -> dd.options.spacing or Number(hx.theme.dropdown.spacing)

  fakeNodeEvent = (node, eventName) ->
    if node?
      (e) -> hx.select.getHexagonElementDataObject(node).eventEmitter?.emit((if eventName? and isNaN(eventName) then eventName else 'click'), e)

  makeButton = ->
    fixture.append('div')
      .attr('id', id.slice(1))
      .style('width', '100px')
      .style('height', '50px')
      .style('position', 'absolute')
      .style('top', '50%')
      .style('left', '50%')
      .style('margin', '-50px -25px 0 0')
      .text('button')

  beforeAll ->

    hx._.dropdown.attachToSelector = '#dropdown-fixture'

    hx.select('body')
      .style('height', '1000px')
      .style('width', '1000px')

    fixture = hx.select('body').append('div')
      .style('padding', '0')
      .style('margin', '0')
      .style('width', '1000px')
      .style('height', '1000px')
      .style('position', 'relative')
      .attr('id', 'dropdown-fixture')

    window.innerHeight = 1000
    window.innerWidth = 1000
    # mock hx.loop
    hx_requestAnimationFrame = (f) ->
      setTimeout(f, 1)
    hx_loop_update = (f, g) -> if not f() then hx_requestAnimationFrame(g)
    savedHxLoop = hx.loop
    hx.loop = hx_loop = (f) ->
      g = -> hx_loop_update(f, g)
      hx_loop_update(f, g)
    baseTime = new Date(2013, 0, 1)
    clock = sinon.useFakeTimers(baseTime.getTime())

  afterAll ->
    fixture.remove()
    hx.loop = savedHxLoop
    clock.restore()
    hx.select('body')
      .style('padding', '')
      .style('margin', '')
      .style('width', '')
      .style('height', '')
      .style('position', '')
      .clear()

  beforeEach ->
    button = makeButton()

  afterEach ->
    hx.component(id).cleanUp()
    hx.selectAll('.hx-dropdown').remove()
    button = undefined
    fixture.clear()


  it 'should throw an error when passing in the wrong thing for dropdownContent', ->
    chai.spy.on(console, 'error')
    dd = new hx.Dropdown(id, hx.detached('div'))
    dd.show()
    console.error.should.have.been.called.with('dropdown: dropdownContent is not a valid type ' + id)

  it 'should create a dropdown object with the correct default options', ->
    dd = new hx.Dropdown(id, content)

    dd._.selection.should.eql(button)
    getSpacing(dd).should.equal(0)
    dd.options.matchWidth.should.equal(true)
    dd._.alignments.should.eql('lblt'.split(''))
    should.not.exist(dd._.dropdown)
    dd._.visible.should.equal(false)
    dd.options.ddClass.should.equal('')
    dd.options.mode.should.equal('click')


  it 'should set the mode correctly for click', ->
    dd = new hx.Dropdown(id, content, {mode: 'click'})

    dd._.selection.node().__hx__.eventEmitter.has('click').should.equal(true)
    dd._.selection.node().__hx__.eventEmitter.has('mouseover').should.equal(false)
    dd._.selection.node().__hx__.eventEmitter.has('mouseout').should.equal(false)

    dd = new hx.Dropdown(id, content, {mode: 'hover'})
    dd._.selection.node().__hx__.eventEmitter.has('click').should.equal(true)
    dd._.selection.node().__hx__.eventEmitter.has('mouseover').should.equal(true)
    dd._.selection.node().__hx__.eventEmitter.has('mouseout').should.equal(true)


  it 'should set the alignment correctly', ->
    dd = new hx.Dropdown(id, content, {align: 'rbrb'})
    dd._.alignments.should.eql('rbrb'.split(''))

  it 'should use the right alignment option when a named align value is used', ->
    dd = new hx.Dropdown(id, content, {align: 'up'})
    dd._.alignments.should.eql('ltlb'.split(''))

    dd = new hx.Dropdown(id, content, {align: 'down'})
    dd._.alignments.should.eql('lblt'.split(''))

    dd = new hx.Dropdown(id, content, {align: 'left'})
    dd._.alignments.should.eql('ltrt'.split(''))

    dd = new hx.Dropdown(id, content, {align: 'right'})
    dd._.alignments.should.eql('rtlt'.split(''))

  it 'should set the spacing correctly', ->
    dd = new hx.Dropdown(id, content, {spacing: 10} )
    getSpacing(dd).should.equal(10)


  # it 'should use the spacing correctly', ->
  #   dd = new hx.Dropdown(id, content, {spacing: 10})
  #   dd.show()
  #   buttonBox = button.box()
  #   clock.tick(301)
  #   console.log(hx.select('body').node())
  #   ddBox = dd._.dropdown.box()
  #   ddBox.left.should.equal(buttonBox.left)
  #   ddBox.top.should.equal(buttonBox.top + buttonBox.height + getSpacing(dd))


  it 'should set the matchWidth property correctly', ->
    dd = new hx.Dropdown(id, content, {matchWidth: false} )
    dd.options.matchWidth.should.equal(false)

    dd = new hx.Dropdown(id, content, {matchWidth: true} )
    dd.options.matchWidth.should.equal(true)

  it 'should set the ddClass correctly', ->
    dd = new hx.Dropdown(id, content, { ddClass: 'bob' })
    dd.options.ddClass.should.equal('bob')

  it 'should call toggle the selector is clicked in click mode', ->
    dd = new hx.Dropdown(id, content)
    chai.spy.on(dd, 'toggle')
    dd._.selection.node().__hx__.eventEmitter.emit('click')
    dd.toggle.should.have.been.called()

  it 'should call show/hide on mouseover/mouseout in hover mode', ->
    dd = new hx.Dropdown(id, content, {mode: 'hover'})
    chai.spy.on(dd, 'show')
    chai.spy.on(dd, 'hide')
    chai.spy.on(dd, 'toggle')

    dd._.selection.node().__hx__.eventEmitter.emit('mouseover')
    dd.show.should.have.been.called()

    dd._.selection.node().__hx__.eventEmitter.emit('mouseout')
    dd.hide.should.have.been.called()

    dd._.selection.node().__hx__.eventEmitter.emit('click')
    dd.toggle.should.have.been.called()

  it 'should correctly detect if the dropdown is open', ->
    dd = new hx.Dropdown(id, content)
    dd.isOpen().should.equal(false)
    dd.show()
    dd.isOpen().should.equal(true)
    dd.hide()
    dd.isOpen().should.equal(false)
    dd.toggle()
    dd.isOpen().should.equal(true)
    dd.toggle()
    dd.isOpen().should.equal(false)

  it 'should exist on the page when opened and set the visible property to true', ->
    dd = new hx.Dropdown(id, content)
    dd._.visible.should.equal(false)
    hx.select('.hx-dropdown').empty().should.equal(true)

    dd._.selection.node().__hx__.eventEmitter.emit('click')

    dd._.visible.should.equal(true)
    hx.select('.hx-dropdown').empty().should.equal(false)
    hx.select('.hx-dropdown').html().should.equal(content)

  it 'should not do anything if show is called and the dropdown is already open', ->
    dd = new hx.Dropdown(id, content)
    dd._.visible.should.equal(false)
    hx.select('.hx-dropdown').empty().should.equal(true)

    dd.show()
    dd._.visible.should.equal(true)
    hx.select('.hx-dropdown').empty().should.equal(false)
    hx.select('.hx-dropdown').html().should.equal(content)

    dd.show()
    dd._.visible.should.equal(true)
    hx.select('.hx-dropdown').empty().should.equal(false)
    hx.select('.hx-dropdown').html().should.equal(content)

  it 'should not do anything if hide is called and the dropdown is already closed', ->
    dd = new hx.Dropdown(id, content)
    chai.spy.on(dd._.clickDetector, 'off')
    dd._.visible.should.equal(false)
    hx.select('.hx-dropdown').empty().should.equal(true)

    dd.hide()
    dd._.visible.should.equal(false)
    hx.select('.hx-dropdown').empty().should.equal(true)
    dd._.clickDetector.off.should.have.not.been.called()

  it 'should call the clean up the click detector', ->
    dd = new hx.Dropdown(id, content)
    chai.spy.on(dd._.clickDetector, 'cleanUp')
    dd.cleanUp()
    dd._.clickDetector.cleanUp.should.have.been.called()

  it 'should call hide when an element other than the button is clicked', ->
    dd = new hx.Dropdown(id, content)
    chai.spy.on(dd, 'hide')
    dd.show()
    document.__hx__.eventEmitter.emit('pointerdown', { event: {target: fixture.node()}})
    document.__hx__.eventEmitter.emit('pointerup', { event: {target: fixture.node()}})
    dd.hide.should.have.been.called()

  # it 'should detect parent z-index and set the index to be 1 greater', ->
  #   fixture.style('z-index', 100)
  #   dd = new hx.Dropdown(id, content)
  #   dd.show()
  #   dd._.dropdown.style('z-index').should.equal('101')

  it 'should detect parent position and match it correctly', ->
    fixture.style('position', 'fixed')

    dd = new hx.Dropdown(id, content)
    dd.show()
    dd._.dropdown.style('position').should.equal('fixed')

  it 'should render correctly using a function as content', ->
    populate = (elem) ->
      hx.select(elem).append('div').class('bob').text('Dave')

    dd = new hx.Dropdown(id, populate)

    dd.show()
    # uses fixture bg as hex gets converted to different things by different browsers
    dd._.dropdown.select('.bob').text().should.equal('Dave')


  it 'should class the dropdown with the supplied dd class', ->
    dd = new hx.Dropdown(id, content, {ddClass: 'bob'})
    dd.show()
    dd._.dropdown.classed('bob').should.equal(true)

  it 'should show and hide correctly', ->
    dd = new hx.Dropdown(id, content)

    dd._.visible.should.equal(false)
    hx.select('.hx-dropdown').empty().should.equal(true)

    dd.show()
    dd._.visible.should.equal(true)
    hx.select('.hx-dropdown').empty().should.equal(false)

    dd.hide()
    dd._.visible.should.equal(false)
    hx.select('.hx-dropdown').empty().should.equal(true)

  it 'should set the overflow style when the useScroll (private) option is specified', ->
    dd = new hx.Dropdown(id, content)
    dd._.useScroll = true
    dd.show()
    clock.tick(300)
    dd._.dropdown.style('overflow-y').should.equal('auto')

  it 'shouldnt try to match the width of the parent if matchWidth is false', ->
    button.text('Wider button for testing')
    bWidth = button.width()

    dd = new hx.Dropdown(id, content, {matchWidth: false })

    dd.show()
    dd._.dropdown.style('min-width').should.equal('0px')
    clock.tick(301)

  it 'should try to match the width of the parent if matchWidth is true', ->
    button.text('Wider button for testing')

    dd = new hx.Dropdown(id, content, {matchWidt: true })

    dd.show()
    dd._.dropdown.style('min-width').should.equal(button.style('width'))
    clock.tick(301)

  # it 'should detect the maxHeight properly', ->
  #   hx.select('head').append('style').attr('id','style').attr('type', 'text/css').text("""
  #     .hx-dropdown{
  #       max-height: 5px;
  #     }
  #   """)

  #   buttonBox = roundAll button.box()

  #   dd = new hx.Dropdown(id, content)
  #   dd.show()
  #   setTimeout ->
  #     ddBox = roundAll dd._.dropdown.box()
  #     dd._.dropdown.style('max-height').should.equal('5px')
  #     ddBox.left.should.equal(buttonBox.left)
  #     ddBox.height.should.equal(5)
  #     hx.select('#style').remove()
  #   , 300
  #   clock.tick(301)

  it 'should shift the dropdown down if shifting it up has moved it off the top of the screen', ->
    dd = new hx.Dropdown(id, content, {align: 'up'})

    button.style('top', '5px')

    buttonBox = roundAll button.box()
    dd.show()
    setTimeout ->
      ddBox = roundAll dd._.dropdown.box()
      ddBox.top.should.equal(buttonBox.top + buttonBox.height + getSpacing(dd))
      ddBox.left.should.equal(buttonBox.left)
    , 300
    clock.tick(301)


  describe 'align', ->
    button = undefined
    buttonBox = undefined
    dd = undefined
    ddBox = undefined

    beforeEach ->
      buttonBox = roundAll button.box()

    describe 'should align correctly when align is set to', ->
      tests = [
          align: null
          check: ->
            ddBox.left.should.equal(buttonBox.left)
            ddBox.top.should.equal(buttonBox.bottom + getSpacing(dd))
        ,
          align: 'up'
          check: ->
            ddBox.left.should.equal(buttonBox.left)
            ddBox.top.should.equal(buttonBox.top - ddBox.height - getSpacing(dd))
        ,
          align: 'down'
          check: ->
            ddBox.left.should.equal(buttonBox.left)
            ddBox.top.should.equal(buttonBox.bottom + getSpacing(dd))
        ,
          align: 'left'
          check: ->
            ddBox.right.should.equal(buttonBox.left - getSpacing(dd))
            ddBox.top.should.equal(buttonBox.top)
        ,
          align: 'right'
          check: ->
            ddBox.left.should.equal(buttonBox.right + getSpacing(dd))
            ddBox.top.should.equal(buttonBox.top)
        ,
          align: 'lbrb'
          check: ->
            ddBox.right.should.equal(buttonBox.left - getSpacing(dd))
            ddBox.bottom.should.equal(buttonBox.bottom)
        ,
          align: 'lbrt'
          check: ->
            ddBox.right.should.equal(buttonBox.left - getSpacing(dd))
            ddBox.top.should.equal(buttonBox.top + buttonBox.height + getSpacing(dd))
        ,
          align: 'ltrb'
          check: ->
            ddBox.right.should.equal(buttonBox.left - getSpacing(dd))
            ddBox.bottom.should.equal(buttonBox.top - getSpacing(dd))
        ,
          align: 'rblt'
          check: ->
            ddBox.left.should.equal(buttonBox.right + getSpacing(dd))
            ddBox.top.should.equal(buttonBox.bottom + getSpacing(dd))
        ,
          align: 'rblb'
          check: ->
            ddBox.left.should.equal(buttonBox.right + getSpacing(dd))
            ddBox.bottom.should.equal(buttonBox.bottom)
        ,
          align: 'rbrt'
          check: ->
            ddBox.right.should.equal(buttonBox.right)
            ddBox.top.should.equal(buttonBox.bottom + getSpacing(dd))
        ,
          align: 'rtlb'
          check: ->
            ddBox.left.should.equal(buttonBox.right + getSpacing(dd))
            ddBox.top.should.equal(buttonBox.top - ddBox.height - getSpacing(dd))
        ,
          align: 'rtrb'
          check: ->
            ddBox.right.should.equal(buttonBox.right)
            ddBox.bottom.should.equal(buttonBox.top - getSpacing(dd))
      ]

      t = (test, index) ->
        it test.align, ->
          dd = new hx.Dropdown(id, content, {
            align: test.align or undefined
          })
          dd.show()
          setTimeout ->
            ddBox = roundAll dd._.dropdown.box()
            test.check()
          , 300
          clock.tick(301)

        if index < tests.length
          t(tests[index], index + 1)

      t(tests[0], 1)


    describe 'shouldnt flow outside the screen when the dropdown is on the', ->
      scrollbarWidth = hx.scrollbarSize()
      moveBy = 10000

      tests = [
        pos: 'left'
        check: ->
          ddBox.left.should.equal(0)
      ,
        pos: 'top'
        check: ->
          ddBox.top.should.equal(0)
      ,
        pos: 'right'
        check: ->
          ddBox.left.should.equal(window.innerWidth - ddBox.width - scrollbarWidth)
      ,
        pos: 'bottom'
        check: ->
          ddBox.top.should.equal(window.innerHeight - ddBox.height)
      ]

      t = (test, index) ->
        it ': ' + test.pos, ->
          button.style('top', '')
            .style('right', '')
            .style('bottom', '')
            .style('left', '')
            .style('left', '')
            .style('margin-left', '')
            .style('margin-top', '')
            .style(test.pos, '-' + moveBy + 'px')

          dd = new hx.Dropdown(id, content)
          dd.show()
          setTimeout ->
            ddBox = roundAll dd._.dropdown.box()
            test.check()
          , 300
          clock.tick(301)

        if index < tests.length
          t(tests[index], index + 1)

      t(tests[0], 1)

    describe 'shouldnt overlap the parent element when align is set to', ->
      tests = [
        align: 'rbrb'
        check: ->
          ddBox.top.should.equal(buttonBox.bottom + getSpacing(dd))
          ddBox.right.should.equal(buttonBox.right)
      ,
        align: 'lblb'
        check: ->
          ddBox.top.should.equal(buttonBox.bottom + getSpacing(dd))
          ddBox.left.should.equal(buttonBox.left)
      ,
        align: 'rtrt'
        check: ->
          ddBox.bottom.should.equal(buttonBox.top - getSpacing(dd))
          ddBox.right.should.equal(buttonBox.right)
      ,
        align: 'ltlt'
        check: ->
          ddBox.bottom.should.equal(buttonBox.top - getSpacing(dd))
          ddBox.left.should.equal(buttonBox.left)
      ,
        align: 'cover'
        check: ->
          ddBox.top.should.equal(buttonBox.bottom + getSpacing(dd))
          ddBox.left.should.equal(buttonBox.left)
      ]

      t = (test, index) ->
        it test.align, ->
          if test.align is 'cover'
            test.align = null
            coverContent = '<div style="width:200px; height: 100px">Content</div>'
          dd = new hx.Dropdown(id, coverContent or content, {align: test.align or undefined })
          dd.show()
          setTimeout ->
            ddBox = roundAll dd._.dropdown.box()
            test.check()
          , 300
          clock.tick(301)

        if index < tests.length
          t(tests[index], index + 1)

      t(tests[0], 1)
