# Handoff — Vores Have
*Opdateret: 23. maj 2026*

---

## Hvad er lavet

### App og design
- Appen hedder **Vores Have** og er live på `https://voreshave.netlify.app`
- Design: naturlig og varm (jordfarver, terrakotta, hvide kort)
- Mobilvenlig, PWA — installeret på iPhone via Safari → "Føj til hjemmeskærm"

### Struktur
- **Haven → Zoner → Elementer** (to niveauer — "emne" er omdøbt til "element")
- Zoner grupperet i **Forhave / Baghave / Terrasse / Indgange** — accordion, kun ét område åbent ad gangen
- Alle Steens rigtige zoner er oprettet (27 stk)

### Funktioner
- **Opret / rediger / slet** zoner og elementer (✏️ i header)
- **Elementfelter:** navn, latinsk navn, type (Træ/Busk/Stauder osv.), plantet dato, note, info-link
- **Foto per zone** — ét coverfoto vist stort i det grønne hero-område øverst. Tryk for at tilføje/skifte, × for at slette
- **Foto per element** — ét thumbnail vist i zonens elementliste. Kamerasymbol hvis intet foto. Tryk thumbnail → lightbox. Tilføj/slet fra elementets detaljeside
- **Påmindelser** — engangs eller tilbagevendende (månedlig/årlig) — med "Ansvarlig: Alle / Steen / Linda"
- **Historik** — log per zone og element — fuldførte påmindelser flyttes automatisk hertil
- **Kalender** — månedsoversigt med farvede prikker, klik på dag for at filtrere
- **Snart / Nu** — urgent strip øverst på forsiden
- **Brugerstyring** — Steen, Linda og Gæst med individuelle 6-cifrede PIN-koder

### PIN-system (redesignet)
- Steen, Linda og Gæst har **hver sin 6-cifrede PIN**
- PIN bestemmer hvem man er — ingen separat navnevælger
- PINs gemmes i **Firestore** (`voreshave/pins`) og caches i localStorage
- Virker på alle enheder inkl. fremmede
- **Gæst-PIN** giver read-only adgang (ingen tilføj/rediger/slet)
- Sæt/skift PINs via S-knappen i headeren → brugermenuen
- Første gang: "Hvem er du?" → vælg navn → indtast PIN to gange

### Firebase-integration
- **Firestore** (`voreshave/data`) — al havedata synkroniseres i realtid mellem Steen og Lindas telefoner
- **Firebase Storage** — fotos uploades til skyen, gemmes som URL (ikke base64)
- Fotos vises øjeblikkeligt som preview (base64), uploades til Storage i baggrunden
- **localStorage** bruges som offline-cache for både data og PINs
- Firebase projekt: `minhave-e9ab6` (Blaze-plan — betaling påkrævet for Storage)

### Teknisk
- Rent HTML/CSS/JS — ingen frameworks, ingen build-trin
- Firebase SDK 10.12.0 via CDN (compat-version)
- **localStorage-nøgle:** `minhave-v3` (data-cache), `minhave-pins` (PIN-cache)
- GitHub: `github.com/soenderup/voreshave` → auto-deploy til Netlify ved push til `main`
- PWA: manifest.json + service worker

---

## Hvad mangler — i prioriteret rækkefølge

### 1. Firestore sikkerhedsregler (kritisk inden deling)
Firestore kører i "test mode" — alle kan læse/skrive i 30 dage fra oprettelse.
Inden appen deles bredt skal reglerne strammes:
```
allow read, write: if request.auth != null;
```
Kræver Firebase Authentication (punkt 2).

### 2. Firebase Authentication
- Google Sign-In eller email/password for Steen og Linda
- Erstatter PIN-løsningen helt på sigt
- Sikrer at kun autoriserede kan tilgå og skrive data

### 3. Push-notifikationer på iPhone
- Kræver Firebase Cloud Messaging (FCM) + opdateret service worker
- Påmindelser med dato og ansvarlig sender push til den rigtige telefon
- iOS kræver PWA installeret på hjemmeskærmen (allerede gjort)

### 4. Rediger og slet påmindelser og historik
- Man kan i dag kun tilføje — ikke redigere en eksisterende påmindelse
- Historik-noter kan heller ikke rettes eller slettes
- Simpel ✏️-knap per post

### 5. Auto-forslag til info-links
- Appen søger automatisk et link op når man tilføjer et element
- Kræver et API-kald (f.eks. plantebasen.dk eller haveselskabet.dk)

### 6. Søgefunktion
- Med 27 zoner kan det blive relevant at søge på tværs

---

## Ting der skal huskes

- **Firestore test mode udløber** ~30 dage efter projektoprettelse — husk at opdatere sikkerhedsreglerne
- **Firebase Blaze-plan** er aktiveret — Storage koster penge over gratis-kvoten (5GB gratis, urealistisk at overskride til have-brug)
- **PIN-nulstilling:** Hvis en PIN glemmes, kan den sættes igen fra brugermenuen af den anden bruger (Steen kan sætte Lindas PIN og omvendt)
- **Offline:** Appen fungerer offline med cached data — ændringer synkroniseres når forbindelsen genoprettes
- **Hæk mod nabo** — zonen kan omdøbes direkte i appen (✏️-knap)

---

## Teknisk overblik (til næste session)

```
voreshave/
├── index.html          ← hele appen (HTML + CSS + JS i én fil)
├── manifest.json       ← PWA-manifest
├── sw.js               ← Service worker (cache)
├── icons/              ← App-ikoner (180, 192, 512px)
├── scripts/
│   ├── dev-start.sh    ← starter server + Safari ved sessionstart
│   ├── dev-stop.sh     ← rydder op ved afslutning
│   ├── dev-reload.sh   ← auto-reload Safari ved fil-ændring
│   └── generate-icons.py
├── CLAUDE.md           ← projektinstruktioner til Claude
└── handoff.md          ← dette dokument
```

**Firebase-struktur:**
```
Firestore:
  voreshave/data    ← al havedata (zones, plants, reminders, history)
  voreshave/pins    ← PIN-koder (Steen, Linda, Gæst)

Storage:
  photos/{uuid}.jpg ← uploadede fotos
```

**Dev-miljø:** `kode` → vælg `minhave` → server på `http://localhost:8766`, Safari åbner til højre.

**Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID Claude inden push.
