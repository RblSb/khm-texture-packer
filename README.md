# khm-texture-packer

Fast and simple atlas generator from specified texture folder.

Depends only on `sharp` and `maxrects-packer` `nodejs` libraries.

## Installation

`npm i -g https://github.com/RblSb/khm-texture-packer`

## Example
```js
const TexturePacker = require('khm-texture-packer').TexturePacker;
const promise = TexturePacker.pack({
	atlasDir: './textures/tiles', // input folder (non-recursive)
	outputDir: './atlases', // folder for tiles.png and tiles.json
	atlasName: 'tiles',
	textureFormat: 'png', // or jpeg / webp / avif
	exporter: 'JsonHash',
	atlasConfig: { // optional obj, default values are:
		maxWidth: maxWidth, // 2048
		maxHeight: maxHeight, // 2048
		padding: padding, // 2
		alphaThreshold: alphaThreshold, // 0
		removeAlpha: removeAlpha, // false
		extrude: extrude, // 0
		// optional array of frame filenames
		extrudeFrames: extrudeFrames, // undefined
		powerOfTwo: powerOfTwo, // true
		square: square, // false
		hasFileExtensions: hasFileExtensions, // false
		trimMode: trimMode, // 'trim', can be 'crop' or 'none'
		allowRotation: allowRotation, // false
		scale: scale // 1.0
	},
	formatConfig: { // optional obj
		png: {
			tinify: true, // optimize palette to 256 colors, false by default
		}
	}
});

promise.then(info => {
	// `info` is `undefined` if input folder has no images and generation was skipped
	if (!info) return;
	// contains info of generated texture atlas
	const kb = Math.floor(info.size / 1024 * 10) / 10;
	console.log(`${info.atlasFileName} ${kb} KiB ${info.width}x${info.height}`);
});
```

## Supported `exporter` types:
- JsonHash
- JsonArray
- Xml
- Pixi
- Phaser3
- GodotAtlas
- GodotTileset
- Spine
- Unreal
- Unity3d
- Cocos2d
- Starling
- Css
- `customExporter: data -> myExporter(data)`

## Usage in Haxe:
- Add `--library hxnodejs`
- Copy `src/Types.hx` to have library type externs
- Example (Haxe):
```haxe
import Types;

@:jsRequire("khm-texture-packer", "TexturePacker")
extern class TexturePacker {
	static function pack(config:TexturePackerConfig):Promise<OutputInfo>;
}

function main() {
	TexturePacker.pack({...}).then(info -> ...);
}
```

You can also install it globally with `npm -g`, use `@:native("TexturePacker")`
instead of `@:jsRequire` meta, and access this way:
```haxe
final pathBuffer:Buffer = ChildProcess.execSync("npm root --location=global");
final path = pathBuffer.toString().trim();
try {
	final lib = Node.require(path + "/khm-texture-packer");
	Node.global.TexturePacker = lib.TexturePacker;
} catch (err) {
	console.log("Install khm-texture-packer globally first: check out README.md");
	Node.process.exit(1);
	return;
}
```
