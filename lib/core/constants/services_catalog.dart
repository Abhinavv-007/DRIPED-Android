import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/billing_cycle.dart';

/// A known service the scanner + picker recognises.
/// Phase-A: slug / name / category / brand colour / icon for UI rendering.
/// Phase-D: fills senderDomains, subjectKeywords, amountPatterns,
/// datePatterns, cycleKeywords, isTrial().
class ServicePattern {
  final String slug;
  final String name;
  final String categorySlug;
  final Color brandColour;
  final IconData fallbackIcon;

  final List<String> senderDomains;
  final List<String> subjectKeywords;
  final List<RegExp> amountPatterns;
  final List<RegExp> datePatterns;
  final Map<String, BillingCycle> cycleKeywords;
  final bool Function(String body)? isTrial;

  const ServicePattern({
    required this.slug,
    required this.name,
    required this.categorySlug,
    required this.brandColour,
    this.fallbackIcon = LucideIcons.package,
    this.senderDomains = const [],
    this.subjectKeywords = const [],
    this.amountPatterns = const [],
    this.datePatterns = const [],
    this.cycleKeywords = const {},
    this.isTrial,
  });
}

/// The catalogue. Keyed by slug.
class ServicesCatalog {
  ServicesCatalog._();

  static final Map<String, ServicePattern> patterns = {
    for (final p in _all) p.slug: p,
  };

  static List<ServicePattern> all() => List.unmodifiable(_all);

  static ServicePattern? bySlug(String slug) => patterns[slug];

  static ServicePattern fallback(String name) {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return ServicePattern(
      slug: slug,
      name: name,
      categorySlug: 'other',
      brandColour: const Color(0xFF64748B),
      fallbackIcon: LucideIcons.package,
    );
  }

