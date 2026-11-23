import 'dart:typed_data';

import 'package:core/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

class ArtworkCache {
  ArtworkCache(this.fetch);

  final Future<Uint8List?> Function(Uri) fetch;
  final _images = <Uri, Future<MemoryImage?>>{};
  final _palette = <(MemoryImage, Brightness), Future<ColorScheme?>>{};
  var _active = 0;
  var _epoch = 0;

  Future<MemoryImage?> image(Uri uri) {
    final existing = _images.remove(uri);
    if (existing != null) {
      _images[uri] = existing;
      return existing;
    }
    final epoch = _epoch;
    final fresh = Future<MemoryImage?>(() async {
      final data = await _fetchBounded(uri, epoch);
      return data == null ? null : MemoryImage(data);
    });
    if (_images.length >= 12) _images.remove(_images.keys.first);
    _images[uri] = fresh;
    return fresh;
  }

  Future<Uint8List?> _fetchBounded(Uri uri, int epoch) async {
    if (epoch != _epoch) return null;
    while (_active >= 2) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (epoch != _epoch || !_images.containsKey(uri)) return null;
    }
    _active++;
    try {
      return await fetch(uri);
    } finally {
      _active--;
    }
  }

  Future<ColorScheme?> palette(MemoryImage image, Brightness brightness) {
    final key = (image, brightness);
    final existing = _palette.remove(key);
    if (existing != null) {
      _palette[key] = existing;
      return existing;
    }
    if (_palette.length >= 6) _palette.remove(_palette.keys.first);
    return _palette[key] = ColorScheme.fromImageProvider(
      provider: ResizeImage(
        image,
        width: 64,
        height: 64,
        policy: ResizeImagePolicy.fit,
      ),
      brightness: brightness,
    ).then<ColorScheme?>((value) => value, onError: (Object _) => null);
  }

  void clear() {
    _epoch++;
    _images.clear();
    _palette.clear();
    PaintingBinding.instance.imageCache.clear();
  }

  int get count => _images.length;
}

class CoverImage extends StatefulWidget {
  const CoverImage({
    super.key,
    required this.cache,
    required this.url,
    required this.pixels,
    this.icon = Icons.music_note,
    this.loaded,
    this.radius = AppRadius.xl,
    this.featured = false,
  });

  final ArtworkCache cache;
  final Uri? url;
  final int pixels;
  final IconData icon;
  final BorderRadius radius;
  final bool featured;
  final ValueChanged<MemoryImage?>? loaded;

  @override
  State<CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<CoverImage> {
  Future<MemoryImage?>? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.cache != widget.cache) _load();
  }

  void _load() {
    final url = widget.url;
    final image = _image = url == null ? null : widget.cache.image(url);
    if (image != null) {
      image.then((value) {
        if (mounted && identical(image, _image)) widget.loaded?.call(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        gradient: widget.featured
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.secondaryContainer,
                  scheme.surfaceContainerHigh,
                ],
              )
            : null,
      ),
      child: Center(
        child: Icon(
          widget.icon,
          color: scheme.onSurfaceVariant,
          size: widget.featured ? 64 : null,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: widget.radius,
      child: SizedBox.expand(
        child: FutureBuilder<MemoryImage?>(
          future: _image,
          builder: (_, snapshot) {
            final image = snapshot.connectionState == ConnectionState.done
                ? snapshot.data
                : null;
            return image == null
                ? placeholder
                : Image(
                    image: ResizeImage(
                      image,
                      width: widget.pixels,
                      height: widget.pixels,
                      policy: ResizeImagePolicy.fit,
                    ),
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => placeholder,
                  );
          },
        ),
      ),
    );
  }
}
