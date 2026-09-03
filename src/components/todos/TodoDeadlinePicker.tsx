import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { X, ChevronLeft, ChevronRight, Calendar as CalendarIcon, Bell, Check, Trash2 } from "lucide-react";
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
      <div className="w-[336px] rounded-3xl bg-white dark:bg-[#1D2529] text-zinc-900 dark:text-[#EEF2F1] border border-black/[0.08] dark:border-white/[0.1] shadow-2xl overflow-hidden p-4.5 select-none transition-all">
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-black/[0.06] dark:border-white/[0.08]">
          <span className="text-xs font-semibold tracking-tight text-zinc-800 dark:text-[#EEF2F1]">
            {t("setDeadline")}
          </span>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded-full flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] transition-colors mui-ripple"
          >
            <X className="w-3.5 h-3.5" />
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
              className="w-7 h-7 rounded-full flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] transition-colors mui-ripple"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={handleNextMonth}
              className="w-7 h-7 rounded-full flex items-center justify-center text-zinc-400 hover:text-zinc-800 dark:hover:text-white hover:bg-black/[0.05] dark:hover:bg-white/[0.08] transition-colors mui-ripple"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Weekday Row */}
        <div className="grid grid-cols-7 gap-1 mt-2 text-center text-[10px] text-zinc-400 dark:text-[#8E9599] font-medium">
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
                    ? "bg-teal-600 dark:bg-[#22B8A7] text-white font-bold shadow-sm"
                    : isCurrentToday
                    ? "border border-teal-500 text-teal-600 dark:text-[#22B8A7] font-semibold"
                    : isCurrentMonth
                    ? "text-zinc-800 dark:text-[#EEF2F1] hover:bg-black/[0.04] dark:hover:bg-white/[0.08]"
                    : "text-zinc-400 dark:text-zinc-600 hover:bg-black/[0.02] dark:hover:bg-white/[0.04]"
                }`}
              >
                {format(day, "d")}
              </button>
            );
          })}
        </div>

        {/* Time & Deadline Input Section */}
        <div className="mt-4 pt-3 border-t border-black/[0.06] dark:border-white/[0.08] space-y-2.5">
          <div className="flex items-center justify-between bg-black/[0.03] dark:bg-black/25 p-2 rounded-xl border border-black/[0.04] dark:border-white/[0.06]">
            <div className="flex items-center space-x-2 text-xs">
              <CalendarIcon className="w-3.5 h-3.5 text-teal-600 dark:text-[#22B8A7]" />
              <span className="font-medium">
                {format(selectedDay, t("dateFormatMonthDay"), { locale: dateLocale })}
              </span>
            </div>
            <input
              type="time"
              value={timeStr}
              onChange={(e) => setTimeStr(e.target.value)}
              className="px-2 py-0.5 rounded-lg bg-white dark:bg-white/10 text-xs font-mono text-zinc-900 dark:text-white border border-black/[0.08] dark:border-white/10 outline-none focus:border-teal-500 dark:focus:border-[#22B8A7]"
            />
          </div>

          {/* Reminder Selection */}
          <div className="flex items-center justify-between bg-black/[0.03] dark:bg-black/25 p-2 rounded-xl border border-black/[0.04] dark:border-white/[0.06] text-xs">
            <div className="flex items-center space-x-2">
              <Bell className="w-3.5 h-3.5 text-teal-600 dark:text-[#22B8A7]" />
              <span className="text-zinc-500 dark:text-[#8E9599] text-[11px]">{t("reminder")}</span>
            </div>
            <select
              value={reminderChoice}
              onChange={(e) => setReminderChoice(e.target.value)}
              className="bg-transparent text-xs text-zinc-800 dark:text-white outline-none cursor-pointer pr-1"
            >
              <option value="atDeadline" className="dark:bg-[#1D2529]">{t("atDeadline")}</option>
              <option value="10m" className="dark:bg-[#1D2529]">{t("tenMinutesBefore")}</option>
              <option value="1h" className="dark:bg-[#1D2529]">{t("oneHourBefore")}</option>
              <option value="1d" className="dark:bg-[#1D2529]">{t("oneDayBefore")}</option>
              <option value="none" className="dark:bg-[#1D2529]">{t("noReminder")}</option>
            </select>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="mt-4 pt-1 flex items-center justify-between">
          {initialDueAt ? (
            <button
              type="button"
              onClick={handleClear}
              className="text-xs text-red-500 hover:text-red-600 dark:text-red-400 dark:hover:text-red-300 flex items-center space-x-1 cursor-pointer mui-ripple px-2 py-1 rounded-lg"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>{t("clearDeadline")}</span>
            </button>
          ) : (
            <div />
          )}

          <button
            type="button"
            onClick={handleSave}
            className="px-5 py-2 rounded-full bg-teal-600 hover:bg-teal-700 dark:bg-[#22B8A7] dark:hover:bg-[#1CA394] text-white font-medium text-xs flex items-center space-x-1.5 shadow-md mui-ripple cursor-pointer"
          >
            <Check className="w-3.5 h-3.5 stroke-[3]" />
            <span>{t("save")}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
