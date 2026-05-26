# Fejl: dev-miljø virker ikke efter omdøbning fra minhave til VoresHave

*Oprettet: 26. maj 2026 — Opdateret: 26. maj 2026*

---

## ✅ LØST (26. maj 2026, kl. 21:05)

---

## Symptomer

- Terminal-vinduet resizes ikke til venstre 67%
- Safari åbner ikke localhost i højre 33%
- Når Claude Code lukkes (exit) lukker Terminal og Safari IKKE automatisk
- macOS viser "Vil du bringe aktive processer til ophør?" dialog gentagne gange under aktiv session

## Fundne årsager (historik)

### Årsag 1: `setsid` eksisterer ikke på macOS (rettet i commit 3aeade9)
`scripts/dev-start.sh` brugte `nohup setsid bash -c '...'` til baggrundsvagten.  
`setsid` er et Linux-kommando og findes ikke på macOS.

### Årsag 2: `pkill -f "python3 -m http.server 8766"` matchede ikke (rettet i commit 3aeade9)
macOS kører Python-serveren med fuld sti, ikke `python3`.  
Rettet til `pkill -f "http.server $PORT"`.

### Årsag 3 (HOVED-ÅRSAG): Stop-hook fyrer efter HVERT svar ← DET STORE PROBLEM

**Symptom:** "Terminate active processes"-dialogen vises gentagne gange UNDER aktiv session, ikke kun ved exit.

**Årsag:** Stop-hook i `.claude/settings.json` peger på `dev-stop.sh`.  
Claude Code's `Stop`-event fyrer **efter hvert assistant-svar** (når agentic loop pauser for brugerinput), IKKE kun ved session-exit.

**Konsekvens:** For hvert svar Claude gav:
1. Stop fyrede → `dev-stop.sh` kørte
2. HTTP-server dræbt
3. `/tmp/voreshave_dev/` ryddet
4. Baggrundsskript forsøgte at lukke Terminal-vindue (efter 2 sek.)
5. Terminal så claude + caffeinate som aktive processer → dialogen

**Hvorfor virkede det før?** Fordi projektstien var forkert (gammel `minhave`-sti).  
Hooken fejlede lydløst → ingen skade. Efter omdøbning til `VoresHave` virkede stien → ødelagde alt.

**Rettelse:** Stop-hook er FJERNET fra `settings.json`. Kun `SessionStart` og `PostToolUse` er tilbage.  
Oprydning ved exit håndteres KUN af baggrundsvagten (watcher), der overvåger Claude's PID.

### Årsag 4: Upålidelig PID-detektion (rettet 26. maj 2026)
`dev-start.sh` brugte `$PPID` direkte. Afhængig af hvordan Claude Code kører hooken  
(med eller uden mellemliggende shell), kan `$PPID` pege på et kortlivet shell-process i stedet for Claude.

**Rettelse:** Bruger nu process-træ-traversal — går op ad træet fra `$$` indtil `claude`-processen findes.  
Fallback til `$PPID` hvis traversal fejler.

### Årsag 5: Race condition — gammel watcher rydder ny sessions filer (delvist rettet)
**Scenario:** Forrige sessions Stop-hook / watcher kaldte `dev-stop.sh` EFTER ny sessions `dev-start.sh`.  
Resulterede i tom `/tmp/voreshave_dev/` og ingen kørende server.

**Rettelse:** Session-token i `/tmp/voreshave_dev/session.token`.  
Watcher tjekker token inden oprydning — gammel watcher springer over hvis ny session er startet.

---

## Rettelser (26. maj 2026)

| Problem | Fil | Rettelse |
|---------|-----|----------|
| Stop-hook fyrer efter hvert svar | `settings.json` | Stop-hook FJERNET |
| PID-detektion upålidelig | `dev-start.sh` | Process-træ traversal i stedet for $PPID |
| Race condition | `dev-start.sh` + `dev-stop.sh` | Session-token tilføjet |
| Terminal-dialog for hurtig | `dev-stop.sh` | Forsinkelse øget fra 2 til 4 sek. |

---

## Sådan testes det virker

1. `/clear` → vælg VoresHave
2. Terminal skal fylde venstre 67%, Safari åbne localhost
3. Skriv noget, få et svar — **ingen dialog skal vises**
4. Skriv `exit` i Claude Code
5. Safari skal lukke, Terminal skal lukke — UDEN dialog
6. Tjek `/tmp/voreshave_dev/` — skal have 5 filer ved sessionstart

---

## Hvis dialogen stadig vises

Stop-hooken er fjernet — dialogen KAN ikke komme fra den vej mere.  
Hvis den stadig vises: det er watchers `dev-stop.sh` der kører med for kort forsinkelse.  
Øg `sleep 4` til `sleep 6` i `dev-stop.sh`.

---

## Fejl 2: Safari crasher ved auto-reload (løst tidligere)

**Symptom:** Safari viste fejlmeddelelse om at ville lukke, hver gang Claude redigerede en fil.
**Årsag:** `dev-reload.sh` sendte AppleScript-keystrokes til Safari.
**Rettelse:** Keystroke-kommandoerne er fjernet. Auto-reload er deaktiveret — tryk Cmd+R manuelt.
