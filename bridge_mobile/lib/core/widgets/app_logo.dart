import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/constants/asset_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showLabel;
  final String labelText;

  const AppLogo({
    super.key,
    this.size = 64.0,
    this.showLabel = true,
    this.labelText = 'Bridge Mobile',
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$labelText Logo',
          child: SvgPicture.string(
            AssetConstants.rawAppLogoSvg,
            width: size,
            height: size,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 12),
          Text(
            labelText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ],
    );
  }
}
