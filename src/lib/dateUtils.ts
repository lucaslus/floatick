import { isToday, isYesterday, format, parseISO, isPast } from "date-fns";
import i18n from "@/i18n";

export function getGroupLabel(dateString: string): string {
  try {
    const date = parseISO(dateString);
    if (isToday(date)) {
      return i18n.t("today");
    }
    if (isYesterday(date)) {
      return i18n.t("yesterday");
    }
    return format(date, "yyyy-MM-dd");
  } catch {
    return i18n.t("earlier");
  }
}

export function formatTime(dateString: string): string {
  try {
    const date = parseISO(dateString);
    return format(date, "HH:mm");
  } catch {
    return "";
  }
}

export function formatDeadline(dueAt: string): { label: string; isOverdue: boolean } {
  try {
    const date = parseISO(dueAt);
    const overdue = isPast(date) && !isToday(date);
    let label = "";
    if (isToday(date)) {
      label = `${i18n.t("today")} ${format(date, "HH:mm")}`;
    } else if (isYesterday(date)) {
      label = `${i18n.t("yesterday")} ${format(date, "HH:mm")}`;
    } else {
      label = format(date, "MM/dd HH:mm");
    }
    return { label, isOverdue: overdue };
  } catch {
    return { label: dueAt, isOverdue: false };
  }
}
