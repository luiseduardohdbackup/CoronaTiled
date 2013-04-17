-- Project: Corona Tiled Map Loader 0.1
--
-- Date: November 24, 2012
-- Last Update: April 17, 2013
--
-- Version: 0.5
--
-- File name: tiled.lua
--
-- Author: Michael Wilson / NO2 Games, Inc. - www.no2games.com
--
-- Update History:
--
-- 0.1 - Initial release
-- 0.2 - Corona Specific Demo Project + Physics
-- 0.3 - Bugfixes & starting TMX support
-- 0.4 - Load a map region & tile properties including shapes
-- 0.5 - Bugfixes & Sprite Layers
-- 
-- Loads JSON/LUA saved map files from Tiled http://www.mapeditor.org/
--
--
-- SUPPORTED
-- JSON/LUA exported map files
-- Multiple Layers
-- Multiple Tilesets
-- Margins and spacing
-- Uses Corona Image Maps and Image Map groups if you limit yourself
-- to a single tileset image
-- Object types (regular, polygon, line)
-- Physics and display object properties
-- Image Layers
-- Flipped and rotated tiles
-- 
-- NOT SUPPORTED
-- TMX files
-- Offsets
-- Transparent colors
-- External tilesets
-- zlib/gzip compression
-- Isometric maps

-- Saving loaded maps

local tiledMap = {}
local tiledMap_mt = { __index = tiledMap }

local json = require "json"

local function printTable( t, label, level )
	if label then print( label ) end
	level = level or 1

	if t then
		for k,v in pairs( t ) do
			local prefix = ""
			for i=1,level do
				prefix = prefix .. "\t"
			end

			print( prefix .. "[" .. tostring(k) .. "] = " .. tostring(v) )
			if type( v ) == "table" then
				print( prefix .. "{" )
				printTable( v, nil, level + 1 )
				print( prefix .. "}" )
			end
		end
	end
end

function split(inputstr, sep)
	sep = sep or "%s"
	inputstr = inputstr or ""
	t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

function copyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function strRight(str,pattern)
	local s,e = str:find(pattern)
	local ret
	if e then
		ret =str:sub(e+1)
		return ret~='' and ret or nil
	end
	return nil
end
 
local function isNumeric(str) 
	return tonumber(str) and true or false 
end

local pointsCenterPoint = {}

local function getCenterPointOfPoints(points)
    local pointsSum = {x = 0, y = 0}
    for i = 1, #points do pointsSum.x = pointsSum.x + points[i].x; pointsSum.y = pointsSum.y + points[i].y end
    return {x = pointsSum.x / #points, y = pointsSum.y / #points}
end

local function getIsLess(a, b)
    local center = pointsCenterPoint
 
    if a.x >= 0 and b.x < 0 then return true
    elseif a.x == 0 and b.x == 0 then return a.y > b.y
    end
 
    local det = (a.x - center.x) * (b.y - center.y) - (b.x - center.x) * (a.y - center.y)
    if det < 0 then return true
    elseif det > 0 then return false
    end
 
    local d1 = (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y)
    local d2 = (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y)
    return d1 > d2
end

local function sortPointsClockwise(points)
    local centerPoint = getCenterPointOfPoints(points)
    pointsCenterPoint = centerPoint
    table.sort(points, getIsLess)
    return points
end

-- LoadXML from http://lua-users.org/wiki/LuaXml
function LoadXML(s)
  local function LoadXML_parseargs(s)
    local arg = {}
    string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
  	arg[w] = a
    end)
    return arg
  end
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=LoadXML_parseargs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=LoadXML_parseargs(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[stack.n].label)
  end
  return stack[1]
end

