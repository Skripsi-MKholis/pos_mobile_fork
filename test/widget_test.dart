import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:pos_mobile/main.dart";

void main() {
  testWidgets("Smoke test for provider scope", (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
  });
}
