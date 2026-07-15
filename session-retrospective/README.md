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
| `tests/eval-cases.md` | Casi-spec del giudizio del rito (6 TC). |

## Meccanica del mostra-vicini (decisa nel Fronte 2)

- **Strumento**: ricerca lessicale (overlap di token significativi), non embedding — deterministica,
  testabile a freddo, zero dipendenze, riproducibile.
- **Perimetro**: `principles/*.md` + `memory/MEMORY.md` + `areas/**/CLAUDE.md` + `~/.claude/skills/*/SKILL.md`.
  Esclusi i sottoalberi effimeri/vendored (`.claude/worktrees`, `node_modules`, ecc.).
- **Soglia**: top-5 sopra ≥2 token condivisi. Barra alta: pochi vicini forti, non molti deboli.
  Il ranking tiene fuori da solo le regole d'area quando la scintilla è globale (pochi token → sotto soglia).

## Test

```
python3 -m pytest tests/test_neighbors.py -v
bats tests/test_show_neighbors.bats
```

Suite: 12 (pytest) + 4 (bats) = 16 test.
