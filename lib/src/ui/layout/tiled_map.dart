import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:xml/xml.dart';

// Tiled dùng 3 bit cao nhất của gid để đánh dấu lật tile — bản đồ này không
// dùng lật tile nên chỉ cần bỏ qua các bit đó khi tra tileset.
const _gidFlipMask = 0x1FFFFFFF;

class TiledAnimFrame {
  const TiledAnimFrame(this.tileId, this.durationMs);
  final int tileId;
  final int durationMs;
}

/// Một tileset (nhúng thẳng trong .tmj hoặc load rời từ .tsx). [image] là ảnh
/// sprite sheet đã decode sẵn để [ui.Canvas.drawImageRect] dùng trực tiếp.
class TiledTileset {
  const TiledTileset({
    required this.firstGid,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.tileCount,
    required this.image,
    required this.animations,
    this.margin = 0,
    this.spacing = 0,
  });

  final int firstGid;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int tileCount;
  final int margin;
  final int spacing;
  final ui.Image image;
  final Map<int, List<TiledAnimFrame>> animations; // local tile id -> frames

  /// Local tile id thật sự cần vẽ tại mốc thời gian [elapsedMs] — trả về
  /// chính [localId] nếu tile đó không có animation.
  int frameAt(int localId, int elapsedMs) {
    final frames = animations[localId];
    if (frames == null || frames.isEmpty) return localId;
    final total = frames.fold<int>(0, (sum, f) => sum + f.durationMs);
    if (total <= 0) return localId;
    var t = elapsedMs % total;
    for (final f in frames) {
      if (t < f.durationMs) return f.tileId;
      t -= f.durationMs;
    }
    return frames.last.tileId;
  }

  ui.Rect srcRectFor(int localId) {
    final col = localId % columns;
    final row = localId ~/ columns;
    final left = margin + col * (tileWidth + spacing);
    final top = margin + row * (tileHeight + spacing);
    return ui.Rect.fromLTWH(
      left.toDouble(),
      top.toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
  }
}

class TiledLayer {
  const TiledLayer({
    required this.name,
    required this.width,
    required this.height,
    required this.gids,
  });
  final String name;
  final int width;
  final int height;
  final List<int> gids;
}

class _TilesetSlot {
  const _TilesetSlot(this.firstGid, this.tileset);
  final int firstGid;
  final TiledTileset?
  tileset; // null nếu thiếu file tileset rời — bỏ qua khi vẽ
}

/// Bản đồ Tiled đã load xong (layers + tilesets + ảnh), sẵn sàng để
/// [TiledMapPainter] vẽ. Xem `assets/tiled/mini_farm.tmj`.
class TiledMap {
  TiledMap._({
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.layers,
    required List<_TilesetSlot> slots,
  }) : _slots = slots..sort((a, b) => a.firstGid.compareTo(b.firstGid));

  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final List<TiledLayer> layers;
  final List<_TilesetSlot> _slots;

  int get pixelWidth => width * tileWidth;
  int get pixelHeight => height * tileHeight;

  /// Tìm tileset sở hữu [rawGid] (đã trừ firstgid ra local id). Trả về null
  /// nếu gid rỗng (0) hoặc rơi vào một tileset rời bị thiếu file.
  (TiledTileset, int)? resolveGid(int rawGid) {
    final gid = rawGid & _gidFlipMask;
    if (gid == 0) return null;
    _TilesetSlot? owner;
    for (final s in _slots) {
      if (gid >= s.firstGid) {
        owner = s;
      } else {
        break;
      }
    }
    final tileset = owner?.tileset;
    if (tileset == null) return null;
    return (tileset, gid - tileset.firstGid);
  }

