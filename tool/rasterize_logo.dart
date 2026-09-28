// One-off: rasterize assets/logo.svg to a 1024px PNG that flutter_launcher_icons
// can consume (the icon generator cannot decode SVG). Run with:
//   flutter test test/tool/rasterize_logo_test.dart
// The generated assets/logo_raster.png is the source; delete this test if the
// logo ever becomes a PNG.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rasterize logo.svg to 1024px PNG', (tester) async {
    const size = 1024.0;
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: size,
            height: size,
            child: RepaintBoundary(
              key: key,
              child: SvgPicture.asset('assets/logo.svg', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
    // Let the async SVG loader resolve and paint.
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();

    final out = File('assets/logo_raster.png')..writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('wrote ${out.path} (${bytes.length} bytes, ${size.toInt()}x${size.toInt()})');
    expect(bytes.length, greaterThan(0));
  });
}
