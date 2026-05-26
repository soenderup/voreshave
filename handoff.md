# Handoff — Vores Have
*Opdateret: 26. maj 2026*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.21 på `https://voreshave.soenderup.dk`
- **Næste:** Se prioriteringslisten nedenfor

---

## Seneste arbejde (26. maj)

### Rollebaseret brugerstyring via UI (v1.21)

**Datastruktur:**
- `voreshave/users` erstatter `voreshave/pins` i Firestore
- Auto-migration ved første load: henter eksisterende pins og opretter users-dokument
- Struktur: `{ list: [{ id, name, pin, role, initials }] }`

**Faste roller:**
| Rolle | Rettigheder |
|-------|-------------|
| `admin` | Alt - inkl. opret/slet brugere, rediger zoner og elementer |
| `member` | Log noter, tilføj påmindelser, se anbefalinger |
| `guest` | Kun læse |

**Hvad der er bygget:**
- `canEdit()`, `canLog()`, `canManageUsers()` er nu rollebaserede (ikke hardkodede på navn)
- Lockscreen viser brugerknapper dynamisk fra `users`-listen. Gæst-bruger får "Fortsæt som gæst"-knap
- Hamburgermenu: "👥 Administrer brugere" vises kun for admin + "📋 Login-log"
- Brugerstyring UI (kun admin): opret, rediger, slet brugere — maks 5 i alt
- Validering: mindst én admin, unikke navne, PIN 4-6 cifre, kan ikke slette sig selv
- Påmindelses-dropdown (assignedTo) er dynamisk fra users-listen
- Initialer og chip-farver er dynamiske (5 farver: color-0..color-4)

**Vigtigt ved første deploy:**
Migration kører automatisk første gang appen åbnes. `voreshave/pins` røres ikke — kun læst. `voreshave/users` oprettes med Steen (admin), Linda (member), Gæst (guest).

---

### Samlet oprettelsesflow via hamburgermenu (v1.20)
- Hamburgermenu (☰) viser altid "Ny zone" og "Nyt element" - uanset hvilken side man er på
- "Ny zone"-dialog: område-vælger + valgfri forælderzone-vælger. Pre-selecter automatisk baseret på aktuel visning
- "Nyt element"-dialog: område-vælger + zone-vælger. Pre-selecter automatisk baseret på aktuel visning
- Fjernet alle inline "Tilføj zone"/"Tilføj element"-knapper fra forsiden og zone-visningen

### Hamburger-menu (v1.19)
- Én rund `☰`-knap erstatter bruger-avatar + rediger + tilføj-knapper
- Kontekst-sektion øverst (viser/skjuler afhængigt af aktuel side)
- Bruger-sektion nederst: PIN, login-log, lås

### Zone-header og app-header redesign + login-log (v1.18)

**Zone-header:**
- Foto som hero-billede (140px, afrundede hjørner, 1rem margin alle sider)
- Gradient-overlay i bunden, zone-navn som hvid tekst i hjørnet
- Fjernet ikon, type og beskrivelse fra zone-headeren
- Bugfix: tilbage fra element direkte i område går til hjem, ikke ghost-zone

**App-header:**
- Logo altid centreret via `position: relative` + absolut positionerede knapper
- Tilbageknap ændret til smal `‹` pil (ingen tekstforskydning af logo)
- Emoji og titel i CSS grid-layout - ugedag flugter præcist med "V"et

**Login-log (kun Steen):**
- Logger bruger, tidspunkt og enhed ved hvert PIN-login
- Gemmes i `voreshave/loginlog` i Firestore (`arrayUnion`)
- Knap i Steens brugermenu: "📋 Login-log" - viser 60 seneste, nyeste øverst

### Trivseldata - segmenteret bar (v1.16 → v1.17)

**Tre nye felter på alle planter:**
- `water`: `'dry'` / `'normal'` / `'moist'`
- `light`: `'full'` / `'full-partial'` / `'partial'` / `'partial-shade'` / `'shade'`
- `perennial`: `true` / `false`

**Visning (variant A - segmenteret bar):**
- Væske: 💧 ──[bar]── 🌧️ (3 segmenter)
- Lys: ☁️ ──[bar]── ☀️ (5 segmenter)
- Levetid: pills (🌱 Etårig / ♾️ Flerårig)

