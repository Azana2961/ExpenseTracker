import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart'; // Adjust 'frontend' if your package name is different in pubspec.yaml

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const HostelExpenseApp());
    expect(find.text('June Overview'), findsNothing); // Basic test initialization
  });
}