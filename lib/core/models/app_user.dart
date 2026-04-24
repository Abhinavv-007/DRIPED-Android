class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String currency;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.currency = 'INR',
    required this.createdAt,
  });

  String get firstName {
    final n = (fullName ?? '').trim();
    if (n.isEmpty) return 'there';
    return n.split(RegExp(r'\s+')).first;
  }

  AppUser copyWith({
    String? fullName,
    String? avatarUrl,
    String? currency,
  }) =>
      AppUser(
        id: id,
        email: email,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        currency: currency ?? this.currency,
        createdAt: createdAt,
      );

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        email: m['email'] as String,
        fullName: m['full_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        currency: (m['currency'] as String?) ?? 'INR',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
      };
}