local function saveTable(t, filename)
    local path = system.pathForFile( filename, system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        local contents = json.encode(t)
        file:write( contents )
        io.close( file )
        return true
    else
        return false
    end
end

function tiledMap:load( mapFile, chunkTop, chunkLeft, chunkWidth, chunkHeight)

	-- Helper function to load JSON/TMX files
	
	local function getFile( filename, base )
		if not base then base = system.ResourceDirectory; end
		local path = system.pathForFile( filename, base )
		local contents
		local file = io.open( path, "r" )
		if file then
		   contents = file:read( "*a" )
		   io.close( file )	-- close the file after using it
		else
			assert(filename .. " not found")
		end
		return contents
	end
	
	local mapData
	if string.match(string.upper(mapFile), ".JSON") then
		mapData = json.decode( getFile( mapFile ) )
	elseif string.match(string.upper(mapFile), ".LUA") then 
		mapData = require(string.gsub(mapFile, '\....$',''))
	elseif string.match(string.upper(mapFile), ".TMX") then 
		--mapData = LoadXML( getFile( mapFile ) )
		assert("No support for TMX files")
	end
	
	local mapGroup = display.newGroup()
	
	local mapLayers = #mapData.layers; print( "layers", mapLayers)
	local orientation = mapData.orientation; print( "orientation", orientation)
	local mapHeight = mapData.height; print( "height", mapHeight)
	local mapWidth = mapData.width; print( "width",mapWidth)
	local tileHeight = mapData.tileheight; print( "tileheight", tileHeight)
	local tileWidth = mapData.tilewidth; print( "tilewidth", tileWidth )
	local version = mapData.version; print( "version", version)

	-- Create the tileset
	
	local imageSheets = {}
	local sheetFrames = {}
	
	for sets=1, #mapData.tilesets do
		local tileSet = mapData.tilesets[sets]		
		local options = 
		{
			frames = {},
			sheetContentWidth =  tileSet.imagewidth,
			sheetContentHeight = tileSet.imageheight,
		}
		
		local frames = options.frames
		local gid = 0

		local tileSetHeight = math.ceil((tileSet.imageheight - tileSet.margin*2 - tileSet.spacing) / (tileSet.tileheight + tileSet.spacing)) 
		local tileSetWidth = math.ceil((tileSet.imagewidth - tileSet.margin*2 - tileSet.spacing) / (tileSet.tilewidth + tileSet.spacing)) 
		
		print("tileset x,y", tileSetWidth, tileSetHeight)
		
		for j=1, tileSetHeight do
			for i=1, tileSetWidth  do
				local element = {
					x = (i-1)*(tileSet.tilewidth + tileSet.spacing) + tileSet.margin,
					y = (j-1)*(tileSet.tileheight + tileSet.spacing) + tileSet.margin,
					width = tileSet.tilewidth,
					height = tileSet.tileheight,
				}
				gid = gid + 1
				table.insert( frames, gid, element )
			end
		end
		print("Looking for tiles in: " .. string.match(tileSet.image,'([%w_]+%.%w%w%w)$'))
		imageSheets[sets] = graphics.newImageSheet(string.match(tileSet.image,'([%w_]+%.%w%w%w)$'), options )
		print("tileset",string.match(tileSet.image,'([%w_]+%.%w%w%w)$'))
		sheetFrames[sets] = frames
	end
	
	-- Render the Map
	
	for layers=1, mapLayers do 
		print("Processing Layer",layers)
		if mapData.layers[layers].type=="tilelayer" then -- render tile layers
			local layerGroup
			if #mapData.tilesets==1 then
				layerGroup = display.newImageGroup( imageSheets[1] ) -- use an imageGroup
			else
				layerGroup = display.newGroup() -- more than one imageSheet? then use a group
			end

			local properties=mapData.layers[layers].properties
			layerGroup.properties={}
			layerGroup.physicsData={}
			layerGroup.tileProperties={}
			
			if properties then
				for k, v in pairs(properties) do
					if string.find(string.lower(k), "physics:")~=nil then
						layerGroup.physicsData[strRight(k, ":")]=properties[k]
					if layerGroup.physicsData[strRight(k, ":")]=="true" then
						layerGroup.physicsData[strRight(k, ":")]=true
					elseif layerGroup.physicsData[strRight(k, ":")]=="false" then
						layerGroup.physicsData[strRight(k, ":")]=false
					elseif isNumeric(layerGroup.physicsData[strRight(k, ":")])==true then
						layerGroup.physicsData[strRight(k, ":")]=tonumber(layerGroup.physicsData[strRight(k, ":")])
					end
					elseif string.find(string.lower(k), "layer:")~=nil then
						layerGroup[strRight(k, ":")]=properties[k]
					if layerGroup[strRight(k, ":")]=="true" then
						layerGroup[strRight(k, ":")]=true
					elseif layerGroup[strRight(k, ":")]=="false" then
						layerGroup[strRight(k, ":")]=false
					elseif isNumeric(layerGroup[strRight(k, ":")])==true then
						layerGroup[strRight(k, ":")]=tonumber(layerGroup[strRight(k, ":")])
					end
					elseif string.find(string.lower(k), "tiles:")~=nil then
						layerGroup.tileProperties[strRight(k, ":")]=properties[k]
						if layerGroup.tileProperties[strRight(k, ":")]=="true" then
							layerGroup.tileProperties[strRight(k, ":")]=true
						elseif layerGroup.tileProperties[strRight(k, ":")]=="false" then
							layerGroup.tileProperties[strRight(k, ":")]=false
						elseif isNumeric(layerGroup.tileProperties[strRight(k, ":")])==true then
							layerGroup.tileProperties[strRight(k, ":")]=tonumber(layerGroup.tileProperties[strRight(k, ":")])
						end
					else
						layerGroup.properties[k]=properties[k]
					end
				end
			end
			
			-- Render Map
			      
      local item = 0 
      local visibleMapTop = chunkTop or 1
      local visibleMapLeft = chunkLeft or 1
      local visibleMapWidth = chunkWidth or mapWidth 
      local visibleMapHeight = chunkHeight or mapHeight
      for j=visibleMapTop, visibleMapHeight do
        for i=visibleMapLeft, visibleMapWidth do
          item = ((j-1) * mapWidth-1) + i + visibleMapLeft
          for sets = 1, #mapData.tilesets do
            local firstgid = mapData.tilesets[sets].firstgid
            local lastgid = firstgid + #sheetFrames[sets] + 1
            local tileNumber = mapData.layers[layers].data[item] or 0
            tileNumber = math.max(0, tileNumber - firstgid + 1)
            if tileNumber > 0 then 
              if tileNumber < lastgid - firstgid then
                local tile = display.newImage( imageSheets[sets], tileNumber, (i-1)*tileWidth, (j-1)*tileHeight )
                --tile:setReferencePoint(display.TopLeftReferencePoint)
								-- set other properties
                for k, v in pairs(layerGroup.tileProperties) do
                  tile[k]=layerGroup.tileProperties[k]
                end
                -- set tile properties from tileset								
                if mapData.tilesets[sets].tileproperties then		
									for k, v in pairs(mapData.tilesets[sets].tileproperties) do
										if tonumber(k) == tileNumber+firstgid-2 then
											for sk, sv in pairs(v) do
												tile[sk]=sv
											end
										end 
									end	
								end
								-- set Physics properties
                if layerGroup.physicsData.enabled==true then
									if tile.shape then
											local tilePhysicsData = copyTable(layerGroup.physicsData)
											tilePhysicsData.shape = split(tile.shape,",")
											physics.addBody(tile, "static", tilePhysicsData)
									else
										physics.addBody(tile, "static", layerGroup.physicsData)
									end
                end
                layerGroup:insert(tile)
              end
            end
          end
        end
      end
      layerGroup.alpha = mapData.layers[layers].opacity
      layerGroup.isVisible = mapData.layers[layers].visible
      mapGroup:insert(layerGroup)
      
		elseif mapData.layers[layers].type=="objectgroup" then -- process Object layer
		
			local layerGroup = display.newGroup() 
			local properties=mapData.layers[layers].properties
			layerGroup.properties={}
			layerGroup.physicsData={}
			layerGroup.physicsData.filter={}
			layerGroup.objectProperties={}
			layerGroup.sequenceData={}			
			
			if properties then
				for k, v in pairs(properties) do
					if string.find(string.lower(k), "physics:")~=nil then
						layerGroup.physicsData[strRight(k, ":")]=properties[k]
						if layerGroup.physicsData[strRight(k, ":")]=="true" then
							layerGroup.physicsData[strRight(k, ":")]=true
						elseif layerGroup.physicsData[strRight(k, ":")]=="false" then
							layerGroup.physicsData[strRight(k, ":")]=false
						elseif isNumeric(layerGroup.physicsData[strRight(k, ":")])==true then
							layerGroup.physicsData[strRight(k, ":")]=tonumber(layerGroup.physicsData[strRight(k, ":")])
						end
					elseif string.find(string.lower(k), "collision:")~=nil then
						layerGroup.physicsData.filter[strRight(k, ":")]=properties[k]
						layerGroup.physicsData.filter[strRight(k, ":")]=tonumber(layerGroup.physicsData.filter[strRight(k, ":")])
					elseif string.find(string.lower(k), "layer:")~=nil then
						layerGroup[strRight(k, ":")]=properties[k]
						if layerGroup[strRight(k, ":")]=="true" then
							layerGroup[strRight(k, ":")]=true
						elseif layerGroup[strRight(k, ":")]=="false" then
							layerGroup[strRight(k, ":")]=false
						elseif isNumeric(layerGroup[strRight(k, ":")])==true then
							layerGroup[strRight(k, ":")]=tonumber(layerGroup[strRight(k, ":")])
						end
					elseif string.find(string.lower(k), "objects:")~=nil then
						layerGroup.objectProperties[strRight(k, ":")]=properties[k]
						if layerGroup.objectProperties[strRight(k, ":")]=="true" then
							layerGroup.objectProperties[strRight(k, ":")]=true
						elseif layerGroup.objectProperties[strRight(k, ":")]=="false" then
							layerGroup.objectProperties[strRight(k, ":")]=false
						elseif isNumeric(layerGroup.objectProperties[strRight(k, ":")])==true then
							layerGroup.objectProperties[strRight(k, ":")]=tonumber(layerGroup.objectProperties[strRight(k, ":")])
						end
					elseif string.find(string.lower(k), "sprites:")~=nil then
						layerGroup.sequenceData[strRight(k, ":")]=properties[k]
						if layerGroup.sequenceData[strRight(k, ":")]=="true" then
							layerGroup.sequenceData[strRight(k, ":")]=true
						elseif layerGroup.sequenceData[strRight(k, ":")]=="false" then
							layerGroup.sequenceData[strRight(k, ":")]=false
						elseif isNumeric(layerGroup.sequenceData[strRight(k, ":")])==true then
							layerGroup.sequenceData[strRight(k, ":")]=tonumber(layerGroup.sequenceData[strRight(k, ":")])
						end
					else
						layerGroup.properties[k]=properties[k]
					end
				end
			end
		
			for i=1, #mapData.layers[layers].objects do
				if mapData.layers[layers].objects[i].ellipse then -- Circles
					local ex = mapData.layers[layers].objects[i].x 
					local ey = mapData.layers[layers].objects[i].y 
					local ew = mapData.layers[layers].objects[i].width 
					local eh = mapData.layers[layers].objects[i].height 
					if (ew > eh) then
						local ellipse = display.newCircle( layerGroup, ex + (ew / 2), ey + (eh / 2), ew / 2)
						ellipse.yScale = (eh / ew)
						-- set Physics properties
						if layerGroup.physicsData.enabled==true then
							layerGroup.physicsData.radius = ew / 2
							physics.addBody(ellipse, "static", layerGroup.physicsData)
							layerGroup.physicsData.radius = nil
						end
						-- set other properties
						for k, v in pairs(layerGroup.objectProperties) do
							ellipse[k]=layerGroup.objectProperties[k]
						end
						--set Object properties
						for k, v in pairs(mapData.layers[layers].objects[i].properties) do
							image[k]=mapData.layers[layers].objects[i].properties[k]
						end					
					else
						local ellipse = display.newCircle( layerGroup, ex + (ew / 2), ey + (eh / 2), eh / 2)
						ellipse.xScale = (ew / eh)
						if layerGroup.physicsData.enabled==true then
							layerGroup.physicsData.radius = eh / 2
							physics.addBody(ellipse, "static", layerGroup.physicsData)
							layerGroup.physicsData.radius = nil
						end						
						-- set other properties
						for k, v in pairs(layerGroup.objectProperties) do
							ellipse[k]=layerGroup.objectProperties[k]
						end
						--set Object properties
						for k, v in pairs(mapData.layers[layers].objects[i].properties) do
							ellipse[k]=mapData.layers[layers].objects[i].properties[k]
						end					
					end
				elseif mapData.layers[layers].objects[i].polygon then -- Polygon
					local points = mapData.layers[layers].objects[i].polygon
					local polygon = display.newLine( points[1].x, points[1].y, points[2].x, points[2].y)
					for i = 3, #points do
						polygon:append(points[i].x, points[i].y)
					end
					polygon:append(points[1].x, points[1].y)
					if layerGroup.physicsData.enabled==true then
						local shape = {}
						local point = 1
						local sortedPoints=points -- not quite there with the sorting
						for i = 1, math.min(#sortedPoints,8) do
							shape[point],shape[point+1] = sortedPoints[i].x, sortedPoints[i].y
							point=point + 2
						end
						layerGroup.physicsData.shape = shape
						physics.addBody(polygon,  "static", layerGroup.physicsData)
						layerGroup.physicsData.shape = nil
					end
					polygon.x = mapData.layers[layers].objects[i].x 
					polygon.y = mapData.layers[layers].objects[i].y 		
					-- set other properties
					for k, v in pairs(layerGroup.objectProperties) do
						polygon[k]=layerGroup.objectProperties[k]
					end	
					--set Object properties
					for k, v in pairs(mapData.layers[layers].objects[i].properties) do
						polygon[k]=mapData.layers[layers].objects[i].properties[k]
					end					
					layerGroup:insert(polygon)
				elseif mapData.layers[layers].objects[i].polyline then -- Lines
					local points = mapData.layers[layers].objects[i].polyline						
					local line = display.newLine( points[1].x, points[1].y ,points[2].x, points[2].y)
					if #points > 2 then
						for i = 3, #points do
							line:append(points[i].x, points[i].y)
						end
					end
					line.x = mapData.layers[layers].objects[i].x 
					line.y = mapData.layers[layers].objects[i].y 						
					local shape = {}
					local point = 1
					for i = 1, math.min(#points,8) do
						shape[point],shape[point+1] = points[i].x, points[i].y
						point=point + 2
					end
					if layerGroup.physicsData.enabled==true then
						layerGroup.physicsData.shape = shape
						physics.addBody(line, "static", layerGroup.physicsData)
						layerGroup.physicsData.shape = nil
					end
					-- set other properties
					for k, v in pairs(layerGroup.objectProperties) do
						line[k]=layerGroup.objectProperties[k]
					end
					--set Object properties
					for k, v in pairs(mapData.layers[layers].objects[i].properties) do
						line[k]=mapData.layers[layers].objects[i].properties[k]
					end					
					layerGroup:insert(line)
				elseif mapData.layers[layers].objects[i].gid then --Image object
					for sets = 1, #mapData.tilesets do
						local firstgid = mapData.tilesets[sets].firstgid
						local lastgid = firstgid + #sheetFrames[sets] + 1
						local tileNumber = mapData.layers[layers].objects[i].gid
						tileNumber = math.max(0, tileNumber - firstgid + 1)
						if tileNumber > 0 then 
							if tileNumber < lastgid - firstgid then								
								if layerGroup.sequenceData.enabled==true  then
									--layerGroup.sequenceData.frames = split(layerGroup.sequenceData.frames ,",")
									image = display.newSprite( imageSheets[sets], layerGroup.sequenceData)
									image:setSequence(layerGroup.sequenceData.name)
									image:play()
								else
									image = display.newImage( imageSheets[sets], tileNumber)
								end
								-- set Physics properties
								if layerGroup.physicsData.enabled==true then
									physics.addBody(image, "static", layerGroup.physicsData)
								end
								-- set other layer properties
								for k, v in pairs(layerGroup.objectProperties) do
									image[k]=layerGroup.objectProperties[k]
								end
								--set Object properties
								for k, v in pairs(mapData.layers[layers].objects[i].properties) do
									image[k]=mapData.layers[layers].objects[i].properties[k]
								end
								layerGroup:insert( image )
								image.x = mapData.layers[layers].objects[i].x 
								image.y = mapData.layers[layers].objects[i].y	
								mapData.layers[layers].objects[i].image = image
							end
						end
					end
				else -- All else fails, make a RECT
					local rx = mapData.layers[layers].objects[i].x 
					local ry = mapData.layers[layers].objects[i].y 
					local rw = mapData.layers[layers].objects[i].width 
					local rh = mapData.layers[layers].objects[i].height 	
					local rect = display.newRect( layerGroup, rx, ry, rw, rh)
					-- set Physics properties
					if layerGroup.physicsData.enabled==true then
						physics.addBody(rect, "static", layerGroup.physicsData)
					end
					-- set other properties
					for k, v in pairs(layerGroup.objectProperties) do
						rect[k]=layerGroup.objectProperties[k]
					end							
				end
			end
			layerGroup.alpha = mapData.layers[layers].opacity
			layerGroup.isVisible = mapData.layers[layers].visible
			mapGroup:insert(layerGroup)
		
		elseif mapData.layers[layers].type=="imagelayer" then -- process Image layer		
		
			local ix = mapData.layers[layers].x 
			local iy = mapData.layers[layers].y 
			imageLayer = display.newImage(mapData.layers[layers].image,ix,iy,true)
			local properties=mapData.layers[layers].properties
			if properties then
				for k, v in pairs(properties) do
					if sstring.find(string.lower(k), "layer:")~=nil then
							layerGroup[strRight(k, ":")]=properties[k]
						if layerGroup[strRight(k, ":")]=="true" then
							layerGroup[strRight(k, ":")]=true
						elseif layerGroup[strRight(k, ":")]=="false" then
							layerGroup[strRight(k, ":")]=false
						elseif isNumeric(layerGroup[strRight(k, ":")])==true then
							layerGroup[strRight(k, ":")]=tonumber(layerGroup[strRight(k, ":")])
						end
					else
						layerGroup.properties[k]=properties[k]
					end
				end
			end
			imageLayer.alpha = mapData.layers[layers].opacity
			imageLayer.isVisible = mapData.layers[layers].visible
			mapGroup:insert(imageLayer)				
		end
	end
	mapGroup.data = mapData -- pass the raw data back
	return mapGroup
end

function tiledMap:findObjects(name,mapData)
	local mapLayers = #mapData.layers
	local objects = {}
	for layers=1, mapLayers do 
		if mapData.layers[layers].type=="objectgroup" then -- search Object layer		
			for i=1, #mapData.layers[layers].objects do
				if mapData.layers[layers].objects[i].name == name then
					table.insert(objects,mapData.layers[layers].objects[i])
				end
			end
		end
	end
	if (#objects == 1) then
		return objects[1]
	elseif (#objects == 0) then
		return nil
	else
		return objects
	end
end

function tiledMap:destroy()
	-- Nothing to Destroy, yet
end

return tiledMap
