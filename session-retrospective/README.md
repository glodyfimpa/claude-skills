# session-retrospective

Il rito di fine sessione, all'osso. Una domanda: *è successo qualcosa di raro che cambia il
domani in meglio?* Esito normale = niente. Se c'è una scintilla, il **mostra-vicini** cerca i
simili nel brain e li mette davanti, così una lezione si fonde invece di duplicare; poi tre
esiti (LEZIONE → principles/hook; SEME-STRUMENTO forma-A → commessa in coda; serve-la-tua-testa
→ appuntamento calendario). Assorbe l'ex `revise-claude-md` nel ramo LEZIONE.

Riscritta dal Fronte 2 dell'audit sistema+brain (2026-07-15): il vecchio rito (8 fasi, 16 KB,
centrato su un backlog-cimitero) aveva il default invertito (pretendeva output → rumore). Design:
`~/Documents/brain/areas/ai-automation/docs/superpowers/specs/2026-07-15-retro-consolidamento-cimitero-design.md`.

## File

| File | Ruolo |
|---|---|
| `SKILL.md` | Il rito (una-domanda + mostra-vicini + tre esiti). Giudizio, non codice. |
| `neighbors.py` | Motore mostra-vicini: token-overlap lessicale, deterministico, zero-dipendenze. |
| `bin/show-neighbors` | CLI: `show-neighbors "<scintilla>"` → i vicini nel brain, dal più simile. |
| `tests/test_neighbors.py` | TDD della libreria (tokenize, score, find_neighbors, collect_sources). |
| `tests/test_show_neighbors.bats` | Integrazione della CLI su un finto vault. |
| `tests/eval-cases.md` | Casi-spec del giudizio del rito (7 TC). |
| `tests/eval/contracts.eval.bats` | Eval dei contratti del giudizio (costa chiamate al modello, gira solo con `RUN_EVALS=1`). |
| `tests/eval/lib.bash` | Mondo fixture isolato: vault git, skill installate, `show-neighbors` che registra le chiamate, stub calendario. |
| `tests/eval/mutate.py` | Varianti rotte di `SKILL.md` per il RED: ognuna toglie la regola che un test protegge. |

## Meccanica del mostra-vicini (decisa nel Fronte 2)

- **Strumento**: ricerca lessicale (overlap di token significativi), non embedding — deterministica,
  testabile a freddo, zero dipendenze, riproducibile.
- **Perimetro**: `.brain/principles/*.md` + `.brain/memory/MEMORY.md` + `areas/**/CLAUDE.md` +
  `~/.claude/skills/*/SKILL.md`. Layout pre-L2 (`principles/`, `memory/` alla root) letto come
  fallback. Esclusi i sottoalberi effimeri/vendored (`.claude/worktrees`, `node_modules`, ecc.).
  Ogni sorgente mancante è segnalata su stderr, mai saltata in silenzio.
- **Soglia**: top-5 sopra ≥2 token condivisi. Barra alta: pochi vicini forti, non molti deboli.
  Il ranking tiene fuori da solo le regole d'area quando la scintilla è globale (pochi token → sotto soglia).

## Test

```
python3 -m pytest tests/test_neighbors.py -v
bats tests/test_show_neighbors.bats
```

Suite veloce, senza modello: `test_neighbors.py` (pytest) e `test_show_neighbors.bats`.

### Eval dei contratti (giudizio del rito)

Sette test GIVEN/WHEN/THEN: una sessione fixture e un vault fixture, un Claude headless
nuovo (`claude -p --safe-mode`) esegue il rito da `SKILL.md`, il test guarda solo gli
effetti (file cambiati nel vault rispetto al commit fixture, chiamate a `show-neighbors`,
voci in `build-queue.md` validate da `queue_parser`, eventi sullo stub calendario).

```
RUN_EVALS=1 bats tests/eval/contracts.eval.bats
EVAL_MUTANT=always-a-spark RUN_EVALS=1 bats -f 'contract a' tests/eval/contracts.eval.bats   # RED
```

Serve: `claude` loggato, `jq`, un python3 con PyYAML (`EVAL_PYTHON`), `queue_parser.py` del
brain (`EVAL_QUEUE_PARSER`, default `~/Documents/brain/areas/ai-automation/autonomous-agents/`).
Modello di default `sonnet` (`EVAL_MODEL`). Costo misurato il 2026-10-21 con sonnet: da 0,05 a 0,20 USD per test,
0,80 USD per l'intera suite (i test con conferma fanno due turni). Senza `RUN_EVALS=1` i test sono skip.

Seam: il calendario reale (evento Google Calendar) è sostituito dalla CLI stub `gcal-event`,
annunciata nel prompt del run; la conferma di Glody è un secondo turno sulla stessa
sessione (`--resume`). Una sola esecuzione per test: il giudizio è di un modello, quindi un
rosso isolato va rilanciato prima di leggerlo come regressione.
