# Description:
#   Spam meo
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

module.exports = (robot) ->
  robot.hear /^spam meo (.+)$/, (msg) ->
    if msg.sendSticker
      msg.sendSticker msg.match[1]
