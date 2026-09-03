import { isToday, isYesterday, format, parseISO, isPast } from "date-fns";
import { zhCN, enUS } from "date-fns/locale";
import i18n from "@/i18n";

export function getGroupLabel(dateString: string, currentLang?: string): string {
  try {
    const date = parseISO(dateString);
    const isZh = (currentLang || i18n.language).startsWith("zh");
    const locale = isZh ? zhCN : enUS;

    if (isToday(date)) {
      return i18n.t("today");
    }
    if (isYesterday(date)) {
      return i18n.t("yesterday");
    }
    return format(date, isZh ? "yyyy年M月d日" : "MMM d, yyyy", { locale });
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

export function formatDeadline(
  dueAt: string,
  currentLang?: string
): { label: string; isOverdue: boolean } {
  try {
    const date = parseISO(dueAt);
    const overdue = isPast(date) && !isToday(date);
    const isZh = (currentLang || i18n.language).startsWith("zh");
    const locale = isZh ? zhCN : enUS;

    let label = "";
    if (isToday(date)) {
      label = `${i18n.t("today")} ${format(date, "HH:mm")}`;
    } else if (isYesterday(date)) {
      label = `${i18n.t("yesterday")} ${format(date, "HH:mm")}`;
    } else {
      label = format(date, isZh ? "M月d日 HH:mm" : "MMM d, HH:mm", { locale });
    }
    return { label, isOverdue: overdue };
  } catch {
    return { label: dueAt, isOverdue: false };
  }
}
