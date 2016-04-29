should = require "should"

script = require "../scripts/youtube.coffee"

{Robot, TextMessage} = require "hubot"

describe "Spam sticker", ->
  say = (string) =>
    @adapter.receive new TextMessage @user, string

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

  it "should store message to brain", () =>
    say "hubot lên youtube live spam lalala"
    @robot.brain.data.youtube.should.deepEqual message: "lalala"

  it "should remove message from brain", () =>
    say "hubot stream xong rồi"
    should(@robot.brain.data.youtube).equal null
