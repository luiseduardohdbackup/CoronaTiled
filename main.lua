display.setStatusBar( display.HiddenStatusBar )
display.setDefault("minTextureFilter", "linear")
display.setDefault("magTextureFilter", "linear")

local cleanUp
local widget=require("widget")

local data={
	{"Benchmarking 1", benchmarking}
}

local g=display.newGroup()
local b={}

for i=1, #data do
	b[i]=widget.newButton{
		
	}
end