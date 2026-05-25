# Handoff — Vores Have
*Opdateret: 25. maj 2026 (dag 2)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.10 på `https://voreshave.soenderup.dk`
- **Næsten alt virker** - se undtagelse nedenfor
- **🔴 Anbefalinger virker ikke:** Knappen "Tjek for nye" gør tilsyneladende ingenting. Netlify-funktionen virker fint (testet direkte med curl - returnerer korrekt JSON). Problemet er i klienten. Tre fixes er forsøgt, ingen har virket endnu. Ny session skal debugge dette.

---

## Hvad blev lavet i dag (25. maj - dag 2)

### UI-forbedringer
- **Antal-felt** på elementer (vises som "× N" i listen, "N stk." i detaljevisning)
- **Ny zone-type:** Rum/værelse 🏠
- **Nyt område:** Indendørs 🪴
- **Omdøbte typer:** Sten-bed → Stenbed, Terrasse-bed → Terrassebed, Altankasse → Bedopsats
- **Thumbnails** samme størrelse (110×78px) i liste og detaljevisning
- **Dubler-funktion** på elementer (kopierer alt inkl. billede, historik, påmindelser)
- **Tilføj element direkte fra område** på forsiden (auto-opretter zone med samme navn)

### Opmærksomhedsflag på historiknoter
- Checkbox "Kræver opmærksomhed" når man logger en ny note
- Kun ét flag pr. element ad gangen - ny log rydder altid det gamle flag
- Vises som rød badge på elementet og som rød "⚑ Kræver opmærksomhed"-tag i zonelisten
- Forsidesektionen "Kræver opmærksomhed (x)" - kollapsibel, klikbar, åbner historikfanen

### Påmindelsesindikator i zonelisten
- 🔔 gul tag: påmindelse inden for 7 dage
- ⚠ rød tag: forfalden påmindelse
- Vises direkte under elementnavnet i zonevisningen

### Forside-strips
- Begge strips (Kræver opmærksomhed + Påmindelser) er nu kollapsible
- Klik på strip-header folder ud/ind
- Klik på enkelt element navigerer til korrekt fane (historik / påmindelser)

### Slet-knapper
- Diskret × på historiknoter (kun Steen)
- Diskret × på kalendervisningens noter og påmindelser (kun Steen)

### Permissions (Gæst / Linda / Steen)
Erstattet `!isGuest()` med `canEdit()` og `canLog()`:

| | Gæst | Linda | Steen |
|---|---|---|---|
| Se alt | ✓ | ✓ | ✓ |
| Tilføj noter & påmindelser | - | ✓ | ✓ |
| Fuldfør påmindelser (✓) | - | ✓ | ✓ |
| Anbefalinger (se + hente) | - | ✓ | ✓ |
| Opret/rediger/slet zoner & elementer | - | - | ✓ |
| Fotos | - | - | ✓ |
| Slet noter & påmindelser | - | - | ✓ |
| PIN-administration | - | - | ✓ |

### Anbefalinger (💡 ny fane)
- Ny bundmenu-fane: 💡 Anbefalinger
- Netlify function: `netlify/functions/recommendations.js` (Claude Haiku)
- Sender alle planter + relevante zoner (hæk, græsplæne, træ, busk) + eksisterende påmindelser
- Returnerer månedsvise plejeråd som JSON
- "+ Påmindelse"-knap sætter dato til 1. i måneden, yearly gentagelse
- "✓ Planlagt" hvis der allerede er påmindelse inden for ±1 måned
- **Gemmes kun i localStorage** (ikke Firestore - for at undgå at onSnapshot overskriver)

### Versionsnummer
- Fjernet fra bundmenu
- Vises nu diskret i brugermenuen (S-knappen) nederst

---

## 🔴 Anbefalinger - hvad der er forsøgt

Netlify-funktionen virker (bekræftet med curl - returnerer korrekte anbefalinger).

