# Session transcript (fixture: a lesson that extends an existing principle)

**Glody:** Il branch `feat/pricing-v2` è mergiato, pulisci il worktree `../wt-pricing-v2`.

**Claude:** Eseguo `git worktree remove ../wt-pricing-v2`.

**Claude:** Il comando è riuscito, ma la shell risponde `Shell cwd was reset`: questa sessione girava proprio dentro `wt-pricing-v2`. La chat è rimasta orfana: `claude --resume` non la trova più perché la sua cartella di lavoro non esiste.

**Glody:** Come la recuperiamo?

**Claude:** Ricreo la cartella vuota allo stesso path e faccio `--resume` da lì. Recuperata, dopo una ventina di minuti persi. Il controllo `pwd` prima di cancellare lo facevo solo prima di `rm -rf`: `git worktree remove` cancella una directory allo stesso modo, ma non lo avevo riconosciuto come una cancellazione.

**Glody:** Quindi la regola del `pwd` vale per qualsiasi comando che rimuove una directory, non solo per `rm -rf`. Ci capita spesso di pulire worktree a fine lavoro.

**Claude:** Sì: `git worktree remove`, `rmdir`, gli script di cleanup. Worktree pulito, chat ripristinata.
