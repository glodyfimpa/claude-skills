# Session transcript (fixture: tool seed that a headless agent can build alone)

**Glody:** Controlla l'IBAN che l'ospite ha scritto nel modulo di rimborso cauzione: IT60 X054 2811 1010 0000 0123 456.

**Claude:** Calcolo il checksum mod-97 a mano in Python: l'IBAN è valido.

**Glody:** Anche questo, del secondo ospite: IT60X0542811101000000123457.

**Claude:** Checksum mod-97 fallito: l'IBAN non è valido, probabilmente un'ultima cifra sbagliata. Va richiesto all'ospite.

**Glody:** Ogni mese ci sono tre o quattro rimborsi cauzione e ogni volta riscriviamo questo controllo da zero, e una volta un bonifico è tornato indietro per un IBAN sbagliato (commissione persa e ospite in attesa due settimane). Mi servirebbe una piccola libreria Python con CLI che valida IBAN (mod-97, lunghezza per paese) e codice fiscale italiano (carattere di controllo), con test. Codice puro, niente browser, niente servizi esterni.

**Claude:** Per oggi i due controlli sono fatti. Non esiste ancora nulla del genere tra le nostre skill.
