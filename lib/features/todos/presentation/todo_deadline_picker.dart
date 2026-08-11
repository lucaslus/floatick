import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/floatick_editor_components.dart';
import '../../../core/ui/floatick_modal_bottom_sheet.dart';
import '../domain/todo_item.dart';

const double _deadlinePickerHeight = 590;

Future<TodoScheduleDraft?> showTodoDeadlinePicker({
  required BuildContext context,
  required TodoScheduleDraft initialSchedule,
}) {
  return showFloatickModalBottomSheet<TodoScheduleDraft>(
    context: context,
    builder: (sheetContext) => SizedBox(
      height: _deadlinePickerHeight,
      child: TodoDeadlinePicker(
        initialSchedule: initialSchedule,
        onClose: () => Navigator.of(sheetContext).pop(),
        onSave: (schedule) => Navigator.of(sheetContext).pop(schedule),
      ),
    ),
  );
}

enum _ReminderChoice {
  atDeadline,
  tenMinutesBefore,
  oneHourBefore,
  oneDayBefore,
  none,
  custom,
}

class TodoDeadlinePicker extends StatefulWidget {
  const TodoDeadlinePicker({
    required this.initialSchedule,
    required this.onClose,
    required this.onSave,
    super.key,
  });

  final TodoScheduleDraft initialSchedule;
  final VoidCallback onClose;
  final ValueChanged<TodoScheduleDraft> onSave;

  @override
  State<TodoDeadlinePicker> createState() => _TodoDeadlinePickerState();
}

class _TodoDeadlinePickerState extends State<TodoDeadlinePicker> {
  static const _selectableReminderChoices = <_ReminderChoice>[
    _ReminderChoice.atDeadline,
    _ReminderChoice.tenMinutesBefore,
    _ReminderChoice.oneHourBefore,
    _ReminderChoice.oneDayBefore,
    _ReminderChoice.none,
  ];

  final _closeFocusNode = FocusNode();
  late DateTime _dueAt;
  late DateTime? _reminderAt;
  late bool _notifyAtDeadline;

  @override
  void initState() {
    super.initState();
    final localDueAt = widget.initialSchedule.dueAt?.toLocal();
    final now = DateTime.now();
    _dueAt =
        localDueAt ??
        DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _reminderAt = widget.initialSchedule.reminderAt?.toLocal();
    _notifyAtDeadline = widget.initialSchedule.hasDeadline
        ? widget.initialSchedule.notifyAtDeadline
        : true;
  }

  @override
  void dispose() {
    _closeFocusNode.dispose();
    super.dispose();
  }

  void _setSelectedDate(DateTime date) {
    setState(() {
      _replaceDueAt(
        DateTime(date.year, date.month, date.day, _dueAt.hour, _dueAt.minute),
      );
    });
  }

  void _setSelectedTime(TimeOfDay time) {
    setState(() {
      _replaceDueAt(
        DateTime(_dueAt.year, _dueAt.month, _dueAt.day, time.hour, time.minute),
      );
    });
  }

  void _replaceDueAt(DateTime value) {
    final reminderOffset = _reminderAt?.difference(_dueAt);
    _dueAt = value;
    if (reminderOffset != null) {
      _reminderAt = value.add(reminderOffset);
    }
  }

  void _selectReminder(_ReminderChoice choice) {
    setState(() {
      switch (choice) {
        case _ReminderChoice.atDeadline:
          _notifyAtDeadline = true;
          _reminderAt = null;
          break;
        case _ReminderChoice.tenMinutesBefore:
          _notifyAtDeadline = false;
          _reminderAt = _dueAt.subtract(const Duration(minutes: 10));
          break;
        case _ReminderChoice.oneHourBefore:
          _notifyAtDeadline = false;
          _reminderAt = _dueAt.subtract(const Duration(hours: 1));
          break;
        case _ReminderChoice.oneDayBefore:
          _notifyAtDeadline = false;
          _reminderAt = _dueAt.subtract(const Duration(days: 1));
          break;
        case _ReminderChoice.none:
          _notifyAtDeadline = false;
          _reminderAt = null;
          break;
        case _ReminderChoice.custom:
          break;
      }
    });
  }

