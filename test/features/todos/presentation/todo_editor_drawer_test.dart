import 'package:floatick/features/todos/presentation/todo_editor_drawer.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
import 'package:floatick/l10n/app_localizations.dart';
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
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('a failed create stays open and shows an inline error', (
    WidgetTester tester,
  ) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);
    var saveCount = 0;
    var didFinishSaving = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 520,
            child: TodoEditorDrawer(
              mode: TodoEditorDrawerMode.create,
              item: null,
              availableTags: const <TodoTag>[],
              originalAssignedTagIds: const <String>[],
              assignedTagIds: const <String>[],
              isOpen: true,
              onClose: () {},
              onEdit: () {},
              onOpenTagAssignment: () {},
              onSave: (title, content, tagIds) async {
                saveCount += 1;
                return false;
              },
              onSaved: () => didFinishSaving = true,
              closeFocusNode: closeFocusNode,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Write release notes',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(saveCount, 1);
    expect(didFinishSaving, isFalse);
    expect(find.text("Couldn't save this todo."), findsOneWidget);
    expect(find.byKey(const Key('todo-title-field')), findsOneWidget);
  });

  testWidgets('create drawer saves selected tags with the todo', (
    WidgetTester tester,
  ) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);
    final tags = <TodoTag>[
      TodoTag(
        id: 'tag-work',
        name: 'Work',
        colorValue: 0xFF20B8A8,
        createdAt: DateTime.utc(2026, 7, 25),
      ),
      TodoTag(
        id: 'tag-focus',
        name: 'Focus',
        colorValue: 0xFF4C8FF5,
        createdAt: DateTime.utc(2026, 7, 25),
      ),
    ];
    List<String>? savedTagIds;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 520,
            child: TodoEditorDrawer(
              mode: TodoEditorDrawerMode.create,
              item: null,
              availableTags: tags,
              originalAssignedTagIds: const <String>[],
              assignedTagIds: const <String>['tag-work'],
              isOpen: true,
              onClose: () {},
              onEdit: () {},
              onOpenTagAssignment: () {},
              onSave: (title, content, tagIds) async {
                savedTagIds = tagIds;
                return true;
              },
              onSaved: () {},
              closeFocusNode: closeFocusNode,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Prepare release',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(savedTagIds, <String>['tag-work']);
  });

  testWidgets('details drawer displays assigned tags', (
    WidgetTester tester,
  ) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);
    final tag = TodoTag(
      id: 'tag-work',
      name: 'Work',
      colorValue: 0xFF20B8A8,
      createdAt: DateTime.utc(2026, 7, 25),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 520,
            child: TodoEditorDrawer(
              mode: TodoEditorDrawerMode.details,
              item: TodoItem(
                id: 'todo-1',
                title: 'Prepare release',
                content: '- Verify the DMG',
                createdAt: DateTime.utc(2026, 7, 25),
              ),
              availableTags: <TodoTag>[tag],
              originalAssignedTagIds: const <String>['tag-work'],
              assignedTagIds: const <String>['tag-work'],
              isOpen: true,
              onClose: () {},
              onEdit: () {},
              onOpenTagAssignment: () {},
              onSave: (title, content, tagIds) async => true,
              onSaved: () {},
              closeFocusNode: closeFocusNode,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todo-details-tags')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('todo-details-edit')),
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('todo-details-edit')),
        matching: find.text('Edit'),
      ),
      findsNothing,
    );
    expect(find.text('Work'), findsOneWidget);

    await tester.tap(find.byKey(const Key('todo-details-copy')));
    await tester.pump();
    expect(clipboardText, '# Prepare release\n\n- Verify the DMG');
  });

  testWidgets('archived details are read-only', (WidgetTester tester) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 520,
            child: TodoEditorDrawer(
              mode: TodoEditorDrawerMode.details,
              item: TodoItem(
                id: 'archived',
                title: 'Archived todo',
                createdAt: DateTime.utc(2026, 7, 25),
                archivedAt: DateTime.utc(2026, 7, 26),
              ),
              availableTags: const <TodoTag>[],
              originalAssignedTagIds: const <String>[],
              assignedTagIds: const <String>[],
              isOpen: true,
              canEdit: false,
              onClose: () {},
              onEdit: () {},
              onOpenTagAssignment: () {},
              onSave: (title, content, tagIds) async => true,
              onSaved: () {},
              closeFocusNode: closeFocusNode,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todo-details-edit')), findsNothing);
    expect(find.text('No additional notes were saved.'), findsOneWidget);
  });

  testWidgets('create drawer opens the shared tag assignment surface', (
    WidgetTester tester,
  ) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);
    final tags = <TodoTag>[
      TodoTag(
        id: 'tag-personal',
        name: 'Personal',
        colorValue: 0xFFA15CE0,
        createdAt: DateTime.utc(2026, 7, 25),
      ),
    ];
    List<String>? savedTagIds;
    var tagAssignmentRequested = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 520,
            child: TodoEditorDrawer(
              mode: TodoEditorDrawerMode.create,
              item: null,
              availableTags: tags,
              originalAssignedTagIds: const <String>[],
              assignedTagIds: const <String>[],
              isOpen: true,
              onClose: () {},
              onEdit: () {},
              onOpenTagAssignment: () => tagAssignmentRequested = true,
              onSave: (title, content, tagIds) async {
                savedTagIds = tagIds;
                return true;
              },
              onSaved: () {},
              closeFocusNode: closeFocusNode,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todo-editor-tag-button')), findsOneWidget);
    expect(find.byKey(const Key('todo-editor-tag-tag-personal')), findsNothing);

    await tester.tap(find.byKey(const Key('todo-editor-tag-button')));
    await tester.pumpAndSettle();
    expect(tagAssignmentRequested, isTrue);

    await tester.enterText(
      find.byKey(const Key('todo-title-field')),
      'Plan weekend',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(savedTagIds, isEmpty);
  });
}
