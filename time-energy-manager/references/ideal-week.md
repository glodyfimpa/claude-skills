# Ideal Week Template

Reference template for the Time & Energy Manager skill. Claude reads this to generate daily plans adapted to the day of the week and sprint cycle.

## Vincoli Fissi

- **Lavoro:** Lun-Ven 9:00-17:00 (remoto, ADESSO - GNV)
- **Pranzo:** 13:00-13:30 con famiglia
- **Palestra:** Lun + Gio, esce 17:00, rientra ~19:30 (dopo = solo famiglia/relax)
- **Compagna palestra:** Mer, esce 17:30, rientra ~20:00 (lui col bimbo)
- **Aperitivo famiglia:** Ven dalle 18:00
- **Domenica:** OFF totale
- **Sonno:** mezzanotte/1:00 → sveglia 8:20
- **Routine mattutina:** 08:20-09:00 (stretching + meditazione + doccia)

## Meeting Ricorrenti

| Meeting | Quando | Orario |
|---------|--------|--------|
| Daily standup | Lun-Ven | 10:15-10:30 |
| Daily cliente (ciclo 3 settimane) | Lun-Ven | 10:45-11:00 |
| Refinement | Lun + Gio | 11:00-13:00 |
| Sprint review prep | Ogni 2 Lun | 15:30-16:00 |
| Sprint Review | Settimana A, Mar | 09:30-11:00 |
| Planning 1 | Settimana A, Mar | 11:30-13:00 |
| Planning 2 | Settimana A, Mar | 15:00-16:00 |
| Tech Review | Settimana B, Mar | 11:30-13:00 |
| Retrospective | Ogni 2 Mer | Orario variabile |

## Ciclo Sprint

Le settimane si alternano: **Settimana A** (sprint ceremonies) e **Settimana B** (tech review). Per determinare quale settimana e, calcola il numero della settimana ISO dalla data corrente. Se pari = A, se dispari = B (calibrare con l'utente al primo utilizzo).

## Finestra d'Oro: 9:00-10:15

Ogni mattina lavorativa, ~1h prima dei meeting. Proteggi questo blocco per side business e studio personale. Non schedulare mai lavoro del cliente qui a meno che non ci sia un'emergenza (e in quel caso, Fase 3 Pivot lo gestisce).

## Giornate Tipo

### Lunedi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio personale | Personale |
| 10:15-10:30 | Daily standup | Lavoro |
| 10:30-11:00 | Lavoro | Lavoro |
| 11:00-13:00 | Refinement | Lavoro |
| 13:00-13:30 | Pranzo con famiglia | Famiglia |
| 13:30-14:00 | Rientro morbido | Lavoro leggero |
| 14:00-14:15 | Pausa early afternoon | Pausa |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura (+ prep sprint review ogni 2 Lun 15:30-16:00) | Lavoro |
| 17:00-19:30 | Palestra (uscita 17:00, rientro ~19:30) | Benessere |
| 19:30+ | Famiglia e relax | OFF |

### Martedi — Settimana A (Sprint)

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-09:25 | Side business (finestra ridotta) | Personale |
| 09:30-11:00 | Sprint Review | Lavoro |
| 11:00-11:15 | Micro-reset post-meeting | Pausa |
| 11:30-13:00 | Planning 1 | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:00 | Lavoro | Lavoro |
| 15:00-16:00 | Planning 2 | Lavoro |
| 16:00-17:00 | Lavoro / recupero | Lavoro |
| 17:00-17:20 | Reset break | Pausa |
| 17:20-17:50 | Sviluppo personale (se energia >= 3) | Personale |
| 17:50-18:00 | Evening Close | TEM |
| 18:00+ | Famiglia e relax | OFF |

### Martedi — Settimana B (Tech)

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-11:30 | Deep work | Lavoro |
| 11:30-13:00 | Tech Review | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-17:20 | Reset break | Pausa |
| 17:20-17:50 | Sviluppo personale (se energia >= 3) | Personale |
| 17:50-18:00 | Evening Close | TEM |
| 18:00+ | Famiglia e relax | OFF |

### Mercoledi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-12:00 | Deep work (o Retrospective ogni 2 Mer) | Lavoro |
| 12:00-12:15 | Pausa | Pausa |
| 12:15-13:00 | Lavoro | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-17:30 | Transizione | — |
| 17:30-20:00 | Solo con il bimbo (compagna in palestra) | Famiglia |
| 20:00+ | Relax | OFF |

### Giovedi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-11:00 | Lavoro | Lavoro |
| 11:00-13:00 | Refinement | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-19:30 | Palestra | Benessere |
| 19:30+ | Famiglia e relax | OFF |

### Venerdi

| Orario | Attivita | Tipo |
|--------|----------|------|
| 08:20-09:00 | Routine mattutina | Fisso |
| 09:00-09:10 | Morning Plan con Claude | TEM |
| 09:10-10:10 | Side business / studio | Personale |
| 10:15-10:30 | Daily | Lavoro |
| 10:30-12:00 | Deep work (giorno piu libero da meeting) | Lavoro |
| 12:00-12:15 | Pausa | Pausa |
| 12:15-13:00 | Lavoro | Lavoro |
| 13:00-13:30 | Pranzo | Famiglia |
| 13:30-14:15 | Rientro morbido | Lavoro leggero |
| 14:15-15:45 | Deep work | Lavoro |
| 15:45-16:00 | Pausa | Pausa |
| 16:00-17:00 | Admin / chiusura | Lavoro |
| 17:00-17:20 | Reset break (opzionale) | Pausa |
| 17:20-17:50 | Sviluppo personale (opzionale, se energia >= 3) | Personale |
| 18:00+ | Aperitivo + famiglia | OFF |

### Sabato

| Attivita | Note |
|----------|------|
| Famiglia, ritmo lento | Mattina |
| 2h studio/side business | Quando possibile, non obbligatorio |
| Famiglia e relax | Resto della giornata |

### Domenica

| Attivita | Note |
|----------|------|
| Famiglia, relax, zero programmi | Tutto il giorno |
| Weekly Review con PRS (opzionale) | Sera, per preparare la settimana |

## Regole Pause

1. **Mai piu di 90 min consecutivi di deep work** → 10-15 min pausa
2. **Dopo meeting lungo (>1h)** → 5-10 min micro-reset
3. **13:30-14:15** → rientro morbido, niente deep work
4. **14:00-14:15** → early afternoon reset
5. **Transizione post-lavoro (17:00-17:20)** → reset break prima dello sviluppo personale

## Logica Energia Post-Lavoro

- Energia >= 3/5 → propone blocco 17:20-17:50 con reset break
- Energia = 2/5 → solo 20 min di qualcosa leggero (lettura, review)
- Energia = 1/5 → "Oggi hai dato abbastanza. Vai diretto a relax."

## Budget Settimanale Side Business/Studio

- Lun-Ven 9:00-10:15: ~5h/settimana
- Mar/Ven 17:20-17:50: ~1h/settimana (se energia lo permette)
- Sabato: ~2h (quando possibile)
- **Totale: 7-8h/settimana**
