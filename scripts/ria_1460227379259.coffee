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

  robot.on "ria_code_1460227356990_0", (msg) ->
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("no")

  robot.respond /4e/, (msg) ->
    return unless 'Inzen' == msg.message.user.id
    robot.emit "ria_code_1460227356990_0", msg

  robot.respond /syda/i, (msg) ->
    return unless 'Inzen' == msg.message.user.id
    robot.emit "ria_code_1460227356990_0", msg

  robot.on "ria_code_1460227364566_0", (msg) ->
    robot.emit "facebook.sendSticker", message: msg, sticker: msg.random emo.get("angry")

  robot.hear /cc 4e/, (msg) ->
    robot.emit "ria_code_1460227364566_0", msg

  robot.hear /cc syda/, (msg) ->
    robot.emit "ria_code_1460227364566_0", msg
