describe 'hx-view', ->
  origConsoleWarning = hx.consoleWarning

  beforeEach ->
    hx.consoleWarning = chai.spy()

  afterEach ->
    hx.consoleWarning = origConsoleWarning

  it "should create elements of a given type using the default view enter fn", ->
    selection = hx.detached('div')
    selection.view('element-type').apply([1..3])
    selection.selectAll('element-type').size().should.equal(3)
    hx.consoleWarning.should.not.have.been.called()

  it "should create elements of a given class using the default view enter fn", ->
    selection = hx.detached('div')
    selection.view('.class').apply([1..3])
    selection.selectAll('.class').size().should.equal(3)
    hx.consoleWarning.should.not.have.been.called()

  it "should create slightly more complicated elements with the default view enter fn", ->
    selection = hx.detached('div')
    selection.view('element-type.class-onion.class-lemon').apply([1..3])
    selection.selectAll('element-type.class-onion.class-lemon').size().should.equal(3)
    hx.consoleWarning.should.not.have.been.called()

  it "should show a warning when the returned element does not match the selector passed in", ->
    selection = hx.detached('div')
    selection.view('.class')
      .enter (datum) -> @append('div').node()
      .apply([1..3])
    hx.consoleWarning.should.have.been.called()

  it "should show a warning when the returned element does not match the selector passed in with extra classes added", ->
    selection = hx.detached('div')
    selection.view('.class')
      .enter (datum) -> @append('div').class('dave').node()
      .apply([1..3])
    hx.consoleWarning.should.have.been.called()

  it "should show a warning when the returned element is not a child of the view", ->
    selection = hx.detached('div')
    selection.view('.class')
      .enter (datum) -> hx.detached('div').class('class').node()
      .apply([1..3])
    hx.consoleWarning.should.have.been.called()

  it "should support update functions", ->
    selection = hx.detached('div')

    selection.view('.class')
      .update (datum, node) -> hx.select(node).text(datum + 1)
      .apply([1..3])

    selection.selectAll('.class').text().should.eql(["2", "3", "4"])
    hx.consoleWarning.should.not.have.been.called()

  it "should create additional elements as needed", ->
    selection = hx.detached('div')

    selection.view('.class')
      .update (datum, node) -> hx.select(node).text(datum + 1)
      .apply([1..3])
      .apply([1..4])

    selection.selectAll('.class').text().should.eql(["2", "3", "4", "5"])
    hx.consoleWarning.should.not.have.been.called()

  it "should remove additional elements as needed", ->
    selection = hx.detached('div')

    selection.view('.class')
      .update (datum, node) -> hx.select(node).text(datum + 1)
      .apply([1..3])
      .apply([1..2])

    selection.selectAll('.class').text().should.eql(["2", "3"])
    hx.consoleWarning.should.not.have.been.called()

  it "should index correctly when entering nodes", ->
    selection = hx.detached('div')

    spy = chai.spy()
    view = selection.view('div')
      .enter (datum, index) ->
        spy(datum, index)
        @append('div').node()

    spy.should.not.have.been.called()
    view.apply([1..3])
    spy.should.have.been.called.exactly(3)
    spy.should.have.been.called.with(1, 0)
    spy.should.have.been.called.with(2, 1)
    spy.should.have.been.called.with(3, 2)
    spy.reset()
    view.apply([1..4])
    spy.should.have.been.called.exactly(1)
    spy.should.have.been.called.with(4, 0)
    hx.consoleWarning.should.not.have.been.called()

  it "should index correctly when updating nodes", ->
    selection = hx.detached('div')

    spy = chai.spy()
    view = selection.view('div')
      .update (datum, node, index) ->
        spy(datum, index)

    spy.should.not.have.been.called()
    view.apply([1..3])
    spy.should.have.been.called.exactly(3)
    spy.should.have.been.called.with(1, 0)
    spy.should.have.been.called.with(2, 1)
    spy.should.have.been.called.with(3, 2)
    spy.reset()
    view.apply([1..4])
    spy.should.have.been.called.exactly(4)
    spy.should.have.been.called.with(1, 0)
    spy.should.have.been.called.with(2, 1)
    spy.should.have.been.called.with(3, 2)
    spy.should.have.been.called.with(4, 3)
    hx.consoleWarning.should.not.have.been.called()