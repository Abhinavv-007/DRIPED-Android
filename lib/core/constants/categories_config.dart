/// Default category definitions used for seeding on first signup.
/// Matches the 12 presets in [CategoryPalette] and the backend seeds.
class CategoryConfig {
  final String slug;
  final String name;
  final String colourHex;
  final String iconName;

  const CategoryConfig({
    required this.slug,
    required this.name,
    required this.colourHex,
    required this.iconName,
  });
}

class CategoriesConfig {
  CategoriesConfig._();

  static const List<CategoryConfig> defaults = [
    CategoryConfig(slug: 'entertainment', name: 'Entertainment', colourHex: '#BF5AF2', iconName: 'tv'),
    CategoryConfig(slug: 'music',         name: 'Music',         colourHex: '#FF375F', iconName: 'music'),
    CategoryConfig(slug: 'productivity',  name: 'Productivity',  colourHex: '#0A84FF', iconName: 'briefcase'),
    CategoryConfig(slug: 'education',     name: 'Education',     colourHex: '#30D158', iconName: 'book-open'),
    CategoryConfig(slug: 'health_fitness',name: 'Health',        colourHex: '#FF6B6B', iconName: 'heart'),
    CategoryConfig(slug: 'finance',       name: 'Finance',       colourHex: '#FFD60A', iconName: 'trending-up'),
    CategoryConfig(slug: 'shopping',      name: 'Shopping',      colourHex: '#FF9F0A', iconName: 'shopping-bag'),
    CategoryConfig(slug: 'development',   name: 'Development',   colourHex: '#64D2FF', iconName: 'code-2'),
    CategoryConfig(slug: 'utilities',     name: 'Utilities',     colourHex: '#8E8E93', iconName: 'zap'),
    CategoryConfig(slug: 'gaming',        name: 'Gaming',        colourHex: '#32D74B', iconName: 'gamepad-2'),
    CategoryConfig(slug: 'news',          name: 'News',          colourHex: '#AC8E68', iconName: 'newspaper'),
    CategoryConfig(slug: 'other',         name: 'Other',         colourHex: '#636366', iconName: 'grid'),
  ];

  static CategoryConfig bySlug(String slug) => defaults.firstWhere(
        (c) => c.slug == slug,
        orElse: () => defaults.last,
      );
}
