---
name: pa-form-filler
description: Compila form di portali PA italiani con browser automation (Playwright→Chrome→Computer Use). Scansiona FAQ PDF per identificare i soli campi obbligatori per legge, gestisce ID dinamici Keycloak (label-first + catalog fallback), salva progressi con checkpoint per resistere a timeout di sessione.
---

# pa-form-filler

Compila autocertificazioni e form su portali PA italiani. Parte dalla FAQ del portale per identificare quali campi sono obbligatori per legge (generalmente 5–10× meno di quelli visibili), poi naviga e compila solo quelli.

Validato su SoggiorniAmo Milano e BDSR Lombardia (2026-05-06).

## Browser Adapter Gerarchico

Usa il tool di browser automation meno invasivo disponibile. Scala al tier successivo solo quando il tier corrente fallisce o non è disponibile.

| Tier | Tool | Quando usare |
|------|------|-------------|
| 1 | Playwright MCP (`mcp__plugin_playwright_playwright__*`) | Primo tentativo. DOM-aware, selettori CSS/XPath, nessuna visione pixel. |
| 2 | Chrome MCP (`mcp__Claude_in_Chrome__*`) | Se Playwright non è connesso o la pagina usa shadow DOM / web components che Playwright non raggiunge. |
| 3 | Computer Use (`mcp__computer-use__*`) | Ultima risorsa. Usa solo per app native o quando i tier 1–2 falliscono su tutti i selettori. Più lento e fragile. |

**Criteri di fallback:**
- Tier 1 → Tier 2: `browser_snapshot` non trova l'elemento dopo 2 tentativi con selettori diversi, oppure `browser_fill_form` lancia errore di timeout.
- Tier 2 → Tier 3: `read_page` restituisce struttura vuota (shadow DOM), oppure `form_input` lancia errore su tutti i selettori.
- Tier 3 attivato: avvisa l'utente ("uso Computer Use — più lento, potrei sbagliare pixel") prima di procedere.

**Gotcha specifici (da CLAUDE.md):**
- Dropdown custom spesso invisibili a `read_page` interactive — usare `javascript_tool` per trovare `<select>` e triggerare `change` event.
- React Select: usare `mousedown` event, non `click()`, per aprire dropdown.
- Autocomplete location: richiedere `keypress` + `keydown` + native setter per ogni carattere + 2s wait per API asincrona.

## FAQ PDF Scan

Prima di compilare qualsiasi campo, scarica e analizza la FAQ del portale.

```
URL pattern: {base_url}/res/FAQ.pdf
Estrazione:  curl -sLo /tmp/faq.pdf "{faq_url}" && pdftotext /tmp/faq.pdf -
Parsing:     cerca sezione "campi obbligatori" / "dati necessari" / "documenti richiesti"
```

Costruisce la lista campi obbligatori per legge. Compila SOLO quelli. Ignora il resto (anagrafica statistica, campi opzionali, sezioni non obbligatorie).

Se la FAQ non è disponibile all'URL `{base_url}/res/FAQ.pdf`, cerca link alternativi nella pagina di login o in piè di pagina prima di procedere senza FAQ.

## Workflow End-to-End

```
INPUT: url portale, profilo utente (da pa-data-vault)

1. FAQ SCAN
   - Scarica FAQ PDF dal portale
   - Estrae lista campi obbligatori per legge
   - Mostra all'utente: "Compilerei N campi su M visibili — procedo?"

2. NAVIGAZIONE
   - Apri url portale con browser adapter (Tier 1 → 2 → 3)
   - Login con credenziali da profilo pa-data-vault
   - Naviga al form target

3. COMPILAZIONE
   - Per ogni campo obbligatorio:
     a. Risolvi selettore con id-mapper (label-first → catalog → discovery manuale)
     b. Compila valore dal profilo
     c. Salva checkpoint ogni 5 campi e ogni cambio pagina
   - Se HTTP 401 / redirect login → checkpoint + prompt resume

4. SUBMIT
   - Verifica riassunto form prima di submit
   - Submit
   - Cattura conferma / numero protocollo
   - Elimina checkpoint

OUTPUT: numero protocollo, screenshot conferma, log campi compilati
```

## ID Mapper — Gestione Campi con ID Dinamici

I portali PA basati su Keycloak rigenerano gli attributi `name` e `id` dei campi a ogni sessione (es. `name=field_a3f7b` → `name=field_c91d2` alla sessione successiva). L'id-mapper risolve il selettore reale a runtime con tre strategie in cascata.

### Strategia 1 — Label-First (preferita, ~90% portali PA)

Algoritmo:
1. Scansiona il DOM per tutte le `<label>` visibili.
2. Normalizza il testo della label (lowercase, rimuovi `:`, rimuovi spazi multipli).
3. Cerca `<label>` che match (esatto o fuzzy) il campo desiderato.
4. Risolvi il campo corrispondente:
   - Se `<label for="...">`: usa l'attributo `for` come ID del campo.
   - Se `<label>` contiene direttamente il campo (nesting): risali al primo `input/select/textarea` dentro la label.
   - Se nessuno dei due: cerca il primo `input/select/textarea` dopo la label nella sequenza DOM.
5. Usa il selettore risolto per compilare.

```
# Esempio: label "Codice Fiscale" → campo con id dinamico field_a3f7b
label_text = "Codice Fiscale"
label_el = find_label(text=label_text)        # <label for="field_a3f7b">
field_id = label_el.get_attribute("for")      # "field_a3f7b"
field_el = find_by_id(field_id)               # <input id="field_a3f7b">
```

