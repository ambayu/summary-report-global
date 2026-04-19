import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.brandName,
    this.logoBase64,
    this.radius = 22,
  });

  final String brandName;
  final String? logoBase64;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = _tryDecodeLogo(logoBase64);
    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
        backgroundColor: Colors.white,
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Text(brandInitial(brandName)),
    );
  }

  static String brandInitial(String brandName) {
    final text = brandName.trim();
    if (text.isEmpty) return 'SC';
    final parts = text.split(RegExp(r'\s+')).where((item) => item.isNotEmpty);
    if (parts.isEmpty) return 'SC';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Uint8List? tryDecodeLogo(String? logoBase64) {
    return _tryDecodeLogo(logoBase64);
  }

  static Uint8List? _tryDecodeLogo(String? logoBase64) {
    if (logoBase64 == null || logoBase64.isEmpty) return null;
    try {
      return base64Decode(logoBase64);
    } catch (_) {
      return null;
    }
  }
}
