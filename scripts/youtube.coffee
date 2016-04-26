# Description:
#   Spam meo
#
# Dependencies:
#
# Configuration:
#   YOUTUBE_CLIENT_ID
#   YOUTUBE_CLIENT_SECRET
#   YOUTUBE_REDIRECT # only host, do not include /hubot/...
#   YOUTUBE_RATE # default is 1000
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

google = require('googleapis')
OAuth2 = google.auth.OAuth2
parse = require("url-parse")

params =
  clientId: process.env.YOUTUBE_CLIENT_ID
  clientSecret: process.env.YOUTUBE_CLIENT_SECRET
  redirect: (process.env.YOUTUBE_REDIRECT || "http://localhost") + "/hubot/youtube/oauth2"
  rate: process.env.YOUTUBE_RATE || 1000
  scope: ['https://www.googleapis.com/auth/youtube',
    'https://www.googleapis.com/auth/youtube.force-ssl',
    'https://www.googleapis.com/auth/youtube.readonly']
oauth2Client = new OAuth2 params.clientId, params.clientSecret, params.redirect
youtube = null

module.exports = (robot) ->
  robot.respond new RegExp("lên youtube live spam(?:\\s+(?:\"(.*)\"|(.*)))?", "i"), (msg) ->
    url = oauth2Client.generateAuthUrl scope: params.scope
    message = msg.match[1] || msg.match[2]
    robot.brain.data.youtube = message: message if message
    msg.send "Anh vào link này đi ạ\n#{url}"

  robot.respond new RegExp("stream xong rồi", "i"), (msg) ->
    youtube.stop()
    msg.send "Vâng ạ"

  robot.router.get "/hubot/youtube/oauth2", (req, res) ->
    query = parse(req.url, true).query

    oauth2Client.getToken query.code, (err, tokens) =>
      return res.send "Error: ", err if err?

      message = robot.brain.data.youtube?.message || ""
      if youtube?
        youtube.getBroadcastList -> res.send "OK"
      else
        youtube = new YoutubeChat
        youtube.login tokens, (err) =>
          robot.logger.debug err if err?
          res.send "OK"
          youtube.listen (err, item) =>
            robot.logger.debug err if err?
            if message
              youtube.insert message, item.snippet.liveChatId, (err) ->
                robot.logger.debug err if err?

class YoutubeChat
  getLiveChat: (broadcast_id, pageToken=null, cb) ->
    [cb, pageToken] = [pageToken, null] unless cb?

    filter = part: "id, snippet", liveChatId: broadcast_id, maxResults: 2000
    filter.pageToken = @broadcasts[broadcast_id].pageToken if @broadcasts[broadcast_id].pageToken?

    @youtube.liveChatMessages.list filter, (err, response) =>
      return cb(err) if err?

      return unless response.items?
      for item in response.items
        date = new Date(item.snippet.publishedAt)
        continue if @broadcasts[broadcast_id].lastPublished? and @broadcasts[broadcast_id].lastPublished >= date
        @broadcasts[broadcast_id].lastPublished = date
        cb(err, item) if item.snippet.authorChannelId != @bot_channel
      @broadcasts[broadcast_id].pageToken = pageToken
      @getLiveChat broadcast_id, response.pageToken, cb if response.pageToken?

  getBroadcastList: (pageToken=null, cb) ->
    [cb, pageToken] = [pageToken, null] unless cb?

    filter = part: "snippet", maxResults: 50, broadcastType: "all"
    if process.env.HUBOT_YOUTUBE_BROADCASTS?
      filter.id = process.env.HUBOT_YOUTUBE_FILTER_IDS
    else if process.env.HUBOT_YOUTUBE_FILTER_STATUS?
      filter.broadcastStatus = process.env.HUBOT_YOUTUBE_FILTER_STATUS
    else
      filter.mine = true
    filter.pageToken = pageToken if pageToken?

    @youtube.liveBroadcasts.list filter, (err, response) =>
      return cb(err) if err?

      return unless response.items?
      for item in response.items
        item = item.snippet
        @broadcasts[item.liveChatId] = lastPublished: new Date() if item.liveChatId?
      if response.nextPageToken?
        @getBroadcastList(response.nextPageToken, cb)
      else
        cb()

  login: (tokens, cb) ->
    oauth2Client.setCredentials tokens
    @youtube = google.youtube
      version: 'v3'
      auth: oauth2Client

    @youtube.channels.list part: "id", mine: true, (err, res) =>
      return cb(err) if err?
      @bot_channel = res.items[0].id if res.items? and res.items[0]?
      @broadcasts = []
      @getBroadcastList cb

  listen: (cb) ->
    @listener = setInterval =>
      for broadcast_id in Object.keys @broadcasts
        @getLiveChat broadcast_id, cb
    , params.rate

  insert: (message, broadcast, cb) ->
    body = snippet:
      liveChatId: broadcast
      type: "textMessageEvent"
      textMessageDetails: messageText: message
    @youtube.liveChatMessages.insert part: "snippet", resource: body, cb

  stop: () ->
    clearInterval(@listener) if @listener?
    @listener = null
