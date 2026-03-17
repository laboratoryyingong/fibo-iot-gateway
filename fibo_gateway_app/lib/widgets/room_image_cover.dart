import 'package:flutter/material.dart';

class RoomImageCover extends StatelessWidget {
  const RoomImageCover({
    super.key,
    required this.imageUrl,
    required this.borderRadius,
    required this.backgroundGradient,
    required this.overlayGradient,
    required this.placeholderIconColor,
    this.placeholderIconSize = 30,
  });

  final String? imageUrl;
  final BorderRadius borderRadius;
  final Gradient backgroundGradient;
  final Gradient overlayGradient;
  final Color placeholderIconColor;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    final source = imageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(gradient: backgroundGradient)),
          if (source != null)
            source.startsWith('http')
                ? Image.network(
                    source,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _RoomImagePlaceholder(
                        iconColor: placeholderIconColor,
                        iconSize: placeholderIconSize,
                      );
                    },
                    errorBuilder: (_, error, stackTrace) =>
                        _RoomImagePlaceholder(
                          iconColor: placeholderIconColor,
                          iconSize: placeholderIconSize,
                        ),
                  )
                : Image.asset(
                    source,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) =>
                        _RoomImagePlaceholder(
                          iconColor: placeholderIconColor,
                          iconSize: placeholderIconSize,
                        ),
                  )
          else
            _RoomImagePlaceholder(
              iconColor: placeholderIconColor,
              iconSize: placeholderIconSize,
            ),
          DecoratedBox(decoration: BoxDecoration(gradient: overlayGradient)),
        ],
      ),
    );
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder({
    required this.iconColor,
    required this.iconSize,
  });

  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.image_outlined, color: iconColor, size: iconSize),
    );
  }
}