  static Future<TiledMap> loadFromAssets(String tmjAssetPath) async {
    final raw = await rootBundle.loadString(tmjAssetPath);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final baseDir = tmjAssetPath.substring(
      0,
      tmjAssetPath.lastIndexOf('/') + 1,
    );

    final layers = <TiledLayer>[
      for (final l in (j['layers'] as List).cast<Map<String, dynamic>>())
        if (l['type'] == 'tilelayer')
          TiledLayer(
            name: l['name'] as String,
            width: l['width'] as int,
            height: l['height'] as int,
            gids: (l['data'] as List).map((e) => (e as num).toInt()).toList(),
          ),
    ];

    final slots = <_TilesetSlot>[];
    for (final ts in (j['tilesets'] as List).cast<Map<String, dynamic>>()) {
      final firstGid = ts['firstgid'] as int;
      if (ts.containsKey('image')) {
        slots.add(
          _TilesetSlot(firstGid, await _loadEmbeddedTileset(ts, baseDir)),
        );
      } else {
        final tileset = await _loadExternalTileset(
          '$baseDir${ts['source']}',
          firstGid,
        );
        slots.add(_TilesetSlot(firstGid, tileset));
      }
    }

    return TiledMap._(
      width: j['width'] as int,
      height: j['height'] as int,
      tileWidth: j['tilewidth'] as int,
      tileHeight: j['tileheight'] as int,
      layers: layers,
      slots: slots,
    );
  }

  static Future<TiledTileset> _loadEmbeddedTileset(
    Map<String, dynamic> ts,
    String baseDir,
  ) async {
    final image = await _loadImage('$baseDir${ts['image']}');
    final animations = <int, List<TiledAnimFrame>>{
      for (final t
          in (ts['tiles'] as List? ?? const []).cast<Map<String, dynamic>>())
        if (t['animation'] != null)
          t['id'] as int: (t['animation'] as List)
              .cast<Map<String, dynamic>>()
              .map((f) {
                return TiledAnimFrame(
                  f['tileid'] as int,
                  (f['duration'] as num).toInt(),
                );
              })
              .toList(),
    };
    return TiledTileset(
      firstGid: ts['firstgid'] as int,
      tileWidth: ts['tilewidth'] as int,
      tileHeight: ts['tileheight'] as int,
      columns: ts['columns'] as int,
      tileCount: ts['tilecount'] as int,
      margin: (ts['margin'] as int?) ?? 0,
      spacing: (ts['spacing'] as int?) ?? 0,
      image: image,
      animations: animations,
    );
  }

  // Tileset rời (.tsx do Tiled xuất) là XML — không xuất hiện trong .tmj JSON
  // nên phải tự load + parse. Bọc toàn bộ trong try/catch: thiếu file, file
  // hỏng/không phải XML hợp lệ, hay thiếu ảnh đều chỉ bỏ qua đúng tileset đó
  // (log lý do) thay vì làm sập cả bản đồ — các gid thuộc range của nó sẽ vẽ
  // ra rỗng.
  static Future<TiledTileset?> _loadExternalTileset(
    String tsxPath,
    int firstGid,
  ) async {
    try {
      final raw = await rootBundle.loadString(tsxPath);
      final root = XmlDocument.parse(raw).rootElement;
      final baseDir = tsxPath.substring(0, tsxPath.lastIndexOf('/') + 1);
      final image = await _loadImage(
        '$baseDir${root.getElement('image')!.getAttribute('source')}',
      );

      final animations = <int, List<TiledAnimFrame>>{
        for (final tile in root.findElements('tile'))
          if (tile.getElement('animation') != null)
            int.parse(tile.getAttribute('id')!): tile
                .getElement('animation')!
                .findElements('frame')
                .map((f) {
                  return TiledAnimFrame(
                    int.parse(f.getAttribute('tileid')!),
                    int.parse(f.getAttribute('duration')!),
                  );
                })
                .toList(),
      };

      return TiledTileset(
        firstGid: firstGid,
        tileWidth: int.parse(root.getAttribute('tilewidth')!),
        tileHeight: int.parse(root.getAttribute('tileheight')!),
        columns: int.parse(root.getAttribute('columns')!),
        tileCount: int.parse(root.getAttribute('tilecount')!),
        image: image,
        animations: animations,
      );
    } catch (e) {
      Logger().d(
        '[TiledMap] Không load được tileset rời "$tsxPath" ($e) — các gid từ $firstGid sẽ bị bỏ qua khi vẽ.',
      );
      return null;
    }
  }

  static Future<ui.Image> _loadImage(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
