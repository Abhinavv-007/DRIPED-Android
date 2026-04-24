import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 12 default category presets seeded on first signup.
/// Each one: distinct vivid colour + matching lucide icon + default slug.
class CategoryPreset {
  final String slug;
  final String name;
  final Color colour;
  final IconData icon;
  const CategoryPreset({
    required this.slug,
    required this.name,
    required this.colour,
    required this.icon,
  });
}

class CategoryPalette {
  CategoryPalette._();

  static const List<CategoryPreset> defaults = [
    CategoryPreset(
      slug: 'entertainment',
      name: 'Entertainment',
      colour: Color(0xFFE11D48), // rose-red
      icon: LucideIcons.tv,
    ),
    CategoryPreset(
      slug: 'music',
      name: 'Music',
      colour: Color(0xFF8B5CF6), // violet
      icon: LucideIcons.music2,
    ),
    CategoryPreset(
      slug: 'productivity',
      name: 'Productivity',
      colour: Color(0xFF3B82F6), // blue
      icon: LucideIcons.zap,
    ),
    CategoryPreset(
      slug: 'education',
      name: 'Education',
      colour: Color(0xFFF97316), // orange
      icon: LucideIcons.graduationCap,
    ),
    CategoryPreset(
      slug: 'health_fitness',
      name: 'Health & Fitness',
      colour: Color(0xFF10B981), // emerald
      icon: LucideIcons.heartPulse,
    ),
    CategoryPreset(
      slug: 'finance',
      name: 'Finance',
      colour: Color(0xFFEAB308), // gold-yellow
      icon: LucideIcons.landmark,
    ),
    CategoryPreset(
      slug: 'shopping',
      name: 'Shopping',
      colour: Color(0xFFEC4899), // pink
      icon: LucideIcons.shoppingBag,
    ),
    CategoryPreset(
      slug: 'development',
      name: 'Development',
      colour: Color(0xFF06B6D4), // cyan
      icon: LucideIcons.terminal,
    ),
    CategoryPreset(
      slug: 'utilities',
      name: 'Utilities',
      colour: Color(0xFF64748B), // slate
      icon: LucideIcons.plug,
    ),
    CategoryPreset(
      slug: 'gaming',
      name: 'Gaming',
      colour: Color(0xFF84CC16), // lime
      icon: LucideIcons.gamepad2,
    ),
    CategoryPreset(
      slug: 'news',
      name: 'News',
      colour: Color(0xFF14B8A6), // teal
      icon: LucideIcons.newspaper,
    ),
    CategoryPreset(
      slug: 'other',
      name: 'Other',
      colour: Color(0xFFA1A1AA), // zinc neutral
      icon: LucideIcons.tag,
    ),
  ];

  static CategoryPreset bySlug(String slug) => defaults.firstWhere(
        (c) => c.slug == slug,
        orElse: () => defaults.last,
      );
}
