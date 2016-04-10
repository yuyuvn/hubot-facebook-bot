path   = require "path"
should = require "should"

script = require "../scripts/command_parser.coffee"
escapeStringRegexp = require "escape-string-regexp"

{Robot, TextMessage} = require "hubot"
{StickerMessage} = require "hubot-facebook"

describe "Parse command", ->
  say = (string) =>
    @adapter.receive new TextMessage @user, string

  to = (string) =>
    @adapter.receive new TextMessage @user, "hubot #{string}"

  beforeEach (done) =>
    @http = get: {}, post: {}
    @robot = new Robot null, "mock-adapter", false, "hubot"
    @robot.adapter.on "connected", =>
      @robot.router =
        get: (uri, cb) => @http.get[uri] = cb
        post: (uri, cb) => @http.post[uri] = cb
      script @robot
      @user = @robot.brain.userForId "1", name: "username", room: "roomid"
      @adapter = @robot.adapter
      @robot.brain.data.ria_room_states_command_parser = {}
      done()
    @robot.run()

  afterEach =>
    @robot.shutdown()

  context "receive command", =>
    it "reset state", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn"
      @robot.emit "reset_state_cp", message: room: "roomid"
      setTimeout =>
        @robot.brain.data.ria_room_states_command_parser.should.empty()
        done()
      , 20

    it "start learn", (done) =>
      @robot.on "facebook.sendSticker", =>
        @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn"
        done()
      to "bắt đầu học nào"

    it "show current state", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn"
      @http.get["/hubot/self_programming/:room"] {params: room: "roomid"},
        setHeader: ->
        send: (code) =>
          code.should.equal "learn"
          done()

    it "show queued code", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn", data: code: "abc"
      @http.get["/hubot/self_programming/:room"] {params: room: "roomid"},
        setHeader: ->
        send: (code) =>
          code.should.equal "abc"
          done()

  context "stop lesson", =>
    beforeEach (done) =>
      to "bắt đầu học nào"
      setTimeout =>
        done()
      , 20

    it "confirm end lesson", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn"
      @robot.emit "finish_learning",
        message: text: "abc"
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.old_state.should.equal "learn"
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn_wait_for_finish_confirm"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "confirm end lesson 2", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn"
      @robot.emit "ria_room_states_command_parser_message_learn",
        message: text: "abc"
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.old_state.should.equal "learn"
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn_wait_for_finish_confirm"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "confirm end lesson 3", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn_wait_for_subject"
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_subject",
        message: text: "abc"
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.old_state.should.equal "learn_wait_for_subject"
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn_wait_for_finish_confirm"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "confirm end lesson 4", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn_wait_for_condition_input"
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_input",
        message: text: "abc"
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.old_state.should.equal "learn_wait_for_condition_input"
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn_wait_for_finish_confirm"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "confirm end lesson 5", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn_wait_for_condition_or_action"
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_or_action",
        message: text: "abc"
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.old_state.should.equal "learn_wait_for_condition_or_action"
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn_wait_for_finish_confirm"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "confirm end lesson 6", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn_wait_for_condition_statement"
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_statement",
        message: text: "abc"
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.old_state.should.equal "learn_wait_for_condition_statement"
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn_wait_for_finish_confirm"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "don't change state", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = state: "learn_wait_for_action_statement"
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_action_statement",
        message: text: "abc"
        random: (array) -> array[0]
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "learn_wait_for_action_statement"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "restore state after cancel confirm", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = old_state: "abc"
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_finish_confirm",
        message: text: "không"
        random: (array) -> array[0]
        send: =>
          @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "abc"
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "restore state after cancel confirm 2", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid = old_state: "abc"
      @robot.on "facebook.sendSticker", (msg, sticker) =>
        @robot.brain.data.ria_room_states_command_parser.roomid.state.should.equal "abc"
        done()
      @robot.emit "ria_room_states_command_parser_sticker_learn_wait_for_finish_confirm",
        message: fields: stickerID: "1530358467204962"
        random: (array) -> array[0]
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "cancel lesson", (done) =>
      @robot.on "reset_state_cp", =>
        done()
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_finish_confirm",
        message: text: "hubot ừ"
        random: (array) -> array[0]
        send: ->
      , {}

    it "cancel lesson 2", (done) =>
      @robot.on "reset_state_cp", =>
        done()
      @robot.emit "ria_room_states_command_parser_sticker_learn_wait_for_finish_confirm",
        message: fields: stickerID: "1530358710538271"
        random: (array) -> array[0]
        send: ->
      , {}

  context "completed code", =>
    beforeEach =>
      @robot.brain.data.ria_room_states_command_parser.roomid = code: "abc"

    it "do not save code if locked", (done) =>
      @robot.brain.data.ria_code_states = locked: true
      @robot.emit "prepair_to_evolution",
        send: =>
          @robot.brain.data.ria_code_states.should.deepEqual locked: true
          done()
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "reset state after prepair code", (done) =>
      @robot.on "reset_state_cp", =>
        done()
      @robot.emit "prepair_to_evolution",
        send: ->
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "add script to hutbot_scripts", (done) =>
      @robot.on "prepair_to_evolution_add_hutbot_scripts", (msg, data) =>
        data.should.have.length 1
        done()
      @robot.emit "prepair_to_evolution",
        send: ->
      , @robot.brain.data.ria_room_states_command_parser.roomid

    it "prepair code", (done) =>
      @robot.brain.data.ria_room_states_command_parser.roomid.hook_root = "xyz"
      @robot.on "reset_state_cp", =>
        for name, content of @robot.brain.data.ria_code_states.files
          content.should.match new RegExp escapeStringRegexp "emo = require(\"../lib/emotion\").Singleton()"
          content.should.match new RegExp escapeStringRegexp "semantic = require(\"../lib/semantic\").Singleton()"
          content.should.match new RegExp escapeStringRegexp "{State} = require \"../lib/state\""
          content.should.match new RegExp escapeStringRegexp "module.exports = (robot) ->"
          content.should.match new RegExp escapeStringRegexp "room: new RoomState robot, "
          content.should.match /abc/
          content.should.match /xyz/
          name.should.match /^scripts\/.+\.coffee$/
        done()
      @robot.emit "prepair_to_evolution",
        send: ->
      , @robot.brain.data.ria_room_states_command_parser.roomid

  context "parser", =>
    beforeEach (done) =>
      to "bắt đầu học nào"
      @state = @robot.brain.data.ria_room_states_command_parser.roomid = {}
      setTimeout =>
        done()
      , 20

    it "swallow start token", (done) =>
      @robot.emit "ria_room_states_command_parser_message_learn",
        message: text: "nếu"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [], ops: []
        @state.state.should.equal "learn_wait_for_subject"
        done()
      , 20

    it "swallow subject token", (done) =>
      @state.data = conditions: [], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_subject",
        message: text: "anh nói"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói"], ops: []
        @state.state.should.equal "learn_wait_for_condition_input"
        done()
      , 20

    it "swallow object token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_input",
        message: text: "/haha/i"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
        @state.state.should.equal "learn_wait_for_condition_or_action"
        done()
      , 20

    it "swallow object token 2", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói"], ops: []
      @robot.emit "ria_room_states_command_parser_sticker_learn_wait_for_condition_input",
        message: fields: stickerID: "123"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/123/"], ops: []
        @state.state.should.equal "learn_wait_for_condition_or_action"
        done()
      , 20

    it "swallow or token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_or_action",
        message: text: "hoặc"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: ["or"]
        @state.state.should.equal "learn_wait_for_condition_statement"
        done()
      , 20

    it "swallow then token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_or_action",
        message: text: "sau đó"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: ["then"]
        @state.state.should.equal "learn_wait_for_condition_statement"
        done()
      , 20

    it "swallow do token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_or_action",
        message: text: "thì"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
        @state.state.should.equal "learn_wait_for_action_statement"
        done()
      , 20

    it "parse condition statement", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: ["or"]
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_statement",
        message: text: "bảo"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [{subject: "anh", verb: "nói", object: "/haha/i"}, verb: "bảo"], ops: ["or"]
        @state.state.should.equal "learn_wait_for_condition_input"
        done()
      , 20

    it "swallow eval token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_action_statement",
        message: text: "chạy đoạn mã này"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
        @state.state.should.equal "learn_wait_for_eval_code"
        done()
      , 20

    it "swallow respond token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_action_statement",
        message: text: "trả lời"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
        @state.state.should.equal "learn_wait_for_print_message"
        done()
      , 20

    it "swallow spam sticker token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_action_statement",
        message: text: "spam sticker "
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
        @state.state.should.equal "learn_wait_for_sticker_message"
        done()
      , 20

    it "swallow show emotion token", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_action_statement",
        message: text: "thể hiện cảm xúc này"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
        @state.state.should.equal "learn_wait_for_sticker_emo"
        done()
      , 20

    it "parse full statement", (done) =>
      @robot.emit "ria_room_states_command_parser_message_learn",
        message: text: "nếu anh nói /haha/ thì em nói"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [subject: "anh", verb: "nói", object: "/haha/"], ops: []
        @state.state.should.equal "learn_wait_for_print_message"
        done()
      , 20

    it "parse more complex statement", (done) =>
      @robot.emit "ria_room_states_command_parser_message_learn",
        message: text: "nếu anh nói /haha/ hoặc nói /hihi/b rồi bảo /hehe/ hoặc ai đó nhắc đến /keke/a rồi foo nói /hô hô/i thì"
      , @state
      setTimeout =>
        @state.data.should.deepEqual conditions: [
          {subject: "anh", verb: "nói", object: "/haha/"}
          {verb: "nói", object: "/hihi/b"}
          {verb: "bảo", object: "/hehe/"}
          {verb: "nhắc đến", subject: "ai đó", object: "/keke/a"}
          {verb: "nói", subject: "foo", object: "/hô hô/i"}
        ], ops: ["or", "then", "or", "then"]
        @state.state.should.equal "learn_wait_for_action_statement"
        done()
      , 20

    it "parse eval code", (done) =>
      @state.data = conditions: [subject: "anh", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_eval_code",
        random: (array) -> array[0]
        message:
          text: "puts hello world"
          user: id: "abc"
        send: =>
          @state.code.should.not.empty()
          @state.state.should.equal "learn"
          done()
      , @state

    it "parse print message", (done) =>
      @state.data = conditions: [subject: "ai đó", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_message_learn_wait_for_print_message",
        random: (array) -> array[0]
        message: text: "hihi"
        send: =>
          @state.code.should.not.empty()
          @state.state.should.equal "learn"
          done()
      , @state

    it "parse sticker message", (done) =>
      @state.data = conditions: [subject: "ai đó", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_sticker_learn_wait_for_sticker_message",
        random: (array) -> array[0]
        message: fields: stickerID: "12345"
        send: =>
          @state.code.should.not.empty()
          @state.state.should.equal "learn"
          done()
      , @state

    it "parse sticker emo", (done) =>
      @state.data = conditions: [subject: "abc", verb: "nói", object: "/haha/i"], ops: []
      @robot.emit "ria_room_states_command_parser_sticker_learn_wait_for_sticker_emo",
        random: (array) -> array[0]
        message: fields: stickerID: "144885159019084"
        send: =>
          @state.code.should.not.empty()
          @state.state.should.equal "learn"
          done()
      , @state
