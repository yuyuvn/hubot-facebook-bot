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

module.exports = (robot) ->

  robot.on "ria_code_1a1ee189", (msg) ->
    msg.sendSticker '144884895685777'

  robot.hear /ria/i, (msg) ->

    room_states.set state: "ad39ccd5", msg.message.room

  robot.on "room_state_handler_message_ad39ccd5", (msg, state) ->
    return robot.emit "room_state_handler_message_default" unless msg.message.stickerID? and msg.match = msg.message.match /144884739019126/
    robot.emit "ria_code_1a1ee189", msg
