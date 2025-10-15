import Types;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Path;

using Lambda;
using StringTools;

class Templates {
	static final APP_NAME = "khm-texture-packer";
	static final APP_URL = "https://github.com/RblSb/khm-texture-packer";
	static final APP_VERSION = "1.0";

	public static function export(exporter:ExporterType, data:TemplateData):String {
		return switch exporter {
			case JsonHash: jsonHash(data);
			case JsonArray: jsonArray(data);
			case Xml: xml(data);
			case Pixi: jsonHash(data);
			case Phaser3: phaser3(data);
			case GodotAtlas: godotAtlas(data);
			case GodotTileset: godotAtlas(data);
			case Spine: spine(data);
			case Unreal: unreal(data);
			case Unity3d: unity3d(data);
			case Cocos2d: cocos2d(data);
			case Starling: starling(data);
			case Css: css(data);
			case _: throw 'Unknown exporter type: $exporter';
		}
	}

	public static function jsonHash(data:TemplateData):String {
		final atlas = {
			frames: ({} : DynamicAccess<Any>),
			meta: metaObj()
		};

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			atlas.frames[frameId] = {
				frame: {
					x: block.frameRect.x,
					y: block.frameRect.y,
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				spriteSourceSize: {
					x: Math.abs(block.spriteRect.x),
					y: Math.abs(block.spriteRect.y),
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				sourceSize: {
					w: block.spriteRect.w,
					h: block.spriteRect.h
				},
				trimmed: block.trimmed,
				rotated: block.rotated
			};
		}

		return Json.stringify(atlas, null, "\t");
	}

	public static function jsonArray(data:TemplateData):String {
		final frames:Array<Dynamic> = [];

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			frames.push({
				filename: frameId,
				frame: {
					x: block.frameRect.x,
					y: block.frameRect.y,
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				rotated: block.rotated,
				trimmed: block.trimmed,
				spriteSourceSize: {
					x: Math.abs(block.spriteRect.x),
					y: Math.abs(block.spriteRect.y),
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				sourceSize: {
					w: block.spriteRect.w,
					h: block.spriteRect.h
				},
				pivot: {
					x: 0.5,
					y: 0.5
				}
			});
		}

		final result = {
			frames: frames,
			meta: {
				app: APP_URL,
				version: APP_VERSION,
				image: data.textureName,
				format: "RGBA8888",
				size: {
					w: data.atlasWidth,
					h: data.atlasHeight
				},
				scale: data.scale
			}
		};

		return Json.stringify(result, null, "\t");
	}

	public static function xml(data:TemplateData):String {
		final buf = new StringBuf();
		buf.add('<!--\nCreated with $APP_NAME v$APP_VERSION $APP_URL\n');
		buf.add('Format:\n');
		buf.add('n  => name\n');
		buf.add('x  => x pos\n');
		buf.add('y  => y pos\n');
		buf.add('w  => width\n');
		buf.add('h  => height\n');
		buf.add('pX => x pos of the pivot point\n');
		buf.add('pY => y pos of the pivot point\n');
		buf.add('oX => x-corner offset\n');
		buf.add('oY => y-corner offset\n');
		buf.add('oW => original width\n');
		buf.add('oH => original height\n');
		buf.add('r => \'y\' if sprite is rotated-->\n');
		buf.add('<?xml version="1.0" encoding="UTF-8"?>\n');
		buf.add('<TextureAtlas imagePath="${data.textureName}" width="${data.atlasWidth}" height="${data.atlasHeight}" scale="${data.scale}" format="RGBA8888">\n');

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			buf.add('  <sprite n="${frameId}" x="${block.frameRect.x}" y="${block.frameRect.y}" w="${block.frameRect.w}" h="${block.frameRect.h}" pX="0.5" pY="0.5"');

			if (block.trimmed) {
				buf.add(' oX="${Math.abs(block.spriteRect.x)}" oY="${Math.abs(block.spriteRect.y)}" oW="${block.spriteRect.w}" oH="${block.spriteRect.h}"');
			}

			if (block.rotated) {
				buf.add(' r="y"');
			}

			buf.add('/>\n');
		}

		buf.add('</TextureAtlas>');
		return buf.toString();
	}

	public static function cocos2d(data:TemplateData):String {
		final buf = new StringBuf();
		buf.add('<?xml version="1.0" encoding="UTF-8"?>\n');
		buf.add('<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n');
		buf.add('<plist version="1.0">\n');
		buf.add('  <dict>\n');
		buf.add('    <key>frames</key>\n');
		buf.add('    <dict>\n');

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			final offsetX = offsetLeft(Math.abs(block.spriteRect.x), block.frameRect.w, block.spriteRect.w);
			final offsetY = offsetRight(Math.abs(block.spriteRect.y), block.frameRect.h, block.spriteRect.h);

			buf.add('      <key>${frameId}</key>\n');
			buf.add('      <dict>\n');
			buf.add('        <key>frame</key>\n');
			buf.add('        <string>{{${block.frameRect.x},${block.frameRect.y}},{${block.frameRect.w},${block.frameRect.h}}}</string>\n');
			buf.add('        <key>offset</key>\n');
			buf.add('        <string>{${offsetX},${offsetY}}</string>\n');
			buf.add('        <key>rotated</key>\n');
			buf.add('        <${block.rotated}/>\n');
			buf.add('        <key>sourceColorRect</key>\n');
			buf.add('        <string>{{${Math.abs(block.spriteRect.x)},${Math.abs(block.spriteRect.y)}},{${block.frameRect.w},${block.frameRect.h}}}</string>\n');
			buf.add('        <key>sourceSize</key>\n');
			buf.add('        <string>{${block.spriteRect.w},${block.spriteRect.h}}</string>\n');
			buf.add('      </dict>\n');
		}

		buf.add('    </dict>\n');
		buf.add('    <key>metadata</key>\n');
		buf.add('    <dict>\n');
		buf.add('      <key>format</key>\n');
		buf.add('      <integer>2</integer>\n');
		buf.add('      <key>pixelFormat</key>\n');
		buf.add('      <string>RGBA8888</string>\n');
		buf.add('      <key>premultiplyAlpha</key>\n');
		buf.add('      <false/>\n');
		buf.add('      <key>realTextureFileName</key>\n');
		buf.add('      <string>${data.textureName}</string>\n');
		buf.add('      <key>size</key>\n');
		buf.add('      <string>{${data.atlasWidth},${data.atlasHeight}}</string>\n');
		buf.add('      <key>textureFileName</key>\n');
		buf.add('      <string>${data.textureName}</string>\n');
		buf.add('    </dict>\n');
		buf.add('  </dict>\n');
		buf.add('</plist>');

		return buf.toString();
	}

