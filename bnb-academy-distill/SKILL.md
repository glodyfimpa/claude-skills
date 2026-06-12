---
name: bnb-academy-distill
description: >
  Processa a gruppi le lezioni video del corso BnB Academy: scarica l'audio dal CDN,
  lo trascrive offline con whisper, confronta ogni lezione con la nostra knowledge base
  marcando cosa è ATTUALE nel 2026 e cosa è DATATO (sempre con una fonte citata, mai a
  naso), e si ferma a un checkpoint umano per ogni gruppo. Usa questa skill quando Glody
  dice "distilla le lezioni", "/bnb-academy-distill", "prossimo gruppo di lezioni del
  corso", "analizza le lezioni BnB Academy", "riprendi le lezioni dal tracker", o varianti.
  NON usare per: ricerca generica sul web, riassunti di altri corsi o video, o per
  sfornare tutte le 233 sintesi in autonomia (è lavoro assistito a checkpoint, non
  fire-and-forget).
---

# BnB Academy Distill

Processa le lezioni del corso BnB Academy in gruppi piccoli, con checkpoint umano a ogni
gruppo. Non è un generatore di sintesi in serie: il pilot 001-005 ha mostrato che 4 lezioni
su 5 erano già coperte dalle nostre procedure, e il valore reale sono **i 2-3 punti dove il
corso o la nostra knowledge erano sbagliati** (es. soglia Superhost, mito viste/preferiti).
Quei punti richiedono giudizio umano e confronto con le fonti, non si automatizzano in serie
senza riprodurre l'errore "marcare a naso".

## Quando NON usarla

- Per distillare tutte le 233 lezioni in un colpo solo. È assistita a checkpoint: N lezioni
  per run, validazione di Glody a ogni gruppo.
- Per corsi diversi da BnB Academy. È una skill specifica (un solo corso oggi); l'estrazione
  a una skill generica avverrà solo al 2° corso (vedi "Candidati estrazione futura").

## Argomento

```
/bnb-academy-distill [N]
```

`N` = numero di lezioni da processare in questo run (default **5**). Il timebox è in lezioni,
non in minuti.

## Cartella di lavoro e fonte dei dettagli tecnici

Tutto vive in:

```
~/Documents/brain/areas/affitti-brevi/bnb-academy/
├── analisi-lezioni/
│   ├── fetch_audio.py        # download audio dal CDN (testato, retry su 429)
│   ├── transcribe.sh         # ffmpeg + whisper -> transcripts/NNN.txt
│   ├── runbook.md            # ★ dettagli tecnici (JS browser, hash, costanti CDN)
│   ├── transcripts/          # output trascrizioni
│   └── sintesi/              # output sintesi NNN.md
└── tracker-lezioni.md        # macchina a stati (checkbox + contatore)
```

I percorsi `references/...` citati sotto sono relativi a questa skill (accanto allo
`SKILL.md`), non alla cartella di lavoro: `references/golden-set.md` è il riferimento
qualità per la Fase 3.

**`analisi-lezioni/runbook.md` è la fonte di verità per i dettagli tecnici** (selettori del
click per titolo, `read_network_requests` per l'hash, costanti Location/Product/CDN, nota
account). Questa skill orchestra il protocollo e applica i gate; per i comandi browser
esatti rimanda al runbook. Non duplicare quei dettagli qui: se il corso cambia l'HTML, si
aggiorna un solo posto.

## Prerequisiti — verifica PRIMA di iniziare

1. **Toolchain offline verde**: `ffmpeg`, `whisper-cli` in PATH, modello in
   `~/.cache/whisper/ggml-small.bin`. Se manca, fermarsi e segnalarlo.
2. **Chrome loggato su BnB Academy** col profilo che ha l'accesso **pagato**. Verificare che
   il progresso del corso NON sia 0/233 (sintomo di account sbagliato, vedi nota account nel
   runbook). Se è 0/233, fermarsi: le lezioni non si aprono.
3. **cwd per gli script** = `~/Documents/brain/areas/affitti-brevi/bnb-academy/analisi-lezioni/`.

## Stato e ripresa

`tracker-lezioni.md` **è** la macchina a stati, come `progresso.md` lo era per `/sbm-resume`.
Non esiste uno stato separato.

- Le lezioni spuntate `- [x]` sono fatte; le `- [ ]` no.
- Il prossimo gruppo = le **prime N** lezioni `- [ ]` in ordine dall'alto.
- Il titolo accanto al numero (`001 · Mod 9 — Come richiedere una recensione`) è il **titolo
  esatto** che serve per il click nel browser (Fase 1).
