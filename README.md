CoronaTiled
===========

Load Tiled Maps into Corona SDK

Version: 0.2

Update History:

0.1 - Initial release
0.2 - GridMap+Tiled release

Loads JSON saved map files from Tiled http://www.mapeditor.org/

SUPPORTED
* JSON/LUA exported map files
* Multiple Layers
* Multiple Tilesets
* Margins and spacing
* Uses Corona Image Maps and Image Map groups if you limit yourself to a single tileset image
* Object types (regular, polygon, line)
* Image Objects
* Physics and display object properties
* Image Layers
 
NOT SUPPORTED
* TMX files
* Offsets
* Transparent colors
* External tilesets
* zlib/gzip compression
* Isometric maps
* Flipped and rotated tiles (but you can set a layer property to be objects:angle=90)
* Saving loaded maps
