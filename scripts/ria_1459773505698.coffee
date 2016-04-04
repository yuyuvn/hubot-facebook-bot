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

  robot.on "ria_code_668ee01c", (msg) ->
    msg.sendSticker '144884895685777'

  robot.respond /hehe/, (msg) ->
    return unless '100008976948319' == msg.message.user.id
    room_states.set state: "c679f06c", msg.message.room

  robot.respond /kaka/, (msg) ->
    return unless '100008976948319' == msg.message.user.id
    room_states.set state: "c679f06c", msg.message.room

  robot.on "room_state_handler_message_c679f06c", (msg, state) ->
    return unless '100008976948319' == msg.message.user.id
    return robot.emit "room_state_handler_message_default" unless msg.match = msg.message.match robot.respondPattern /khà khà/
    room_states.set state: "2df14a17", msg.message.room

  robot.on "room_state_handler_message_c679f06c", (msg, state) ->
    return unless '100008976948319' == msg.message.user.id
    return robot.emit "room_state_handler_message_default" unless msg.match = msg.message.match robot.respondPattern /lala/
    room_states.set state: "2df14a17", msg.message.room

  robot.on "room_state_handler_message_2df14a17", (msg, state) ->
    return unless '100008976948319' == msg.message.user.id
    return robot.emit "room_state_handler_message_default" unless msg.match = msg.message.match robot.respondPattern /zaza/
    robot.emit "ria_code_668ee01c", msg

  robot.on "ria_code_13cdb765", (msg) ->
    msg.sendSticker '144885195685747'

  robot.respond /hê hê/, (msg) ->
    return unless '100008976948319' == msg.message.user.id
    room_states.set state: "4bb98b0b", msg.message.room

  robot.on "room_state_handler_message_4bb98b0b", (msg, state) ->
    return unless '100008976948319' == msg.message.user.id
    return robot.emit "room_state_handler_message_default" unless msg.match = msg.message.match robot.respondPattern /ra ra/
    room_states.set state: "668be87d", msg.message.room

  robot.on "room_state_handler_message_668be87d", (msg, state) ->
    return unless '100008976948319' == msg.message.user.id
    return robot.emit "room_state_handler_message_default" unless msg.message.stickerID? and msg.match = msg.message.match /144885159019084/
    robot.emit "ria_code_13cdb765", msg
