# Handoff — Vores Have
*Opdateret: 9. juni 2026 (session 16)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.25 på `https://voreshave.soenderup.dk`
- **Seneste:** Huskeliste — personlig samling af elementer (📌 ny 5. fane i bund-nav). Markér på element-siden, find igen i huskeliste-fanen, fjern med ✕. Personlig pr. bruger, synker via Firebase, skjult for gæst
- **Næste:** Cloudflare Workers migration (Netlify koster), se idé-listen

---

## Seneste arbejde (9. juni — session 16)

### Huskeliste

- **Ny 5. fane** 📌 Huskeliste i bund-navigationen (ved siden af Søg) — skjult for gæst (`isGuest()`)
- **Formål:** samle de elementer man vil kigge på (fx når man planlægger indendørs), så man slipper for at lede efter dem i haven
- **Toggle på element-siden** (`renderPlant`, synlig på alle faner, vises for `!isGuest()`): "📌 Føj til huskeliste" ↔ "📌 På huskelisten ✓"
- **Huskeliste-visning** (`renderBookmarks`): genbruger søgeresultat-stilen — foto/navn/zone, klik → element, ✕ fjerner direkte fra listen. Tom state med vejledning
- **Personlig pr. bruger:** gemt som felt `bookmarkedBy` (array af brugernavne) på selve planten → synker via Firestore + localStorage, virker på tværs af enheder. Steen og Linda har hver deres liste (identificeret via `currentUser()` = brugernavn)
- **Ingen migration nødvendig:** `bookmarkedBy === undefined` behandles som tom. Sletning af en plante fjerner den naturligt fra alle huskelister
- Helpers: `isBookmarked(pid)`, `myBookmarks()`, `toggleBookmark(pid)` (nær `canManageUsers`)
- CSS: `.bookmark-toggle` (+`.on`) og `.bookmark-remove`. Bund-nav-knapper komprimeret (font 0.58rem, mindre padding) så 5 ikoner passer
- **Alle rettelser sker fortsat på elementet selv** — huskelisten er kun en samling
- Dokumentation (`dokumentation.html`) opdateret med beskrivelse + dato → juni 2026

---

## Seneste arbejde (9. juni — session 15)

### Opmærksomheds-flag på oversigten

- **To statustilstande** vises nu på forsidens oversigt, og kan optræde samtidig:
  - Gult **⚠️** = overskredet påmindelse (forfalden reminder) — drevet af `plantUrgent(pid)` / `zoneStatus(zid)`
  - Rødt **🚩** = "kræver opmærksomhed" (history-note med `needsAttention`) — drevet af `plantAttentionFlag(pid)` / ny `zoneAttention(zid)`
- Flagene propagerer op gennem hierarkiet: **element → zone → område**, så man kan finde den rette plante uden at bladre alle igennem
- Nye CSS-klasser `.flag-overdue` og `.flag-attention` (rene emoji-spans, ensartet størrelse)
- `directElementCard` (planter der står direkte i et område) brugte tidligere et separat `OK`/`Handling krævet`-tag — **fjernet**. Bruger nu samme flag-sprog som zone-planter: intet når alt er fint, ⚠️/🚩 ved behov
- Dokumentation (`dokumentation.html`) opdateret med beskrivelse af flagene

### Dokumentation: port-fejl rettet

- `dokumentation.html` (AES-256-GCM-krypteret) sagde dev-port **8766** tre steder → rettet til **8081**
- Workflow ved redigering af krypteret doc: dekryptér med nøgle `fFKqvN687VDqCye6kxoD` (PBKDF2 100k iter, SHA-256, salt[0:32]+iv[32:44]+ciphertext+authTag[-16]) → rediger klartekst → genkryptér med frisk salt+iv → erstat `const D = '...'`

---

## Seneste arbejde (juni — session 14)

### Dokumentation krypteret + dev-server oprydning

