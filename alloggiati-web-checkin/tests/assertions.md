# Asserzioni di correttezza — alloggiati-web-checkin

Test di **completezza e correttezza interna** della skill. NON testa l'esecuzione browser
(quella si dimostra solo al primo invio reale): testa che la skill sia una guida senza
buchi che farebbero sbagliare l'agente.

Ogni asserzione è un fatto verificato sui 2 invii reali (Via Braida, 10/06 e 12/06/2026,
documentati in `areas/affitti-brevi/procedure/adempimenti-pa-checkin.md`) o nel manuale
ufficiale Polizia (pag. 6). La fonte di verità sono quei fatti, non l'opinione di chi ha
scritto la skill. Un verificatore indipendente controlla ogni asserzione contro
`SKILL.md` + `references/portal-map.md` + `references/tipo-alloggiato.md` e risponde
PASS/FAIL con la riga di evidenza.

## A. Confine dei ruoli (2FA)

- **A1** La skill afferma che login + 2FA li fa l'utente a mano, non l'agente.
- **A2** La skill motiva il confine con la valenza penale / il fatto che mettere i 3 fattori insieme annulla la 2FA (non un MUST nudo).
- **A3** La skill afferma che, dopo il gate, l'agente arriva fino a "Invia Tutti" in automatico (full auto, deciso 12/06).

## B. Motore browser

- **B1** Il motore canonico è Chrome MCP.
- **B2** La skill spiega PERCHÉ Chrome e non Playwright (sessione già loggata dell'utente).
- **B3** La skill dice di NON scalare ad altri motori (se Chrome MCP manca, chiedere di abilitarlo).

## C. Sequenza pagine (portal-map)

- **C1** La sequenza è completa: Home → Inserimento_Step1 → "Conferma" → Inserimento_Step2 → "Invia Tutti" → Inserimento_Conferma → Analisi.
- **C2** Step2 è dichiarato saltabile per Ospite Singolo (un singolo non ha membri).
- **C3** Analisi.aspx è indicato come prova di trasmissione immediata.

## D. Tipi di campo e tecnica (portal-map)

- **D1** I dropdown sono `<button>` custom, non `<select>` (tecnica: click apre, click opzione).
- **D2** Gli autocomplete richiedono di SELEZIONARE il suggerimento, non basta digitare.
- **D3** Cittadinanza ha default "ITALIA" da sovrascrivere per stranieri.
- **D4** "Data di Arrivo" offre solo oggi e ieri.
- **D5** I `ref` cambiano tra iterazioni → rileggere con `read_page`/`find`, non click ciechi.
- **D6** Gli stati esteri usano denominazioni ufficiali ("FRANCIA (ES)", "REPUBBLICA SLOVACCA (ES)").

## E. Tipi alloggiato (tipo-alloggiato)

- **E1** Sono enumerati tutti e 5: Ospite Singolo, Capo Famiglia, Capo Gruppo, Familiare, Membro Gruppo.
- **E2** L'albero decisionale copre: 1 persona → Singolo; gruppo familiare → Capo Famiglia + Familiari; gruppo non familiare → Capo Gruppo + Membri.
- **E3** I campi documento (Tipo/Numero/Luogo Rilascio) compaiono SOLO per Capo*/Ospite Singolo, non per Familiare/Membro.
- **E4** È vietato fare N schedine singole slegate per un gruppo.

## F. Arrivi scaglionati (tipo-alloggiato)

- **F1** Una prenotazione con arrivi in giorni diversi → invii SEPARATI, uno per giorno di arrivo.
- **F2** Il motivo è il vincolo "Data di Arrivo = oggi o ieri" (manuale pag. 6), non una scelta.
- **F3** I documenti di tutti si raccolgono prima; raccogliere ≠ comunicare.
- **F4** Chi era già comunicato (es. Singolo notte 1) NON va re-inviato.

## G. Input e privacy (SKILL)

- **G1** La skill accetta DUE input: foto documenti (chat Airbnb o sessione) OPPURE tabella già pronta.
- **G2** La lettura foto usa la riga MRZ; i nomi vanno traslitterati (caratteri semplici).
- **G3** La verifica de visu è dichiarata responsabilità dell'utente, fuori dalla skill.
- **G4** Nessun dato ospite finisce su disco / nel vault.

## H. Dati e termini (SKILL)

- **H1** Sono elencati i dati obbligatori per schedina (cognome, nome, nascita, sesso, cittadinanza, luogo nascita; documento solo per il capo).
- **H2** I termini di invio sono corretti: 24h (sopra 24h soggiorno), 6h (sotto 24h), dalla consegna chiavi se arrivo serale.
- **H3** La ricevuta PDF NON è disponibile subito: l'elenco Ricevute si popola il giorno dopo.

## I. Coerenza interna

- **I1** Niente checkpoint/timeout machinery (a differenza di pa-form-filler); motivato dalla sessione fragile filata in ~25 min.
- **I2** Il gate umano è UNO solo (sulla tabella dati), non uno per submit.
- **I3** Nessuna contraddizione tra SKILL.md e i due reference (es. tecnica campo descritta diversamente in due punti).