	public static function css(data:TemplateData):String {
		final buf = new StringBuf();
		buf.add('/*\n');
		buf.add('   ---------------------------\n');
		buf.add('   created with $APP_NAME v$APP_VERSION\n');
		buf.add('   $APP_URL\n');
		buf.add('   ---------------------------\n');
		buf.add('*/\n');

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			buf.add('.${frameId} { display:inline-block;overflow:hidden;background:url(${data.textureName}) no-repeat -${block.frameRect.x}px -${block.frameRect.y}px;');

			if (!block.rotated) {
				buf.add('width:${block.frameRect.w}px;height:${block.frameRect.h}px;');
			} else {
				final hw = block.frameRect.w / 2;
				final hh = block.frameRect.h / 2;
				buf.add('width:${block.frameRect.h}px;height:${block.frameRect.w}px;');
				buf.add('transform-origin:${hw}px ${hh}px;');
				buf.add('-moz-transform-origin:${hw}px ${hh}px;');
				buf.add('-ms-transform-origin:${hw}px ${hh}px;');
				buf.add('-webkit-transform-origin:${hw}px ${hh}px;');
				buf.add('-o-transform-origin:${hw}px ${hh}px;');
				buf.add('transform:rotate(-90deg);');
				buf.add('-moz-transform:rotate(-90deg);');
				buf.add('-ms-transform:rotate(-90deg);');
				buf.add('-webkit-transform:rotate(-90deg);');
				buf.add('-o-transform:rotate(-90deg);');
			}

			if (block.trimmed) {
				buf.add('margin-left:${Math.abs(block.spriteRect.x)}px;margin-top:${Math.abs(block.spriteRect.y)}px');
			}

			buf.add(' }\n');
		}

