import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

ImageProvider getImageProvider(String url) {
  if (url.isEmpty) {
    return const AssetImage('assets/placeholder.png'); // Fallback placeholder if empty
  }
  if (url.startsWith('http') || url.startsWith('blob:') || kIsWeb) {
    return NetworkImage(url);
  } else {
    return FileImage(File(url));
  }
}

Widget buildCustomImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover, Widget? errorWidget}) {
  if (url.isEmpty) {
    return errorWidget ?? Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood_rounded));
  }

  final fallback = errorWidget ?? Container(
    width: width,
    height: height,
    color: const Color(0xFFFFF0E6),
    child: const Icon(Icons.fastfood_rounded, color: Color(0xFFE8612C)),
  );

  if (url.startsWith('http') || url.startsWith('blob:') || kIsWeb) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  } else {
    return Image.file(
      File(url),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
