// lib/features/home/presentation/bloc/shell_tab_cubit.dart
//
// ShellTabCubit — manages the active bottom-navigation tab index.

import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit that owns the active shell tab index.
///
/// Consumers call [switchToTab] to programmatically switch tabs from anywhere
/// in the widget tree (e.g. PostCard switching to Profile tab on own-post tap).
class ShellTabCubit extends Cubit<int> {
  /// Creates a [ShellTabCubit] starting on tab 0 (Feed).
  ShellTabCubit() : super(0);

  /// Switches to the given [index].
  void switchToTab(int index) => emit(index);
}
