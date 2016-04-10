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
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("angry")

  robot.hear /cc 4e/, (msg) ->
    robot.emit "ria_code_c9e8561d", msg

  robot.hear /cc syda/, (msg) ->
    robot.emit "ria_code_c9e8561d", msg
