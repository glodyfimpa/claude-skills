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

> ✅ **STATO: corso completo — 233/233 distillato (2026-06-17).** Tutte le lezioni sono
> trascritte e sintetizzate, il tracker è a 233/233. Questa skill ha esaurito il suo scopo
> per il corso BnB Academy: NON c'è più nulla da distillare. Serve ancora solo come (a)
> riferimento per RI-trascrivere una lezione dall'hash salvato nel runbook (senza riaprire il
> browser), (b) modello di protocollo per un eventuale 2° corso (vedi "Candidati estrazione
> futura"). Se Glody chiede di "distillare le lezioni", verificare prima il tracker: è già
> tutto fatto.

Processa le lezioni del corso BnB Academy in gruppi (default 20, anche di più), con checkpoint
umano a ogni gruppo. Non è un generatore di sintesi in serie: il pilot 001-005 ha mostrato che 4 lezioni
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

`N` = numero di lezioni da processare in questo run (default **20**). Il timebox è in lezioni,
non in minuti. Glody preferisce gruppi grandi per chiudere la distill prima: se non passa un
`N`, punta a **20+** e spingiti oltre quando la macchina regge e il contenuto scorre, non
fermarti a 5. Il checkpoint umano resta a ogni gruppo (vedi Fase 4), ma il gruppo è grande.

## Saturazione macchina — il thread principale NON aspetta mai (direttiva permanente)

Regola di Glody, da applicare sempre senza che la ripeta: **sfrutta ogni tempo morto, il main
non resta mai in attesa che un background finisca.** Il pipeline ha 3 stadi con vincoli diversi
— incastrali, non eseguirli a barriera:

- **Fase 1 (browser)** = lavoro del main, seriale (un solo Chrome). Mentre un download `curl` o
  un whisper girano in background, il main avanza la Fase 1 sulla lezione successiva (apri →
  leggi hash → lancia download in background → passa alla prossima). Non guardare il download.
- **Fase 2 (whisper)** = background, seriale obbligato (mai due insieme: contesa CPU). Lancia
  le trascrizioni in coda in background e prosegui.
- **Fase 3 (confronto)** = sub-agenti paralleli, sicuri (leggono file + WebSearch, niente
  browser). Lanciali sulle lezioni GIÀ trascritte mentre la Fase 2 macina le successive e il
  main fa Fase 1 sulle ancora-da-aprire.

Il lavoro che il main porta avanti nei tempi morti deve essere **non in conflitto** con i
background: avanzare la Fase 1 nel browser (risorsa esclusiva del main) mentre download/whisper
girano è il caso canonico. Non lanciare due cose che competono per la stessa risorsa (due
whisper, due agenti sullo stesso Chrome). Pattern di riferimento già nel CLAUDE.md globale:
"Parallelismo proattivo — decidere io, non l'utente".

## Modalità leggera per la Traccia Passiva (lezioni 191-230)

La Traccia Passiva del corso (Mod 10 analisi host, Mod 11 case study, le 23 FAQ
#OresteRisponde) è marcata "ascolto serale, senza ordine" e si è rivelata **quasi
interamente N/A per Via Braida**: analisi di annunci altrui, case study narrativi, FAQ su
acquisizione/PM. Distillarla col rigore pieno (un sub-agente di confronto per lezione + gate
fonti) è costo che non si ripaga su contenuto N/A — verificato sul gruppo 191-233 (distillato
2026-06-17): 43 lezioni, zero fix nuovi propagati, tutto già coperto dai moduli Nucleo→Fase 5.

**Regola: per la Traccia Passiva usa la modalità leggera** (salvo che Glody chieda il rigore
pieno). Il deliverable che resta è la **trascrizione cercabile**, non la sintesi:

1. **Scarica + trascrivi** normalmente (così il contenuto resta cercabile nel vault).
2. **NIENTE sub-agente di confronto pieno.** Il main scrive la sintesi snella a mano: 2-3
   punti + tabella con una riga `N/A` + "nessuna azione". Una funzione helper bash che genera
   il file da pochi parametri è il modo più veloce (vedi gruppo 191-233).
3. **Scan datati a colpo d'occhio**: il main legge la trascrizione e marca SOLO se trova un
   claim Airbnb/fiscale/normativo databile. Vale ancora il GATE FONTI (claim prodotto Airbnb →
   `DA VERIFICARE` se non confermato a fonte ufficiale; vedi 227 rating). Le FAQ
   fiscali/normative meritano l'occhio in più (es. APE, metratura, soglia 30 giorni, PM/P.IVA,
   contanti) — ma di norma confermano la nostra knowledge o ne sono una versione più povera.
4. **Niente checkpoint a gruppi di 20 per la passiva**: si può catturare/distillare in blocco
   e fare UN solo checkpoint finale, vista la resa.

Distinzione netta: i moduli **Nucleo → Fase 5** (lezioni ~1-190) vanno col **rigore pieno**
(sub-agente + gate), perché è lì che vive il valore (compliance, fisco, prodotto). La passiva
no. Se una lezione passiva sorprende con un claim databile reale, alza tu il rigore su quella
singola, non sull'intero blocco.

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
2. **Chrome loggato su BnB Academy** col profilo che ha l'accesso **pagato** (NON Arc).
   ⚠️ **`0/233` NON significa "account sbagliato"** (corretto 2026-06-15): l'account giusto
   può mostrare `0/233` perché è un **render stantio** della SPA (contatore prima che il
   progresso si idrati). Non fermarsi su quel dato: attendere l'idratazione, oppure
   controllare la vista libreria `/courses/library-v2` che mostra il % reale (BnB Academy al
   6%, avatar GF, "I miei corsi 2" = accesso OK). L'account "Personal Chrome" (login Google
   glodyfimpa) è quello giusto e pagato — confermato. Fermarsi solo se ANCHE la vista libreria
   non mostra il corso (vero account senza accesso). Vedi memory `project-bnb-academy-account-access`.
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
4. (Facoltativo, igiene) **Metti in pausa il video** dopo aver letto l'hash (`document.querySelector('video').pause()`):
   il play serve SOLO a far scaricare i segmenti da cui si legge l'hash, non a "guardare" il
   video. Lasciarlo girare a vuoto è spreco innocuo ma disordinato.
