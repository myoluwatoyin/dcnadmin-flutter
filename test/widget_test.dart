import 'package:dcnadmin/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Firebase-ready app shell', (tester) async {
    await tester.pumpWidget(const DcnAdminApp());

    expect(find.text('DCN Admin'), findsOneWidget);
    expect(find.text('DCN Admin mobile app'), findsOneWidget);
    expect(
      find.text('Firebase is configured for Android and iOS.'),
      findsOneWidget,
    );
  });
}
