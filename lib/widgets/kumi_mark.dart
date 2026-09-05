import 'package:flutter/material.dart';

/// The Kumi logo, rendered from the bundled `logo.png` asset. Used on the
/// splash screen, the sidebar, and the About page.
class KumiMark extends StatelessWidget {
  const KumiMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset('logo.png', fit: BoxFit.contain),
    );
  }
}