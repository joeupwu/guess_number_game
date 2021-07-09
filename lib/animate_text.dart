import 'package:flutter/material.dart';

class AnimatedFlipText extends StatelessWidget {
  final String value;
  final Duration duration;
  final double size;
  final Color textColor;

  AnimatedFlipText({
    Key? key,
    required this.value,
    required this.duration,
    this.size = 100,
    this.textColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(value.length, (int i) {
        return _SingleDigitFlipCounter(
          key: ValueKey(i),
          value: value.substring(i, i + 1),
          duration: duration,
          height: size,
          width: size / 1.5,
          color: textColor,
        );
      }),
    );
  }
}

class _SingleDigitFlipCounter extends StatelessWidget {
  final String value;
  final Duration duration;
  final double height;
  final double width;
  final Color color;

  const _SingleDigitFlipCounter({
    Key? key,
    required this.value,
    required this.duration,
    required this.height,
    required this.width,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double charVal = value.codeUnitAt(0).toDouble();
    return TweenAnimationBuilder(
      tween: Tween(begin: charVal, end: charVal),
      duration: duration,
      builder: (context, double value, child) {
        final whole = value ~/ 1;
        final decimal = value - whole;
        return SizedBox(
          height: height,
          width: width,
          child: Stack(
            children: <Widget>[
              _buildSingleDigit(
                char: String.fromCharCode(whole),
                offset: height * decimal,
                opacity: 1 - decimal,
              ),
              _buildSingleDigit(
                char: String.fromCharCode(whole + 1),
                offset: height * decimal - height,
                opacity: decimal,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleDigit({
    required String char,
    required double offset,
    required double opacity,
  }) {
    return Positioned(
      bottom: offset,
      child: Text(
        char,
        style: TextStyle(
          fontSize: height,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }
}
