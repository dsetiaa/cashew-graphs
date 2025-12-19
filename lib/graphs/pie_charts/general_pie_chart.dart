import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:cashew_graphs/presentation/resources/app_colours.dart';
import 'package:cashew_graphs/presentation/resources/app_spacing.dart';
import 'package:cashew_graphs/presentation/resources/app_typography.dart';
import 'package:cashew_graphs/database/tables.dart';
import 'package:cashew_graphs/logic/helpers.dart';


class GeneralPieChart extends StatefulWidget {
  const GeneralPieChart({
    required this.data,
    required this.totalSpent,
    super.key});

  final List<CategoryWithTotal> data;
  final double totalSpent;

  @override
  State<StatefulWidget> createState() => _GeneralPieChartState();
}

class _GeneralPieChartState extends State<GeneralPieChart> {
  int touchedIndex = -1;

  Color _getCategoryColor(int index) {
    return widget.data[index].category.colour != null
        ? Color(int.parse(widget.data[index].category.colour!.substring(4), radix: 16) + 0xFF000000)
        : Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: showingSections(),
                  startDegreeOffset: -90,
                ),
              ),
              // Center content - total amount
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '₹${widget.totalSpent.toStringAsFixed(0)}',
                    style: AppTypography.titleLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Horizontal legend
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: List.generate(
            widget.data.length >= 5 ? 5 : widget.data.length,
            (i) => _buildLegendItem(i),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(int index) {
    final color = _getCategoryColor(index);
    final isSelected = touchedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            widget.data[index].category.name,
            style: AppTypography.legendText.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // List<PieChartSectionData> showingSections() {
  //   return List.generate(4, (i) {
  //     final isTouched = i == touchedIndex;
  //     final fontSize = isTouched ? 25.0 : 16.0;
  //     final radius = isTouched ? 60.0 : 50.0;
  //     const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
  //     return switch (i) {
  //       0 => PieChartSectionData(
  //         color: AppColors.contentColorBlue,
  //         value: 40,
  //         title: '40%',
  //         radius: radius,
  //         titleStyle: TextStyle(
  //           fontSize: fontSize,
  //           fontWeight: FontWeight.bold,
  //           color: AppColors.mainTextColor1,
  //           shadows: shadows,
  //         ),
  //       ),
  //       1 => PieChartSectionData(
  //         color: AppColors.contentColorYellow,
  //         value: 30,
  //         title: '30%',
  //         radius: radius,
  //         titleStyle: TextStyle(
  //           fontSize: fontSize,
  //           fontWeight: FontWeight.bold,
  //           color: AppColors.mainTextColor1,
  //           shadows: shadows,
  //         ),
  //       ),
  //       2 => PieChartSectionData(
  //         color: AppColors.contentColorPurple,
  //         value: 15,
  //         title: '15%',
  //         radius: radius,
  //         titleStyle: TextStyle(
  //           fontSize: fontSize,
  //           fontWeight: FontWeight.bold,
  //           color: AppColors.mainTextColor1,
  //           shadows: shadows,
  //         ),
  //       ),
  //       3 => PieChartSectionData(
  //         color: AppColors.contentColorGreen,
  //         value: 15,
  //         title: '15%',
  //         radius: radius,
  //         badgeWidget: ,
  //         titleStyle: TextStyle(
  //           fontSize: fontSize,
  //           fontWeight: FontWeight.bold,
  //           color: AppColors.mainTextColor1,
  //           shadows: shadows,
  //         ),
  //       ),
  //       _ => throw StateError('Invalid'),
  //     };
  //   });
  // }

  List<PieChartSectionData> showingSections() {
    return List.generate(widget.data.length, (i) {
      final bool isTouched = i == touchedIndex;
      final double radius = isTouched ? 55.0 : 50.0;
      final Color color = _getCategoryColor(i);

      double percent = widget.totalSpent == 0
          ? 0
          : (widget.data[i].total / widget.totalSpent * 100).abs();

      return PieChartSectionData(
        color: color,
        value: widget.totalSpent == 0
            ? 5
            : (widget.data[i].total / widget.totalSpent).abs(),
        title: isTouched ? '${percent.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.contentColorWhite,
          fontWeight: FontWeight.w600,
        ),
        titlePositionPercentageOffset: 0.55,
        borderSide: isTouched
            ? const BorderSide(color: AppColors.contentColorWhite, width: 2)
            : BorderSide.none,
      );
    });
  }
}

