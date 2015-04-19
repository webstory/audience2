# CodeMirror, copyright (c) by Marijn Haverbeke and others
# Distributed under an MIT license: http://codemirror.net/LICENSE
((mod) ->
  if typeof exports is "object" and typeof module is "object" # CommonJS
    mod require("codemirror")
  else if typeof define is "function" and define.amd # AMD
    define ["codemirror"], mod
  # Plain browser env
  else
    mod CodeMirror
) (CodeMirror) ->
  "use strict"
  CodeMirror.defineMode "finaldraft", ->
    token: (stream, state) ->
      if stream.sol() is true
        state.indent = stream.indentation()

        if state.indent == 0
          token = if stream.match(/^INT\.|EXT\.|INT\/EXT\./) then "sceneheading" else "action"
          stream.skipToEnd()
          return token
        else
          stream.eatSpace()
          return null

      token = null

      if 10 <= state.indent <= 12 and stream.match(/^\S/) then token = "dialogue"
      if 16 <= state.indent <= 18 and
        (stream.match(/^\(.*\)?/) or stream.match(/\)\s*$/))
        then token = "parenthetical"
      if 20 <= state.indent <= 24 and stream.match(/^\S/) then token = "character"

      stream.skipToEnd()
      return token

    startState: ->
      return { escaped: false }

  CodeMirror.defineMIME "text/x-finaldraft", "txt"

