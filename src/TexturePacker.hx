import Types;
import externs.MaxRectsPacker;
import externs.Sharp.Sharp;
import haxe.crypto.Md5;
import js.lib.Promise;
import js.node.Buffer;
import js.node.Path;
import sys.FileSystem;
import sys.io.File;

using Lambda;
using StringTools;

typedef ImageData = {
	width:Int,
	height:Int,
	trimmed:Bool,
	?trim:{
		x:Int,
		y:Int,
		w:Int,
		h:Int
	},
	data:Buffer
}

typedef AtlasInfo = {
	blocks:Array<BlockData>,
	atlasWidth:Int,
	atlasHeight:Int
}

class TexturePacker {
	@:expose
	public static function pack(config:TexturePackerConfig):Promise<Null<OutputInfo>> {
		if (!(config.atlasConfig is AtlasConfig)) {
			config.atlasConfig = AtlasConfig.fromObject(config.atlasConfig);
		}
		final atlasConfig = config.atlasConfig;
		final atlasDir = config.atlasDir;
		final atlasName = config.atlasName;
		final outputDir = config.outputDir;
		final textureFormat = config.textureFormat;
		final formatConfig = config.formatConfig ?? {};

		var names = FileSystem.readDirectory(atlasDir);
		names = names.filter(name -> {
			if (FileSystem.isDirectory('$atlasDir/$name')) return false;
			if (name.startsWith(".")) return false;
			final ext = haxe.io.Path.extension(name);
			if (!isImageExtension(ext)) return false;
			return true;
		});
		if (names.length == 0) return Promise.resolve(null);

		return getBlocksData(names, atlasDir, atlasConfig).then(blocks -> {
			final atlasInfo = fitBlocks(atlasConfig, blocks);

			if (atlasInfo == null) throw 'Atlas is too big: $atlasDir';

			final atlasWidth = atlasInfo.atlasWidth;
			final atlasHeight = atlasInfo.atlasHeight;

			return getTextureBuffer({
				atlasWidth: atlasWidth,
				atlasHeight: atlasHeight,
				blocks: blocks,
				removeAlpha: atlasConfig.removeAlpha,
				textureFormat: textureFormat,
				formatConfig: formatConfig
			}).then(atlasTextureData -> {
				final atlasOutputName = '$atlasName.$textureFormat';
				final atlasPath = Path.join(outputDir, atlasOutputName);

				return atlasTextureData.toFile(atlasPath).then(info -> {
					final templateData:TemplateData = {
						textureName: atlasOutputName,
						atlasWidth: atlasWidth,
						atlasHeight: atlasHeight,
						scale: atlasConfig.scale,
						blocks: blocks,
						spriteExtensions: atlasConfig.hasFileExtensions
					};
					final atlasTextData = if (config.customExporter != null) {
						config.customExporter(templateData);
					} else {
						Templates.export(config.exporter, templateData);
					}
					final ext = config.exporter?.toExtension() ?? "json";
					final atlasDataName = '$atlasName.$ext';
					final path = Path.join(outputDir, atlasDataName);
					File.saveContent(path, atlasTextData);

					final info:OutputInfo = cast info;
					info.dataFileName = atlasDataName;
					info.atlasFileName = atlasOutputName;
					Promise.resolve(info);
				});
			});
		});
	}

	@:expose
	public static function getDataFileExtension(type:ExporterType):String {
		return type.toExtension();
	}

	static function isImageExtension(ext:String):Bool {
		return switch ext {
			case "png", "jpg", "jpeg", "webp", "avif": true;
			case _: false;
		}
	}

