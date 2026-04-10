---
name: bash-portability-linter
description: >
  Scansiona script shell per costrutti che si rompono su macOS bash 3.2, BSD coreutils
  e Git Bash su Windows. Usa questo skill quando devi controllare la portabilità di
  script bash prima di distribuirli su macchine diverse. Trigger: "scansiona questi
  script per problemi di portabilità", "controlla bash portability", "check bash
  portability", "lint shell for macOS bash 3.2", "trova costrutti bash 4+", "verifica
  che questo script giri su Mac", "does this script work on BSD", "find GNU-only
  flags", "lint shell scripts", "portability check", "is this bash 3.2 compatible".
  Sette regole (BP001-BP007) coprono i bug più comuni che rompono gli script quando
  si passa da Linux/GNU a macOS/BSD: case modification ${var,,}, declare -A,
  mapfile/readarray, sed -i senza suffisso, awk RS multi-carattere, readlink -f,
  date --iso-8601. Include modalità file singolo, scansione ricorsiva di directory
  (skippa .git, node_modules, tests/fixtures), output testuale e JSON.
---

# bash-portability-linter

Scansiona shell script per costrutti non portabili tra Linux/GNU, macOS/BSD e Git Bash su Windows.

## Quando usarlo

- Prima di committare uno script bash che deve girare anche su macOS o Git Bash
- Durante review di PR che modificano file `.sh` o `.bash`
- Quando uno script "funziona sul mio Linux" ma un utente Mac segnala errori
- Per controllare skill/plugin Claude Code che includono script shell, dato che molti utenti li eseguono su macOS con bash 3.2

## Come invocarlo

Lo skill espone un eseguibile `bin/bash-portability-linter`:

```bash
# Scansione di un singolo file
bash-portability-linter path/to/script.sh

# Scansione ricorsiva di una directory
bash-portability-linter path/to/repo

# Output JSON (per integrazioni CI o post-processing)
bash-portability-linter path/to/repo --json
```

### Exit codes

- `0` — tutto pulito
- `1` — almeno una violazione di severità `ERROR`
- `2` — solo violazioni di severità `WARN`

Questo permette di usarlo in un pre-commit hook o in CI con:

```bash
bash-portability-linter ./scripts || exit $?
```

## Le 7 regole

| ID    | Severità | Cosa trova                                              |
|-------|----------|---------------------------------------------------------|
| BP001 | ERROR    | `${var,,}` / `${var^^}` — case modification bash 4+     |
| BP002 | ERROR    | `declare -A` / `local -A` — associative array bash 4+   |
| BP003 | ERROR    | `mapfile` / `readarray` — builtin bash 4+               |
| BP004 | ERROR    | `sed -i ''` o `sed -i ` senza suffisso attaccato        |
| BP005 | ERROR    | `awk -v RS='multi-char'` — BSD awk è single-char        |
| BP006 | WARN     | `readlink -f` — GNU-only                                |
| BP007 | WARN     | `date --iso-8601` / `date --rfc-3339` — GNU-only        |

Le prime 5 sono `ERROR` perché lo script esplode subito quando incontra quei costrutti. BP006 e BP007 sono `WARN` perché lo script parte e si rompe solo sulla linea specifica, quindi sono più facili da aggirare al volo.

## Cosa fa il linter internamente

- Usa `grep -nE` con regex POSIX estese (niente perl, niente python — il linter stesso è bash 3.2 compatible)
- Skippa le linee che sono puri commenti (primo carattere non-whitespace è `#`)
- In modalità directory usa `find` per ricorrere, escludendo `.git/`, `node_modules/`, e qualsiasi path che contenga `tests/fixtures/`
- In modalità JSON accumula le violazioni in memoria e emette un singolo oggetto finale con `files_scanned`, `violations[]`, `error_count`, `warn_count`

## Origine

Tutte e 7 le regole sono bug reali incontrati mentre costruivo il plugin `claude-autopilot` su macOS bash 3.2. Ogni volta che una regola catturava un bug mi segnavo il pattern. Dopo 7 regole ho capito che era un linter.

## Sviluppo

Questo skill è stato costruito con TDD stretto: RED → GREEN → REFACTOR per ogni regola, una alla volta. La test suite usa `bats-core`:

```bash
bats bash-portability-linter/tests/linter.bats
```

Include 19 test: uno per ogni regola (con fixture dedicata), più cross-cutting tests per exit code, scansione ricorsiva, output JSON, e un self-lint che esegue il linter su sé stesso per garantire che rimanga bash 3.2 pulito.
