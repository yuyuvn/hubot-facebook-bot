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
{RoomState, Stickers} = require "../lib/state"

module.exports = (robot) ->
  states =
    room: new RoomState robot, "spameo"
    stickers: new Stickers robot

  robot.on "facebook.sendSticker", (event) ->
    states.room.set event.message, state: "spam", id: event.sticker

  robot.on "reset_state_spameo", (msg) ->
    states.room.remove msg

  robot.on "send_random_sticker", (msg) ->
    sticker_ids = states.stickers.subscribing()
    if sticker_ids.length < 1
      robot.emit "reset_state_spameo", msg if states.room.get(msg)?
    else
      sticker_id = msg.random sticker_ids
      robot.emit "facebook.sendSticker", message: msg, sticker: sticker_id

  robot.respond new RegExp("spam #{semantic.regex(":sticker")} ([0-9]+)", "i"), (msg) ->
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.match[1]

  robot.respond new RegExp("#{semantic.regex(":stop")} spam(.*)", "i"), (msg) ->
    match = msg.match[1].match new RegExp "^\\s#{semantic.regex(":sticker")} này", "i"
    if match?
      states.room.set msg, state: "remove"
    else
      sticker = if states.stickers.unsubscribe_all() then msg.random(emo.get("sad")) else msg.random(emo.get("cry"))
      robot.emit "facebook.sendSticker", message: msg, sticker: sticker

  robot.respond new RegExp("spam #{semantic.regex(":sticker")} này", "i"), (msg) ->
    states.room.set msg, state: "add"

  robot.router.get "/hubot/facebook/stickers", (req, res) ->
    res.setHeader 'content-type', 'application/json'
    res.send states.stickers.data.get()

  robot.on "ria_room_states_spameo_sticker_default", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    unless states.stickers.subscribing sticker_id
      return robot.emit "ria_room_states_spameo_message_default", msg
    spammed = false
    unless state?.no_spam
      rate = state.rate || 20
      rand = Math.random()*100
      if rand <= rate
        robot.emit "facebook.sendSticker", message: msg, sticker: sticker_id
        spammed = true
      else if rand <= (rate+20)
        robot.emit "send_random_sticker", msg
        spammed = true
    unless spammed
      times = (state?.times || 0) + 1
      states.room.set msg, state: "chain", id: sticker_id, times: times

  robot.on "ria_room_states_spameo_sticker_add", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    sticker_url = msg.message.text
    if states.stickers.subscribe sticker_id, sticker_url
      msg.send "Từ giờ em sẽ spam #{sticker_id} :3"
    else
      msg.send "Em spam #{sticker_id} lâu rồi mà -_-"
    robot.emit "reset_state_spameo", msg

  robot.on "ria_room_states_spameo_sticker_remove", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    sticker_url = msg.message.text
    if states.stickers.unsubscribe sticker_id, sticker_url
      msg.send "Từ giờ em sẽ ngừng spam #{sticker_id} ạ :'("
    else
      msg.send "Em đã bao giờ spam #{sticker_id} đâu :/"
    robot.emit "reset_state_spameo", msg

  robot.on "ria_room_states_spameo_sticker_spam", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    spammed = sticker_id is state.id
    robot.emit "ria_room_states_spameo_sticker_default", msg, state unless spammed

  robot.on "ria_room_states_spameo_sticker_chain", (msg, state) ->
    sticker_id = msg.message.fields.stickerID
    state.rate = 0 if state.rate?
    state.rate += 10*state.times if sticker_id is state.id
    robot.emit "ria_room_states_spameo_sticker_default", msg, state

  robot.on "ria_room_states_spameo_message_default", (msg, state) ->
    rand = Math.random()*100
    if rand <= 5
      robot.emit "send_random_sticker", msg
    else if states.room.get(msg)?
      robot.emit "reset_state_spameo", msg