- Il contatore in cima (`Progresso: X/233`) va aggiornato in Fase 4.

Leggere il tracker, individuare il gruppo, annunciarlo a Glody prima di partire.

## Protocollo — 4 fasi

Pattern **pipeline, non barriera**: mentre whisper trascrive la lezione N (Fase 2), un
sub-agente può già confrontare la N-1 trascritta (Fase 3).

### Fase 1 · SCARICA — main, browser singolo, NO sub-agenti

Per ogni lezione del gruppo, nell'ordine del tracker:

1. Apri la lezione cliccando il **titolo esatto** (runbook, Passo 1). Due viste DOM diverse:
   la **home corso** (`?source=courses` senza `/posts/`) mostra l'albero completo di tutti i
   moduli → il click-per-titolo funziona per qualsiasi lezione. **Dentro** una lezione
   (`/posts/<id>`) l'indice laterale si restringe al modulo corrente → per una lezione di un
   altro modulo torna prima alla home.
2. **Cattura il testo allegato** della lezione (template, note): spesso è già metà del
   valore e costa zero (runbook, Passo 1). Non tutte le lezioni ce l'hanno (molte sono solo
   video): se assente, il valore è tutto nella trascrizione.
3. Leggi l'hash video (`cts-<HASH>_`). ⚠️ **Punto fragile, verificato nel collaudo 006-010.**
4. Scarica l'audio: `python3 fetch_audio.py NNN <HASH>` → `audio/NNN.ts`.

> ⚠️ **La cattura dell'hash è il punto debole del protocollo.** Il player HLS **precarica
> ~230 manifest** (tutti i video del corso) all'apertura, quindi "l'ultimo `master.m3u8`
> richiesto" NON è la lezione corrente. Nel collaudo 006-010 solo **2 hash su 5** erano
> corretti col metodo automatico. Conseguenze pratiche:
> - L'unico hash isolabile in modo pulito da `read_network_requests` è quello della **PRIMA**
>   lezione aperta in una sessione di rete vergine (prima che il precaricamento completi).
> - `read_network_requests(clear:true)` può sforare i token (skill `mcp-tokens-overflow-handler`).
> - La `performance.getEntriesByType('resource')` vede le risorse anche pre-tracking, ma
>   restituisce TUTTI i manifest precaricati, non isola la lezione corrente.
> - **Metodo robusto da definire** (TODO build): una mappa `postId → hash` (il postId è nell'URL
>   della lezione, stabile), o leggere l'url da hls.js. Finché non c'è, la cattura hash va fatta
>   con cautela e SEMPRE validata (gate sotto).

> ⚠️ **GATE coerenza hash — obbligatorio prima di trascrivere (Fase 1 → Fase 2).** Un hash
> sbagliato scarica il video di un'altra lezione. Due controlli a costo quasi zero che lo
> rivelano:
> 1. **Durata**: `ffprobe -v error -show_entries format=duration -of csv=p=0 audio/NNN.ts`.
>    Se la durata è incongrua con una lezione tematica (es. 74 min per una lezione corta, o
>    2 min), l'hash è quasi certamente sbagliato → riscarica, non trascrivere.
> 2. **Coerenza titolo↔contenuto**: dopo la trascrizione, le prime righe del transcript
>    devono parlare dell'argomento del titolo. Nel collaudo la 006 aveva durata plausibile
>    (13 min) ma era il video sbagliato ("obiettivo del corso" invece di "Le date HOT") — solo
>    la trascrizione l'ha rivelato. Se il contenuto non combacia col titolo: hash sbagliato,
>    scarta la sintesi, riscarica con hash corretto.

> ⚠️ **Un solo Chrome.** Mai parallelizzare la Fase 1 con sub-agenti: collisione
> Playwright/Chrome (vedi environment-macos). I download `curl` di `fetch_audio.py` sono già
> veloci e sequenziali; il rate-limit 429 del CDN è gestito dal retry dello script.

### Fase 2 · TRASCRIVI — main, SERIALE OBBLIGATO

Per ogni `audio/NNN.ts`: `./transcribe.sh NNN` → `transcripts/NNN.txt`.

> ⚠️ **Mai due whisper insieme.** È CPU-bound a ~1× realtime: due trascrizioni in parallelo
> = 2× tempo per contesa CPU, zero guadagno (misurato nel pilot). È il collo di bottiglia
> reale: serializzare.

### Fase 3 · CONFRONTA — parallelizzabile via sub-agenti

