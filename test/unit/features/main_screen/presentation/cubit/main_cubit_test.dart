import 'package:bdo_event/features/main_screen/domain/entities/main_tab.dart';
import 'package:bdo_event/features/main_screen/presentation/cubit/main_screen_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selectTab updates the active main tab', () {
    final cubit = MainScreenCubit();

    cubit.selectTab(MainTab.profile);

    expect(cubit.state.currentTab, MainTab.profile);
    cubit.close();
  });

  test('selectTab ignores the current tab', () {
    final cubit = MainScreenCubit();
    final initialState = cubit.state;

    cubit.selectTab(MainTab.events);

    expect(cubit.state, same(initialState));
    cubit.close();
  });
}