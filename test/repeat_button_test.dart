import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prronclick/repeat_button.dart';

void main() {
  testWidgets('held down, it repeats until let go or disabled', (tester) async {
    var n = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return RepeatIconButton(
                icon: const Icon(Icons.add),
                tooltip: 'More', // must not take the long press
                onPressed: n < 10 ? () => rebuild(() => n++) : null,
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(IconButton));
    expect(n, 1);

    final hold = await tester.startGesture(
      tester.getCenter(find.byType(IconButton)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    expect(n, 2); // the long press counts once
    await tester.pump(RepeatIconButton.every * 3);
    expect(n, 5);
    await hold.up();
    await tester.pump(RepeatIconButton.every * 3);
    expect(n, 5); // let go: stops

    final again = await tester.startGesture(
      tester.getCenter(find.byType(IconButton)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    for (var i = 0; i < 10; i++) {
      await tester.pump(RepeatIconButton.every);
    }
    expect(n, 10); // stops at the end of its range
    await again.up();
  });
}
