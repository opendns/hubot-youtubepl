modules.exports = (robot) ->
  unless process.evn.HUBOT_YOUTUBE_API?
    robot.logger.warning "Need HUBOT_YOUTUBE_API"
    return

  update_playlist = (code) ->
    # Do stuff here

  robot.hear /https?:\/\/(www\.)?youtube\.com\/watch?v=([^&]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.hear /https?:\/\/(www\.)?youtu\.be\/([^?]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.respond /playlist/i, (res) ->
    res.send "I should give you the playlist url here"
