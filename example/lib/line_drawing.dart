import 'package:artemis_camera_kit/artemis_camera_kit_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LineDrawing extends StatelessWidget {
  final List<OcrLine> lines;

  const LineDrawing({Key? key, required this.lines}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: CustomPaint(
          painter: LogoPainter(lines),
        ),
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  final List<OcrLine> lines;

  LogoPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 0.0;
    var maxx = 0.0;
    var maxy = 0.0;
    var minx = 0.0;
    var miny = 0.0;
    for (var l in lines) {
      for (var c in l.cornerPoints) {
        if (c.x > maxx) maxx = c.x;
        if (c.y > maxy) maxy = c.y;
        if (c.x < minx || minx == 0) minx = c.x;
        if (c.y < miny || miny == 0) miny = c.y;
      }
    }
    // print(maxx);
    // print(maxy);
    // print(minx);
    // print(miny);
    // print(Get.height);
    // print(Get.width);
    for (var l in lines) {
      for (var c in l.cornerPoints) {
        c.y = maxy - c.y;
        c.x = c.x * Get.height / maxx;
        c.y = c.y * Get.width / maxy;
      }
    }
    for (var l in lines) {
      final Path quadPath = Path()
        ..moveTo(l.cornerPoints[0].y, l.cornerPoints[0].x)
        ..lineTo(l.cornerPoints[1].y, l.cornerPoints[1].x)
        ..lineTo(l.cornerPoints[2].y, l.cornerPoints[2].x)
        ..lineTo(l.cornerPoints[3].y, l.cornerPoints[3].x)
        ..lineTo(l.cornerPoints[0].y, l.cornerPoints[0].x);
      canvas.drawPath(quadPath, paint);
      paint.color = Colors.red;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
