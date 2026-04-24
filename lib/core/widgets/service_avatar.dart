import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/services_catalog.dart';
import '../theme/app_colors.dart';
import '../utils/brand_asset_resolver.dart';
import '../utils/custom_brand_logo_store.dart';

/// Circular avatar for a service. Coloured fill + brand-coloured glow
/// + lucide icon or monogram on top.
class ServiceAvatar extends StatelessWidget {
  final String serviceSlug;
  final String serviceName;
  final double size;
  final bool glow;
  final Color? overrideColour;

  const ServiceAvatar({
    super.key,
    required this.serviceSlug,
    required this.serviceName,
    this.size = 44,
    this.glow = true,
    this.overrideColour,
  });

  @override
  Widget build(BuildContext context) {
    final pattern = ServicesCatalog.bySlug(serviceSlug);
    final colour =
        overrideColour ?? pattern?.brandColour ?? const Color(0xFF64748B);
    final icon = pattern?.fallbackIcon;
    final mono = (serviceName.isNotEmpty ? serviceName[0] : '?').toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetFuture = BrandAssetResolver.serviceAsset(
      serviceSlug: serviceSlug,
      serviceName: serviceName,
    );
    final customLogoUrl = CustomBrandLogoStore.logoUrlForSlug(serviceSlug);

    return Semantics(
      label: '$serviceName subscription logo',
      child: FutureBuilder<String?>(
        future: assetFuture,
        builder: (context, snapshot) {
          final assetPath = snapshot.data;
          final hasBrandAsset = assetPath != null || customLogoUrl != null;
          final decoration = hasBrandAsset
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.inkRaised : AppColors.lightCard,
                  boxShadow: [
                    if (glow)
                      BoxShadow(
                        color: colour.withOpacity(0.24),
                        blurRadius: size * 0.42,
                        spreadRadius: 0,
                      ),
                    BoxShadow(
                      color:
                          AppColors.shadowInk.withOpacity(isDark ? 0.28 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: hasBrandAsset
                        ? colour.withOpacity(0.30)
                        : Colors.white.withOpacity(0.08),
                    width: hasBrandAsset ? 1.2 : 1,
                  ),
                )
              : BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.alphaBlend(Colors.white.withOpacity(0.15), colour),
                      colour,
                    ],
                    radius: 0.85,
                    focal: Alignment.topLeft,
                    focalRadius: 0.1,
                  ),
                  boxShadow: [
                    if (glow)
                      BoxShadow(
                        color: colour.withOpacity(0.35),
                        blurRadius: size * 0.5,
                        spreadRadius: 0,
                      ),
                    BoxShadow(
                      color: AppColors.shadowInk.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                );

          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: decoration,
            child: assetPath != null
                ? Padding(
                    padding: EdgeInsets.all(size * 0.18),
                    child: BrandAssetResolver.isSvgAsset(assetPath)
                        ? SvgPicture.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          )
                        : Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                          ),
                  )
                : customLogoUrl != null
                    ? Padding(
                        padding: EdgeInsets.all(size * 0.18),
                        child: Image.network(
                          customLogoUrl,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => icon != null
                              ? Icon(
                                  icon,
                                  color: _contrastingForeground(colour),
                                  size: size * 0.48,
                                )
                              : Text(
                                  mono,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _contrastingForeground(colour),
                                    fontSize: size * 0.42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                        ),
                      )
                : icon != null
                    ? Icon(
                        icon,
                        color: _contrastingForeground(colour),
                        size: size * 0.48,
                      )
                    : Text(
                        mono,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _contrastingForeground(colour),
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
          );
        },
      ),
    );
  }

  static Color _contrastingForeground(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.6 ? AppColors.ink : Colors.white;
  }
}