Un sub-agente indipendente per lezione trascritta. **Prima di abbozzare**, ogni sub-agente
legge `references/golden-set.md` (criteri di qualità + due esempi calibrati dal pilot: il
pattern "CORSO IMPRECISO con fonte" della 001 e la marcatura calibrata non-allarmista della
002). Poi legge `transcripts/NNN.txt` + il testo allegato della Fase 1, e produce
`sintesi/NNN.md` con questa struttura fissa:

```markdown
# NNN — <titolo lezione>

## Sintesi (5-8 punti)
- ...

## Confronto con la nostra knowledge
| Affermazione del corso | Stato 2026 | Fonte di verità |
|---|---|---|
| ... | ATTUALE / DATATO / DA VERIFICARE | [[locazioni-turistiche-compliance]] o link |

## Azioni per Via Braida
- [ ] ...
```

Confrontare sempre contro: `[[locazioni-turistiche-compliance]]`, le procedure in
`areas/affitti-brevi/procedure/`, la revisione pricing
`appartamenti/via-braida/outputs/pricing-revisione-2026-06-10.md`.

> ⚠️ Sub-agenti sicuri da parallelizzare: leggono file + fanno WebSearch, **niente browser
> condiviso**. Pipeline: lanciali sulle lezioni già trascritte mentre la Fase 2 macina la
> successiva.

#### ░░ GATE FONTI — obbligatorio, non aggirabile ░░

1. **Nessuna marcatura `DATATO` / `IMPRECISO` / `PENALIZZA` senza una fonte citata (link).**
   Questo è il fix strutturale del bug del pilot (002): marcare a naso è vietato.
2. **Confronto alla pari.** Corso ↔ nostra knowledge ↔ fonte, senza vincitore predefinito.
   A volte la nostra knowledge corregge il corso, a volte una fonte esterna corregge
   entrambi. Il discriminante non è "chi ha ragione" ma **è applicabile oggi (2026)?** —
   molte lezioni sono girate nel 2019-2023.
3. **Non fidarsi del primo cluster di blog** che si copiano a vicenda. Cercare la doc
   ufficiale (Airbnb Help) o un esperto tecnico riconosciuto prima di marcare.
4. **Fonte non trovata dopo aver provato** → marca `DA VERIFICARE` onesto e segnala a Glody
   "non risolto, decidi tu". **Non forzare** una marcatura.

### Fase 4 · CHECKPOINT — main, sequenziale, umano. STOP.

1. Presenta a Glody le sintesi del gruppo, evidenziando i punti `DATATO` / `DA VERIFICARE`
   (è lì il valore, non nelle conferme "tutto ATTUALE").
2. Glody valida o contesta.
3. Propaga i fix validati alle procedure (es. una correzione di soglia in
   `procedure/gestione-recensioni.md`).
4. Spunta le lezioni nel tracker (`- [ ]` → `- [x]`, aggiungi `· [[NNN|sintesi]]`) e aggiorna
   il contatore `Progresso: X/233` con i sotto-totali per fase.
5. Commit.
6. **Pulisci** `audio/*.ts` e `audio/*.wav` (grossi, rigenerabili dall'hash via
   `fetch_audio.py`). Tieni solo `transcripts/` e `sintesi/`.

Poi: chiedi a Glody se procedere col gruppo successivo o fermarsi qui.

## Regole incorporate (dal pilot 001-005)

1. **Gate verifica fonti** (fix bug 002): marcatura solo con fonte. Vedi Fase 3.
2. **Confronto alla pari**: nessun vincitore a priori, discriminante = applicabilità 2026.
3. **Non fidarsi del primo cluster di blog**: doc ufficiale o esperto tecnico prima di
   marcare. Lezione metodologica nella memory `feedback-compare-dont-assume-winner`.
4. **Checkpoint umano** a ogni gruppo: niente sintesi cieche in serie.

## Candidati estrazione futura (per il 2° corso, NON ora)

Questa skill è specifica per un solo corso. Quando arriverà un 2° corso da distillare, e si
vedrà cosa si è davvero ripetuto, valutare l'estrazione di una skill generica
`video-lesson-distill` da questi 3 pezzi:

- **Motore download autenticato**: browser → leggi URL media dalla rete della pagina
  autenticata → scarica server-side senza token. Oggi specifico di apisystem.tech/plyr.
- **Protocollo confronto knowledge**: trascrivi → marca → gate fonti → checkpoint. Già
  agnostico al dominio.
- **Tracker-as-state-machine**: checkbox + contatore come stato di ripresa (pattern SBM).

Non astrarre prima: regola "no astrazione a 1 occorrenza".
