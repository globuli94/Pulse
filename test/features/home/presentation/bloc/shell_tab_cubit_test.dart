import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/home/presentation/bloc/shell_tab_cubit.dart';

void main() {
  group('ShellTabCubit', () {
    test('initial state is 0', () {
      expect(ShellTabCubit().state, 0);
    });

    blocTest<ShellTabCubit, int>(
      'emits [1] when switchToTab(1) called',
      build: () => ShellTabCubit(),
      act: (cubit) => cubit.switchToTab(1),
      expect: () => [1],
    );

    blocTest<ShellTabCubit, int>(
      'emits [3] when switchToTab(3) called',
      build: () => ShellTabCubit(),
      act: (cubit) => cubit.switchToTab(3),
      expect: () => [3],
    );
  });
}
