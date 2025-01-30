/*
 * Copyright (c) 2023-2025. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/data/model/time_series_entry.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphCardWithButton extends StatelessWidget {
  static const double radius = 15;

  const GraphCardWithButton({
    super.key,
    this.backgroundColor,
    this.graphColor,
    required this.tempStore,
    required this.topChild,
    required this.buttonChild,
    required this.onTap,
    this.onLongPress,
    this.onTapGraph,
  });

  final Color? backgroundColor;
  final Color? graphColor;
  final Widget topChild;
  final Widget buttonChild;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapGraph;
  final List<TemperatureSensorSeriesEntry> tempStore;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var bgColor = backgroundColor ?? themeData.colorScheme.surfaceContainer;
    var gcColor =
        graphColor ?? ((Theme.of(context).brightness == Brightness.dark) ? bgColor.brighten(15) : bgColor.darken(15));
    var onBackgroundColor = (ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? Colors.white.blendAlpha(themeData.colorScheme.primary.brighten(20), 0)
        : Colors.black.blendAlpha(themeData.colorScheme.primary.brighten(20), 0));

    return Padding(
      padding: CardTheme.of(context).margin ?? const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onTapGraph,
            child: Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned.fill(
                      top: radius,
                      child: _Chart(
                        graphColor: gcColor,
                        tempStore: tempStore,
                      )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                    child: Theme(
                      data: themeData.copyWith(
                        textTheme: themeData.textTheme.apply(
                          bodyColor: onBackgroundColor,
                          displayColor: onBackgroundColor,
                        ),
                        iconTheme: themeData.iconTheme.copyWith(color: onBackgroundColor),
                      ),
                      child: topChild,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              maximumSize: const Size.fromHeight(48),
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
              ),
              foregroundColor: themeData.colorScheme.onPrimary,
              backgroundColor: themeData.colorScheme.primary,
              // onPrimary: Theme.of(context).colorScheme.onSecondary,
              disabledForegroundColor: themeData.colorScheme.onPrimary.withOpacity(0.38),
            ),
            onPressed: onTap,
            onLongPress: onLongPress,
            child: buttonChild,
          ),
        ],
      ),
    );
  }
}

class _Chart extends ConsumerWidget {
  const _Chart({
    super.key,
    required this.graphColor,
    required this.tempStore,
  });

  final Color graphColor;

  final List<TemperatureSensorSeriesEntry> tempStore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(isVisible: false),
      primaryYAxis: NumericAxis(
        isVisible: false,
        minimum: 0,
        rangePadding: ChartRangePadding.none,
      ),
      plotAreaBorderWidth: 0,
      plotAreaBorderColor: Colors.transparent,
      margin: const EdgeInsets.all(0),
      series: [
        AreaSeries(
          // Disables animation
          animationDuration: 0,
          color: graphColor,
          dataSource: tempStore,
          xValueMapper: (point, _) => point.time,
          yValueMapper: (point, _) => (point as TemperatureSensorSeriesEntry).temperature,
        ),
      ],
    );
  }
}
