assert(love.filesystem.isDirectory("samples"),
  "Sample directory does not exist.\n"..
  "Consider running `./tools/gen_sample.sh`?")

-- Require or module
LoveVideo = require("LoveVideo.lovevideo")
LoveVideo.thread_file = "LoveVideo/lovevideo_loadthread.lua"

samples = love.filesystem.getDirectoryItems("samples")
function next_sample()
  sample_target_index = sample_target_index
    and sample_target_index + 1
    or 1
  if sample_target_index > #samples then
    sample_target_index = 1
  end
  sample_target = samples[sample_target_index]
  -- This is where we load the current sample with the LoveVideo module
  bunny = LoveVideo.newVideo("samples/"..sample_target)
end

function love.load()
  next_sample()
end

function love.draw()
  love.graphics.print(love.timer.getFPS().."fps "..
    " - ["..sample_target_index.."]"..sample_target.."\n"..
    "N[ext] (un-)[P]ause")
  -- Draw the video
  bunny:draw(32,32,
    (love.graphics.getWidth()-64)/bunny:getWidth(), -- Get video width
    (love.graphics.getHeight()-64)/bunny:getHeight() -- Get video height
  )
end

function love.update(dt)
  bunny:update(dt) -- Update the video
  if bunny:isDone() then -- Check if the video is done
    bunny = LoveVideo.newVideo("samples/"..sample_target)
  end
end

function love.keypressed(key)
  if key == "n" then
    bunny:stop() -- For audio cue and cleanup!
    next_sample()
  elseif key == "p" then
    if bunny:isPlaying() then -- Check if the video is playing
      bunny:pause() -- pause the video
    else
      bunny:resume() -- resume the video
    end
  end
end
