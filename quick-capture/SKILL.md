---
name: quick-capture
description: Cattura veloce di un'idea, nota o memo in `~/Documents/brain/inbox/` con frontmatter minimo. Usa questa skill quando Glody dice "appunta", "ricorda", "annota", "capture <testo>", "quick capture", "/capture", "salva questa idea", "scrivi in inbox" o varianti. Zero classificazione manuale — la nota va in inbox come `inbox-raw`, lo smistamento lo fa il Distill agentico in un secondo momento. NON usare per task strutturati (life-os ha skill dedicate), pagine progetto vive (vault `projects/`), o decisioni architetturali (vault `system/decisions.log`).
---

# Quick Capture

Cattura un pensiero in `~/Documents/brain/inbox/` senza attrito. Nessuna decisione su dove va o come si classifica — quella la fa il Distill agentico più tardi.

## Trigger

L'utente dice (esempi):

- "appunta che [...]"
- "ricorda di [...]"
- "annota [...]"
- "capture [...]"
- "/capture [...]"
- "scrivi in inbox [...]"
- "salva questa idea: [...]"

## Workflow

1. **Estrai il testo** da catturare. Tutto quello che l'utente ha detto dopo il trigger è il contenuto.

2. **Genera il filename** seguendo questo schema esatto:

   ```
   YYYY-MM-DD-HHMM-<slug>.md
   ```

   - `YYYY-MM-DD-HHMM` = timestamp locale corrente (es. `2026-05-28-1042`)
   - `<slug>` = primi 60 char del testo, slugificati:
     - lowercase
     - accenti normalizzati (NFKD), poi solo `[a-z0-9-]`
     - emoji e simboli rimossi
     - parole separate da `-`
     - troncato su confine di parola (no trailing dash)
     - se vuoto dopo slugify → `untitled`

3. **Scrivi il file** in `~/Documents/brain/inbox/<filename>` con questo formato:

   ```markdown
   ---
   tipo: inbox
   created: <data YYYY-MM-DD, es. 2026-05-28 — string, NON datetime YAML>
   source: claude-capture
   captured_at: <ISO8601 con timezone, es. 2026-05-28T10:42:15+02:00>
   ---

   <testo originale dell'utente, integrale, niente parafrasi>
   ```

   **Importante**:
   - `tipo: inbox` (senza suffisso `-raw`): l'unico valore allowlisted dallo schema vault. Distingui la provenance con `source:`, non con `tipo:`.
   - `created:` deve essere stringa `YYYY-MM-DD` (es. `2026-05-28`), NON datetime YAML completo, altrimenti `validate_vault` rifiuta.
   - Se vuoi precisione al minuto, usa `captured_at:` come campo aggiuntivo (libero).

4. **Conferma all'utente** in 1 riga: "Capturato in `inbox/<filename>`." Nient'altro.

## Esempi

### Esempio 1
**Utente**: "appunta che devo richiamare il commercialista per la chiusura fiscale 2025"

**File**: `~/Documents/brain/inbox/2026-05-28-1042-devo-richiamare-il-commercialista-per-la-chiusura.md`

```markdown
---
tipo: inbox
created: 2026-05-28
source: claude-capture
captured_at: 2026-05-28T10:42:00+02:00
---

devo richiamare il commercialista per la chiusura fiscale 2025
```

**Risposta**: "Capturato in `inbox/2026-05-28-1042-devo-richiamare-il-commercialista-per-la-chiusura.md`."

### Esempio 2
**Utente**: "/capture idea: micro-servizio Telegram per riassumere PDF lunghi via Claude API"

**File**: `~/Documents/brain/inbox/2026-05-28-1100-idea-micro-servizio-telegram-per-riassumere-pdf-lunghi.md`

```markdown
---
tipo: inbox
created: 2026-05-28
source: claude-capture
captured_at: 2026-05-28T11:00:00+02:00
---

idea: micro-servizio Telegram per riassumere PDF lunghi via Claude API
```

**Risposta**: "Capturato in `inbox/2026-05-28-1100-idea-micro-servizio-telegram-per-riassumere-pdf-lunghi.md`."

### Esempio 3 (testo vuoto)
**Utente**: "/capture"

**Risposta**: "Niente testo da catturare. Riprova con `/capture <testo>`."

(Non scrivere file.)

## Regole vincolanti

- **NON parafrasare** il testo dell'utente. Va integrale nel body.
- **NON classificare**. Niente tag, niente `area:`, niente decisione tipo `resource` vs altro. Sempre `tipo: inbox`.
- **NON arricchire**. Niente link wiki, niente backlinks, niente sotto-cartelle. Solo `brain/inbox/<filename>.md`.
- **NON chiedere conferma** prima di scrivere. È capture rapida, attrito zero.
- **Validate post-write**: il file deve esistere ed essere leggibile (Read dopo Write). Se Write fallisce, riportare l'errore senza ritentare.

## Output atteso

Un solo messaggio breve: "Capturato in `inbox/<filename>`." + (opzionale) preview frontmatter se l'utente l'ha chiesto.
