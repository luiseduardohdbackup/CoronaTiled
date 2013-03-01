-- Project: Corona Tiled Map Loader 0.1
--
-- Date: November 24, 2012
--
-- Version: 0.1
--
-- File name: tiled.lua
--
-- Author: Michael Wilson / NO2 Games, Inc. - www.no2games.com
--
-- Update History:
--
-- 0.1 - Initial release
-- 0.2 - GridMap+Tiled release
--
-- Loads JSON saved map files from Tiled http://www.mapeditor.org/
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
-- 
-- NOT SUPPORTED
-- TMX files
-- Offsets
-- Transparent colors
-- External tilesets
-- zlib/gzip compression
-- Isometric maps
-- Flipped and rotated tiles
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

local function tableMerge(t1, t2)
	for k,v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				tableMerge(t1[k] or {}, t2[k] or {})
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
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

function tiledMap:load( mapFile )

	-- Helper function to load JSON/TMX files
	
	local function getFile( filename, base )
		if not base then base = system.ResourceDirectory; end
		local path = system.pathForFile( filename, base )
		local contents
		local file = io.open( path, "r" )
		if file then
		   contents = file:read( "*a" )
		   io.close( file )	-- close the file after using it
		end
		return contents
	end
	
	local mapData
	if string.match(string.upper(mapFile), ".JSON") then
		mapData = json.decode( getFile( mapFile ) )
	elseif string.match(string.upper(mapFile), ".LUA") then 
		mapData = require(string.gsub(mapFile, '\....$',''))
	elseif string.match(string.upper(mapFile), ".TMX") then 
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
			for j=1, mapHeight do
				for i=1, mapWidth do
					item = item + 1
					for sets = 1, #mapData.tilesets do
						local firstgid = mapData.tilesets[sets].firstgid
						local lastgid = firstgid + #sheetFrames[sets] + 1
						local tileNumber = mapData.layers[layers].data[item]
						tileNumber = math.max(0, tileNumber - firstgid + 1)
						if tileNumber > 0 then 
							if tileNumber < lastgid - firstgid then
								local tile = display.newImage( imageSheets[sets], tileNumber, (i-1)*tileWidth, (j-1)*tileHeight )
								-- set Physics properties
								if layerGroup.physicsData.enabled==true then
									physics.addBody(tile, "static", layerGroup.physicsData)
								end
								-- set other properties
								for k, v in pairs(layerGroup.tileProperties) do
									tile[k]=layerGroup.tileProperties[k]
								end
								layerGroup:insert( tile )
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
			layerGroup.objectProperties={}
			
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
					elseif string.find(string.lower(k), "objects:")~=nil then
						layerGroup.objectProperties[strRight(k, ":")]=properties[k]
						if layerGroup.objectProperties[strRight(k, ":")]=="true" then
							layerGroup.objectProperties[strRight(k, ":")]=true
						elseif layerGroup.objectProperties[strRight(k, ":")]=="false" then
							layerGroup.objectProperties[strRight(k, ":")]=false
						elseif isNumeric(layerGroup.objectProperties[strRight(k, ":")])==true then
							layerGroup.objectProperties[strRight(k, ":")]=tonumber(layerGroup.objectProperties[strRight(k, ":")])
						end
					else
						layerGroup.properties[k]=properties[k]
					end
				end
			end
		
			for i=1, #mapData.layers[layers].objects do
				if mapData.layers[layers].objects[i].ellipse then
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
							image[k]=mapData.layers[layers].objects[i].properties[k]
						end					
					end
				elseif mapData.layers[layers].objects[i].polygon then
					local points = mapData.layers[layers].objects[i].polygon
					local polygon = display.newLine( points[1].x, points[1].y, points[2].x, points[2].y)
					for i = 3, #points do
						polygon:append(points[i].x, points[i].y)
					end
					polygon:append(points[1].x, points[1].y)
					local shape = {}
					local point = 1
					for i = 1, math.min(#points,8) do
						shape[point],shape[point+1] = points[i].x, points[i].y
						point=point + 2
					end
					--shape[point],shape[point + 1] = 0,0
					if layerGroup.physicsData.enabled==true then
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
						image[k]=mapData.layers[layers].objects[i].properties[k]
					end					
					layerGroup:insert(polygon)
				elseif mapData.layers[layers].objects[i].polyline then
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
						image[k]=mapData.layers[layers].objects[i].properties[k]
					end					
					layerGroup:insert(line)
				elseif mapData.layers[layers].objects[i].gid then --image object
					for sets = 1, #mapData.tilesets do
						local firstgid = mapData.tilesets[sets].firstgid
						local lastgid = firstgid + #sheetFrames[sets] + 1
						local tileNumber = mapData.layers[layers].objects[i].gid
						tileNumber = math.max(0, tileNumber - firstgid + 1)
						if tileNumber > 0 then 
							if tileNumber < lastgid - firstgid then
								local image = display.newImage( imageSheets[sets], tileNumber)
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
								mergedProperties =  nil
								layerGroup:insert( image )
								image.x = mapData.layers[layers].objects[i].x 
								image.y = mapData.layers[layers].objects[i].y							
							end
						end
					end
				else
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

function tiledMap:destroy()
	-- Nothing to Destroy, yet
end

return tiledMap
