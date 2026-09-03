import 'package:bdo_event/core/util/helpers/input_field.dart';
import 'package:bdo_event/core/util/helpers/validation_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds the correct password visibility button state', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            visibilityButton(false, () => pressed++),
            visibilityButton(true, () => pressed++),
          ],
        ),
      ),
    );

    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.byTooltip('Hide password'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Hide password'));
    expect(pressed, 2);
  });

  testWidgets('builds a validated form field with the supplied properties', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Form(
          child: field(
            controller,
            'Password',
            Icons.lock_outline,
            TextInputType.visiblePassword,
            (value) => value == null || value.isEmpty ? 'Required' : null,
            obscureText: true,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(textField.controller, same(controller));
    // expect(textField.obscureText, isTrue);
    // expect(textField.keyboardType, TextInputType.visiblePassword);
    expect(find.text('Password'), findsOneWidget);

    final form = tester.widget<Form>(find.byType(Form));
    expect(form.key, isNull);
    controller.dispose();
  });
}
