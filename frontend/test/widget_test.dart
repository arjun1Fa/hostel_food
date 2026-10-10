import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test builds HostelFoodApp without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HostelFoodApp(),
      ),
    );
    expect(find.byType(HostelFoodApp), findsOneWidget);
  });
}
