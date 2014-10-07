#LoveVideo

### A Video Library For L&Ouml;VE.

Please report any issues here; https://github.com/josefnpat/LoveVideo/issues

## Usage

_For a more in depth example, see the full documentation._

Here's a quick sample usage:

```lua
LoveVideo = require "LoveVideo.lovevideo"

bunny = LoveVideo.newVideo("big_buck_bunny")

function love.draw()
  bunny:draw(0,0,
    love.graphics.getWidth()/bunny:getWidth(), -- x scale
    love.graphics.getHeight()/bunny:getHeight() -- y scale
  )
end

function love.update(dt)
  bunny:update(dt)
end
```

## Documentation

To build the full module docs, run;

`./tools/gen_docs.sh`
(dependencies: lua-ldoc)

To create a directory containing a valid video target, run;

`./tool/convert.sh [path_to_foo.mp4] [target_video_output]`
(dependencies: libimage-exiftool-perl libav-tools imagemagick)

To build a sample video, run;

`./tool/gen_sample.sh`
(dependencies: wget libimage-exiftool-perl libav-tools imagemagick)

### Generated Video Structure

Example video structure for video `sample`;

    sample/1.png
    sample/2.png
    ...
    sample/N.png
    sample/info.lua
    sample/audio.ogg

* `sample/[1..N].png` - These are the frames for the video itself.
* `sample/info.lua` - This has information about how the video should be played.
  See info.lua.template for more details.
* `sample/audio.ogg` - The audio file meant to be played during the video. Keep
  in mind that LoveVideo usues this to keep time.

## Authors

Josef Patoprsty (josefnpat) 2014

This module is a pure lua refactoring of:

* Flashkot's 2012 mjpeg library and
* Philipp &Uuml;berbacher 2014 update for 0.9.1.

## Contributions

* Leandro Fonseca (Shell32)

## License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
