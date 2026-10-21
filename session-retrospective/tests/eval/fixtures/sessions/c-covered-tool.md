# Session transcript (fixture: tool idea already fully covered by an installed skill)

**Glody:** Lo script `backup-vault.sh` funziona sul Mac ma sulla VPS Linux fallisce.

**Claude:** Sulla VPS `sed -i '' 's/x/y/'` fallisce: la sintassi BSD di `sed -i` con suffisso vuoto non è valida in GNU sed. Corretto con `sed -i.bak ... && rm file.bak`, portabile su entrambi.

**Glody:** Ora fallisce un'altra riga.

**Claude:** `date -d '1 day ago'` esiste solo in GNU date; sul Mac serviva `date -v-1d`, e lo script era stato scritto per il Mac con un ramo sbagliato. Corretto con un ramo `uname`. Poi `readlink -f` sul Mac di vecchie versioni non esiste: sostituito con `cd "$(dirname "$0")" && pwd -P`.

**Glody:** Ci abbiamo messo un'ora per tre righe. Mi servirebbe uno strumento che, dato uno script bash, mi segnala in anticipo tutti i costrutti non portabili tra macOS e Linux (sed -i, date -d, readlink -f) con l'alternativa portabile, prima di metterlo sulla VPS.

**Claude:** Lo script ora gira su entrambi. Annotato il bisogno dello strumento.
