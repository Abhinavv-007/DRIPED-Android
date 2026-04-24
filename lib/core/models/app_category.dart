import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String userId;
  final String name;
  final String slug;
  final Color colour;
  final String iconName;
  final double? budgetLimit;
  final bool isDefault;

  const AppCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    required this.colour,
    required this.iconName,
    this.budgetLimit,
    this.isDefault = true,
  });

  AppCategory copyWith({
    String? name,
    Color? colour,
    String? iconName,
    double? budgetLimit,
  }) =>
      AppCategory(
        id: id,
        userId: userId,
        name: name ?? this.name,
        slug: slug,
        colour: colour ?? this.colour,
        iconName: iconName ?? this.iconName,
        budgetLimit: budgetLimit ?? this.budgetLimit,
        isDefault: isDefault,
      );

  String get colourHex =>
      '#${colour.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'slug': slug,
        'colour_hex': colourHex,
        'icon_name': iconName,
        'budget_limit': budgetLimit,
        'is_default': isDefault ? 1 : 0,
      };

  factory AppCategory.fromMap(Map<String, dynamic> m) => AppCategory(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String,
        slug: (m['slug'] as String?) ?? 'other',
        colour: _hex(m['colour_hex'] as String? ?? '#A1A1AA'),
        iconName: (m['icon_name'] as String?) ?? 'tag',
        budgetLimit: (m['budget_limit'] as num?)?.toDouble(),
        isDefault: (m['is_default'] as int? ?? 1) == 1,
      );

  static Color _hex(String hex) {
    final h = hex.replaceAll('#', '');
    final v = int.parse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return Color(v);
  }
}
