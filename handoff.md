# Handoff — Vores Have
*Opdateret: 23. maj 2026 (aften)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v2.6 på `https://voreshave.netlify.app`
- **Foto-persistens VIRKER på Steens iPhone** via IndexedDB - overlever reload, deployment, app-genstart
- **Fotos synker IKKE til Linda endnu** - de ligger kun lokalt på Steens enhed
- **Cloud-billedlager er stadig uafklaret** - se "Hvad blev opdaget i dag" nedenfor

## Hvad blev opdaget i dag (23. maj)

### Foto-mysteriet løst (delvist)
Fotos forsvandt hver gang en ny version blev pushet. Grundårsagen viste sig at være:
1. Firebase Storage-uploaden fejlede stille (silent fejl) - se næste punkt
2. saveDB() blev kun kaldt med URL'en fra Storage. Hvis Storage fejlede, blev intet gemt
3. Photo lå kun i hukommelsen og forsvandt ved reload
4. Forsøg på at gemme base64 i localStorage som backup fejlede på iOS Safari pga. kvote-grænser

**Endelig løsning (v2.6):** IndexedDB. Robust på iOS Safari (50MB+ kvote), pålideligt. Fotos er nu gemt under nøgler som `zone-{id}` og `plant-{id}` i en IndexedDB-database kaldet `minhave-photos`. `photoCache` (en in-memory Map) loades ved opstart, og `mergeLocalPhotos()` flikker fotos ind i db-objektet ved hver opdatering fra Firestore.

### Firebase Storage-bombe
**handoff.md sagde tidligere at Blaze-planen var aktiveret. Det var FORKERT.** Projektet kørte på Spark-planen (gratis), hvor Storage slet ikke er tilgængeligt. Det er årsagen til at uploads har fejlet hele tiden - Storage findes simpelthen ikke.

Steen opgraderede til Blaze i dag (Pay-as-you-go, eksisterende "Firebase Payment"-konto blev tilknyttet). Men da vi prøvede at oprette Storage-bucket bagefter, fik vi **403 Forbidden** i konsollen, selv efter 30 minutters ventetid. Det er enten:
- Blaze-billing-propagering der tager længere tid (kan tage timer)
- Cloud Storage API skal aktiveres manuelt i Google Cloud Console
- Anden Google-bøvl

### Vurderede alternativer til Firebase Storage
- **Supabase** (1 GB foto, 500 MB DB, 5 GB trafik gratis, ingen kreditkort) - MEN: projektet pauser efter en uges inaktivitet og kræver manuel klik på supabase.com for at reaktivere. Reel ulempe.
- **Cloudinary** (25 GB foto gratis, direkte browser-upload) - kun til billeder. Vi beholder Firestore til data.
- **Cloudflare** (Pages + D1 + R2, alt samlet, ingen pause) - kræver mest omskrivning.
- **Bliv på IndexedDB** - virker for Steen alene, Linda ser ikke fotos.

## Hvad der skal afklares næste session

1. **Prøv Firebase Storage igen i morgen** - Blaze-propagering har måske endelig sat sig. Hvis ja: vi sætter Storage-regler op (test mode → senere mere restriktive), og fotos uploades til skyen. Linda kan så også se dem.

2. **Hvis Firebase Storage stadig fejler:** beslutning skal tages mellem:
   - Cloudinary (kun fotos, ingen Google, ingen pause)
   - Supabase (alt nyt, pause-irritation)
   - Cloudflare (alt nyt, mere arbejde, men mest samlet)
   - Steen er meget træt af Google-bureaukrati. Cloudinary er det letteste skift.

3. **Migration fra IndexedDB:** Når cloud-storage virker, skal Steens nuværende fotos i IndexedDB uploades til skyen og URL'en gemmes i Firestore. Engangsoperation - kan klares med en lille "migrer fotos"-knap i appen.

## Tekniske ændringer i dag (v1.8 → v2.6)

- **v1.9-v2.2:** Forsøg på saveDB-rækkefølge og base64-fallback i Firestore - flere regressioner
- **v2.3-v2.4:** localStorage-baseret foto-backup - fejlede på iOS Safari
- **v2.5:** Skift til IndexedDB - virkede
- **v2.6:** Test af deployment-overlevelse - bestået

Vigtige kodeændringer (alle i `index.html`):
- Tilføjet `photoCache`, `openPhotoDB()`, `loadPhotoCache()`, `savePhotoToIDB()`, `deletePhotoFromIDB()` (linje ~512+)
- `mergeLocalPhotos()` bruger nu `photoCache` i stedet for `localStorage`
- `doPickZonePhoto` og `doPickElementPhoto`: gemmer i IndexedDB via `savePhotoToIDB`
- `deleteZonePhoto` og `deleteElementPhoto`: sletter fra IndexedDB
- `saveDB()` pakket i try/catch så localStorage-fejl ikke crasher flowet
- Boot-sekvens: `loadPhotoCache()` køres før `loadDB()` så cache er klar

---

## Hvad er lavet (samlet)

### App og design
- Appen hedder **Vores Have** og er live på `https://voreshave.netlify.app`
- Design: naturlig og varm (jordfarver, terrakotta, hvide kort)
- Mobilvenlig, PWA — installeret på iPhone via Safari → "Føj til hjemmeskærm"

