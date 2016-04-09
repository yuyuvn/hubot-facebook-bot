path = require "path"
promisify = require "promisify-node"
fse = promisify require "fs-extra"
appDir = require "app-root-path"
escapeStringRegexp = require "escape-string-regexp"
unique = require "array-unique"

class Semantic
  load_data: ->
    fse.readJson(appDir + "/data/syntax.json").done (err, syntax) => @syntax_data = syntax
    fse.readJson(appDir + "/data/vocabulary.json").done (err, vocabulary) => @vocabulary_data = vocabulary

  load_data_sync: ->
    @syntax_data = fse.readJsonSync appDir + "/data/syntax.json"
    @vocabulary_data = fse.readJsonSync appDir + "/data/vocabulary.json"

  # Input is a key from syntax list
  # Output is string
  say: (sentence, data={}) ->
    @load_data_sync() unless @syntax_data? and @vocabulary_data?
    @parse_syntax sentence, data

  regex: (word, data={}) ->
    word_list = @say(word, data)
    word_list =
      escapeStringRegexp(word) for word in word_list
    "(?:#{word_list.join("|")})"

  # Input is string
  # Output is a key from syntax list and data
  listen: (sentence) ->
    # TODO

  # Private
  # Get a word from type
  parse_word: (word, deep=0) ->
    return [] if deep > 10
    if word.charAt(0) is ":"
      output = []
      words = @vocabulary_data[word.substr 1]
      throw "#{word} is not recognized" unless words?
      for w in words
        output = output.concat @parse_word w, deep+1
      unique output
    else
      return [word]

  parse_syntax: (syntax, data={}, deep=0) ->
    return [] if deep > 5
    tokens = syntax.split " "
    output = []
    for token in tokens
      if data[token]?
        data[token] = [data[token]] unless Array.isArray data[token]
        output = @append output, data[token]
        continue
      switch token.charAt(0)
        when "#"
          syntaxs = @syntax_data[token.substr 1]
          throw "#{token} is not recognized" unless syntaxs?
          child_output = []
          for _syntax in syntaxs
            child_output = child_output.concat @parse_syntax _syntax, data, deep+1
          output = @append output, child_output
        else
          output = @append output, @parse_word token, deep+1
    output

  append: (source, array) ->
    return source if not array? or array.length == 0
    return array if not source? or source.length == 0
    output = []
    for _source in source
      for _array in array
        output.push "#{_source} #{_array}"
    unique output

semantic = null
module.exports = exports = {
  Semantic
  Singleton: ->
    semantic = if semantic? then semantic else new Semantic
    semantic.load_data() unless semantic.syntax_data? and semantic.vocabulary_data?
    semantic
}

