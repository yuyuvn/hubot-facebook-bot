# Description:
#   Spam meo
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

HubotFacebook = require 'hubot-facebook'
crc = require 'crc'

class CachedData
  constructor: (@robot, @key) ->
    @cached = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.get(@key)?
        @cached = @robot.brain.get @key
      else
        @robot.brain.set @key, @cached

  get: (paths...) ->
    data = @cached
    for path in paths
      return null if not data[path]?
      data = data[path]
    data

  set: (value, paths...) ->
    parent_data = @cached
    last_path = paths.splice(-1,1)
    for path in paths
      parent_data[path] = {} if not parent_data[path]?
      parent_data = parent_data[path]
    parent_data[last_path] = value
    @robot.brain.set @key, @cached

  remove: (paths...) ->
    parent_data = @cached
    last_path = paths.splice(-1,1)
    for path in paths
      return if not parent_data[path]?
    delete parent_data[last_path]
    @robot.brain.set @key, @cached

  clean: ->
    @cached = {}
    @robot.brain.remove @key


class Stickers
  constructor: (robot) ->
    @data = new CachedData robot, "stickers"

  subscribe: (sticker_id, sticker_url) ->
    return false if @subscribing(sticker_id)
    @data.set sticker_url, sticker_id

  unsubscribe: (sticker_id) ->
    return false if not @subscribing(sticker_id)
    @data.remove sticker_id

  unsubscribe_all: ->
    return false if Object.keys(@data.cached).length < 1
    @data.clean()

  subscribing: (sticker_id) ->
    @data.get(sticker_id)?

