import 'dart:math' as math;
import 'package:flutter/material.dart';

class CustomColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const CustomColorPickerDialog({
    super.key,
    required this.initialColor,
  });

  static Future<Color?> show(BuildContext context, {Color initialColor = const Color(0xFF3B82F6)}) {
    return showDialog<Color>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) => CustomColorPickerDialog(initialColor: initialColor),
    );
  }

  @override
  State<CustomColorPickerDialog> createState() => _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<CustomColorPickerDialog> {
  late double _hue; // 0..360
  late double _saturation; // 0..1
  late double _value; // 0..1

  @override
  void initState() {
    super.initState();
    final HSVColor hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _currentColor {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
  }

  Color get _pureHueColor {
    return HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor();
  }

  String get _hexString {
    final Color c = _currentColor;
    final int r = (c.r * 255.0).round().clamp(0, 255).toInt();
    final int g = (c.g * 255.0).round().clamp(0, 255).toInt();
    final int b = (c.b * 255.0).round().clamp(0, 255).toInt();
    final int argb = (0xFF << 24) | (r << 16) | (g << 8) | b;
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2).toLowerCase()}';
  }

  void _onWheelPan(Offset localPos, double size) {
    final Offset center = Offset(size / 2, size / 2);
    final double dx = localPos.dx - center.dx;
    final double dy = localPos.dy - center.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double radius = size / 2;

    double angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    setState(() {
      _hue = angle.clamp(0.0, 360.0).toDouble();
      _saturation = (dist / radius).clamp(0.0, 1.0).toDouble();
    });
  }

  void _onSliderPan(Offset localPos, double height) {
    setState(() {
      _value = (1.0 - (localPos.dy / height)).clamp(0.0, 1.0).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 170;
    const double sliderWidth = 24;
    const double sliderHeight = 170;

    final Color curr = _currentColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E26), // Dark background matching screenshot
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: Title "Color"
            const Text(
              'Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 18),

            // Middle: Wheel + Vertical Brightness Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Circular Color Wheel
                GestureDetector(
                  onPanDown: (DragDownDetails d) => _onWheelPan(d.localPosition, wheelSize),
                  onPanUpdate: (DragUpdateDetails d) => _onWheelPan(d.localPosition, wheelSize),
                  child: SizedBox(
                    width: wheelSize,
                    height: wheelSize,
                    child: CustomPaint(
                      painter: _ColorWheelPainter(
                        hue: _hue,
                        saturation: _saturation,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Vertical Value / Brightness Slider
                GestureDetector(
                  onPanDown: (DragDownDetails d) => _onSliderPan(d.localPosition, sliderHeight),
                  onPanUpdate: (DragUpdateDetails d) => _onSliderPan(d.localPosition, sliderHeight),
                  child: Container(
                    width: sliderWidth,
                    height: sliderHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: <Color>[_pureHueColor, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        Positioned(
                          top: ((1.0 - _value) * (sliderHeight - 14)).clamp(0.0, sliderHeight - 14).toDouble(),
                          left: -2,
                          right: -2,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action row: Swatch, Check, Close, Hex code box
            Row(
              children: <Widget>[
                // Selected color preview swatch
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: curr,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                ),
                const SizedBox(width: 14),

                // Confirm Check icon button
                IconButton(
                  onPressed: () => Navigator.pop(context, _currentColor),
                  icon: const Icon(Icons.check, color: Colors.white, size: 24),
                  tooltip: 'Chọn màu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),

                // Cancel icon button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                  tooltip: 'Hủy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),

                // Hex box (e.g. #87d7ff)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C36),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _hexString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // RGB and HSV boxes
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF14141A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: <Widget>[
                  // Row 1: RGB
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _buildValueItem('R', '${(curr.r * 255.0).round().clamp(0, 255).toInt()}'),
                      _buildValueItem('G', '${(curr.g * 255.0).round().clamp(0, 255).toInt()}'),
                      _buildValueItem('B', '${(curr.b * 255.0).round().clamp(0, 255).toInt()}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2: HSV
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _buildValueItem('H', '${_hue.round()}'),
                      _buildValueItem('S', _saturation.toStringAsFixed(2)),
                      _buildValueItem('V', _value == 1.0 ? '1' : _value.toStringAsFixed(2)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueItem(String label, String val) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF24242F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double hue;
  final double saturation;

  _ColorWheelPainter({
    required this.hue,
    required this.saturation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    const SweepGradient sweepGradient = SweepGradient(
      colors: <Color>[
        Color(0xFFFF0000), // Red
        Color(0xFFFFFF00), // Yellow
        Color(0xFF00FF00), // Green
        Color(0xFF00FFFF), // Cyan
        Color(0xFF0000FF), // Blue
        Color(0xFFFF00FF), // Magenta
        Color(0xFFFF0000), // Red
      ],
      stops: <double>[0.0, 0.166, 0.333, 0.5, 0.666, 0.833, 1.0],
    );

    final Paint sweepPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sweepPaint);

    // Radial white overlay for saturation
    final RadialGradient radialGradient = RadialGradient(
      colors: <Color>[Colors.white, Colors.white.withValues(alpha: 0.0)],
      stops: const <double>[0.0, 1.0],
    );
    final Paint radialPaint = Paint()
      ..shader = radialGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, radialPaint);

    // Draw cursor circle
    final double angleRad = hue * math.pi / 180;
    final double dist = saturation * radius;
    final Offset cursorOffset = Offset(
      center.dx + dist * math.cos(angleRad),
      center.dy + dist * math.sin(angleRad),
    );

    final Paint cursorOutlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(cursorOffset, 6, cursorOutlinePaint);

    final Paint cursorInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(cursorOffset, 5, cursorInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.hue != hue || oldDelegate.saturation != saturation;
  }
}
