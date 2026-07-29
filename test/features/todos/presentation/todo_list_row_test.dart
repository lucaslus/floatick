import 'dart:async';

import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/features/todos/presentation/widgets/todo_list_row.dart';
import 'package:floatick/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String clipboardText;

  setUp(() {
    clipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, String>{'text': clipboardText};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'hover actions align, copy Markdown, and double-click opens details',
    (tester) async {
      var toggleCount = 0;
      var detailsCount = 0;
      final item = TodoItem(
        id: 'aligned',
        title: 'Review the aligned row',
        content: 'The redundant content indicator should stay hidden.',
        createdAt: DateTime.utc(2026, 7, 27, 8),
      );
      final tags = <TodoTag>[
        TodoTag(
          id: 'tag-work',
          name: 'Work',
          colorValue: 0xFF20BFB2,
          createdAt: DateTime.utc(2026, 7, 27, 7),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 420,
                child: TodoListRow(
                  item: item,
                  archivedScope: false,
                  onToggle: () => toggleCount += 1,
                  onOpenDetails: () => detailsCount += 1,
                  onEdit: () {},
                  onArchive: () {},
                  onRestore: () {},
                  tags: tags,
                  assignedTagIds: const <String>['tag-work'],
                  onOpenTagAssignment: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(find.byType(TodoListRow)));
      await tester.pumpAndSettle();

      final primaryCenterY = tester
          .getCenter(find.byKey(const Key('todo-title-aligned')))
          .dy;
      for (final key in <String>[
        'toggle-todo-aligned',
        'copy-todo-aligned',
        'more-todo-aligned',
      ]) {
        expect(
          tester.getCenter(find.byKey(Key(key))).dy,
          closeTo(primaryCenterY, 0.5),
        );
      }

      final tagCenterY = tester
          .getCenter(find.byKey(const Key('todo-tag-aligned-tag-work')))
          .dy;
      final timeCenterY = tester
          .getCenter(find.byKey(const Key('todo-time-aligned')))
          .dy;
      expect(timeCenterY, closeTo(tagCenterY, 0.5));
      expect(tagCenterY, greaterThan(primaryCenterY + 10));
      expect(find.byKey(const Key('todo-has-content-aligned')), findsNothing);

      await tester.tap(find.byKey(const Key('copy-todo-aligned')));
      await tester.pump();
      expect(
        clipboardText,
        '# Review the aligned row\n\n'
        'The redundant content indicator should stay hidden.',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('copy-todo-aligned')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('more-todo-aligned')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('todo-action-view-aligned')), findsOneWidget);
      expect(find.byKey(const Key('todo-action-edit-aligned')), findsOneWidget);
      expect(
        find.byKey(const Key('todo-action-archive-aligned')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('todo-action-tags-aligned')), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('todo-actions-bottom-sheet-close')),
      );
      await tester.pumpAndSettle();

      final detailsRegion = find.byKey(
        const Key('todo-open-details-region-aligned'),
      );
      await tester.tap(detailsRegion);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(detailsRegion);
      await tester.pump();

      expect(detailsCount, 1);

      await tester.tap(find.byKey(const Key('toggle-todo-aligned')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(toggleCount, 1);
      expect(detailsCount, 1);
    },
  );

  testWidgets('external tag action bypasses the inline assignment menu', (
    tester,
  ) async {
    var openCount = 0;
    final item = TodoItem(
      id: 'todo-1',
      title: 'Review the draft',
      createdAt: DateTime.utc(2026, 7, 27, 8),
    );
    final tags = <TodoTag>[
      TodoTag(
        id: 'tag-1',
        name: 'Work',
        colorValue: 0xFF20BFB2,
        createdAt: DateTime.utc(2026, 7, 27, 7),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TodoListRow(
            item: item,
            archivedScope: false,
            onToggle: () {},
            onOpenDetails: () {},
            onEdit: () {},
            onArchive: () {},
            onRestore: () {},
            tags: tags,
            assignedTagIds: const <String>['tag-1'],
            onOpenTagAssignment: () => openCount += 1,
            showArchiveAction: false,
          ),
        ),
      ),
    );

    expect(find.text('Work'), findsOneWidget);
    expect(find.byType(MenuAnchor), findsNothing);
    expect(find.byIcon(Icons.archive_outlined), findsNothing);

    await tester.tap(find.byKey(const Key('assign-tags-todo-1')));
    await tester.pumpAndSettle();

    expect(openCount, 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(TodoListRow)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more-todo-todo-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('todo-action-tags-todo-1')));
    await tester.pumpAndSettle();

    expect(openCount, 2);
  });

  testWidgets(
    'inline tag action opens a responsive bottom sheet and reflects saved state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var saveSucceeds = false;
      var toggleCount = 0;
      var manageCount = 0;
      final item = TodoItem(
        id: 'bottom-sheet',
        title: 'Plan mobile tag flow',
        createdAt: DateTime.utc(2026, 7, 27, 8),
      );
      final tags = <TodoTag>[
        TodoTag(
          id: 'tag-work',
          name: 'Work',
          colorValue: 0xFF20BFB2,
          createdAt: DateTime.utc(2026, 7, 27, 7),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: TodoListRow(
              item: item,
              archivedScope: false,
              onToggle: () {},
              onOpenDetails: () {},
              onEdit: () {},
              onArchive: () {},
              onRestore: () {},
              tags: tags,
              assignedTagIds: const <String>[],
              onToggleTag: (_) async {
                toggleCount += 1;
                return saveSucceeds;
              },
              onOpenTagManagement: () => manageCount += 1,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('assign-tags-bottom-sheet')));
      await tester.pumpAndSettle();

      final sheet = find.byKey(const Key('tag-assignment-bottom-sheet'));
      final tagRow = find.byKey(const Key('assign-bottom-sheet-tag-work'));
      expect(sheet, findsOneWidget);
      expect(find.byType(MenuAnchor), findsNothing);
      expect(tester.getSize(sheet).width, closeTo(390, 0.5));
      expect(tester.getSize(sheet).height, lessThanOrEqualTo(844 * 0.72));
      expect(tester.getSize(tagRow).height, greaterThanOrEqualTo(44));

      await tester.tap(tagRow);
      await tester.pumpAndSettle();
      expect(toggleCount, 1);
      expect(
        find.descendant(of: tagRow, matching: find.byIcon(Icons.check_rounded)),
        findsNothing,
      );

      saveSucceeds = true;
      await tester.tap(tagRow);
      await tester.pumpAndSettle();
      expect(toggleCount, 2);
      expect(
        find.descendant(of: tagRow, matching: find.byIcon(Icons.check_rounded)),
        findsOneWidget,
      );
      final selectedRowInkWell = tester.widget<InkWell>(
        find.descendant(of: tagRow, matching: find.byType(InkWell)),
      );
      expect(
        (selectedRowInkWell.child! as Container).decoration,
        isNull,
        reason: 'Selected tags should use only a checkmark, without row fill.',
      );

      await tester.tap(find.byKey(const Key('tag-assignment-manage')));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(manageCount, 1);
    },
  );

  testWidgets(
    'macOS tag sheet stays inside the panel and keeps selection geometry stable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final pendingSaves = <Completer<bool>>[];
      final item = TodoItem(
        id: 'mac-sheet',
        title: 'Verify stable tags',
        createdAt: DateTime.utc(2026, 7, 27, 8),
      );
      final tags = <TodoTag>[
        TodoTag(
          id: 'tag-work',
          name: 'Work',
          colorValue: 0xFF20BFB2,
          createdAt: DateTime.utc(2026, 7, 27, 7),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(platform: TargetPlatform.macOS),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: TodoListRow(
                  item: item,
                  archivedScope: false,
                  onToggle: () {},
                  onOpenDetails: () {},
                  onEdit: () {},
                  onArchive: () {},
                  onRestore: () {},
                  tags: tags,
                  assignedTagIds: const <String>[],
                  onToggleTag: (_) {
                    final completer = Completer<bool>();
                    pendingSaves.add(completer);
                    return completer.future;
                  },
                  onOpenTagManagement: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('assign-tags-mac-sheet')));
      await tester.pumpAndSettle();

      final boundary = find.byKey(const Key('floatick-modal-surface-boundary'));
      final sheet = find.byKey(const Key('tag-assignment-bottom-sheet'));
      final sheetSurface = find.byKey(
        const Key('tag-assignment-bottom-sheet-surface'),
      );
      final tagRow = find.byKey(const Key('assign-mac-sheet-tag-work'));
      expect(tester.getRect(boundary), const Rect.fromLTWH(0, 0, 440, 700));
      expect(tester.getRect(sheet).left, tester.getRect(boundary).left);
      expect(tester.getRect(sheet).right, tester.getRect(boundary).right);
      expect(tester.getRect(sheet).bottom, tester.getRect(boundary).bottom);
      final sheetDecoration =
          tester.widget<DecoratedBox>(sheetSurface).decoration as BoxDecoration;
      final sheetRadius = sheetDecoration.borderRadius! as BorderRadius;
      expect(sheetRadius.bottomLeft.x, 25);
      expect(sheetRadius.bottomRight.x, 25);
      final contentSafeArea = tester.widget<SafeArea>(
        find.byKey(const Key('tag-assignment-content-safe-area')),
      );
      expect(contentSafeArea.minimum.bottom, 16);
      final sheetList = find.descendant(
        of: sheet,
        matching: find.byType(ListView),
      );
      expect(
        tester.getRect(sheet).bottom - tester.getRect(sheetList).bottom,
        greaterThanOrEqualTo(16),
      );

      final initialRect = tester.getRect(tagRow);
      await tester.tap(tagRow);
      await tester.pump();
      expect(pendingSaves, hasLength(1));
      expect(
        find.descendant(of: tagRow, matching: find.byIcon(Icons.check_rounded)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tagRow,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      expect(tester.getRect(tagRow), initialRect);

      pendingSaves.first.complete(true);
      await tester.pumpAndSettle();
      expect(tester.getRect(tagRow), initialRect);

      await tester.tap(tagRow);
      await tester.pump();
      expect(pendingSaves, hasLength(2));
      expect(
        find.descendant(of: tagRow, matching: find.byIcon(Icons.check_rounded)),
        findsNothing,
      );
      expect(tester.getRect(tagRow), initialRect);

      pendingSaves.last.complete(true);
      await tester.pumpAndSettle();
      expect(tester.getRect(tagRow), initialRect);
    },
  );

  testWidgets(
    'archived row menu only offers copy, view, restore, and deletion',
    (tester) async {
      var viewCount = 0;
      var restoreCount = 0;
      var deleteCount = 0;
      final item = TodoItem(
        id: 'archived',
        title: 'Archived todo',
        createdAt: DateTime.utc(2026, 7, 27, 8),
        archivedAt: DateTime.utc(2026, 7, 27, 9),
      );
      final tags = <TodoTag>[
        TodoTag(
          id: 'tag-1',
          name: 'Work',
          colorValue: 0xFF20BFB2,
          createdAt: DateTime.utc(2026, 7, 27, 7),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodoListRow(
              item: item,
              archivedScope: true,
              onToggle: () {},
              onOpenDetails: () => viewCount += 1,
              onEdit: null,
              onArchive: () {},
              onRestore: () => restoreCount += 1,
              tags: tags,
              assignedTagIds: const <String>['tag-1'],
              onDeletePermanently: () => deleteCount += 1,
            ),
          ),
        ),
      );

      expect(find.text('Work'), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(find.byType(TodoListRow)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('more-todo-archived')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('todo-action-edit-archived')), findsNothing);
      expect(find.byKey(const Key('todo-action-tags-archived')), findsNothing);
      await tester.tap(find.byKey(const Key('todo-action-view-archived')));
      await tester.pumpAndSettle();
      expect(viewCount, 1);

      await tester.tap(find.byKey(const Key('more-todo-archived')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('todo-action-restore-archived')));
      await tester.pumpAndSettle();
      expect(restoreCount, 1);

      await tester.tap(find.byKey(const Key('more-todo-archived')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('todo-action-delete-archived')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cancel-delete-todo-archived')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('confirm-delete-todo-archived')),
        findsOneWidget,
      );
      expect(deleteCount, 0);

      await tester.tap(find.byKey(const Key('confirm-delete-todo-archived')));
      expect(deleteCount, 1);
    },
  );
}
