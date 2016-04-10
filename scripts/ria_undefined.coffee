# Description:
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   Ria Scarlet

emo = require("../lib/emotion").Singleton()
semantic = require("../lib/semantic").Singleton()
{State} = require "../lib/state"

module.exports = (robot) ->
  states =
    room: new RoomState robot, "undefined"undefined