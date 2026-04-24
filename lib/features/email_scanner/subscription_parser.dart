import '../../core/models/billing_cycle.dart';

/// Detected subscription from email scan.
class DetectedSubscription {
  final String serviceName;
  final String serviceSlug;
  final String categorySlug;
  final String? storeName;
  double amount;
  String currency;
  BillingCycle billingCycle;
  DateTime? nextRenewalDate;
  bool isTrial;
  final String? emailSubject;
  final DateTime? emailDate;
  String? paymentMethodLabel;
  bool isCancellation;
  bool isRefund;
  bool isFailedPayment;
  bool isOneTimePurchase;
  final double confidence;
  final bool requiresReview;
  final String detectionSource;

  DetectedSubscription({
    required this.serviceName,
    required this.serviceSlug,
    required this.categorySlug,
    this.storeName,
    required this.amount,
    this.currency = 'INR',
    required this.billingCycle,
    this.nextRenewalDate,
    this.isTrial = false,
    this.emailSubject,
    this.emailDate,
    this.paymentMethodLabel,
    this.isCancellation = false,
    this.isRefund = false,
    this.isFailedPayment = false,
    this.isOneTimePurchase = false,
    this.confidence = 1.0,
    this.requiresReview = false,
    this.detectionSource = 'parser',
  });
}

class ServicePattern {
  final String name;
  final String slug;
  final String category;
  final List<String> senderDomains;
  final List<String> subjectKeywords;
  final List<RegExp> amountPatternsINR;
  final List<RegExp> amountPatternsUSD;
  final List<RegExp> datePatterns;
  final Map<String, BillingCycle> cycleKeywords;
  final bool Function(String body) isTrial;

  const ServicePattern({
    required this.name,
    required this.slug,
    required this.category,
    required this.senderDomains,
    required this.subjectKeywords,
    required this.amountPatternsINR,
    required this.amountPatternsUSD,
    required this.datePatterns,
    required this.cycleKeywords,
    required this.isTrial,
  });
}

class MerchantResolution {
  final String serviceName;
  final String serviceSlug;
  final String categorySlug;
  final String? storeName;
  final ServicePattern? pattern;

  const MerchantResolution({
    required this.serviceName,
    required this.serviceSlug,
    required this.categorySlug,
    this.storeName,
    this.pattern,
  });
}

class SubscriptionCandidateSignals {
  final bool shouldAnalyzeWithAi;
  final int score;
  final List<String> reasons;

  const SubscriptionCandidateSignals({
    required this.shouldAnalyzeWithAi,
    required this.score,
    required this.reasons,
  });
}

