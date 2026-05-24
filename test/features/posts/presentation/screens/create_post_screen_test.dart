import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/posts/presentation/bloc/create_post_bloc.dart';
import 'package:pulse/features/posts/presentation/screens/create_post_screen.dart';

class MockCreatePostBloc extends Mock implements CreatePostBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockXFile extends Mock implements XFile {
  MockXFile({required String path}) : _path = path;
  final String _path;

  @override
  String get path => _path;

  @override
  String get name => _path.split('/').last;
}

void main() {
  group('CreatePostScreen', () {
    late MockCreatePostBloc mockCreatePostBloc;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockCreatePostBloc = MockCreatePostBloc();
      mockAuthBloc = MockAuthBloc();
      when(() => mockCreatePostBloc.state).thenReturn(const CreatePostInitial());
      when(() => mockCreatePostBloc.stream).thenAnswer((_) => const Stream.empty());
      final mockUser = AppUser(uid: 'user-123', email: 'test@example.com', displayName: 'Test User');
      when(() => mockAuthBloc.state).thenReturn(Authenticated(mockUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CreatePostBloc>.value(value: mockCreatePostBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const CreatePostScreen(),
        ),
      );
    }

    testWidgets('renders text field for post content', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('renders submit button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('renders image picker button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());

      // Find the image picker button which is an OutlinedButton.icon with image icon
      expect(find.byIcon(Icons.image), findsOneWidget);
    });
  });
}
