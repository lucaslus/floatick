import 'package:floatick/features/todos/presentation/todo_editor_drawer.dart';
import 'package:floatick/features/todos/domain/todo_item.dart';
import 'package:floatick/features/todos/domain/todo_tag.dart';
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
              onSave: (title, content, tagIds, schedule) async {
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

    expect(
      find.byKey(const Key('floatick-editor-mode-switch')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('todo-document-editor')), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Title (optional)'), findsNothing);
    expect(find.byKey(const Key('todo-editor-footer')), findsOneWidget);
    expect(find.text('Tags'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('todo-editor-tag-button'))).dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('floatick-editor-mode-switch')))
            .dx,
      ),
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('todo-title-field')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );

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

  testWidgets('create drawer saves a deadline selected in the tall picker', (
    WidgetTester tester,
  ) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);
    TodoScheduleDraft? savedSchedule;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 440,
            height: 590,
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
              onSave: (title, content, tagIds, schedule) async {
                savedSchedule = schedule;
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
      'Ship release',
    );

    final beforeOpeningDeadlinePicker = DateTime.now();
    await tester.tap(find.byKey(const Key('todo-editor-deadline-button')));
    await tester.pumpAndSettle();
    final afterOpeningDeadlinePicker = DateTime.now();
    expect(find.byKey(const Key('todo-deadline-picker')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('todo-deadline-picker'))).height,
      590,
    );
    final picker = find.byKey(const Key('todo-deadline-picker'));
    expect(
      find.descendant(of: picker, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );
    expect(find.byKey(const Key('todo-reminder-picker')), findsOneWidget);
    expect(find.byKey(const Key('deadline-shortcut-row')), findsNothing);
    expect(
      tester
          .getBottomRight(find.byKey(const Key('deadline-picker-content')))
          .dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('deadline-picker-footer'))).dy,
      ),
    );
    expect(find.byKey(const Key('save-todo-deadline')).hitTestable(), findsOne);

    expect(find.byKey(const Key('todo-time-picker-dialog')), findsNothing);
    final inlineTimeEditor = find.byKey(const Key('todo-inline-time-editor'));
    expect(inlineTimeEditor, findsOneWidget);
    expect(tester.getSize(inlineTimeEditor), const Size(132, 34));
    final deadlineRowRect = tester.getRect(
      find.byKey(const Key('todo-deadline-time-field')),
    );
    final inlineTimeEditorRect = tester.getRect(inlineTimeEditor);
    expect(deadlineRowRect.contains(inlineTimeEditorRect.topLeft), isTrue);
    expect(deadlineRowRect.contains(inlineTimeEditorRect.bottomRight), isTrue);
    final hourSpinnerRect = tester.getRect(
      find.byKey(const Key('todo-time-hour-spinner')),
    );
    final separatorRect = tester.getRect(
      find.byKey(const Key('todo-time-separator')),
    );
    final minuteSpinnerRect = tester.getRect(
      find.byKey(const Key('todo-time-minute-spinner')),
    );
    expect(separatorRect.left - hourSpinnerRect.right, greaterThanOrEqualTo(0));
    expect(
      minuteSpinnerRect.left - separatorRect.right,
      greaterThanOrEqualTo(0),
    );
    expect(separatorRect.width, 16);
    TextFormField timeInput(Key key) =>
        tester.widget<TextFormField>(find.byKey(key));
    final initialDate = tester
        .widget<CalendarDatePicker>(
          find.byKey(const Key('todo-deadline-calendar')),
        )
        .initialDate!;
    final initialHour = int.parse(
      timeInput(const Key('todo-time-hour-input')).controller!.text,
    );
    final initialMinute = int.parse(
      timeInput(const Key('todo-time-minute-input')).controller!.text,
    );
    final initialDueAt = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      initialHour,
      initialMinute,
    );
    DateTime atMinutePrecision(DateTime value) =>
        DateTime(value.year, value.month, value.day, value.hour, value.minute);
    expect(
      initialDueAt.isBefore(atMinutePrecision(beforeOpeningDeadlinePicker)),
      isFalse,
    );
    expect(
      initialDueAt.isAfter(atMinutePrecision(afterOpeningDeadlinePicker)),
      isFalse,
    );
    final hourInputDecoration = tester
        .widget<InputDecorator>(
          find.descendant(
            of: find.byKey(const Key('todo-time-hour-input')),
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration;
    expect(hourInputDecoration.filled, isFalse);
    expect(hourInputDecoration.hoverColor, Colors.transparent);

    await tester.tap(find.byKey(const Key('todo-time-hour-increment')));
    await tester.pump();
    expect(
      timeInput(const Key('todo-time-hour-input')).controller!.text,
      ((initialDueAt.hour + 1) % 24).toString().padLeft(2, '0'),
    );

    await tester.tap(find.byKey(const Key('todo-time-hour-input')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      timeInput(const Key('todo-time-hour-input')).controller!.text,
      initialDueAt.hour.toString().padLeft(2, '0'),
    );

    await tester.enterText(find.byKey(const Key('todo-time-hour-input')), '19');
    await tester.enterText(
      find.byKey(const Key('todo-time-minute-input')),
      '59',
    );
    await tester.tap(find.byKey(const Key('todo-time-minute-increment')));
    await tester.pump();
    expect(timeInput(const Key('todo-time-hour-input')).controller!.text, '20');
    expect(
      timeInput(const Key('todo-time-minute-input')).controller!.text,
      '00',
    );

    final minuteSpinner = find.byKey(const Key('todo-time-minute-spinner'));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(minuteSpinner),
        scrollDelta: const Offset(0, 20),
      ),
    );
    await tester.pump();
    expect(timeInput(const Key('todo-time-hour-input')).controller!.text, '19');
    expect(
      timeInput(const Key('todo-time-minute-input')).controller!.text,
      '59',
    );

    await tester.tap(find.byKey(const Key('todo-reminder-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 minutes before'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-todo-deadline')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(savedSchedule?.dueAt, isNotNull);
    expect(savedSchedule!.dueAt!.toLocal().hour, 19);
    expect(savedSchedule!.dueAt!.toLocal().minute, 59);
    expect(savedSchedule?.notifyAtDeadline, isFalse);
    expect(
      savedSchedule!.dueAt!.difference(savedSchedule!.reminderAt!),
      const Duration(minutes: 10),
    );
  });

  testWidgets('create drawer accepts a content-only todo', (
    WidgetTester tester,
  ) async {
    final closeFocusNode = FocusNode();
    addTearDown(closeFocusNode.dispose);
    String? savedTitle;
    String? savedContent;

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
              onSave: (title, content, tagIds, schedule) async {
                savedTitle = title;
                savedContent = content;
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
      find.byKey(const Key('todo-content-field')),
      'Capture this without stopping',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-todo-details')));
    await tester.pumpAndSettle();

    expect(savedTitle, isEmpty);
    expect(savedContent, 'Capture this without stopping');
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
              onSave: (title, content, tagIds, schedule) async {
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
              onSave: (title, content, tagIds, schedule) async => true,
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
              onSave: (title, content, tagIds, schedule) async => true,
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
              onSave: (title, content, tagIds, schedule) async {
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
