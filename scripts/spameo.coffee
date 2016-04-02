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
{TextMessage} = require 'hubot'

class CachedData
  constructor: (@robot, @key) ->
    @cached = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data[@key]?
        @cached = @robot.brain.data[@key]
      else
        @robot.brain.data[@key] = @cached

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
    @robot.brain.data[@key] = @cached

  remove: (paths...) ->
    parent_data = @cached
    last_path = paths.splice(-1,1)
    for path in paths
      return if not parent_data[path]?
    delete parent_data[last_path]
    @robot.brain.data[@key] = @cached

  clean: ->
    @cached = {}
    @robot.brain.data[@key] = @cached


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
    cry: ["144884895685777"]
  vocabulary =
    sticker: ["con","em","mèo","moè","sticker","bé","thằng","emo"],
    stop: ["dừng","ngừng","ngưng"]
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
    sticker_id = msg.message.stickerID
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

