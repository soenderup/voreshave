# Handoff — Vores Have
*Opdateret: 25. maj 2026 (nat)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.10 på `https://voreshave.soenderup.dk`
- **Alt virker:** Foto-upload til Firebase Storage, data i Firestore, "Viden om" via Claude AI
- **Firebase:** Nyt projekt på ny standard Gmail-konto (det gamle Google Workspace-problem er løst)
- **Linda:** Kan installere appen og logge ind med sin PIN - alt synkroniserer

---

## Hvad blev lavet i dag (24-25. maj)

### Firebase-skift (nyt projekt)
Det gamle Firebase-projekt (`minhave-e9ab6`) kørte på en Google Workspace/familie-konto som gav 403-fejl på Storage. Løsning: ny standard Gmail-konto → nyt Firebase-projekt (`voreshave-5e7de`).

- Firestore data migreret via `saveDB()` i browser-konsollen
- Firebase Storage virker nu - fotos uploades til skyen og ses på alle enheder
- PINs sat op igen (de lå i separat Firestore-dokument der ikke var med i migreringen)
- Blaze-plan aktiveret på det nye projekt

### UI-ændringer
- **Fast header:** Viser altid "🌿 Vores Have" uanset hvilken side man er på
- **Zone/plante-navn:** Vises i lyst grønt banner i indholdet (ikke i headeren)
- **CSS Grid layout:** Header og bundnavigation sidder fast - kun midten scroller
- **Logo-klik:** Tryk på "🌿 Vores Have" navigerer til forsiden
- **Kalender:** Klik på påmindelser og historik-noter åbner rediger/slet
- **Måneds-navigation:** Sticky i kalenderen ved scroll
- **"Note" → "Egne noter":** Omdøbt i plantevisning

### Viden om (AI-funktion)
- Netlify Function (`netlify/functions/plant-info.js`) kalder Claude Haiku
- Hentes automatisk når en plante åbnes uden `aiInfo` og har latinsk navn
- Genindlæses hvis latinsk navn eller egne noter ændres ved redigering
- API-nøgle gemt som secret i Netlify environment variables (`ANTHROPIC_API_KEY`)
- Ny nøgle oprettet på console.anthropic.com (den gamle fra portrait-projektet virkede ikke)

### Versionering rettet
- Sprang fejlagtigt fra v1.8 til v2.0 i en tidligere session
- Rettet tilbage til v1.x - nu på v1.10
- Service worker cache bumped til `vores-have-v3`

---

## Teknisk overblik

```
voreshave/
├── index.html              ← hele appen (v1.10)
├── manifest.json           ← PWA-manifest
├── sw.js                   ← Service worker (cache: vores-have-v3)
├── netlify.toml            ← Netlify config (Node 18, secrets-scanner slået fra)
├── netlify/functions/
│   └── plant-info.js       ← Claude Haiku - genererer "Viden om" tekst
├── icons/                  ← App-ikoner
├── scripts/                ← Dev-miljø (ikke deployed)
├── CLAUDE.md               ← projektinstruktioner til Claude
└── handoff.md              ← dette dokument
```

**Firebase (nyt projekt: voreshave-5e7de):**
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

**Lokal foto-storage (IndexedDB - fallback):**
```
minhave-photos → photos store
  zone-{id}   ← base64 zonefoto (backup hvis cloud fejler)
  plant-{id}  ← base64 elementfoto
```

---

## Hvad mangler — prioriteret

### 1. Firestore sikkerhedsregler (vigtigt - deadline)
Firestore kører i "test mode" — alle kan læse/skrive i **30 dage fra oprettelse** af det nye projekt (ca. 24. juni 2026). Inden da skal reglerne strammes til kun at tillade kendte brugere. Kræver Firebase Authentication.

### 2. Firebase Authentication
- Erstatter PIN-systemet på sigt
- Email/password for Steen og Linda
- Nødvendigt for at stramme Firestore-regler

### 3. Rediger/slet påmindelser fra zone/plante-visning
- I dag kan man kun redigere/slette fra kalenderen
- Ville give bedre UX at kunne gøre det direkte på zonen/planten

### 4. Push-notifikationer på iPhone
- Kræver Firebase Cloud Messaging + opdateret service worker
- iOS kræver PWA installeret på hjemmeskærmen

### 5. Søgefunktion
- Med 27 zoner kan det blive relevant

---

## Ting der skal huskes

- **Firestore test mode udløber ~24. juni 2026** - husk sikkerhedsregler!
- **Firebase plan:** Blaze (Pay-as-you-go) - betaler kun ved overforbrug
- **Viden om:** Koster øre pr. opslag via Anthropic API (Claude Haiku er billigst)
- **PIN-nulstilling:** Kan sættes igen fra S-menuen af enhver logget ind bruger
- **Dev-miljø:** `kode` → vælg `minhave` → server på `http://localhost:8766`
- **Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID Claude inden push.
- **Cache:** Bump `sw.js` CACHE-konstant + VERSION i `index.html` ved større ændringer

---

## Brugeropsætning

| Bruger | Adgang | PIN |
|--------|--------|-----|
| Steen  | Fuld   | Sat |
| Linda  | Fuld   | Sat |
| Gæst   | Læse   | Sat |

Linda installerer appen: åbn `voreshave.soenderup.dk` i Safari → del-knap → "Føj til hjemmeskærm"