- `dokumentation.html` konverteret fra adgangskode-overlay til **AES-256-GCM kryptering** — selve indholdet er nu krypteret, ikke bare skjult bag et overlay
- `?key=` query-param giver auto-login (dekrypterer direkte ved åbning med nøgle i URL'en)
- Dev-server ensrettet til fast **port 8081** (jf. global regel)
- No-cache på dev-serveren + automatisk Safari-reload genindført

---

## Seneste arbejde (28. maj — session 13)

### Billedoptimering — thumbnail-upload og lazy loading

- `uploadPhoto()` og `uploadBase64Photo()` uploader nu **to** filer til Firebase Storage:
  - `photos/{id}.jpg` — fuld opløsning (1200px, 0.78 quality)
  - `photos/{id}_thumb.jpg` — thumbnail (150px, 0.7 quality)
- Begge returnerer `{ url, thumbUrl }`
- `p.photoThumb` tilføjet som felt på planter — gemmer thumbnail-URL for primærfoto
- Tidslinje-fotos (`p.photos[i]`) får `thumbUrl` på hvert entry
- Plantelisten (38px) og søgeresultater (36px) bruger nu `p.photoThumb || p.photo`
- `loading="lazy"` tilføjet på liste-thumbnails
- Sletning rydder også thumbnail fra Firebase Storage
- `setPrimaryTimelinePhoto` og `deleteTimelinePhoto` syncer `p.photoThumb` korrekt
- Eksisterende fotos (ingen `photoThumb`) falder automatisk tilbage til fuld URL
- **Gevinst:** Ca. 10-20x mindre data i plantelister (5-15 KB vs 200-500 KB pr. billede)

---

## Seneste arbejde (28. maj — session 12)

### Firebase Anonymous Auth + Firestore sikkerhedsregler

- Firestore kørte i "test mode" — alle kunne læse/skrive uden login
- Firebase Auth SDK tilføjet (`firebase-auth-compat.js`)
- `signInAnonymously()` kaldes ved app-start — usynligt for brugere
- Sikkerhedsregler deployet via Firebase CLI: `allow read, write: if request.auth != null`
- `firestore.rules` og `firebase.json` tilføjet til projektet
- Firebase CLI installeret globalt (`npm install -g firebase-tools`)
- Firebase-konto til Console: `appsstorage081@gmail.com`
- Deploy-kommando: `firebase deploy --only firestore:rules --project voreshave-5e7de`

### Dokumentationsside

- `dokumentation.html` oprettet — komplet projektbeskrivelse med fold-ud sektioner
- Adgangskodebeskyttet via SHA-256-hash hardkodet i filen (ingen setup-flow)
- Tilgængelig på `voreshave.soenderup.dk/dokumentation.html`
- Adgangskode gemt i Steens kodeordsarkiv
- Indeholder: projektbeskrivelse, funktioner, brugere, teknisk arkitektur, Firebase, Netlify, GitHub, Claude API, dev-miljø, problemer, fremtidsplaner, vigtige noter, changelog
- Regel gemt: Claude spørger altid om dokumentationen skal opdateres ved større ændringer

### Diverse

- VERSION rettet til 1.25 (var fejlagtigt stadig 1.23 i koden)
- Billedoptimering tilføjet til idé-listen (loading="lazy" + thumbnail-resize ved upload)

---

## Seneste arbejde (27. maj — session 11)

### Tjek registreringer — mange forbedringer

- **Hæk-check ignorerer nu ghost-zoner** (isDirect) — "Liguster"-advarsler forsvandt
- **Perennial-konflikter** får auto-fix "Ret"-knap der synkroniserer trivseldata med typen
- **AI-forslag** opdaterer nu også `perennial`-feltet ved "Ret"
- **Busk i krukke** fjernet fra advarsler — kun Træ advares (Busk i krukke er helt normalt)
- **Info-items** (tomme zoner) får "Ignorer"-knap der fjerner dem visuelt
- **AI flip-flop fix:** "Ignorer permanent"-knap gemmer plant-id i `db.ignoredAIChecks` — planten flagges aldrig igen
- **Prompt skærpet:** AI instrueres eksplicit om at tvetydige planter (figentræ, lavendel, gummitræ, tomat) er acceptable og ikke må flages

### Nye plantetyper

- `Stauder` omdøbt til `Staude` (ental som alle andre typer)
- `Stueplante` tilføjet — til orkidéer, gummitræer og lignende
- `Krydderurt` tilføjet — til basilikum, timian, rosmarin osv.
- Migration kører automatisk ved app-start: `type === 'Stauder'` → `'Staude'`
- `altidFlerårig`-listen og AI-prompt opdateret med nye typer

### App-ikon (hjemmeskærm)

- Nyt ikon: 🌿 emoji på mørk grøn baggrund med afrundede hjørner
- Genereret via SVG + qlmanage + Pillow (Python)
- `apple-touch-icon` peger nu på `/icons/icon-180-v2.png` (nyt filnavn tvinger iOS til at hente frisk)
- SW cache bumped til v8, `skipWaiting()` tilføjet så ny SW overtager med det samme
- Favicon.svg opdateret tilsvarende

### Plantedato — "Ukendt"

- Dato-felt starter nu tomt (ikke dagens dato) ved oprettelse
- "Ukendt"-checkbox skjuler/rydder dato-feltet — fungerer på iPhone
- Eksisterende planter med dato: checkbox ikke hakket, dato vises
- Eksisterende planter uden dato: checkbox hakket, felt skjult
- Visning: viser "Ukendt" i kursiv når plantedato mangler

### Netlify overforbrug

- Sitet var nede pga. overskredne function-kald (125k/måned gratis)
- Betalt 100 kr. for ekstra kald
- **Overvej Cloudflare Workers** (100k kald/dag gratis) — se huskelisten

---

## Seneste arbejde (27. maj — session 10)

### Svip-navigation mellem planter i samme zone

- Svip venstre = næste plante i zonen, svip højre = forrige (eller tilbage hvis første)
- Pile `‹` og `›` i hero-området flankerer plantenavnet
- Breadcrumb øverst: `‹ Rosenhaven` - klikbar, går altid tilbage til zonen
- Counter: `2 af 5` under plantenavnet
- Planter uden zone uændret (kun ‹ tilbage-knap)
- Swipe-listener registreres kun én gang ved app-start (IIFE) - ikke i `bindEvents()` som kørte ved hvert `render()`
- Ignorerer lodrette bevægelser og korte svip (< 60px)

### Forbedret fejl-log

- `window.onerror` bruger nu 5. parameter (Error-objektet med stack)
- `window.onunhandledrejection` sender stack trace hvis tilgængeligt
- Alle `catch`-blokke sender nu `e` som 4. parameter i stedet for kun `e.message`
- App-kontekst (view, plantId, zoneId) logges per fejl
- UI viser stack trace i scrollbar `<pre>`-boks, 📄 fil:linje, 📍 kontekst, 👤 bruger

### Slet zone - nu tilgængeligt

- **⚙️-ikon** på alle zone-foldout-headers (kun admin) - åbner "Rediger zone" direkte
- **Hamburger ☰** på element-siden viser nu "Rediger zone · [zonenavn]" som kontekst-handling
- Tidligere var `openEditZone()` kun tilgængeligt via "Tjek registreringer" for tomme zoner

### Bugfixes

- **Gem som note (diagnose):** `JSON.stringify` satte dobbelte anførselstegn i onclick-attributten og brød knappen. Fikset ved at gemme `noteText` i `diagnoseState` i stedet.

---

## Seneste arbejde (27. maj — session 9)

### Admin: "Tjek registreringer" (☰-menu, kun admin)
- Ny knap i hamburgermenu: "🔍 Tjek registreringer"
- **Lokal tjek (øjeblikkeligt)** — kører direkte på `db` uden API:
  - 🔴 Forældreløse planter (zoneId peger på ikke-eksisterende zone)
  - 🔴 Forældreløse påmindelser/noter (entityId peger på slettet plante/zone)
  - ⚠️ Stor plante i lille beholder (Træ/Busk i krukke/kasse/højbed)
  - ⚠️ Hæk-plante ikke i hæk-zone
  - ⚠️ Plante i træ-zone der ikke er Træ/Busk
  - ⚠️ Perennial/type-modstrid (Stauder markeret etårig, Etårig markeret flerårig)
  - ℹ️ Mangler type, latinsk navn, trivseldata
  - ℹ️ Dubletter (samme navn i samme zone)
  - ℹ️ Tomme zoner (ingen planter/underzoner)
- **AI-tjek** — kalder `/.netlify/functions/check-plants` (Claude Haiku)
  - Sender alle planter med navn + latinsk navn + type
  - Claude markerer mistænkelige typeregistreringer med begrundelse
  - Foreslår korrekt type
- Ny Netlify-funktion: `netlify/functions/check-plants.js`

### `parseDrainage()` — drainage-normalisering
- Ny hjælpefunktion normaliserer drainage-værdier
- Håndterer: dansk ("velafdrænet", "fugtig", "leret"), forkert casing ("Well-Drained"), underscore ("well_drained"), varianter ("sandet jord")
- Bruges i **rendering** (careIconsHTML) og alle **3 steder der skriver** drainage
- Forhindrer at uventede svar fra Claude-API ødelægger drainage-visningen
- Rettede et problem hvor "Opdater jordbundsdata" ikke persisterede korrekt pga. onSnapshot-race (migrationen virker online)

---

## Seneste arbejde (27. maj — session 8)

### Fejl-log
- Global fejlfangst via `window.onerror` + `window.onunhandledrejection` → Firestore (`voreshave/errorlog`)
- `logError()` tilføjet i alle vigtige catch-blokke: loadDB, loadUsers, loadSettings, vejr, lokationssøgning, foto-upload (zone/element/tidslinje), anbefalinger, identificer, diagnose, fetchPlantInfo, fetchCareData
- Fejl-log UI i ☰ (kun admin): viser fejlbesked, fil:linje, bruger, tidspunkt — nyeste øverst
- 🧪 Test-knap til at verificere at logningen virker
- 🗑️ Tøm log-knap (som login-loggen)
- Max 200 entries i Firestore

### Diagnose ("Hvad fejler den?")
- **Foto-valg:** Fjernet `capture="environment"` → iOS viser nu native picker (Tag foto / Fotoarkiv / Gennemse)
- **iOS fix:** Input-element tilføjes DOM før klik (ellers fyrer `onchange` ikke ved fotoarkiv-valg)
- **Hints-felt:** Efter foto-valg vises sheet med preview + textarea til kontekst
  - Placeholder: "Eks: jorden er meget våd · det var frost i nat · ved siden af står en..."
- **Hint sendes til API** som ekstra kontekst i prompten

### Identificer
- **Prøv igen:** Beholder billede, viser korrektionsfelt i stedet for at nulstille alt
  - Placeholder: "Eks: det er ikke meldug · bladene er runde, ikke spidse"
- **Svar på brugerens tekst:** `response`-felt i JSON — Claude svarer direkte på hint eller korrektion
  - Vises som 💬-boks øverst i resultatkort (kun når bruger har skrevet noget)
- **Links:** 📖 Wikipedia (latinsk navn) + 🔎 Google — vises under resultat
- **Knap-feedback:** "Analysér igen" viser "⏳ Analyserer..." ved klik

### Retry ved Anthropic 529/503
- Alle fire Netlify-funktioner (plant-info, recommendations, identify-plant, diagnose-plant) venter 1 sek og prøver automatisk igen ved 529/503

### Jord-slider (jordbund/dræning)
- Ny care-indikator på elementsiden mellem Lys og Levetid — label: **"Jord"**
- 3 segmenter: `🏜️` velafdrænet ← → `🌊` fugtig/leret
- Værdier: `'well-drained'` / `'normal'` / `'moist'`
- Returneres af `identify-plant.js` og `plant-info.js`
- Migrations-funktion i ☰ → "🔄 Opdater jordbundsdata" — **allerede kørt, alle planter har nu data**
- Migrations-knappen beholdes til genopfriskning — kør altid fra live-sitet, ikke localhost

### Identificer — sycophancy-fix
- Hint behandles nu som "påstand der vurderes mod billedet", ikke kendsgerning der bekræftes
- Claude instrueres til at sige fra hvis hint modsiger det den ser (f.eks. "du skriver blå blomster, men jeg ser røde")

### Burgermenu
- Komprimeret: padding `1rem` → `0.6rem`, ikon `1.5rem` → `1.15rem`, label `1rem` → `0.88rem`

### Påmindelsesbanner
- Maks 5 påmindelser vist
- Header: "Påmindelser (3)" ved ≤5, "Påmindelser (+5)" ved >5
- Link "→ Se alle i kalenderen" vises under de 5 hvis der er flere

---

## Seneste arbejde (26. maj — session 7)

### Login-forbedringer + dev-rettelse

**Husk mig på login:**
- Checkbox "Husk mig på denne enhed" vises under PIN-tasterne
- Korrekt PIN + hak → brugernavn gemmes i `localStorage['voreshave-remember']`
- `checkAccess()` auto-logger ind ved sideindlæsning hvis bruger er husket (ingen lockscreen)
- "Glem denne enhed"-knap i ☰-menuen (vises kun hvis brugeren er husket på enheden)
- Hvis brugeren er slettet ryddes huske-posten automatisk

**Tøm log:**
- "🗑️ Tøm log"-knap i bunden af login-loggen (vises kun når der er poster)
- Bekræftelsesdialog → sletter alle entries i `voreshave/loginlog` i Firestore → opdaterer visningen

**Dev-fix: Safari responsivt design:**
- `dev-start.sh` brugte engelske menunavne ("Develop" / "Enter Responsive Design View")
- Rettet til danske: "Udvikler" / "Start responsiv designfunktion"
- Tilføjet `sleep 0.5` + `activate` inden klik for at undgå timing-fejl

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
  voreshave/errorlog ← fejl-log (max 200 entries)
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
| **~~Billedoptimering~~** | ~~Fuld opløsning bruges som thumbnails (38px) — gem lille thumbnail ved upload (client-side resize). Tilføj også `loading="lazy"` på liste-billeder.~~ | ✓ Bygget (session 13) |

---

## Hvad mangler — prioriteret

### 1. Cloudflare Workers-migration
Netlify-functions overskredet (125k/md gratis, betalt 100 kr.). Flyt: plant-info, recommendations, identify-plant, diagnose-plant, check-plants. Cloudflare Workers giver 100k kald/dag gratis.

### 2. Push-notifikationer på iPhone
Kræver Firebase Cloud Messaging + opdateret service worker. (Kun `messagingSenderId` står i config pt. — intet FCM endnu.)

### ~~Firestore sikkerhedsregler~~ ✓ Løst (session 12)
Anonymous Auth + regler deployet: `allow read, write: if request.auth != null`. `signInAnonymously()` kaldes ved app-start. Ikke længere "test mode".

### ~~Søgefunktion~~ ✓ Bygget (v1.24)
### ~~Vækst-tidslinje~~ ✓ Bygget (v1.25)

---

## Ting der skal huskes

- **Firestore sikkerhedsregler:** Deployet (session 12) — `allow read, write: if request.auth != null` + Anonymous Auth. Ikke længere test mode.
- **Firebase plan:** Blaze (Pay-as-you-go)
- **Viden om + Anbefalinger + Identificer:** Koster øre pr. opslag via Anthropic API
- **Dev-miljø:** `kode` → vælg `VoresHave` → server på `http://localhost:8081` — Safari åbner automatisk og placeres i højre 33% (Terminal i venstre 67%) via System Events
- **Safari auto-reload:** Deaktiveret — tryk Cmd+R manuelt når index.html ændres
- **Lokal server understøtter IKKE POST** - Netlify-funktioner testes kun på live
- **Jord-migration:** Kør altid fra **live-sitet** (ikke localhost). Migrations-knappen kan beholdes til genopfriskning
- **parseDrainage():** Normaliserer drainage-værdier mod dansk/forkert casing — bruges i rendering + alle skrivepunkter
- **Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID inden push
- **PWA cache:** SW bruger network-first for HTML — luk og genåbn app for at få seneste version
- **Cache-bump:** Kun nødvendigt når `SHELL`-listen i `sw.js` ændres (nye ikoner e.l.)
- **VERSION:** Kun ved større funktionsændringer
- **Vejr-widget:** Henter fra Open-Meteo (gratis). Cache 1 time i localStorage. Kræver admin sætter lokation via ☰ → Vejr & lokation. Viser placeholder hvis API er nede.
- **Netlify gratis-plan:** 125.000 function-kald/måned - vi har overskredet det. Overvej at flytte til **Cloudflare Workers** (100.000 kald/dag gratis). Funktionerne der skal flyttes: plant-info, recommendations, identify-plant, diagnose-plant, check-plants
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