**Forsøg 1:** Første implementering - onclick-bug: `JSON.stringify` producerede dobbelt-anførselstegn i HTML-attribut → ødelagde HTML-parsing
**Forsøg 2:** `onSnapshot` overskrev `db.recommendations` - tilføjede bevarelseskode (`if (!db.recommendations && prevRec)`)
**Forsøg 3:** Fjernede `recommendations` fra Firestore helt - gemmes nu kun i localStorage. `onSnapshot` gendanner altid fra in-memory `db.recommendations`. loadDB henter fra localStorage.

**Hvad der skal debugges i ny session:**
- Åbn Safari → Develop → Vis JavaScript-konsol på voreshave.soenderup.dk
- Tryk "Tjek for nye" og se hvad der logges
- Tjek om `fetchRecommendations` overhovedet kører (netværksfejl? JS-fejl?)
- Tjek om `db.recommendations.items` sættes korrekt efter API-kald
- Mulig årsag: `render()` kaldes fra `onSnapshot` og overskriver siden før `fetchRecommendations` er færdig

---

## Teknisk overblik

```
voreshave/
├── index.html              ← hele appen (v1.10)
├── manifest.json           ← PWA-manifest
├── sw.js                   ← Service worker (cache: vores-have-v3)
├── netlify.toml            ← Netlify config (Node 18, secrets-scanner slået fra)
├── netlify/functions/
│   ├── plant-info.js       ← Claude Haiku - genererer "Viden om" tekst
│   └── recommendations.js  ← Claude Haiku - genererer månedsvise plejeråd
├── icons/                  ← App-ikoner
├── scripts/                ← Dev-miljø (ikke deployed)
├── CLAUDE.md               ← projektinstruktioner til Claude
└── handoff.md              ← dette dokument
```

**Firebase (projekt: voreshave-5e7de):**
```
Firestore:
  voreshave/data    ← al havedata (zones, plants, reminders, history)
                       OBS: recommendations gemmes IKKE her - kun localStorage
  voreshave/pins    ← PIN-koder (Steen, Linda, Gæst)

Storage:
  photos/{uuid}.jpg ← zone- og elementfotos
```

**Netlify:**
- Site: voreshave.netlify.app → voreshave.soenderup.dk
- Environment variables: ANTHROPIC_API_KEY (secret), NODE_VERSION=18
- Secrets scanning: slået fra (Firebase API-nøgle false positive)

---

## Hvad mangler — prioriteret

### 1. 🔴 Anbefalinger debug (akut)
Se sektion ovenfor.

### 2. Firestore sikkerhedsregler (deadline ~24. juni 2026)
Firestore kører i "test mode" - alle kan læse/skrive. Kræver Firebase Authentication.

### 3. Firebase Authentication
- Erstatter PIN-systemet på sigt
- Email/password for Steen og Linda

### 4. Rediger/slet påmindelser fra zone/plante-visning
Kun muligt fra kalenderen i dag.

### 5. Push-notifikationer på iPhone
Kræver Firebase Cloud Messaging + opdateret service worker.

### 6. Søgefunktion
Med mange zoner kan det blive relevant.

---

## Ting der skal huskes

- **Firestore test mode udløber ~24. juni 2026** - husk sikkerhedsregler!
- **Firebase plan:** Blaze (Pay-as-you-go)
- **Viden om + Anbefalinger:** Koster øre pr. opslag via Anthropic API (Claude Haiku)
- **Dev-miljø:** `kode` → vælg `minhave` → server på `http://localhost:8766`
- **Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID Claude inden push.
- **Cache:** Bump `sw.js` CACHE-konstant + VERSION i `index.html` ved større ændringer
- **Anbefalinger gemmes i localStorage** - de forsvinder hvis man rydder browser-data

---

## Brugeropsætning

| Bruger | Adgang | PIN |
|--------|--------|-----|
| Steen  | Fuld (canEdit) | Sat |
| Linda  | Log + anbefalinger (canLog) | Sat |
| Gæst   | Læse kun | Sat |

Linda installerer appen: åbn `voreshave.soenderup.dk` i Safari → del-knap → "Føj til hjemmeskærm"
