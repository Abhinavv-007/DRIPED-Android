import 'package:hive/hive.dart';

class CustomBrandLogoStore {
  CustomBrandLogoStore._();

  static const _logosKey = 'custom_service_logos';
  static const _websitesKey = 'custom_service_websites';
  static const _logoDevToken = 'pk_MzFReKrGRoWiBo5kzYrKKA';

  static Box get _box => Hive.box('driped_cache');

  static String? logoUrlForSlug(String slug) {
    final logos = _box.get(_logosKey);
    if (logos is! Map) return null;
    return logos[_normalizeSlug(slug)] as String?;
  }

  static String? websiteForSlug(String slug) {
    final websites = _box.get(_websitesKey);
    if (websites is! Map) return null;
    return websites[_normalizeSlug(slug)] as String?;
  }

  static Future<void> saveForSlug({
    required String slug,
    required String websiteUrl,
    required String logoUrl,
  }) async {
    final normalizedSlug = _normalizeSlug(slug);
    final logoMap = Map<String, dynamic>.from(
      (_box.get(_logosKey) as Map?) ?? const {},
    );
    final websiteMap = Map<String, dynamic>.from(
      (_box.get(_websitesKey) as Map?) ?? const {},
    );
    logoMap[normalizedSlug] = logoUrl;
    websiteMap[normalizedSlug] = websiteUrl;
    await _box.put(_logosKey, logoMap);
    await _box.put(_websitesKey, websiteMap);
  }

  static Future<void> clearForSlug(String slug) async {
    final normalizedSlug = _normalizeSlug(slug);
    final logoMap = Map<String, dynamic>.from(
      (_box.get(_logosKey) as Map?) ?? const {},
    );
    final websiteMap = Map<String, dynamic>.from(
      (_box.get(_websitesKey) as Map?) ?? const {},
    );
    logoMap.remove(normalizedSlug);
    websiteMap.remove(normalizedSlug);
    await _box.put(_logosKey, logoMap);
    await _box.put(_websitesKey, websiteMap);
  }

  static String? logoUrlForWebsite(String rawWebsiteUrl) {
    final host = hostFromWebsite(rawWebsiteUrl);
    if (host == null) return null;
    return 'https://img.logo.dev/$host?token=$_logoDevToken&format=webp&retina=true';
  }

  static String? hostFromWebsite(String rawWebsiteUrl) {
    final sanitized = sanitizeWebsiteUrl(rawWebsiteUrl);
    if (sanitized == null) return null;
    final uri = Uri.tryParse(sanitized);
    if (uri == null || uri.host.isEmpty) return null;
    final host = uri.host.toLowerCase();
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static String? sanitizeWebsiteUrl(String rawWebsiteUrl) {
    final trimmed = rawWebsiteUrl.trim();
    if (trimmed.isEmpty) return null;
    final direct = Uri.tryParse(trimmed);
    if (direct != null && direct.hasScheme && direct.host.isNotEmpty) {
      return direct.toString();
    }
    final withHttps = Uri.tryParse('https://$trimmed');
    if (withHttps != null && withHttps.host.isNotEmpty) {
      return withHttps.toString();
    }
    return null;
  }

  static String slugFromNameOrWebsite({
    required String name,
    required String websiteUrl,
  }) {
    final host = hostFromWebsite(websiteUrl);
    if (host != null) {
      final parts = host.split('.');
      if (parts.length >= 3 &&
          parts.last.length == 2 &&
          parts[parts.length - 2].length <= 3) {
        return _normalizeSlug(parts[parts.length - 3]);
      }
      if (parts.length >= 2) {
        return _normalizeSlug(parts[parts.length - 2]);
      }
      return _normalizeSlug(parts.first);
    }
    return _normalizeSlug(name);
  }

  static String _normalizeSlug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('+', 'plus')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
