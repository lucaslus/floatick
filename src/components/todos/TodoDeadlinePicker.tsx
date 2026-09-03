import React, { useState } from "react";
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

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="w-[330px] rounded-2xl bg-[#1D2529] text-[#EEF2F1] border border-white/[0.1] shadow-2xl overflow-hidden p-4 select-none">
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-white/[0.08]">
          <span className="text-xs font-semibold">设置截止时间</span>
          <button
            onClick={onClose}
            className="w-6 h-6 rounded-md flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/[0.08]"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Month Navigation */}
        <div className="flex items-center justify-between pt-3 px-1">
          <span className="text-xs font-medium">
            {format(currentMonth, "yyyy年 M月")}
          </span>
          <div className="flex items-center space-x-1">
            <button
              type="button"
              onClick={handlePrevMonth}
              className="w-6 h-6 rounded flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/[0.08]"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={handleNextMonth}
              className="w-6 h-6 rounded flex items-center justify-center text-zinc-400 hover:text-white hover:bg-white/[0.08]"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Weekday Row */}
        <div className="grid grid-cols-7 gap-1 mt-2 text-center text-[10px] text-zinc-400 font-medium">
          {["日", "一", "二", "三", "四", "五", "六"].map((d) => (
            <div key={d} className="h-6 flex items-center justify-center">
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
                className={`h-7 w-7 mx-auto rounded-full flex items-center justify-center text-[11px] transition-all cursor-pointer ${
                  isSelected
                    ? "bg-[#22B8A7] text-white font-bold shadow-xs"
                    : isCurrentToday
                    ? "border border-[#22B8A7] text-[#22B8A7]"
                    : isCurrentMonth
                    ? "text-[#EEF2F1] hover:bg-white/[0.08]"
                    : "text-zinc-600 hover:bg-white/[0.04]"
                }`}
              >
                {format(day, "d")}
              </button>
            );
          })}
        </div>

        {/* Time & Deadline Input Section */}
        <div className="mt-4 pt-3 border-t border-white/[0.08] space-y-2.5">
          <div className="flex items-center justify-between bg-black/20 p-2 rounded-xl border border-white/[0.06]">
            <div className="flex items-center space-x-2 text-xs">
              <CalendarIcon className="w-3.5 h-3.5 text-[#22B8A7]" />
              <span>{format(selectedDay, "M月d日")}</span>
            </div>
            <input
              type="time"
              value={timeStr}
              onChange={(e) => setTimeStr(e.target.value)}
              className="px-2 py-0.5 rounded-lg bg-white/10 text-xs font-mono text-white border border-white/10 outline-none focus:border-[#22B8A7]"
            />
          </div>

          {/* Reminder Selection */}
          <div className="flex items-center justify-between bg-black/20 p-2 rounded-xl border border-white/[0.06] text-xs">
            <div className="flex items-center space-x-2">
              <Bell className="w-3.5 h-3.5 text-[#22B8A7]" />
              <span className="text-zinc-400 text-[11px]">提醒</span>
            </div>
            <select
              value={reminderChoice}
              onChange={(e) => setReminderChoice(e.target.value)}
              className="bg-transparent text-xs text-white outline-none cursor-pointer"
            >
              <option value="atDeadline" className="bg-[#1D2529]">截止时提醒</option>
              <option value="10m" className="bg-[#1D2529]">提前 10 分钟</option>
              <option value="1h" className="bg-[#1D2529]">提前 1 小时</option>
              <option value="1d" className="bg-[#1D2529]">提前 1 天</option>
              <option value="none" className="bg-[#1D2529]">不提醒</option>
            </select>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="mt-4 pt-2 flex items-center justify-between">
          {initialDueAt ? (
            <button
              type="button"
              onClick={handleClear}
              className="text-xs text-red-400 hover:text-red-300 flex items-center space-x-1 cursor-pointer"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>清除</span>
            </button>
          ) : (
            <div />
          )}

          <button
            type="button"
            onClick={handleSave}
            className="px-4 py-1.5 rounded-xl bg-[#22B8A7] hover:bg-[#1CA394] text-white font-medium text-xs flex items-center space-x-1 shadow-md cursor-pointer transition-colors"
          >
            <Check className="w-3.5 h-3.5 stroke-[3]" />
            <span>保存</span>
          </button>
        </div>
      </div>
    </div>
  );
};
