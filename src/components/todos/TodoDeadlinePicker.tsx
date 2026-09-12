import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import {
  X,
  CaretLeft,
  CaretRight,
  CalendarBlank,
  Bell,
  Check,
  Trash,
} from "@phosphor-icons/react";
import {
  format,
  addMonths,
  subMonths,
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  isSameMonth,
  isSameDay,
  isToday,
  parseISO,
} from "date-fns";
import { zhCN, enUS } from "date-fns/locale";

interface TodoDeadlinePickerProps {
  initialDueAt?: string | null;
  initialReminderAt?: string | null;
  onSave: (dueAt: string | null, reminderAt: string | null) => void;
  onClose: () => void;
}

export const TodoDeadlinePicker: React.FC<TodoDeadlinePickerProps> = ({
  initialDueAt,
  initialReminderAt,
  onSave,
  onClose,
}) => {
  const { t, i18n } = useTranslation();
  const dateLocale = i18n.language.startsWith("zh") ? zhCN : enUS;

  const initialDate = initialDueAt ? parseISO(initialDueAt) : new Date();

  const [currentMonth, setCurrentMonth] = useState(initialDate);
  const [selectedDay, setSelectedDay] = useState(initialDate);
  const [timeStr, setTimeStr] = useState(
    initialDueAt ? format(parseISO(initialDueAt), "HH:mm") : "18:00"
  );
  const [reminderChoice, setReminderChoice] = useState<string>(
    initialReminderAt ? "custom" : "atDeadline"
  );

  const monthStart = startOfMonth(currentMonth);
  const monthEnd = endOfMonth(monthStart);
  const startDate = startOfWeek(monthStart, { weekStartsOn: 0 });
  const endDate = endOfWeek(monthEnd, { weekStartsOn: 0 });

  const calendarDays = eachDayOfInterval({ start: startDate, end: endDate });

  const handlePrevMonth = () => setCurrentMonth(subMonths(currentMonth, 1));
  const handleNextMonth = () => setCurrentMonth(addMonths(currentMonth, 1));

  const handleSave = () => {
    const [hours, minutes] = timeStr.split(":").map(Number);
    const resultDate = new Date(selectedDay);
    resultDate.setHours(hours || 0, minutes || 0, 0, 0);

    const dueIso = resultDate.toISOString();

    let remIso: string | null = null;
    if (reminderChoice === "atDeadline") {
      remIso = dueIso;
    } else if (reminderChoice === "10m") {
      remIso = new Date(resultDate.getTime() - 10 * 60 * 1000).toISOString();
    } else if (reminderChoice === "1h") {
      remIso = new Date(resultDate.getTime() - 60 * 60 * 1000).toISOString();
    } else if (reminderChoice === "1d") {
      remIso = new Date(resultDate.getTime() - 24 * 60 * 60 * 1000).toISOString();
    }

    onSave(dueIso, remIso);
    onClose();
  };

  const handleClear = () => {
    onSave(null, null);
    onClose();
  };

  const weekDayLabels = i18n.language.startsWith("zh")
    ? ["日", "一", "二", "三", "四", "五", "六"]
    : ["S", "M", "T", "W", "T", "F", "S"];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs animate-in fade-in duration-150">
      <div className="w-[336px] rounded-[14px] bg-[var(--color-bg-drawer)] text-[var(--color-text-primary)] border border-[var(--color-border-drawer)] shadow-2xl overflow-hidden p-4.5 select-none transition-all">
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-[var(--color-border-drawer)]">
          <span className="text-xs font-semibold tracking-tight text-[var(--color-text-primary)]">
            {t("setDeadline")}
          </span>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded-full flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] transition-colors mui-ripple"
          >
            <X size={15} weight="bold" />
          </button>
        </div>

        {/* Month Navigation */}
        <div className="flex items-center justify-between pt-3 px-1">
          <span className="text-xs font-semibold tracking-tight">
            {format(currentMonth, t("dateFormatMonthYear"), { locale: dateLocale })}
          </span>
          <div className="flex items-center space-x-1">
            <button
              type="button"
              onClick={handlePrevMonth}
              className="w-7 h-7 rounded-full flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] transition-colors mui-ripple"
            >
              <CaretLeft size={16} weight="bold" />
            </button>
            <button
              type="button"
              onClick={handleNextMonth}
              className="w-7 h-7 rounded-full flex items-center justify-center text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)] transition-colors mui-ripple"
            >
              <CaretRight size={16} weight="bold" />
            </button>
          </div>
        </div>

        {/* Weekday Row */}
        <div className="grid grid-cols-7 gap-1 mt-2 text-center text-[10px] text-[var(--color-text-subtle)] font-medium">
          {weekDayLabels.map((d, i) => (
            <div key={i} className="h-6 flex items-center justify-center">
              {d}
            </div>
          ))}
        </div>

        {/* Days Grid */}
        <div className="grid grid-cols-7 gap-1 text-center text-xs mt-1">
          {calendarDays.map((day) => {
            const isSelected = isSameDay(day, selectedDay);
            const isCurrentMonth = isSameMonth(day, currentMonth);
            const isCurrentToday = isToday(day);

            return (
              <button
                key={day.toISOString()}
                type="button"
                onClick={() => setSelectedDay(day)}
                className={`h-7.5 w-7.5 mx-auto rounded-full flex items-center justify-center text-[11px] font-medium transition-all mui-ripple ${
                  isSelected
                    ? "bg-[var(--color-teal-primary)] text-[var(--color-on-accent)] font-bold shadow-sm"
                    : isCurrentToday
                    ? "border border-[var(--color-teal-primary)] text-[var(--color-teal-primary)] font-semibold"
                    : isCurrentMonth
                    ? "text-[var(--color-text-primary)] hover:bg-[var(--color-hover-overlay)]"
                    : "text-[var(--color-text-subtle)] hover:bg-[var(--color-hover-overlay)]"
                }`}
              >
                {format(day, "d")}
              </button>
            );
          })}
        </div>

        {/* Time & Deadline Input Section */}
        <div className="mt-4 pt-3 border-t border-[var(--color-border-drawer)] space-y-2.5">
          <div className="flex items-center justify-between bg-[var(--color-hover-overlay)] p-2 rounded-[8px] border border-[var(--color-border-panel)]">
            <div className="flex items-center space-x-2 text-xs">
              <CalendarBlank size={15} weight="fill" className="text-[var(--color-teal-primary)]" />
              <span className="font-medium">
                {format(selectedDay, t("dateFormatMonthDay"), { locale: dateLocale })}
              </span>
            </div>
            <input
              type="time"
              value={timeStr}
              onChange={(e) => setTimeStr(e.target.value)}
              className="px-2 py-0.5 rounded-[6px] bg-[var(--color-bg-elevated)] text-xs font-mono text-[var(--color-text-primary)] border border-[var(--color-border-panel)] outline-none focus:border-[var(--color-teal-primary)]"
            />
          </div>

          {/* Reminder Selection */}
          <div className="flex items-center justify-between bg-[var(--color-hover-overlay)] p-2 rounded-[8px] border border-[var(--color-border-panel)] text-xs">
            <div className="flex items-center space-x-2">
              <Bell size={15} weight="fill" className="text-[var(--color-teal-primary)]" />
              <span className="text-[var(--color-text-subtle)] text-[11px]">{t("reminder")}</span>
            </div>
            <select
              value={reminderChoice}
              onChange={(e) => setReminderChoice(e.target.value)}
              className="bg-transparent text-xs text-[var(--color-text-primary)] outline-none cursor-pointer pr-1"
            >
              <option value="atDeadline" className="bg-[var(--color-bg-drawer)]">{t("atDeadline")}</option>
              <option value="10m" className="bg-[var(--color-bg-drawer)]">{t("tenMinutesBefore")}</option>
              <option value="1h" className="bg-[var(--color-bg-drawer)]">{t("oneHourBefore")}</option>
              <option value="1d" className="bg-[var(--color-bg-drawer)]">{t("oneDayBefore")}</option>
              <option value="none" className="bg-[var(--color-bg-drawer)]">{t("noReminder")}</option>
            </select>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="mt-4 pt-1 flex items-center justify-between">
          {initialDueAt ? (
            <button
              type="button"
              onClick={handleClear}
              className="text-xs text-red-500 hover:text-red-400 flex items-center space-x-1 cursor-pointer mui-ripple px-2 py-1 rounded-[6px]"
            >
              <Trash size={14} />
              <span>{t("clearDeadline")}</span>
            </button>
          ) : (
            <div />
          )}

          <button
            type="button"
            onClick={handleSave}
            title={t("save")}
            className="w-8 h-8 rounded-lg flex items-center justify-center text-[var(--color-teal-primary)] hover:bg-[var(--color-teal-tint)] transition-colors tactile-btn cursor-pointer"
          >
            <Check size={20} weight="bold" />
          </button>
        </div>
      </div>
    </div>
  );
};
