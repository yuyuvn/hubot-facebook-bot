path   = require "path"
should = require "should"

{Emotion} = require "../lib/emotion"

describe "Emotion parser", ->
  beforeEach =>
    @emo = new Emotion

  afterEach =>
    delete @emo

  it "load data from json", =>
    @emo.load_data_sync()
    @emo.data.should.not.empty()

  it "load data when get method is called", =>
    @emo.get "sad"
    @emo.data.should.not.empty()

  it "can get emo", =>
    @emo.data = sad: ["144885159019084"]
    @emo.get("sad").should.deepEqual ["144885159019084"]

