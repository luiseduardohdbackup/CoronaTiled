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
-- 
-- Loads JSON saved map files from Tiled http://www.mapeditor.org/
--
-- SUPPORTED
-- JSON saved map files
-- Multiple Layers
-- Multiple Tilesets
-- Margins and spacing
-- Uses Corona Image Maps and Image Map groups if you limit yourself
-- to a single tileset image
-- 
-- NOT SUPPORTED
-- TMX files
-- Offsets
-- Object types (regular, polygon, line)
-- Properties
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
		if mapData.layers[layers].data then -- render only tile layers
			local layerGroup
			if #mapData.tilesets==1 then
				layerGroup = display.newImageGroup( imageSheets[1] ) -- use an imageGroup
			else
				layerGroup = display.newGroup() -- more than one imageSheet? then use a group
			end
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
								tile:setReferencePoint( display.TopLeftReferencePoint )
								layerGroup:insert( tile )
							end
						end
					end
				end
			end
			layerGroup.alpha = mapData.layers[layers].opacity
			layerGroup.isVisible = mapData.layers[layers].visible
			mapGroup:insert(layerGroup)
		end
	end
	mapGroup.data = mapData -- pass the raw data back
	return mapGroup
end

function tiledMap:destroy()
	-- Nothing to Destroy, yet
end

return tiledMap