// class _Badge extends StatelessWidget {
//   final double scale;
//   final Color color;
//   final String iconName;
//   final String? emojiIconName;
//   final double percent;
//   final bool isTouched;
//   final bool showLabels;
//   final Color categoryColor;
//   final double totalPercentAccumulated;
//
//   const _Badge({
//     Key? key,
//     required this.scale,
//     required this.color,
//     required this.iconName,
//     required this.emojiIconName,
//     required this.percent,
//     required this.isTouched,
//     required this.showLabels,
//     required this.categoryColor,
//     required this.totalPercentAccumulated,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     bool showIcon = percent.abs() < 5;
//     return AnimatedScale(
//       curve: showIcon ? Curves.easeInOutCubicEmphasized : ElasticOutCurve(0.6),
//       duration:
//       showIcon ? Duration(milliseconds: 700) : Duration(milliseconds: 1300),
//       scale: showIcon && isTouched == false
//           ? 0
//           : (showLabels || isTouched ? (showIcon ? 1 : scale) : 0),
//       child: AnimatedSwitcher(
//         duration: Duration(milliseconds: 500),
//         child: Container(
//           key: ValueKey(iconName),
//           height: 45,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: color,
//               width: 2.5,
//             ),
//           ),
//           child: Stack(
//             alignment: AlignmentDirectional.center,
//             children: [
//               AnimatedOpacity(
//                 duration: Duration(milliseconds: 200),
//                 opacity: this.scale == 1 ? 0 : 1,
//                 child: Center(
//                   child: Transform.translate(
//                     offset: Offset(
//                       0,
//                       // Prevent overlapping labels when displayed on top
//                       // Divider percent by 2, because the label is in the middle
//                       // This means any label location that is past 50% will change orientation
//                       totalPercentAccumulated - percent / 2 < 50 ? -34 : 34,
//                     ),
//                     child: IntrinsicWidth(
//                       child: Container(
//                         height: 20,
//                         padding: EdgeInsetsDirectional.symmetric(horizontal: 5),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadiusDirectional.circular(5),
//                           border: Border.all(
//                             color: color,
//                             width: 1.5,
//                           ),
//                           color: Theme.of(context).colorScheme.background,
//                         ),
//                         child: Center(
//                           child: MediaQuery(
//                             child: TextFont(
//                               text: convertToPercent(percent),
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                               textAlign: TextAlign.center,
//                             ),
//                             data: MediaQuery.of(context)
//                                 .copyWith(textScaleFactor: 1.0),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Container(
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Theme.of(context).colorScheme.background,
//                 ),
//                 child: Center(
//                   // child: SimpleShadow(
//                   //   child: Image(
//                   //     image: assetImage,
//                   //     width: 23,
//                   //   ),
//                   //   opacity: 0.8,
//                   //   color: categoryColor,
//                   //   offset: Offset(0, 0),
//                   //   sigma: 1,
//                   // ),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).brightness == Brightness.light
//                           ? dynamicPastel(context, categoryColor,
//                           amountLight: 0.55, amountDark: 0.35)
//                           : Colors.transparent,
//                       shape: BoxShape.circle,
//                     ),
//                     padding: EdgeInsetsDirectional.all(8),
//                     child: emojiIconName != null
//                         ? Container()
//                         : CacheCategoryIcon(
//                       iconName: iconName,
//                       size: 34,
//                     ),
//                   ),
//                 ),
//               ),
//               emojiIconName != null
//                   ? EmojiIcon(
//                 emojiIconName: emojiIconName,
//                 size: 34 * 0.7,
//               )
//                   : SizedBox.shrink(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class EmojiIcon extends StatelessWidget {
//   const EmojiIcon({
//     required this.emojiIconName,
//     required this.size,
//     this.correctionPaddingBottom,
//     this.emojiScale = 1,
//     super.key,
//   });
//   final String? emojiIconName;
//   final double size;
//   final double? correctionPaddingBottom;
//   final double emojiScale;
//
//   @override
//   Widget build(BuildContext context) {
//     return MediaQuery(
//       data: MediaQueryData(textScaleFactor: 1),
//       child: IgnorePointer(
//         child: Padding(
//           padding: EdgeInsetsDirectional.only(
//               bottom: size * 0.185 - (correctionPaddingBottom ?? 0)),
//           child: Transform.scale(
//             scale: emojiScale,
//             child: TextFont(
//               text: emojiIconName ?? "",
//               textAlign: TextAlign.center,
//               fontSize: size,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class CacheCategoryIcon extends StatefulWidget {
//   const CacheCategoryIcon({
//     required this.iconName,
//     required this.size,
//     super.key,
//   });
//   final String iconName;
//   final double size;
//   @override
//   State<CacheCategoryIcon> createState() => _CacheCategoryIconState();
// }
//
// class _CacheCategoryIconState extends State<CacheCategoryIcon> {
//   late Image image;
//
//   @override
//   void initState() {
//     super.initState();
//     image = Image.asset(
//       "assets/categories/" + widget.iconName,
//       width: widget.size,
//     );
//   }
//
//   @override
//   void didUpdateWidget(covariant CacheCategoryIcon oldWidget) {
//     if (widget.iconName != oldWidget.iconName ||
//         widget.size != oldWidget.size) {
//       setState(() {
//         image = Image.asset(
//           "assets/categories/" + widget.iconName,
//           width: widget.size,
//         );
//       });
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     precacheImage(image.image, context);
//     super.didChangeDependencies();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return image;
//   }
// }
