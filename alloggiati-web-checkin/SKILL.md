---
name: alloggiati-web-checkin
description: Compila e invia le schedine ospiti su Alloggiati Web (Portale Alloggiati, Polizia di Stato, art. 109 TULPS) per una struttura ricettiva. Usa questa skill quando l'utente deve comunicare alla Questura i dati di uno o più ospiti appena arrivati: frasi come "invia le schedine", "comunica gli ospiti alla Questura", "alloggiati web per [nome ospite]", "ho i documenti del gruppo, fai il check-in PS", "registra l'arrivo su alloggiati", o quando passa le foto dei documenti di chi è arrivato. NON è la skill generica pa-form-filler: gestisce le specificità del portale Polizia (5 tipi alloggiato, Capo Gruppo→Membro, autocomplete stati esteri, campi documento solo per il capo, vincolo data oggi/ieri, arrivi scaglionati). L'utente fa login + 2FA a mano; tutto il resto è automatico fino a "Invia Tutti". È per l'INVIO delle schedine di ospiti già arrivati, NON per la registrazione iniziale della struttura o la richiesta credenziali al portale, NON per l'imposta di soggiorno (SoggiorniAmo/Comune), e NON per i messaggi di benvenuto o le istruzioni di self check-in all'ospite.
---

# alloggiati-web-checkin

Comunica alla Polizia di Stato i dati di ogni ospite di una struttura ricettiva, via il [Portale Alloggiati](https://alloggiatiweb.poliziadistato.it) (obbligo art. 109 TULPS). Vale per **qualsiasi canale** (Airbnb o prenotazione diretta) e per **ogni** persona che pernotta.

Validata su due invii reali per Via Braida (10/06 e 12/06/2026, ~25 min ciascuno).

## Il confine non negoziabile: la 2FA è dell'utente, non della skill

Il portale chiede tre fattori: login, password, e un codice estratto da una **Scheda dei Codici** cartacea (2FA). Questo secondo fattore ha valenza penale e protegge una comunicazione alla pubblica sicurezza. **Non si automatizza in casa**: mettere tutti e tre i fattori nelle mani dell'agente annullerebbe la 2FA. Quindi:

- **L'utente fa, a mano, una volta sola**: login + completamento del codice 2FA dalla Scheda. Da quel momento è dentro una sessione autenticata nel **suo** browser.
- **L'agente fa tutto il resto**, automaticamente, su quella stessa sessione: legge i documenti, prepara la tabella, compila i form, esegue i submit intermedi e il "Invia Tutti" finale.

Per questo il motore è **Chrome MCP** (`mcp__Claude_in_Chrome__*`), non Playwright: l'agente deve lavorare sulla sessione già loggata dell'utente, non aprire un browser pulito dove la 2FA andrebbe rifatta. Non scalare ad altri motori: se Chrome MCP non è connesso, chiedi all'utente di abilitarlo, non aprire Playwright.

## Niente checkpoint, sessione filata

A differenza di altri form PA, qui **non** serve la machinery di checkpoint/resume. Il portale è un ASP.NET datato con sessione fragile che scade in fretta, e l'intero invio dura ~25 minuti. La strategia corretta è l'opposta del checkpoint: fai tutto in una sequenza unica e veloce (login → inserimento → invia → verifica), senza pause lunghe. Salvare stato intermedio inviterebbe proprio le pause che fanno cadere la sessione.

## I cinque stati del flusso

```
[1] RACCOGLI   Leggi le foto dei documenti dalla chat Airbnb o dalla sessione in cui
               la skill viene lanciata, OPPURE accetta una tabella dati già pronta.
               Estrai i dati dalla riga MRZ (verifica incrociata col fronte documento).
               ⚠ La verifica de visu dell'ospite è responsabilità dell'utente, non della
                 skill: la foto copre i DATI, non l'identificazione in tempo reale.
                     │
[2] PREPARA    Costruisci la tabella ospiti e decidi il tipo alloggiato di ciascuno
               (albero decisionale → references/tipo-alloggiato.md). Traslittera i nomi
               dalla riga MRZ (caratteri semplici: MANIK, non Mánik).
                     │
[3] GATE 👤    Mostra la tabella all'utente e ASPETTA il suo "vai". È l'unico stop umano
               oltre la 2FA. Qui l'utente ha già fatto login + 2FA a mano (vedi sopra).
                     │
[4] COMPILA    Full auto su Chrome MCP (tecniche → references/portal-map.md):
               Step1 (capo o singolo, con campi documento) → "Conferma" →
               Step2 (membri del gruppo, solo anagrafica, ripeti "Aggiungi" per ognuno) →
               "Invia Tutti".
                     │
[5] PROVA      Verifica in Analisi.aspx ("Lista delle schedine inviate oggi" = prova
               immediata della trasmissione). Ricorda all'utente: la ricevuta PDF NON è
               disponibile subito, l'elenco in "Ricevute" si popola il giorno successivo.
               Va scaricata l'indomani e archiviata.
```

### [1] RACCOGLI — dati ospiti

Due ingressi possibili, riconosci quale stai ricevendo:

- **Foto documenti** (caso reale): l'utente incolla le foto di carte d'identità / passaporti nella chat Airbnb o direttamente nella sessione. Leggi la **riga MRZ** (le due/tre righe di caratteri `<<<` in fondo al documento): è la fonte più affidabile per cognome, nome, data di nascita, sesso, cittadinanza, numero documento. Incrocia col fronte per cogliere errori OCR.
- **Tabella già pronta**: l'utente fornisce i dati scritti (es. li ha ricevuti dall'ospite). Parti direttamente da [2].

