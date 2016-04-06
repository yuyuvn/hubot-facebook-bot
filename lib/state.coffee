extend = require "extend"

class CachedData
  constructor: (@robot, @key) ->
    @robot.brain.on 'loaded', =>
      @robot.brain.data[@key] = @raw_data()

  raw_data: ->
    @robot.brain.data[@key] || {}

  extend: (objects...) ->
    data = @raw_data()
    extend true, data, objects...
    @set data

  get: (paths...) ->
    data = @raw_data()
    for path in paths
      return null if not data[path]?
      data = data[path]
    data

  set: (value, paths...) ->
    data = parent_data = @raw_data()
    last_path = paths.splice(-1,1)[0]
    for path in paths
      parent_data[path] = {} if not parent_data[path]?
      parent_data = parent_data[path]
    if last_path?
      parent_data[last_path] = value
    else
      data = value
    @robot.brain.data[@key] = data

  remove: (paths...) ->
    data = parent_data = @raw_data()
    last_path = paths.splice(-1,1)[0]
    for path in paths
      return if not parent_data[path]?
      parent_data = parent_data[path]
    if last_path?
      delete parent_data[last_path]
    else
      data = {}
    @robot.brain.data[@key] = data

  clean: ->
    @robot.brain.data[@key] = {}


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
      @data.get(sticker_id)
    else
      Object.keys @data.raw_data()

class State
  constructor: (robot) ->
    @room = new CachedData robot, "ria_room_states"
    # @user = new CachedData robot, "ria_user_states"
    @stickers = new Stickers robot
    @code = new CachedData robot, "ria_code_states"

module.exports = exports = {
  CachedData,
  State
}