	static function getBlocksData(names:Array<String>, atlasDir:String, config:AtlasConfig):Promise<Array<BlockData>> {
		final blocks:Array<BlockData> = [];
		final sprites:Map<String, ImageData> = [];

		function processBlock(file:String, imgHash:String):Void {
			final sprite = sprites.get(imgHash);
			final trimmed = sprite.trimmed;
			final imageBuffer = sprite.data;
			final width = sprite.width;
			final height = sprite.height;
			final trim = sprite.trim;

			final frameRect = {
				x: 0,
				y: 0,
				w: trim?.w ?? width,
				h: trim?.h ?? height
			};
			final spriteRect = {
				x: trim?.x ?? 0,
				y: trim?.y ?? 0,
				w: width,
				h: height
			};
			final extrude = calcExtrude(config, file);

			blocks.push({
				id: file,
				frameRect: frameRect,
				spriteRect: spriteRect,
				trimmed: trimmed,
				rotated: false,
				extrude: extrude,
				hash: imgHash,
				imageBuffer: imageBuffer
			});
		}

		return Utils.promiseSequence(names.map(file -> {
			return () -> {
				final imgPath = Path.join(atlasDir, file);
				final imgHash = Md5.encode(File.getContent(imgPath));

				if (sprites.exists(imgHash)) {
					processBlock(file, imgHash);
					return Promise.resolve(null);
				}

				final imgData:ImageData = {
					width: 0,
					height: 0,
					trimmed: false,
					trim: null,
					data: null
				};

				return Sharp.create(imgPath).toBufferWithInfo().then(result -> {
					imgData.width = result.info.width;
					imgData.height = result.info.height;
					imgData.data = result.data;

					if (config.scale == 1) return Promise.resolve(null);

					final newWidth = Math.ceil(imgData.width * config.scale);
					final newHeight = Math.ceil(imgData.height * config.scale);
					return Sharp.create(imgData.data)
						.resize(newWidth, newHeight).toBufferWithInfo().then(scaledResult -> {
						imgData.width = newWidth;
						imgData.height = newHeight;
						imgData.data = scaledResult.data;
						return Promise.resolve(null);
					});
				}).then(_ -> {
					if (config.trimMode == None) return Promise.resolve(null);
					if (imgData.width < 3 || imgData.height < 3) return Promise.resolve(null);
					return Sharp.create(imgData.data).trim({
						threshold: config.alphaThreshold,
						background: {
							r: 0,
							g: 0,
							b: 0,
							alpha: 0
						}
					}).toBufferWithInfo().then(trimResult -> {
						final trimOffsetLeft = trimResult.info.trimOffsetLeft;
						final trimOffsetTop = trimResult.info.trimOffsetTop;
						final trimWidth = trimResult.info.width;
						final trimHeight = trimResult.info.height;
						if (imgData.width == trimWidth && imgData.height == trimHeight) {
							return Promise.resolve(null);
						}
						switch config.trimMode {
							case None:
							case Trim:
								imgData.trimmed = true;
								imgData.trim = {
									x: trimOffsetLeft,
									y: trimOffsetTop,
									w: trimWidth,
									h: trimHeight
								};
								imgData.data = trimResult.data;
							case Crop:
								imgData.width = trimWidth;
								imgData.height = trimHeight;
								imgData.data = trimResult.data;
						}
						return Promise.resolve(null);
					}).catchError(err -> {
						trace('Warning: Failed to trim image $file: $err');
						return Promise.resolve(null);
					});
				}).then(_ -> {
					sprites.set(imgHash, imgData);
					processBlock(file, imgHash);
					return Promise.resolve(null);
				});
			};
		})).then(_ -> Promise.resolve(blocks));
	}

	static function calcExtrude(config:AtlasConfig, id:String):Int {
		if (config.extrudeFrames == null) return config.extrude;
		if (config.extrudeFrames.contains(id)) {
			if (config.extrude == 0) return 1;
			return config.extrude;
		}
		return 0;
	}

	static function getTextureBuffer(params:{
		atlasWidth:Int,
		atlasHeight:Int,
		blocks:Array<BlockData>,
		removeAlpha:Bool,
		textureFormat:TextureFormat,
		formatConfig:FormatConfig
	}):Promise<Sharp> {
		final width = params.atlasWidth;
		final height = params.atlasHeight;
		final blocks = params.blocks;
		final removeAlpha = params.removeAlpha;
		final textureFormat = params.textureFormat;
		final formatConfig = params.formatConfig;

		final frames:Array<{
			imageBuffer:Buffer,
			left:Int,
			top:Int,
			rotated:Bool
		}> = [];

		for (block in blocks) {
			if (block.duplicate != true) {
				if (block.extrude > 0) {
					for (data in addExtrudeData(block)) {
						frames.push(data);
					}
				}
				frames.push({
					imageBuffer: block.imageBuffer,
					left: block.frameRect.x,
					top: block.frameRect.y,
					rotated: block.rotated
				});
			}
		}

		return Promise.all(frames.map(frame -> {
			if (frame.rotated) {
				return Sharp.create(frame.imageBuffer)
					.rotate(90).toBuffer().then(rotatedBuffer -> {
					return Promise.resolve({
						input: rotatedBuffer,
						top: frame.top,
						left: frame.left
					});
				});
			} else {
				return Promise.resolve({
					input: frame.imageBuffer,
					top: frame.top,
					left: frame.left
				});
			}
		})).then(compositeImages -> {
			var buffer = Sharp.create({
				create: {
					width: width,
					height: height,
					channels: 4,
					background: {
						r: 0,
						g: 0,
						b: 0,
						alpha: removeAlpha ? 1 : 0
					}
				}
			}).composite(compositeImages);

			switch textureFormat {
				case Png:
					final tinify = formatConfig?.png?.tinify ?? false;
					if (tinify) buffer = buffer.png({
						compressionLevel: 9,
						adaptiveFiltering: false,
						quality: 100,
						palette: true,
					}); else buffer = buffer.png({
						compressionLevel: 9,
						adaptiveFiltering: true,
						quality: 100,
						palette: false,
					});
				case Jpeg:
					final quality = formatConfig?.jpeg?.quality ?? 80;
					buffer = buffer.jpeg({quality: quality});
				case Webp:
					final quality = formatConfig?.webp?.quality ?? 80;
					final alphaQuality = formatConfig?.webp?.alphaQuality ?? 80;
					buffer = buffer.webp({quality: quality, alphaQuality: alphaQuality});
				case Avif:
					final quality = formatConfig?.avif?.quality ?? 80;
					buffer = buffer.avif({quality: quality});
			}
			return buffer;
		});
	}

