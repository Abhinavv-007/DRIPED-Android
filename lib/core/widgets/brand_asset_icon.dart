import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/brand_asset_resolver.dart';

class BrandAssetIcon extends StatelessWidget {
  final Future<String?> assetPathFuture;
  final Widget fallback;
  final double size;
  final EdgeInsetsGeometry padding;

  const BrandAssetIcon({
    super.key,
    required this.assetPathFuture,
    required this.fallback,
    required this.size,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: assetPathFuture,
      builder: (context, snapshot) {
        final assetPath = snapshot.data;
        if (assetPath == null) {
          return SizedBox.square(dimension: size, child: Center(child: fallback));
        }

        return SizedBox.square(
          dimension: size,
          child: Padding(
            padding: padding,
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
          ),
        );
      },
    );
  }
}
