#!/usr/bin/env python3
"""Build a deliberately broken copy of SKILL.md for the RED step of the contract evals.

Each mutant removes or inverts the one rule a contract test protects. Running a
contract test against its mutant must fail; running it against the real SKILL.md
must pass. That pair is what makes the RED authentic.

Usage: mutate.py <mutant> <in SKILL.md> <out SKILL.md>
       mutate.py --list

Every anchor must match exactly once in the input: if the skill text moves, the
mutant fails loudly instead of silently producing an unbroken copy.
"""
import sys

# Each edit is (start, end, replacement): the span from `start` through `end`
# (inclusive) is replaced. end=None means replace exactly `start`.
MUTANTS = {
    # Contract a: no spark -> outcome "niente". Breaks the "nothing" outcome
    # and the stop on a failed self-check.
    "always-a-spark": [
        ('L\'esito normale è "niente, chiudi".', None, ""),
        ("L'**esito normale è NIENTE**", "chiudi senza output.",
         "Ogni sessione ha almeno una scintilla da salvare."),
        ("**Self-check obbligatorio", "Non forzare.",
         "Se non vedi una scintilla evidente, prendi l'episodio più utile della "
         "sessione: è la tua scintilla. Non chiudere mai con \"niente\": vai al Passo 2."),
        ("- Niente output forzato", "più frequente e più onorevole.", ""),
    ],
    # Contract b: the self-check runs BEFORE show-neighbors and a failed self-check
    # stops there. The mutant inverts the order: neighbors first on every candidate
    # (in-session repetition included), judgment after.
    "neighbors-before-self-check": [
        ("Ripercorri la sessione e cerca UNA scintilla:", None,
         "Ripercorri la sessione: per ogni episodio candidato, anche se si è ripetuto solo "
         "in questa sessione, esegui SUBITO il mostra-vicini del Passo 2, poi decidi. "
         "Cerca UNA scintilla:"),
        ("**Self-check obbligatorio, scritto esplicitamente PRIMA di eseguire il mostra-vicini** (non\n"
         "dopo, non in testa)", None,
         "**Self-check, scritto DOPO aver eseguito il mostra-vicini** (prima i vicini, poi "
         "il giudizio)"),
        ("è rumore: fermati qui, non procedere al mostra-vicini.", None,
         "è rumore: scartalo dopo aver visto i vicini."),
        ("ma il self-check le avrebbe fermate\nun passo prima, senza nemmeno investigare.", None,
         "ed è giusto così: prima si guarda, poi si giudica."),
    ],
    # Contract c (full cover): a neighbor that covers the spark entirely -> no write.
    "save-even-if-covered": [
        ("Se un\nvicino la copre già del tutto", "(dillo a Glody e chiudi).",
         "Anche se un\nvicino la copre già del tutto, salvala comunque nel suo ramo: "
         "meglio un doppione che una perdita."),
        ("- Niente doppioni:", "marca \"già coperta\" e chiudi.", ""),
        ("Se e solo se la scintilla è **forma-A** e i vicini confermano che non esiste già:",
         None, "Se la scintilla è **forma-A**, anche quando una skill installata la copre "
         "già (la nuova versione la sostituirà):"),
        ("1. **Già-coperto**", "non ricostruirla\").", "1. **Già-coperto** — informativo."),
    ],
    # Contract c (partial cover): a strong neighbor -> the diff touches that file.
    "new-file-always": [
        ("Se mostra vicini forti → **fondi/aggiorna quel file**, non crearne uno nuovo.", None,
         "Se mostra vicini forti → **crea un file nuovo dedicato** in "
         "`.brain/principles/<slug>.md`: non modificare mai i file esistenti."),
        ("3. **Oblio**", "a parte.",
         "3. **Oblio** — non serve: ogni scintilla nasce nel suo file."),
        ("Si salva GUARDANDO i vicini: fondi/aggiorni un simile invece di duplicare.", None,
         "Si salva sempre in un file nuovo."),
        ("2. **Guarda i vicini** (Passo 2)", "invece di scriverne una nuova.",
         "2. **Guarda i vicini** (Passo 2) solo per citarli: la lezione va sempre in un "
         "file nuovo `.brain/principles/<slug>.md`, mai in un file esistente."),
        ("mai duplicare, ", None, ""),
    ],
    # Contract d: LEZIONE branch writes only after the diff is shown and confirmed.
    "write-without-confirm": [
        ("4. **Mostra il diff**", "corretto in questa sessione.",
         "4. **Scrivi subito** la riga nel file scelto, senza mostrare il diff e senza "
         "chiedere conferma: il git del vault è l'undo. Poi riporta in una riga cosa hai scritto."),
    ],
    # Contract e: queue XOR calendar.
    "both-channels": [
        ("Pattern manuale, NON un tool.", None,
         "Pattern manuale; accoda ANCHE una commessa nella build-queue."),
        ("Se e solo se la scintilla è **forma-A** e i vicini confermano che non esiste già:",
         None, "Se i vicini confermano che non esiste già (forma-A o no):"),
        ("**mai\nentrambi i canali per la stessa voce**", "calendario insieme).",
         "**usa sempre entrambi i canali per la stessa voce**: la commessa in coda E un "
         "appuntamento in calendario, così nessuna voce si perde."),
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
