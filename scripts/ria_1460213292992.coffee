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
  states = new State robot

  robot.on "ria_code_c9e8561d", (msg) ->
    robot.emit "facebook.sendSticker", message: msg, sticker: "1530358467204962"

  robot.respond /syda/i, (msg) ->
    return unless 'Inzen' == msg.message.user.id
    robot.emit "ria_code_c9e8561d", msg

  robot.respond /4e/, (msg) ->
    return unless 'Inzen' == msg.message.user.id
    robot.emit "ria_code_c9e8561d", msg
