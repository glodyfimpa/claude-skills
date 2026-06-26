---
name: portable-local-routine
description: >
  Gate di portabilità per routine e agenti schedulati LOCALI (script che girano a
  orari fissi via launchd/cron, non nel cloud di Claude). Lo standard: una routine
  locale si costruisce portabile, gira via clone su QUALSIASI PC — il Mac oggi, una
  VPS Linux sempre accesa domani — senza riscrivere niente e senza dipendere dal
  cloud. Usa questa skill quando stai costruendo o modificando una routine/agente
  schedulato locale (modalità build, come gate prima di considerarlo finito) O quando
  vuoi controllare una routine esistente e conformarla allo standard (modalità audit).
  Include un gate a monte (Gate 0) che decide la FORMA giusta: routine locale launchd/cron,
  Claude routine dentro l'app (quando serve un MCP autenticato interattivamente nell'app), o
  ibrido — usalo anche quando ti chiedi "questa la faccio come scheduled-task Claude o come
  script launchd?" o "mi servono gli MCP per questa routine?".
  L'asse che decide il trigger è "schedulato o no": questa skill fira solo quando
  l'artefatto è una routine SCHEDULATA (launchd/cron/job a orari fissi); per la
  portabilità di SINTASSI di uno script bash qualsiasi non-schedulato delega a
  bash-portability-linter. Triggera su: "routine portabile", "questa routine
  schedulata gira su ogni PC", "che giri anche su VPS", "scheduling locale", "launchd",
  "cron job locale", "portable local routine", "controlla la portabilità di questa
  routine", "audit routine locale", "questa routine gira solo sul mio Mac?", "rendi
  portabile questo script schedulato". NON triggera per: routine cloud-native (Claude
  Code Routines/CCR), portabilità di sintassi di uno script non-schedulato (→
  bash-portability-linter, bash 3.2/BSD), o CI/CD su runner cloud.
---

# Portable Local Routine — gate di portabilità

Una "routine locale" è uno script (di solito bash + `claude -p`/CLI) che gira a orari
fissi su un PC, lanciato da uno scheduler del sistema operativo (launchd su macOS, cron
su Linux). A differenza di una Claude Code Routine cloud, non gira a PC spento — ma con
un design portabile lo stesso clone può girare su un PC/VPS sempre acceso, risolvendo il
caso "PC spento" per spostamento dell'hardware invece che per cambio di runtime.

Questa skill è il **gate** che garantisce quel design. Una routine costruita male è
inchiodata a una macchina: path assoluti che esistono solo lì, scheduler scritto per un
solo OS, segreti non clonabili, dipendenze implicite. Spostarla su un altro PC diventa
una riscrittura. Il gate previene quel debito mentre il costo di evitarlo è ancora basso.

## Gate 0 — è davvero il caso di una routine locale? (decidi PRIMA dei 7 criteri)

Prima di applicare i criteri di portabilità, decidi *in quale forma* va costruita la
routine. Esistono tre forme, e si scelgono in base a UNA domanda: **la routine ha bisogno
di un MCP che è autenticato interattivamente dentro l'app Claude** (Notion/Calendar/Gmail
collegati cliccando in Claude Desktop, sessione OAuth viva nell'app)?

Non confondere "usa un MCP" con "usa un MCP dell'app". `claude -p` headless **può** caricare
server MCP via `--mcp-config` se l'MCP è process-based e si autentica da solo (token in env
o file). Il discriminante non è "MCP sì/no", è **come è autenticato**:

- **MCP stdio/process-based, credenziali in env o file** → `claude -p` lo carica con
  `--mcp-config`, funziona headless anche su VPS. Conta come "solo-CLI" ai fini di questo gate.
- **MCP autenticato interattivamente nell'app** (OAuth fatto nell'UI, sessione che vive
  nell'app) → un `claude -p` headless parte come processo nuovo, con il proprio contesto
  MCP, e non riusa la sessione OAuth viva nell'app: quell'MCP gli risulta tipicamente
  assente. È la stessa gotcha già osservata sulle routine cloud CCR ("interactively-
  authenticated MCP servers may be absent in headless runs"). Trattalo come comportamento
  da verificare nel caso specifico (un MCP process-based con token in env si ricarica via
  `--mcp-config`; uno OAuth-interattivo no), non come legge assoluta — se in dubbio, prova
  `claude -p --mcp-config ... -p "usa il tool X"` una volta e guarda se il tool risponde.

### Le tre forme

**A. Solo-CLI / MCP-headless-configurabile → routine locale launchd/cron** (quella che
questa skill standardizza). La routine fa lavoro da riga di comando (`git`, `gh`, `curl`,
`claude -p`, test runner) ed eventuali MCP autenticabili da sé via `--mcp-config`. È la
scelta **strettamente migliore** quando si applica: gira come processo del SO (non si
interrompe se usi l'app, gira anche con l'app chiusa) ed è portabile su VPS. Procedi con i
7 criteri sotto.

**B. Serve un MCP interattivo dell'app, e SOLO quello → Claude routine dentro l'app**
(scheduled-task in `~/.claude/scheduled-tasks/`, non questa skill). Accetti i due limiti
noti — si interrompe se l'app è occupata al fire ([reference] task local interrotto da
sessione attiva), non gira su VPS — perché sono il prezzo per avere la sessione MCP viva.
Questa skill non si applica: NON forzare la forma launchd su una routine che dipende da un
MCP interattivo, la romperesti.

