package externs;

import js.lib.Promise;
import js.node.Buffer;

// https://github.com/lovell/sharp/blob/1bbee519aa33205cee9da8f0ad26b26b08a5a520/lib/index.d.ts

typedef SharpCreateOptions = {
	create:{
		width:Int, height:Int, channels:Int, background:BackgroundColor
	}
}

@:jsRequire("Sharp")
extern class Sharp {
	@:selfCall
	@:overload(function(input:Buffer):Sharp {})
	@:overload(function(input:String):Sharp {})
	@:overload(function(options:SharpCreateOptions):Sharp {})
	public static function create(input:Dynamic):Sharp;

	function resize(width:Int, height:Int, ?options:ResizeOptions):Sharp;
	function rotate(?angle:Int):Sharp;
	function trim(?options:TrimOptions):Sharp;
	function composite(images:Array<CompositeImage>):Sharp;
	function png(?options:PngOptions):Sharp;
	function jpeg(?options:JpegOptions):Sharp;
	function webp(?options:WebpOptions):Sharp;
	function avif(?options:AvifOptions):Sharp;
	function raw():Sharp;
	function toBuffer():Promise<Buffer>;
	extern inline function toBufferWithInfo():Promise<{data:Buffer, info:OutputInfo}> {
		final toBuffer:Dynamic = toBuffer;
		return toBuffer({resolveWithObject: true});
	}
	function toFile(path:String):Promise<OutputInfo>;
	function extract(arg:{
		left:Int,
		top:Int,
		width:Int,
		height:Int
	}):Sharp;
}

typedef OutputInfo = {
	var format:String;
	var size:Int;
	var width:Int;
	var height:Int;
	/** 1 for grayscale, 2 for grayscale + alpha, 3 for sRGB, 4 for CMYK or RGBA */
	var channels:Int;
	/** indicating if premultiplication was used */
	var premultiplied:Bool;
	/** Only defined when using a crop strategy */
	var ?cropOffsetLeft:Int;
	/** Only defined when using a crop strategy */
	var ?cropOffsetTop:Int;
	/** Only defined when using a trim method */
	var ?trimOffsetLeft:Int;
	/** Only defined when using a trim method */
	var ?trimOffsetTop:Int;
	/** DPI the font was rendered at, only defined when using `text` input */
	var ?textAutofitDpi:Int;
	/** When using the attention crop strategy, the focal point of the cropped region */
	var ?attentionX:Int;
	var ?attentionY:Int;
	/** Number of pages/frames contained within the image, with support for TIFF, HEIF, PDF, animated GIF and animated WebP */
	var ?pages:Int;
	/** Number of pixels high each page in a multi-page image will be. */
	var ?pageHeight:Int;
}

typedef BackgroundColor = {
	r:Int,
	g:Int,
	b:Int,
	alpha:Float
}

typedef ResizeOptions = {
	?fit:String,
	?position:String,
	?kernel:String
}

typedef TrimOptions = {
	?threshold:Int,
	?background:BackgroundColor,
	?lineArt:Bool,
}

typedef CompositeImage = {
	input:Buffer,
	top:Int,
	left:Int
}

typedef PngOptions = {
	/** Use progressive (interlace) scan (optional, default false) */
	var ?progressive:Bool;
	/** zlib compression level, 0-9 (optional, default 6) */
	var ?compressionLevel:Int;
	/** Use adaptive row filtering (optional, default false) */
	var ?adaptiveFiltering:Bool;
	/** Use the lowest Int of colours needed to achieve given quality (optional, default `100`) */
	var ?quality:Int;
	/** Level of CPU effort to reduce file size, between 1 (fastest) and 10 (slowest), sets palette to true (optional, default 7) */
	var ?effort:Int;
	/** Quantise to a palette-based image with alpha transparency support (optional, default false) */
	var ?palette:Bool;
	/** Maximum Int of palette entries (optional, default 256) */
	var ?colours:Int;
	/** Maximum number of palette entries (optional, default 256) */
	var ?colors:Int;
	/**  Level of Floyd-Steinberg error diffusion (optional, default 1.0) */
	var ?dither:Int;
}

typedef JpegOptions = {
	?quality:Int
}

typedef WebpOptions = {
	?quality:Int,
	?alphaQuality:Int
}

typedef AvifOptions = {
	?quality:Int
}

typedef ToBufferOptions = {
	?resolveWithObject:Bool
}

typedef SharpOutputInfo = {
	width:Int,
	height:Int,
	channels:Int,
	?trimOffsetLeft:Int,
	?trimOffsetTop:Int
}

typedef SharpResult = {
	data:Buffer,
	info:SharpOutputInfo
}
