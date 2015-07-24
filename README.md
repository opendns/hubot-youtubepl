# hubot-youtubepl

A hubot script that will add all youtube links to a playlist

See [`src/youtubepl.coffee`](src/youtubepl.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-youtubepl --save`

Then add **hubot-youtubepl** to your `external-scripts.json`:

```json
[
  "hubot-youtubepl"
]
```

## Sample Interaction

```
user1>> hubot youtubepl authorize
hubot>> http://.....
user1>> hubot youtubepl verify XYZ
hubot>> All good!
user1>> hubot youtubepl
hubot>> https://www.youtube.com/playlist?list=PLkPBG58N87CgfhdabCoFe0dB3ClZZ6oho
user1>> http://youtu.be/XYZ
hubot>> Added that to the playlist!
```
