package externs;

enum abstract PackingLogic(Int) {
	var MAX_AREA = 0;
	var MAX_EDGE = 1;
	var FILL_WIDTH = 2;
}

typedef PackerOptions = {
	?smart:Bool,
	?pot:Bool,
	?square:Bool,
	?allowRotation:Bool,
	?tag:Bool,
	?exclusiveTag:Bool,
	?border:Int,
	?logic:PackingLogic
}

typedef IRectangle = {
	width:Int,
	height:Int,
	x:Int,
	y:Int,

	data:Dynamic,
	rot:Dynamic,
}

typedef IBin = {
	width:Int,
	height:Int,
	maxWidth:Int,
	maxHeight:Int,
	freeRects:Array<IRectangle>,
	rects:Array<IRectangle>,
}

@:jsRequire("maxrects-packer", "MaxRectsPacker")
extern class MaxRectsPacker {
	var bins:Array<IBin>;

	function new(
		?width:Int = 4096,
		?height:Int = 4096,
		padding:Int = 0,
		?config:PackerOptions
	);

	function addArray(arr:Array<{width:Int, height:Int, data:String}>):Void;
}
