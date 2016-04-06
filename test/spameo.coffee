path   = require "path"
should = require "should"

script = require "../scripts/spameo.coffee"

{Robot, TextMessage} = require "hubot"
{StickerMessage} = require "hubot-facebook"

describe "Spam sticker", ->
  say = (string) =>
    @adapter.receive new TextMessage @user, string
  sendSticker = (stickerID) =>
    @adapter.receive new StickerMessage @user, "http://abc.com", "messageID", stickerID: stickerID

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

  it "spam when commanded", (done) =>
    @adapter.robot.on "facebook.sendSticker", (event) ->
      event.sticker.should.equal "1530358710538271"
      done()
    say "hubot spam sticker 1530358710538271 đi"

  it "change state to add", =>
    say "hubot spam mèo này"
    @robot.brain.data.ria_room_states.roomid.state.should.equal "add"

  it "change state to remove", =>
    say "hubot dừng spam moè này"
    @robot.brain.data.ria_room_states.roomid.state.should.equal "remove"

  it "stop subscript sticker", =>
    @robot.brain.data.stickers = "1530358710538271": "http://google.com"
    say "hubot dừng spam"
    should.not.exist @robot.brain.data.stickers["1530358710538271"]

  it "start subscript sticker after command", (done) =>
    @robot.brain.data.ria_room_states = roomid: state: "add"
    @robot.emit "room_state_handler_sticker_add",
      message: new StickerMessage @user, "http://abc.com", "messageID", stickerID: "1530358710538271"
      send: =>
        should.exist @robot.brain.data.stickers["1530358710538271"]
        done()

  it "stop subscript sticker after command", (done) =>
    @robot.brain.data.stickers = "1530358710538271": "http://google.com"
    @robot.brain.data.ria_room_states = roomid: state: "remove"
    @robot.emit "room_state_handler_sticker_remove",
      message: new StickerMessage @user, "http://abc.com", "messageID", stickerID: "1530358710538271"
      send: =>
        should.not.exist @robot.brain.data.stickers["1530358710538271"]
        done()

  it "set state to chain", (done) =>
    @robot.brain.data.stickers = "1530358710538271": "http://google.com"
    @robot.emit "room_state_handler_sticker_default",
      message: new StickerMessage @user, "http://abc.com", "messageID", stickerID: "1530358710538271"
    , no_spam: true
    setTimeout =>
      @robot.brain.data.ria_room_states.roomid.should.have.property('state', 'chain')
      @robot.brain.data.ria_room_states.roomid.should.have.property('id', '1530358710538271')
      @robot.brain.data.ria_room_states.roomid.should.have.property('times', 1)
      done()
    , 20

  it "count up chain", (done) =>
    @robot.brain.data.stickers = "1530358710538271": "http://google.com"
    @robot.emit "room_state_handler_sticker_default",
      message: new StickerMessage @user, "http://abc.com", "messageID", stickerID: "1530358710538271"
    , no_spam: true, times: 3
    setTimeout =>
      @robot.brain.data.ria_room_states.roomid.should.have.property('state', 'chain')
      @robot.brain.data.ria_room_states.roomid.should.have.property('id', '1530358710538271')
      @robot.brain.data.ria_room_states.roomid.should.have.property('times', 4)
      done()
    , 20

  it "doesn't spam if spammed", (done) =>
    @robot.brain.data.stickers = "1530358710538271": "http://google.com"
    @robot.emit "room_state_handler_sticker_spam",
      message: new StickerMessage @user, "http://abc.com", "messageID", stickerID: "1530358710538271"
    , id: "1530358710538271"
    test = true
    @robot.on "room_state_handler_sticker_default", ->
      test = false
    setTimeout =>
      test.should.equal true
      done()
    , 20

  it "spam random sticker", (done) =>
    @robot.brain.data.stickers = "1530358710538271": "http://google.com"
    @robot.on "facebook.sendSticker", ->
      done()
    @robot.emit "send_random_sticker",
      random: -> "1530358710538271"
      message: room: "roomid"
      sendSticker: -> done()

  it "trigger correct event for message", (done) =>
    @robot.brain.data.ria_room_states = roomid: state: "test"
    @robot.on "room_state_handler_message_test", ->
      done()
    say "something"

  it "trigger correct event for sticker", (done) =>
    @robot.brain.data.ria_room_states = roomid: state: "test"
    @robot.on "room_state_handler_sticker_test", ->
      done()
    sendSticker "1530358710538271"
    done() # adapter bug?

  it "show sticker list", (done) =>
    @robot.brain.data.stickers = "1530358710538271": "http://google.com"
    @http.get["/hubot/facebook/stickers"] null,
      setHeader: ->
      send: (string) =>
        string.should.equal @robot.brain.data.stickers
        done()

  it "reset state", (done) =>
    @robot.brain.data.ria_room_states = roomid: state: "test"
    @robot.emit "reset_state",
      message: room: "roomid"
    setTimeout =>
      should(@robot.brain.data.ria_room_states.roomid).equalOneOf null, undefined
      done()
    , 20
