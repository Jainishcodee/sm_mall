import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = (_controller.value * 2) - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.6 + shift, -0.2),
              end: Alignment(1.6 + shift, 0.2),
              colors: [AppColors.slate200, AppColors.card, AppColors.slate200],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const ProductGridSkeleton({
    super.key,
    required this.itemCount,
    required this.crossAxisCount,
    required this.childAspectRatio,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                height: 74,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              SizedBox(height: 8),
              SkeletonBox(height: 12, width: 90),
              SizedBox(height: 6),
              SkeletonBox(height: 10, width: 60),
              SizedBox(height: 10),
              SkeletonBox(height: 12, width: 45),
              Spacer(),
              SkeletonBox(
                height: 30,
                width: 56,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoryGridSkeleton extends StatelessWidget {
  final int itemCount;

  const CategoryGridSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const Column(
          children: [
            SkeletonBox(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            SizedBox(height: 8),
            SkeletonBox(height: 10, width: 48),
          ],
        );
      },
    );
  }
}

class ProductListSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: const Row(
            children: [
              SkeletonBox(
                width: 54,
                height: 54,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 130),
                    SizedBox(height: 8),
                    SkeletonBox(height: 12, width: 110),
                    SizedBox(height: 8),
                    SkeletonBox(height: 12, width: 70),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Column(
                children: [
                  SkeletonBox(
                    width: 22,
                    height: 22,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  SizedBox(height: 14),
                  SkeletonBox(
                    width: 22,
                    height: 22,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class CategoryHorizontalSkeleton extends StatelessWidget {
  final int itemCount;

  const CategoryHorizontalSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 68,
            child: Column(
              children: [
                SkeletonBox(
                  width: 68,
                  height: 56,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                SizedBox(height: 8),
                SkeletonBox(height: 10, width: 52),
              ],
            ),
          );
        },
      ),
    );
  }
}
