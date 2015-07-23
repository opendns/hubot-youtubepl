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

scribe = require('scribe-node').load(['OAuth'])
services =
  'youtube':
    'provider': scribe.GoogleApi2
    'key': process.env.GOOGLE_OAUTH2_API_KEY
    'secret': process.env.GOOGLE_OAUTH2_API_SECRET
    'scope': 'https://www.googleapis.com/auth/youtube.force-ssl'
    'callback': 'urn:ietf:wg:oauth:2.0:oob'

module.exports = (robot) ->

  # OAUTH...
  unless process.env.GOOGLE_OAUTH2_API_KEY?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_KEY"
    return
  unless process.env.GOOGLE_OAUTH2_API_SECRET?
    robot.logger.warning "Need GOOGLE_OAUTH2_API_SECRET"
    return

  # Need to store the token stuff... But where

  #update_playlist = (code) ->
    # Do stuff here

  robot.respond /ytauthorize/i, (res) ->
    res.send 'Getting you the authorization url'
    callback = (url) ->
      res.send "Authorization URL " + url
    new scribe.OAuth(robot.brain.data, 'youtube', services).get_authorization_url(callback)

  robot.respond /ytverify (.*)/i, (res) ->
    res.send 'Setting verification token to ' + res.match[1]
    callback = (response) ->
      res.send "Verification response " + response
    new scribe.OAuth(robot.brain.data, 'youtube', services).set_verification_code(res.match[1], callback)

  robot.hear /https?:\/\/(www\.)?youtube\.com\/watch?v=([^&]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.hear /https?:\/\/(www\.)?youtu\.be\/([^?]+)/i, (res) ->
    update_playlist(res.match[1])

  robot.respond /playlist/i, (res) ->
    res.send "I should give you the playlist url here"
