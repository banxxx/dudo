class PageCurlQuality {
  const PageCurlQuality({
    required this.stripCount,
    required this.pixelRatioCap,
  });

  static const low = PageCurlQuality(
    stripCount: 32,
    pixelRatioCap: 1.25,
  );

  static const normal = PageCurlQuality(
    stripCount: 56,
    pixelRatioCap: 1.5,
  );

  static const high = PageCurlQuality(
    stripCount: 88,
    pixelRatioCap: 2.0,
  );

  final int stripCount;
  final double pixelRatioCap;

  double cappedPixelRatio(double devicePixelRatio) {
    return devicePixelRatio.clamp(1.0, pixelRatioCap).toDouble();
  }
}
