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
  states = room: new RoomState robot, "1460315386566_64b91b84"

  robot.on "ria_code_1460315386566_2b0b571c", (msg) ->
    states.room.remove(msg)
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("cry")

  robot.on "ria_room_states_1460315386566_64b91b84_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match robot.respondPattern /4e/i
    states.room.set msg, state: "1460315386566_8198d73"

  robot.on "ria_room_states_1460315386566_64b91b84_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match robot.respondPattern /syda/i
    states.room.set msg, state: "1460315386566_8198d73"

  robot.on "ria_room_states_1460315386566_64b91b84_sticker_1460315386566_8198d73", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.message.field?.stickerID? and msg.match = msg.message.text.match /^[0-9]+$/
    robot.emit "ria_code_1460315386566_2b0b571c", msg

  robot.on "ria_code_1460315455410_ae54629a", (msg) ->
    states.room.remove(msg)
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("angry")

  robot.on "ria_room_states_1460315386566_64b91b84_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match /cc 4e/i
    states.room.set msg, state: "1460315455410_55d607bf"

  robot.on "ria_room_states_1460315386566_64b91b84_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match /cc syda/i
    states.room.set msg, state: "1460315455410_55d607bf"

  robot.on "ria_room_states_1460315386566_64b91b84_sticker_1460315455410_55d607bf", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.message.field?.stickerID? and msg.match = msg.message.text.match /^.+$/
    robot.emit "ria_code_1460315455410_ae54629a", msg
