import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;
  final Widget? child;

  const AppShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.shapeBorder,
    this.child,
  });

  const AppShimmer.circular({
    super.key,
    required this.width,
    required this.height,
    this.child,
  }) : borderRadius = 0,
       shapeBorder = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child:
          child ??
          Container(
            width: width,
            height: height,
            decoration: shapeBorder != null
                ? ShapeDecoration(color: Colors.white, shape: shapeBorder!)
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
          ),
    );
  }
}
