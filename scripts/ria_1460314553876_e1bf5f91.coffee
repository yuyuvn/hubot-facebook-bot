# Description:
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   Ria Scarlet

emo = require("../lib/emotion").Singleton()
semantic = require("../lib/semantic").Singleton()
{RoomState} = require "../lib/state"

module.exports = (robot) ->
  states = room: new RoomState robot, "1460314553876_e1bf5f91"

  robot.on "ria_code_1460314553876_e1bf5f91", (msg) ->
    states.room.remove(msg)
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("angry")

  robot.on "ria_room_states_1460314553876_e1bf5f91_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match /cc 4e/i
    states.room.set msg, state: "1460314553876_c4919eee"

  robot.on "ria_room_states_1460314553876_e1bf5f91_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match /cc syda/i
    states.room.set msg, state: "1460314553876_c4919eee"

  robot.on "ria_room_states_1460314553876_e1bf5f91_sticker_1460314553876_c4919eee", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.message.field?.stickerID? and msg.match = msg.message.text.match /^.+$/
    robot.emit "ria_code_1460314553876_e1bf5f91", msg

  robot.on "ria_code_1460314553876_e1bf5f91", (msg) ->
    states.room.remove(msg)
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("cry")

  robot.on "ria_room_states_1460314553876_e1bf5f91_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match robot.respondPattern /4e/i
    states.room.set msg, state: "1460314595452_cfbd62d3"

  robot.on "ria_room_states_1460314553876_e1bf5f91_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match robot.respondPattern /syda/i
    states.room.set msg, state: "1460314595452_cfbd62d3"

  robot.on "ria_room_states_1460314553876_e1bf5f91_sticker_1460314595452_cfbd62d3", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.message.field?.stickerID? and msg.match = msg.message.text.match /^.+$/
    robot.emit "ria_code_1460314553876_e1bf5f91", msg
