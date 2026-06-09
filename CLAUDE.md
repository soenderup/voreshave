# VoresHave — CLAUDE.md

## Projekt
En have-app. Teknologistack er rent HTML/CSS/JS - ingen build-trin, ingen frameworks.

## Deploy
- Lokalt: `http://localhost:8081` (startes automatisk ved sessionstart)
- GitHub → Netlify: push til `main` udløser automatisk live deploy. Spørg **altid** inden push.

## Dev-miljø
Styres af `.claude/settings.json` med tre hooks:
- **SessionStart**: `scripts/dev-start.sh` — starter HTTP-server, placerer vinduer, starter baggrundsvagt
- **PostToolUse**: `scripts/dev-reload.sh` — auto-reload i Safari ved ændring af `.html`-filer
- **Stop**: `scripts/dev-stop.sh` — rydder op når Claude Code lukkes

## Filer
- `index.html` — eneste side pt.
- `scripts/` — dev-miljø-scripts (ikke deployed, ikke relevant for Netlify)
- `handoff.md` — sessionhandoff (intern fil)

## Vigtige regler
- Test **altid** lokalt inden commit
- Kør **aldrig** build-test inden push - der er ingen build, bare push
- `scripts/`-mappen skal **ikke** med i Netlify-deploy (tilføj `netlify.toml` eller `_redirects` ved behov)
