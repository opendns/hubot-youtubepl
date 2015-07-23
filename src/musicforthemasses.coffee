modules.exports = (robot) ->

  # OAUTH...
  unless process.env.HUBOT_YOUTUBE_CLIENTID?
    robot.logger.warning "Need HUBOT_YOUTUBE_CLIENTID"
    return
  unless process.env.HUBOT_YOUTUBE_CLIENTSECRET?
    robot.logger.warning "Need HUBOT_YOUTUBE_CLIENTSECRET"
    return

  # Need to store the token stuff... But where

  update_playlist = (code) ->
    # Do stuff here

  robot.hear /https?:\/\/(www\.)?youtube\.com\/watch?v=([^&]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.hear /https?:\/\/(www\.)?youtu\.be\/([^?]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.respond /playlist/i, (res) ->
    res.send "I should give you the playlist url here"
