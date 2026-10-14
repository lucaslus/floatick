import { isMac } from "../../lib/platform";
import { useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { ArrowSquareOut, ArrowsClockwise } from "@phosphor-icons/react";
import { api, appVersion, type UpdateSettings } from "@/lib/api";

export function UpdateSettingsSection() {
  const { t, i18n } = useTranslation();
  const [settings, setSettings] = useState<UpdateSettings | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const actionPending = useRef(false);

  useEffect(() => {
    let disposed = false;
    let timer: ReturnType<typeof setTimeout>;
    const refresh = async () => {
      try {
        const next = await api.getUpdateSettings();
        if (!disposed) {
          setSettings(next);
          setError((current) => current === "updateSettingsFailed" ? null : current);
        }
      } catch {
        if (!disposed) setError("updateSettingsFailed");
      } finally {
        // Native update windows may outlive this drawer. Read their state only
        // while the section is visible, without overlapping native requests.
        if (!disposed) timer = setTimeout(refresh, 2000);
      }
    };
    void refresh();
    return () => {
      disposed = true;
      clearTimeout(timer);
    };
  }, []);

  const runAction = async (action: () => Promise<void>, errorKey: string) => {
    if (actionPending.current) return;
    actionPending.current = true;
    setPending(true);
    setError(null);
    try {
      await action();
      setSettings(await api.getUpdateSettings());
    } catch {
      setError(errorKey);
    } finally {
      actionPending.current = false;
      setPending(false);
    }
  };

  const busy = pending || (settings?.available && !settings.canCheck);
  return (
    <section aria-labelledby="updates-heading">
      <span id="updates-heading" className="text-[12px] font-medium text-[var(--color-text-subtle)] px-1 block mb-1.5">
        {t("updatesSectionTitle")}
      </span>
      <div className="bg-[var(--color-bg-elevated)] rounded-xl border border-[var(--color-border-panel)] divide-y divide-[var(--color-border-panel)] overflow-hidden">
        <div className="px-3.5 py-3 flex items-center justify-between gap-3">
          <div className="min-w-0">
            <p className="text-[13px] text-[var(--color-text-primary)]">{t("currentVersionLabel")}</p>
            <p className="text-[12px] font-mono text-[var(--color-text-subtle)] mt-0.5">v{settings?.currentVersion ?? appVersion}</p>
          </div>
          <button
            type="button"
            disabled={!settings?.available || busy}
            aria-busy={!!busy}
            onClick={() => void runAction(api.checkForUpdates, "updateCheckFailed")}
            className="inline-flex items-center justify-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-[var(--color-teal-tint)] text-[var(--color-teal-primary)] text-[12px] font-medium cursor-pointer tactile-btn disabled:opacity-45 disabled:cursor-default shrink-0 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-teal-primary)]"
          >
            <ArrowsClockwise size={14} className={busy ? "animate-spin motion-reduce:animate-none" : ""} />
            {t(busy ? "updateInProgress" : "checkForUpdates")}
          </button>
        </div>
        <div className="px-3.5 py-3 flex items-center justify-between gap-4">
          <div>
            <p id="auto-update-label" className="text-[13px] text-[var(--color-text-primary)]">{t("autoCheckUpdates")}</p>
            <p className="text-[11.5px] text-[var(--color-text-subtle)] leading-relaxed mt-0.5">{t("autoCheckUpdatesDescription")}</p>
          </div>
          <button
            type="button"
            role="switch"
            aria-labelledby="auto-update-label"
            aria-checked={settings?.automaticallyChecks ?? false}
            disabled={!settings?.available || pending}
            onClick={() => void runAction(
              () => api.setAutomaticallyChecksForUpdates(!settings?.automaticallyChecks),
              "updatePreferenceFailed",
            )}
            className={`w-9 h-5 rounded-full relative shrink-0 cursor-pointer transition-colors disabled:opacity-45 disabled:cursor-default focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-teal-primary)] ${settings?.automaticallyChecks ? "bg-[var(--color-teal-primary)]" : "bg-black/15 dark:bg-white/18"}`}
          >
            <span className={`w-4 h-4 rounded-full bg-white shadow-xs absolute top-0.5 left-0.5 transition-transform ${settings?.automaticallyChecks ? "translate-x-4" : ""}`} />
          </button>
        </div>
      </div>
      <div className="px-1 mt-2 text-[11.5px] leading-relaxed text-[var(--color-text-subtle)]" aria-live="polite">
        {error ? <p role="alert" className="text-red-500">{t(error)}</p> : settings && !settings.available ? (
          <p>{t(isMac ? "updatesUnavailable" : "updatesPackageManager")}</p>
        ) : busy ? (
          <p>{t("nativeUpdateWindowHint")}</p>
        ) : settings?.lastCheckedAt ? (
          <p>{t("lastUpdateCheck", { date: new Date(settings.lastCheckedAt).toLocaleString(i18n.language) })}</p>
        ) : null}
        <button
          type="button"
          onClick={() => void runAction(api.openLatestRelease, "openReleaseFailed")}
          className="inline-flex items-center gap-1 mt-1 text-[var(--color-teal-primary)] cursor-pointer hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
        >
          {t("viewReleaseNotes")}<ArrowSquareOut size={12} />
        </button>
      </div>
    </section>
  );
}
