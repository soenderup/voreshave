# Fejl: dev-miljø virker ikke efter omdøbning fra minhave til VoresHave

*Oprettet: 26. maj 2026*

---

## Symptomer

- Terminal-vinduet resizes ikke til venstre 67%
- Safari åbner ikke localhost i højre 33%
- Når Claude Code lukkes (exit) lukker Terminal og Safari IKKE automatisk
- macOS viser "Vil du bringe aktive processer til ophør?" dialog når man manuelt prøver at lukke Terminal

## Fundne årsager (26. maj 2026)

### 1. `setsid` eksisterer ikke på macOS
`scripts/dev-start.sh` brugte `nohup setsid bash -c '...'` til baggrundsvagten.  
`setsid` er et Linux-kommando og findes ikke på macOS.  
Konsekvens: baggrundsvagten startede aldrig — ingen automatisk oprydning ved exit.

### 2. `pkill -f "python3 -m http.server 8766"` matchede ikke
macOS kører Python-serveren som:
```
/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/Resources/Python.app/Contents/MacOS/Python -m http.server 8766
```
Dvs. binæren hedder `Python` (stort P) med fuld sti — ikke `python3`.  
Konsekvens: pkill dræbte ikke den gamle server → ny server fejlede (port optaget) → ingen fungerende dev-server.

### 3. "Terminate processes"-dialog
Stop-hook'en kører *mens* Claude Code stadig lukker ned.  
Når dev-stop.sh prøvede at lukke Terminal-vinduet på det tidspunkt, så Terminal stadig aktive processer (claude, caffeinate, bash) og viste dialogen.

### 4. `/tmp/voreshave_dev/` endte tom
Sandsynligvis race condition: forrige sessions Stop-hook var stadig i gang da ny sessions dev-start.sh skrev sine filer — og slettede dem bagefter.

---

## Rettelser lavet (commit 3aeade9)

| Problem | Rettelse |
|---------|----------|
| `setsid` | Fjernet — baggrundsvagt bruger nu bare `nohup bash` |
| pkill-pattern | Ændret til `pkill -f "http.server $PORT"` (matcher uanset Python-sti) |
| Terminal-dialog | Terminal-lukning sker nu i baggrundsskript med 2 sek. forsinkelse |
| Watcher PID | Bruger nu `$PPID` direkte (Claude-processens PID) i stedet for procestræ-søgning |

---

## Sådan testes det virker

1. Start ny session: `kode` → vælg VoresHave
2. Terminal skal automatisk fylde venstre 67%, Safari åbne localhost i højre 33%
3. Skriv `exit` i Claude Code
4. Safari skal lukke, Terminal skal lukke — UDEN "terminate processes"-dialog
5. Tjek `/tmp/voreshave_dev/` — der skal ligge `terminal_win_id.txt`, `server.pid`, `watcher.pid`, `claude.pid`

---

## Hvis det stadig ikke virker — hvad der skal undersøges

```bash
# Tjek om filer faktisk gemmes ved sessionstart:
ls -la /tmp/voreshave_dev/

# Tjek om serveren kører korrekt:
ps aux | grep "http.server 8766" | grep -v grep

# Tjek om baggrundsvagten kører:
cat /tmp/voreshave_dev/watcher.pid
ps -p $(cat /tmp/voreshave_dev/watcher.pid) -o pid,args 2>/dev/null

# Tjek Terminal vindue-ID:
cat /tmp/voreshave_dev/terminal_win_id.txt
osascript -e 'tell application "Terminal" to return id of front window'
# De to skal matche!
```

---

## Fejl 2: Safari crasher ved auto-reload (26. maj 2026)

**Symptom:** Safari viser fejlmeddelelse om at ville lukke, hver gang Claude redigerer en fil.

**Årsag:** `dev-reload.sh` sendte AppleScript-keystrokes (`Cmd+Option+E` og `Cmd+Option+R`) til Safari for at tømme cache og hård-genindlæse. Disse keystrokes kunne ramme dialoger i Safari på det forkerte tidspunkt.

**Rettelse (commit 3daf557):** Keystroke-kommandoerne er fjernet. URL-navigeringen i AppleScriptet (`set URL of t to "..."`) genindlæser siden tilstrækkeligt.

---

Hvis `/tmp/voreshave_dev/` er **tom** igen på trods af rettelserne, er problemet formentlig at:
- Stop-hook fra forrige session kørte *efter* ny sessions dev-start.sh
- Løsning: tilføj session-token til dev-start.sh som dev-stop.sh tjekker inden sletning
