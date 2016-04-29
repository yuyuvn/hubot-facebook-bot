# Description:
#   youtube
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

semantic = require("../lib/semantic").Singleton()
module.exports = (robot) ->
  robot.respond new RegExp("#{semantic.regex("lên youtube live :spam")}(?:\\s+(?:\"(.*)\"|(.*)))?", "i"), (msg) ->
    message = msg.match[1] || msg.match[2]
    robot.brain.data.youtube = message: message if message
    msg.send "ok rồi ạ"

  robot.respond new RegExp("stream xong rồi", "i"), (msg) ->
    robot.brain.data.youtube = null
    msg.send "Vâng ạ"
