# Handoff — Vores Have
*Opdateret: 26. maj 2026*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.19 på `https://voreshave.soenderup.dk` (v1.20 klar til push)
- **Næste:** push til GitHub → live deploy

---

## Seneste arbejde (26. maj)

### Samlet oprettelsesflow via hamburgermenu (v1.20)
- Hamburgermenu (☰) viser altid "Ny zone" og "Nyt element" - uanset hvilken side man er på
- "Ny zone"-dialog: område-vælger + valgfri forælderzone-vælger. Pre-selecter automatisk baseret på aktuel visning
- "Nyt element"-dialog: område-vælger + zone-vælger. Pre-selecter automatisk baseret på aktuel visning
- Fjernet alle inline "Tilføj zone"/"Tilføj element"-knapper fra forsiden og zone-visningen
- Kontekst-sektionen i menu viser stadig "Rediger zone"/"Rediger element" + "Tilføj påmindelse"/"Tilføj log-note"

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
- Blok vises øverst i info-sektionen med fuld bredde

**Auto-udfyldning:**
- Ved identificér-foto: `identify-plant.js` returnerer alle tre felter
- Ved ny plante: `fetchPlantInfo()` gemmer care-data fra `plant-info.js`
- Begge Netlify-funktioner returnerer nu JSON med `{info, water, light, perennial}`

**Migration af eksisterende planter (enkeltstående - kør én gang):**
- Forsiden viser banner "X elementer mangler trivseldata" med "Udfyld automatisk"-knap
- `migrateAllCareData()` processer alle planter uden care-data (300ms pause pr. plante)
- Individuel "🌿 Hent trivseldata"-knap på hver planteside der mangler data

**Fravalgt:** vindtolerance - ikke nok værdi for almindelig havebrug

---

## Tidligere arbejde

### Identifikation og navngivning (v1.14)

- **"Planteidentifikation"** omdøbt til **"Identifikation via foto"** — kan jo være træer, buske, grøntsager osv.
- Knap **"Opret element i haven"** → **"Opret element"**
- Identificér-knap **"🔍 Identificer plante"** → **"🔍 Identificer"**

### Foto medfølger fra identificér (v1.14)

- Når man opretter et element fra identificér-resultatet, tages billedet med som elementets foto
- Foto sættes som base64 med det samme, uploades til Firebase Storage i baggrunden
- Ny hjælpefunktion: `uploadBase64Photo(base64)` — uploader direkte fra base64 uden File-objekt

### Område/Zone/Element vælger (v1.14)

- Rediger element: tilføjet OMRÅDE-vælger øverst — zone-listen filtreres dynamisk
- Opret fra identificér: samme OMRÅDE + ZONE vælger
- Gem flytter elementet til den valgte zone og navigerer korrekt

### Direkte elementer under område (v1.15)

**Baggrund:** Alle elementer skal teknisk have en `zoneId`. "Direkte" elementer oprettes via en usynlig ghost-zone (`isDirect: true`, `type: 'andet'`).

**Hvad vi byggede:**
- `isDirectZone(zid)` — detekterer ghost-zoner via `isDirect` flag ELLER heuristik (type 'andet', ingen beskrivelse, ingen underzoner, 1 element)
- `directElementCard(z, p)` — renderer element-kort direkte under området (med foto-thumbnail, navn, type, status-badge)
- Område-tæller viser nu **"X zoner · Y elementer"** separat
- Ghost-zoner filtreres fra zone-vælgeren i rediger/identificér
- **"— Direkte i området —"** som første valg i zone-dropdown — virker i både "Rediger element" og "Opret fra identificér"
- `deletePlant`: auto-sletter tom ghost-zone og navigerer hjem
- `submitEditPlant`: auto-sletter tom ghost-zone når element flyttes væk
- `submitAddDirectPlant`: sætter `isDirect: true` på ny ghost-zone

**Hierarkier der virker:**
- Område → Element (direkte, som element-kort)
- Område → Zone → Element
- Område → Zone → Zone → Element

---

---

## Teknisk overblik

```
voreshave/
├── index.html              ← hele appen (v1.15)
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
  voreshave/pins    ← PIN-koder (Steen, Linda, Gæst)

Storage:
  photos/{uuid}.jpg ← zone- og elementfotos
```

**Netlify:**
- Site: voreshave.netlify.app → voreshave.soenderup.dk
- Environment variables: ANTHROPIC_API_KEY (secret), NODE_VERSION=18
- Secrets scanning: slået fra (Firebase API-nøgle false positive)

