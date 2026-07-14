---
name: document-collector
description: >
  Trova e raccoglie documenti sparsi sul filesystem (e opzionalmente Google Drive) in una cartella di lavoro,
  rinominandoli in modo leggibile e rimuovendo duplicati. Usa questo skill ogni volta che l'utente deve preparare
  un pacchetto documentale per una pratica burocratica, amministrativa, legale o fiscale: ricorsi INPS, ISEE,
  domande di congedo, richieste al Comune, pratiche commercialista, apertura attività, richieste di mutuo o affitto.
  Trigger anche quando l'utente dice cose come "trovami i documenti per...", "prepara gli allegati", "raccogli
  tutto quello che serve per...", "metti insieme i documenti", "cerca sul PC il certificato di...", o qualsiasi
  variante che implichi cercare e raccogliere documenti esistenti per un obiettivo specifico.
---

# Document Collector

Cerca, filtra e raccoglie documenti sparsi in una cartella di lavoro organizzata.

## Quando si attiva

Ogni volta che serve preparare un pacchetto di documenti per una pratica. Esempi:
- Ricorso INPS, domanda di congedo, ISEE
- Pratica SUAP, apertura attività, CIN
- Commercialista (fatture, F24, certificazioni)
- Affitto, mutuo, documenti per proprietario/banca
- Qualsiasi contesto in cui servono "gli allegati"

## Workflow

### Fase 1: Capire cosa serve

Prima di cercare, chiarisci con l'utente:

1. **Quale pratica/obiettivo?** (es. "ricorso INPS congedo parentale", "ISEE 2026", "documenti per commercialista")
2. **Quali documenti servono?** Se l'utente non lo sa, aiutalo a costruire la lista basandoti sulla pratica. Cerca online se necessario per capire quali allegati sono richiesti per quel tipo di pratica.
3. **Per chi?** (es. "miei", "del partner", "del figlio/a", "di tutta la famiglia")
4. **Ci sono vincoli?** (es. limite dimensione file, formati accettati, documenti che devono essere recenti)

Se il contesto è già chiaro dalla conversazione, salta le domande ridondanti.

### Fase 2: Cercare i documenti

Cerca in ordine di priorità:

**1. Filesystem locale (priorità massima)**
Usa `find` con pattern intelligenti. Le keyword da cercare derivano dal tipo di documento:

| Tipo documento | Pattern di ricerca |
|---|---|
| Carta d'identità | `*carta_identita*`, `*identity*`, `*CI_*`, `*documento_identita*` |
| Codice fiscale | `*codice_fiscale*`, `*CF_*`, `*tessera_sanitaria*` |
| Certificato nascita/parto | `*nascita*`, `*birth*`, `*parto*`, `*atto_nascita*` |
| Stato di famiglia | `*stato_famiglia*`, `*stato_di_famiglia*`, `*nucleo_familiare*` |
| Certificato residenza | `*residenza*`, `*residence*`, `*certificato_residenza*` |
| Permesso soggiorno | `*permesso*soggiorno*`, `*residence_permit*` |
| ISEE/DSU | `*isee*`, `*dsu*`, `*attestazione*` |
| Busta paga/CU | `*busta_paga*`, `*cedolino*`, `*CU_*`, `*certificazione_unica*` |
| Contratto lavoro | `*contratto*lavoro*`, `*employment*`, `*assunzione*` |
| Fatture | `*fattura*`, `*invoice*`, `*ricevuta*` |
| Passaporto | `*passaporto*`, `*passport*` |

Cartelle prioritarie da cui partire (adatta alla struttura filesystem dell'utente):
- Cartelle con documenti familiari (es. `FAMILY/`, `Famiglia/`)
- Cartelle con documenti personali/ID (es. `ID/`, `Documenti/`)
- `Downloads/` (documenti scaricati di recente)
- Cartelle archivio (come fallback, documenti più vecchi)

Esplora prima la root delle cartelle montate per capire la struttura dell'utente.

**2. Google Drive (se MCP collegato)**
Se il tool `google_drive_search` è disponibile, cerca anche lì con query mirate. Utile per documenti condivisi o scannerizzati dal telefono.

**3. Notion (se MCP collegato)**
Cerca pagine Notion che potrebbero contenere allegati o riferimenti a documenti.

### Fase 3: Filtrare e selezionare

Per ogni tipo di documento richiesto:

1. **Se trovi più versioni dello stesso documento**, scegli la più recente (per data di modifica) a meno che il contesto non richieda diversamente
2. **Controlla le dimensioni** se ci sono limiti (es. 2MB per allegato INPS). Segnala file che superano il limite
3. **Elimina duplicati reali** (stesso file in cartelle diverse). Confronta per nome e dimensione
4. **Segnala documenti potenzialmente scaduti** (es. stato di famiglia di 2+ anni fa, carta d'identità scaduta)

### Fase 4: Copiare e rinominare

Copia i documenti selezionati nella cartella di lavoro con nomi che seguono questo schema:

```
XX_tipo_documento_persona.estensione
```

Dove:
- `XX` = numero progressivo a 2 cifre (01, 02, 03...)
- `tipo_documento` = descrizione chiara in snake_case
- `persona` = nome della persona a cui appartiene (se rilevante)
- L'estensione resta quella originale

Esempi:
- `01_certificato_nascita_figlio.pdf`
- `02_carta_identita_coniuge.pdf`
- `03_codice_fiscale_coniuge.pdf`

### Fase 5: Report finale

Mostra una tabella riepilogativa con:

| # | File | Cosa dimostra | Dimensione | Note |
|---|------|--------------|------------|------|

Segnala:
- Documenti trovati e copiati
- Documenti richiesti ma NON trovati (con suggerimento su dove procurarli)
- Documenti trovati ma potenzialmente problematici (scaduti, troppo grandi, versione vecchia)

## Cose da ricordare

- Mai sovrascrivere file esistenti nella cartella di lavoro senza chiedere
- Se un file ha un nome illeggibile (es. URL encodato, hash), rinominalo sempre
- Preferisci PDF e immagini (i formati più accettati dalle PA italiane)
- Se il filesystem non è montato, usa `request_cowork_directory` per chiedere accesso
- Il nome del file rinominato deve essere cercabile: qualcuno che fa Ctrl+F nella cartella deve poter trovare "carta_identita" o "codice_fiscale"