**C. Misto: serve un MCP interattivo dell'app PER UNA PARTE, più lavoro CLI/git/PR per il
resto → ibrido a due stadi.** Lo stadio MCP gira dentro l'app (legge Notion/Calendar/Gmail)
e **passa i dati già estratti come argomenti** a uno script portabile, che fa la parte CLI.
Attenzione al falso ibrido: una routine-app che lancia uno script il quale richiama
`claude -p` **non** trasferisce gli MCP dell'app al sotto-processo (`claude -p` riparte da
zero). L'ibrido che regge è "l'app estrae → lo script elabora i dati estratti", non "l'app
chiama un claude headless sperando che erediti gli MCP". Lo script della parte CLI va reso
portabile coi 7 criteri sotto; lo stadio MCP-app resta dentro l'app.

### Decisione (due assi)

Il primo asse è "serve un MCP interattivo dell'app?"; il secondo, che separa B da C, è
"c'è lavoro CLI sostanziale (git/PR/test) oltre alla parte MCP?".

| MCP interattivo dell'app? | + lavoro CLI sostanziale? | Forma |
|---|---|---|
| No | (qualunque) | **A** — script launchd/cron (questa skill) |
| Sì, ed è tutto lì | No | **B** — Claude scheduled-task dentro l'app |
| Sì, ma solo per una parte | Sì | **C** — l'app estrae i dati → script portabile li elabora |

"Lavoro CLI sostanziale" = abbastanza da giustificare uno script portabile a parte (aprire
issue/PR, girare test, build). Una singola `curl` di notifica NON lo è: una routine che
legge un MCP-app e manda un Telegram resta forma B, non diventa C per via del curl finale.

Se sei in forma A o nello stadio-script della forma C, prosegui coi 7 criteri. Se sei in
forma B, questa skill non è quella giusta.

## Quando usarla — due modalità

**`build`** — stai costruendo una routine nuova. Usa i 7 criteri sotto come checklist
prima di considerarla finita. Idealmente trasformali in TODO così non ne salti uno.

**`audit`** — esiste già una routine e vuoi sapere se è portabile (o conformarla). Leggi
gli script reali, applica i 7 criteri uno per uno, e produci il **report** sotto: cosa è
conforme, cosa no, e come si sistema. In questa versione la skill **consiglia, non
modifica**: i fix li applica chi guida la sessione, dopo aver visto il report.

## I 7 criteri di portabilità

Per ciascuno: cosa controllare, perché conta, come si sistema.

### 1. Nessun path assoluto hard-coded
Cerca `/Users/...`, `/home/...`, `/opt/homebrew`, un `$HOME` letterale incollato, path che
contengono uno username. Perché conta: su un altro PC quello username non esiste e lo
script rompe al primo accesso. Fix: risolvi la radice dello script una volta sola con
`SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"` e costruisci tutto
relativo a quello. Per le directory utente usa le variabili d'ambiente (`$HOME`,
`${XDG_CONFIG_HOME:-$HOME/.config}`), non il path espanso.

### 2. Shebang ed esecuzione neutrali rispetto alla macchina
`#!/usr/bin/env bash`, non `#!/bin/bash` (su alcuni sistemi bash non è in `/bin`). Evita
costrutti bash 4+ se il target può essere il bash 3.2 di macOS (per la sintassi fine c'è
la skill `bash-portability-linter`). Perché conta: un'incompatibilità di shell si manifesta
solo sull'altra macchina, dopo che pensavi fosse a posto.

