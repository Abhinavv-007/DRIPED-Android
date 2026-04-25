import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/payment_method.dart';

class BrandAssetResolver {
  BrandAssetResolver._();

  static const _assetRoot = 'assets/icons';
  static const _supportedExtensions = ['svg', 'webp', 'png', 'jpg', 'jpeg'];
  static Set<String>? _assetManifestCache;
  static Future<Set<String>>? _assetManifestFuture;
  static final Map<String, Future<String?>> _resolvedPathCache = {};

  static Future<void> preload() async {
    await _loadAssetManifest();
  }

  static final Map<String, List<String>> _serviceAliases = {
    'amazonprime': ['amazonprime', 'primevideo', 'amazon'],
    'disneyhotstar': ['disneyplushotstar', 'hotstar'],
    'disneyplushotstar': ['hotstar'],
    'youtubepremium': ['youtube'],
    'youtubemusic': ['youtube', 'youtubemusic'],
    'appletv': ['appletv', 'apple'],
    'applemusic': ['applemusic', 'apple'],
    'applearcade': ['applearcade', 'apple'],
    'googleone': ['googleone', 'google'],
    'microsoft365': ['microsoft365', 'office365', 'microsoft'],
    'office365': ['microsoft365', 'microsoft'],
    'googleworkspace': ['googleworkspace', 'google'],
    'githubpro': ['github'],
    'playstationplus': ['playstation'],
    'xboxgamepass': ['xbox'],
    'swiggyone': ['swiggy'],
    'zomatogold': ['zomato'],
    'claudepro': ['claude', 'anthropic'],
    'geminiadvanced': ['googlegemini', 'google'],
    'uberone': ['uber'],
    'ubereatspass': ['ubereats', 'uber'],
    'discordnitro': ['discord'],
    'googleplay': ['g-play', 'googleplay', 'google'],
    'appleappstore': ['apple', 'appstore'],
    'duolingosuper': ['duolingo'],
    'courseraplus': ['coursera'],
    'udemyplan': ['udemy'],
    'replitcore': ['replit'],
    'netlify': ['netlify'],
    'cloudflare': ['cloudflare'],
    'perplexitypro': ['perplexity'],
    'soundcloudgo': ['soundcloud'],
    'applepodcasts': ['applepodcasts', 'apple'],
    'fitbitpremium': ['fitbit'],
    'alltrailsplus': ['alltrails'],
    'bigbasketbbstar': ['bigbasket'],
    'tripadvisorplus': ['tripadvisor'],
    'deliverooplus': ['deliveroo'],
  };

  static final Map<String, List<String>> _paymentAliases = {
    'creditcard': ['creditcard'],
    'debitcard': ['debitcard'],
    'upi': ['upi'],
    'gpay': ['googlepay'],
    'googlepay': ['googlepay'],
    'phonepe': ['phonepe'],
    'paytm': ['paytm'],
    'paypal': ['paypal'],
    'amazonpay': ['amazonpay'],
    'cashapp': ['cashapp'],
    'venmo': ['venmo'],
    'wise': ['wise'],
    'payoneer': ['payoneer'],
    'revolut': ['revolut'],
    'stripe': ['stripe'],
    'binance': ['binance'],
    'binancepay': ['binance'],
    'crypto': ['btc', 'binance'],
    'bitcoin': ['btc'],
    'btc': ['btc'],
    'rupay': ['rupay'],
    'discover': ['discover'],
    'dinersclub': ['dinersclub'],
    'diners': ['dinersclub'],
    'maestro': ['maestro'],
    'visa': ['visa'],
    'mastercard': ['mastercard'],
    'americanexpress': ['americanexpress'],
    'amex': ['americanexpress'],
    'netbanking': ['banktransfer'],
    'banktransfer': ['banktransfer'],
    'wallet': ['wallet'],
    'axis': ['axisbank'],
    'axisbank': ['axisbank'],
    'hdfc': ['hdfcbank'],
    'hdfcbank': ['hdfcbank'],
    'icici': ['icicibank'],
    'icicibank': ['icicibank'],
    'airtel': ['airtel'],
    'jio': ['jio'],
    'sbi': ['sbi'],
    'idfcfirst': ['idfcfirst'],
    'applepay': ['applepay'],
    'samsungpay': ['samsungpay'],
    'bankofamerica': ['bankofamerica'],
    'barclays': ['barclays'],
  };

  /// Reverse alias map built lazily from `_serviceAliases`. Whenever the
  /// canonical-slug map says e.g. `discordnitro: [discord]`, every short form
  /// (`discord`) gets pointed back at its canonical asset (`discordnitro`)
  /// so that subscriptions stored as `service_slug = "discord"` (because the
  /// scanner returned the short form) still resolve to `discordnitro.webp`.
  static late final Map<String, String> _shortToCanonical = (() {
    final out = <String, String>{};
    for (final entry in _serviceAliases.entries) {
      for (final shortForm in entry.value) {
        // Only register the reverse if it isn't already a canonical entry —
        // otherwise we'd shadow real canonical assets like `apple` (legitimate
        // Apple icon file) with whatever first canonical claimed `apple` as
        // a fallback (`applemusic`, `appletv`, `applepay`, …).
        out.putIfAbsent(shortForm, () => entry.key);
      }
    }
    return out;
  })();