  static final List<ServicePattern> _all = [
    // ── streaming ──
    ServicePattern(
      slug: 'netflix',
      name: 'Netflix',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFFE50914),
      fallbackIcon: LucideIcons.film,
      senderDomains: const ['netflix.com', 'members.netflix.com'],
      subjectKeywords: const ['payment', 'membership', 'receipt'],
    ),
    ServicePattern(
      slug: 'amazon_prime',
      name: 'Amazon Prime',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF00A8E1),
      fallbackIcon: LucideIcons.video,
      senderDomains: const ['amazon.in', 'amazon.com', 'primevideo.com'],
      subjectKeywords: const ['prime membership', 'renewal'],
    ),
    ServicePattern(
      slug: 'disney_hotstar',
      name: 'Disney+ Hotstar',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF1F80E0),
      fallbackIcon: LucideIcons.star,
      senderDomains: const ['hotstar.com', 'disneyplushotstar.com'],
      subjectKeywords: const ['subscription', 'renewal'],
    ),
    ServicePattern(
      slug: 'youtube_premium',
      name: 'YouTube Premium',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFFFF0000),
      fallbackIcon: LucideIcons.youtube,
      senderDomains: const ['youtube.com', 'google.com'],
      subjectKeywords: const ['youtube premium', 'receipt'],
    ),
    ServicePattern(
      slug: 'apple_tv',
      name: 'Apple TV+',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF000000),
      fallbackIcon: LucideIcons.apple,
      senderDomains: const ['apple.com'],
      subjectKeywords: const ['apple tv', 'receipt'],
    ),
    ServicePattern(
      slug: 'zee5',
      name: 'Zee5',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF8230C9),
      fallbackIcon: LucideIcons.tv2,
      senderDomains: const ['zee5.com'],
      subjectKeywords: const ['zee5', 'subscription'],
    ),
    ServicePattern(
      slug: 'sonyliv',
      name: 'SonyLIV',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFFE00E63),
      fallbackIcon: LucideIcons.tv,
      senderDomains: const ['sonyliv.com'],
      subjectKeywords: const ['sonyliv', 'premium'],
    ),

    // ── music ──
    ServicePattern(
      slug: 'spotify',
      name: 'Spotify',
      categorySlug: 'music',
      brandColour: const Color(0xFF1DB954),
      fallbackIcon: LucideIcons.music,
      senderDomains: const ['spotify.com'],
      subjectKeywords: const ['premium', 'receipt', 'invoice'],
    ),
    ServicePattern(
      slug: 'apple_music',
      name: 'Apple Music',
      categorySlug: 'music',
      brandColour: const Color(0xFFFC3C44),
      fallbackIcon: LucideIcons.music2,
      senderDomains: const ['apple.com'],
      subjectKeywords: const ['apple music'],
    ),
    ServicePattern(
      slug: 'youtube_music',
      name: 'YouTube Music',
      categorySlug: 'music',
      brandColour: const Color(0xFFFF0000),
      fallbackIcon: LucideIcons.music4,
      senderDomains: const ['youtube.com', 'google.com'],
      subjectKeywords: const ['youtube music'],
    ),
    ServicePattern(
      slug: 'amazon_music',
      name: 'Amazon Music',
      categorySlug: 'music',
      brandColour: const Color(0xFF00A8E1),
      fallbackIcon: LucideIcons.music2,
      senderDomains: const ['amazon.in', 'amazon.com'],
      subjectKeywords: const ['amazon music unlimited'],
    ),
    ServicePattern(
      slug: 'gaana',
      name: 'Gaana+',
      categorySlug: 'music',
      brandColour: const Color(0xFFE72C30),
      fallbackIcon: LucideIcons.music3,
      senderDomains: const ['gaana.com'],
      subjectKeywords: const ['gaana', 'subscription'],
    ),
    ServicePattern(
      slug: 'jiosaavn',
      name: 'JioSaavn',
      categorySlug: 'music',
      brandColour: const Color(0xFF2BC5B4),
      fallbackIcon: LucideIcons.music,
      senderDomains: const ['jiosaavn.com'],
      subjectKeywords: const ['jiosaavn pro'],
    ),

    // ── productivity ──
    ServicePattern(
      slug: 'notion',
      name: 'Notion',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF191919),
      fallbackIcon: LucideIcons.bookOpen,
      senderDomains: const ['notion.so'],
      subjectKeywords: const ['notion', 'receipt', 'invoice'],
    ),
    ServicePattern(
      slug: 'slack',
      name: 'Slack',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF4A154B),
      fallbackIcon: LucideIcons.hash,
      senderDomains: const ['slack.com'],
      subjectKeywords: const ['slack invoice', 'receipt'],
    ),
    ServicePattern(
      slug: 'microsoft_365',
      name: 'Microsoft 365',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF00A4EF),
      fallbackIcon: LucideIcons.briefcase,
      senderDomains: const ['microsoft.com'],
      subjectKeywords: const ['microsoft 365', 'office subscription'],
    ),
    ServicePattern(
      slug: 'google_one',
      name: 'Google One',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF4285F4),
      fallbackIcon: LucideIcons.cloud,
      senderDomains: const ['google.com'],
      subjectKeywords: const ['google one', 'google storage'],
    ),
    ServicePattern(
      slug: 'google_workspace',
      name: 'Google Workspace',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFEA4335),
      fallbackIcon: LucideIcons.grid,
      senderDomains: const ['google.com'],
      subjectKeywords: const ['google workspace'],
    ),
    ServicePattern(
      slug: 'dropbox',
      name: 'Dropbox',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF0061FF),
      fallbackIcon: LucideIcons.box,
      senderDomains: const ['dropbox.com'],
      subjectKeywords: const ['dropbox plus', 'receipt'],
    ),
    ServicePattern(
      slug: 'zoom',
      name: 'Zoom',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF2D8CFF),
      fallbackIcon: LucideIcons.video,
      senderDomains: const ['zoom.us'],
      subjectKeywords: const ['zoom subscription', 'invoice'],
    ),
    ServicePattern(
      slug: 'canva',
      name: 'Canva Pro',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF00C4CC),
      fallbackIcon: LucideIcons.palette,
      senderDomains: const ['canva.com'],
      subjectKeywords: const ['canva pro', 'receipt'],
    ),
    ServicePattern(
      slug: 'adobe_cc',
      name: 'Adobe Creative Cloud',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFFF0000),
      fallbackIcon: LucideIcons.layers,
      senderDomains: const ['adobe.com'],
      subjectKeywords: const ['adobe creative cloud', 'receipt'],
    ),
    ServicePattern(
      slug: 'figma',
      name: 'Figma',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFF24E1E),
      fallbackIcon: LucideIcons.figma,
      senderDomains: const ['figma.com'],
      subjectKeywords: const ['figma', 'receipt'],
    ),

    // ── development ──
    ServicePattern(
      slug: 'github_pro',
      name: 'GitHub Pro',
      categorySlug: 'development',
      brandColour: const Color(0xFF24292E),
      fallbackIcon: LucideIcons.github,
      senderDomains: const ['github.com'],
      subjectKeywords: const ['github', 'invoice'],
    ),
    ServicePattern(
      slug: 'vercel',
      name: 'Vercel',
      categorySlug: 'development',
      brandColour: const Color(0xFF000000),
      fallbackIcon: LucideIcons.triangle,
      senderDomains: const ['vercel.com'],
      subjectKeywords: const ['vercel', 'invoice'],
    ),
    ServicePattern(
      slug: 'chatgpt_plus',
      name: 'ChatGPT Plus',
      categorySlug: 'development',
      brandColour: const Color(0xFF10A37F),
      fallbackIcon: LucideIcons.bot,
      senderDomains: const ['openai.com'],
      subjectKeywords: const ['chatgpt plus', 'openai', 'receipt'],
    ),
    ServicePattern(
      slug: 'digitalocean',
      name: 'DigitalOcean',
      categorySlug: 'development',
      brandColour: const Color(0xFF0080FF),
      fallbackIcon: LucideIcons.droplet,
      senderDomains: const ['digitalocean.com'],
      subjectKeywords: const ['digitalocean invoice'],
    ),
    ServicePattern(
      slug: 'supabase',
      name: 'Supabase Pro',
      categorySlug: 'development',
      brandColour: const Color(0xFF3ECF8E),
      fallbackIcon: LucideIcons.database,
      senderDomains: const ['supabase.com', 'supabase.io'],
      subjectKeywords: const ['supabase', 'invoice'],
    ),

    // ── gaming ──
    ServicePattern(
      slug: 'xbox_game_pass',
      name: 'Xbox Game Pass',
      categorySlug: 'gaming',
      brandColour: const Color(0xFF107C10),
      fallbackIcon: LucideIcons.gamepad2,
      senderDomains: const ['microsoft.com', 'xbox.com'],
      subjectKeywords: const ['game pass', 'xbox subscription'],
    ),
    ServicePattern(
      slug: 'playstation_plus',
      name: 'PlayStation Plus',
      categorySlug: 'gaming',
      brandColour: const Color(0xFF003791),
      fallbackIcon: LucideIcons.gamepad,
      senderDomains: const ['playstation.com', 'sony.com'],
      subjectKeywords: const ['playstation plus', 'receipt'],
    ),

    // ── indian lifestyle ──
    ServicePattern(
      slug: 'swiggy_one',
      name: 'Swiggy One',
      categorySlug: 'shopping',
      brandColour: const Color(0xFFFC8019),
      fallbackIcon: LucideIcons.utensils,
      senderDomains: const ['swiggy.in'],
      subjectKeywords: const ['swiggy one', 'membership'],
    ),
    ServicePattern(
      slug: 'zomato_gold',
      name: 'Zomato Gold',
      categorySlug: 'shopping',
      brandColour: const Color(0xFFCB202D),
      fallbackIcon: LucideIcons.utensils,
      senderDomains: const ['zomato.com'],
      subjectKeywords: const ['zomato gold', 'membership'],
    ),
    ServicePattern(
      slug: 'cultfit',
      name: 'Cult.fit',
      categorySlug: 'health_fitness',
      brandColour: const Color(0xFFFE5000),
      fallbackIcon: LucideIcons.dumbbell,
      senderDomains: const ['cult.fit', 'cure.fit'],
      subjectKeywords: const ['cult.fit', 'membership'],
    ),
    ServicePattern(
      slug: 'times_prime',
      name: 'Times Prime',
      categorySlug: 'shopping',
      brandColour: const Color(0xFFC72026),
      fallbackIcon: LucideIcons.crown,
      senderDomains: const ['timesprime.com'],
      subjectKeywords: const ['times prime', 'membership'],
    ),
    ServicePattern(
      slug: 'healthifyme',
      name: 'HealthifyMe',
      categorySlug: 'health_fitness',
      brandColour: const Color(0xFF1AAE88),
      fallbackIcon: LucideIcons.apple,
      senderDomains: const ['healthifyme.com'],
      subjectKeywords: const ['healthifyme', 'subscription'],
    ),
    ServicePattern(
      slug: 'kindle_unlimited',
      name: 'Kindle Unlimited',
      categorySlug: 'education',
      brandColour: const Color(0xFF00A8E1),
      fallbackIcon: LucideIcons.bookOpen,
      senderDomains: const ['amazon.in', 'amazon.com'],
      subjectKeywords: const ['kindle unlimited', 'membership'],
    ),

    // ── health ──
    ServicePattern(
      slug: 'headspace',
      name: 'Headspace',
      categorySlug: 'health_fitness',
      brandColour: const Color(0xFFF47E42),
      fallbackIcon: LucideIcons.brain,
      senderDomains: const ['headspace.com'],
      subjectKeywords: const ['headspace', 'subscription'],
    ),
    ServicePattern(
      slug: 'calm',
      name: 'Calm',
      categorySlug: 'health_fitness',
      brandColour: const Color(0xFF2962D9),
      fallbackIcon: LucideIcons.moon,
      senderDomains: const ['calm.com'],
      subjectKeywords: const ['calm', 'subscription'],
    ),

    // ── news ──
    ServicePattern(
      slug: 'medium',
      name: 'Medium',
      categorySlug: 'news',
      brandColour: const Color(0xFF000000),
      fallbackIcon: LucideIcons.fileText,
      senderDomains: const ['medium.com'],
      subjectKeywords: const ['medium membership', 'receipt'],
    ),
    ServicePattern(
      slug: 'claude_pro',
      name: 'Claude Pro',
      categorySlug: 'development',
      brandColour: const Color(0xFFD97706),
      fallbackIcon: LucideIcons.bot,
      senderDomains: const ['anthropic.com'],
      subjectKeywords: const ['claude', 'anthropic', 'subscription'],
    ),
    ServicePattern(
      slug: 'gemini_advanced',
      name: 'Gemini Advanced',
      categorySlug: 'development',
      brandColour: const Color(0xFF4285F4),
      fallbackIcon: LucideIcons.sparkles,
      senderDomains: const ['google.com'],
      subjectKeywords: const ['gemini', 'google one ai premium'],
    ),
    ServicePattern(
      slug: 'airtel',
      name: 'Airtel',
      categorySlug: 'utilities',
      brandColour: const Color(0xFFE40000),
      fallbackIcon: LucideIcons.smartphone,
      senderDomains: const ['airtel.com'],
      subjectKeywords: const ['airtel', 'recharge', 'bill payment'],
    ),
    ServicePattern(
      slug: 'jio',
      name: 'Jio',
      categorySlug: 'utilities',
      brandColour: const Color(0xFF0F3CC9),
      fallbackIcon: LucideIcons.smartphone,
      senderDomains: const ['jio.com'],
      subjectKeywords: const ['jio', 'recharge', 'bill payment'],
    ),
    ServicePattern(
      slug: 'apple_arcade',
      name: 'Apple Arcade',
      categorySlug: 'gaming',
      brandColour: const Color(0xFF6E6E73),
      fallbackIcon: LucideIcons.gamepad2,
      senderDomains: const ['apple.com'],
      subjectKeywords: const ['apple arcade', 'receipt'],
    ),
    ServicePattern(
      slug: 'uber_one',
      name: 'Uber One',
      categorySlug: 'shopping',
      brandColour: const Color(0xFF000000),
      fallbackIcon: LucideIcons.car,
      senderDomains: const ['uber.com'],
      subjectKeywords: const ['uber one', 'membership'],
    ),

    // ── AI ──
    ServicePattern(
      slug: 'perplexity_pro',
      name: 'Perplexity Pro',
      categorySlug: 'development',
      brandColour: const Color(0xFF1FB8CD),
      fallbackIcon: LucideIcons.search,
    ),

    // ── News / Content ──
    ServicePattern(
      slug: 'substack',
      name: 'Substack',
      categorySlug: 'news',
      brandColour: const Color(0xFFFF6719),
      fallbackIcon: LucideIcons.newspaper,
    ),

    // ── Streaming (extra) ──
    ServicePattern(
      slug: 'max',
      name: 'Max',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF002BE7),
      fallbackIcon: LucideIcons.tv,
    ),
    ServicePattern(
      slug: 'hulu',
      name: 'Hulu',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF1CE783),
      fallbackIcon: LucideIcons.tv2,
    ),
    ServicePattern(
      slug: 'crunchyroll',
      name: 'Crunchyroll',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFFF47521),
      fallbackIcon: LucideIcons.tv,
    ),
    ServicePattern(
      slug: 'paramount_plus',
      name: 'Paramount+',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF0064FF),
      fallbackIcon: LucideIcons.star,
    ),
    ServicePattern(
      slug: 'peacock',
      name: 'Peacock',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF000000),
      fallbackIcon: LucideIcons.feather,
    ),
    ServicePattern(
      slug: 'jiohotstar',
      name: 'JioHotstar',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF0C3B72),
      fallbackIcon: LucideIcons.star,
    ),

    // ── Music (extra) ──
    ServicePattern(
      slug: 'tidal',
      name: 'Tidal',
      categorySlug: 'music',
      brandColour: const Color(0xFF000000),
      fallbackIcon: LucideIcons.music,
    ),
    ServicePattern(
      slug: 'deezer',
      name: 'Deezer',
      categorySlug: 'music',
      brandColour: const Color(0xFFA238FF),
      fallbackIcon: LucideIcons.music3,
    ),
    ServicePattern(
      slug: 'soundcloud_go',
      name: 'SoundCloud Go+',
      categorySlug: 'music',
      brandColour: const Color(0xFFFF5500),
      fallbackIcon: LucideIcons.cloudSun,
    ),
    ServicePattern(
      slug: 'audible',
      name: 'Audible',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFFF8991D),
      fallbackIcon: LucideIcons.headphones,
    ),
    ServicePattern(
      slug: 'apple_podcasts',
      name: 'Apple Podcasts',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF9933CC),
      fallbackIcon: LucideIcons.podcast,
    ),

    // ── Productivity (extra) ──
    ServicePattern(
      slug: 'grammarly',
      name: 'Grammarly',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF15C39A),
      fallbackIcon: LucideIcons.spellCheck,
    ),
    ServicePattern(
      slug: 'calendly',
      name: 'Calendly',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF006BFF),
      fallbackIcon: LucideIcons.calendarDays,
    ),
    ServicePattern(
      slug: 'clickup',
      name: 'ClickUp',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF7B68EE),
      fallbackIcon: LucideIcons.checkSquare,
    ),
    ServicePattern(
      slug: 'asana',
      name: 'Asana',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFF06A6A),
      fallbackIcon: LucideIcons.target,
    ),
    ServicePattern(
      slug: 'trello',
      name: 'Trello',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF0079BF),
      fallbackIcon: LucideIcons.columns,
    ),
    ServicePattern(
      slug: 'jira',
      name: 'Jira',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF0052CC),
      fallbackIcon: LucideIcons.bug,
    ),
    ServicePattern(
      slug: 'linear',
      name: 'Linear',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF5E6AD2),
      fallbackIcon: LucideIcons.layoutList,
    ),
    ServicePattern(
      slug: 'loom',
      name: 'Loom',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF625DF5),
      fallbackIcon: LucideIcons.video,
    ),
    ServicePattern(
      slug: 'miro',
      name: 'Miro',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFFFD02F),
      fallbackIcon: LucideIcons.penTool,
    ),
    ServicePattern(
      slug: 'todoist',
      name: 'Todoist',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFE44332),
      fallbackIcon: LucideIcons.checkCircle,
    ),
    ServicePattern(
      slug: 'evernote',
      name: 'Evernote',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF00A82D),
      fallbackIcon: LucideIcons.stickyNote,
    ),
    ServicePattern(
      slug: 'basecamp',
      name: 'Basecamp',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF1D2D35),
      fallbackIcon: LucideIcons.tent,
    ),
    ServicePattern(
      slug: 'box',
      name: 'Box',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF0061D5),
      fallbackIcon: LucideIcons.box,
    ),

    // ── Development (extra) ──
    ServicePattern(
      slug: 'replit_core',
      name: 'Replit Core',
      categorySlug: 'development',
      brandColour: const Color(0xFFF26207),
      fallbackIcon: LucideIcons.code2,
    ),
    ServicePattern(
      slug: 'render',
      name: 'Render',
      categorySlug: 'development',
      brandColour: const Color(0xFF46E3B7),
      fallbackIcon: LucideIcons.server,
    ),
    ServicePattern(
      slug: 'railway',
      name: 'Railway',
      categorySlug: 'development',
      brandColour: const Color(0xFF0B0D0E),
      fallbackIcon: LucideIcons.train,
    ),
    ServicePattern(
      slug: 'netlify',
      name: 'Netlify Pro',
      categorySlug: 'development',
      brandColour: const Color(0xFF00C7B7),
      fallbackIcon: LucideIcons.globe,
    ),
    ServicePattern(
      slug: 'cloudflare',
      name: 'Cloudflare Pro',
      categorySlug: 'development',
      brandColour: const Color(0xFFF38020),
      fallbackIcon: LucideIcons.shield,
    ),
    ServicePattern(
      slug: 'flydotio',
      name: 'Fly.io',
      categorySlug: 'development',
      brandColour: const Color(0xFF7B3BE2),
      fallbackIcon: LucideIcons.plane,
    ),
    ServicePattern(
      slug: 'stackblitz',
      name: 'StackBlitz',
      categorySlug: 'development',
      brandColour: const Color(0xFF1389FD),
      fallbackIcon: LucideIcons.zap,
    ),
    ServicePattern(
      slug: 'postman',
      name: 'Postman',
      categorySlug: 'development',
      brandColour: const Color(0xFFFF6C37),
      fallbackIcon: LucideIcons.send,
    ),

    // ── Security / Infra ──
    ServicePattern(
      slug: 'onepassword',
      name: '1Password',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF0572EC),
      fallbackIcon: LucideIcons.keyRound,
    ),
    ServicePattern(
      slug: 'bitwarden',
      name: 'Bitwarden',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF175DDC),
      fallbackIcon: LucideIcons.lock,
    ),
    ServicePattern(
      slug: 'proton',
      name: 'Proton',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF6D4AFF),
      fallbackIcon: LucideIcons.shield,
    ),
    ServicePattern(
      slug: 'okta',
      name: 'Okta',
      categorySlug: 'development',
      brandColour: const Color(0xFF007DC1),
      fallbackIcon: LucideIcons.shieldCheck,
    ),
    ServicePattern(
      slug: 'auth0',
      name: 'Auth0',
      categorySlug: 'development',
      brandColour: const Color(0xFFEB5424),
      fallbackIcon: LucideIcons.fingerprint,
    ),

    // ── Marketing / CRM ──
    ServicePattern(
      slug: 'mailchimp',
      name: 'Mailchimp',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFFFE01B),
      fallbackIcon: LucideIcons.mail,
    ),
    ServicePattern(
      slug: 'hubspot',
      name: 'HubSpot',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFFF7A59),
      fallbackIcon: LucideIcons.users,
    ),
    ServicePattern(
      slug: 'brevo',
      name: 'Brevo',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF0B996E),
      fallbackIcon: LucideIcons.mailPlus,
    ),
    ServicePattern(
      slug: 'intercom',
      name: 'Intercom',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF286EFA),
      fallbackIcon: LucideIcons.messageCircle,
    ),
    ServicePattern(
      slug: 'zendesk',
      name: 'Zendesk',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF03363D),
      fallbackIcon: LucideIcons.helpCircle,
    ),

    // ── Web / Hosting ──
    ServicePattern(
      slug: 'shopify',
      name: 'Shopify',
      categorySlug: 'development',
      brandColour: const Color(0xFF96BF48),
      fallbackIcon: LucideIcons.shoppingBag,
    ),
    ServicePattern(
      slug: 'godaddy',
      name: 'GoDaddy',
      categorySlug: 'development',
      brandColour: const Color(0xFF1BDBDB),
      fallbackIcon: LucideIcons.globe2,
    ),
    ServicePattern(
      slug: 'namecheap',
      name: 'Namecheap',
      categorySlug: 'development',
      brandColour: const Color(0xFFDE3723),
      fallbackIcon: LucideIcons.atSign,
    ),
    ServicePattern(
      slug: 'webflow',
      name: 'Webflow',
      categorySlug: 'development',
      brandColour: const Color(0xFF4353FF),
      fallbackIcon: LucideIcons.globe,
    ),
    ServicePattern(
      slug: 'vimeo',
      name: 'Vimeo',
      categorySlug: 'productivity',
      brandColour: const Color(0xFF1AB7EA),
      fallbackIcon: LucideIcons.video,
    ),

    // ── Data / Monitoring ──
    ServicePattern(
      slug: 'datadog',
      name: 'Datadog',
      categorySlug: 'development',
      brandColour: const Color(0xFF632CA6),
      fallbackIcon: LucideIcons.activity,
    ),
    ServicePattern(
      slug: 'backblaze',
      name: 'Backblaze',
      categorySlug: 'development',
      brandColour: const Color(0xFFE21D38),
      fallbackIcon: LucideIcons.hardDrive,
    ),
    ServicePattern(
      slug: 'zapier',
      name: 'Zapier',
      categorySlug: 'productivity',
      brandColour: const Color(0xFFFF4A00),
      fallbackIcon: LucideIcons.zap,
    ),

    // ── Education ──
    ServicePattern(
      slug: 'duolingo_super',
      name: 'Duolingo Super',
      categorySlug: 'education',
      brandColour: const Color(0xFF58CC02),
      fallbackIcon: LucideIcons.languages,
    ),
    ServicePattern(
      slug: 'coursera_plus',
      name: 'Coursera Plus',
      categorySlug: 'education',
      brandColour: const Color(0xFF0056D2),
      fallbackIcon: LucideIcons.graduationCap,
    ),
    ServicePattern(
      slug: 'udemy_plan',
      name: 'Udemy Personal Plan',
      categorySlug: 'education',
      brandColour: const Color(0xFFA435F0),
      fallbackIcon: LucideIcons.bookOpen,
    ),
    ServicePattern(
      slug: 'blinkist',
      name: 'Blinkist',
      categorySlug: 'education',
      brandColour: const Color(0xFF04846B),
      fallbackIcon: LucideIcons.bookMarked,
    ),

    // ── Social ──
    ServicePattern(
      slug: 'discord_nitro',
      name: 'Discord Nitro',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFF5865F2),
      fallbackIcon: LucideIcons.messageSquare,
    ),
    ServicePattern(
      slug: 'patreon',
      name: 'Patreon',
      categorySlug: 'entertainment',
      brandColour: const Color(0xFFFF424D),
      fallbackIcon: LucideIcons.heart,
    ),

    // ── Health / Fitness (extra) ──
    ServicePattern(
      slug: 'alltrails_plus',
      name: 'AllTrails+',
      categorySlug: 'health_fitness',
      brandColour: const Color(0xFF428813),
      fallbackIcon: LucideIcons.mountain,
    ),
    ServicePattern(
      slug: 'fitbit_premium',
      name: 'Fitbit Premium',
      categorySlug: 'health_fitness',
      brandColour: const Color(0xFF00B0B9),
      fallbackIcon: LucideIcons.watch,
    ),

    // ── Food delivery ──
    ServicePattern(
      slug: 'uber_eats_pass',
      name: 'Uber Eats Pass',
      categorySlug: 'shopping',
      brandColour: const Color(0xFF06C167),
      fallbackIcon: LucideIcons.utensils,
    ),
    ServicePattern(
      slug: 'dashpass',
      name: 'DoorDash DashPass',
      categorySlug: 'shopping',
      brandColour: const Color(0xFFFF3008),
      fallbackIcon: LucideIcons.bike,
    ),
    ServicePattern(
      slug: 'deliveroo_plus',
      name: 'Deliveroo Plus',
      categorySlug: 'shopping',
      brandColour: const Color(0xFF00CCBC),
      fallbackIcon: LucideIcons.bike,
    ),
    ServicePattern(
      slug: 'bigbasket_bbstar',
      name: 'BigBasket BBStar',
      categorySlug: 'shopping',
      brandColour: const Color(0xFF84C225),
      fallbackIcon: LucideIcons.shoppingBag,
    ),
    ServicePattern(
      slug: 'tripadvisor_plus',
      name: 'TripAdvisor Plus',
      categorySlug: 'shopping',
      brandColour: const Color(0xFF34E0A1),
      fallbackIcon: LucideIcons.compass,
    ),

    // ── Platform purchases ──
    ServicePattern(
      slug: 'google_play',
      name: 'Google Play',
      categorySlug: 'platform',
      brandColour: const Color(0xFF34A853),
      fallbackIcon: LucideIcons.playCircle,
    ),
    ServicePattern(
      slug: 'apple_appstore',
      name: 'Apple App Store',
      categorySlug: 'platform',
      brandColour: const Color(0xFF0D84FF),
      fallbackIcon: LucideIcons.appWindow,
    ),
  ];
}
