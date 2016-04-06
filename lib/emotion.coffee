path = require "path"
promisify = require "promisify-node"
fse = promisify require "fs-extra"
appDir = require "app-root-path"

class Emotion
  load_data: ->
    fse.readJson(appDir+"/data/emo.json").done (err, emo) => @data = emo

  load_data_sync: ->
    @data = fse.readJsonSync appDir + "/data/emo.json"

  get: (emotion) ->
    @load_data_sync() unless @data?
    @data[emotion]

emotion = null
module.exports = exports = {
  Emotion
  Singleton: ->
    emotion = if emotion? then emotion else new Emotion
    emotion.load_data() unless emotion.data?
    emotion
}
