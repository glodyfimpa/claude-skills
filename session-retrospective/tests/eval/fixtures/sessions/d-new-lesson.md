# Session transcript (fixture: a new lesson with no neighbor in the vault)

**Glody:** Esporta in CSV le prenotazioni di ottobre per il commercialista.

**Claude:** Esportato `prenotazioni-ottobre.csv` con separatore virgola, UTF-8.

**Glody:** Il commercialista dice che in Excel vede tutto in una colonna sola e i nomi con l'accento sono rotti ("NicolÃ²").

**Claude:** Excel con impostazioni italiane usa il punto e virgola come separatore di lista (la virgola è il separatore decimale) e senza BOM legge il file come Windows-1252. Riesportato con `;` come separatore, importi con la virgola decimale e UTF-8 con BOM.

**Glody:** Ora si apre giusto. È la seconda volta che succede: ad agosto era successo con il CSV per la banca e l'avevamo rifatto a mano.

**Claude:** Vale per ogni CSV destinato a un utente con Excel in italiano: `;` come separatore e UTF-8 con BOM, altrimenti colonne e accenti si rompono. Ogni mese mandiamo almeno due CSV (commercialista, banca).