**Zone-datastruktur:**
```js
// Ghost-zone (direkte element under område)
{ id, name, type: 'andet', area: 'baghave', description: '', parentZoneId: null, isDirect: true }

// Normal zone
{ id, name, type: 'bed'|'højbed'|..., area: 'baghave', description: '...', parentZoneId: null|zid }
```

---

## Hvad mangler — prioriteret

### ~~3. Samlet oprettelsesflow via hamburgermenuen~~ ✅ FÆRDIG (v1.20)

---

### 1. Brugerstyring via UI (næste prioritet)

**Ønsket:** Steen skal via UI kunne oprette nye brugere (maks 5), tildele dem en rolle og sætte deres PIN. Ingen Firebase Auth - kun PIN-login som nu.

**Roller der skal understøttes:**
| Rolle | Hvad må man |
|-------|-------------|
| `admin` | Alt - inkl. opret/slet brugere, rediger zoner og elementer |
| `member` | Log noter, tilføj påmindelser, se anbefalinger |
| `guest` | Læse kun - ingen ændringer |

**Nuværende problem:** Brugerne er hardcodet (`canEdit() = currentUser() === 'Steen'`), og PIN-data er en flad struktur `{ Steen: '123456', Linda: '...' }` i Firestore. Maks-antal og roller kan ikke styres.

---

**Hvad der skal bygges - trin for trin:**

**Trin 1: Ny datastruktur i Firestore**

Erstat `voreshave/pins` med `voreshave/users`:
```js
// voreshave/users
{
  list: [
    { id: 'uid1', name: 'Steen', pin: '123456', role: 'admin' },
    { id: 'uid2', name: 'Linda', pin: '654321', role: 'member' },
    { id: 'uid3', name: 'Gæst',  pin: '000000', role: 'guest' },
  ]
}
```
Migration: ved første load tjekkes om `voreshave/users` eksisterer - ellers oprettes den ud fra det eksisterende `voreshave/pins`.

**Trin 2: Refaktor af roller**

Erstat de tre hardcodede funktioner:
```js
// I dag:
function canEdit() { return currentUser() === 'Steen'; }
function canLog()  { return currentUser() === 'Steen' || currentUser() === 'Linda'; }

// Ny:
function currentUserObj() { return users.find(u => u.name === currentUser()); }
function canEdit() { return currentUserObj()?.role === 'admin'; }
function canLog()  { return ['admin','member'].includes(currentUserObj()?.role); }
```

**Trin 3: Lockscreen**

Lockscreen læser fra `users.list` i stedet for hardcodet `{ Steen, Linda, Gæst }`. PIN-validering: find bruger med matchende PIN i listen.

**Trin 4: Brugerstyring UI**

Ny sektion i hamburgermenu (kun admin):
- **"👥 Brugere"** - åbner brugerliste
- Viser alle brugere med navn + rolle + "Rediger"-knap
- **Opret bruger**: navn + PIN + rolle (dropdown). Deaktiveret hvis 5 brugere allerede.
- **Rediger bruger**: skift navn, PIN, rolle. Kan ikke slette sig selv. Kan ikke fjerne sin egen admin-rolle.
- **Slet bruger**: bekræftelse.

**Trin 5: Validering**
- Maks 5 brugere i alt
- Mindst én admin skal altid eksistere
- PIN skal være 4-6 cifre
- Navne skal være unikke

---

**Hvad det ikke løser:**
- Firestore sikkerhedsregler kræver stadig Firebase Auth (se pkt. 2 nedenfor)
- Ingen "glemt PIN"-recovery
- Session er stadig `sessionStorage` - nulstilles ved app-luk

**Estimat:** 3-4 timers arbejde. Alt inden for eksisterende stack.

---

### 2. Firestore sikkerhedsregler (deadline ~24. juni 2026)
Firestore kører i "test mode" - alle kan læse/skrive uden login. Kræver Firebase Authentication for at kunne skrive ordentlige regler. Firebase Auth er et større projekt (2-3 dage) og løses separat fra brugerstyring ovenfor.

### 3. Push-notifikationer på iPhone
Kræver Firebase Cloud Messaging + opdateret service worker.

### 4. Søgefunktion
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

---

## Brugeropsætning

| Bruger | Adgang | PIN |
|--------|--------|-----|
| Steen  | Fuld (canEdit) | Sat |
| Linda  | Log + anbefalinger (canLog) | Sat |
| Gæst   | Læse kun | Sat |

Linda installerer appen: åbn `voreshave.soenderup.dk` i Safari → del-knap → "Føj til hjemmeskærm"