### Struktur
- **Haven → Zoner → Elementer** (to niveauer)
- Zoner grupperet i **Forhave / Baghave / Terrasse / Indgange** — accordion, kun ét område åbent ad gangen
- Alle Steens rigtige zoner er oprettet (27 stk)

### Funktioner
- **Opret / rediger / slet** zoner og elementer (✏️ i header)
- **Elementfelter:** navn, latinsk navn, type, plantet dato, note, info-link
- **Foto per zone** — ét coverfoto. Tryk for tilføj/skift, × for slet
- **Foto per element** — thumbnail i listen, lightbox ved tryk
- **Påmindelser** — engangs eller tilbagevendende — med "Ansvarlig: Alle / Steen / Linda"
- **Historik** — log per zone og element — fuldførte påmindelser flyttes automatisk hertil
- **Kalender** — månedsoversigt med farvede prikker
- **Snart / Nu** — urgent strip øverst på forsiden
- **Brugerstyring** — Steen, Linda og Gæst med individuelle 6-cifrede PIN-koder

### Foto-persistens (nyt 23. maj)
- **Lokal**: IndexedDB (`minhave-photos` database, `photos` object store)
- **Sky**: Firebase Storage skal aktiveres - venter på Blaze-propagering
- **Synk**: Endnu ikke - kun lokal Steen pt.

### PIN-system
- Steen, Linda og Gæst har hver sin 6-cifrede PIN
- PINs gemmes i Firestore (`voreshave/pins`) og caches i localStorage
- Gæst-PIN giver read-only adgang
- Sæt/skift PINs via S-knappen i headeren

### Firebase-integration
- **Firestore** (`voreshave/data`) — al havedata synkroniseres mellem enheder
- **Firebase Storage** — IKKE i drift endnu (Blaze nu aktiveret, men bucket-oprettelse fejler med 403)
- Firebase projekt: `minhave-e9ab6`, plan: **Blaze (Pay-as-you-go)** siden 23. maj

### Teknisk
- Rent HTML/CSS/JS — ingen frameworks
- Firebase SDK 10.12.0 via CDN (compat-version)
- localStorage-nøgler: `minhave-v3` (data-cache), `minhave-pins` (PIN-cache)
- IndexedDB: `minhave-photos` database med `photos` store
- GitHub: `github.com/soenderup/voreshave` → auto-deploy til Netlify
- PWA: manifest.json + service worker

---

## Hvad mangler — i prioriteret rækkefølge

### 1. Sky-billedlager (kritisk - blokerer foto-deling med Linda)
Beslut hvad der skal bruges:
- Firebase Storage (hvis det virker i morgen efter Blaze-propagering)
- Cloudinary (hvis Firebase fortsat fejler)
- Supabase eller Cloudflare som større skifte

### 2. Firestore sikkerhedsregler
Firestore kører i "test mode" — alle kan læse/skrive i 30 dage fra oprettelse.
Inden appen deles bredt skal reglerne strammes. Kræver Firebase Authentication (punkt 3).

### 3. Firebase Authentication
- Google Sign-In eller email/password for Steen og Linda
- Erstatter PIN-løsningen helt på sigt

### 4. Push-notifikationer på iPhone
- Kræver Firebase Cloud Messaging (FCM) + opdateret service worker
- iOS kræver PWA installeret på hjemmeskærmen

### 5. Rediger og slet påmindelser og historik
- Man kan i dag kun tilføje — ikke redigere

### 6. Auto-forslag til info-links
- Kræver et API-kald (f.eks. plantebasen.dk)

### 7. Søgefunktion
- Med 27 zoner kan det blive relevant

---

## Ting der skal huskes

- **Firebase plan**: Blaze (Pay-as-you-go) siden 23. maj 2026. "Firebase Payment"-billingkonto er tilknyttet. Du betaler kun ved overforbrug.
- **Firestore test mode udløber** ~30 dage efter oprettelse — husk at opdatere sikkerhedsreglerne
- **PIN-nulstilling:** Hvis en PIN glemmes, kan den sættes igen fra brugermenuen af den anden bruger
- **Offline:** Appen fungerer offline med cached data
- **Hvis foto-flytning til sky lykkes:** kør migrering af Steens IndexedDB-fotos op i skyen

---

## Teknisk overblik

```
voreshave/
├── index.html          ← hele appen
├── manifest.json       ← PWA-manifest
├── sw.js               ← Service worker (cache)
├── icons/              ← App-ikoner
├── scripts/            ← Dev-miljø
├── CLAUDE.md           ← projektinstruktioner til Claude
└── handoff.md          ← dette dokument
```

**Firebase-struktur:**
```
Firestore:
  voreshave/data    ← al havedata (zones, plants, reminders, history)
  voreshave/pins    ← PIN-koder

Storage:
  photos/{uuid}.jpg ← (KOMMER - mangler bucket)
```

**Lokal foto-storage (IndexedDB):**
```
minhave-photos (database)
  photos (object store)
    zone-{id}  ← base64 zonefoto
    plant-{id} ← base64 elementfoto
```

**Dev-miljø:** `kode` → vælg `minhave` → server på `http://localhost:8766`

**Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID Claude inden push.
