# Mappa tecnica del Portale Alloggiati

Come parla il portale, campo per campo. Questo file invecchia se la Polizia ridisegna il sito: è separato apposta da `tipo-alloggiato.md` (regole di legge, che restano). Rilevato via browser 12/06/2026 sulla struttura Via Braida.

Il portale è un **ASP.NET datato**. Conseguenza pratica: i "dropdown" non sono `<select>` HTML standard ma `<button>` custom che aprono una lista, e gli identificatori dei controlli (i `ref`) **cambiano tra un'iterazione e l'altra**. Non cliccare mai a coordinate cieche e non riusare un `ref` letto in un passo precedente: rileggi sempre la pagina.

## Sequenza pagine

```
Home.aspx
   │ menu hamburger → Inserimento
   ▼
Inserimento_Step1.aspx     ← 1° ospite: Capo Gruppo / Capo Famiglia / Ospite Singolo
   │                          (ha i campi documento)
   │ submit "Conferma"
   ▼
Inserimento_Step2.aspx     ← membri del gruppo: solo anagrafica.
   │                          Ripetibile: "Aggiungi" per ogni membro.
   │                          (saltato se Ospite Singolo)
   │ submit "Invia Tutti"
   ▼
Inserimento_Conferma.aspx  ← riepilogo "Elenco schedine da inviare"
   ▼
Analisi.aspx               ← "Lista delle schedine inviate oggi" = prova trasmissione immediata
```

Per accedere a Inserimento dopo il login: portale → menu → ACCESSO → "Area di Lavoro (Codici)".

## Tipi di controllo e come compilarli

Tre famiglie di campo, ognuna con la sua tecnica. Sbagliare tecnica = il valore non viene registrato.

| Campo | Tipo controllo | Tecnica |
|-------|----------------|---------|
| Tipo (alloggiato) | dropdown button | click apre la lista, poi click sull'opzione |
| Data di Arrivo | dropdown button | come sopra; offre SOLO oggi e ieri (vincolo manuale pag. 6) |
| Sesso | dropdown button | come sopra |
| Permanenza | textbox | `form_input` diretto |
| Cognome | textbox | `form_input` diretto |
| Nome | textbox | `form_input` diretto |
| Data di Nascita | textbox | `form_input` diretto |
| Numero Documento | textbox | `form_input` diretto |
| Cittadinanza | autocomplete | `type` il testo, poi click sul suggerimento |
| Luogo di Nascita | autocomplete | come sopra |
| Luogo di Rilascio | autocomplete | come sopra |
| Tipo Documento | autocomplete | come sopra (es. "PASSAPORTO ORDINARIO") |

### Dropdown button (Tipo / Data di Arrivo / Sesso)

Non sono `<select>`: sono `<button>` che, al click, aprono una lista di opzioni cliccabili. Due click: uno sul bottone per aprire, uno sull'opzione. Il `ref` del bottone Sesso e del bottone "Aggiungi" **cambia tra le iterazioni di Step2**: rileggi con `find` prima di ogni nuovo membro.

Valori del dropdown **Tipo**: Ospite Singolo / Capo Famiglia / Capo Gruppo / Familiare / Membro Gruppo.

### Autocomplete (Cittadinanza / luoghi / Tipo Documento)

Scrivere il testo **non basta**: il portale richiede di selezionare il suggerimento che appare nella tendina. Sequenza: `type` il testo → attendi la tendina → click sul suggerimento giusto.

Gotcha del DB stati esteri: usa le **denominazioni ufficiali italiane**, non quelle comuni.
- "SLOVACCHIA" non trova nulla → digita "REPUBBLICA SLOVACCA" e seleziona "REPUBBLICA SLOVACCA (ES)"
- "REPUBBLICA CECA (ES)" idem
- Per la Francia: "FRANCIA" → seleziona "FRANCIA (ES)"
- In generale: digita "REPUBBLICA <paese>" o una sottostringa univoca del nome ufficiale.

**Cittadinanza ha default "ITALIA"**: per gli stranieri il campo è precompilato. Triple-click sul campo + digita per sovrascrivere, altrimenti il default resta.

**Luogo di nascita per nati all'estero**: è lo **stato estero**, non la città.

## Campi documento: solo per il capo

I campi Tipo Documento / Numero Documento / Luogo di Rilascio **compaiono solo** per Capo Gruppo / Capo Famiglia / Ospite Singolo. Per Familiare / Membro Gruppo il portale chiede solo i dati anagrafici (nessun campo documento). Verificato al primo invio reale 10/06/2026.

## Step2: aggiungere i membri

- C'è un contatore "Elenco Componenti Gruppo o Famiglia: N" che incrementa a ogni "Aggiungi".
- Il Capo Gruppo **non è eliminabile** dall'elenco (non ha la ✗); i membri sì.
- Dopo aver compilato un membro, click "Aggiungi" → il form si svuota per il successivo. Il `ref` di "Aggiungi" cambia: rileggilo.

## Tecnica affidabile (riassunto operativo)

1. Usa `read_page` con `filter=interactive` per ottenere i `ref` correnti, **non** click a coordinate cieche.
2. I `ref` dei dropdown (Sesso, Aggiungi) cambiano tra iterazioni → rileggi con `find` prima di ogni uso ripetuto.
3. Distingui le tre tecniche per famiglia di campo (tabella sopra): textbox = scrivi e basta; autocomplete = scrivi + seleziona; dropdown = click + click.
4. Cittadinanza straniera: sovrascrivi il default ITALIA con triple-click.

Fonte vincoli: [manuale Alloggiati Web](https://alloggiatiweb.poliziadistato.it/PortaleAlloggiati/Download/Manuali/MANUALE.pdf), pag. 6 (Tipo Alloggiato + Data di Arrivo oggi/ieri).
