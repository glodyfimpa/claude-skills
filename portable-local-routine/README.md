# portable-local-routine

Gate di portabilità per routine e agenti **schedulati locali** — script che girano a
orari fissi via launchd/cron (non nel cloud di Claude). Lo standard: una routine locale
si costruisce portabile, gira via clone su qualsiasi PC (il Mac oggi, una VPS Linux
sempre accesa domani) senza riscrivere niente.

## Cosa fa

**Gate 0 — quale forma?** Prima dei criteri di portabilità, decide come va costruita la
routine in base a "serve un MCP autenticato interattivamente nell'app?": (A) no → routine
locale launchd/cron (questa skill); (B) sì e basta → Claude routine dentro l'app
(scheduled-task); (C) misto → ibrido (l'app estrae i dati via MCP, uno script portabile li
elabora). Nota: `claude -p` headless può caricare MCP process-based via `--mcp-config`; il
discriminante è l'autenticazione *interattiva* nell'app, non "MCP sì/no".

Poi applica 7 criteri di portabilità alla routine locale (forme A e allo script della C):

1. Nessun path assoluto hard-coded (`SCRIPT_DIR` via `BASH_SOURCE`)
2. Shebang `env bash`, bash 3.2-safe
3. Scheduler OS-detect (launchd su macOS, cron su Linux), mai OS-locked
4. Segreti in `.env` gitignored + `.env.example` versionato (clonabile)
5. Dipendenze dichiarate + preflight che fallisce chiaro
6. Niente bridge cloud quando il target è locale (curl/gh diretti)
7. Fire diagnosticabile (log JSONL fire_start/fire_end)

## Due modalità

- **build** — checklist mentre costruisci una routine nuova (gate prima di "finito").
- **audit** — linta una routine esistente e produce un report `[OK]/[FIX]/[N/A]` per
  criterio, con la riga concreta da cambiare per ogni fix.

Questa versione **consiglia, non modifica**. Auto-fix = estensione futura post-collaudo.

## Quando triggera

"routine portabile", "gira su ogni PC", "che giri anche su VPS", "scheduling locale",
"launchd", "cron job locale", "audit routine locale", "questa routine gira solo sul mio
Mac?", "rendi portabile questo script schedulato".

Non per: routine cloud-native (CCR), portabilità di sintassi bash generica (usa
`bash-portability-linter`), CI/CD su runner cloud.

## Origine

Nata dallo scheduling degli autonomous-agents (Builder/Reviewer locali), 2026-06-26.
Il primo caso d'uso reale — `areas/ai-automation/autonomous-agents/schedule.sh` — è la
referenza viva dei 7 criteri.
