# Description:
#   Spam meo
#
# Dependencies:
#
# Configuration:
#   YOUTUBE_CLIENT_ID
#   YOUTUBE_CLIENT_SECRET
#   YOUTUBE_REDIRECT # only host, do not include /hubot/...
#   YOUTUBE_RATE # default is 1000
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

module.exports = (robot) ->
  robot.respond new RegExp("lên youtube live spam(?:\\s+(?:\"(.*)\"|(.*)))?", "i"), (msg) ->
    message = msg.match[1] || msg.match[2]
    robot.brain.data.youtube = message: message if message
    msg.send "ok rồi ạ"

  robot.respond new RegExp("stream xong rồi", "i"), (msg) ->
    robot.brain.data.youtube = null
    msg.send "Vâng ạ"
