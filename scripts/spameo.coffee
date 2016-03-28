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

HubotFacebook = require 'hubot-facebook'

module.exports = (robot) ->
  robot.respond /spam meo (.+)/, (msg) ->
    if msg.sendSticker
      msg.sendSticker msg.match[1]

  robot.listeners.push new HubotFacebook.StickerListener robot, /^(144884852352448|144885022352431)$/, (msg) ->
    msg.sendSticker msg.match[0]
