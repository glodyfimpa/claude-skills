# Tipo alloggiato — regole di dominio

Quale tipo assegnare a ciascuna persona e come gestire i casi composti. Questo file è separato da `portal-map.md` perché sono regole di legge (manuale Polizia, art. 109 TULPS): restano valide anche se il portale cambia aspetto.

Il portale offre cinque tipi: **Ospite Singolo · Capo Famiglia · Capo Gruppo · Familiare · Membro Gruppo**. La distinzione che conta è una sola: chi porta i dati completi (con documento) e chi è agganciato a lui.

## Albero decisionale

```
Quante persone in questo arrivo?
│
├─ 1 sola ──────────────────► OSPITE SINGOLO (dati completi + documento)
│
└─ 2 o più
   │
   ├─ legate da parentela? ──► 1 CAPO FAMIGLIA (dati completi + documento)
   │                            + gli altri FAMILIARE (solo anagrafica)
   │
   └─ gruppo non familiare ──► 1 CAPO GRUPPO (dati completi + documento)
                                + gli altri MEMBRO GRUPPO (solo anagrafica)
```

Regola d'oro: per un gruppo si crea **una** schedina capo + N schedine agganciate. **Mai** N schedine singole slegate. Il capo è l'unico che richiede i campi documento; i membri/familiari solo i dati anagrafici.

Famiglia vs gruppo è una distinzione anagrafica (parentela sì/no). Quando incerto e nessun dato lo chiarisce, "Capo Gruppo + Membro Gruppo" è la scelta neutra che non richiede di dichiarare un legame familiare.

## Arrivi scaglionati

Caso: una sola prenotazione (su Airbnb è 1 booking), ma le persone arrivano in **giorni diversi**. Esempio reale: Greta, 04–06 lug 2026 — 1 ospite la notte 1, altri 3 la notte 2.

Su Alloggiati Web questo **non** è un invio solo: diventa **più invii separati, uno per ogni giorno di arrivo**. Non è una scelta di comodità, è obbligato dal portale.

### Perché è obbligato

Il campo "Data di Arrivo" è **per-ospite** e il manuale (pag. 6) dice che *"l'applicativo permette soltanto l'inserimento della data odierna o quella del giorno precedente"*. Quindi non puoi inserire oggi un ospite che arriva domani: la sua data di arrivo non sarebbe né oggi né ieri. Ogni persona va comunicata entro 24h dal **suo** arrivo reale, con la **sua** data.

### Procedura per "1 la notte 1, poi il gruppo la notte 2"

```
Giorno arrivo 1° ospite
   └─► schedina OSPITE SINGOLO, data = quel giorno, invio entro 24h

Giorno arrivo degli altri
   └─► nuovo inserimento: CAPO GRUPPO + componenti collegati,
       data = quel giorno, invio entro 24h
```

Punti di attenzione:

- I **documenti di tutti** si raccolgono **prima** del primo arrivo (organizzazione tua, serve anche per la de visu di chi fa self check-in il giorno 2). Raccogliere ≠ comunicare: i documenti li hai prima, le schedine le invii quando ognuno arriva davvero.
- Se il 1° ospite era "Singolo" la notte 1 e poi entra nel gruppo la notte 2, **non** va re-inviato: è già stato comunicato. Il 2° invio copre solo i nuovi arrivati.
- In caso di controllo, ciò che conta è che ogni persona risulti comunicata entro 24h dal suo arrivo con la data giusta. Questa procedura lo rispetta.

## Nomi e luoghi

- **Traslittera dalla riga MRZ** del documento: il portale vuole caratteri semplici (MANIK, non Mánik; DUPONT, non DüPont).
- Per nati all'estero, il Luogo di Nascita è lo **stato estero**, non la città.
- Le denominazioni degli stati seguono il DB ufficiale italiano: vedi i gotcha autocomplete in `portal-map.md` ("REPUBBLICA SLOVACCA (ES)", "FRANCIA (ES)", ecc.).

Fonte: [manuale Alloggiati Web](https://alloggiatiweb.poliziadistato.it/PortaleAlloggiati/Download/Manuali/MANUALE.pdf), pag. 6.