### Strategia 2 — Catalog Fallback

Se label-first fallisce (label non trovata o ambigua), consulta `references/portals-catalog.yaml`:

```yaml
known_fields:
  codice_fiscale: "input[name='codiceFiscale']"
```

Usa il selettore CSS del catalog come fallback diretto. Funziona per portali dove la label è assente o in formato non-standard.

### Strategia 3 — Discovery Manuale + Auto-Save

Se sia label-first che catalog falliscono:
1. Mostra all'utente la lista dei `<input>/<select>/<textarea>` visibili nel form con il loro testo circostante.
2. Chiede: "Quale di questi corrisponde al campo '{label}'?"
3. L'utente indica il campo (per numero o cliccando).
4. Auto-save: scrive la nuova regola in `portals-catalog.yaml` sotto `known_fields` per usi futuri.

```yaml
# Auto-save genera questa entry
known_fields:
  denominazione: "input[name='denominazioneStruttura']"  # scoperto 2026-05-13
```

**Teardown auto-save**: il test bats verifica che l'auto-save scriva correttamente nel YAML e poi elimina la regola di test per non sporcare il catalog.

## Checkpoint — Gestione Session Timeout

I portali PA basati su Keycloak scadono dopo ~30 minuti senza avvisare. Il checkpoint salva il progresso su disco e permette di riprendere dalla compilazione interrotta.

### Schema File Checkpoint

Percorso: `~/.claude/pa-checkpoints/{portale}-{YYYY-MM-DD}.json`

Esempio: `~/.claude/pa-checkpoints/soggiorniamoMilano-2026-05-13.json`

```json
{
  "portale": "soggiorniamoMilano",
  "data": "2026-05-13",
  "url_corrente": "https://soggiorniamoamilano.comune.milano.it/form/step2",
  "pagina_corrente": 2,
  "campi_compilati": {
    "nome_struttura": "BnB Via Braida",
    "tipo_struttura": "bed_and_breakfast"
  },
  "campi_rimanenti": ["cin", "codice_struttura_milano"],
  "timestamp": "2026-05-13T14:23:00Z"
}
```

### Trigger Save

Salva il checkpoint automaticamente in questi momenti:
- Ogni cambio pagina del form (step 1 → step 2 → ...)
- Ogni 5 campi compilati con successo
- Prima di operazioni lente (upload documenti, chiamate API portale)

### Detection Session Timeout

Rileva timeout in questi modi (in ordine di affidabilità):
1. **HTTP 401** nella risposta del browser adapter.
2. **Redirect a URL login**: URL corrente contiene `/login`, `/sso`, `/auth/realms`.
3. **DOM "sessione scaduta"**: cerca testo "sessione scaduta", "session expired", "Accedi di nuovo" nella pagina.

Quando rilevato: salva checkpoint immediato + interrompe compilazione + mostra prompt:

```
Sessione scaduta su {portale}. Checkpoint salvato.
Vuoi riprendere dal campo '{ultimo_campo_compilato}'? [s/n]
```

### Resume Esplicito

L'utente può richiedere resume in qualsiasi momento:

```
riprendi il form soggiorniamoMilano
```

Mostra lista checkpoint disponibili ordinati per data:
```
Checkpoint disponibili:
1. soggiorniamoMilano-2026-05-13.json — pagina 2, 3 campi rimanenti (2026-05-13 14:23)
2. bdsr-2026-05-10.json — pagina 1, 7 campi rimanenti (2026-05-10 09:15)
Quale vuoi riprendere? [1/2/annulla]
```

### Cleanup Post-Submit

Dopo submit andato a buon fine (pagina conferma / numero protocollo ricevuto):
- Elimina `~/.claude/pa-checkpoints/{portale}-{YYYY-MM-DD}.json`
- Log: "Checkpoint eliminato — sessione completata."

Se submit fallisce, il checkpoint viene mantenuto per retry manuale.

## Dipendenze

- **pa-data-vault**: fornisce il profilo con CF, PEC, CIN, P.IVA, codici portali.
- **pa-form-filler references/portals-catalog.yaml**: catalogo URL e mapping campi noti.
- **ID mapper**: gestisce campi con ID dinamici Keycloak (sezione separata — task t1778606943593).
- **Checkpoint**: gestisce session timeout e resume (sezione separata — task t1778606943771).

## Portals Catalog

Il file `references/portals-catalog.yaml` mappa portali a URL base, URL FAQ, provider auth e mapping campi noti. Viene aggiornato automaticamente dal id-mapper quando scopre nuovi selettori (auto-save).

```yaml
portals:
  <nome>:
    base_url: "https://..."
    faq_url: "https://.../res/FAQ.pdf"
    auth_provider: keycloak
    session_timeout_min: 30
    known_fields:
      <label>: "<selettore CSS>"
```

Vedi `references/portals-catalog.yaml` per le entry esempio (soggiorniamoMilano, bdsr).

## Error Handling

| Errore | Causa | Azione |
|--------|-------|--------|
| FAQ non disponibile | URL 404 | Avvisa utente, procedi chiedendo conferma manuale dei campi |
| Browser non disponibile | Nessun tier attivo | Stop + istruzioni per installare Playwright MCP o abilitare Computer Use |
| Campo non trovato | ID dinamico non in catalog | Attiva discovery manuale id-mapper |
| HTTP 401 / redirect login | Session timeout Keycloak | Salva checkpoint, prompt resume |
| Submit fallito | Errore form / validazione PA | Mostra messaggio errore, lascia form aperto per correzione manuale |
