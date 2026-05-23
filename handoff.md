# Handoff — minhave opstartsgennemgang

Læs dette ved første session i projektet. Gennemgå punkterne og beslut hvad der skal ændres.

---

## Hvad sker der automatisk ved sessionstart?

Når du skriver `kode` og vælger `minhave`, kører `scripts/dev-start.sh` automatisk via `.claude/settings.json` (SessionStart-hook).

### Trin for trin:

**1. Tmp-mappe oprettes**
`/tmp/minhave_dev/` — bruges til PID-filer og vindue-ID.
Ændr: intet at ændre her.

**2. Eventuel gammel server stoppes**
`pkill -f "python3 -m http.server 8766"`
Ændr: **port 8766** — skal du bruge en anden port?

**3. HTTP-server startes**
`python3 -m http.server 8766` fra projektmappen.
Serverer alle filer i `/Documents/udvikling/minhave/` på `http://localhost:8766`.
Ændr: port som nævnt ovenfor.

**4. Skærmstørrelse hentes dynamisk via AppleScript**
Virker på alle skærmstørrelser og ekstern skærm.
Ændr: intet nødvendigt.

**5. Terminal-vindue placeres: venstre 67% af skærmen**
Ændr: procentsatsen i linjen `TERM_W=$(python3 -c "print(int($SCREEN_W * 0.67))")`

**6. Safari åbnes: højre 33% af skærmen**
Lukker alle eksisterende Safari-vinduer og åbner `http://localhost:8766`.
Ændr: vil du beholde eksisterende Safari-vinduer? Eller en anden browser?

**7. Fokus gives tilbage til Terminal**
Safari er synlig til højre, Terminal aktiv til venstre.
Ændr: intet nødvendigt.

**8. Baggrundsvagt startes**
Holder øje med Claude Code-processen. Når Claude Code lukkes (ikke ved `/clear`), køres `dev-stop.sh` automatisk som rydder op.
Ændr: intet nødvendigt.

**9. Git branch-info vises**
Viser aktuel branch og alle branches i terminalen.
Ændr: intet nødvendigt.

---

## Hvad sker der ved fil-ændringer? (PostToolUse-hook)

Hver gang Claude redigerer en `.html`-fil kører `scripts/dev-reload.sh`:
- Finder Safari-fanen med `localhost:8766`
- Navigerer til den ændrede side
- Tømmer cache (Cmd+Option+E)
- Genindlæser siden (Cmd+Option+R)
- Giver fokus tilbage til Terminal

Ændr: intet nødvendigt med mindre du ikke vil have auto-reload.

---

## Hvad sker der ved nedlukning?

`scripts/dev-stop.sh` kører og:
- Stopper HTTP-serveren
- Lukker Safari's localhost-vindue (nulstiller størrelsen)
- Lukker Terminal-vinduet der kørte Claude Code

---

## Tjekliste — beslut nu

- [ ] Port 8766 — passer det, eller vil du have en anden?
- [ ] Safari lukker alle vinduer ved opstart — ok?
- [ ] Terminal venstre 67% / Safari højre 33% — ok?
- [ ] Auto-reload ved fil-ændringer — ok?
- [ ] Projektet mangler CLAUDE.md — skal der oprettes en?
- [ ] GitHub-repo — skal projektet pushes til GitHub?