Dati obbligatori per ogni schedina: Cognome, Nome, Data di nascita, Sesso, Cittadinanza, Luogo di nascita, e — solo per il capo/ospite singolo — Tipo documento, Numero documento, Luogo di rilascio. Manca un campo → invio rifiutato.

**Privacy**: i dati ospiti vivono solo in chat e nella sessione. Nessun file su disco, niente dati ospiti nel vault. Dopo l'invio non resta nulla da ripulire.

### [2] PREPARA — tipo alloggiato

Questa è la parte di dominio che si sbaglia più spesso. Leggi `references/tipo-alloggiato.md` per l'albero decisionale completo. In breve:

- 1 persona sola → **Ospite Singolo**
- gruppo/famiglia → 1 **Capo Gruppo / Capo Famiglia** (dati completi, con documento) + gli altri come **Membro Gruppo / Familiare** (solo anagrafica, agganciati al capo)
- mai N schedine singole slegate per un gruppo
- arrivi in giorni diversi → invii separati, uno per giorno di arrivo (caso speciale, sotto)

Costruisci una tabella e mostrala. Esempio:

| # | Tipo | Cognome | Nome | Nascita | Sesso | Cittadinanza | Luogo nascita | Documento |
|---|------|---------|------|---------|-------|--------------|---------------|-----------|
| 1 | Capo Gruppo | DUPONT | MARIE | 1990-04-12 | F | FRANCIA | FRANCIA | Passaporto 12AB34567, FRANCIA |
| 2 | Membro Gruppo | DUPONT | PAUL | 1992-08-03 | M | FRANCIA | FRANCIA | — |

### [3] GATE — conferma umana

Mostra la tabella e fermati. Aspetta il "vai" esplicito dell'utente prima di toccare il browser. Questo gate esiste perché preparare i dati correttamente è la parte delicata; una volta confermati, compilare è meccanico. Dopo il "vai", procedi fino a "Invia Tutti" senza ulteriori conferme — l'utente ha già scelto il full auto.

### [4] COMPILA — esecuzione browser

L'utente è già loggato (login + 2FA fatti a mano). Le tecniche di compilazione campo per campo, i tipi di controllo (dropdown button vs textbox vs autocomplete) e i gotcha del portale sono in `references/portal-map.md`. Leggi quel file prima di iniziare la compilazione.

### [5] PROVA — verifica e ricevuta

Dopo "Invia Tutti", apri `Analisi.aspx`: le schedine inviate oggi compaiono subito, è la prova immediata della trasmissione. La ricevuta PDF ufficiale **non** è disponibile nello stesso momento: l'elenco in "Ricevute" si popola il giorno dopo. Ricorda all'utente di scaricarla l'indomani e archiviarla nella cartella burocrazia della struttura.

## Termini di invio (per non sforare)

| Durata soggiorno | Termine |
|---|---|
| oltre 24h | entro **24 ore** dall'arrivo |
| sotto 24h | entro **6 ore** dall'arrivo |
| arrivo serale/notturno | il termine scatta dalla **consegna delle chiavi** |

Per soggiorni brevi, conviene chiudere l'invio nel pomeriggio, non a sera: il termine 6h si esaurisce in fretta.

## Arrivi scaglionati (gruppo che si forma a metà soggiorno)

Caso: una sola prenotazione Airbnb, ma le persone arrivano in giorni diversi (es. 1 ospite la notte 1, il gruppo si completa la notte 2). Su Alloggiati Web questo diventa **più invii separati**, e non è una scelta: lo impone il vincolo del campo "Data di Arrivo", che accetta solo oggi o ieri. Procedura e razionale completi in `references/tipo-alloggiato.md`, sezione "Arrivi scaglionati".

## Se dimentichi o sbagli

Manda subito una PEC alla Questura spiegando il ritardo: sgrava (parzialmente) dalla responsabilità penale. Meglio tardi e dichiarato che mai. I riferimenti dell'Ufficio Alloggiati Web (Questura di Milano) vivono nella procedura della struttura, non in questa skill (sono specifici della Questura competente, non del flusso).

## A regime: il salto a Chekin

Questa skill è la soluzione semi-assistita corretta finché l'invio è manuale. La vera automazione PA, senza intervento umano sulla 2FA, è **Chekin** (o channel manager equivalente): ha un canale ufficiale certificato con Alloggiati Web (FTP/SOAP) che bypassa la 2FA web in modo autorizzato. Non uno script casalingo. Quando quel canale sarà attivo, questa skill diventa il fallback per gli invii fuori canale.
