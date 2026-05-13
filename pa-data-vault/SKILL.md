---
name: pa-data-vault
description: Gestisce dati identificativi (CF, PEC, CIN, P.IVA, codici portali) per strutture BnB e profilo personale, li rende disponibili alle altre skill PA, rileva campi mancanti e salva nuovi valori.
---

# pa-data-vault

Vault centrale dei dati identificativi per la compilazione di portali PA italiani. Fornisce un data bundle strutturato alle skill `pa-form-filler` e `pa-legal-clause-analyzer`.

I dati vivono in file Markdown sotto `references/`. Lo schema usa il segnaposto `[da completare]` per i campi non ancora inseriti: grep-able, auto-documentante, non rompe il workflow.

## Struttura References

```
pa-data-vault/references/
├── personal/
│   └── glody.md                    profilo personale (CF, PEC, credenziali portali)
└── bnb-via-braida/
    └── structure.md                dati struttura (CIN, codici, capacità, certificazioni)
```

**Aggiungere una seconda struttura**: crea `references/bnb-struttura2/structure.md` copiando lo schema da `bnb-via-braida/structure.md` e sostituendo i valori. Nessuna altra modifica richiesta.

## Workflow

### 1. Caricamento Profilo

```
INPUT: tipo profilo (personal/glody, bnb-via-braida/structure, ...)

- Leggi il file references/{tipo}.md
- Parsa i blocchi code-fence con formato key: value
- Restituisce data bundle come mappa chiave→valore
```

### 2. Detection Campi Mancanti

```
- Filtra il bundle per valori == "[da completare]"
- Restituisce lista campi_mancanti con chiave e sezione
- Esempio output:
  CAMPI MANCANTI in bnb-via-braida/structure.md:
  - [Identificazione] cin
  - [Identificazione] codice_struttura_milano
  - [Gestore] codice_fiscale_gestore
```

Se `campi_mancanti` è vuoto, il vault considera il profilo completo e restituisce il bundle senza avvisi.

### 3. Salvataggio Nuovo Valore

```
INPUT: tipo profilo, chiave campo, valore

- Leggi references/{tipo}.md
- Trova la riga "chiave: [da completare]"
- Sostituisce "[da completare]" con il valore fornito
- Riscrive il file (sed in-place, BSD compatible: sed -i '' -e 's/...' file)
- Aggiorna il bundle in memoria
```

### 4. Restituzione Data Bundle

```
OUTPUT JSON:
{
  "profile": "bnb-via-braida/structure",
  "data": {
    "cin": "[da completare]",
    "nome_struttura": "..."
  },
  "missing": ["cin", "codice_struttura_milano"]
}
```

## Ricerca Documenti su Filesystem

Per trovare documenti di identità, CIN, DIA o altri file PDF/DOCX collegati a una struttura, usa la skill **document-collector** invece di reimplementare la ricerca:

```
/document-collector cerca "CIN struttura via braida"
```

`document-collector` gestisce la ricerca su filesystem, Finder tags, e cartelle Documenti. `pa-data-vault` gestisce i dati strutturati nei reference file — non fa ricerca su filesystem.

## Error Handling

| Errore | Causa | Azione |
|--------|-------|--------|
| File non trovato | Profilo inesistente in references/ | Errore controllato: "Profilo '{tipo}' non trovato. Profili disponibili: personal/glody, bnb-via-braida/structure" |
| Formato non valido | Blocco code-fence assente o malformato | Warning + parsing parziale dei campi trovati |
| Scrittura fallita | File in sola lettura | Errore con percorso file e istruzioni chmod |