		return buf.toString();
	}

	public static function oldCss(data:TemplateData):String {
		final buf = new StringBuf();
		buf.add('/*\n');
		buf.add('   ---------------------------\n');
		buf.add('   created with $APP_NAME v$APP_VERSION\n');
		buf.add('   $APP_URL\n');
		buf.add('   ---------------------------\n');
		buf.add('*/\n');

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			buf.add('.${frameId} { display:inline-block;overflow:hidden;background:url(${data.textureName}) no-repeat -${block.frameRect.x}px -${block.frameRect.y}px;width:${block.frameRect.w}px;height:${block.frameRect.h}px }\n');
		}

		return buf.toString();
	}

	public static function starling(data:TemplateData):String {
		final buf = new StringBuf();
		buf.add('<!--\n');
		buf.add('Created with $APP_NAME v$APP_VERSION $APP_URL\n');
		buf.add('-->\n');
		buf.add('<?xml version="1.0" encoding="UTF-8"?>\n');
		buf.add('<TextureAtlas imagePath="${data.textureName}" width="${data.atlasWidth}" height="${data.atlasHeight}">\n');

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			buf.add('  <SubTexture name="${frameId}" x="${block.frameRect.x}" y="${block.frameRect.y}" ');

			if (block.rotated) {
				buf.add('width="${block.frameRect.h}" height="${block.frameRect.w}" rotated="true"');
			} else {
				buf.add('width="${block.frameRect.w}" height="${block.frameRect.h}"');
			}

			buf.add(' frameX="-${Math.abs(block.spriteRect.x)}" frameY="-${Math.abs(block.spriteRect.y)}" frameWidth="${block.spriteRect.w}" frameHeight="${block.spriteRect.h}"/>\n');
		}

		buf.add('</TextureAtlas>');
		return buf.toString();
	}

	public static function spine(data:TemplateData):String {
		final buf = new StringBuf();
		buf.add('\n${data.textureName}\n');
		buf.add('size: ${data.atlasWidth},${data.atlasHeight}\n');
		buf.add('format: RGBA8888\n');
		buf.add('filter: Nearest,Nearest\n');
		buf.add('repeat: none\n');

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			buf.add('${frameId}\n');
			buf.add('  rotate: ${block.rotated}\n');
			buf.add('  xy: ${block.frameRect.x},${block.frameRect.y}\n');
			buf.add('  size: ${block.frameRect.w},${block.frameRect.h}\n');
			buf.add('  orig: ${block.spriteRect.w},${block.spriteRect.h}\n');
			buf.add('  offset: 0,0\n');
			buf.add('  index: -1\n');
		}

		return buf.toString();
	}

	public static function phaser3(data:TemplateData):String {
		final frames:Array<Dynamic> = [];

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			frames.push({
				filename: frameId,
				rotated: block.rotated,
				trimmed: block.trimmed,
				sourceSize: {
					w: block.spriteRect.w,
					h: block.spriteRect.h
				},
				spriteSourceSize: {
					x: Math.abs(block.spriteRect.x),
					y: Math.abs(block.spriteRect.y),
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				frame: {
					x: block.frameRect.x,
					y: block.frameRect.y,
					w: block.frameRect.w,
					h: block.frameRect.h
				}
			});
		}

		final texture = {
			image: data.textureName,
			format: "RGBA8888",
			size: {
				w: data.atlasWidth,
				h: data.atlasHeight
			},
			scale: data.scale,
			frames: frames
		};

		final result:Dynamic = {
			textures: [texture],
			meta: metaObj()
		};

		return Json.stringify(result, null, "\t");
	}

	public static function unity3d(data:TemplateData):String {
		final buf = new StringBuf();
		buf.add('#\n');
		buf.add('# Sprite sheet data for Unity.\n');
		buf.add('#\n');
		buf.add('# To import these sprites into your Unity project, download "TexturePackerImporter":\n');
		buf.add('# https://assetstore.unity.com/packages/tools/sprite-management/texturepacker-importer-16641\n');
		buf.add('#\n');
		buf.add('# created with $APP_NAME v$APP_VERSION\n');
		buf.add('# $APP_URL\n');
		buf.add('#\n');
		buf.add(':format=40300\n');
		buf.add(':texture=${data.textureName}\n');
		buf.add(':size=${data.atlasWidth}x${data.atlasHeight}\n');
		buf.add(':pivotpoints=enabled\n');
		buf.add(':borders=disabled\n\n');

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);
			final escapedName = escapeName(frameId);
			final mirroredY = mirror(block.frameRect.y, block.frameRect.h, data.atlasHeight);

			buf.add('${escapedName};${block.frameRect.x};${mirroredY};${block.frameRect.w};${block.frameRect.h}; 0.5;0.5; 0;0;0;0\n');
		}

		return buf.toString();
	}

	public static function unreal(data:TemplateData):String {
		final atlas = {
			frames: ({} : DynamicAccess<Any>),
			meta: {
				app: APP_URL,
				version: APP_VERSION,
				image: data.textureName,
				format: "RGBA8888",
				size: {
					w: data.atlasWidth,
					h: data.atlasHeight
				},
				scale: data.scale,
				target: "paper2d"
			}
		};

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			atlas.frames[frameId] = {
				frame: {
					x: block.frameRect.x,
					y: block.frameRect.y,
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				rotated: block.rotated,
				trimmed: block.trimmed,
				spriteSourceSize: {
					x: Math.abs(block.spriteRect.x),
					y: Math.abs(block.spriteRect.y),
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				sourceSize: {
					w: block.spriteRect.w,
					h: block.spriteRect.h
				},
				pivot: {
					x: 0.5,
					y: 0.5
				}
			};
		}

		return Json.stringify(atlas, null, "\t");
	}

	public static function godotAtlas(data:TemplateData):String {
		final sprites:Array<Dynamic> = [];

		final ids = data.blocks.map(block -> block.id);
		ids.sort(Utils.numericStringSort);

		for (id in ids) {
			final block = data.blocks.find(b -> b.id == id) ?? continue;
			final frameId = data.spriteExtensions ? block.id : Path.withoutExtension(block.id);

			sprites.push({
				filename: frameId,
				region: {
					x: block.frameRect.x,
					y: block.frameRect.y,
					w: block.frameRect.w,
					h: block.frameRect.h
				},
				margin: {
					x: 0,
					y: 0,
					w: 0,
					h: 0
				}
			});
		}

		final result = {
			textures: [{
				image: data.textureName,
				size: {
					w: data.atlasWidth,
					h: data.atlasHeight
				},
				sprites: sprites
			}],
			meta: {
				app: APP_URL,
				version: APP_VERSION,
				format: "RGBA8888"
			}
		};

		return Json.stringify(result, null, "\t");
	}

	static function metaObj():{app:String, version:String} {
		return {
			app: APP_URL,
			version: APP_VERSION,
		}
	}

	static function offsetLeft(start:Float, size1:Float, size2:Float):Float {
		final x1 = start + size1 / 2;
		final x2 = size2 / 2;
		return x1 - x2;
	}

	static function offsetRight(start:Float, size1:Float, size2:Float):Float {
		final x1 = start + size1 / 2;
		final x2 = size2 / 2;
		return x2 - x1;
	}

	static function mirror(start:Float, size1:Float, size2:Float):Float {
		return size2 - start - size1;
	}

	static function escapeName(name:String):String {
		return name.replace("%", "%25")
			.replace("#", "%23").replace(":", "%3A").replace(";", "%3B").replace("\\", "-").replace("/", "-");
	}
}
