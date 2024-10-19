/*
 * Copyright (c) 2024. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/service/ui/bottom_sheet_service_interface.dart';
import 'package:common/ui/bottomsheet/mobileraker_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class ColorPickerSheet extends HookConsumerWidget {
  const ColorPickerSheet({super.key, this.initialColor});

  final String? initialColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<Color> hex = useValueNotifier(initialColor?.toColor() ?? Colors.orange);
    // 104ac5F

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: IntrinsicHeight(
          child: HueRingPicker(
            pickerColor: initialColor?.toColor() ?? Colors.orange,
            onColorChanged: (color) => hex.value = color,
            // colorPickerWidth: 300,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
      ),
    );

    final themeData = Theme.of(context);

    final title = PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        title: const Text('components.select_color_sheet.title').tr(),
      ),
    );

    final bottom = StickyBottomBarVisibility(
      child: Theme(
        data: themeData.copyWith(useMaterial3: false),
        child: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  style: ElevatedButton.styleFrom(
                      foregroundColor: themeData.colorScheme.primary, backgroundColor: themeData.colorScheme.surface),
                  onPressed: () {
                    Navigator.pop(context, BottomSheetResult.confirmed(null));
                  },
                  icon: const Icon(Icons.search_off),
                  tooltip: 'general.clear'.tr(),
                  // child: Text('general.clear').tr(),
                ),
                const Gap(8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, BottomSheetResult.confirmed(colorToHex(hex.value, enableAlpha: false)));
                    },
                    child: const Text('general.select').tr(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return MobilerakerSheet(
      padding: EdgeInsets.zero,
      useSafeArea: false,
      hasScrollable: true,
      child: SheetContentScaffold(
        resizeBehavior: const ResizeScaffoldBehavior.avoidBottomInset(maintainBottomBar: true),
        appBar: title,
        body: body,
        bottomBar: bottom,
      ),
    );
  }
}