### 3. Lo scheduler NON è OS-locked
Il pezzo che installa lo scheduling deve sapere girare su più OS. Un installer launchd-only
non parte su una VPS Linux; un systemd-timer-only non parte sul Mac. Fix: un installer che
rileva l'OS (`uname -s`) e installa il meccanismo nativo — launchd su macOS, cron su Linux —
dietro un comando unico (`./schedule.sh install`). cron è il minimo comune denominatore
(c'è ovunque); launchd in più dà su Mac il recupero dei fire persi durante lo sleep.
In **audit**: uno scheduler launchd-only non è un difetto, è un *gap di portabilità* — la
routine funziona oggi sul Mac, le manca solo il ramo cron per girare su una VPS. Marcalo
`[FIX]` con "aggiungere il ramo cron", non come errore.

### 4. Segreti clonabili, mai versionati
Token e chiavi vivono in un file `.env` gitignored, accanto a un `.env.example` versionato
che elenca le variabili senza i valori. Perché conta: così clonare è "copia `.env.example`
→ `.env`, compila, parti", e nessun segreto finisce nella storia git. Mai segreti hard-coded
nello script né committati.

### 5. Dipendenze dichiarate + preflight + fail-fast
Elenca i binari che la routine invoca (`jq`, `gh`, `git`, `curl`, `claude`, `python3`, …).
Una macchina fresca (VPS appena provisionata) potrebbe non averli. Fix: un preflight check
all'avvio dell'installer che verifica ogni dipendenza e fallisce **chiaro** nominando cosa
manca, invece di crashare a metà del primo fire con un errore oscuro. Correlato:
`set -euo pipefail` in cima a ogni script. Senza `set -e` un comando fallito non ferma il
run e la routine "fa finta di aver lavorato" — esattamente il fire-che-non-fa-nulla che il
criterio 7 cerca di diagnosticare. È robustezza più che portabilità, ma è il prerequisito
che rende affidabile il resto: una routine portabile ma che ingoia i propri errori è
portabile e rotta su ogni macchina invece che su una sola.

### 6. Niente dipendenza da bridge cloud quando il target è locale
Se la routine gira in locale, le notifiche e le API vanno chiamate **dirette** (`curl` a
Telegram, `gh` diretto), non attraverso i bridge che servono solo in sandbox CCR (dove
`api.telegram.org` è bloccato e `gh` non esiste). Perché conta: trascinarsi dietro
l'impalcatura cloud in una routine locale aggiunge complessità e punti di rottura inutili.
(Il bridge serve SOLO se il target è davvero CCR — allora è un'altra routine.)

### 7. Il fire è diagnosticabile da remoto
Devi poter sapere se un run schedulato è partito senza essere fisicamente al PC. Fix: un
log strutturato (JSONL) che timestampa avvio ed esito di ogni fire. Così un fire saltato
(PC spento all'orario) si legge come **assenza di una riga attesa**, distinto da un errore
applicativo — e un errore applicativo la routine lo notifica da sé (Telegram/mail).

## Formato del report (modalità audit)

Quando audìti una routine, produci questo, una riga per criterio:

```
Audit portabilità — <nome routine>

[OK]   1. Path assoluti        — nessuno, SCRIPT_DIR via BASH_SOURCE
[FIX]  2. Shebang              — run-x.sh riga 1: #!/bin/bash → #!/usr/bin/env bash
[FIX]  3. Scheduler OS-detect  — schedule.sh è launchd-only: aggiungere il ramo cron (uname=Linux)
[FIX]  4. Segreti clonabili    — .env gitignored OK, ma manca .env.example: crearlo con le chiavi senza valori
[OK]   5. Preflight + set -e   — preflight_check copre jq/gh/git/curl/claude; set -euo pipefail presente
[N/A]  6. Bridge cloud         — routine puramente locale, nessun bridge (corretto)
[OK]   7. Fire diagnosticabile — schedule.log JSONL fire_start/fire_end

Verdetto: 3 fix per la piena portabilità (criteri 2, 3, 4). Gli altri conformi.
```

Usa `[OK]` / `[FIX]` / `[N/A]`. Il tag è il verdetto del criterio; il testo della riga
mette **per ultima** la cosa da fare (è il punchline azionabile). Per ogni `[FIX]` dai la
riga/file/comando concreto da cambiare, mai un consiglio generico. Chiudi con un verdetto
di una riga: quanti fix mancano e quali.

**Fuori scope (dichiaralo se chiesto):** questo gate copre la *portabilità*, non la
*correttezza a runtime*. La sovrapposizione di run (un fire che parte mentre il precedente
gira ancora) e i lock-file sono bug reali di routine schedulate, ma sono correttezza, non
portabilità — non li controlla questa skill. Se emergono, segnalali a parte, non come `[FIX]`.

## Nota di evoluzione

Questa versione fa **check + report**. Quando il gate è collaudato, una modalità `--fix`
potrà applicare i fix meccanici sicuri (shebang, path assoluto → `SCRIPT_DIR`) con test a
guardia. Non è in questa versione: prima si valida il giudizio, poi si automatizza la mano.
