module.exports = (robot) ->
  keepaliveCallback = (req, res) ->
    res.set 'Content-Type', 'text/plain'
    res.send 'OK'

  robot.router.post "/heroku/keepalive", keepaliveCallback
  robot.router.get "/heroku/keepalive", keepaliveCallback
