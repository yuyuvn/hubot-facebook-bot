path   = require "path"
should = require "should"

{Semantic} = require "../lib/semantic"

describe "Semantic parser", ->
  describe "parse word", ->
    beforeEach =>
      @semantic = new Semantic
      @semantic.syntax_data = {}
      @semantic.vocabulary_data =
        said: [":told", ":speaked", ":spam"]
        told: ["nói","bảo"]
        spam: [":spammed"]
        spammed: ["spam1", "spam2"]
        speaked: ["nhắc đến","nhắc tới"]
        sticker: ["con","em","mèo","moè","sticker","bé","thằng","emo"]

    afterEach =>
      delete @semantic

    it "parse constant word", =>
      @semantic.parse_word("test").should.deepEqual ["test"]

    it "parse link word", =>
      @semantic.parse_word(":sticker").should.deepEqual ["con","em","mèo","moè","sticker","bé","thằng","emo"]

    it "parse deep link word", =>
      @semantic.parse_word(":said").should.deepEqual ["nói","bảo", "nhắc đến","nhắc tới", "spam1","spam2"]

  describe "parse sentence", ->
    beforeEach =>
      @semantic = new Semantic
      @semantic.syntax_data =
        spam: [":spam :sticker"]
        constant: ["rarara :spam","kakaka"]
        simple: ["#subject #predicative"]
        subject: ["subject", ":noun"]
        predicative: [":verb", ":verb :noun"]
        loop: ["#loop2", "test"]
        loop2: ["#loop :told"]
      @semantic.vocabulary_data =
        said: [":told", ":speaked", "#spam"]
        told: ["nói","bảo"]
        spam: ["spam"]
        speaked: ["nhắc đến","nhắc tới"]
        sticker: ["con","em","mèo","moè","sticker","bé","thằng","emo"]
        verb: [":said",":stop"],
        noun: [":sticker"]
        stop: ["dừng","ngừng","ngưng"]

    afterEach =>
      delete @semantic

    it "parse constant sentence", =>
      @semantic.parse_syntax("constant sentence").should.deepEqual ["constant sentence"]

    it "parse link sentence", =>
      @semantic.parse_syntax("#constant sentence").should.deepEqual ["rarara spam sentence","kakaka sentence"]

    it "parse deep sentence", =>
      @semantic.parse_syntax("#simple").should.have.length 648

    it "parse sentence with data", =>
      @semantic.parse_syntax("#constant sentence", "#constant": "haha").should.deepEqual ["haha sentence"]

    it "parse link sentence with data", =>
      @semantic.parse_syntax("#simple", "#subject": "Clicia").should.have.length 72

    it "parse cycle loop sentence", =>
      @semantic.parse_syntax("#loop", "#subject": "Clicia").should.not.empty

  describe "utils", ->
    beforeEach =>
      @semantic = new Semantic
      @semantic.syntax_data = {}
      @semantic.vocabulary_data = {}

    afterEach =>
      delete @semantic

    it "load data from json", =>
      delete @semantic.syntax_data
      delete @semantic.vocabulary_data
      @semantic.load_data_sync()
      @semantic.syntax_data.should.not.empty()
      @semantic.vocabulary_data.should.not.empty()

    it "load data when say method is called", =>
      delete @semantic.syntax_data
      delete @semantic.vocabulary_data
      @semantic.say("abc").should.deepEqual ["abc"]
      @semantic.syntax_data.should.not.empty()
      @semantic.vocabulary_data.should.not.empty()

    it "send data to parse_syntax", =>
      @semantic.say("foo :bar", {":bar": "baz"}).should.deepEqual ["foo baz"]

    it "send array data", =>
      @semantic.say("foo :bar", {":bar": ["bar", "baz"]}).should.deepEqual ["foo bar", "foo baz"]

    it "convert array to reg_gex", =>
      @semantic.regex "f?oo :bar", ":bar": ["bar", "baz"]
      .should.equal "(?:f\\?oo bar|f\\?oo baz)"

    it "remove unique element", =>
      @semantic.syntax_data = test: [":test"]
      @semantic.vocabulary_data =
        test: [":test1", ":test2"]
        test1: [":foo"]
        test2: [":bar"]
        foo: ["test"]
        bar: ["test"]
      @semantic.say(":test").should.deepEqual ["test"]

    it "append array", =>
      @semantic.append(["first","second"],["next1","next2"]).should
      .deepEqual ["first next1","first next2","second next1","second next2"]

