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
    @http.get["/hubot/github/evolution"] null,
      setHeader: ->
      send: (data) ->
    setTimeout =>
      done()
    , 20

  it "return if locked", (done) =>
    @robot.brain.data.ria_code_states = files: {}, locked: true
    @robot.on "run_evolution", (res) ->
      res.fail()
    @http.get["/hubot/github/evolution"] null,
      setHeader: ->
      send: (data) ->
    setTimeout =>
      done()
    , 20

  it "add hubot scripts", (done) =>
    @robot.brain.data.ria_code_states = files: "hubot-scripts.json": content: JSON.stringify ["abc", "foo"]
    @robot.emit "prepair_to_evolution_add_hutbot_scripts", null, ["foo", "xyz"], =>
      @robot.brain.data.ria_code_states.files.should.deepEqual "hubot-scripts.json": content: "#{JSON.stringify ["abc", "foo", "xyz"], null, 2}\n"
      done()

  it "add external scripts", (done) =>
    @robot.brain.data.ria_code_states = files: "external-scripts.json": content: JSON.stringify ["abc", "foo"]
    @robot.emit "prepair_to_evolution_add_external_scripts", null, ["foo", "xyz"], =>
      @robot.brain.data.ria_code_states.files.should.deepEqual "external-scripts.json": content: "#{JSON.stringify ["abc", "foo", "xyz"], null, 2}\n"
      done()

  it "add dependency package", (done) =>
    @robot.brain.data.ria_code_states = files: "package.json": content: JSON.stringify dependencies: abc: "*", xyz: "0.0.1"
    @robot.emit "prepair_to_evolution_add_package", null, {test: "1.2.3", xyz: "0.1.0"}, =>
      @robot.brain.data.ria_code_states.files.should.deepEqual "package.json": content: "#{JSON.stringify dependencies: abc: "*", xyz: "0.1.0", test: "1.2.3", null, 2}\n"
      done()
