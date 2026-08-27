import 'dart:math' show min;

/// Returns the effective logical-pixel speed for a scrolling danmaku.
double calculateScrollSpeed({
  required double viewportWidth,
  required double itemWidth,
  required double durationInMilliseconds,
  required double maxScrollSpeed,
  required double maxScrollDistancePerFrame,
  required double displayRefreshRate,
  required double devicePixelRatio,
}) {
  final distance = viewportWidth + itemWidth;
  final intendedSpeed = distance * 1000 / durationInMilliseconds;
  final smoothSpeed =
      maxScrollDistancePerFrame * displayRefreshRate / devicePixelRatio;

  return min(intendedSpeed, min(maxScrollSpeed, smoothSpeed));
}
