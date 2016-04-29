class Emotion
  load_data_sync: ->
    @data = require "../data/emo.json"

  get: (emotion) ->
    @load_data_sync() unless @data?
    @data[emotion]

emotion = null
module.exports = exports = {
  Emotion
  Singleton: ->
    emotion = if emotion? then emotion else new Emotion
    emotion.load_data_sync() unless emotion.data?
    emotion
}
