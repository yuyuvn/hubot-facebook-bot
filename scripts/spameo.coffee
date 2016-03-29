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
  respam_list = (process.env.RESPAM_MEO || "").split "|"
  robot.respond /spam mèo (.+)/, (msg) ->
    if msg.sendSticker
      msg.sendSticker msg.match[1]

  robot.listeners.push new HubotFacebook.StickerListener robot, /^.+$/, (msg) ->
    sticker_id = msg.match[0]
    stickers = robot.brain.get("stickers") || {}
    if !stickers[sticker_id]
      stickers[sticker_id] = msg.message.text
      robot.brain.set "stickers", stickers
      robot.brain.save
    else if sticker_id in respam_list
      msg.sendSticker sticker_id

  robot.router.get "/hubot/facebook/stickers", (req, res) ->
    stickers = robot.brain.get("stickers") || {}
    data = JSON.stringify {stickers: stickers}
    res.setHeader 'content-type', 'application/json'
    res.send data
