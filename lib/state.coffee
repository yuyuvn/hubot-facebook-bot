{CachedData} = require "hubot-state"

class Stickers
  constructor: (robot) ->
    @data = new CachedData robot, "stickers"

  subscribe: (sticker_id, sticker_url) ->
    return false if @subscribing sticker_id
    @data.set sticker_url, sticker_id

  unsubscribe: (sticker_id) ->
    return false unless @subscribing sticker_id
    @data.remove sticker_id

  unsubscribe_all: ->
    return false unless @subscribing().length > 0
    @data.clean()

  subscribing: (sticker_id) ->
    if sticker_id?
      @data.get sticker_id
    else
      Object.keys @data.raw_data()

class CachedDataWraper
  constructor: (robot, key) ->
    @data = new CachedData robot, key
    robot.catchAll (msg) =>
      state_data = @get msg
      state = state_data?.state || "default"
      if msg.message.fields?.stickerID?
        robot.emit "#{key}_sticker_#{state}", msg, state_data
      else if msg.message.text?
        robot.emit "#{key}_message_#{state}", msg, state_data

  extend: (msg, objects...) ->
    @data.extend @get_path(msg), objects...

  get: (msg, objects...) ->
    @data.get @get_path(msg), objects...

  set: (msg, data, objects...) ->
    @data.set data, @get_path(msg), objects...

  remove: (msg, objects...) ->
    @data.remove @get_path(msg), objects...

  get_path: (msg) -> throw "get_path is not implemented"

class RoomState extends CachedDataWraper
  constructor: (robot, key) ->
    super robot, "ria_room_states_#{key}"

  get_path: (msg) -> msg.message?.room || msg

class UserState extends CachedDataWraper
  constructor: (robot, key) ->
    super robot, "ria_user_states_#{key}"

  get_path: (msg) -> msg.message?.user?.id || msg


module.exports = exports = {
  CachedData
  Stickers
  RoomState
  UserState
}
