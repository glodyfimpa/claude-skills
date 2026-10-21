#!/usr/bin/env python3
"""Build a deliberately broken copy of SKILL.md for the RED step of the profile evals.

Each mutant removes or inverts the one rule a contract test protects. A test run against
its mutant must fail; against the real SKILL.md it must pass.

Usage: mutate.py <mutant> <in SKILL.md> <out SKILL.md>
       mutate.py --list
Every anchor must match exactly once, so a moved text fails loudly instead of silently
producing an unbroken copy.
"""
import sys

# (start, end, replacement): replace the span start..end (inclusive); end=None -> start only.
MUTANTS = {
    # Contract a: the skill returns the value stored in the profile.
    "values-withheld": [
        ("- Restituisce data bundle come mappa chiave→valore", None,
         "- Restituisce solo i nomi dei campi presenti, mai i loro valori: i valori restano nel file"),
    ],
    # Contract b: fields marked [da completare] are reported as missing.
    "placeholders-hidden": [
        ('- Filtra il bundle per valori == "[da completare]"', "- [Gestore] codice_fiscale_gestore",
         '- I campi con valore "[da completare]" sono marcatori interni: non riportarli mai '
         "nelle risposte, nemmeno come mancanti"),
    ],
    # Contract c: a new value replaces the placeholder in place, touching nothing else.
    "append-instead-of-replace": [
        ('- Trova la riga "chiave: [da completare]"', "sed -i '' -e 's/...' file)",
         '- Non modificare la riga esistente: aggiungi in fondo al file una nuova riga '
         '"chiave: valore" e lascia intatta quella con [da completare]'),
    ],
}


def apply(text, edits):
    for start, end, new in edits:
        if text.count(start) != 1:
            raise SystemExit(f"anchor not found exactly once: {start!r}")
        i = text.index(start)
        if end is None:
            j = i + len(start)
        else:
            k = text.find(end, i)
            if k < 0:
                raise SystemExit(f"end anchor not found after {start!r}: {end!r}")
            j = k + len(end)
        text = text[:i] + new + text[j:]
    return text


def main(argv):
    if argv[1:] == ["--list"]:
        print("\n".join(MUTANTS))
        return 0
    if len(argv) != 4 or argv[1] not in MUTANTS:
        print(__doc__, file=sys.stderr)
        return 64
    with open(argv[2], encoding="utf-8") as f:
        text = f.read()
    with open(argv[3], "w", encoding="utf-8") as f:
        f.write(apply(text, MUTANTS[argv[1]]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
