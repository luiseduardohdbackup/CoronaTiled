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

map = tiledMap:load("desert.json")

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

function showFps()
	local prevTime = 0
	local curTime = 0
	local dt = 0       
	local fps = 50
	local mem = 0

	local underlay = display.newRect(0, 0, display.contentWidth, 16)   
	underlay:setFillColor(0, 0, 0, 128)             
	local displayInfo = display.newText("FPS: " .. fps .. " - Memory: ".. mem .. "mb", 0, 0, native.systemFont, 12)
	displayInfo:setReferencePoint(display.CenterReferencePoint)
	displayInfo.x=display.contentWidth/2
	local function updateText()
		curTime = system.getTimer()
		dt = curTime - prevTime
		prevTime = curTime
		fps = math.floor(1000 / dt)
		mem = system.getInfo("textureMemoryUsed") / 1000000
		if fps > 60 then fps = 60; end
		displayInfo.text = "FPS: " .. fps .. " MEM: ".. string.sub(mem, 1, string.len(mem) - 4) .. "mb"
		underlay:toFront()
		displayInfo:toFront()
	end
	Runtime:addEventListener("enterFrame", updateText)
end

showFps()
map:addEventListener( "touch", map )