module.exports = (robot) ->
  room_states = new CachedData robot, "ria_room_states"
  # user_states = new CachedData robot, "ria_user_states"
  stickers = new Stickers robot

  emo =
    sad: ["144885159019084"],
    cry: ["144884895685777"],
    yes: ["1530358710538271"],
    no: ["1530358467204962"],
    happy: ["144884852352448", "1530358220538320"]
  vocabulary =
    yes: ["ừ","uhm","ờ"],
    no: ["không"],
    sticker: ["con","em","mèo","moè","sticker","bé","thằng","emo"],
    stop: ["dừng","ngừng","ngưng"],
    _I: ["anh"], _you: ["em"], _anyone: ["ai đó","có người","bất kỳ ai"],
    _when: ["khi","nếu","lúc"], _spammed: ["spam sticker","spam emo","spam mèo","spam moè"],
    _or: ["hoặc"], _told: ["nói","bảo"], _then: ["rồi","sau đó"], _do: ["thì"], _speaked: ["nhắc đến","nhắc tới"]
  vocabulary._said = vocabulary._told.concat vocabulary._speaked, vocabulary._spammed
  vocabulary._subject = vocabulary._I.concat vocabulary._anyone, ["[^\\s]+"]
  vocabulary_regex = {}
  for key, value of vocabulary
    vocabulary_regex[key] = "(#{value.join("|")})"

  robot.respondSticker = (regex, callback) ->
    robot.listeners.push new HubotFacebook.StickerListener robot, regex, callback

  robot.on "reset_state", (msg) ->
    room_states.clean msg.message.room

  robot.on "send_random_sticker", (msg) ->
    sticker_ids = Object.keys(stickers.data.cached)
    if sticker_ids.length < 1
      robot.emit "reset_state", msg if room_states.get(msg.message.room)?

    sticker_id = msg.random sticker_ids
    room_states.set state: "spam", id: sticker_id, msg.message.room
    msg.sendSticker sticker_id

  robot.respond new RegExp("spam #{vocabulary_regex.sticker} ([0-9]+)", "i"), (msg) ->
    msg.sendSticker msg.match[2] if msg.sendSticker
    robot.emit "reset_state", msg

  robot.respond new RegExp("#{vocabulary_regex.stop} spam(.*)", "i"), (msg) ->
    match = msg.match[2].match new RegExp "^\\s#{vocabulary_regex.sticker} này", "i"
    if match?
      room_states.set state: "remove", msg.message.room
    else
      msg.sendSticker if stickers.unsubscribe_all() then msg.random(emo.sad) else msg.random(emo.cry)
      robot.emit "reset_state", msg

  robot.respond new RegExp("spam #{vocabulary_regex.sticker} này", "i"), (msg) ->
    room_states.set state: "add", msg.message.room

  robot.router.get "/hubot/facebook/stickers", (req, res) ->
    res.setHeader 'content-type', 'application/json'
    res.send stickers.data.cached

  robot.catchAll (msg) ->
    state_data = room_states.get(msg.message.room) || {}
    state = state_data.state || "default"
    if msg.message.stickerID?
      robot.emit "room_state_handler_sticker_#{state}", msg, state_data
      robot.logger.debug "Trigger room_state_handler_sticker_#{state}"
    else if msg.message.text?
      robot.emit "room_state_handler_message_#{state}", msg, state_data
      robot.logger.debug "Trigger room_state_handler_message_#{state}"

  robot.on "room_state_handler_sticker_default", (msg, state) ->
    unless stickers.subscribing msg.message.stickerID
      robot.emit "room_state_handler_message_default", msg, state
      return
    rate = state.rate || 40
    spammed = true
    unless state?.no_spam
      rand = Math.random()*100
      if rand <= rate
        msg.sendSticker sticker_id
        room_states.set state: "spam", id: sticker_id, msg.message.room
      else if rand <= (rate*1.25)
        robot.emit "send_random_sticker", msg
      else
        spammed = false
    unless spammed
      times = (state?.times || 0) + 1
      room_states.set state: "chain", id: sticker_id, times: times, msg.message.room

  robot.on "room_state_handler_sticker_add", (msg, state) ->
    sticker_id = msg.message.stickerID
    sticker_url = msg.message.text
    if stickers.subscribe sticker_id, sticker_url
      msg.send "Từ giờ em sẽ spam #{sticker_id} :3"
    else
      msg.send "Em spam #{sticker_id} lâu rồi mà -_-"
    robot.emit "reset_state", msg

  robot.on "room_state_handler_sticker_remove", (msg, state) ->
    sticker_id = msg.message.stickerID
    sticker_url = msg.message.text
    if stickers.unsubscribe sticker_id, sticker_url
      msg.send "Từ giờ em sẽ ngừng spam #{sticker_id} ạ :'("
    else
      msg.send "Em đã bao giờ spam #{sticker_id} đâu :/"
    robot.emit "reset_state", msg

  robot.on "room_state_handler_sticker_spam", (msg, state) ->
    sticker_id = msg.message.stickerID
    spammed = sticker_id is state.id
    robot.emit "room_state_handler_sticker_default", msg, state unless spammed

  robot.on "room_state_handler_sticker_chain", (msg, state) ->
    sticker_id = msg.message.stickerID
    state.rate = 0 if state.rate?
    state.rate += 10*state.times if sticker_id is state.id
    robot.emit "room_state_handler_sticker_default", msg, state

  robot.on "room_state_handler_message_default", (msg, state) ->
    rand = Math.random()*100
    if rand <= 5
      robot.emit "send_random_sticker", msg
    else if room_states.get(msg.message.room)?
      robot.emit "reset_state", msg

  robot.on "room_state_handler_message_default", (msg, state) ->
    rand = Math.random()*100
    if rand <= 5
      robot.emit "send_random_sticker", msg
    else if room_states.get(msg.message.room)?
      robot.emit "reset_state", msg

  robot.on "room_state_handler_message_learn", (msg, state) ->
    if state.data?.code?
      msg.send "Xong rồi ạ? :3"
    else
      msg.send "Nghỉ ạ? :'("
    room_states.set "learn_wait_for_finish_confirm", msg.message.room, "state"

  robot.on "room_state_handler_sticker_learn", (msg, state) ->
    if state.data?.code?
      msg.send "Xong rồi ạ? :3"
    else
      msg.send "Nghỉ ạ? :'("
    room_states.set "learn_wait_for_finish_confirm", msg.message.room, "state"

  robot.on "prepair_to_evolution", (msg, data) ->
    code = "# Description:\n#\n# Dependencies:\n#\n# Configuration:\n#\n# Commands:\n#\n# Author:\n#   Ria Scarlet\n\n"
    code += data.hook_root if data.hook_root?
    code += "module.exports = (robot) ->\n"
    code += data.code

    file_name = "scripts/ria_#{new Date().getTime()}.coffee"
    queue = {files:{}}
    queue.files[file_name] = content: code
    robot.brain.set "code_queue", queue
    robot.emit "prepair_to_evolution_add_hutbot_scripts", msg, [file_name]
    room_states.set state: "default", msg.message.room

  robot.on "room_state_handler_message_learn_wait_for_finish_confirm", (msg, state) ->
    if msg.message.text.match robot.respondPattern new RegExp "#{vocabulary_regex.yes}"
      if state.data?
        robot.emit "prepair_to_evolution", msg, state.data
        msg.sendSticker "144885335685733"
      else
        msg.send "Nhưng em đã học được gì đâu :'("
        room_states.set state: "default", msg.message.room
    else
      msg.send "Yay! Học tiếp :3"
      room_states.set "learn", msg.message.room, "state"

  robot.on "room_state_handler_sticker_learn_wait_for_finish_confirm", (msg, state) ->
    stickerID = msg.message.stickerID
    if stickerID in emo.yes
      if state.data?
        robot.emit "prepair_to_evolution", msg, state.data
        msg.sendSticker "144885335685733"
      else
        msg.send "Nhưng em đã học được gì đâu :'("
    else
      msg.sendSticker msg.random emo.happy
      room_states.set "learn", msg.message.room, "state"

  robot.respond /(bắt đầu học nào|đến giờ học rồi)/i, (msg) ->
    room_states.set state: "learn", msg.message.room
    msg.sendSticker "144885145685752"

  input_regex = "\\/.+?\\/[a-z]*"
  or_regex = "(( #{vocabulary_regex._or} #{vocabulary_regex._said} #{input_regex})*)"
  full_sentence_regex = new RegExp "#{vocabulary_regex._when} #{vocabulary_regex._subject} #{vocabulary_regex._said}( (#{input_regex})#{or_regex}((( #{vocabulary_regex._then} #{vocabulary_regex._said} #{input_regex})*)#{or_regex})( #{vocabulary_regex._do}(.*))?)?$"
  or_sentences_regex = new RegExp "#{vocabulary_regex._or} #{vocabulary_regex._said} #{input_regex}(?=\\s|$)", "g"
  or_sentence_regex = new RegExp "^#{vocabulary_regex._or} #{vocabulary_regex._said} (#{input_regex})\\s*$"
  then_sentences_regex = new RegExp "#{vocabulary_regex._then} #{vocabulary_regex._said} #{input_regex}#{or_regex}", "g"
  then_sentence_regex = new RegExp "^#{vocabulary_regex._then} #{vocabulary_regex._said} (#{input_regex})#{or_regex}(?=\\s|$)"
  parse_or_statemnet = (data) ->
    matches = data.text.match or_sentences_regex
    if matches?
      for match in matches
        match = match.match or_sentence_regex
        data.data.conditions.push {verb: match[2], object: match[3]}
        data.data.ops.push "or"
      room_states.set "learn_wait_for_condition_or_action", data.msg.message.room, "state"
    else
      match = data.text.match new RegExp "#{vocabulary_regex._or} #{vocabulary_regex._said}\\s*$"
      if match?
        data.data.conditions.push {verb: match[2]}
        data.data.ops.push "or"
        room_states.set data.data, data.msg.message.room, "data"
        room_states.set "learn_wait_for_condition", data.msg.message.room, "state"

  parse_then_statemnet = (data) ->
    matches = data.text.match then_sentences_regex
    if matches?
      for match in matches
        match = match.match then_sentence_regex
        data.data.conditions.push {verb: match[2], object: match[3]}
        data.data.ops.push "then"
        if match[4]
          data.text = match[4]
          parse_or_statemnet data
      room_states.set "learn_wait_for_condition_or_action", data.msg.message.room, "state"
    else
      # try to parse with break
      match = data.text.match new RegExp "#{vocabulary_regex._then} #{vocabulary_regex._said}\\s*$"
      if match?
        data.data.conditions.push {verb: match[2]}
        data.data.ops.push "then"
        room_states.set data.data, data.msg.message.room, "data"
        room_states.set "learn_wait_for_condition", data.msg.message.room, "state"

  parse_action_statemnet = (data) ->
    msg = data.msg
    if match = data.text.match new RegExp "#{vocabulary_regex._do}?\\s?chạy lệnh"
      room_states.set "learn_wait_for_eval_code", msg.message.room, "state"
    else if match = data.text.match new RegExp "#{vocabulary_regex._do}?\\s?(nói|trả lời)"
      room_states.set "learn_wait_for_print_message", msg.message.room, "state"
    else if match = data.text.match new RegExp "#{vocabulary_regex._do}?\\s?spam #{vocabulary_regex.sticker}"
      room_states.set "learn_wait_for_sticker_message", msg.message.room, "state"
    else if match = data.text.match new RegExp "#{vocabulary_regex._do}?\\s?thể hiện cảm xúc"
      room_states.set "learn_wait_for_sticker_emo", msg.message.room, "state"
    else
      data.msg.send "#{data.text} là gì ạ?"

  parse_condition = (condition, fallback) ->
    condition_codes = []
    if fallback.subject? and condition.subject? and condition.subject not in vocabulary._anyone
      subject = condition.subject.replace "'", "\\'"
      condition_codes.push "#{fallback.subject} unless '#{subject}' == msg.message.user.id"
    if fallback.object?
      if condition.verb in vocabulary._told
        condition_codes.push "#{fallback.object} unless msg.match = msg.message.match robot.respondPattern #{condition.object}"
      else if condition.verb in vocabulary._speaked
        condition_codes.push "#{fallback.object} unless msg.match = msg.message.match #{condition.object}"
      else if condition.verb in vocabulary._spammed
        condition_codes.push "#{fallback.object} unless msg.message.stickerID? and msg.match = msg.message.match #{condition.object}"
    condition_codes.join "\n"

  robot.on "parse_statemnet", (msg, state) ->
    match = msg.match
    data = state.data || conditions: [], ops: []
    unless match[4]
      room_states.set data, msg.message.room, "data"
      data.conditions.push {subject: match[2],verb: match[3]}
      room_states.set data, msg.message.room, "data"
      room_states.set "learn_wait_for_condition", msg.message.room, "state"
      return
    data.conditions.push {subject: match[2],verb: match[3], object: match[5]}
    room_states.set true, msg.message.room, "has_condition"
    room_states.set "learn_wait_for_condition_or_action", msg.message.room, "state"
    if match[6]
      parse_or_statemnet text: match[6], data: data, msg: msg
    if match[10]
      parse_then_statemnet text: match[10], data: data, msg: msg
    if match[21]
      parse_action_statemnet text: match[21], data: data, msg: msg
    else if match[20]
      room_states.set "learn_wait_for_action", msg.message.room, "state"
    room_states.set data, msg.message.room, "data"

  robot.on "room_state_handler_message_learn_wait_for_action", (msg, state) ->
    matches = msg.message.text.match new RegExp "^(?:#{robot.alias}|#{robot.name}) ([^]+)", "i"
    text = if matches? then matches[1] else msg.message.text
    data = state.data
    parse_action_statemnet text: text, data: data, msg: msg

  robot.on "room_state_handler_message_learn_wait_for_condition", (msg, state) ->
    data = state.data
    condition = data.conditions.pop()
    matches = msg.message.text.match new RegExp "^(?:#{robot.alias}|#{robot.name}) ([^]+)", "i"
    msg.message.text = if matches? then matches[1] else msg.message.text
    if condition.subject?
      text = "#{vocabulary._when[0]} #{condition.subject} #{condition.verb} #{msg.message.text}"
      msg.match = text.match full_sentence_regex
      robot.emit "parse_statemnet", msg, state
    else
      op = data.ops.pop()
      if op == "or"
        text = "#{vocabulary._or[0]} #{condition.verb} #{msg.message.text}"
        parse_or_statemnet text: text, data: data, msg: msg
      else
        text = "#{vocabulary._then[0]} #{condition.verb} #{msg.message.text}"
        parse_then_statemnet text: text, data: data, msg: msg

  robot.on "room_state_handler_sticker_learn_wait_for_condition", (msg, state) ->
    stickerID = msg.message.stickerID
    msg.message.text = "/#{stickerID}/"
    robot.emit "room_state_handler_message_learn_wait_for_condition", msg, state

  robot.on "room_state_handler_message_learn_wait_for_print_message", (msg, state) ->
    matches = msg.message.text.match new RegExp "^(?:#{robot.alias}|#{robot.name}) ([^]+)", "i"
    text = if matches? then matches[1] else msg.message.text
    action = "msg.send '#{text.replace("'","\\'")}'"
    msg.message.text = action
    robot.emit "room_state_handler_message_learn_wait_for_eval_code", msg, state

  robot.on "room_state_handler_sticker_learn_wait_for_sticker_message", (msg, state) ->
    action = "msg.sendSticker '#{msg.message.stickerID}'"
    msg.message.text = action
    robot.emit "room_state_handler_message_learn_wait_for_eval_code", msg, state

  robot.on "room_state_handler_sticker_learn_wait_for_sticker_emo", (msg, state) ->
    stickerID = msg.message.stickerID
    for key, value of emo
      if stickerID in value
        emotion = key
        break
    if emotion?
      action = "msg.sendSticker msg.random emo.#{emotion}"
      msg.message.text = action
      robot.emit "room_state_handler_message_learn_wait_for_eval_code", msg, state
    else
      msg.send "Em không biết đây là cảm xúc gì :'("

  robot.on "room_state_handler_message_learn_wait_for_eval_code", (msg, state) ->
    matches = msg.message.text.match new RegExp "^(?:#{robot.alias}|#{robot.name}) ([^]+)", "i"
    text = if matches? then matches[1] else msg.message.text
    msg.message.text = text
    data = state.data
    conditions = data.conditions
    ops = data.ops
    ops.push "do"
    scope = {}
    current_scope = scope
    current_scope.conditions = [conditions.shift()]
    do_event = crc.crc32(ops.join('')).toString(16)
    for op in ops
      switch op
        when "or"
          current_scope.conditions.push conditions.shift()
        when "then"
          regex = "#{current_scope.conditions[0].object}_#{Math.floor((Math.random()*1000))}"
          stateID = crc.crc32(regex).toString(16)
          current_scope.action = "room_states.set state: \"#{stateID}\", msg.message.room"
          current_scope.child_scope= {stateID: stateID}
          current_scope = current_scope.child_scope
          current_scope.conditions = [conditions.shift()]
        when "do"
          current_scope.action = "robot.emit \"ria_code_#{do_event}\", msg"

    action = msg.message.text
    action = action.replace /.+/g, (code_string) ->
      if code_string != "" then "    #{code_string}" else ""

    current_scope = scope
    data.code = "" unless data.code?
    data.code += "\n  robot.on \"ria_code_#{do_event}\", (msg) ->\n#{action}\n"
    subject = vocabulary._anyone[0]
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
          condition.subject = msg.message.user.id if condition.subject in vocabulary._I
          condition_codes = parse_condition condition, subject: "    return", object: return_code
          data.code += "\n  robot.on \"room_state_handler_message_#{current_scope.stateID}\", (msg, state) ->\n#{condition_codes}\n#{action}\n"
      else
        # Can we calculor outersect of regex?
        for condition in current_scope.conditions
          if condition.subject?
            subject = condition.subject
          else
            condition.subject = subject
          condition.subject = msg.message.user.id if condition.subject in vocabulary._I
          condition_codes = parse_condition condition, subject: "    return"
          condition_codes += "\n" if condition_codes
          if condition.verb in vocabulary._told
            data.code += "\n  robot.respond #{condition.object}, (msg) ->\n#{condition_codes}#{action}\n"
          else if condition.verb in vocabulary._speaked
            data.code += "\n  robot.hear #{condition.object}, (msg) ->\n#{condition_codes}#{action}\n"
          else if condition.verb in vocabulary._spammed
            data.code += "\n  robot.respondSticker #{condition.object}, (msg) ->\n#{condition_codes}#{action}\n"
      current_scope = current_scope.child_scope
    data.conditions = []
    data.ops = []
    room_states.set data, msg.message.room, "data"
    room_states.set "learn", msg.message.room, "state"
    msg.send "Em thuộc rồi ạ"
    msg.sendSticker msg.random emo.happy

  robot.respond full_sentence_regex, (msg) ->
    return robot.emit "room_state_handler_message_default", msg if room_states.get(msg.message.room, "state") != "learn"
    robot.emit "parse_statemnet", msg, room_states.get msg.message.room

  robot.on "room_state_handler_message_learn_wait_for_condition_or_action", (msg, state) ->
    matches = msg.message.text.match new RegExp "^(?:#{robot.alias}|#{robot.name}) ([^]+)", "i"
    text = if matches? then matches[1] else msg.message.text
    msg.message.text = text
    data = state.data
    if match = msg.message.text.match new RegExp "^(#{vocabulary_regex._or}|#{vocabulary_regex._then}|#{vocabulary_regex._do})\\s?([^]*)"
      if match[1] in vocabulary._do
        if match[5]
          parse_action_statemnet text: match[5], data: data, msg: msg
        else
          room_states.set "learn_wait_for_action", msg.message.room, "state"
      else unless match[5]
        room_states.set "learn_wait_for_condition", msg.message.room, "state"
      else
        if match[1] in vocabulary._or
          parse_or_statemnet text: msg.message.text, data: data, msg: msg
        if match[1] in vocabulary._then
          parse_then_statemnet text: msg.message.text, data: data, msg: msg
    else if match = msg.message.text.match new RegExp "^(thì)"
      parse_action_statemnet text: msg.message.text, data: data, msg: msg
    room_states.set data, msg.message.room, "data"

  robot.router.get "/hubot/self_programming/:room", (req, res) ->
    res.setHeader 'content-type', 'text/plain'
    state = room_states.get req.params.room
    code = state?.data?.code || state?.state || '# Nothing to say'
    res.send code
