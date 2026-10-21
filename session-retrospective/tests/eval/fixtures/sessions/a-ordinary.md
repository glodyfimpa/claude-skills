# Session transcript (fixture: ordinary session, no spark)

**Glody:** Nel README del toolkit BnB la tabella dei comandi ha ancora `analyze-zone` scritto `analyse-zone`. Correggi.

**Claude:** Corretto il refuso nella riga della tabella (`analyse-zone` -> `analyze-zone`). Commit `fix(readme): typo analyze-zone`.

**Glody:** Il test `test_sync.sh` è verde?

**Claude:** Sì, 19/19 verdi.

**Glody:** Aggiorna la data `updated` nel frontmatter di `progetti/bnb/README.md` a oggi.

**Claude:** Fatto: `updated: 2026-10-21`.

**Glody:** Cerca dove è definita la costante `MAX_GUESTS`.

**Claude:** In `pricing/config.py`, riga 12: `MAX_GUESTS = 4`. È usata solo da `pricing/quote.py`.

**Glody:** Ok, va bene così. Push.

**Claude:** Pushato su main.
