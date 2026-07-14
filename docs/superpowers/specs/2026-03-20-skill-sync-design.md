# Skill Sync — Design Spec

**Date**: 2026-03-20
**Status**: Approved

## Problem

Skills creati personalmente vivono in `~/Documents/3.RESOURCES/SKILLS/claude-skills/`. Devono essere copiati manualmente verso due destinazioni separate (Claude Code e Claude Desktop/Cowork) ogni volta che vengono modificati. Facile dimenticarsene.

## Solution

Script `sync.sh` che sincronizza skill dalla sorgente verso entrambe le destinazioni. Eseguito automaticamente dopo ogni `git commit` nella repo, e disponibile manualmente per skill non ancora committati.

## Architecture

### Files

```
claude-skills/
├── sync.sh                    # Script principale (bash)
├── .sync-manifest.json        # Generato dal sync, traccia stato
├── tests/
│   ├── test_sync.sh           # Test suite (unit + integration)
│   └── fixtures/              # Create at runtime nei test
└── .git/hooks/post-commit     # Chiama sync.sh --quiet
```

### Flow

1. Scansiona sorgente: trova cartelle con `SKILL.md`
2. Per ogni skill trovato:
   - Copia/aggiorna → `~/.claude/skills/{nome}/`
   - Copia/aggiorna → path Cowork (trovato dinamicamente)
3. Cleanup (whitelist):
   - Legge manifest precedente
   - Skill nel manifest ma non più nella sorgente → rimuove dalle destinazioni
   - Non tocca skill non nel manifest (es. `deploy-check`)
4. Scrive `.sync-manifest.json` aggiornato
5. Output: cosa è stato copiato/rimosso/skippato

### Cowork Path Discovery

```bash
find ~/Library/Application\ Support/Claude/local-agent-mode-sessions/skills-plugin \
  -name "SKILL.md" -maxdepth 5 2>/dev/null
```

Estrae la cartella `skills/` dal primo match. Se non trova nulla, sync solo verso Claude Code con warning.

### Manifest `.sync-manifest.json`

```json
{
  "last_sync": "2026-03-20T15:30:00",
  "managed_skills": ["session-retrospective", "document-collector"],
  "destinations": {
    "claude_code": "/Users/figlody_mac/.claude/skills",
    "cowork": "/path/trovato/dinamicamente/skills"
  }
}
```

### Flags

- `--quiet`: output minimo (per post-commit hook)
- Nessun flag: output verboso (per uso manuale)

### Cleanup Logic (Whitelist B)

Lo script gestisce SOLO skill elencati in `managed_skills` nel manifest. Se uno skill viene rimosso dalla sorgente:
1. Lo script lo trova nel manifest ma non nella sorgente
2. Lo rimuove dalle destinazioni
3. Lo rimuove dal manifest

Skill presenti nelle destinazioni ma MAI stati nel manifest (es. `deploy-check`) non vengono toccati.

### Post-commit Hook

```bash
#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
"$SCRIPT_DIR/sync.sh" --quiet
```

Installato in `.git/hooks/post-commit`.

### Error Handling

- Sorgente non trovata → exit 1
- Destinazione Claude Code non esiste → la crea
- Destinazione Cowork non trovata → warning, sync solo Claude Code
- Manifest non esiste → primo sync, crea da zero
- Manifest corrotto → warning, ricrea da zero

## Test Strategy

### Unit (logica pura, cartelle tmp)

- Scansione sorgente trova solo cartelle con `SKILL.md`
- Manifest scritto correttamente
- Cleanup rimuove solo skill nel manifest ma non nella sorgente
- Cleanup non tocca skill fuori dal manifest
- Discovery Cowork fallisce gracefully

### Integration (cartelle tmp, flusso completo)

- Sync completo: sorgente → due destinazioni, verifica file copiati
- Sync idempotente: due esecuzioni → stesso risultato
- Aggiunta skill: nuovo skill appare nelle destinazioni
- Rimozione skill: skill rimosso dalla sorgente pulito dalle destinazioni
- Skill esterni preservati dopo sync + cleanup
- Cowork assente: sync funziona solo verso Claude Code

## Trigger

- Automatico: post-commit hook nella repo claude-skills
- Manuale: `./sync.sh` per skill WIP
- Suggerito da Claude: quando noto lavoro su skill senza commit
