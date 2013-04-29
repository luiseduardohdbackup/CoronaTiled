CoronaTiled
===========

Load Tiled Maps into Corona SDK

Version: 0.4

Update History:

* 0.1 - Initial release
* 0.2 - GridMap+Tiled release
* 0.3 - Bugfixes & starting TMX support
* 0.4 - Load a map region & tile properties including shapes
* 0.5 - Bugfixes & Sprite Layers
* 0.6 - First GUI release and "tile gap" fix

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
* GUI Text areas and Touch areas (buttons)
 
NOT SUPPORTED
* TMX files
* Offsets
* Transparent colors
* External tilesets
* zlib/gzip compression
* Isometric maps
* Flipped and rotated tiles (but you can set a layer property to be objects:angle=90)
* Saving loaded maps
