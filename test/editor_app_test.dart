import 'package:flutter_test/flutter_test.dart';
import 'package:memoria_editor_custom/main.dart';

void main() {
  testWidgets('Editor loads main window', (tester) async {
    await tester.pumpWidget(const EditorApp(isSubWindow: false));
    expect(find.text('Memoria Editor — Main'), findsOneWidget);
  });
}