  static Future<String?> serviceAsset({
    required String serviceSlug,
    required String serviceName,
  }) {
    final normalizedSlug = _normalize(serviceSlug);
    final normalizedName = _normalize(serviceName);
    final canonicalFromSlug = _shortToCanonical[normalizedSlug];
    final canonicalFromName = _shortToCanonical[normalizedName];
    final candidates = _dedupe([
      normalizedSlug,
      // Canonical asset filename for this short form (discord → discordnitro).
      // Tried before the short form so we don't trip on a stray test asset
      // named after the short form when the real branded one exists.
      if (canonicalFromSlug != null) canonicalFromSlug,
      ..._expandAliases(normalizedSlug, _serviceAliases),
      normalizedName,
      if (canonicalFromName != null) canonicalFromName,
      ..._expandAliases(normalizedName, _serviceAliases),
      ..._normalizedWords(serviceName),
      ..._normalizedWords(serviceSlug),
    ]);
    return _resolve('service:$normalizedSlug:$normalizedName', candidates);
  }

  static Future<String?> paymentAsset({
    String? iconSlug,
    required PaymentMethodType type,
    required String name,
  }) {
    final suggested = suggestPaymentIconSlug(
      iconSlug: iconSlug,
      type: type,
      name: name,
    );
    final normalizedName = _normalize(name);
    final candidates = _dedupe([
      if (suggested != null) suggested,
      normalizedName,
      ..._expandAliases(normalizedName, _paymentAliases),
      ..._normalizedWords(name)
          .expand((word) => [word, ..._expandAliases(word, _paymentAliases)]),
      switch (type) {
        PaymentMethodType.creditCard => 'creditcard',
        PaymentMethodType.debitCard => 'debitcard',
        PaymentMethodType.gpay => 'googlepay',
        PaymentMethodType.phonepe => 'phonepe',
        PaymentMethodType.paytm => 'paytm',
        PaymentMethodType.paypal => 'paypal',
        PaymentMethodType.upi => 'upi',
        PaymentMethodType.netBanking => 'banktransfer',
        PaymentMethodType.other => 'wallet',
      },
    ]);
    return _resolve(
      'payment:${iconSlug ?? ''}:$normalizedName:${type.name}',
      candidates.where((candidate) => candidate.isNotEmpty).toList(),
    );
  }

  static String? suggestPaymentIconSlug({
    String? iconSlug,
    required PaymentMethodType type,
    required String name,
  }) {
    final normalizedIconSlug = _normalize(iconSlug ?? '');
    if (normalizedIconSlug.isNotEmpty) {
      final aliases = _expandAliases(normalizedIconSlug, _paymentAliases);
      return aliases.isNotEmpty ? aliases.first : normalizedIconSlug;
    }

    final normalizedName = _normalize(name);
    for (final entry in _paymentAliases.entries) {
      if (normalizedName.contains(entry.key)) return entry.value.first;
    }

    return switch (type) {
      PaymentMethodType.creditCard => 'creditcard',
      PaymentMethodType.debitCard => 'debitcard',
      PaymentMethodType.gpay => 'googlepay',
      PaymentMethodType.phonepe => 'phonepe',
      PaymentMethodType.paytm => 'paytm',
      PaymentMethodType.paypal => 'paypal',
      PaymentMethodType.upi => 'upi',
      PaymentMethodType.netBanking => 'banktransfer',
      PaymentMethodType.other => 'wallet',
    };
  }

  static Future<String?> _resolve(String cacheKey, List<String> candidates) {
    final cachedManifest = _assetManifestCache;
    if (cachedManifest != null) {
      return SynchronousFuture(_firstMatch(cachedManifest, candidates));
    }

    return _resolvedPathCache.putIfAbsent(cacheKey, () async {
      final manifest = await _loadAssetManifest();
      return _firstMatch(manifest, candidates);
    });
  }

  static Future<Set<String>> _loadAssetManifest() {
    final cachedManifest = _assetManifestCache;
    if (cachedManifest != null) {
      return SynchronousFuture(cachedManifest);
    }

    return _assetManifestFuture ??= () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest
          .listAssets()
          .where(
            (asset) =>
                asset.startsWith('$_assetRoot/') &&
                _supportedExtensions.any(asset.endsWith),
          )
          .toSet();
      _assetManifestCache = assets;
      return assets;
    }();
  }

  static String? _firstMatch(Set<String> manifest, List<String> candidates) {
    for (final candidate in candidates) {
      for (final ext in _supportedExtensions) {
        final path = '$_assetRoot/$candidate.$ext';
        if (manifest.contains(path)) return path;
      }
    }
    return null;
  }

  static bool isSvgAsset(String assetPath) {
    return assetPath.toLowerCase().endsWith('.svg');
  }

  static List<String> _expandAliases(
    String key,
    Map<String, List<String>> aliases,
  ) {
    return aliases[_normalize(key)] ?? const [];
  }

  static List<String> _normalizedWords(String value) {
    return value
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .map(_normalize)
        .where((word) => word.length >= 3)
        .toList();
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('+', 'plus')
        .replaceAll('@', 'at')
        .replaceAll('.', 'dot')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static List<String> _dedupe(List<String> values) {
    final unique = <String>{};
    final ordered = <String>[];
    for (final value in values) {
      if (value.isEmpty || !unique.add(value)) continue;
      ordered.add(value);
    }
    return ordered;
  }
}
