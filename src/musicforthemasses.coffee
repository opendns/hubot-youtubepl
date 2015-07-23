# Description
#   A hubot script that does the things
#
# Configuration:
#   HUBOT_YOUTUBE_CLIENTID
#   HUBOT_YOUTUBE_CLIENTSECRET
#
# Commands:
#   hubot playlist - Gives you the URL for this room's playlist
#   https?://(www.)?youtube.com/watch?v=ID - Adds to playlist
#   https?://(www.)?youtu.be/ID - Adds to playlist
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Brian Hartvigsen <brian.andrew@brianandjenny.com>

google = require 'googleapis'
youtube = google.youtube 'v3'
oauth2 = google.auth.OAuth2
client = new oauth2 process.env.GOOGLE_OAUTH2_API_KEY, process.env.GOOGLE_OAUTH2_API_SECRET, 'urn:ietf:wg:oauth:2.0:oob'

module.exports = (robot) ->
  # OAUTH...
  unless process.env.GOOGLE_OAUTH2_API_KEY?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_KEY"
    return
  unless process.env.GOOGLE_OAUTH2_API_SECRET?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_SECRET"
    return

  if robot.brain.get 'youtubepl.token'
    client.setCredentials robot.brain.get('youtubepl.token')

  # Need to store the token stuff... But where

  get_room_playlist = (room, cb) ->
    if robot.brain.get('youtubepl.playlist.' + room)?
      cb(null, robot.brain.get('youtubepl.playlist.' + room))
    else
      youtube.playlists.insert({
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
          cb(err, null)
        else
          robot.brain.set 'youtubepl.playlist.' + room, response.id
          cb(null, response.id)
      )


  update_playlist = (code, res) ->
    get_room_playlist(res.message.room, (err, playlist) ->
      if err?
        res.send "Error updating playlist: #{err}"
        return

      youtube.playlistItems.insert({
        auth: client,
        part: 'snippet',
        resource: {
          snippet: {
            playlistId: playlist,
            resourceId: {
              videoId: code,
              kind: 'youtube#video'
            }
          }
        }
      }, (err, response) ->
        if err?
          res.send JSON.stringify(err)
          res.send "Unable to add that to the playlist :( (#{err})"
        else
          res.send "Added that to the playlist!"
      )
    )

  robot.respond /youtubepl authorize/i, (res) ->
    res.send client.generateAuthUrl({
      access_type: 'offline',
      scope: 'https://www.googleapis.com/auth/youtube.force-ssl'
    })

  robot.respond /youtubepl verify (.*)/i, (res) ->
    client.getToken(res.match[1], (err, tokens) ->
      client.setCredentials tokens
      robot.brain.set 'youtubepl.token',  tokens
      res.send if err? then err else "All good here"
    )

  robot.hear /https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([^&]+)/i, (res) ->
    update_playlist(res.match[1], res)

  robot.hear /https?:\/\/(?:www\.)?youtu\.be\/([^?]+)/i, (res) ->
    update_playlist(res.match[1], res)

  robot.respond /playlist/i, (res) ->
    get_room_playlist(res.message.room, (err, response) ->
      if err?
        res.send "Unable to get/create playlist for #{res.message.room}: #{err}"
      else
        res.send "https://www.youtube.com/playlist?list=#{response}"
    )
