# Description:
#   You can guide ria to communicate
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

crc = require "crc"
emo = require("../lib/emotion").Singleton()
semantic = require("../lib/semantic").Singleton()
{State} = require "../lib/state"

module.exports = (robot) ->
  states = new State robot
  regex = {}

  robot.respond new RegExp("#{semantic.regex("#start_lesson")}", "i"), (msg) ->
    regex.start = new RegExp "^(?:#{robot.alias}|#{robot.name})?\\s*#{semantic.regex(":when")}([^]*)$", "i"
    regex.subject = new RegExp "^(?:#{robot.alias}|#{robot.name})?\\s*(#{semantic.regex(":subject")}|[^\\s]+)\\s(#{semantic.regex(":said")})([^]*)$", "i"
    regex.condition_input = new RegExp "^(?:#{robot.alias}|#{robot.name})?\\s*(\\/.+?\\/[a-z]*)([^]*)$", "i"
    regex.condition_or_action = new RegExp "^(?:#{robot.alias}|#{robot.name})?\\s*(#{semantic.regex(":or")}|#{semantic.regex(":then")}|#{semantic.regex(":do")})([^]*)$", "i"
    regex.condition_statement = new RegExp "^(?:#{robot.alias}|#{robot.name})?\\s*(?:(#{semantic.regex(":subject")}|[^\\s]+)\\s+)?(#{semantic.regex(":said")})([^]*)$", "i"
    regex.action_statement = new RegExp "^(?:#{robot.alias}|#{robot.name})?\\s*#{semantic.regex(":you ")}?(#{semantic.regex("#eval")}|#{semantic.regex(":respond")}|#{semantic.regex("#spam")}|#{semantic.regex("#show")})([^]*)$", "i"

    states.room.set state: "learn", msg.message.room
    robot.emit "facebook.sendSticker", message: msg, sticker: "144885145685752"

  robot.on "finish_learning", (msg, state) ->
    state.old_state = state.state
    state.state = "learn_wait_for_finish_confirm"
    msg.send if state.data?.code? then "Xong rồi ạ? :3" else "Nghỉ ạ? :'("

  emit_or_wait = (type, msg, state, offset=2) ->
    if msg.match[offset]
      msg.message.text = msg.match[offset]
      robot.emit "room_state_handler_message_#{type}", msg, state
    else
      state.state = type

  robot.on "room_state_handler_message_learn", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.start
    state.data = conditions: [], ops: []
    emit_or_wait "learn_wait_for_subject", msg, state, 1

  robot.on "room_state_handler_message_learn_wait_for_subject", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.subject
    condition = subject: msg.match[1], verb: msg.match[2]
    state.data.conditions.push condition
    emit_or_wait "learn_wait_for_condition_input", msg, state, 3

  robot.on "room_state_handler_message_learn_wait_for_condition_input", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.condition_input
    condition = state.data.conditions.pop()
    condition.object = msg.match[1]
    state.data.conditions.push condition
    emit_or_wait "learn_wait_for_condition_or_action", msg, state

  robot.on "room_state_handler_sticker_learn_wait_for_condition_input", (msg, state) ->
    stickerID = msg.message.fields.stickerID
    msg.message.text = "/#{stickerID}/"
    robot.emit "room_state_handler_message_learn_wait_for_condition_input", msg, state

  robot.on "room_state_handler_message_learn_wait_for_condition_or_action", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.condition_or_action
    action = msg.match[1]
    if action in semantic.say ":do"
      emit_or_wait "learn_wait_for_action_statement", msg, state
    else
      state.data.ops.push if action in semantic.say ":or" then "or" else "then"
      emit_or_wait "learn_wait_for_condition_statement", msg, state

  robot.on "room_state_handler_message_learn_wait_for_condition_statement", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.condition_statement
    condition = verb: msg.match[2]
    condition.subject = msg.match[1] if msg.match[1]
    state.data.conditions.push condition
    emit_or_wait "learn_wait_for_condition_input", msg, state, 3

  robot.on "room_state_handler_message_learn_wait_for_action_statement", (msg, state) ->
    unless msg.match = msg.message.text.match regex.action_statement
      msg.send msg.random semantic.say "#what ạ?", "#subject": msg.message.text
      return
    action = msg.match[1]
    state.state = if action in semantic.say "#eval"
      "learn_wait_for_eval_code"
    else if action in semantic.say ":respond"
      "learn_wait_for_print_message"
    else if action in semantic.say "#spam"
      "learn_wait_for_sticker_message"
    else
      "learn_wait_for_sticker_emo"

  robot.on "prepair_to_evolution", (msg, state) ->
    return msg.send "Em đang ôn không nhớ được ạ, anh chờ lát nữa confirm lại nhé" if states.code.get "locked"

    code = "# Description:\n#\n# Dependencies:\n#\n# Configuration:\n#\n# Commands:\n#\n# Author:\n#   Ria Scarlet\n\n"
    code += "emo = require(\"../lib/emotion\").Singleton()\nsemantic = require(\"../lib/semantic\").Singleton()\n{State} = require \"../lib/state\"\n"
    code += state.hook_root if state.hook_root?
    code += "\nmodule.exports = (robot) ->\n"
    code += "  states = new State robot\n"
    code += state.code

    file_name = "scripts/ria_#{new Date().getTime()}.coffee"
    queue = states.code.get()
    queue.files = {} unless queue.files?
    queue.files[file_name] = content: code
    states.code.set queue
    robot.emit "prepair_to_evolution_add_hutbot_scripts", msg, [file_name]
    robot.emit "reset_state", msg

  robot.on "room_state_handler_message_learn_wait_for_finish_confirm", (msg, state) ->
    if msg.message.text.match robot.respondPattern new RegExp "#{semantic.regex(":yes")}"
      if state.data?
        robot.emit "prepair_to_evolution", msg, state
      else
        robot.emit "reset_state", msg
        msg.send "Nhưng em đã học được gì đâu :'("
    else
      state.state = state.old_state
      msg.send "Yay! Học tiếp :3"

  robot.on "room_state_handler_sticker_learn_wait_for_finish_confirm", (msg, state) ->
    stickerID = msg.message.fields.stickerID
    if stickerID in emo.get "yes"
      if state.data?
        robot.emit "prepair_to_evolution", msg, state
      else
        robot.emit "reset_state", msg
        msg.send "Nhưng em đã học được gì đâu :'("
    else
      state.state = state.old_state
      robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get "happy"

  parse_condition = (condition, fallback) ->
    condition_codes = []
    if fallback.subject? and condition.subject? and condition.subject not in semantic.say ":anyone"
      subject = condition.subject.replace "'", "\\'"
      condition_codes.push "#{fallback.subject} unless '#{subject}' == msg.message.user.id"
    if fallback.object?
      condition_codes.push if condition.verb in semantic.say ":told"
        "#{fallback.object} unless msg.match = msg.message.match robot.respondPattern #{condition.object}"
      else if condition.verb in semantic.say ":speaked"
        "#{fallback.object} unless msg.match = msg.message.match #{condition.object}"
      else
        "#{fallback.object} unless msg.message.field?.stickerID? and msg.match = msg.message.match #{condition.object}"
    condition_codes.join "\n"

  robot.on "room_state_handler_message_learn_wait_for_print_message", (msg, state) ->
    matches = msg.message.text.match robot.respondPattern /([^]+)/
    text = if matches? then matches[1] else msg.message.text
    action = "msg.send '#{text.replace("'","\\'")}'"
    msg.message.text = action
    robot.emit "room_state_handler_message_learn_wait_for_eval_code", msg, state

  robot.on "room_state_handler_sticker_learn_wait_for_sticker_message", (msg, state) ->
    action = "robot.emit \"facebook.sendSticker\", message: msg, sticker: \"#{msg.message.fields.stickerID}\""
    msg.message.text = action
    robot.emit "room_state_handler_message_learn_wait_for_eval_code", msg, state

  robot.on "room_state_handler_sticker_learn_wait_for_sticker_emo", (msg, state) ->
    stickerID = msg.message.fields.stickerID
    emotion = null
    for key, value of emo.data
      if stickerID in value
        emotion = key
        break
    if emotion?
      action = "robot.emit \"facebook.sendSticker\", message: msg, sticker: msg.random emo.get(\"#{emotion}\")"
      msg.message.text = action
      robot.emit "room_state_handler_message_learn_wait_for_eval_code", msg, state
    else
      msg.send msg.random semantic.say "Em #dont_know", "#clause": semantic.say "#what_emo", "#subject": "đây"

  robot.on "room_state_handler_message_learn_wait_for_eval_code", (msg, state) ->
    matches = msg.message.text.match robot.respondPattern /([^]+)/
    msg.message.text = if matches? then matches[1] else msg.message.text
    data = state.data
    conditions = data.conditions
    ops = data.ops
    ops.push "do"
    scope = {}
    current_scope = scope
    current_scope.conditions = [conditions.shift()]
    do_event = "#{(new Date).getTime()}_#{crc.crc32(Math.random()).toString(16)}"
    for op in ops
      switch op
        when "or"
          current_scope.conditions.push conditions.shift()
        when "then"
          regex = "#{current_scope.conditions[0].object}_#{Math.floor((Math.random()*1000))}"
          stateID = "#{(new Date).getTime()}_#{crc.crc32(Math.random()).toString(16)}"
          current_scope.action = "states.room.set state: \"#{stateID}\", msg.message.room"
          current_scope.child_scope= {stateID: stateID}
          current_scope = current_scope.child_scope
          current_scope.conditions = [conditions.shift()]
        when "do"
          current_scope.action = "robot.emit \"ria_code_#{do_event}\", msg"

    action = msg.message.text
    action = action.replace /.+/g, (code_string) ->
      if code_string != "" then "    #{code_string}" else ""

    current_scope = scope
    state.code = "" unless state.code?
    state.code += "\n  robot.on \"ria_code_#{do_event}\", (msg) ->\n#{action}\n"
    subject = semantic.say(":anyone")[0]
    while current_scope?
      action = current_scope.action.replace /.+/g, (code_string) ->
        if code_string != "" then "    #{code_string}" else ""
      if current_scope.stateID
        return_code = "    return robot.emit \"room_state_handler_message_default\""
        for condition in current_scope.conditions
          if condition.subject?
            subject = condition.subject
          else
            condition.subject = subject
          condition.subject = msg.message.user.id if condition.subject in semantic.say ":I"
          condition_codes = parse_condition condition, subject: "    return", object: return_code
          state.code += "\n  robot.on \"room_state_handler_message_#{current_scope.stateID}\", (msg, state) ->\n#{condition_codes}\n#{action}\n"
      else
        # Can we calculor outersect of regex?
        for condition in current_scope.conditions
          if condition.subject?
            subject = condition.subject
          else
            condition.subject = subject
          condition.subject = msg.message.user.id if condition.subject in semantic.say ":I"
          condition_codes = parse_condition condition, subject: "    return"
          condition_codes += "\n" if condition_codes
          state.code += if condition.verb in semantic.say ":told"
            "\n  robot.respond #{condition.object}, (msg) ->\n#{condition_codes}#{action}\n"
          else if condition.verb in semantic.say ":speaked"
            "\n  robot.hear #{condition.object}, (msg) ->\n#{condition_codes}#{action}\n"
          else
            "\n  robot.respondSticker #{condition.object}, (msg) ->\n#{condition_codes}#{action}\n"
      current_scope = current_scope.child_scope
    state.data = conditions: [], ops: []
    state.state = "learn"
    msg.send msg.random semantic.say "Em :remember :finished_prefix ạ"
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get "happy"

  robot.router.get "/hubot/self_programming/:room", (req, res) ->
    res.setHeader 'content-type', 'text/plain'
    state = states.room.get req.params.room
    code = state?.data?.code || state?.state || '# Nothing to say'
    res.send code
