# Handoff — Vores Have
*Opdateret: 26. maj 2026 (session 6)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.25 + UI-rettelser på `https://voreshave.soenderup.dk`
- **Seneste:** Vækst-tidslinje + accordion-zoner + UI-polish
- **Næste:** Se idé-listen og prioriteringslisten nedenfor

---

## Seneste arbejde (26. maj — session 6)

### UI-rettelser (ingen versionsbump)

- **Pile i bannere:** `▾` skiftet til `▼` i orange påmindelses- og opmærksomhedsbannere — alle pile nu `0.85rem` og visuelt ens
- **Accordion-zoner:** Kun én zone åben ad gangen pr. område - åbner man en, lukkes de andre automatisk
- **Scroll til top:** Elementside starter altid fra toppen (ikke midtsiden fra forrige scroll-position)
- **Zoner kollapset ved område-skift:** Åbner man BAGHAVE fra FORHAVE er alle zoner foldet ind fra start

---

## Seneste arbejde (26. maj — session 5)

### Vækst-tidslinje (v1.25)

**Ny funktion:**
- 📸 Foto-strip på element-detalje (info-tab) med vandret scroll
- Op til 15 fotos pr. plante - tæller vises (1/15)
- Thumbnails sorteres ældst-til-nyest (vækst læses venstre → højre)
- Dato vises under hvert thumbnail
- Primær-foto markeres med grøn kant + "✓ primær"-badge
- Tryk på thumbnail → sheet med preview, "Vis i fuld størrelse", "Sæt som primær", "Slet"
- Lightbox med ‹ › pil-navigation, dato + tæller (1/2), knapper til primær/slet
- `+` knap tilføjer nyt foto (skjules automatisk ved 15 fotos)
- **Bagudkompatibel migration:** eksisterende `plant.photo` → `photos[0]` automatisk ved første load
- `plant.photo` synkes altid til det aktuelle primære foto (bruges stadig i kortvisning)

**Teknisk:**
- Ny datastruktur: `plant.photos = [{id, url, date, primary}]`
- Migration kører i `mergeLocalPhotos()` — sker automatisk ved første åbning
- Lightbox understøtter nu både enkelt-foto (zoner/andet) og tidslinje-navigation

---

## Seneste arbejde (26. maj — session 4)

### Søgefunktion (v1.24)

**Ny funktion:**
- 🔍 Søg som 4. fane i bottom-nav
- Live-søgning mens man skriver (ingen Enter nødvendig)
- Søger i plantenavne, latinnavne, beskrivelser og zonenavne
- Resultater grupperes i "Planter" og "Zoner" med antal
- Klik på plante-resultat → navigerer direkte til planten
- Klik på zone-resultat → navigerer til Haven og folder zonen ud
- Clear-knap (✕) vises når der er tekst i feltet
- Tom state og "ingen resultater"-state med emoji

### Safari-vindue placeres automatisk

Safari positioneres nu i højre 33% ved sessionstart via `System Events` (accessibility API) — tidligere åbnede den bare uden positionering.

### Forfaldne påmindelser ryddet

Alle påmindelser med overskredet dato er slettet fra Firestore via konsol.

---

## Seneste arbejde (26. maj — session 3)

### AI-plantediagnose: "Hvad fejler den?" (v1.23)

**Ny funktion:**
- Knap "🔍 Hvad fejler den?" på element-siden (info-tab), under "Viden om"
- Vises kun for admin og member (ikke gæst)
- Tryk → fil-picker åbner (kamera/bibliotek) → foto analyseres af Claude Sonnet vision
- Resultat vises i sheet: diagnose, symptombeskrivelse, behandling og disclaimer
- "Gem som note" gemmer diagnosen som historik-entry på planten

**Ny Netlify-funktion:** `netlify/functions/diagnose-plant.js`
- Samme mønster som `identify-plant.js` (base64 → Claude Sonnet 4.6 vision → JSON)
- Input: `{imageBase64, plantName, latinName}`
- Output: `{diagnosis, symptoms, treatment, disclaimer}` eller `{notRecognized: true}`

### Dev-miljø: Safari-crash fjernet

**Problem:** AppleScript-styring af Safari crashede konsekvent ved hver session.
- `dev-start.sh` brugte `close every window` + `make new document` + `set bounds` → crash
- `dev-stop.sh` brugte samme mønster til at nulstille vinduesstørrelse → crash
- `dev-reload.sh` sendte keystrokes (`Cmd+Option+E`, `Cmd+Option+R`) til Safari → crash

**Løsning:**
- Al direkte AppleScript på Safari fjernet fra alle tre scripts
- `dev-start.sh` åbner Safari med `open -a Safari`, venter 1.5 sek., placerer derefter vinduet via `System Events` (accessibility API) — højre 33%
- `dev-stop.sh` rører ikke Safari overhovedet
- `dev-reload.sh` printer kun en besked i terminalen — tryk Cmd+R manuelt

---

## Seneste arbejde (26. maj — forrige session)

### UI-polish: header, navigation og forsiden

**Header venstrestillet:**
- Logo + "Vores Have" er nu venstrestillet i stedet for centreret
- Flugter visuelt med indholdet nedenunder (PÅMINDELSER-linjen)
- Tilbage-knap (`‹`) er fjernet fra headeren

**Tilbage-knap flyttet til detail-hero:**
- `‹` sidder nu i det lysegrønne `detail-hero`-område foran element-titlen
- Element-titlen flugter præcist med "Vores Have" i headeren (pixel-målt og justeret)
- Latin-navn indrykket tilsvarende

