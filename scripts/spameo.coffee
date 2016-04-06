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

emo = require("../lib/emotion").Singleton()
semantic = require("../lib/semantic").Singleton()
{State} = require "../lib/state"

module.exports = (robot) ->
  states = new State robot

  robot.on "reset_state", (msg) ->
    states.room.remove msg.message.room

  robot.on "send_random_sticker", (msg) ->
    sticker_ids = states.stickers.subscribing()
    if sticker_ids.length < 1
      robot.emit "reset_state", msg if states.room.get(msg.message.room)?

    sticker_id = msg.random sticker_ids
    states.room.set state: "spam", id: sticker_id, msg.message.room
    robot.emit "facebook.sendSticker", message: msg, sticker: sticker_id

  robot.respond new RegExp("spam #{semantic.regex(":sticker")} ([0-9]+)", "i"), (msg) ->
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.match[1]
    robot.emit "reset_state", msg

  robot.respond new RegExp("#{semantic.regex(":stop")} spam(.*)", "i"), (msg) ->
    match = msg.match[1].match new RegExp "^\\s#{semantic.regex(":sticker")} này", "i"
    if match?
      states.room.set state: "remove", msg.message.room
    else
      sticker = if states.stickers.unsubscribe_all() then msg.random(emo.get("sad")) else msg.random(emo.get("cry"))
      robot.emit "facebook.sendSticker", message: msg, sticker: sticker
      robot.emit "reset_state", msg

  robot.respond new RegExp("spam #{semantic.regex(":sticker")} này", "i"), (msg) ->
    states.room.set state: "add", msg.message.room

  robot.router.get "/hubot/facebook/stickers", (req, res) ->
    res.setHeader 'content-type', 'application/json'
    res.send states.stickers.data.get()

  robot.catchAll (msg) ->
    state_data = states.room.get(msg.message.room) || {}
    state = state_data.state || "default"
    if msg.message.fields?.stickerID?
      robot.emit "room_state_handler_sticker_#{state}", msg, state_data
      robot.logger.debug "Trigger room_state_handler_sticker_#{state}"
    else if msg.message.text?
      robot.emit "room_state_handler_message_#{state}", msg, state_data
      robot.logger.debug "Trigger room_state_handler_message_#{state}"

  robot.on "room_state_handler_sticker_default", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    unless states.stickers.subscribing sticker_id
      return robot.emit "room_state_handler_message_default", msg, state
    spammed = false
    unless state?.no_spam
      rate = state.rate || 40
      rand = Math.random()*100
      if rand <= rate
        robot.emit "facebook.sendSticker", message: msg, sticker: sticker_id
        states.room.set state: "spam", id: sticker_id, msg.message.room
        spammed = true
      else if rand <= (rate*1.25)
        robot.emit "send_random_sticker", msg
        spammed = true
    unless spammed
      times = (state?.times || 0) + 1
      states.room.set state: "chain", id: sticker_id, times: times, msg.message.room

  robot.on "room_state_handler_sticker_add", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    sticker_url = msg.message.text
    if states.stickers.subscribe sticker_id, sticker_url
      msg.send "Từ giờ em sẽ spam #{sticker_id} :3"
    else
      msg.send "Em spam #{sticker_id} lâu rồi mà -_-"
    robot.emit "reset_state", msg

  robot.on "room_state_handler_sticker_remove", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    sticker_url = msg.message.text
    if states.stickers.unsubscribe sticker_id, sticker_url
      msg.send "Từ giờ em sẽ ngừng spam #{sticker_id} ạ :'("
    else
      msg.send "Em đã bao giờ spam #{sticker_id} đâu :/"
    robot.emit "reset_state", msg

  robot.on "room_state_handler_sticker_spam", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    spammed = sticker_id is state.id
    robot.emit "room_state_handler_sticker_default", msg, state unless spammed

  robot.on "room_state_handler_sticker_chain", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    state.rate = 0 if state.rate?
    state.rate += 10*state.times if sticker_id is state.id
    robot.emit "room_state_handler_sticker_default", msg, state

  robot.on "room_state_handler_message_default", (msg, state) ->
    rand = Math.random()*100
    if rand <= 5
      robot.emit "send_random_sticker", msg
    else if states.room.get(msg.message.room)?
      robot.emit "reset_state", msg
