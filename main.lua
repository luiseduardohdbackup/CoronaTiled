-- Project: Corona Tiled Map Loader Example 0.1
--
-- Date: November 24, 2012
--
-- Version: 0.1
--
-- File name: main.lua
--
-- Author: Michael Wilson / NO2 Games, Inc. - www.no2games.com
--
-- Update History:
--
-- 0.1 - Initial release
-- 
-- Loads JSON saved map files from Tiled http://www.mapeditor.org/
--

display.setStatusBar( display.HiddenStatusBar )

tiledMap = require("tiled")

map = tiledMap:load("desert.lua")

function map:touch( event )
    if event.phase == "began" then
        self.markX = self.x    -- store x location of object
        self.markY = self.y    -- store y location of object
    elseif event.phase == "moved" then
        local x = (event.x - event.xStart) + self.markX
        local y = (event.y - event.yStart) + self.markY
        self.x, self.y = x, y    -- move object based on calculations above
    end
    return true
end

map:addEventListener( "touch", map )

