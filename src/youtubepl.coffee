# Description
#   A hubot script that will add all youtube links to a playlist
#
# Configuration:
#   GOOGLE_OAUTH2_API_KEY
#   GOOGLE_OAUTH2_API_SECRET
#
# Commands:
#   hubot youtubepl - Gives you the URL for this room's playlist
#   hubot youtubepl prune # - Removes # of entries from the playlist
#   https://www.youtube.com/watch?v=ID - Add the video to the room's playlist
#   https://youtu.be/ID - Adds the video to the room's playlist
#
# Notes:
#
# Author:
#   Brian Hartvigsen <bhartvigsen@opendns.com>

async = require 'async'
google = require 'googleapis'
youtube = google.youtube 'v3'
oauth2 = google.auth.OAuth2
client = new oauth2 process.env.GOOGLE_OAUTH2_API_KEY,
  process.env.GOOGLE_OAUTH2_API_SECRET,
  'urn:ietf:wg:oauth:2.0:oob'
credsSet = false

module.exports = (robot) ->
  # OAUTH...
  unless process.env.GOOGLE_OAUTH2_API_KEY?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_KEY"
    return
  unless process.env.GOOGLE_OAUTH2_API_SECRET?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_SECRET"
    return

  # Turns out the brain can get loaded AFTER this script
  # So let's just call this whenever we might need auth
  oauth_set_creds = ->
    if credsSet
      return
    else
      if robot.brain.get 'youtubepl.token'
        robot.logger.info "Loading youtubepl.token from brain"
        client.setCredentials robot.brain.get 'youtubepl.token'
        credsSet = true
      else
        robot.logger.info "No youtubepl.token found in brain"

  oauth_authorize = (res) ->
    res.send client.generateAuthUrl {
      access_type: 'offline',
      scope: 'https://www.googleapis.com/auth/youtube.force-ssl'
    }

  oauth_verify = (res) ->
    client.getToken res.match[1], (err, tokens) ->
      robot.brain.set 'youtubepl.token', tokens
      client.setCredentials tokens
      res.send if err? then err else "All good here"

  get_room_playlist = (room, cb) ->
    if robot.brain.get('youtubepl.playlist.' + room)?
      cb null, robot.brain.get 'youtubepl.playlist.' + room
    else
      oauth_set_creds()
      youtube.playlists.insert {
        auth: client,
        part: 'snippet,status',
        resource: {
          snippet: {
            title: 'Playlist for ' + room,
          },
          status: {
            privacyStatus: 'unlisted'
          }
        }
      }, (err, response) ->
        if err?
          cb err, null
        else
          robot.brain.set 'youtubepl.playlist.' + room, response.id
          cb null, response.id

  prune_from_playlist = (playlist, num, res, cb) ->
    if num > 50 or num <= 0
      res.send "You can't delete #{num} entires, must be between 1 and 50"
      return

    oauth_set_creds()
    youtube.playlistItems.list {
      auth: client,
      part: 'id',
      maxResults: num,
      playlistId: playlist
    }, (err, videos) ->
      if err?
        res.send "Unable to get playlist items: #{err}"
      else
        async.eachSeries videos.items, (item, callback) ->
          youtube.playlistItems.delete {
            auth: client,
            id: item.id
          }, (err, response) ->
            if err? then callback err else callback()
        , (err) ->
          if err?
            res.send "Unable to delete from playlist: #{err}"
          else
            cb()

  prune_playlist = (playlist, res, cb) ->
    prune_from_playlist playlist, 5, res, cb

  insert_video_to_playlist = (video, playlist, res) ->
    oauth_set_creds()
    youtube.playlistItems.insert {
      auth: client,
      part: 'snippet',
      resource: {
        snippet: {
          playlistId: playlist,
          resourceId: {
            videoId: video,
            kind: 'youtube#video'
          }
        }
      }
    }, (err, response) ->
      if err?
        switch err.code
          when 403
            prune_playlist playlist, res, () ->
              # Try again!
              insert_video_to_playlist(video, playlist, res)
          else robot.logger.error "Unable to add that to the playlist :( (#{err})"
      else
        robot.logger.debug "Added that to the playlist!"

  update_playlist = (code, res) ->
    get_room_playlist res.message.room, (err, playlist) ->
      if err?
        res.send "Error updating playlist: #{err}"
      else
        insert_video_to_playlist code, playlist, res

  robot.respond /youtubepl authorize/i, (res) ->
    oauth_authorize res

  robot.respond /youtubepl verify (.*)/i, (res) ->
    oauth_verify res

  robot.hear /https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([^&]+)/i, (res) ->
    update_playlist res.match[1], res

  robot.hear /https?:\/\/(?:www\.)?youtu\.be\/([^?]+)/i, (res) ->
    update_playlist res.match[1], res

  robot.respond /youtubepl prune ([0-9]+)/i, (res) ->
    get_room_playlist res.message.room, (err, playlist) ->
      prune_from_playlist playlist, res.match[1], res, () ->
        res.send "Successfully deleted #{res.match[1]} items from the playlist"

  robot.respond /youtubepl delete playlist/i, (res) ->
    get_room_playlist res.message.room, (err, response) ->
      if err?
        res.send "Unable to find playlist to delete for #{res.message.room}: #{err}"
      else
        robot.brain.remove 'youtubepl.playlist.' + res.message.room
        res.send "Deleted playlist for room #{res.message.room}"

  robot.respond /youtubepl$/i, (res) ->
    get_room_playlist res.message.room, (err, response) ->
      if err?
        res.send "Unable to get/create playlist for #{res.message.room}: #{err}"
      else
        res.send "https://www.youtube.com/playlist?list=#{response}"

  robot.respond /(?:youtube|yt)(?: me)? (.*)/i, (msg) ->
    unless process.env.HUBOT_YOUTUBE_API_KEY
      return msg.send "You must configure the HUBOT_YOUTUBE_API_KEY environment variable"
    query = msg.match[1]
    maxResults = if process.env.HUBOT_YOUTUBE_DETERMINISTIC_RESULTS == 'true' then 1 else 15
    robot.http("https://www.googleapis.com/youtube/v3/search")
      .query({
        order: 'relevance'
        part: 'snippet'
        type: 'video'
        maxResults: maxResults
        q: query
        key: process.env.HUBOT_YOUTUBE_API_KEY
      })
      .get() (err, res, body) ->
        videos = JSON.parse(body)
        videos = videos.items

        unless videos? && videos.length > 0
          return msg.send "No video results for \"#{query}\""

        video  = msg.random videos
        msg.send "https://www.youtube.com/watch?v=#{video.id.videoId}"
        update_playlist "#{video.id.videoId}", msg
