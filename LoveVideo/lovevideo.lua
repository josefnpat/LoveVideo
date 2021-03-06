--- LoveVideo is a video module for LÖVE.
-- @module LoveVideo
-- @author Josef N Patoprsty <seppi@josefnpat.com> [2014]
-- @author Philipp Überbacher [2014]
-- @author flashkot [2012]
-- @copyright 2014
-- @license <a href="http://www.apache.org/licenses/LICENSE-2.0">Apache 2.0</a>

local lovevideo = {
  _VERSION = "LoveVideo %VERSION%",
  _DESCRIPTION = "LÖVE module for playing video.",
  _URL = "https://github.com/josefnpat/LoveVideo/",
  _LICENSE = [[
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
  ]],
  threadtarget = "LoveVideo/lovevideo_loadthread.lua"
}

--- Instantiate a new instance of the video player.
-- @param target <i>Required</i> The directory that should be loaded.
-- @param srgb <i>Optional</i> Enable the srgb color space.
-- No trailing forwardslash.
function lovevideo.newVideo(target,srgb)

  local self = {}
  self._target = target
  self._srgb = srgb and true or false

  -- Public functions
  self.update = lovevideo.update
  self.draw = lovevideo.draw
  self.isDone = lovevideo.isDone
  self.setOnDone = lovevideo.setOnDone
  self._ondone = function() end
  self.isPlaying = lovevideo.isPlaying
  self.pause = lovevideo.pause
  self.resume = lovevideo.resume
  self.stop = lovevideo.stop

  self.setSpeed = lovevideo.setSpeed
  self.getSpeed = lovevideo.getSpeed

  self.getWidth = lovevideo.getWidth
  self.getHeight = lovevideo.getHeight
  self.getDimensions = lovevideo.getDimensions
  self.getAudio = lovevideo.getAudio

  assert(type(target)=="string",
    "Target expected, `"..type(target).."`provided.")
  assert(love.filesystem.isDirectory(target),
    "Target does not exist.")

  assert(love.filesystem.isFile(target.."/info.lua"),
    "Information file missing: `"..target.."/info.lua`.")
  self._info = require(target.."/info")

  assert(self._info.image_format == "jpg" or
    self._info.image_format == "png" or
    self._info.image_format == "dds",
    "info.image_format must be `jpg`, `png` or `dds`.")

  self._iscompressed = self._info.image_format == "dds"
  self.isCompressed = lovevideo.isCompressed

  assert(type(self._info.fps)=="number" and self._info.fps > 0,
    "info.fps must be a positive number.")
  assert(type(self._info.frame)=="table",
    "info.frame must be a table.")
  for _,value in pairs({"width","height","rows","columns"}) do
    assert(
      type(self._info.frame[value])=="number"
        and self._info.frame[value] > 0,
      "info.frame."..value.." must be a positive integer.")
  end

  self._time = 0
  self._stopcount = 0
  self._stopvideo = false
  self._firstimage = true
  self._waitimage = false
  self._framesperimage = self._info.frame.rows * self._info.frame.columns
  self._frametime = 0
  self._audioposition = 0
  self._nextload = 3
  self._pausevideo = false
  self._done = false
  self._speed = 1

  self._quads = {}
  local c,r
  for r = 0, self._info.frame.rows - 1, 1 do
    for c = 0, self._info.frame.columns - 1, 1 do
      table.insert(self._quads,
        love.graphics.newQuad(
          self._info.frame.width*c,
          self._info.frame.height*r,
          self._info.frame.width,
          self._info.frame.height,
          self._info.frame.width*self._info.frame.columns,
          self._info.frame.height*self._info.frame.rows
        )
      )
    end
  end
  self._currentquad = 1

  self._loaderthread = love.thread.newThread(lovevideo.threadtarget)
  self._channelfilename = love.thread.getChannel("filename")
  self._channelimagedata = love.thread.getChannel("imagedata")
  self._loaderthread:start()

  self._images = {}
  for i = 1,2 do
    local image_file = target.."/"..i.."."..self._info.image_format
    if love.filesystem.isFile(image_file) then
      self._channelfilename:push(image_file)
      self._imagedata = self._channelimagedata:demand()
      self._images[i] = love.graphics.newImage(self._imagedata,
        self._srgb and "srgb" or nil)
    end
  end

  self._audio = love.audio.newSource(target.."/audio.ogg")
  love.audio.play(self._audio)

  return self

