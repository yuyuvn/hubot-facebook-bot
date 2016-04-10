# Description:
#   Fork, commit and make pull-request
#
# Dependencies:
#
# Configuration:
#   GITHUB_REPO
#   GITHUB_BRANCH (optional)
#   HUBOT_GITHUB_TOKEN
#
# Commands:
#
# Author:
#   clicia scarlet <yuyuvn@icloud.com>

github = require "githubot"
semantic = require("../lib/semantic").Singleton()
{CachedData} = require "../lib/state"

module.exports = (robot) ->
  states = code: new CachedData robot, "ria_code_states"
  github_config = repo: process.env.GITHUB_REPO,
  branch: process.env.GITHUB_BRANCH || "master"

  robot.router.get "/hubot/github/evolution/debug", (req, res) ->
    res.setHeader "content-type", "application/json"
    res.send states.code.raw_data()

  robot.router.get "/hubot/github/evolution/unlock", (req, res) ->
    res.setHeader "content-type", "application/json"
    states.code.remove "locked"
    res.send status: "OK"

  robot.router.get "/hubot/github/evolution", (req, res) ->
    res.setHeader "content-type", "text/plain"

    return res.send "Nothing to do" unless states.code.get("files")?
    return res.send "Coding..." if states.code.get "locked"

    robot.emit "run_evolution", res
    res.send "Coding..."

  robot.on "run_evolution", (res) ->
    state = states.code.get()
    return if state.locked or not state.files?
    states.code.set true, "locked"
    room = states.code.get "room"

    branch_name = "ria-#{new Date().getTime()}"
    issue_id = url = owner = head_sha = null


    robot.logger.debug "Create issue"
    github.post("repos/#{github_config.repo}/issues",
      title: "Chuẩn bị cho #{semantic.random semantic.say "#upgrade"} #{branch_name}").then (issue) ->
      issue_id = issue.number
      robot.logger.debug "Fork repo"
      github.post "repos/#{github_config.repo}/forks"
    .then (fork) ->
      owner = fork.owner.login
      url = fork.url
      robot.logger.debug "Get sha of head of branch"
      github.get "repos/#{github_config.repo}/git/refs/heads/#{github_config.branch}"
    .then (ref) ->
      head_sha = ref.object.sha
      robot.logger.debug "Get sha of base tree"
      github.get "/repos/#{github_config.repo}/git/commits/#{head_sha}"
    .then (ref) ->
      robot.logger.debug "Get base tree"
      github.get "/repos/#{github_config.repo}/git/trees/#{ref.tree.sha}", recursive: 1
    .then (ref) ->
      data = {}
      if ref.truncated
        # Repo is too big, can't delete file
        data.tree = []
        data.base_tree = ref.sha
        for file_name, file of state.files
          data.tree.push path: file_name, content: file.content, mode: "100644"
      else
        editted = {}
        remove = []
        tree = ref.tree
        # edit
        for file, index in tree
          if state.files[file.path]?
            f = state.files[file.path]
            if f.delete
              remove.push index
            else
              tree[index].content = f.content
              delete tree[index].sha
            editted[file.path] = true
        # delete
        for value, index in remove
          tree.splice value-index, 1
        # add
        for file_name, file of state.files
          continue if editted[file_name]
          tree.push path: file_name, content: file.content, mode: "100644"
          data.tree = tree

      robot.logger.debug "Create tree"
      github.post "#{url}/git/trees", data
    .then (ref) ->
      data =
        message: "Resolve ##{issue_id}"
        tree: ref.sha
        parents: [head_sha]
      robot.logger.debug "Create commit"
      github.post "#{url}/git/commits", data
    .then (ref) ->
      data = ref: "refs/heads/#{branch_name}", sha: ref.sha
      robot.logger.debug "Create branch"
      github.post "#{url}/git/refs", data
    .then ->
      robot.logger.debug "Create pull-request"
      data =
        title: semantic.random semantic.say "#upgrade cho em :please_prefix"
        body: "Resolve ##{issue_id}"
        head: "#{owner}:#{branch_name}"
        base: github_config.branch
      github.post "repos/#{github_config.repo}/pulls", data
    .then (pr) ->
      robot.logger.debug "Created pull request ##{pr.id} successfully"
      res.send "Em vừa tạo pull-request ở đây ạ\n#{pr.html_url}"
      states.code.clean()
    .catch (err) ->
      res.send "Bài lúc nãy em không nhớ được :'("
      states.code.remove "locked"
      robot.logger.debug err
      robot.logger.debug "Rolling back..."
      github.patch "repos/#{github_config.repo}/issues/#{issue_id}", {state: "closed"}

  robot.on "prepair_to_evolution_add_hutbot_scripts", (msg, files, cb) ->
    states.code.extend files: {}
    state = states.code.get()
    files_data = states.code.get "files"
    if files_data["hubot-scripts.json"]?
      scripts = JSON.parse state.files["hubot-scripts.json"].content
      for file in files
        script = file.replace /(^scripts\/|\.coffee$)/g, ""
        scripts.push script unless script in scripts
      files_data["hubot-scripts.json"].content = "#{JSON.stringify(scripts, null, 2)}\n"
      cb() if cb?
    else
      sha = ""
      data = ref: github_config.branch
      github.get("repos/#{github_config.repo}/contents/hubot-scripts.json", data).then (content) ->
        sha = content.sha
        github.get content.download_url
      .then (scripts) ->
        for file in files
          script = file.replace /(^scripts\/|\.coffee$)/g, ""
          scripts.push script unless script in scripts
        states.code.set content: "#{JSON.stringify(scripts, null, 2)}\n", sha: sha, "files", "hubot-scripts.json"
        cb() if cb?

  robot.on "prepair_to_evolution_add_external_scripts", (msg, libs, cb) ->
    states.code.extend files: {}
    state = states.code.get()
    files_data = states.code.get "files"
    if files_data["external-scripts.json"]?
      scripts = JSON.parse state.files["external-scripts.json"].content
      for script in libs
        scripts.push script unless script in scripts
      files_data["external-scripts.json"].content = "#{JSON.stringify(scripts, null, 2)}\n"
      cb() if cb?
    else
      sha = ""
      data = ref: github_config.branch
      github.get("repos/#{github_config.repo}/contents/external-scripts.json", data).then (content) ->
        sha = content.sha
        github.get content.download_url
      .then (scripts) ->
        for script in libs
          scripts.push script unless script in scripts
        states.code.set content: "#{JSON.stringify(scripts, null, 2)}\n", sha: sha, "files", "external-scripts.json"
        cb() if cb?

  robot.on "prepair_to_evolution_add_package", (msg, libs, cb) ->
    states.code.extend files: {}
    state = states.code.get()
    files_data = states.code.get "files"
    if files_data["package.json"]?
      scripts = JSON.parse state.files["package.json"].content
      dependencies = scripts.dependencies
      for lib, version of libs
        scripts.dependencies[lib] = version
      files_data["package.json"].content = "#{JSON.stringify(scripts, null, 2)}\n"
      cb() if cb?
    else
      sha = ""
      data = ref: github_config.branch
      github.get("repos/#{github_config.repo}/contents/package.json", data).then (content) ->
        sha = content.sha
        github.get content.download_url
      .then (scripts) ->
        dependencies = scripts.dependencies
        for lib, version of libs
          scripts.dependencies[lib] = version
        states.code.set content: "#{JSON.stringify(scripts, null, 2)}\n", sha: sha, "files", "external-scripts.json"
        cb() if cb?