5. Scarica l'audio: `python3 fetch_audio.py NNN <HASH>` → `audio/NNN.ts`.

> ℹ️ **Perché NON si perde nessuna parte del video** (dubbio legittimo). Il play nel browser
> non è la fonte del contenuto: serve solo a costringere il player a scaricare i segmenti, dal
> cui URL si legge l'`<HASH>` (= "numero di scaffale" della lezione). Una volta letto l'hash,
> `fetch_audio.py` scarica il file **completo dall'inizio alla fine** direttamente dal CDN
> (come scaricare un PDF), indipendentemente da quanto il video sia avanzato nel browser. Quindi
> il fatto che il video continui a scorrere mentre si fa altro è irrilevante: la trascrizione è
> sempre della lezione intera. Il gate durata (sotto) lo conferma a costo zero.

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

> ⚠️ **Webinar / Video-Call lunghi (>1h) — download fragile + contenuto diluito (verificato 131-150).**
> Alcune lezioni del corso (es. i "Macro-aggiornamenti"/"Video-Call Interna") sono dirette/webinar
> da 2-3.5h. Due conseguenze:
> 1. **Il download CDN si tronca spesso** su file così lunghi (HTTP 502 / socket timeout, non
>    sistematico: nel gruppo 131-150 134/136 troncati, 135/137/138 integri). GATE: confronta la
>    durata audio scaricata con quella letta dal player (`ffprobe` vs durata `<video>`); se manca
>    una porzione, **marca la sintesi "parziale ~X/Y min", NON spacciarla completa**. Ri-scaricare
>    dall'hash a volte riesce (è andata così per la 138). Il file integro può superare gli 800 MB.
> 2. **Sono contenuto community/Q&A/promo, valore di dominio diluito.** Il sub-agente deve scorrere
>    (non leggere parola per parola), estrarre i 3-6 punti reali, e marcare il resto N/A-community
>    senza gonfiare. whisper su 3h aggiunge spesso un loop allucinato in coda (artefatto noto, nulla
>    perso). Costo alto, resa bassa: valutare con Glody se distillarli o lasciarli come allegato-hash.

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
5. **Comportamento di un prodotto (Airbnb in primis) → SOLO fonte ufficiale del fornitore.**
   Regola rafforzata dopo l'errore del gruppo 131-150: un claim su **commissioni / ranking /
   policy / feature** di Airbnb (o altra piattaforma) si marca `DATATO`/`IMPRECISO` **solo** se
   sostenuto da Airbnb Help/Terms o newsroom (URL `airbnb.com` / `news.airbnb.com`). Con **solo**
   blog di settore (Hostaway, Futurestay, Lodgify, thehostreport, AirDNA blog, OptimizeMyBnb…) o
   thread community → marca `DA VERIFICARE`, **MAI `DATATO`**. Caso reale: i sub-agenti avevano
   marcato "split-fee 3% dismesso", "copertina scelta dall'algoritmo", "Smart Setup è il default" —
   tutti **falsi/non confermati** alla fonte ufficiale (Help art. 1857: lo split-fee resta; art.
   477: l'host controlla la copertina). I blog STR sono i primi risultati di ricerca e si copiano:
   sono la trappola numero uno di questa skill.
6. **La testimonianza diretta di Glody sul suo account/strumento è FONTE PRIMARIA.** Se Glody
   dice "ho l'opzione X attiva ora", quello batte qualsiasi blog. Non contraddire un fatto di
   prima mano dell'utente con un consenso di blog.

### Fase 4 · CHECKPOINT — main, sequenziale, umano. STOP.

1. Presenta a Glody le sintesi del gruppo, evidenziando i punti `DATATO` / `DA VERIFICARE`
   (è lì il valore, non nelle conferme "tutto ATTUALE").
2. Glody valida o contesta.
3. Propaga i fix validati alle procedure (es. una correzione di soglia in
   `procedure/gestione-recensioni.md`).
   > ⚠️ **Prima di propagare a un artefatto in uso** (procedura, knowledge, tool/skill, codice):
   > il fix dev'essere **verificato alla fonte ufficiale**, non solo riportato da un sub-agente.
   > "Validato da un sub-agente" ≠ "verificato". Nel gruppo 131-150 un claim-da-blog è stato
   > propagato nei tool `bnb-investment-toolkit` (cambiato persino il default di calcolo) e ha
   > richiesto un `git checkout` per annullarlo. Se il fix tocca un prodotto esterno, applica il
   > GATE FONTI punto 5 (Help ufficiale) PRIMA dell'edit. In dubbio, porta il punto a Glody invece
   > di propagare.
4. Spunta le lezioni nel tracker (`- [ ]` → `- [x]`, aggiungi `· [[NNN|sintesi]]`) e aggiorna
   il contatore `Progresso: X/233` con i sotto-totali per fase.
5. **Pulisci `audio/*.ts` e `*.wav` PRIMA del commit** (grossi, rigenerabili dall'hash via
   `fetch_audio.py`). Tieni solo `transcripts/`, `sintesi/`, `allegati/`.
6. **Commit** — committa SOLO `sintesi/`, `transcripts/`, `allegati/`, knowledge/procedure
   modificate, tracker. **Mai `git add` della cartella `audio/`** (vedi gate sotto).
7. Push se richiesto.

> ⚠️⚠️ **GATE: l'audio NON va mai in git (errore 051-070, 2026-06-16).** `audio/*.ts`/`*.wav`
> sono ~700MB/gruppo di spazzatura intermedia, rigenerabili dagli hash salvati nel runbook.
> `audio/` è già in `.gitignore` (`areas/affitti-brevi/bnb-academy/analisi-lezioni/audio/`).
> Errore commesso: `git add` della cartella `analisi-lezioni/` PRIMA di pulire ha forzato gli
> audio in git scavalcando gitignore (git ignora il gitignore per file aggiunti esplicitamente
> via cartella padre già tracciata). Conseguenza: 687MB committati, poi rewrite della history
> per toglierli prima del push. **Regola operativa**: (a) pulizia audio = step 5, PRIMA del
> commit; (b) `git add` mirato sui soli path buoni (`...analisi-lezioni/sintesi`,
> `.../transcripts`, `.../allegati`), MAI `git add` della cartella `analisi-lezioni/` intera né
> `git add -A`; (c) prima di committare, `git status` e verificare zero `audio/` staged.

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