**Auto-udfyldning:**
- Ved identificér-foto: `identify-plant.js` returnerer alle tre felter
- Ved ny plante: `fetchPlantInfo()` gemmer care-data fra `plant-info.js`

---

## Teknisk overblik

```
voreshave/
├── index.html              ← hele appen (v1.21)
├── manifest.json           ← PWA-manifest
├── sw.js                   ← Service worker (cache: vores-have-v7, network-first for HTML)
├── netlify.toml            ← Netlify config (Node 18, secrets-scanner slået fra)
├── netlify/functions/
│   ├── plant-info.js       ← Claude Haiku - genererer "Viden om" tekst
│   ├── recommendations.js  ← Claude Haiku - per-plante anbefalinger
│   └── identify-plant.js   ← Claude Sonnet 4.6 - identifikation via foto
├── icons/                  ← App-ikoner
├── scripts/                ← Dev-miljø (ikke deployed)
├── CLAUDE.md               ← projektinstruktioner til Claude
└── handoff.md              ← dette dokument
```

**Firebase (projekt: voreshave-5e7de):**
```
Firestore:
  voreshave/data    ← al havedata (zones, plants, reminders, history)
  voreshave/pins    ← gammel PIN-struktur (beholdes til migration, rør ikke)
  voreshave/users   ← ny brugerstruktur med roller (oprettet automatisk v1.21)
  voreshave/loginlog ← login-historik

Storage:
  photos/{uuid}.jpg ← zone- og elementfotos
```

**Netlify:**
- Site: voreshave.netlify.app → voreshave.soenderup.dk
- Environment variables: ANTHROPIC_API_KEY (secret), NODE_VERSION=18
- Secrets scanning: slået fra (Firebase API-nøgle false positive)

**Bruger-datastruktur (v1.21):**
```js
// voreshave/users
{ list: [
  { id: 'uid1', name: 'Steen', pin: '123456', role: 'admin',  initials: 'S' },
  { id: 'uid2', name: 'Linda', pin: '654321', role: 'member', initials: 'L' },
  { id: 'uid3', name: 'Gæst',  pin: '000000', role: 'guest',  initials: 'G' },
]}
```

---

## Hvad mangler — prioriteret

### 1. Firestore sikkerhedsregler (deadline ~24. juni 2026)
Firestore kører i "test mode" - alle kan læse/skrive uden login. Kræver Firebase Authentication for at kunne skrive ordentlige regler. Firebase Auth er et større projekt (2-3 dage) og løses separat fra brugerstyring.

### 2. Push-notifikationer på iPhone
Kræver Firebase Cloud Messaging + opdateret service worker.

### 3. Søgefunktion
Med mange zoner kan det blive relevant.

---

## Ting der skal huskes

- **Firestore test mode udløber ~24. juni 2026** - husk sikkerhedsregler!
- **Firebase plan:** Blaze (Pay-as-you-go)
- **Viden om + Anbefalinger + Identificer:** Koster øre pr. opslag via Anthropic API
- **Dev-miljø:** `kode` → vælg `minhave` → server på `http://localhost:8766`
- **Lokal server understøtter IKKE POST** - Netlify-funktioner testes kun på live
- **Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID inden push
- **PWA cache:** SW bruger network-first for HTML — luk og genåbn app for at få seneste version
- **Cache-bump:** Kun nødvendigt når `SHELL`-listen i `sw.js` ændres (nye ikoner e.l.)
- **VERSION:** Kun ved større funktionsændringer
- **Netlify gratis-plan:** 10 sekunders timeout på functions - hold kald små
- **voreshave/pins:** Rør ikke — bruges til migration hvis nogen endnu ikke har fået `voreshave/users`

---

## Brugeropsætning

| Bruger | Rolle | Adgang |
|--------|-------|--------|
| Steen  | admin | Alt inkl. brugerstyring |
| Linda  | member | Log noter, påmindelser, anbefalinger |
| Gæst   | guest | Kun læse |

Linda installerer appen: åbn `voreshave.soenderup.dk` i Safari → del-knap → "Føj til hjemmeskærm"
