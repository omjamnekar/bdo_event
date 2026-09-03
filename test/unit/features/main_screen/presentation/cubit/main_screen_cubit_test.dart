import 'package:bdo_event/features/main_screen/domain/entities/main_tab.dart';
import 'package:bdo_event/features/main_screen/presentation/cubit/main_screen_cubit.dart';
import 'package:bdo_event/features/main_screen/presentation/cubit/main_screen_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts loading on the events tab', () {
    final cubit = MainScreenCubit();

    expect(cubit.state.status, MainScreenStatus.loading);
    expect(cubit.state.currentTab, MainTab.events);
    cubit.close();
  });

  test('finishes loading without changing the selected tab', () {
    final cubit = MainScreenCubit();

    cubit.finishLoading();

    expect(cubit.state.status, MainScreenStatus.ready);
    expect(cubit.state.currentTab, MainTab.events);
    cubit.close();
  });

  test('selects every available tab', () {
    final cubit = MainScreenCubit();

    for (final tab in MainTab.values) {
      cubit.selectTab(tab);
      expect(cubit.state.currentTab, tab);
    }

    cubit.close();
  });

  test('does not emit when selecting the current tab', () async {
    final cubit = MainScreenCubit();
    final states = <MainScreenState>[];
    final subscription = cubit.stream.listen(states.add);

    cubit.selectTab(MainTab.events);
    await Future<void>.delayed(Duration.zero);

    expect(states, isEmpty);
    await subscription.cancel();
    await cubit.close();
  });

  test('does not emit after closing when finishing loading', () async {
    final cubit = MainScreenCubit();
    await cubit.close();

    cubit.finishLoading();

    expect(cubit.isClosed, isTrue);
  });
}
