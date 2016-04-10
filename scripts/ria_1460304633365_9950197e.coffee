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
  states =
    room: new RoomState robot, "1460304633365_9950197e"
  robot.on "ria_code_1460304633365_9950197e", (msg) ->
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("angry")

  robot.on "ria_room_states_1460304633365_9950197e_message_default", (msg, state) ->
    return states.room.remove() unless msg.match = msg.message.match /cc 4e/
    robot.emit "ria_code_1460304633365_9950197e", msg

  robot.on "ria_room_states_1460304633365_9950197e_message_default", (msg, state) ->
    return states.room.remove() unless msg.match = msg.message.match /cc syda/
    robot.emit "ria_code_1460304633365_9950197e", msg