  _ReminderChoice get _reminderChoice {
    final reminderAt = _reminderAt;
    if (reminderAt == null) {
      return _notifyAtDeadline
          ? _ReminderChoice.atDeadline
          : _ReminderChoice.none;
    }
    if (_notifyAtDeadline) {
      return _ReminderChoice.custom;
    }
    final offset = _dueAt.difference(reminderAt);
    if (offset == const Duration(minutes: 10)) {
      return _ReminderChoice.tenMinutesBefore;
    }
    if (offset == const Duration(hours: 1)) {
      return _ReminderChoice.oneHourBefore;
    }
    if (offset == const Duration(days: 1)) {
      return _ReminderChoice.oneDayBefore;
    }
    return _ReminderChoice.custom;
  }

  String _reminderLabel(String locale) {
    final reminderAt = _reminderAt;
    if (_reminderChoice != _ReminderChoice.custom) {
      return _copy.reminderChoiceName(_reminderChoice);
    }
    if (reminderAt == null) {
      return _copy.atDeadline;
    }
    final customTime = DateFormat.MMMd(locale).add_Hm().format(reminderAt);
    return _notifyAtDeadline ? _copy.customAndDeadline(customTime) : customTime;
  }

  _DeadlineCopy get _copy => _DeadlineCopy.of(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hasExistingDeadline = widget.initialSchedule.hasDeadline;
    return FloatickEditorDrawerSurface(
      key: const Key('todo-deadline-picker'),
      title: hasExistingDeadline ? _copy.editDeadline : _copy.addDeadline,
      closeTooltip: _copy.close,
      onClose: widget.onClose,
      closeFocusNode: _closeFocusNode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              key: const Key('deadline-picker-content'),
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Theme(
                      data: theme.copyWith(
                        datePickerTheme: DatePickerThemeData(
                          backgroundColor: Colors.transparent,
                          headerBackgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          todayBorder: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                      child: CalendarDatePicker(
                        key: const Key('todo-deadline-calendar'),
                        initialDate: _dueAt,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 3650),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                        onDateChanged: _setSelectedDate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SectionLabel(text: _copy.deadline),
                  const SizedBox(height: 5),
                  _SelectionRow(
                    key: const Key('todo-deadline-time-field'),
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat.yMMMd(locale).format(_dueAt),
                    trailing: _InlineTimeEditor(
                      initialTime: TimeOfDay.fromDateTime(_dueAt),
                      copy: _copy,
                      onChanged: _setSelectedTime,
                    ),
                    showChevron: false,
                  ),
                  const SizedBox(height: 10),
                  _SectionLabel(text: _copy.reminder),
                  const SizedBox(height: 5),
                  PopupMenuButton<_ReminderChoice>(
                    key: const Key('todo-reminder-picker'),
                    tooltip: _copy.reminder,
                    position: PopupMenuPosition.under,
                    initialValue: _reminderChoice == _ReminderChoice.custom
                        ? null
                        : _reminderChoice,
                    onSelected: _selectReminder,
                    itemBuilder: (context) => <PopupMenuEntry<_ReminderChoice>>[
                      for (final choice in _selectableReminderChoices)
                        PopupMenuItem<_ReminderChoice>(
                          value: choice,
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 22,
                                child: choice == _reminderChoice
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 17,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _copy.reminderChoiceName(choice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    child: _SelectionRow(
                      icon: Icons.notifications_none_rounded,
                      label: _reminderLabel(locale),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FloatickEditorFooter(
            key: const Key('deadline-picker-footer'),
            child: Row(
              children: <Widget>[
                if (hasExistingDeadline)
                  TextButton(
                    key: const Key('clear-todo-deadline'),
                    onPressed: () => widget.onSave(const TodoScheduleDraft()),
                    child: Text(_copy.clear),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onClose,
                  child: Text(_copy.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('save-todo-deadline'),
                  onPressed: () => widget.onSave(
                    TodoScheduleDraft(
                      dueAt: _dueAt,
                      reminderAt: _reminderAt,
                      notifyAtDeadline: _notifyAtDeadline,
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: Text(
                    hasExistingDeadline ? _copy.save : _copy.setDeadline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineTimeEditor extends StatefulWidget {
  const _InlineTimeEditor({
    required this.initialTime,
    required this.copy,
    required this.onChanged,
  });

  final TimeOfDay initialTime;
  final _DeadlineCopy copy;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<_InlineTimeEditor> createState() => _InlineTimeEditorState();
}

class _InlineTimeEditorState extends State<_InlineTimeEditor> {
  final _hourFocusNode = FocusNode();
  final _minuteFocusNode = FocusNode();
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = TextEditingController(text: _twoDigits(_hour));
    _minuteController = TextEditingController(text: _twoDigits(_minute));
    _hourFocusNode.addListener(_normalizeHourOnBlur);
    _minuteFocusNode.addListener(_normalizeMinuteOnBlur);
  }

  @override
  void didUpdateWidget(covariant _InlineTimeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime == oldWidget.initialTime ||
        widget.initialTime == TimeOfDay(hour: _hour, minute: _minute)) {
      return;
    }
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    if (!_hourFocusNode.hasFocus) {
      _syncHourController();
    }
    if (!_minuteFocusNode.hasFocus) {
      _syncMinuteController();
    }
  }

  @override
  void dispose() {
    _hourFocusNode
      ..removeListener(_normalizeHourOnBlur)
      ..dispose();
    _minuteFocusNode
      ..removeListener(_normalizeMinuteOnBlur)
      ..dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  void _normalizeHourOnBlur() {
    if (!_hourFocusNode.hasFocus) {
      _syncHourController();
    }
  }

  void _normalizeMinuteOnBlur() {
    if (!_minuteFocusNode.hasFocus) {
      _syncMinuteController();
    }
  }

  void _syncHourController() {
    _hourController.value = TextEditingValue(
      text: _twoDigits(_hour),
      selection: const TextSelection.collapsed(offset: 2),
    );
  }

  void _syncMinuteController() {
    _minuteController.value = TextEditingValue(
      text: _twoDigits(_minute),
      selection: const TextSelection.collapsed(offset: 2),
    );
  }

  void _readValidHour(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= 23) {
      _hour = parsed;
      _emitTime();
    }
  }

  void _readValidMinute(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= 59) {
      _minute = parsed;
      _emitTime();
    }
  }

  void _emitTime() {
    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  void _stepHour(int amount) {
    _readValidHour(_hourController.text);
    setState(() {
      _hour = (_hour + amount) % 24;
      _syncHourController();
    });
    _emitTime();
  }

  void _stepMinute(int amount) {
    _readValidHour(_hourController.text);
    _readValidMinute(_minuteController.text);
    final adjusted = DateTime(2000, 1, 1, _hour, _minute + amount);
    setState(() {
      _hour = adjusted.hour;
      _minute = adjusted.minute;
      _syncHourController();
      _syncMinuteController();
    });
    _emitTime();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      key: const Key('todo-inline-time-editor'),
      width: 132,
      height: 34,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TimeSpinnerField(
              key: const Key('todo-time-hour-spinner'),
              inputKey: const Key('todo-time-hour-input'),
              incrementKey: const Key('todo-time-hour-increment'),
              decrementKey: const Key('todo-time-hour-decrement'),
              label: widget.copy.hour,
              controller: _hourController,
              focusNode: _hourFocusNode,
              textInputAction: TextInputAction.next,
              onChanged: _readValidHour,
              onIncrement: () => _stepHour(1),
              onDecrement: () => _stepHour(-1),
              incrementTooltip: widget.copy.increaseHour,
              decrementTooltip: widget.copy.decreaseHour,
              onSubmitted: (_) => _minuteFocusNode.requestFocus(),
            ),
          ),
          SizedBox(
            key: const Key('todo-time-separator'),
            width: 16,
            child: Text(
              ':',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _TimeSpinnerField(
              key: const Key('todo-time-minute-spinner'),
              inputKey: const Key('todo-time-minute-input'),
              incrementKey: const Key('todo-time-minute-increment'),
              decrementKey: const Key('todo-time-minute-decrement'),
              label: widget.copy.minute,
              controller: _minuteController,
              focusNode: _minuteFocusNode,
              textInputAction: TextInputAction.done,
              onChanged: _readValidMinute,
              onIncrement: () => _stepMinute(1),
              onDecrement: () => _stepMinute(-1),
              incrementTooltip: widget.copy.increaseMinute,
              decrementTooltip: widget.copy.decreaseMinute,
              onSubmitted: (_) => _minuteFocusNode.unfocus(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSpinnerField extends StatefulWidget {
  const _TimeSpinnerField({
    required this.inputKey,
    required this.incrementKey,
    required this.decrementKey,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.textInputAction,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
    required this.incrementTooltip,
    required this.decrementTooltip,
    required this.onSubmitted,
    super.key,
  });

  final Key inputKey;
  final Key incrementKey;
  final Key decrementKey;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String incrementTooltip;
  final String decrementTooltip;
  final ValueChanged<String> onSubmitted;

  @override
  State<_TimeSpinnerField> createState() => _TimeSpinnerFieldState();
}

class _TimeSpinnerFieldState extends State<_TimeSpinnerField> {
  static const double _scrollThreshold = 8;
  double _scrollAccumulator = 0;
  bool _isHovered = false;

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    _scrollAccumulator += event.scrollDelta.dy;
    if (_scrollAccumulator <= -_scrollThreshold) {
      _scrollAccumulator = 0;
      widget.onIncrement();
    } else if (_scrollAccumulator >= _scrollThreshold) {
      _scrollAccumulator = 0;
      widget.onDecrement();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: widget.label,
      textField: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          child: ListenableBuilder(
            listenable: widget.focusNode,
            builder: (context, child) {
              final baseColor =
                  theme.inputDecorationTheme.fillColor ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.045);
              return AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _isHovered && !widget.focusNode.hasFocus
                      ? Color.alphaBlend(
                          theme.colorScheme.onSurface.withValues(alpha: 0.025),
                          baseColor,
                        )
                      : baseColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.focusNode.hasFocus
                        ? theme.colorScheme.primary.withValues(alpha: 0.72)
                        : theme.colorScheme.onSurface.withValues(
                            alpha: _isHovered ? 0.20 : 0.12,
                          ),
                    width: widget.focusNode.hasFocus ? 1.25 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              );
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.arrowUp):
                          widget.onIncrement,
                      const SingleActivator(LogicalKeyboardKey.arrowDown):
                          widget.onDecrement,
                    },
                    child: TextFormField(
                      key: widget.inputKey,
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: widget.textInputAction,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      maxLength: 2,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: widget.onChanged,
                      onFieldSubmitted: widget.onSubmitted,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 3),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: _TimeStepButton(
                          key: widget.incrementKey,
                          icon: Icons.keyboard_arrow_up_rounded,
                          tooltip: widget.incrementTooltip,
                          onPressed: widget.onIncrement,
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.10,
                        ),
                      ),
                      Expanded(
                        child: _TimeStepButton(
                          key: widget.decrementKey,
                          icon: Icons.keyboard_arrow_down_rounded,
                          tooltip: widget.decrementTooltip,
                          onPressed: widget.onDecrement,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeStepButton extends StatelessWidget {
  const _TimeStepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.expand(),
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.hovered)) {
            return Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.055);
          }
          return Colors.transparent;
        }),
      ),
      icon: Icon(icon, size: 12),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.onPressed,
    this.showChevron = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing case final trailing?) ...[
                const SizedBox(width: 10),
                trailing,
              ],
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineCopy {
  const _DeadlineCopy(this.isChinese);

  factory _DeadlineCopy.of(BuildContext context) {
    return _DeadlineCopy(
      Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('zh'),
    );
  }

  final bool isChinese;

  String get addDeadline => isChinese ? '添加截止时间' : 'Add deadline';
  String get editDeadline => isChinese ? '编辑截止时间' : 'Edit deadline';
  String get deadline => isChinese ? '截止时间' : 'Deadline';
  String get reminder => isChinese ? '提醒' : 'Reminder';
  String get atDeadline => isChinese ? '截止时' : 'At deadline';
  String get clear => isChinese ? '清除' : 'Clear';
  String get cancel => isChinese ? '取消' : 'Cancel';
  String get save => isChinese ? '保存' : 'Save';
  String get setDeadline => isChinese ? '设置截止时间' : 'Set deadline';
  String get close => isChinese ? '关闭' : 'Close';
  String get hour => isChinese ? '小时' : 'Hour';
  String get minute => isChinese ? '分钟' : 'Minute';
  String get increaseHour => isChinese ? '增加一小时' : 'Increase hour';
  String get decreaseHour => isChinese ? '减少一小时' : 'Decrease hour';
  String get increaseMinute => isChinese ? '增加一分钟' : 'Increase minute';
  String get decreaseMinute => isChinese ? '减少一分钟' : 'Decrease minute';

  String reminderChoiceName(_ReminderChoice choice) {
    return switch (choice) {
      _ReminderChoice.atDeadline => atDeadline,
      _ReminderChoice.tenMinutesBefore =>
        isChinese ? '提前 10 分钟' : '10 minutes before',
      _ReminderChoice.oneHourBefore => isChinese ? '提前 1 小时' : '1 hour before',
      _ReminderChoice.oneDayBefore => isChinese ? '提前 1 天' : '1 day before',
      _ReminderChoice.none => isChinese ? '不提醒' : 'No reminder',
      _ReminderChoice.custom => isChinese ? '自定义提醒' : 'Custom reminder',
    };
  }

  String customAndDeadline(String customTime) {
    return isChinese ? '$customTime，并在截止时再次提醒' : '$customTime and at deadline';
  }
}
