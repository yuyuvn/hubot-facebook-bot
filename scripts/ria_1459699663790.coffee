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
    msg.send 'có inzen 4e thì có'

  robot.respond /4e/, (msg) ->
    return unless 'keitenou' == msg.message.user.id
    robot.emit "ria_code_9d45c095", msg
