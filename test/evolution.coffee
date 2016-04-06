path   = require "path"
should = require "should"

script = require "../scripts/evolution.coffee"

{Robot, TextMessage} = require "hubot"

describe "Evolution", ->
  beforeEach (done) =>
    @http = get: {}, post: {}
    @robot = new Robot null, "mock-adapter", false, "hubot"
    @robot.adapter.on "connected", =>
      @robot.router =
        get: (uri, cb) => @http.get[uri] = cb
        post: (uri, cb) => @http.post[uri] = cb
      script(@robot)
      @user = @robot.brain.userForId "1", name: "username", room: "roomid"
      @adapter = @robot.adapter
      done()
    @robot.run()

  afterEach =>
    @robot.shutdown()

  it "create debug page", (done) =>
    @robot.brain.data.ria_code_states = test: "test"
    @http.get["/hubot/github/evolution/debug"] null,
      setHeader: ->
      send: (data) ->
        data.should.deepEqual test: "test"
        done()

  it "return if nothing to code", (done) =>
    @robot.on "run_evolution", (res) ->
      res.fail()
    @http.post["/hubot/github/evolution"] null,
      setHeader: ->
      send: (data) ->
    setTimeout =>
      done()
    , 20

  it "return if locked", (done) =>
    @robot.brain.data.ria_code_states = files: {}, locked: true
    @robot.on "run_evolution", (res) ->
      res.fail()
    @http.post["/hubot/github/evolution"] null,
      setHeader: ->
      send: (data) ->
    setTimeout =>
      done()
    , 20
