enum abstract TextureFormat(String) {
	var Png = "png";
	var Jpeg = "jpeg";
	var Webp = "webp";
	var Avif = "avif";

	public inline function toString():String {
		return this;
	}
}

enum abstract ExporterType(String) {
	var JsonHash;
	var JsonArray;
	var Xml;
	var Pixi;
	var Phaser3;
	var GodotAtlas;
	var GodotTileset;
	var Spine;
	var Unreal;
	var Unity3d;
	var Cocos2d;
	var Starling;
	var Css;

	public function toExtension():String {
		return switch abstract {
			case JsonHash, JsonArray, Pixi, Phaser3: "json";
			case Xml, Starling: "xml";
			case Css: "css";
			case GodotAtlas, Unity3d: "tpsheet";
			case GodotTileset: "tpset";
			case Cocos2d: "plist";
			case Unreal: "paper2dsprites";
			case Spine: "atlas";
		}
	}
}

typedef TexturePackerConfig = {
	/** Folder with input images. **/
	var atlasDir:String;
	/** Atlas name to generate (without extension). **/
	var atlasName:String;
	/** Output directory for atlas texture / json. **/
	var outputDir:String;
	/** Output atlas texture format. **/
	var textureFormat:TextureFormat;
	/** Output atlas json data format. **/
	var exporter:ExporterType;
	var ?customExporter:(data:TemplateData) -> String;
	var ?atlasConfig:AtlasConfig;
	var ?formatConfig:FormatConfig;
}

@:structInit
@:publicFields
class AtlasConfig {
	/** Max atlas width. **/
	var maxWidth = 2048;
	/** Max atlas height. **/
	var maxHeight = 2048;
	/** Spaces in pixels around images. **/
	var padding = 2;
	/** Alpha threshold value for trimming transparent areas. **/
	var alphaThreshold = 0;
	/** Remove alpha channel. **/
	var removeAlpha = false;
	/** Extrude border pixels size around images by pixel count. **/
	var extrude = 0;
	/** Array of image names to extrude, instead of all images. Sets `extrude` to `1` is found. **/
	var extrudeFrames:Array<String> = null;
	/** Force the atlas size to be a power of two (e.g., 256x256, 512x512). **/
	var powerOfTwo = true;
	/** Force the atlas size to be square. **/
	var square = false;
	/** Append image extensions to sprite frame names. **/
	var hasFileExtensions = false;
	/** Trim mode for transparent areas around images. **/
	var trimMode:TrimMode = Trim;
	/** Allow image rotation when packing. **/
	var allowRotation = false;
	/** Atlas texture scale. **/
	var scale = 1.0;

	public static function fromObject(obj:Any):AtlasConfig {
		final config:AtlasConfig = {};
		for (field in Reflect.fields(obj)) {
			final value = Reflect.field(obj, field);
			Reflect.setField(config, field, value);
		}
		return config;
	}
}

enum abstract TrimMode(String) {
	var None = "none";
	var Trim = "trim";
	var Crop = "crop";
}

typedef FormatConfig = {
	var ?png:{?tinify:Bool};
	var ?jpeg:{?quality:Int};
	var ?webp:{?quality:Int, ?alphaQuality:Int};
	var ?avif:{?quality:Int};
}

typedef TemplateData = {
	textureName:String,
	atlasWidth:Int,
	atlasHeight:Int,
	scale:Float,
	blocks:Array<BlockData>,
	spriteExtensions:Bool
}

typedef BlockData = {
	id:String,
	frameRect:{x:Int, y:Int, w:Int, h:Int},
	spriteRect:{x:Int, y:Int, w:Int, h:Int},
	trimmed:Bool,
	rotated:Bool,
	extrude:Int,
	hash:String,
	imageBuffer:js.node.Buffer,
	?duplicate:Bool
}

typedef OutputInfo = {
	/** Filename of generated json/xml/etc file for atlas texture file. **/
	var dataFileName:String;
	/** Filename of generated atlas texture file. **/
	var atlasFileName:String;

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
