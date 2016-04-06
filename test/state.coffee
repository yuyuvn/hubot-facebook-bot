path   = require "path"
should = require "should"

{CachedData, State} = require "../lib/state"
{Robot} = require "hubot"

describe "State", ->
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

  context "State", =>
    beforeEach =>
      @state = new State @robot

    afterEach =>
      @state.room.clean()
      @state.code.clean()
      @state.stickers.unsubscribe_all()
      delete @state

    it "create datas", =>
      @state.room.should.not.be.null()
      @state.code.should.not.be.null()
      @state.stickers.should.not.be.null()

    it "subscribe sticker", =>
      @state.stickers.subscribe("id", "url").should.not.be.false()
      @robot.brain.data.stickers.id.should.equal "url"
      @state.stickers.subscribe("id", "url").should.be.false()

    it "unsubscribe sticker", =>
      @state.stickers.unsubscribe("id").should.be.false()
      @robot.brain.data.stickers = id: "url"
      @state.stickers.unsubscribe("id").should.not.be.false()
      should(@robot.brain.data.stickers.id).equalOneOf null, undefined

    it "unsubscribe_all all", =>
      @state.stickers.unsubscribe_all().should.be.false()
      @robot.brain.data.stickers = id1: "url1", id2: "url2"
      @state.stickers.unsubscribe_all().should.not.be.false()
      @robot.brain.data.stickers.should.be.empty()

    it "return list of subscribing sticker id", =>
      @robot.brain.data.stickers = id1: "url1", id2: "url2"
      @state.stickers.subscribing().should.deepEqual ["id1","id2"]

    it "return state of sticker", =>
      @robot.brain.data.stickers = id: "url"
      @state.stickers.subscribing("id").should.equal "url"
      should(@state.stickers.subscribing("id2")).null()