	static function addExtrudeData(block:BlockData):Array<{
		imageBuffer:Buffer,
		top:Int,
		left:Int,
		rotated:Bool
	}> {
		final imageBuffer = block.imageBuffer;
		final frameRect = block.frameRect;
		final extrude = block.extrude;
		final rotated = block.rotated;

		return [
			{
				imageBuffer: imageBuffer,
				top: frameRect.y - extrude,
				left: frameRect.x - extrude,
				rotated: rotated
			},
			{
				imageBuffer: imageBuffer,
				top: frameRect.y - extrude,
				left: frameRect.x + extrude,
				rotated: rotated
			},
			{
				imageBuffer: imageBuffer,
				top: frameRect.y + extrude,
				left: frameRect.x - extrude,
				rotated: rotated
			},
			{
				imageBuffer: imageBuffer,
				top: frameRect.y + extrude,
				left: frameRect.x + extrude,
				rotated: rotated
			},
			{
				imageBuffer: imageBuffer,
				top: frameRect.y,
				left: frameRect.x + extrude,
				rotated: rotated
			},
			{
				imageBuffer: imageBuffer,
				top: frameRect.y,
				left: frameRect.x - extrude,
				rotated: rotated
			},
			{
				imageBuffer: imageBuffer,
				top: frameRect.y - extrude,
				left: frameRect.x,
				rotated: rotated
			},
			{
				imageBuffer: imageBuffer,
				top: frameRect.y + extrude,
				left: frameRect.x,
				rotated: rotated}
		];
	}

	static function fitBlocks(atlasConfig:AtlasConfig, blocks:Array<BlockData>):Null<AtlasInfo> {
		final maxWidth = atlasConfig.maxWidth;
		final maxHeight = atlasConfig.maxHeight;
		final powerOfTwo = atlasConfig.powerOfTwo;
		final square = atlasConfig.square;
		final allowRotation = atlasConfig.allowRotation;
		final padding = atlasConfig.padding;

		final packer = new MaxRectsPacker(maxWidth, maxHeight, padding, {
			smart: true,
			pot: powerOfTwo,
			square: square,
			allowRotation: allowRotation
		});

		final uniq:Map<String, Bool> = [];

		final blocksWithoutDuplicates = blocks.filter(block -> {
			if (uniq.exists(block.hash)) {
				return false;
			}
			uniq.set(block.hash, true);
			return true;
		});

		packer.addArray(blocksWithoutDuplicates.map(block -> {
			return {
				width: block.frameRect.w + block.extrude * 2,
				height: block.frameRect.h + block.extrude * 2,
				data: block.id
			};
		}));

		if (packer.bins.length > 1) {
			return null;
		}

		for (block in blocksWithoutDuplicates) {
			final frame = packer.bins[0].rects.find(packed -> packed.data == block.id);
			if (frame != null) {
				block.frameRect.x = block.extrude + frame.x;
				block.frameRect.y = block.extrude + frame.y;
				block.rotated = frame.rot;
			}
		}

		for (block in blocks) {
			if (!blocksWithoutDuplicates.contains(block)) {
				final updatedBlock = blocksWithoutDuplicates.find(el -> el.hash == block.hash);
				if (updatedBlock != null) {
					block.frameRect.x = updatedBlock.frameRect.x;
					block.frameRect.y = updatedBlock.frameRect.y;
					block.rotated = updatedBlock.rotated;
					block.duplicate = true;
				}
			}
		}

		return {
			blocks: blocks,
			atlasWidth: packer.bins[0].width,
			atlasHeight: packer.bins[0].height
		};
	}
}
