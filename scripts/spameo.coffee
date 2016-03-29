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

class Stickers
  constructor: (@robot) ->
    @cached = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.stickers
        @cached = @robot.brain.data.stickers
      else
        @robot.brain.data.stickers = {}

  subscribe: (sticker_id, sticker_url) ->
    return false if @subscribing(sticker_id)
    @cached[sticker_id] = sticker_url
    @robot.brain.data.stickers = @cached

  unsubscribe: (sticker_id) ->
    return false if not @subscribing(sticker_id)
    delete @cached[sticker_id]
    @robot.brain.data.stickers = @cached

  unsubscribe_all: ->
    return false if Object.keys(@cached).length < 1
    @cached = {}
    @robot.brain.data.stickers = @cached

  subscribing: (sticker_id) ->
    @cached[sticker_id]?

class StatesCollection
  constructor: (@robot) ->
    @cached = {}
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.meo_states
        @cached = @robot.brain.data.meo_states
      else
        @robot.brain.data.meo_states = {}

  get_state: (msg) ->
    room = msg.message.room
    @cached[room]

  set_state: (state) ->
    room = state.room
    @cached[room] = state
    @robot.brain.data.meo_states = @cached

  reset_state: (msg) ->
    room = msg.message.room
    if @cached[room]?
      delete @cached[room]
      @robot.brain.data.meo_states = @cached

module.exports = (robot) ->
  states = new StatesCollection robot
  stickers = new Stickers robot

  robot.respond /spam (con|em|mèo|moè|sticker|bé|thằng) ([0-9]+)/i, (msg) ->
    msg.sendSticker msg.match[2] if msg.sendSticker
    states.reset_state msg

  robot.respond /ngừng spam(.*)/i, (msg) ->
    match = msg.match[1].match /^\s(con|em|mèo|moè|sticker|bé|thằng) này/i
    if match?
      states.set_state room: msg.message.room, state: "remove"
    else
      msg.sendSticker if stickers.unsubscribe_all() then "144885159019084" else "144884895685777"
      states.reset_state msg

  robot.respond /spam (con|em|mèo|moè|sticker|bé|thằng) này/i, (msg) ->
    states.set_state room: msg.message.room, state: "add"

  robot.listeners.push new HubotFacebook.StickerListener robot, /^.+$/, (msg) ->
    sticker_id = msg.match[0]
    sticker_url = msg.message.text

    state = states.get_state msg
    if state?
      switch state.state
        when "add"
          if stickers.subscribe sticker_id, sticker_url
            msg.send "Từ giờ em sẽ spam #{sticker_id} :3"
          else
            msg.send "Em spam #{sticker_id} lâu rồi mà -_-"
        when "remove"
          if stickers.unsubscribe sticker_id, sticker_url
            msg.send "Từ giờ em sẽ ngừng spam #{sticker_id} ạ :'("
          else
            msg.send "Em đã bao giờ spam #{sticker_id} đâu :/"
        when "spam"
          msg.sendSticker sticker_id if sticker_id isnt state.id and stickers.subscribing(sticker_id)
    else
      msg.sendSticker sticker_id if stickers.subscribing(sticker_id)
    states.set_state room: msg.message.room, state: "spam", id: sticker_id


  robot.router.get "/hubot/facebook/stickers", (req, res) ->
    res.setHeader 'content-type', 'application/json'
    res.send stickers.cached

  robot.catchAll (msg) ->
    states.reset_state msg
