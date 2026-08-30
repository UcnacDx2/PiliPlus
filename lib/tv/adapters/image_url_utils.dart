abstract final class ImageUrlUtils {
  static String getResizedUrl(String url, {int? width, int? height}) {
    if (url.startsWith('//')) return 'https:$url';
    return url;
  }
}