**Zoner starter foldet ind:**
- Alle zone-kort er collapsed som standard ved sideindlæsning
- Implementeret via `collapsedZones` Set + `zonesInitialized`-flag i `mergeLocalPhotos()`
- Live-opdateringer fra Firestore (onSnapshot) nulstiller ikke brugerens åbne/lukkede valg

**Fjernet zone/element-tæller fra forsiden:**
- Teksten "X zoner · Y elementer" er fjernet fra område-headers (FORHAVE, BAGHAVE etc.)
- Behold kun ⚠️-ikonet — det giver reel information

---

## Vejrudsigt widget (v1.22)

**Placering:** Lige under den orange påmindelseslinje på forsiden.

**Opførsel:**
- **Lukket:** Én kompakt linje (samme højde som orange banner): `⛅ 21° (13°) 💧 30% 💨 5 m/s SV ▼`
- **Åben:** Klik folder ud til "Nu + 4 dage"-visning med blå gradient, stor aktuel temp + 4-dages grid
- **Placeholder:** Vises som `🌡️ [stednavn] — henter vejr...` hvis API er nede eller data endnu ikke cachet

**Datakilde:** [Open-Meteo](https://open-meteo.com) — gratis, ingen API-nøgle, direkte browser-fetch
- Geocoding: `https://geocoding-api.open-meteo.com/v1/search`
- Vejr: `https://api.open-meteo.com/v1/forecast` — daily weathercode, max/min temp, nedbørsprocent, vindstyrke/-retning
- Cache: `localStorage['voreshave-weather']` — max 1 time, invalideres ved lokationsskift

**Admin-opsætning:** ☰ → "📍 Vejr & lokation" (kun admin)
- Søg på bynavn → geocoder → vælg fra liste → gemmes i `voreshave/settings` i Firestore
- Viser nuværende lokation under søgefeltet

**Ny Firestore-reference:** `voreshave/settings`
- Struktur: `{ location: { lat, lon, name, displayName } }`

**Ny localStorage-nøgle:** `voreshave-weather`
- Struktur: `{ timestamp, lat, lon, data: {current_weather, daily: {...}} }`

**Ny localStorage-nøgle:** `voreshave-settings`
- Backup-cache af Firestore settings

---

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
├── index.html              ← hele appen (v1.25)
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
  voreshave/data     ← al havedata (zones, plants, reminders, history)
  voreshave/pins     ← gammel PIN-struktur (beholdes til migration, rør ikke)
  voreshave/users    ← brugerstruktur med roller (oprettet automatisk v1.21)
  voreshave/loginlog ← login-historik
  voreshave/settings ← app-indstillinger inkl. vejr-lokation (oprettet v1.22)

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

## Idéer til fremtidige funktioner

Brainstormet 26. maj — ingen rækkefølge, ingen deadline:

| Idé | Beskrivelse | Sværhed |
|-----|-------------|---------|
| **"Hvad kan jeg plante nu?"** | AI foreslår hvad der er sæson til baseret på dato og måned | Lille |
| **Ønskeliste / frøbank** | Simpel liste over planter man vil købe eller frø man har liggende | Lille |
| **Samliv-guide** | Vælg en plante → AI svarer hvad den trives/ikke trives med som nabo | Mellem |
| **Havens årskalender** | Månedsoversigt: hvad blomstrer, høstes, beskæres hvornår — genereret pr. plante | Mellem |
| **Vækst-tidslinje** | ~~Se fotos over tid pr. plante~~ | ✓ Bygget (v1.25) |
| **Havens årsberetning** | Dashboard: antal planter, noter logget, årets plante — mest for hyggens skyld | Stor |

---

## Hvad mangler — prioriteret

### 1. Firestore sikkerhedsregler (deadline ~24. juni 2026)
Firestore kører i "test mode" - alle kan læse/skrive uden login. Kræver Firebase Authentication for at kunne skrive ordentlige regler. Firebase Auth er et større projekt (2-3 dage) og løses separat fra brugerstyring.

### 2. Push-notifikationer på iPhone
Kræver Firebase Cloud Messaging + opdateret service worker.

### 3. ~~Søgefunktion~~ ✓ Bygget (v1.24)
### 4. ~~Vækst-tidslinje~~ ✓ Bygget (v1.25)

---

## Ting der skal huskes

- **Firestore test mode udløber ~24. juni 2026** - husk sikkerhedsregler!
- **Firebase plan:** Blaze (Pay-as-you-go)
- **Viden om + Anbefalinger + Identificer:** Koster øre pr. opslag via Anthropic API
- **Dev-miljø:** `kode` → vælg `VoresHave` → server på `http://localhost:8766` — Safari åbner automatisk og placeres i højre 33% (Terminal i venstre 67%) via System Events
- **Safari auto-reload:** Deaktiveret — tryk Cmd+R manuelt når index.html ændres
- **Lokal server understøtter IKKE POST** - Netlify-funktioner testes kun på live
- **Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID inden push
- **PWA cache:** SW bruger network-first for HTML — luk og genåbn app for at få seneste version
- **Cache-bump:** Kun nødvendigt når `SHELL`-listen i `sw.js` ændres (nye ikoner e.l.)
- **VERSION:** Kun ved større funktionsændringer
- **Vejr-widget:** Henter fra Open-Meteo (gratis). Cache 1 time i localStorage. Kræver admin sætter lokation via ☰ → Vejr & lokation. Viser placeholder hvis API er nede.
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
