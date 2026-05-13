---
name: pa-legal-clause-analyzer
description: Analizza autocertificazioni PA italiane, estrae riferimenti normativi, incrocia con il profilo pa-data-vault per identificare clausole di esonero applicabili (es. BDSR Punto 2 gas/CO per <4 appartamenti, art. 13-ter DL 145/2023).
---

# pa-legal-clause-analyzer

Analizza un documento PA (autocertificazione, modulo, FAQ) e identifica quali clausole si applicano al profilo dell'utente, quali sono obbligatorie, e quali possono essere escluse in base alle norme citate nel documento stesso.

**Limite esplicito**: cita solo norme presenti nel documento. Non fa interpretazione giuridica autonoma. Se il documento non cita norme, dichiara esplicitamente l'incertezza.

Caso d'uso validato: BDSR Punto 2 gas/CO — esonero per strutture con meno di 4 appartamenti tramite comma 7 art. 13-ter DL 145/2023 (citato nel FAQ BDSR ufficiale, 2026-05-06).

## Input Accettati

| Tipo | Come fornirlo | Come viene processato |
|------|---------------|----------------------|
| URL | `https://bdsr.regione.lombardia.it/res/FAQ.pdf` | `curl -sLo /tmp/doc.pdf URL && pdftotext /tmp/doc.pdf -` |
| PDF locale | percorso assoluto o relativo al file | `pdftotext /path/to/file.pdf -` |
| Testo incollato | testo direttamente nel messaggio | usato direttamente |

Se il documento è HTML (non PDF), usa `pdftotext` solo su PDF. Per HTML: estrai testo con `get_page_text` (Chrome MCP) o `browser_snapshot` (Playwright).

## Estrazione Pattern Normativi

Cerca nel testo le seguenti forme (case-insensitive, con varianti tipografiche comuni):

```
Pattern A — articolo di legge:
  "ai sensi dell'art. {N}"
  "art. {N} del D.L. {N}/{YYYY}"
  "articolo {N} del decreto {N}/{YYYY}"
  "comma {N} art. {N} D.L. {N}/{YYYY}"

Pattern B — decreto legislativo:
  "D.Lgs. {N}/{YYYY}"
  "d.lgs. n. {N} del {YYYY}"
  "decreto legislativo {N} del {YYYY}"

Pattern C — decreto legge:
  "D.L. {N}/{YYYY}"
  "d.l. n. {N}/{YYYY}"
  "decreto-legge {N}/{YYYY}"

Pattern D — circolare / risoluzione:
  "Circolare n. {N} del {YYYY}"
  "Risoluzione {N}/{YYYY}"
```

Ogni riferimento estratto include:
- Il testo originale citato nel documento
- Il contesto (frase completa in cui appare)
- La sezione / punto del documento in cui si trova

## Cross-Check Profilo → Esonero

Per ogni riferimento normativo estratto:
1. Carica il profilo tramite **pa-data-vault** (numero appartamenti, tipo struttura, regime fiscale, etc.).
2. Valuta se il criterio di esonero citato nella norma si applica al profilo.
3. Classifica la clausola come: **Obbligatoria** / **Esonerata** / **N/A** / **Incerta**.

**Esempio (BDSR Punto 2)**:
- Norma estratta: "comma 7 art. 13-ter DL 145/2023 — esonero rilevatore CO per strutture con < 4 appartamenti"
- Profilo: numero_appartamenti = 1 (< 4)
- Risultato: **Esonerata** — valore suggerito: "N/A"

## Output — Tabella Markdown

```markdown
| Clausola | Obbligatoria? | Norma citata | Valore suggerito |
|----------|--------------|--------------|-----------------|
| Punto 1 — Denominazione struttura | Sì | — | BnB Via Braida |
| Punto 2 — Rilevatore CO/gas | No (esonerata) | comma 7 art. 13-ter DL 145/2023 | N/A |
| Punto 3 — CIN | Sì | art. 13-ter DL 145/2023 | [da completare] |
```

Colonne:
- **Clausola**: nome del punto/sezione nel documento
- **Obbligatoria?**: Sì / No (esonerata) / N/A / Incerta
- **Norma citata**: riferimento normativo estratto dal documento (vuoto se assente)
- **Valore suggerito**: valore da inserire nel form, dal profilo pa-data-vault o "[da completare]"

## Limite Esplicito — Fallback Documento Senza Norme

Se il documento non contiene riferimenti normativi riconoscibili:

```
Nessun riferimento normativo trovato nel documento.
Impossibile determinare esoneri applicabili.

Opzioni:
1. Verifica la FAQ ufficiale del portale per riferimenti normativi.
2. Consulta un patronato o CAF per valutazione manuale.
3. Compila tutti i campi come obbligatori (approccio conservativo).
```

Non inventare norme. Non interpretare clausole in assenza di riferimenti espliciti nel documento.

## Workflow Completo

```
INPUT: documento (URL / PDF locale / testo), profilo pa-data-vault

1. ACQUISIZIONE
   - Scarica o legge il documento (curl + pdftotext / lettura diretta)
   - Testo grezzo estratto

2. ESTRAZIONE NORME
   - Applica Pattern A/B/C/D al testo
   - Lista riferimenti normativi con contesto

3. CROSS-CHECK
   - Carica profilo da pa-data-vault
   - Per ogni clausola: valuta obbligatoria / esonerata / N/A / incerta

4. OUTPUT
   - Tabella markdown Clausola / Obbligatoria? / Norma / Valore suggerito
   - Se nessuna norma: fallback esplicito (vedi sezione Limite)

OUTPUT: tabella + lista campi da compilare con valori suggeriti
```

## Dipendenze

- **pa-data-vault**: fornisce il profilo (numero appartamenti, CIN, tipo struttura).
- `pdftotext` (basictex): per estrazione testo da PDF — già installato in ambiente.
- `curl`: per download documenti remoti.

## Casi d'Uso Validati

| Portale | Clausola | Norma | Risultato |
|---------|----------|-------|-----------|
| BDSR Lombardia | Punto 2 — Rilevatore CO/gas | comma 7 art. 13-ter DL 145/2023 | Esonerato (<4 appartamenti) |
| ROSS 1000 Lombardia | Anagrafica statistica struttura | nessuna norma citata | N/A (non obbligatorio per legge) |