end

--- Updates the instances internals.
-- @param dt <i>Required</i> The delta time from love.update
function lovevideo:update(dt)

  if self._done then return end

  if not self._pausevideo then
    self._time = self._time + dt
    local new_dt = self._audio:tell() - self._audioposition
    self._audioposition = self._audio:tell()
    if self._audio:isStopped() then
      self._done = true
      self:_ondone()
    end
    self._frametime = self._frametime + new_dt
  end

  if not self._stopvideo then
    if self._waitimage then
      self._imagedata = self._channelimagedata:demand()
      if self._imagedata then
        self._images[ self._firstimage and 2 or 1 ] =
          love.graphics.newImage(self._imagedata,
            self._srgb and "srgb" or nil)
      end
      self._waitimage = false
      collectgarbage("collect")
    end
  end

  if self._frametime >= 1/self._info.fps*self._speed then
    self._frametime = self._frametime - 1/self._info.fps*self._speed
    self._currentquad = self._currentquad + 1
    if self._currentquad > self._framesperimage then
      self._currentquad = 1
      local target_file =
        self._target.."/"..self._nextload.."."..self._info.image_format
      self._channelfilename:push(target_file)
      self._waitimage = true
      if not love.filesystem.exists(target_file) then
        self:stop()
      end
      self._nextload = self._nextload + 1
      self._firstimage = not self._firstimage
    end
  end
end

--- Draw the instance on the screen.
-- This function imitates love.graphics.draw.
-- @param x <i>Optional</i> The position to draw the instance (x-axis). [0]
-- @param y <i>Optional</i> The position to draw the instance (y-axis). [0]
-- @param sx <i>Optional</i> Scale factor (x-axis). [1]
-- @param sy <i>Optional</i> Scale factor (y-axis). [1]
function lovevideo:draw( x, y, sx, sy)

  if self._done then return end

  if self._stopvideo then
    self._stopcount = self._stopcount + 1
  end

  if self._stopcount <= self._framesperimage then
    love.graphics.draw(self._images[self._firstimage and 1 or 2],
      self._quads[self._currentquad],
      x or 0, y or 0, 0, sx or 1, sy or 1)
  end

end

--- Determines if the instance has ended.
function lovevideo:isDone()
  return self._done
end

--- Set the function to be called when the video finishes.
-- @param func <i>Required</i> the function to be called when the current
-- instance finishes.
function lovevideo:setOnDone( func )
  assert(type(func) == "function","Argument must be a function.")
  self._ondone = func
end

--- Determines if the instance is playing.
function lovevideo:isPlaying()
  return not self._pausevideo
end

--- Stop the current instance.
function lovevideo:stop()
  self._done = true
  self._ondone()
  self._audio:stop()
end

--- Sets the speed of the current instance.
-- @param speed <i>Required</i> The multiplier at which the speed should play.
function lovevideo:setSpeed(speed)
  assert(type(speed) == "number","Speed must be a number")
  assert(speed > 0, "Speed must be a number greater than zero.")
  self._speed = speed
  self._audio:setPitch(speed)
end

--- Gets the speed of the current instance.
-- @return speed of current instance.
function lovevideo:getSpeed()
  return self._speed
end

--- Pause the current instance.
function lovevideo:pause()
  self._pausevideo = true
  self._audio:pause()
end

--- Resume the current instance.
function lovevideo:resume()
  self._pausevideo = false
  self._audio:resume()
end

--- Get the width of the video.
-- @return the video width
function lovevideo:getWidth()
  return self._info.frame.width
end

--- Get the height of the video.
-- @return the video height
function lovevideo:getHeight()
  return self._info.frame.height
end

--- Get the current dimensions of the video.
-- @return the video width, the video height
function lovevideo:getDimensions()
  return self._info.frame.width,self._info.frame.height
end

--- Gets the current audio Source
-- @return the audio Source
function lovevideo:getAudio()
  return self._audio
end

--- Determines if the current instance is using a compressed format (e.g. dds)
-- @return boolean of whether the video is compressed
function lovevideo:isCompressed()
  return self._iscompressed
end

return lovevideo
