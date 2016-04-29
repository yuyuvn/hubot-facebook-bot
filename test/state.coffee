should = require "should"

{CachedData, Stickers, RoomState, UserState} = require "../lib/state"
{Robot, TextMessage} = require "hubot"
{StickerMessage} = require "hubot-facebook"

describe "State", ->
  say = (string) =>
    @adapter.receive new TextMessage @user, string
  sendSticker = (stickerID) =>
    @adapter.receive new StickerMessage @user, "http://abc.com", "messageID", stickerID: stickerID

  beforeEach (done) =>
    @http = get: {}, post: {}
    @robot = new Robot null, "mock-adapter", false, "hubot"
    @robot.adapter.on "connected", =>
      @user = @robot.brain.userForId "1", name: "username", room: "roomid"
      @adapter = @robot.adapter
      done()
    @robot.run()

  afterEach =>
    @robot.shutdown()

  context "Cached data", =>
    beforeEach =>
      @data = new CachedData @robot, "test"

    afterEach =>
      @data.clean()
      delete @data

    it "get raw_data", =>
      @robot.brain.data.test = "abc"
      @data.raw_data().should.equal "abc"

    it "return empty hash if data is not provided", =>
      @data.raw_data().should.be.empty()

    it "can extend object", =>
      @robot.brain.data.test = test: "value"
      @data.extend test2: "value2", test3: child: "value"
      @robot.brain.data.test.should.deepEqual test: "value", test2: "value2", test3: child: "value"

    it "overwrite value when extend", =>
      @robot.brain.data.test = test: child1: "value1", child2: "value2"
      @data.extend test: child1: "new value", child3: "value3"
      @robot.brain.data.test.should.deepEqual test: child1: "new value", child2: "value2", child3: "value3"

    it "get value", =>
      @robot.brain.data.test = "abc"
      @data.get().should.equal "abc"

    it "get value from path", =>
      @robot.brain.data.test = test: "abc"
      @data.get("test").should.equal "abc"

    it "return null when value is not existed", =>
      @data.get().should.be.empty()
      should(@data.get("test")).null()
      @robot.brain.data.test = "abc"
      should(@data.get("test", "test2", "test3")).null()

    it "can set value", =>
      @data.set "value"
      @robot.brain.data.test.should.equal "value"

    it "can set value from path", =>
      @data.set "value", "path1", "path2"
      @robot.brain.data.test.should.deepEqual path1: path2: "value"

    it "not overwrite value if not need", =>
      @robot.brain.data.test = test: child1: "abc", child2: "xyz"
      @data.set "value", "test", "child3"
      @robot.brain.data.test.should.deepEqual test: child1: "abc", child2: "xyz", child3: "value"

    it "remove data", =>
      @robot.brain.data.test = test: "value"
      @data.remove()
      @robot.brain.data.test.should.be.empty()
      @robot.brain.data.test = test: child1: "value1", child2: "value2"
      @data.remove "test", "child1"
      @robot.brain.data.test.should.deepEqual test: child2: "value2"

    it "not throw if delete not existed data", =>
      @robot.brain.data.test = test: "value"
      @data.remove "test", "test2"
      @robot.brain.data.test.should.deepEqual test: "value"

    it "clean data", =>
      @robot.brain.data.test = test: "value"
      @data.clean()
      @robot.brain.data.test.should.be.empty()

    it "set data without set method", =>
      @robot.brain.data.test = test: child1: "abc", child2: "xyz"
      data = @data.get "test"
      data.child1 = "foo"
      @robot.brain.data.test.should.deepEqual test: child1: "foo", child2: "xyz"

  context "Stickers", =>
    beforeEach =>
      @stickers = new Stickers @robot

    afterEach =>
      delete @stickers

    it "subscribe sticker", =>
      @stickers.subscribe("id", "url").should.not.be.false()
      @robot.brain.data.stickers.id.should.equal "url"
      @stickers.subscribe("id", "url").should.be.false()

    it "unsubscribe sticker", =>
      @stickers.unsubscribe("id").should.be.false()
      @robot.brain.data.stickers = id: "url"
      @stickers.unsubscribe("id").should.not.be.false()
      should(@robot.brain.data.stickers.id).equalOneOf null, undefined

    it "unsubscribe_all all", =>
      @stickers.unsubscribe_all().should.be.false()
      @robot.brain.data.stickers = id1: "url1", id2: "url2"
      @stickers.unsubscribe_all().should.not.be.false()
      @robot.brain.data.stickers.should.be.empty()

    it "return list of subscribing sticker id", =>
      @robot.brain.data.stickers = id1: "url1", id2: "url2"
      @stickers.subscribing().should.deepEqual ["id1","id2"]

    it "return state of sticker", =>
      @robot.brain.data.stickers = id: "url"
      @stickers.subscribing("id").should.equal "url"
      should(@stickers.subscribing("id2")).null()

  context "RoomState", =>
    beforeEach =>
      @state = new RoomState @robot, "test"

    afterEach =>
      delete @state

    it "trigger default message event", (done) =>
      @robot.on "ria_room_states_test_message_default", -> done()
      @robot.on "ria_room_states_test_sticker_default", -> throw "should not called"
      say "abc"

    it "trigger default sticker event", (done) =>
      @robot.on "ria_room_states_test_message_default", -> throw "should not called"
      @robot.on "ria_room_states_test_sticker_default", -> done()
      sendSticker "123"

    it "trigger correct message event", (done) =>
      @robot.brain.data.ria_room_states_test = roomid: state: "foo"
      @robot.on "ria_room_states_test_message_default", -> throw "should not called"
      @robot.on "ria_room_states_test_sticker_default", -> throw "should not called"
      @robot.on "ria_room_states_test_message_foo", -> done()
      @robot.on "ria_room_states_test_sticker_foo", -> throw "should not called"
      say "abc"

    it "trigger correct message event", (done) =>
      @robot.brain.data.ria_room_states_test = roomid: state: "foo"
      @robot.on "ria_room_states_test_message_default", -> throw "should not called"
      @robot.on "ria_room_states_test_sticker_default", -> throw "should not called"
      @robot.on "ria_room_states_test_message_foo", -> throw "should not called"
      @robot.on "ria_room_states_test_sticker_foo", -> done()
      sendSticker "123"

  context "UserState", =>
    beforeEach =>
      @state = new UserState @robot, "test"

    afterEach =>
      delete @state

    it "trigger default message event", (done) =>
      @robot.on "ria_user_states_test_message_default", -> done()
      @robot.on "ria_user_states_test_sticker_default", -> throw "should not called"
      say "abc"

    it "trigger default sticker event", (done) =>
      @robot.on "ria_user_states_test_message_default", -> throw "should not called"
      @robot.on "ria_user_states_test_sticker_default", -> done()
      sendSticker "123"

    it "trigger correct message event", (done) =>
      @robot.brain.data.ria_user_states_test = "1": state: "foo"
      @robot.on "ria_user_states_test_message_default", -> throw "should not called"
      @robot.on "ria_user_states_test_sticker_default", -> throw "should not called"
      @robot.on "ria_user_states_test_message_foo", -> done()
      @robot.on "ria_user_states_test_sticker_foo", -> throw "should not called"
      say "abc"

    it "trigger correct message event", (done) =>
      @robot.brain.data.ria_user_states_test = "1": state: "foo"
      @robot.on "ria_user_states_test_message_default", -> throw "should not called"
      @robot.on "ria_user_states_test_sticker_default", -> throw "should not called"
      @robot.on "ria_user_states_test_message_foo", -> throw "should not called"
      @robot.on "ria_user_states_test_sticker_foo", -> done()
      sendSticker "123"
