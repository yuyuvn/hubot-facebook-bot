# Description:
#   Accept facebook friend request
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

CronJob = require("cron").CronJob
Nightmare = require('nightmare')

semantic = require("../lib/semantic").Singleton()
module.exports = (robot) ->
  accept = () ->
    nightmare = Nightmare()

    nightmare.goto("https://www.facebook.com/login/")
    # .on 'console', (type, args...) ->
    #   robot.logger.debug arguments
    .wait 5000
    .exists "#loginbutton"
    .then (need_login) ->
      if need_login
        nightmare.type "email", process.env.FB_LOGIN_EMAIL
          .type "pass", process.env.FB_LOGIN_PASSWORD
          .click "#loginbutton"
          .wait 5000
      else
        Promise.resolve()
    .then () ->
      nightmare.click "._2n_9"
      .wait 5000
      .evaluate () ->
        new_requests = document.getElementsByName "actions[accept]"
        button.click() for button in new_requests if new_requests?
      .end()
    .catch (err) ->
      nightmare.end()
      throw err

  new CronJob "* * 7 * * *", accept

  robot.respond new RegExp("#{semantic.regex(":accept :friend")}", "i"), (msg) ->
    msg.send "vâng ạ"
    accept().then () ->
      msg.send "xong rồi ạ"
    .catch (err) ->
      robot.logger.debug err
