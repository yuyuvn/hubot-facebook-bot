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

  robot.on "ria_code_9d45c095", (msg) ->
    msg.sendSticker '1530358417204967'

  robot.respondSticker /1530358660538276/, (msg) ->
    return unless '100008976948319' == msg.message.user.id
    robot.emit "ria_code_9d45c095", msg
