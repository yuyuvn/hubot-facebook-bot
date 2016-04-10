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
    room: new RoomState robot, "1460312258031_414dd762"
  robot.on "ria_code_1460312258031_414dd762", (msg) ->
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("angry")

  robot.on "ria_room_states_1460312258031_414dd762_message_default", (msg, state) ->
    return states.room.remove() unless msg.match = msg.message.match /cc 4e/i
    states.room.set msg, state: "1460312258031_cde33a09"

  robot.on "ria_room_states_1460312258031_414dd762_message_default", (msg, state) ->
    return states.room.remove() unless msg.match = msg.message.match /cc syda/i
    states.room.set msg, state: "1460312258031_cde33a09"

  robot.on "ria_room_states_1460312258031_414dd762_sticker_1460312258031_cde33a09", (msg, state) ->
    return states.room.remove() unless msg.message.field?.stickerID? and msg.match = msg.message.match /1530358710538271/
    robot.emit "ria_code_1460312258031_414dd762", msg
