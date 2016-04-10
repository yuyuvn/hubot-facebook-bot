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
{State} = require "../lib/state"

module.exports = (robot) ->
  states = room: new RoomState robot, "1460313556082_9cbbe969"

  robot.on "ria_code_1460313501734_1c729c47", (msg) ->
    states.room.remove()
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("angry")

  robot.on "ria_room_states_1460313501734_1c729c47_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match /cc 4e/i
    states.room.set msg, state: "1460313501734_afd6aff8"

  robot.on "ria_room_states_1460313501734_1c729c47_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match /cc syda/i
    states.room.set msg, state: "1460313501734_afd6aff8"

  robot.on "ria_room_states_1460313501734_1c729c47_sticker_1460313501734_afd6aff8", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.message.field?.stickerID? and msg.match = msg.message.text.match /^[0-9]+$/
    undefinedrobot.emit "ria_code_1460313501734_1c729c47", msg

  robot.on "ria_code_1460313556082_9cbbe969", (msg) ->
    states.room.remove()
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("sad")

  robot.on "ria_room_states_1460313556082_9cbbe969_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match robot.respondPattern /4e/i
    states.room.set msg, state: "1460313556082_5759e356"

  robot.on "ria_room_states_1460313556082_9cbbe969_message_default", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.match = msg.message.text.match robot.respondPattern /syda/i
    states.room.set msg, state: "1460313556082_5759e356"

  robot.on "ria_room_states_1460313556082_9cbbe969_sticker_1460313556082_5759e356", (msg, state) ->
    return unless 'Inzen' == msg.message.user.id
    return states.room.remove(msg) unless msg.message.field?.stickerID? and msg.match = msg.message.text.match /^[0-9]+$/
    undefinedrobot.emit "ria_code_1460313556082_9cbbe969", msg