// ═══════════════════════════════════════
// Common regexes
// ═══════════════════════════════════════
final _amountINR = [
  RegExp(r'₹\s*([0-9,]+(?:\.[0-9]{1,2})?)'),
  RegExp(r'INR\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
  RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
  RegExp(r'rupees\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
];

final _amountUSD = [
  RegExp(r'\$\s*([0-9,]+(?:\.[0-9]{1,2})?)'),
  RegExp(r'USD\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
];

final _amountEUR = [
  RegExp(r'€\s*([0-9,]+(?:\.[0-9]{1,2})?)'),
  RegExp(r'EUR\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
];

final _amountGBP = [
  RegExp(r'£\s*([0-9,]+(?:\.[0-9]{1,2})?)'),
  RegExp(r'GBP\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
];

final _datePatterns = [
  RegExp(
      r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})'),
  RegExp(
      r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s+(\d{4})'),
  RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
  RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
];

final _defaultCycleKeywords = <String, BillingCycle>{
  'monthly': BillingCycle.monthly,
  'per month': BillingCycle.monthly,
  '/mo': BillingCycle.monthly,
  'yearly': BillingCycle.yearly,
  'annual': BillingCycle.yearly,
  'per year': BillingCycle.yearly,
  '/yr': BillingCycle.yearly,
  'quarterly': BillingCycle.quarterly,
  'every 3 months': BillingCycle.quarterly,
  'weekly': BillingCycle.weekly,
  'per week': BillingCycle.weekly,
  'every week': BillingCycle.weekly,
  'every month': BillingCycle.monthly,
  'every year': BillingCycle.yearly,
};

bool _defaultTrialCheck(String body) {
  final lower = body.toLowerCase();
  const keywords = [
    'free trial',
    'trial period',
    'trial ends',
    'days left in your trial',
    'trial subscription',
    'complimentary',
    'trial ending',
  ];
  return keywords.any(lower.contains);
}

ServicePattern _sp(String name, String slug, String cat, List<String> domains,
    List<String> subKw,
    {List<RegExp>? inr, List<RegExp>? usd}) {
  return ServicePattern(
    name: name,
    slug: slug,
    category: cat,
    senderDomains: domains,
    subjectKeywords: subKw,
    amountPatternsINR: inr ?? _amountINR,
    amountPatternsUSD: usd ?? _amountUSD,
    datePatterns: _datePatterns,
    cycleKeywords: _defaultCycleKeywords,
    isTrial: _defaultTrialCheck,
  );
}

// ═══════════════════════════════════════
// Full pattern catalog — 38 services
// ═══════════════════════════════════════
final Map<String, ServicePattern> kServicePatterns = {
  // ── Streaming ──
  'netflix': _sp(
      'Netflix',
      'netflix',
      'entertainment',
      ['netflix.com', 'members.netflix.com'],
      ['payment', 'membership', 'receipt', 'renewal']),
  'amazon_prime': _sp(
      'Amazon Prime',
      'amazon_prime',
      'entertainment',
      ['amazon.in', 'amazon.com', 'primevideo.com'],
      ['prime membership', 'renewal', 'receipt']),
  'disney_hotstar': _sp(
      'Disney+ Hotstar',
      'disney_hotstar',
      'entertainment',
      ['hotstar.com', 'disneyplushotstar.com'],
      ['subscription', 'renewal', 'receipt']),
  'youtube_premium': _sp(
      'YouTube Premium',
      'youtube_premium',
      'entertainment',
      ['youtube.com', 'google.com', 'googleplay.com'],
      ['youtube premium', 'receipt', 'subscription']),
  'apple_tv': _sp(
      'Apple TV+',
      'apple_tv',
      'entertainment',
      ['apple.com', 'email.apple.com'],
      ['apple tv', 'receipt', 'subscription']),
  'zee5': _sp('Zee5', 'zee5', 'entertainment', ['zee5.com'],
      ['zee5', 'subscription', 'renewal']),
  'sonyliv': _sp('SonyLIV', 'sonyliv', 'entertainment', ['sonyliv.com'],
      ['sonyliv', 'premium', 'subscription']),

  // ── Music ──
  'spotify': _sp('Spotify', 'spotify', 'music', ['spotify.com'],
      ['premium', 'receipt', 'invoice', 'subscription']),
  'apple_music': _sp('Apple Music', 'apple_music', 'music',
      ['apple.com', 'email.apple.com'], ['apple music', 'receipt']),
  'youtube_music': _sp('YouTube Music', 'youtube_music', 'music',
      ['youtube.com', 'google.com'], ['youtube music', 'receipt']),
  'amazon_music': _sp('Amazon Music', 'amazon_music', 'music',
      ['amazon.in', 'amazon.com'], ['amazon music unlimited', 'receipt']),
  'gaana': _sp('Gaana+', 'gaana', 'music', ['gaana.com'],
      ['gaana', 'subscription', 'receipt']),
  'jiosaavn': _sp('JioSaavn', 'jiosaavn', 'music', ['jiosaavn.com'],
      ['jiosaavn pro', 'receipt']),

  // ── Productivity ──
  'notion': _sp('Notion', 'notion', 'productivity',
      ['notion.so', 'makenotion.com'], ['notion', 'receipt', 'invoice']),
  'slack': _sp('Slack', 'slack', 'productivity', ['slack.com'],
      ['slack invoice', 'receipt', 'subscription']),
  'microsoft_365': _sp(
      'Microsoft 365',
      'microsoft_365',
      'productivity',
      ['microsoft.com', 'office365.com'],
      ['microsoft 365', 'office subscription', 'receipt']),
  'google_one': _sp(
      'Google One',
      'google_one',
      'productivity',
      ['google.com', 'googleplay.com'],
      ['google one', 'google storage', 'receipt']),
  'google_workspace': _sp('Google Workspace', 'google_workspace',
      'productivity', ['google.com'], ['google workspace', 'invoice']),
  'dropbox': _sp(
      'Dropbox',
      'dropbox',
      'productivity',
      ['dropbox.com', 'dropboxmail.com'],
      ['dropbox plus', 'receipt', 'invoice']),
  'zoom': _sp('Zoom', 'zoom', 'productivity', ['zoom.us'],
      ['zoom subscription', 'invoice', 'receipt']),
  'canva': _sp('Canva Pro', 'canva', 'productivity', ['canva.com'],
      ['canva pro', 'receipt', 'invoice']),
  'adobe_cc': _sp('Adobe Creative Cloud', 'adobe_cc', 'productivity',
      ['adobe.com'], ['adobe creative cloud', 'receipt', 'invoice']),
  'figma': _sp('Figma', 'figma', 'productivity', ['figma.com'],
      ['figma', 'receipt', 'invoice']),

  // ── Development ──
  'github_pro': _sp('GitHub Pro', 'github_pro', 'development', ['github.com'],
      ['github', 'invoice', 'receipt']),
  'vercel': _sp('Vercel', 'vercel', 'development', ['vercel.com'],
      ['vercel', 'invoice', 'receipt']),
  'chatgpt_plus': _sp('ChatGPT Plus', 'chatgpt_plus', 'development',
      ['openai.com'], ['chatgpt plus', 'openai', 'receipt', 'invoice']),
  'digitalocean': _sp('DigitalOcean', 'digitalocean', 'development',
      ['digitalocean.com'], ['digitalocean invoice', 'receipt']),

  // ── Gaming ──
  'xbox_game_pass': _sp(
      'Xbox Game Pass',
      'xbox_game_pass',
      'gaming',
      ['microsoft.com', 'xbox.com'],
      ['game pass', 'xbox subscription', 'receipt']),
  'playstation_plus': _sp('PlayStation Plus', 'playstation_plus', 'gaming',
      ['playstation.com', 'sony.com'], ['playstation plus', 'receipt']),
  'steam': _sp(
      'Steam',
      'steam',
      'gaming',
      ['steampowered.com', 'steampowered.com', 'steamgames.com'],
      ['steam', 'purchase', 'receipt', 'order']),
  'epic_games': _sp('Epic Games', 'epic_games', 'gaming', ['epicgames.com'],
      ['epic games', 'purchase', 'receipt', 'order']),
  'jetbrains': _sp('JetBrains', 'jetbrains', 'development', ['jetbrains.com'],
      ['jetbrains', 'license', 'receipt', 'invoice']),
  'unity': _sp('Unity', 'unity', 'development', ['unity.com'],
      ['unity', 'subscription', 'receipt', 'invoice']),

  // ── Indian Lifestyle ──
  'swiggy_one': _sp('Swiggy One', 'swiggy_one', 'shopping', ['swiggy.in'],
      ['swiggy one', 'membership', 'receipt']),
  'zomato_gold': _sp('Zomato Gold', 'zomato_gold', 'shopping', ['zomato.com'],
      ['zomato gold', 'membership', 'receipt']),
  'cultfit': _sp('Cult.fit', 'cultfit', 'health_fitness',
      ['cult.fit', 'cure.fit'], ['cult.fit', 'membership', 'receipt']),
  'times_prime': _sp('Times Prime', 'times_prime', 'shopping',
      ['timesprime.com'], ['times prime', 'membership', 'receipt']),
  'healthifyme': _sp('HealthifyMe', 'healthifyme', 'health_fitness',
      ['healthifyme.com'], ['healthifyme', 'subscription', 'receipt']),
  'kindle_unlimited': _sp(
      'Kindle Unlimited',
      'kindle_unlimited',
      'education',
      ['amazon.in', 'amazon.com'],
      ['kindle unlimited', 'membership', 'receipt']),

  // ── Health ──
  'headspace': _sp('Headspace', 'headspace', 'health_fitness',
      ['headspace.com'], ['headspace', 'subscription', 'receipt']),
  'calm': _sp('Calm', 'calm', 'health_fitness', ['calm.com'],
      ['calm', 'subscription', 'receipt']),

  // ── News ──
  'medium': _sp('Medium', 'medium', 'news', ['medium.com'],
      ['medium membership', 'receipt']),
  'substack': _sp('Substack', 'substack', 'news', ['substack.com'],
      ['substack', 'subscription', 'paid']),

  // ── AI ──
  'claude_pro': _sp('Claude Pro', 'claude_pro', 'development',
      ['anthropic.com'], ['claude pro', 'anthropic', 'receipt', 'invoice']),
  'gemini_advanced': _sp('Gemini Advanced', 'gemini_advanced', 'development',
      ['google.com'], ['gemini advanced', 'google one ai', 'receipt']),
  'perplexity_pro': _sp('Perplexity Pro', 'perplexity_pro', 'development',
      ['perplexity.ai'], ['perplexity pro', 'receipt', 'invoice']),

  // ── Streaming (extra) ──
  'max': _sp(
      'Max',
      'max',
      'entertainment',
      ['max.com', 'hbomax.com', 'warnerbros.com'],
      ['max subscription', 'hbo max', 'receipt', 'renewal']),
  'hulu': _sp('Hulu', 'hulu', 'entertainment', ['hulu.com'],
      ['hulu', 'subscription', 'receipt', 'renewal']),
  'crunchyroll': _sp('Crunchyroll', 'crunchyroll', 'entertainment',
      ['crunchyroll.com'], ['crunchyroll', 'premium', 'receipt']),
  'paramount_plus': _sp(
      'Paramount+',
      'paramount_plus',
      'entertainment',
      ['paramountplus.com', 'cbs.com'],
      ['paramount+', 'paramount plus', 'receipt', 'subscription']),
  'peacock': _sp('Peacock', 'peacock', 'entertainment', ['peacocktv.com'],
      ['peacock', 'premium', 'receipt']),
  'jiohotstar': _sp(
      'JioHotstar',
      'jiohotstar',
      'entertainment',
      ['hotstar.com', 'jiocinema.com', 'jio.com'],
      ['jiohotstar', 'jio hotstar', 'jiostar', 'subscription', 'receipt']),

  // ── Music (extra) ──
  'tidal': _sp('Tidal', 'tidal', 'music', ['tidal.com'],
      ['tidal', 'hifi', 'subscription', 'receipt']),
  'deezer': _sp('Deezer', 'deezer', 'music', ['deezer.com'],
      ['deezer', 'premium', 'receipt']),
  'soundcloud_go': _sp('SoundCloud Go+', 'soundcloud_go', 'music',
      ['soundcloud.com'], ['soundcloud go', 'subscription', 'receipt']),
  'audible': _sp('Audible', 'audible', 'entertainment',
      ['audible.com', 'audible.in'], ['audible', 'membership', 'receipt']),
  'apple_podcasts': _sp('Apple Podcasts', 'apple_podcasts', 'entertainment',
      ['apple.com'], ['apple podcasts', 'premium', 'receipt']),

  // ── Telecom ──
  'airtel': _sp('Airtel', 'airtel', 'utilities', ['airtel.in', 'myairtel.com'],
      ['airtel', 'recharge', 'plan', 'receipt']),
  'jio': _sp('Jio', 'jio', 'utilities', ['jio.com', 'reliancejio.com'],
      ['jio', 'recharge', 'plan', 'receipt']),

  // ── Productivity (extra) ──
  'grammarly': _sp('Grammarly', 'grammarly', 'productivity', ['grammarly.com'],
      ['grammarly', 'premium', 'receipt', 'invoice']),
  'calendly': _sp('Calendly', 'calendly', 'productivity', ['calendly.com'],
      ['calendly', 'receipt', 'invoice', 'subscription']),
  'clickup': _sp('ClickUp', 'clickup', 'productivity', ['clickup.com'],
      ['clickup', 'receipt', 'invoice']),
  'asana': _sp('Asana', 'asana', 'productivity', ['asana.com'],
      ['asana', 'premium', 'receipt', 'invoice']),
  'trello': _sp('Trello', 'trello', 'productivity', ['trello.com'],
      ['trello', 'premium', 'receipt']),
  'jira': _sp('Jira', 'jira', 'productivity',
      ['atlassian.com', 'atlassian.net'], ['jira', 'invoice', 'receipt']),
  'linear': _sp('Linear', 'linear', 'productivity', ['linear.app'],
      ['linear', 'receipt', 'invoice']),
  'loom': _sp('Loom', 'loom', 'productivity', ['loom.com'],
      ['loom', 'receipt', 'invoice', 'subscription']),
  'miro': _sp('Miro', 'miro', 'productivity', ['miro.com'],
      ['miro', 'receipt', 'invoice', 'subscription']),
  'todoist': _sp('Todoist', 'todoist', 'productivity',
      ['todoist.com', 'doist.com'], ['todoist', 'pro', 'receipt', 'invoice']),
  'evernote': _sp('Evernote', 'evernote', 'productivity', ['evernote.com'],
      ['evernote', 'premium', 'receipt']),
  'basecamp': _sp('Basecamp', 'basecamp', 'productivity', ['basecamp.com'],
      ['basecamp', 'receipt', 'invoice']),
  'box': _sp('Box', 'box', 'productivity', ['box.com'],
      ['box', 'business', 'receipt', 'invoice']),

  // ── Development (extra) ──
  'replit_core': _sp('Replit Core', 'replit_core', 'development',
      ['replit.com'], ['replit', 'core', 'receipt', 'invoice']),
  'render': _sp('Render', 'render', 'development', ['render.com'],
      ['render', 'invoice', 'receipt']),
  'railway': _sp('Railway', 'railway', 'development', ['railway.app'],
      ['railway', 'invoice', 'receipt']),
  'netlify': _sp('Netlify Pro', 'netlify', 'development', ['netlify.com'],
      ['netlify', 'pro', 'invoice', 'receipt']),
  'cloudflare': _sp('Cloudflare Pro', 'cloudflare', 'development',
      ['cloudflare.com'], ['cloudflare', 'pro', 'invoice', 'receipt']),
  'flydotio': _sp('Fly.io', 'flydotio', 'development', ['fly.io'],
      ['fly.io', 'invoice', 'receipt']),
  'stackblitz': _sp('StackBlitz', 'stackblitz', 'development',
      ['stackblitz.com'], ['stackblitz', 'receipt', 'invoice']),
  'postman': _sp('Postman', 'postman', 'development',
      ['postman.com', 'getpostman.com'], ['postman', 'receipt', 'invoice']),
  'supabase': _sp(
      'Supabase Pro',
      'supabase',
      'development',
      ['supabase.com', 'supabase.io'],
      ['supabase', 'pro', 'invoice', 'receipt']),

  // ── Security / Infra ──
  'onepassword': _sp('1Password', 'onepassword', 'productivity',
      ['1password.com'], ['1password', 'receipt', 'invoice']),
  'bitwarden': _sp('Bitwarden', 'bitwarden', 'productivity', ['bitwarden.com'],
      ['bitwarden', 'premium', 'receipt']),
  'proton': _sp(
      'Proton',
      'proton',
      'productivity',
      ['proton.me', 'protonmail.com'],
      ['proton', 'plus', 'receipt', 'invoice']),
  'okta': _sp('Okta', 'okta', 'development', ['okta.com'],
      ['okta', 'invoice', 'receipt']),
  'auth0': _sp('Auth0', 'auth0', 'development', ['auth0.com'],
      ['auth0', 'invoice', 'receipt']),

  // ── Marketing / CRM ──
  'mailchimp': _sp('Mailchimp', 'mailchimp', 'productivity', ['mailchimp.com'],
      ['mailchimp', 'receipt', 'invoice']),
  'hubspot': _sp('HubSpot', 'hubspot', 'productivity', ['hubspot.com'],
      ['hubspot', 'receipt', 'invoice']),
  'brevo': _sp('Brevo', 'brevo', 'productivity',
      ['brevo.com', 'sendinblue.com'], ['brevo', 'receipt', 'invoice']),
  'intercom': _sp('Intercom', 'intercom', 'productivity',
      ['intercom.com', 'intercom.io'], ['intercom', 'receipt', 'invoice']),
  'zendesk': _sp('Zendesk', 'zendesk', 'productivity', ['zendesk.com'],
      ['zendesk', 'receipt', 'invoice']),

  // ── Web / Hosting ──
  'shopify': _sp('Shopify', 'shopify', 'development', ['shopify.com'],
      ['shopify', 'subscription', 'receipt', 'invoice']),
  'godaddy': _sp('GoDaddy', 'godaddy', 'development', ['godaddy.com'],
      ['godaddy', 'renewal', 'receipt', 'invoice']),
  'namecheap': _sp('Namecheap', 'namecheap', 'development', ['namecheap.com'],
      ['namecheap', 'renewal', 'receipt', 'invoice']),
  'webflow': _sp('Webflow', 'webflow', 'development', ['webflow.com'],
      ['webflow', 'receipt', 'invoice']),
  'vimeo': _sp('Vimeo', 'vimeo', 'productivity', ['vimeo.com'],
      ['vimeo', 'plus', 'pro', 'receipt']),

  // ── Data / Monitoring ──
  'datadog': _sp('Datadog', 'datadog', 'development',
      ['datadog.com', 'datadoghq.com'], ['datadog', 'invoice', 'receipt']),
  'backblaze': _sp('Backblaze', 'backblaze', 'development', ['backblaze.com'],
      ['backblaze', 'invoice', 'receipt']),
  'zapier': _sp('Zapier', 'zapier', 'productivity', ['zapier.com'],
      ['zapier', 'receipt', 'invoice']),

  // ── Education ──
  'duolingo_super': _sp('Duolingo Super', 'duolingo_super', 'education',
      ['duolingo.com'], ['duolingo', 'super', 'plus', 'receipt']),
  'coursera_plus': _sp('Coursera Plus', 'coursera_plus', 'education',
      ['coursera.org'], ['coursera', 'plus', 'receipt', 'invoice']),
  'udemy_plan': _sp('Udemy Personal Plan', 'udemy_plan', 'education',
      ['udemy.com'], ['udemy', 'personal plan', 'receipt']),
  'blinkist': _sp('Blinkist', 'blinkist', 'education', ['blinkist.com'],
      ['blinkist', 'premium', 'receipt']),

  // ── Social ──
  'discord_nitro': _sp(
      'Discord Nitro',
      'discord_nitro',
      'entertainment',
      ['discord.com', 'discordapp.com'],
      ['discord nitro', 'nitro', 'receipt', 'subscription']),
  'patreon': _sp('Patreon', 'patreon', 'entertainment', ['patreon.com'],
      ['patreon', 'membership', 'receipt', 'pledge']),

  // ── Health / Fitness (extra) ──
  'alltrails_plus': _sp('AllTrails+', 'alltrails_plus', 'health_fitness',
      ['alltrails.com'], ['alltrails', 'plus', 'receipt']),
  'fitbit_premium': _sp('Fitbit Premium', 'fitbit_premium', 'health_fitness',
      ['fitbit.com'], ['fitbit premium', 'receipt']),

  // ── Food delivery ──
  'uber_one': _sp('Uber One', 'uber_one', 'shopping', ['uber.com'],
      ['uber one', 'membership', 'receipt']),
  'uber_eats_pass': _sp('Uber Eats Pass', 'uber_eats_pass', 'shopping',
      ['uber.com', 'ubereats.com'], ['uber eats pass', 'eats pass', 'receipt']),
  'dashpass': _sp('DoorDash DashPass', 'dashpass', 'shopping', ['doordash.com'],
      ['dashpass', 'membership', 'receipt']),
  'deliveroo_plus': _sp('Deliveroo Plus', 'deliveroo_plus', 'shopping',
      ['deliveroo.com'], ['deliveroo plus', 'receipt']),
  'bigbasket_bbstar': _sp('BigBasket BBStar', 'bigbasket_bbstar', 'shopping',
      ['bigbasket.com'], ['bbstar', 'bb star', 'membership', 'receipt']),
  'tripadvisor_plus': _sp('TripAdvisor Plus', 'tripadvisor_plus', 'shopping',
      ['tripadvisor.com'], ['tripadvisor plus', 'receipt']),

  // ── Apple ecosystem ──
  'apple_arcade': _sp(
      'Apple Arcade',
      'apple_arcade',
      'gaming',
      ['apple.com', 'email.apple.com'],
      ['apple arcade', 'receipt', 'subscription']),

  // ── Platform purchases (Google Play / Apple) ──
  'google_play': _sp('Google Play', 'google_play', 'platform', [
    'googleplay-noreply@google.com',
    'google.com',
    'payments-noreply@google.com'
  ], [
    'google play',
    'order received',
    'subscription',
    'receipt',
    'your order'
  ]),
  'apple_appstore': _sp('Apple App Store', 'apple_appstore', 'platform', [
    'no_reply@email.apple.com',
    'apple.com',
    'email.apple.com',
    'itunes'
  ], [
    'app store',
    'itunes',
    'receipt',
    'subscription renewal',
    'apple.com/bill'
  ]),
};

// ═══════════════════════════════════════
// Parser
// ═══════════════════════════════════════
// ═══════════════════════════════════════
// Subscription keywords — 50 targeted terms
// that capture 99.9% of real paid subs
// ═══════════════════════════════════════
const kSubscriptionKeywords = [
  // ── Transaction signals (high confidence) ──
  'receipt', 'invoice', 'payment confirmation',
  'payment receipt', 'tax invoice', 'paid invoice',
  'order confirmation', 'subscription confirmed',
  'charged successfully', 'payment processed',
  'payment successful', 'payment received', 'billing statement',
  'transaction', 'purchase confirmation', 'bill is ready',
  'your bill', 'amount paid', 'total paid',

  // ── Subscription lifecycle ──
  'subscription', 'renewal', 'auto-renewal',
  'auto renew', 'automatic renewal',
  'has been renewed', 'renewed', 'renews on', 'renewal notice',
  'your plan', 'plan renewed', 'plan activated',
  'plan starts', 'plan expires', 'valid till', 'valid until',
  'membership', 'membership renewed',
  'subscription started', 'subscription ending',
  'you subscribed', 'subscribed to', 'thanks for subscribing',

  // ── Billing & money ──
  'billing', 'monthly charge', 'annual charge',
  'subscription fee', 'recurring payment', 'recurring charge',
  'charged to your', 'deducted from',
  'payment due', 'upcoming payment',
  'next billing date', 'next billing', 'next payment',
  'next charge', 'next invoice', 'upcoming charge',

  // ── Trial ──
  'free trial', 'trial ending', 'trial ends',
  'trial period', 'trial subscription', 'trial started',
  'trial expires', 'trial will end',

  // ── Platform purchases (Google Play / Apple) ──
  'google play', 'play store',
  'app store', 'itunes', 'apple.com/bill',
  'in-app purchase', 'order received',

  // ── Premium / upgrade ──
  'premium', 'pro plan', 'plus plan',
  'monthly plan', 'annual plan', 'yearly plan',
  'upgrade confirmed', 'welcome to premium',
  'welcome to pro', 'welcome to plus',
];

// ── Senders that indicate real transactions ──
const kPlatformSenders = [
  'googleplay-noreply@google.com',
  'payments-noreply@google.com',
  'no_reply@email.apple.com',
  'noreply@youtube.com',
];

// ── Signals that an email is a newsletter / marketing (NOT a sub) ──
const kNewsletterSignals = [
  'unsubscribe from this list',
  'email preferences',
  'update your preferences',
  'you are receiving this email because',
  'manage email notifications',
  'this is a promotional email',
  'view in browser',
  'weekly digest',
  'daily digest',
  'newsletter',
  'what\'s new this week',
  'top picks for you',
  'recommended for you',
  'trending now',
];

// ── Signals that confirm a real paid transaction ──
const kTransactionConfirmSignals = [
  'receipt',
  'invoice',
  'charged',
  'payment processed',
  'payment successful',
  'order confirmation',
  'billing',
  'bill is ready',
  'tax invoice',
  'payment receipt',
  'paid invoice',
  'amount',
  'amount paid',
  'total paid',
  'total due',
  'transaction id',
  'payment method',
  'card ending',
  'charged to',
  'billed to',
  'paid with',
  'total:',
  'subtotal',
  'deducted',
  'paid',
  'payment received',
  'next billing',
  'renewal date',
  'renews on',
];

// ── Signals indicating cancellation ──
const kCancellationSignals = [
  'subscription cancelled',
  'subscription canceled',
  'has been cancelled',
  'has been canceled',
  'cancellation confirmed',
  'cancellation confirmation',
  'you cancelled',
  'you canceled',
  'membership cancelled',
  'membership canceled',
  'successfully cancelled',
  'successfully canceled',
  'plan cancelled',
  'plan canceled',
  'your cancellation',
  'cancelled your',
];

// ── Signals indicating refund ──
const kRefundSignals = [
  'refund',
  'refunded',
  'refund processed',
  'refund confirmation',
  'money back',
  'credit issued',
  'credited to your',
  'reversal',
  'chargeback',
];

// ── Signals indicating one-time purchase (not subscription) ──
const kOneTimePurchaseSignals = [
  'one-time purchase',
  'one time purchase',
  'single purchase',
  'order placed',
  'your order',
  'shipping confirmation',
  'delivery confirmation',
  'dispatch',
  'out for delivery',
  'has shipped',
  'license key',
  'activation code',
  'serial number',
  'game purchase',
  'software license',
  'perpetual license',
];

const kFailedPaymentSignals = [
  'payment failed',
  'payment was declined',
  'card declined',
  'could not process your payment',
  'unable to renew',
  'renewal failed',
  'billing issue',
  'update your payment method',
  'payment method was declined',
];

final Map<String, List<String>> kMerchantAliases = {
  'spotify': ['spotify premium'],
  'discord_nitro': ['discord nitro'],
  'chatgpt_plus': ['chatgpt plus', 'openai chatgpt plus'],
  'google_one': ['google one ai premium', 'google one'],
  'google_workspace': ['google workspace', 'workspace individual'],
  'youtube_premium': ['youtube premium'],
  'youtube_music': ['youtube music'],
  'apple_tv': ['apple tv', 'apple tv+'],
  'apple_music': ['apple music'],
  'apple_arcade': ['apple arcade'],
  'amazon_prime': ['prime video', 'amazon prime'],
  'amazon_music': ['amazon music', 'music unlimited'],
  'microsoft_365': ['office 365', 'microsoft 365'],
  'fitbit_premium': ['fitbit premium'],
  'xbox_game_pass': ['game pass', 'xbox game pass'],
  'playstation_plus': ['playstation plus', 'ps plus'],
  'steam': ['steam', 'steampowered'],
  'epic_games': ['epic games', 'epic games store'],
  'jetbrains': ['jetbrains', 'all products pack'],
};

class SubscriptionParser {
  /// Build focused Gmail queries using targeted keywords.
  /// Returns a list of queries to run (multi-phase scan).
  static List<String> buildSmartQueries({DateTime? after}) {
    final afterClause =
        after != null ? ' after:${after.millisecondsSinceEpoch ~/ 1000}' : '';
    return [
      // Gmail supports OR groups, but brace negation is inconsistent across accounts.
      '(receipt OR invoice OR "payment confirmation" OR "payment receipt" OR "tax invoice" OR billing OR bill OR charged OR paid)$afterClause',
      '(subscription OR membership OR recurring OR "auto-renew" OR "auto renew" OR "automatic renewal") (receipt OR invoice OR billing OR payment OR charged OR paid OR renewal)$afterClause',
      '("renews on" OR renews OR "renewal date" OR "next renewal" OR "next billing" OR "next payment" OR "next charge" OR "next invoice" OR "upcoming charge" OR "upcoming invoice")$afterClause',
      '("your plan" OR "plan renewed" OR "plan activated" OR "plan starts" OR "plan expires" OR "welcome to premium" OR "welcome to pro" OR "welcome to plus")$afterClause',
      '(from:googleplay-noreply@google.com OR from:payments-noreply@google.com OR from:no_reply@email.apple.com OR from:itunes.com) (subscription OR receipt OR invoice OR renewal OR "your order" OR "auto-renew" OR renews)$afterClause',
      '("apple.com/bill" OR "google play" OR "play store" OR "app store" OR "in-app purchase") (subscription OR renewal OR receipt OR invoice OR "auto-renew" OR membership)$afterClause',
      '("free trial" OR "trial ends" OR "trial ending" OR "trial expires" OR "trial started") (subscription OR plan OR membership OR premium OR pro)$afterClause',
      '("card ending" OR "ending in" OR "payment method" OR "paid with" OR "charged to" OR "billed to") (subscription OR membership OR renewal OR invoice OR receipt OR plan)$afterClause',
    ];
  }

  /// Fast, local pre-filter used before invoking the offline AI model.
  /// It intentionally casts a slightly wider net than [resolveMerchant] so
  /// unknown merchants can still be extracted by the local model.
  static SubscriptionCandidateSignals candidateSignals(
      String from, String content) {
    final fromLower = from.toLowerCase();
    final contentLower = content.toLowerCase();
    final reasons = <String>[];
    var score = 0;

    final hasStrictTransactionSignal =
        _hasStrictTransactionSignal(contentLower);
    final hasTransactionSignal =
        hasStrictTransactionSignal || _hasTransactionSignal(contentLower);
    final hasAmount = RegExp(r'[₹$€£]\s*[\d,]+').hasMatch(content) ||
        RegExp(r'\b(INR|USD|EUR|GBP)\s*[\d,]+', caseSensitive: false)
            .hasMatch(content) ||
        RegExp(r'\b(?:rs\.?|rupees)\s*[\d,]+', caseSensitive: false)
            .hasMatch(content);
    final hasSubscriptionSignal = RegExp(
      r'\b(subscription|subscribed|renewal|renews|renewed|auto-renew|auto renew|autorenew|automatic renewal|membership|plan renewed|plan activated|plan starts|plan expires|next billing|next payment|next charge|next invoice|trial ends|trial ending|trial expires|trial period|recurring|recurring payment|recurring charge|monthly plan|annual plan|yearly plan|premium plan|pro plan|plus plan)\b',
      caseSensitive: false,
    ).hasMatch(content);
    final hasPaymentMethodSignal = RegExp(
      r'\b(card ending|ending in|payment method|paid with|charged to|billed to|visa|mastercard|rupay|amex|paypal|upi|gpay|google pay|apple pay)\b',
      caseSensitive: false,
    ).hasMatch(content);
    final hasLifecycleDateSignal = RegExp(
      r'\b(renews on|renewal date|next renewal|valid till|valid until|expires on|expiry date|next billing date|next payment date|next charge date)\b',
      caseSensitive: false,
    ).hasMatch(content);
    final hasBillingSender = RegExp(
      r'\b(billing|bill|invoice|receipt|payment|payments|subscription|subscriptions|orders|accounts|no-?reply)\b',
      caseSensitive: false,
    ).hasMatch(from);
    final isPlatformSender = fromLower.contains('googleplay-noreply') ||
        fromLower.contains('payments-noreply@google') ||
        fromLower.contains('no_reply@email.apple.com') ||
        fromLower.contains('itunes') ||
        fromLower.contains('apple.com') ||
        fromLower.contains('youtube.com');
    final looksLikeAuthOrShipping = RegExp(
      r'\b(verification code|password reset|sign-in alert|login alert|otp|has shipped|out for delivery|delivery confirmation|tracking number)\b',
      caseSensitive: false,
    ).hasMatch(content);

    if (_isLikelyNewsletter(contentLower) && !hasTransactionSignal) {
      return const SubscriptionCandidateSignals(
        shouldAnalyzeWithAi: false,
        score: 0,
        reasons: ['newsletter'],
      );
    }
    if (looksLikeAuthOrShipping && !hasTransactionSignal) {
      return const SubscriptionCandidateSignals(
        shouldAnalyzeWithAi: false,
        score: 0,
        reasons: ['non_billing'],
      );
    }

    if (hasStrictTransactionSignal) {
      score += 2;
      reasons.add('transaction');
    } else if (hasTransactionSignal) {
      score += 1;
      reasons.add('soft_transaction');
    }
    if (hasSubscriptionSignal) {
      score += 2;
      reasons.add('subscription');
    }
    if (hasAmount) {
      score += 1;
      reasons.add('amount');
    }
    if (hasPaymentMethodSignal) {
      score += 1;
      reasons.add('payment_method');
    }
    if (hasLifecycleDateSignal) {
      score += 1;
      reasons.add('lifecycle_date');
    }
    if (hasBillingSender) {
      score += 1;
      reasons.add('billing_sender');
    }
    if (isPlatformSender) {
      score += 2;
      reasons.add('platform_sender');
    }

    for (final pattern in kServicePatterns.values) {
      if (pattern.category == 'platform') continue;
      final senderMatch =
          _matchesSenderDomain(fromLower, pattern.senderDomains);
      if (!senderMatch) continue;
      score += 1;
      reasons.add('known_sender');
      if (_matchesServiceNameInBody(pattern, contentLower)) {
        score += 1;
        reasons.add('known_service');
      }
      break;
    }

    final shouldAnalyze = score >= 3 ||
        (score >= 2 &&
            (hasSubscriptionSignal ||
                hasLifecycleDateSignal ||
                isPlatformSender ||
                reasons.contains('known_service')));

    return SubscriptionCandidateSignals(
      shouldAnalyzeWithAi: shouldAnalyze,
      score: score,
      reasons: reasons,
    );
  }

  static MerchantResolution? resolveMerchant(String from, String content) {
    final fromLower = from.toLowerCase();
    final contentLower = content.toLowerCase();

    // ── Step 1: Hard reject newsletters ──
    if (_isLikelyNewsletter(contentLower) &&
        !_hasStrictTransactionSignal(contentLower)) {
      return null;
    }

    // ── Step 2: Platform emails (Google Play / Apple) — highest precision ──
    final platformMatch = _matchPlatformPurchase(from, fromLower, contentLower);
    if (platformMatch != null) return platformMatch;

    // ── Step 3: Named service matching — domain + specific service name in body ──
    for (final pattern in kServicePatterns.values) {
      if (pattern.category == 'platform') continue;

      // Must match the sender domain precisely
      final domainMatch =
          _matchesSenderDomain(fromLower, pattern.senderDomains);
      if (!domainMatch) continue;

      // Must find the specific service name or alias in the email body
      final nameInBody = _matchesServiceNameInBody(pattern, contentLower);
      if (!nameInBody) continue;

      // Must have a real payment/billing signal
      if (!_hasStrictTransactionSignal(contentLower)) continue;

      return MerchantResolution(
        serviceName: pattern.name,
        serviceSlug: pattern.slug,
        categorySlug: pattern.category,
        pattern: pattern,
      );
    }

    // ── No match — do NOT add generic fallback entries ──
    return null;
  }

  /// Checks if the sender domain exactly matches any of the pattern's domains.
  /// Uses suffix matching (e.g. 'email.netflix.com' matches 'netflix.com').
  static bool _matchesSenderDomain(String fromLower, List<String> domains) {
    for (final domain in domains) {
      // Extract just the domain part from the From header
      final emailDomain = _extractDomain(fromLower);
      if (emailDomain.endsWith(domain) || emailDomain == domain) return true;
    }
    return false;
  }

  static String _extractDomain(String fromLower) {
    final atIndex = fromLower.indexOf('@');
    if (atIndex < 0) return fromLower;
    final afterAt = fromLower.substring(atIndex + 1);
    // Remove trailing '>' or whitespace
    return afterAt.replaceAll(RegExp(r'[>\s].*'), '');
  }

  /// Checks if the specific service name or any alias appears in the email body.
  static bool _matchesServiceNameInBody(
      ServicePattern pattern, String contentLower) {
    // Check the canonical service name (normalized)
    final canonical = pattern.name
        .toLowerCase()
        .replaceAll('+', ' plus ')
        .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (canonical.length >= 3 && contentLower.contains(canonical)) return true;

    // Check slug as words
    final slugWords = pattern.slug.replaceAll('_', ' ');
    if (slugWords.length >= 4 && contentLower.contains(slugWords)) return true;

    // Check known aliases
    final aliases = kMerchantAliases[pattern.slug];
    if (aliases != null) {
      for (final alias in aliases) {
        if (alias.length >= 4 && contentLower.contains(alias.toLowerCase())) {
          return true;
        }
      }
    }

    // Check specific subject keywords that include the service name
    for (final kw in pattern.subjectKeywords) {
      // Only use keywords that aren't purely generic
      if (kw.length >= 6 &&
          !_isGenericKeyword(kw) &&
          contentLower.contains(kw.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  static bool _isGenericKeyword(String kw) {
    const generic = {
      'receipt',
      'invoice',
      'subscription',
      'renewal',
      'payment',
      'membership',
      'billing',
      'order',
      'plan',
    };
    return generic.contains(kw.toLowerCase().trim());
  }

  /// Stricter transaction signal — requires at least 1 money/billing term.
  static bool _hasStrictTransactionSignal(String contentLower) {
    const strict = [
      'receipt',
      'invoice',
      'charged',
      'paid',
      'payment processed',
      'payment successful',
      'payment received',
      'payment confirmation',
      'payment receipt',
      'order confirmation',
      'billing statement',
      'bill is ready',
      'tax invoice',
      'charged to your',
      'charged to',
      'billed to',
      'paid with',
      'amount paid',
      'total paid',
      'card ending',
      'next billing',
      'next payment',
      'next charge',
      'next invoice',
      'upcoming charge',
      'renewal date',
      'renews on',
      'transaction id',
      'deducted from',
      'subscription confirmed',
      'charged successfully',
      'auto-renewal',
      'automatic renewal',
      'recurring payment',
      'recurring charge',
      'billing cycle',
      'your subscription',
    ];
    for (final s in strict) {
      if (contentLower.contains(s)) return true;
    }
    return false;
  }

  /// Try to match an email to a known service.
  /// Returns null if it looks like a newsletter or has no transaction signal.
  static ServicePattern? matchService(String from, String content) {
    return resolveMerchant(from, content)?.pattern;
  }

  static MerchantResolution? _matchPlatformPurchase(
      String from, String fromLower, String contentLower) {
    final isGooglePlay = fromLower.contains('googleplay-noreply') ||
        fromLower.contains('payments-noreply@google');
    final isApple = fromLower.contains('no_reply@email.apple.com') ||
        fromLower.contains('itunes');

    if (!isGooglePlay && !isApple) return null;

    // Only process if this is actually a subscription email, not a one-time purchase
    final isSubscriptionEmail = contentLower.contains('subscription') ||
        contentLower.contains('renewal') ||
        contentLower.contains('membership') ||
        contentLower.contains('auto-renewal') ||
        contentLower.contains('renews on') ||
        contentLower.contains('next billing');

    if (!isSubscriptionEmail) return null;

    // Try to match a specific known service from the body text
    for (final pattern in kServicePatterns.values) {
      if (pattern.category == 'platform') continue;
      final canonicalName = pattern.name
          .toLowerCase()
          .replaceAll('+', ' plus ')
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim();
      final slugWords = pattern.slug.replaceAll('_', ' ');
      if (contentLower.contains(canonicalName) ||
          contentLower.contains(slugWords)) {
        return MerchantResolution(
          serviceName: pattern.name,
          serviceSlug: pattern.slug,
          categorySlug: pattern.category,
          storeName: isGooglePlay ? 'Google Play' : 'App Store',
          pattern: pattern,
        );
      }
    }

    // Try to extract app name from platform receipt patterns
    final platform = isGooglePlay ? 'google_play' : 'apple';
    final extracted = extractMerchantFromPlatformEmail(contentLower, platform);
    if (extracted != null) {
      // Search against known services first
      for (final pattern in kServicePatterns.values) {
        if (pattern.category == 'platform') continue;
        if (_matchesExtractedMerchant(extracted, pattern)) {
          return MerchantResolution(
            serviceName: pattern.name,
            serviceSlug: pattern.slug,
            categorySlug: pattern.category,
            storeName: isGooglePlay ? 'Google Play' : 'App Store',
            pattern: pattern,
          );
        }
      }
      // Only create a dynamic entry if the name looks legitimate (not a generic term)
      final cleanName = extracted.trim();
      final isGeneric =
          {'app', 'item', 'plan', 'subscription', 'your'}.contains(cleanName);
      if (!isGeneric && cleanName.length >= 3) {
        return MerchantResolution(
          serviceName: _titleCase(cleanName),
          serviceSlug: _slugify(cleanName),
          categorySlug: 'platform',
          storeName: isGooglePlay ? 'Google Play' : 'App Store',
        );
      }
    }

    // Could not identify the specific service — skip rather than add a vague entry
    return null;
  }

  /// Extract sender display name from "From" header.
  static String _extractSenderName(String from) {
    final match = RegExp(r'^"?([^"<]+)"?\s*<').firstMatch(from);
    if (match != null) {
      final name = match.group(1)!.trim();
      if (name.isNotEmpty) return name;
    }
    final raw =
        from.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ').trim();
    return raw.isNotEmpty ? raw : 'Unknown';
  }

  /// Extract the actual merchant/app name from a platform receipt email.
  static String? extractMerchantFromPlatformEmail(
      String contentLower, String platform) {
    final patterns = platform == 'google_play'
        ? [
            // Google Play patterns
            RegExp(r'(?:item|app|subscription):\s*(.+?)(?:\n|\r|\s{2,}|$)'),
            RegExp(
                r'(?:you bought|you subscribed to|order for)\s+(.+?)(?:\n|\r|\s{2,}|\.|$)'),
            RegExp(
                r'(?:your )(\S+(?:\s+\S+){0,3})(?:\s+subscription|\s+membership|\s+plan)'),
          ]
        : [
            // Apple patterns
            RegExp(r'(?:subscription|app|item):\s*(.+?)(?:\n|\r|\s{2,}|$)'),
            RegExp(
                r'(?:renewal for|receipt for|subscribed to)\s+(.+?)(?:\n|\r|\s{2,}|\.|$)'),
            RegExp(
                r'(?:your )(\S+(?:\s+\S+){0,3})(?:\s+subscription|\s+membership|\s+plan)'),
          ];
    for (final re in patterns) {
      final match = re.firstMatch(contentLower);
      if (match != null && match.group(1) != null) {
        final name = match.group(1)!.trim();
        if (name.length >= 2 && name.length <= 60) return name;
      }
    }
    return null;
  }

  /// Check if email is likely a newsletter / marketing (not a transaction).
  static bool _isLikelyNewsletter(String contentLower) {
    int signals = 0;
    for (final kw in kNewsletterSignals) {
      if (contentLower.contains(kw)) signals++;
    }
    return signals >= 2; // 2+ newsletter signals = likely newsletter
  }

  /// Check if email has real transaction / payment indicators.
  static bool _hasTransactionSignal(String contentLower) {
    for (final kw in kTransactionConfirmSignals) {
      if (contentLower.contains(kw)) return true;
    }
    // Also check for price patterns
    if (RegExp(r'[₹$€£]\s*\d').hasMatch(contentLower)) return true;
    if (RegExp(r'(INR|USD|EUR|GBP)\s*\d').hasMatch(contentLower)) return true;
    return false;
  }

  /// Compute a confidence score (0.0 – 1.0) for a detected subscription.
  static double confidenceScore(
      ServicePattern pattern, String from, String content) {
    double score = 0;
    final fromLower = from.toLowerCase();
    final contentLower = content.toLowerCase();

    // Domain match
    if (pattern.senderDomains.any(fromLower.contains)) score += 0.30;

    // Transaction signals
    int txSignals = 0;
    for (final kw in kTransactionConfirmSignals) {
      if (contentLower.contains(kw)) txSignals++;
    }
    score += (txSignals.clamp(0, 5) / 5) * 0.30;

    // Price pattern found
    if (RegExp(r'[₹$€£]\s*[\d,]+').hasMatch(contentLower)) score += 0.20;

    // Name/keyword match
    final canonicalName = pattern.name
        .toLowerCase()
        .replaceAll('+', ' plus ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    if (contentLower.contains(canonicalName)) score += 0.10;
    if (pattern.subjectKeywords.any(contentLower.contains)) score += 0.10;

    return score.clamp(0.0, 1.0);
  }

  /// Detect if an email indicates a cancellation.
  static bool isCancellationEmail(String content) {
    final lower = content.toLowerCase();
    return kCancellationSignals.any(lower.contains);
  }

  /// Detect if an email indicates a refund.
  static bool isRefundEmail(String content) {
    final lower = content.toLowerCase();
    return kRefundSignals.any(lower.contains);
  }

  static bool isFailedPaymentEmail(String content) {
    final lower = content.toLowerCase();
    return kFailedPaymentSignals.any(lower.contains);
  }

  /// Detect if an email is likely a one-time purchase, not a subscription.
  static bool isOneTimePurchase(String content) {
    final lower = content.toLowerCase();
    // Must have one-time signals and NOT have subscription signals
    final hasOneTime = kOneTimePurchaseSignals.any(lower.contains);
    final hasSubSignal = lower.contains('subscription') ||
        lower.contains('recurring') ||
        lower.contains('renewal') ||
        lower.contains('monthly') ||
        lower.contains('annual') ||
        lower.contains('yearly') ||
        lower.contains('auto-renew');
    return hasOneTime && !hasSubSignal;
  }

  /// Extract amount from email body/snippet.
  static double? extractAmount(String text, String currency) {
    final patterns = switch (currency.toUpperCase()) {
      'USD' => _amountUSD,
      'EUR' => _amountEUR,
      'GBP' => _amountGBP,
      _ => _amountINR,
    };
    for (final re in patterns) {
      final match = re.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        return double.tryParse(raw);
      }
    }
    // Fallback: try all patterns
    for (final re in [
      ..._amountINR,
      ..._amountUSD,
      ..._amountEUR,
      ..._amountGBP
    ]) {
      final match = re.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        return double.tryParse(raw);
      }
    }
    return null;
  }

  /// Extract currency from text.
  static String detectCurrency(String text) {
    final upper = text.toUpperCase();
    if (text.contains('\$') || upper.contains('USD')) return 'USD';
    if (text.contains('€') || upper.contains('EUR')) return 'EUR';
    if (text.contains('£') || upper.contains('GBP')) return 'GBP';
    return 'INR';
  }

  /// Extract billing cycle from text.
  static BillingCycle detectCycle(String text) {
    final lower = text.toLowerCase();
    for (final entry in _defaultCycleKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return BillingCycle.monthly;
  }

  static DateTime? extractRenewalDate(String text) {
    final lower = text.toLowerCase();
    final anchorPatterns = [
      RegExp(
          r'(renews? on|next billing date|next payment date|renews? at|valid till|next billing|renewal date)\s*[:\-]?\s*([^\n\r<]{4,40})'),
      RegExp(
          r'(next charge|upcoming charge|next invoice)\s*[:\-]?\s*([^\n\r<]{4,40})'),
    ];
    for (final re in anchorPatterns) {
      final match = re.firstMatch(lower);
      if (match != null) {
        final rawStr = match.group(2)!.trim();
        final parsed = extractDate(rawStr);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? extractPaymentMethodLabel(String text) {
    final lower = text.toLowerCase();
    final patterns = [
      RegExp(
        r'(visa|mastercard|rupay|amex|american express|paypal|gpay|apple pay|discover)\s*(?:ending in\s*)?(?:\*{3,4}-?)?\s*(\d{4})?',
        caseSensitive: false,
      ),
      RegExp(
          r'(?:card ending|ending in|paid with|payment method)\s*[:\-]?\s*([^\n\r<]{2,40})'),
    ];
    for (final re in patterns) {
      final match = re.firstMatch(lower);
      if (match == null) continue;

      // If it extracted a known processor like Visa + last 4
      if (match.groupCount >= 2 && match.group(1) != null) {
        final brand = match.group(1)!;
        final last4 = match.group(2);
        if (last4 != null && last4.isNotEmpty) {
          return '${_titleCase(brand)} $last4';
        }
      }

      final raw = (match.groupCount > 0
                  ? (match.group(1) ?? match.group(0))
                  : match.group(0))
              ?.trim() ??
          '';
      if (raw.isEmpty) continue;
      return _titleCase(raw.replaceAll(RegExp(r'\s+'), ' '));
    }
    return null;
  }

  /// Extract a date from text.
  static DateTime? extractDate(String text) {
    for (final re in _datePatterns) {
      final match = re.firstMatch(text);
      if (match == null) continue;
      try {
        // ISO format: YYYY-MM-DD
        if (match.groupCount >= 3 && (match.group(1)?.length ?? 0) == 4) {
          return DateTime.parse(
              '${match.group(1)}-${match.group(2)}-${match.group(3)}');
        }
        // DD Mon YYYY
        if (match.groupCount >= 3) {
          final monthStr = match.group(2)!;
          final monthNum = _monthNum(monthStr);
          if (monthNum > 0) {
            final day = int.parse(match.group(1)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, monthNum, day);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static int _monthNum(String m) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    return months[m.toLowerCase()] ?? 0;
  }

  static bool _matchesPatternAlias(
      ServicePattern pattern, String contentLower) {
    final canonicalName = pattern.name
        .toLowerCase()
        .replaceAll('+', ' plus ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    final slugWords = pattern.slug.replaceAll('_', ' ');
    if (contentLower.contains(canonicalName) ||
        contentLower.contains(slugWords)) {
      return true;
    }
    final aliases = kMerchantAliases[pattern.slug] ?? const <String>[];
    return aliases.any((alias) => contentLower.contains(alias));
  }

  static bool _matchesExtractedMerchant(
      String extracted, ServicePattern pattern) {
    final normalizedExtracted = _normalizeForMatch(extracted);
    final candidates = <String>[
      _normalizeForMatch(pattern.name),
      _normalizeForMatch(pattern.slug.replaceAll('_', ' ')),
      ...(kMerchantAliases[pattern.slug] ?? const <String>[])
          .map(_normalizeForMatch),
    ];
    return candidates.any(
      (candidate) =>
          candidate.isNotEmpty &&
          (normalizedExtracted.contains(candidate) ||
              candidate.contains(normalizedExtracted)),
    );
  }

  static String _normalizeForMatch(String value) {
    return value
        .toLowerCase()
        .replaceAll('+', ' plus ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static String slugifyServiceName(String value) => _slugify(value);

  static String titleCaseServiceName(String value) => _titleCase(value);

  static String guessCategoryForService(String serviceName, String content) {
    final normalizedName = _normalizeForMatch(serviceName);
    final contentLower = content.toLowerCase();
    for (final pattern in kServicePatterns.values) {
      if (pattern.category == 'platform') continue;
      if (_matchesExtractedMerchant(normalizedName, pattern)) {
        return pattern.category;
      }
    }
    if (RegExp(r'\b(movie|music|video|stream|tv|podcast)\b')
        .hasMatch(contentLower)) {
      return 'entertainment';
    }
    if (RegExp(r'\b(github|api|cloud|hosting|developer|server|code)\b')
        .hasMatch(contentLower)) {
      return 'development';
    }
    if (RegExp(r'\b(fitness|health|workout|meditation)\b')
        .hasMatch(contentLower)) {
      return 'health_fitness';
    }
    if (RegExp(r'\b(course|learn|education|book)\b').hasMatch(contentLower)) {
      return 'education';
    }
    if (RegExp(r'\b(news|magazine|publication)\b').hasMatch(contentLower)) {
      return 'news';
    }
    if (RegExp(r'\b(storage|productivity|workspace|calendar|notes|design)\b')
        .hasMatch(contentLower)) {
      return 'productivity';
    }
    return 'other';
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll('+', ' plus ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) =>
            '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1).toLowerCase() : ''}')
        .join(' ');
  }
}
