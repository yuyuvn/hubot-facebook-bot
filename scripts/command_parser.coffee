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
{RoomState, CachedData} = require "../lib/state"

module.exports = (robot) ->
  states =
    room: new RoomState robot, "command_parser"
    code: new CachedData robot, "ria_code_states"
  regex = null

  robot.on "reset_state_cp", (msg) ->
    states.room.remove msg

  robot.respond new RegExp("#{semantic.regex("#start_lesson")}", "i"), (msg) ->
    unless regex
      regex = {}
      regex.robotPatern = "^(?:#{robot.alias}|#{robot.name})?\\s*"
      regex.suffix = "(?:\\s+([^]+))?\\s*$"
      regex.start = new RegExp "#{regex.robotPatern}#{semantic.regex(":when")}#{regex.suffix}", "i"
      regex.subject = new RegExp "#{regex.robotPatern}(#{semantic.regex(":subject")}|[^\\s]+)\\s(#{semantic.regex("#said")})#{regex.suffix}", "i"
      regex.condition_input = new RegExp "#{regex.robotPatern}(\\/.+?\\/[a-z]*)#{regex.suffix}", "i"
      regex.condition_or_action = new RegExp "#{regex.robotPatern}(#{semantic.regex(":or")}|#{semantic.regex(":then")}|#{semantic.regex(":do")})#{regex.suffix}", "i"
      regex.condition_statement = new RegExp "#{regex.robotPatern}(?:(#{semantic.regex(":subject")}|[^\\s]+)\\s+)?(#{semantic.regex("#said")})#{regex.suffix}", "i"
      regex.action_statement = new RegExp "#{regex.robotPatern}#{semantic.regex(":you ")}?(#{semantic.regex("#eval")}|#{semantic.regex(":respond")}|#{semantic.regex("#spam")}|#{semantic.regex("#show")})#{regex.suffix}", "i"

    states.room.set msg, state: "learn"
    robot.emit "facebook.sendSticker", message: msg, sticker: "144885145685752"

  robot.on "finish_learning", (msg, state) ->
    state.old_state = state.state
    state.state = "learn_wait_for_finish_confirm"
    msg.send if state.data?.code? then "Xong rồi ạ? :3" else "Nghỉ ạ? :'("

  emit_or_wait = (type, msg, state, offset=2) ->
    if msg.match[offset]
      msg.message.text = msg.match[offset]
      robot.emit "ria_room_states_command_parser_message_#{type}", msg, state
    else
      state.state = type

  robot.on "ria_room_states_command_parser_message_learn", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.start
    state.data = conditions: [], ops: []
    emit_or_wait "learn_wait_for_subject", msg, state, 1

  robot.on "ria_room_states_command_parser_message_learn_wait_for_subject", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.subject
    condition = subject: msg.match[1], verb: msg.match[2]
    state.data.conditions.push condition
    emit_or_wait "learn_wait_for_condition_input", msg, state, 3

  robot.on "ria_room_states_command_parser_message_learn_wait_for_condition_input", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.condition_input
    condition = state.data.conditions.pop()
    condition.object = msg.match[1]
    state.data.conditions.push condition
    emit_or_wait "learn_wait_for_condition_or_action", msg, state

  robot.on "ria_room_states_command_parser_sticker_learn_wait_for_condition_input", (msg, state) ->
    stickerID = msg.message.fields.stickerID
    msg.message.text = "/#{stickerID}/"
    robot.emit "ria_room_states_command_parser_message_learn_wait_for_condition_input", msg, state

  robot.on "ria_room_states_command_parser_message_learn_wait_for_condition_or_action", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.condition_or_action
    action = msg.match[1]
    if action in semantic.say ":do"
      emit_or_wait "learn_wait_for_action_statement", msg, state
    else
      state.data.ops.push if action in semantic.say ":or" then "or" else "then"
      emit_or_wait "learn_wait_for_condition_statement", msg, state

  robot.on "ria_room_states_command_parser_message_learn_wait_for_condition_statement", (msg, state) ->
    return robot.emit "finish_learning", msg, state unless msg.match = msg.message.text.match regex.condition_statement
    condition = verb: msg.match[2]
    condition.subject = msg.match[1] if msg.match[1]
    state.data.conditions.push condition
    emit_or_wait "learn_wait_for_condition_input", msg, state, 3

  robot.on "ria_room_states_command_parser_message_learn_wait_for_action_statement", (msg, state) ->
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
    code += "emo = require(\"../lib/emotion\").Singleton()\nsemantic = require(\"../lib/semantic\").Singleton()\n{RoomState} = require \"../lib/state\"\n"
    code += state.hook_root if state.hook_root?
    code += "\nmodule.exports = (robot) ->\n"
    code += "  states = room: new RoomState robot, \"#{state.name}\"\n"
    code += state.code

    file_name = "scripts/ria_#{state.name}.coffee"
    queue = states.code.get()
    queue.files = {} unless queue.files?
    queue.files[file_name] = content: code
    states.code.set queue
    robot.emit "prepair_to_evolution_add_hutbot_scripts", msg, [file_name], ->
      robot.emit "run_evolution", msg
    robot.emit "reset_state_cp", msg

  robot.on "ria_room_states_command_parser_message_learn_wait_for_finish_confirm", (msg, state) ->
    if msg.message.text.match robot.respondPattern new RegExp "#{semantic.regex(":yes")}"
      if state.code
        robot.emit "prepair_to_evolution", msg, state
      else
        robot.emit "reset_state_cp", msg
        msg.send "Nhưng em đã học được gì đâu :'("
    else
      state.state = state.old_state
      msg.send "Yay! Học tiếp :3"

  robot.on "ria_room_states_command_parser_sticker_learn_wait_for_finish_confirm", (msg, state) ->
    stickerID = msg.message.fields.stickerID
    if stickerID in emo.get "yes"
      if state.data?
        robot.emit "prepair_to_evolution", msg, state
      else
        robot.emit "reset_state_cp", msg
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
        "#{fallback.object} unless msg.match = msg.message.text.match robot.respondPattern #{condition.object}"
      else if condition.verb in semantic.say ":speaked"
        "#{fallback.object} unless msg.match = msg.message.text.match #{condition.object}"
      else
        "#{fallback.object} unless msg.message.field?.stickerID? and msg.match = msg.message.text.match #{condition.object}"
    condition_codes.join "\n"

  robot.on "ria_room_states_command_parser_message_learn_wait_for_print_message", (msg, state) ->
    matches = msg.message.text.match robot.respondPattern /([^]+)/
    text = if matches? then matches[1] else msg.message.text
    action = "msg.send '#{text.replace("'","\\'")}'"
    msg.message.text = action
    robot.emit "ria_room_states_command_parser_message_learn_wait_for_eval_code", msg, state

  robot.on "ria_room_states_command_parser_sticker_learn_wait_for_sticker_message", (msg, state) ->
    action = "robot.emit \"facebook.sendSticker\", message: msg, sticker: \"#{msg.message.fields.stickerID}\""
    msg.message.text = action
    robot.emit "ria_room_states_command_parser_message_learn_wait_for_eval_code", msg, state

  robot.on "ria_room_states_command_parser_sticker_learn_wait_for_sticker_emo", (msg, state) ->
    stickerID = msg.message.fields.stickerID
    emotion = null
    for key, value of emo.data
      if stickerID in value
        emotion = key
        break
    if emotion?
      action = "robot.emit \"facebook.sendSticker\", message: msg, sticker: msg.random emo.get(\"#{emotion}\")"
      msg.message.text = action
      robot.emit "ria_room_states_command_parser_message_learn_wait_for_eval_code", msg, state
    else
      msg.send msg.random semantic.say "Em #dont_know", "#clause": semantic.say "#what_emo", "#subject": "đây"

  robot.on "ria_room_states_command_parser_message_learn_wait_for_eval_code", (msg, state) ->
    matches = msg.message.text.match robot.respondPattern /([^]+)/
    msg.message.text = if matches? then matches[1] else msg.message.text
    data = state.data
    conditions = data.conditions
    ops = data.ops
    ops.push "do"
    state.name = state.name || "#{(new Date).getTime()}_#{crc.crc32(Math.random().toString()).toString(16)}"
    scope = {stateID: "default"}
    current_scope = scope
    current_scope.conditions = [conditions.shift()]
    for op in ops
      switch op
        when "or"
          current_scope.conditions.push conditions.shift()
        when "then"
          stateID = "#{(new Date).getTime()}_#{crc.crc32(Math.random().toString()).toString(16)}"
          current_scope.action = "states.room.set msg, state: \"#{stateID}\""
          current_scope.child_scope= {stateID: stateID}
          current_scope = current_scope.child_scope
          current_scope.conditions = [conditions.shift()]
        when "do"
          current_scope.action = "robot.emit \"ria_code_#{state.name}\", msg"

    action = msg.message.text
    action = action.replace /.+/g, (code_string) -> "    #{code_string}"

    current_scope = scope
    state.code = state.code || ""
    state.code += "\n  robot.on \"ria_code_#{state.name}\", (msg) ->\n    states.room.remove(msg)\n#{action}\n"
    subject = semantic.say(":anyone")[0]
    while current_scope?
      action = current_scope.action.replace /.+/g, (code_string) -> "    #{code_string}"
      return_code = "    return states.room.remove(msg)"
      for condition in current_scope.conditions
        if condition.subject?
          subject = condition.subject
        else
          condition.subject = subject
        condition.subject = msg.message.user.id if condition.subject in semantic.say ":I"
        condition_codes = parse_condition condition, subject: "    return", object: return_code
        state.code += if condition.verb in semantic.say "#spam"
          "\n  robot.on \"ria_room_states_#{state.name}_sticker_#{current_scope.stateID}\", (msg, state) ->\n#{condition_codes}\n#{action}\n"
        else
          "\n  robot.on \"ria_room_states_#{state.name}_message_#{current_scope.stateID}\", (msg, state) ->\n#{condition_codes}\n#{action}\n"
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
