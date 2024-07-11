/*
 * Copyright (c) 2023-2024. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:async';
import 'dart:math';

import 'package:common/data/dto/machine/print_state_enum.dart';
import 'package:common/service/machine_service.dart';
import 'package:common/service/moonraker/klippy_service.dart';
import 'package:common/service/moonraker/printer_service.dart';
import 'package:common/service/setting_service.dart';
import 'package:common/service/ui/bottom_sheet_service_interface.dart';
import 'package:common/service/ui/dialog_service_interface.dart';
import 'package:common/ui/components/async_button_.dart';
import 'package:common/ui/components/async_guard.dart';
import 'package:common/ui/components/skeletons/card_title_skeleton.dart';
import 'package:common/ui/components/skeletons/range_selector_skeleton.dart';
import 'package:common/ui/components/spool_widget.dart';
import 'package:common/ui/mobileraker_icons.dart';
import 'package:common/util/extensions/async_ext.dart';
import 'package:common/util/extensions/double_extension.dart';
import 'package:common/util/extensions/object_extension.dart';
import 'package:common/util/extensions/ref_extension.dart';
import 'package:common/util/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/ui/components/range_selector.dart';
import 'package:mobileraker_pro/service/moonraker/spoolman_service.dart';
import 'package:mobileraker_pro/service/ui/pro_sheet_type.dart';
import 'package:mobileraker_pro/spoolman/dto/spool.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../service/ui/dialog_service_impl.dart';
import '../../../components/dialog/edit_form/num_edit_form_dialog.dart';
import '../../../components/dialog/filament_operation_dialog.dart';

part 'control_extruder_card.freezed.dart';
part 'control_extruder_card.g.dart';

class ControlExtruderCard extends HookConsumerWidget {
  const ControlExtruderCard({super.key, required this.machineUUID});

  static Widget preview() {
    return const _Preview();
  }

  final String machineUUID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    return AsyncGuard(
      animate: true,
      debugLabel: 'ControlExtruderCard-$machineUUID',
      toGuard: _controlExtruderCardControllerProvider(machineUUID).selectAs((value) => value.showCard),
      childOnLoading: const _ControlExtruderLoading(),
      childOnData: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _CardTitle(machineUUID: machineUUID),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: _CardBody(machineUUID: machineUUID),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends HookWidget {
  static const String _machineUUID = 'preview';

  const _Preview({super.key});

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    return ProviderScope(
      overrides: [
        _controlExtruderCardControllerProvider(_machineUUID).overrideWith(_ControlExtruderCardPreviewController.new),
      ],
      child: const ControlExtruderCard(machineUUID: _machineUUID),
    );
  }
}

class _ControlExtruderLoading extends StatelessWidget {
  const _ControlExtruderLoading({super.key});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    return Card(
      child: Shimmer.fromColors(
        baseColor: Colors.grey,
        highlightColor: themeData.colorScheme.background,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CardTitleSkeleton(),
            Padding(
              padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Extruder buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 40,
                          width: 104,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 40,
                          width: 104,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Step selecotr with title
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: SizedBox(
                          height: 19,
                          width: 142,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                        ),
                      ),
                      RangeSelectorSkeleton(itemCount: 5),
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
}

class _CardTitle extends ConsumerWidget {
  const _CardTitle({super.key, required this.machineUUID});

  final String machineUUID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var model = ref.watch(_controlExtruderCardControllerProvider(machineUUID).select((value) => value.requireValue));
    var controller = ref.watch(_controlExtruderCardControllerProvider(machineUUID).notifier);

    return ListTile(
      leading: const Icon(FlutterIcons.printer_3d_nozzle_outline_mco),
      title: Row(
        children: [
          const Text('pages.dashboard.control.extrude_card.title').tr(),
          AnimatedOpacity(
            opacity: model.minExtrudeTempReached ? 0 : 1,
            duration: kThemeAnimationDuration,
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Tooltip(
                triggerMode: TooltipTriggerMode.tap,
                margin: const EdgeInsets.symmetric(horizontal: 64.0),
                message: tr(
                  'pages.dashboard.control.extrude_card.cold_extrude_error',
                  args: [model.minExtrudeTemp.toStringAsFixed(0)],
                ),
                child: Icon(
                  Icons.severe_cold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
      trailing: model.extruderCount <= 1
          ? null
          : DropdownButton(
              value: model.extruderIndex,
              onChanged: model.klippyCanReceiveCommands ? controller.onExtruderSelected : null,
              items: List.generate(model.extruderCount, (index) {
                String name = tr('pages.dashboard.control.extrude_card.title');
                if (index > 0) name += ' $index';
                return DropdownMenuItem(value: index, child: Text(name));
              }),
            ),
    );
  }
}

class _CardBody extends ConsumerWidget {
  const _CardBody({super.key, required this.machineUUID});

  final String machineUUID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(_controlExtruderCardControllerProvider(machineUUID).select((value) => value.requireValue));
    final controller = ref.watch(_controlExtruderCardControllerProvider(machineUUID).notifier);

    final canExtrude = model.minExtrudeTempReached && model.klippyCanReceiveCommands;

    final themeData = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          overflowAlignment: OverflowBarAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(MobilerakerIcons.nozzle_unload),
              label: const Text(
                'pages.dashboard.control.extrude_card.retract',
              ).tr(),
              onPressed: canExtrude ? () => controller.onMoveE(true) : null,
            ),
            IconButton(
              onPressed: controller.onFeedrateButtonPressed,
              icon: const Icon(Icons.speed),
              color: themeData.colorScheme.primary,
            ),
            ElevatedButton.icon(
              icon: const Icon(MobilerakerIcons.nozzle_load),
              label: const Text(
                'pages.dashboard.control.extrude_card.extrude',
              ).tr(),
              onPressed: canExtrude ? () => controller.onMoveE() : null,
            ),
          ],
        ),
        Text(
          '${tr('pages.dashboard.control.extrude_card.extrude_len')} [mm]',
        ),
        const SizedBox(height: 8),
        RangeSelector(
          selectedIndex: model.stepIndex,
          onSelected: canExtrude ? controller.onSelectedStepChanged : null,
          values: [for (var step in model.steps) step.toString()],
        ),
        const SizedBox(height: 8),
        const Divider(),
        OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          overflowAlignment: OverflowBarAlignment.center,
          children: [
            AsyncOutlinedButton(
              onPressed: controller.onUnloadFilament.only(model.klippyCanReceiveCommands),
              child: const Text('general.unload').tr(),
            ),
            GestureDetector(
              onTap: controller.onSpoolManagement,
              child: SpoolWidget(
                height: 32,
                color: model.activeSpool?.filament.colorHex ?? themeData.colorScheme.secondary.hexCode.substring(2),
              ),
            ),
            AsyncOutlinedButton(
              onPressed: controller.onLoadFilament.only(model.klippyCanReceiveCommands),
              child: const Text('general.load').tr(),
            ),
          ],
        ),
      ],
    );
  }
}

@riverpod
class _ControlExtruderCardController extends _$ControlExtruderCardController {
  DialogService get _dialogService => ref.read(dialogServiceProvider);

  SettingService get _settingService => ref.read(settingServiceProvider);

  PrinterService get _printerService => ref.read(printerServiceProvider(machineUUID));

  BottomSheetService get _bottomSheetService => ref.read(bottomSheetServiceProvider);

  KeyValueStoreKey get _settingsKey => CompositeKey.keyWithString(UtilityKeys.extruderStepIndex, machineUUID);

  @override
  Stream<_Model> build(String machineUUID) async* {
    ref.keepAliveFor();
    // await Future.delayed(Duration(seconds: 5));

    logger.i('Building ControlExtruderCardController for $machineUUID');

    // The active extruder (Set via klipper/moonraker) is watched and based on it, the streams are constructed
    var activeExtruder =
        await ref.watch(printerProvider(machineUUID).selectAsync((data) => data.toolhead.activeExtruderIndex));

    var activeSpool = await ref.watch(activeSpoolProvider(machineUUID).selectAsync((s) => s));

    var showCard =
        ref.watchAsSubject(printerProvider(machineUUID).selectAs((data) => data.print.state != PrintState.printing));

    // Below is stream code to prevent to many controller rebuilds
    var klippy = ref.watchAsSubject(klipperProvider(machineUUID));
    var steps = ref.watchAsSubject(machineSettingsProvider(machineUUID).selectAs((data) => data.extrudeSteps));
    var printer = ref.watchAsSubject(printerProvider(machineUUID));

    var initialIndex = _settingService.readInt(_settingsKey, 0);
    var initialVelocity =
        await ref.watch(machineSettingsProvider(machineUUID).selectAsync((data) => data.extrudeFeedrate.toDouble()));

    yield* Rx.combineLatest4(
      klippy,
      printer,
      steps,
      showCard,
      (a, b, c, d) {
        var idx = state.whenData((value) => value.stepIndex).valueOrNull ?? initialIndex.clamp(0, c.length - 1);
        var velocity = state.whenData((value) => value.extruderVelocity).valueOrNull ?? initialVelocity;

        var minExtrudeTemp = b.configFile.extruderForIndex(activeExtruder)?.minExtrudeTemp ?? 170;
        return _Model(
          activeSpool: activeSpool,
          showCard: d,
          klippyCanReceiveCommands: a.klippyCanReceiveCommands,
          hasSpoolman: a.hasSpoolmanComponent,
          extruderCount: b.extruderCount,
          extruderIndex: activeExtruder,
          stepIndex: min(max(0, idx), c.length - 1),
          steps: c,
          minExtrudeTemp: minExtrudeTemp,
          minExtrudeTempReached: (b.extruders.elementAtOrNull(activeExtruder)?.temperature ?? 0) >= minExtrudeTemp,
          extruderVelocity: velocity,
        );
      },
    );
  }

  void onExtruderSelected(int? idx) {
    state = state.toLoading();
    if (idx != null) _printerService.activateExtruder(idx);
  }

  Future<void> onMoveE([bool isRetract = false]) async {
    var machineSettings = ref.read(machineSettingsProvider(machineUUID)).valueOrNull;
    if (machineSettings == null) return;

    var step = state.value?.let((it) => it.steps.elementAtOrNull(it.stepIndex));
    if (step == null) return;

    var velocity = state.value?.let((it) => it.extruderVelocity);
    if (velocity == null) return;

    HapticFeedback.selectionClick();
    await _printerService.moveExtruder(
      (isRetract ? step * -1 : step).toDouble(),
      velocity,
    );
  }

  void onSelectedStepChanged(int? index) {
    if (index == null) return;
    state = state.whenData((value) => value.copyWith(stepIndex: index));
    _settingService.writeInt(_settingsKey, index);
  }

  void onFeedrateButtonPressed() {
    var maxVelocity = ref
        .read(printerProvider(machineUUID).selectAs((data) => data.configFile.primaryExtruder?.maxExtrudeOnlyVelocity))
        .valueOrNull
        ?.floorToDouble();

    _dialogService
        .show(DialogRequest(
      type: ref.read(settingServiceProvider).readBool(AppSettingKeys.defaultNumEditMode)
          ? DialogType.numEdit
          : DialogType.rangeEdit,
      title: tr('dialogs.extruder_feedrate.title'),
      dismissLabel: tr('general.cancel'),
      actionLabel: tr('general.confirm'),
      data: NumberEditDialogArguments(
        current: state.requireValue.extruderVelocity,
        min: 0.1,
        max: maxVelocity ?? 20,
        fraction: 1,
      ),
    ))
        .then((value) {
      if (value != null && value.confirmed && value.data != null) {
        num v = value.data;
        state = state.whenData((s) => s.copyWith(extruderVelocity: v.toDouble().toPrecision(1)));
      }
    });
  }

  Future<void> onUnloadFilament() async {
    final extruderName =
        state.requireValue.extruderIndex > 0 ? 'extruder${state.requireValue.extruderIndex}' : 'extruder';

    _dialogService.show(DialogRequest(
        type: DialogType.filamentOperation,
        barrierDismissible: false,
        data: FilamentOperationDialogArgs(
          machineUUID: machineUUID,
          isLoad: false,
          extruder: extruderName,
        )));
  }

  Future<void> onLoadFilament() async {
    final extruderName =
        state.requireValue.extruderIndex > 0 ? 'extruder${state.requireValue.extruderIndex}' : 'extruder';

    _dialogService.show(DialogRequest(
        type: DialogType.filamentOperation,
        barrierDismissible: false,
        data: FilamentOperationDialogArgs(
          machineUUID: machineUUID,
          isLoad: true,
          extruder: extruderName,
        )));
  }

  void onSpoolManagement() {
    if (state.valueOrNull?.hasSpoolman != true) return;
    _bottomSheetService.show(BottomSheetConfig(
      type: ProSheetType.selectSpoolman,
      data: machineUUID,
      isScrollControlled: true,
    ));
  }
}

class _ControlExtruderCardPreviewController extends _ControlExtruderCardController {
  @override
  Stream<_Model> build(String machineUUID) {
    state = const AsyncValue.data(
      _Model(
        showCard: true,
        klippyCanReceiveCommands: true,
        extruderCount: 1,
        extruderIndex: 0,
        stepIndex: 0,
        steps: [1, 5, 10, 20, 50],
        minExtrudeTemp: 170,
        minExtrudeTempReached: true,
        extruderVelocity: 10,
      ),
    );

    return const Stream.empty();
  }

  @override
  void onExtruderSelected(int? idx) {
    // Do nothing preview
  }

  @override
  Future<void> onMoveE([bool isRetract = false]) async {
    // Do nothing preview
  }

  @override
  void onSelectedStepChanged(int? index) {
    state = state.whenData((value) => value.copyWith(stepIndex: index ?? 0));
  }

  @override
  void onFeedrateButtonPressed() {
    // Do nothing preview
  }

  @override
  Future<void> onUnloadFilament() async {
    // Do nothing preview
  }

  @override
  Future<void> onLoadFilament() async {
    // Do nothing preview
  }

  @override
  void onSpoolManagement() {
    // Do nothing preview
  }
}

@freezed
class _Model with _$Model {
  const factory _Model({
    required bool showCard,
    required bool klippyCanReceiveCommands,
    @Default(1) int extruderCount,
    required int extruderIndex,
    required int stepIndex,
    required List<int> steps,
    @Default(170) double minExtrudeTemp,
    @Default(false) bool minExtrudeTempReached,
    required double extruderVelocity,
    @Default(false) bool hasSpoolman,
    Spool? activeSpool,
  }) = __Model;
}
