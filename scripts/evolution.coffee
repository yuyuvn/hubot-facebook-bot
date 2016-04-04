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

promisify = require "promisify-node"
github = promisify "githubot"

module.exports = (robot) ->
  github_config = repo: process.env.GITHUB_REPO,
  branch: process.env.GITHUB_BRANCH || "master"

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

    branch_name = "ria-#{new Date().getTime()}"
    issue_id = url = owner = null

    github.post("/repos/#{github_config.repo}/issues", title: "Chuẩn bị cho nâng cấp mới").then (issue) ->
      issue_id = issue.id
      github.post "/repos/#{github_config.repo}/forks", {}
    .then (fork) ->
      owner = fork.owner.login
      url = fork.url
      github.get "/repos/#{github_config.repo}/git/refs/heads/#{github_config.branch}"
    .then (ref) ->
      data = ref: "refs/heads/#{branch_name}", sha: ref.object.sha
      github.post "#{url}/git/refs", data
    .then ->
      Promise.all Object.keys(queue.files).map (file_name) ->
        data = message: "Cập nhật file #{file_name} cho issue ##{issue_id}", branch: branch_name,
        content: new Buffer(queue.files[file_name].content).toString 'base64'
        data.sha = queue.files[file_name].sha if queue.files[file_name].sha?
        github.put "#{url}/contents/#{file_name}", data
    .then ->
      data = title: "Resolve ##{issue_id} Nâng cấp cho em đi",
      body: "Cải tiến :heart_eyes:",
      head: "#{owner}:#{branch_name}",
      base: github_config.branch
      github.post "repos/#{github_config.repo}/pulls", data
    .done (pr) ->
      robot.logger.debug "Created pull request ##{pr.id}"
      robot.brain.remove "code_queue"

  robot.on "prepair_to_evolution_add_hutbot_scripts", (msg, files) ->
    queue = robot.brain.get "code_queue"
    queue = files: {} unless queue?
    queue.files = {} unless queue.files?
    sha = ""
    data = ref: github_config.branch
    github.get("/repos/#{github_config.repo}/contents/hubot-scripts.json").then (content) ->
      sha = content.sha
      github.get content.download_url
    .done (scripts) ->
      for file in files
        script = file.replace /(^scripts\/|\.coffee$)/g, ""
        scripts.push script unless script in scripts
      queue.files["hubot-scripts.json"] = content: "#{JSON.stringify(scripts, null, 2)}\n", sha: sha
      robot.brain.set "code_queue", queue

  robot.on "prepair_to_evolution_add_external_scripts", (msg, libs) ->
    queue = robot.brain.get "code_queue"
    queue = files: [] unless queue?
    queue.files = [] unless queue.files?
    sha = ""
    data = ref: github_config.branch
    github.get("/repos/#{github_config.repo}/contents/external-scripts.json").then (content) ->
      sha = content.sha
      github.get content.download_url
    .done (scripts) ->
      for file in libs
        scripts.push script unless script in scripts
      queue.files["external-scripts.json"] = content: "#{JSON.stringify(scripts, null, 2)}\n", sha: sha
      robot.brain.set "code_queue", queue

  robot.on "prepair_to_evolution_add_package", (msg, libs) ->
    queue = robot.brain.get "code_queue"
    queue = files: [] unless queue?
    queue.files = [] unless queue.files?
    sha = ""
    data = ref: github_config.branch
    github.get("/repos/#{github_config.repo}/contents/external-scripts.json").then (content) ->
      sha = content.sha
      github.get content.download_url
    .done (scripts) ->
      dependencies = scripts.dependencies
      for lib, version of libs
        scripts.dependencies[lib] = version
      queue.files["external-scripts.json"] = content: "#{JSON.stringify(scripts, null, 2)}\n", sha: sha
      robot.brain.set "code_queue", queue
