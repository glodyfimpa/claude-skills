```
 _               _       _ _       _   
| |__   __ _ ___| |__   | (_)_ __ | |_ 
| '_ \ / _` / __| '_ \  | | | '_ \| __|
| |_) | (_| \__ \ | | | | | | | | | |_ 
|_.__/ \__,_|___/_| |_| |_|_|_| |_|\__|
```

Lint shell scripts for constructs that break on macOS bash 3.2 / BSD coreutils / Git Bash.

Seven rules, all extracted from real bugs hit while building the `claude-autopilot` plugin on macOS. Each violation corresponds to a bash 4+ builtin, a GNU-only flag, or a BSD-vs-GNU ambiguity that silently bites when a script written on Linux is run on a Mac. The linter itself is bash 3.2 compatible and passes its own rules.

## Usage

```bash
# Single file
bash-portability-linter script.sh

# Recursive directory scan (skips .git, node_modules, tests/fixtures)
bash-portability-linter ./scripts

# JSON output (for CI / post-processing)
bash-portability-linter ./scripts --json
```

Exit codes: `0` clean, `1` any ERROR, `2` WARN-only.

## Rules

| ID    | Severity | What it catches                                         |
|-------|----------|---------------------------------------------------------|
| BP001 | ERROR    | `${var,,}` / `${var^^}` bash 4+ case modification       |
| BP002 | ERROR    | `declare -A` / `local -A` associative arrays (bash 4+)  |
| BP003 | ERROR    | `mapfile` / `readarray` builtins (bash 4+)              |
| BP004 | ERROR    | Non-portable `sed -i` (BSD vs GNU ambiguity)            |
| BP005 | ERROR    | `awk -v RS='multi-char'` (BSD awk is single-char only)  |
| BP006 | WARN     | `readlink -f` (GNU-only)                                |
| BP007 | WARN     | `date --iso-8601` / `date --rfc-3339` (GNU-only)        |

## Example output

```
$ bash-portability-linter tests/fixtures/bp001_lowercase.sh
tests/fixtures/bp001_lowercase.sh:6: [ERROR] BP001: bash 4+ case modification parameter expansion — Pipe through tr to change case portably
```

```
$ bash-portability-linter ./scripts --json
{"files_scanned":12,"violations":[{"file":"scripts/deploy.sh","line":42,"severity":"ERROR","rule_id":"BP003","rule_name":"bash 4+ array read builtin","message":"bash 4+ array read builtin","suggestion":"Use: while IFS= read -r line; do ... done < file"}],"error_count":1,"warn_count":0}
```

## Development

Built with strict TDD. Tests live under `tests/linter.bats` and run with [`bats-core`](https://github.com/bats-core/bats-core):

```bash
brew install bats-core
bats bash-portability-linter/tests/linter.bats
```

19 tests cover: one fixture per rule, clean-file baseline, exit code matrix (0/1/2), recursive directory scanning, directory exclusion rules, `--json` output validity (round-tripped through `python3 -c json.loads`), and a self-lint pass that runs the linter on itself.

To add a new rule, follow RED → GREEN → REFACTOR:
1. Add a fixture in `tests/fixtures/bpNNN_<name>.sh` that contains exactly one violation
2. Add a bats test that asserts the rule id, severity, and line number
3. Run the test — it must fail for the right reason
4. Add the `grep_rule` call to `bin/bash-portability-linter`
5. Run the test — it must pass
6. Verify `bash-portability-linter bash-portability-linter/bin/bash-portability-linter` stays clean
