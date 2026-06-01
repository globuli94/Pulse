import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Keyboard dismiss on tap outside', () {
    testWidgets('tap outside dismisses keyboard', (tester) async {
      // Create a minimal widget tree with GestureDetector wrapping TextField
      const testKey = Key('text-field');
      final textFieldFocus = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      key: testKey,
                      focusNode: textFieldFocus,
                      decoration: const InputDecoration(
                        hintText: 'Enter text',
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text('Tap outside'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      addTearDown(textFieldFocus.dispose);

      // Focus the TextField
      await tester.tap(find.byKey(testKey));
      await tester.pump();
      expect(textFieldFocus.hasFocus, isTrue);

      // Tap outside the TextField (on the Text widget area)
      await tester.tap(find.text('Tap outside'));
      await tester.pump();

      // Assert keyboard is dismissed (TextField loses focus)
      expect(textFieldFocus.hasFocus, isFalse);
    });

    testWidgets('existing tap targets still fire', (tester) async {
      bool buttonPressed = false;
      const textFieldKey = Key('text-field');
      const buttonKey = Key('button');
      final textFieldFocus = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      key: textFieldKey,
                      focusNode: textFieldFocus,
                      decoration: const InputDecoration(
                        hintText: 'Enter text',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      key: buttonKey,
                      onPressed: () {
                        buttonPressed = true;
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: const Text('Tap me'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      addTearDown(textFieldFocus.dispose);

      // Focus the TextField
      await tester.tap(find.byKey(textFieldKey));
      await tester.pump();
      expect(textFieldFocus.hasFocus, isTrue);

      // Tap the ElevatedButton
      await tester.tap(find.byKey(buttonKey));
      await tester.pump();

      // Assert button callback was invoked AND TextField lost focus
      expect(buttonPressed, isTrue);
      expect(textFieldFocus.hasFocus, isFalse);
    });
  });
}
