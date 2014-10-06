-- Copyright 2012 flashkot
-- Copyright 2014 Philipp Überbacher (port to Löve 0.9.1)
-- Copyright 2014 Josef Patoprsty (seppi@josefnpat.com) [Refactor]

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

-- http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

require("love.filesystem")
require("love.image")

local channel_filename = love.thread.getChannel("filename")
local channel_imagedata = love.thread.getChannel("imagedata")

local running = true

while running do
  collectgarbage("collect")
  filename = channel_filename:demand()
  if love.filesystem.exists(filename) then
    local filedata = love.filesystem.newFileData(filename)
    local imageData
    if love.image.isCompressed(filedata) then
      imageData = love.image.newCompressedData(filedata)
    else
      imageData = love.image.newImageData(filedata)
    end
    channel_imagedata:push(imageData)
  elseif filename == "stop" then
    running = false
  end
end
