# Description:
#   Github message
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

CronJob = require("hubot-cronjob")
semantic = require("../lib/semantic").Singleton()
GithubLED = require("github-profile-message")
gl = new GithubLED()
{RoomState} = require "../lib/state"

module.exports = (robot) ->
  states = room: new RoomState robot, "gpm"

  post = () ->
    message = robot.brain.data["github-profile-message"]
    gl.post message if message?

  new CronJob "0 0 1 * *", null, post

  emit_or_wait = (type, msg, state, offset=1) ->
    if msg.match[offset]
      msg.message.text = msg.match[offset]
      robot.emit "ria_room_states_gpm_message_#{type}", msg, state
    else
      states.room.set msg, type, "state"

  robot.respond new RegExp("#{semantic.regex ":post"} github profile(?:\\s+(\".+\"))?","i"), (msg) ->
    emit_or_wait "gpm_wait_for_message", msg, states.room.get(msg)

  robot.on "ria_room_states_gpm_message_gpm_wait_for_message", (msg, state) ->
    return unless msg.match = msg.message.text.match new RegExp "^(?:#{robot.alias}|#{robot.name})?\\s*(?:\"(.+)\"|(.+))"
    message = msg.match[1] || msg.match[2]
    states.room.set msg, state: "default"
    if gl.verify_message message
      msg.send "Em không post được từ dài quá 8 kí tự đâu :'("
    else
      robot.brain.data["github-profile-message"] = message
      post().then () -> msg.send "Em post xong rồi ạ :3"
