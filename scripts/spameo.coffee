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

class CachedData
  constructor: (@robot, @key) ->
    @cached = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data[@key]?
        @cached = @robot.brain.data[@key]
      else
        @robot.brain.data[@key] = @cached

  get: (paths...) ->
    data = @cached
    for path in paths
      return null if not data[path]?
      data = data[path]
    data

  set: (value, paths...) ->
    parent_data = @cached
    last_path = paths.splice(-1,1)
    for path in paths
      parent_data[path] = {} if not parent_data[path]?
      parent_data = parent_data[path]
    parent_data[last_path] = value
    @robot.brain.data[@key] = @cached

  remove: (paths...) ->
    parent_data = @cached
    last_path = paths.splice(-1,1)
    for path in paths
      return if not parent_data[path]?
    delete parent_data[last_path]
    @robot.brain.data[@key] = @cached

  clean: ->
    @cached = {}
    @robot.brain.data[@key] = @cached


class Stickers
  constructor: (robot) ->
    @data = new CachedData robot, "stickers"

  subscribe: (sticker_id, sticker_url) ->
    return false if @subscribing(sticker_id)
    @data.set sticker_url, sticker_id

  unsubscribe: (sticker_id) ->
    return false if not @subscribing(sticker_id)
    @data.remove sticker_id

  unsubscribe_all: ->
    return false if Object.keys(@data.cached).length < 1
    @data.clean

  subscribing: (sticker_id) ->
    @data.get(sticker_id)?

module.exports = (robot) ->
  states = new CachedData robot, "ria_states"
  stickers = new Stickers robot

  robot.respondSticker = (regex, callback) ->
    robot.listeners.push new HubotFacebook.StickerListener robot, regex, callback

  robot.respond /spam (con|em|mèo|moè|sticker|bé|thằng) ([0-9]+)/i, (msg) ->
    msg.sendSticker msg.match[2] if msg.sendSticker
    robot.emit "reset_state", msg

  robot.respond /ngừng spam(.*)/i, (msg) ->
    match = msg.match[1].match /^\s(con|em|mèo|moè|sticker|bé|thằng) này/i
    if match?
      states.set "remove", msg.message.room
    else
      msg.sendSticker if stickers.unsubscribe_all() then "144885159019084" else "144884895685777"
      robot.emit "reset_state", msg

  robot.respond /spam (con|em|mèo|moè|sticker|bé|thằng) này/i, (msg) ->
    states.set "add", msg.message.room

  robot.respondSticker /^.+$/, (msg) ->
    sticker_id = msg.match[0]
    sticker_url = msg.message.text

    state_data = states.get msg.message.room
    if state_data?
      state = state_data.state? or state_data
      switch state
        when "add"
          if stickers.subscribe sticker_id, sticker_url
            msg.send "Từ giờ em sẽ spam #{sticker_id} :3"
          else
            msg.send "Em spam #{sticker_id} lâu rồi mà -_-"
          robot.emit "reset_state", msg
        when "remove"
          if stickers.unsubscribe sticker_id, sticker_url
            msg.send "Từ giờ em sẽ ngừng spam #{sticker_id} ạ :'("
          else
            msg.send "Em đã bao giờ spam #{sticker_id} đâu :/"
          robot.emit "reset_state", msg
        when "spam"
          spam = sticker_id isnt state_data.id and stickers.subscribing(sticker_id)
    else
      spam = stickers.subscribing(sticker_id)

    if spam
      rand = Math.random()*100
      if rand <= 70
        msg.sendSticker sticker_id
        states.set state: "spam", id: sticker_id, msg.message.room
      else if rand <= 90
        robot.emit "send_random_sticker", msg

  robot.router.get "/hubot/facebook/stickers", (req, res) ->
    res.setHeader 'content-type', 'application/json'
    res.send stickers.data.cached

  robot.on "reset_state", (msg) ->
    states.clean msg.message.room

  robot.on "send_random_sticker", (msg) ->
    sticker_ids = Object.keys(stickers.data.cached)
    return if sticker_ids.length < 1
    sticker_id = msg.random sticker_ids
    msg.sendSticker sticker_id

  robot.catchAll (msg) ->
    if states.get(msg.message.room)?
      robot.emit "reset_state", msg
    else
      rand = Math.random()*100
      robot.emit "send_random_sticker", msg if rand <= 5
