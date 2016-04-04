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
    msg.send 'hihi'

  robot.respond /haha/, (msg) ->
    return unless '100008976948319' == msg.message.user.id
    robot.emit "ria_code_9d45c095", msg
