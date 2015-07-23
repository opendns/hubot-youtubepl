# Description
#   A hubot script that does the things
#
# Configuration:
#   HUBOT_YOUTUBE_CLIENTID
#   HUBOT_YOUTUBE_CLIENTSECRET
#
# Commands:
#   hubot playlist - <what the respond trigger does>
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


#    'key': process.env.GOOGLE_OAUTH2_API_KEY
#    'secret': process.env.GOOGLE_OAUTH2_API_SECRET


module.exports = (robot) ->
  # OAUTH...
  unless process.env.GOOGLE_OAUTH2_API_KEY?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_KEY"
    return
  unless process.env.GOOGLE_OAUTH2_API_SECRET?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_SECRET"
    return

  # Need to store the token stuff... But where

  update_playlist = (code, res) ->
    youtube.playlistitems.insert {, auth: client}, (err, response) ->
      # Do stuff here

  robot.respond /brain/i, (res) ->
    res.send JSON.stringify robot.brain.data

  robot.respond /yttoken/i, (res) ->
    res.send "Token is output here"

  robot.respond /ytrefresh/i, (res) ->
    client.refreshAccessToken (err, tokens) ->
      res.send if err? then err else "All good here!"

  robot.respond /ytauthorize/i, (res) ->
    res.send client.generateAuthUrl({
      access_type: 'offline',
      scope: 'https://www.googleapis.com/auth/youtube.force-ssl'
    })

  robot.respond /ytverify (.*)/i, (res) ->
    client.getToken(res.match[1], (err, tokens) ->
      client.setCredentials tokens
      res.send if err? then err else "All good here"
    )

  robot.hear /https?:\/\/(www\.)?youtube\.com\/watch?v=([^&]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.hear /https?:\/\/(www\.)?youtu\.be\/([^?]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.respond /playlist/i, (res) ->
    res.send "I should give you the playlist url here"
