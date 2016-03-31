# Description:
#   Spam meo
#
# Dependencies:
#
# Configuration:
#   GITHUB_REPO
#   GITHUB_BRANCH (optional)
#   GITHUB_USERNAME
#   GITHUB_PASSWORD
#   GITHUB_ORINGIN
#   CLONE_PATH (optional)
#   HUBOT_GITHUB_TOKEN
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

nodegit = require "nodegit"
path = require "path"
promisify = require "promisify-node"
fse = promisify require "fs-extra"
appDir = require "app-root-path"

module.exports = (robot) ->
  github = require("githubot")(robot)
  github_config = repo: process.env.GITHUB_REPO,
  branch: process.env.GITHUB_BRANCH || "master",
  username: process.env.GITHUB_USERNAME,
  password: process.env.GITHUB_PASSWORD,
  origin: process.env.GITHUB_ORINGIN
  temp_path = process.env.CLONE_PATH || "#{appDir}/tmp/ria_clone"

  robot.router.get "/hubot/github/evolution/debug", (req, res) ->
    res.setHeader 'content-type', 'text/plain'
    res.send robot.brain.get("code_queue") || "Null"

  #robot.router.post "/hubot/github/evolution", (req, res) ->
  robot.router.get "/hubot/github/evolution", (req, res) ->
    res.setHeader 'content-type', 'text/plain'
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    #return if data.token != process.env.HUBOT_GITHUB_TOKEN

    queue = robot.brain.get "code_queue"
    return res.send "Nothing to do" unless queue?
    #return res.send "Coding..." if queue.locked

    action = queue.state || "run_evolution"
    robot.emit action, res
    res.send "Coding..."

  robot.on "run_evolution", (res) ->
    queue = robot.brain.get "code_queue"
    queue.locked = true
    robot.brain.set "code_queue", queue
    robot.brain.save

    branch_name = "ria-#{(new Date).getTime()}"
    repo = index = oid = null

    fse.remove(temp_path).then ->
      nodegit.Clone "https://github.com/#{github_config.repo}.git",
        temp_path,
        checkoutBranch: github_config.branch
        fetchOpts:
          callbacks:
            certificateCheck: ->
              1
    .then (r) ->
      repo = r
      repo.getBranchCommit github_config.branch
    .then (commit) ->
      repo.createBranch branch_name, commit, 1
    .then (branch) ->
      repo.checkoutBranch branch
    .then ->
      Promise.all Object.keys(queue.files).map (file_name) ->
        fse.writeFile path.join(temp_path, file_name),  queue.files[file_name]
    .then ->
      repo.openIndex()
    .then (i) ->
      index = i
      index.addAll()
    .then ->
      index.write()
    .then ->
      index.writeTree()
    .then (o) ->
      oid = o
      nodegit.Reference.nameToId repo, "refs/heads/#{branch_name}"
    .then (commit) ->
      repo.getCommit commit
    .then (parent) ->
      author = nodegit.Signature.create "Ria Scarlet",
        "yuyuvn@icloud.com", (new Date).getTime(), 0
      committer = nodegit.Signature.create "Ria Scarlet",
        "yuyuvn@icloud.com", (new Date).getTime(), 0
      repo.createCommit "HEAD", author, committer, "Update", oid, [parent]
    .then ->
      nodegit.Remote.create repo, "ria_origin", "https://github.com/#{github_config.origin}.git"
    .then (remote) ->
      return remote.push ["refs/heads/#{branch_name}:refs/heads/#{branch_name}"],
        callbacks:
          credentials: ->
            return nodegit.Cred.userpassPlaintextNew github_config.username, github_config.password
    .then ->
      data = title: "Nâng cấp cho em đi",
      body: "Cải tiến :heart_eyes:",
      head: "#{github_config.origin.split("/")[0]}:#{branch_name}",
      base: github_config.branch
      github.post "repos/#{github_config.repo}/pulls", data, (pr) ->
        robot.logger.debug "Created pull request #{pr.id}"
    .done ->
      robot.brain.remove "code_queue"

  robot.on "prepair_to_evolution_add_hutbot_scripts", (msg, files) ->
    queue = robot.brain.get "code_queue"
    queue = files: {} unless queue?
    queue.files = {} unless queue.files?
    robot.http("https://raw.githubusercontent.com/#{github_config.repo}/\
      #{github_config.branch}/hubot-scripts.json").get() (err, res, body) ->
        scripts = JSON.parse body
        for file in files
          script = file.replace /(^scripts\/|\.coffee$)/, ""
          scripts.push script unless script in scripts
        queue.files["hubot-scripts.json"] = "#{JSON.stringify(scripts, null, 2)}\n"

  robot.on "prepair_to_evolution_add_external_scripts", (msg, libs) ->
    queue = robot.brain.get "code_queue"
    queue = files: [] unless queue?
    queue.files = [] unless queue.files?
    robot.http("https://raw.githubusercontent.com/#{github_config.repo}/\
      #{github_config.branch}/external-scripts.json").get() (err, res, body) ->
        scripts = JSON.parse body
        for script in libs
          scripts.push script unless script in scripts
        queue.files["external-scripts.json"] = "#{JSON.stringify(scripts, null, 2)}\n"

  robot.on "prepair_to_evolution_add_package", (msg, libs) ->
    queue = robot.brain.get "code_queue"
    queue = files: [] unless queue?
    queue.files = [] unless queue.files?
    robot.http("https://raw.githubusercontent.com/#{github_config.repo}/\
      #{github_config.branch}/package.json").get() (err, res, body) ->
        data = JSON.parse body
        dependencies = data.dependencies
        for lib, version of libs
          data.dependencies[lib] = version
        queue.files["package.json"] = "#{JSON.stringify(data, null, 2)}\n"


