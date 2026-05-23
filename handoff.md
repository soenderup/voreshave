# Handoff — Vores Have
*Opdateret: 23. maj 2026*

---

## Hvad er lavet

### App og design
- Appen hedder **Vores Have** og er live på `https://voreshave.netlify.app` (og snart `voreshave.soenderup.dk`)
- Design: naturlig og varm (jordfarver, terrakotta, hvide kort) — valgt ud fra 3 forslag
- Mobilvenlig, PWA — installeret på iPhone via Safari → "Føj til hjemmeskærm"

### Struktur
- **Haven → Zoner → Emner** (to niveauer)
- Zoner grupperet i **Forhave / Baghave / Terrasse / Indgange** — accordion, kun ét område åbent ad gangen
- Alle Steens rigtige zoner er oprettet (27 stk): flis-bed, sten-bed, højbede 1-3, dråbebed, flødebolle, sommerfuglebed, altankasser 1-6, krukker, træer, hækker osv.

### Funktioner
- **Opret / rediger / slet** zoner og emner (✏️ i header)
- **Emnefelter:** navn, latinsk navn, type (Træ/Busk/Stauder osv.), plantet dato, note, info-link
- **Foto-upload** per zone og per emne — vælg kamera eller fotoalbum — komprimeres automatisk, vises som thumbnail-strip med lightbox
- **Påmindelser** — engangs eller tilbagevendende (månedlig/årlig) — med "Ansvarlig: Alle / Steen / Linda"
- **Historik** — log per zone og emne — fuldførte påmindelser flyttes automatisk hertil
- **Kalender** — månedsoversigt med farvede prikker, klik på dag for at filtrere, blade mellem måneder
- **Snart / Nu** — urgent strip øverst på forsiden
- **Brugerstyring** — Steen og Linda, PIN-lås (4 cifre), bruger huskes per enhed, historik og påmindelser tagges med navn

### Teknisk
- Rent HTML/CSS/JS — ingen frameworks, ingen build-trin
- Data gemmes i **localStorage** (midlertidigt — erstattes af Firebase)
- Fotos gemmes som base64 i localStorage (~100KB per billede komprimeret)
- **PWA:** manifest.json + service worker (cache-first), grønt ikon, standalone-mode
- GitHub: `github.com/soenderup/voreshave` → auto-deploy til Netlify ved push til `main`
- PIN gemmes i plain text i localStorage (acceptabelt for et have-overblik)

---

## Hvad mangler — i prioriteret rækkefølge

### 1. Firebase (kritisk inden seriøs brug)
Firebase er nødvendigt for to afgørende ting:
- **Firestore** — databasesynkronisering mellem Steens og Lindas telefoner. Lige nu ser de ikke hinandens ændringer.
- **Firebase Storage** — fotos gemmes i skyen i stedet for i browseren. localStorage har ~5MB grænse — med mange fotos vil den gå fuld.

Hvad der skal gøres:
- Opret Firebase-projekt på console.firebase.google.com
- Tilføj Firestore og Storage
- Opret `.env`-fil med Firebase-config (må IKKE committes til GitHub — tilføj til `.gitignore`)
- Erstat localStorage-kald med Firestore-læsning/-skrivning
- Erstat base64-fotos med Firebase Storage upload/URL

### 2. Firebase Authentication (login i stedet for PIN)
- Google Sign-In eller email/password for Steen og Linda
- Erstatter den nuværende PIN-løsning
- Sikrer at kun de to kan tilgå appen

### 3. Push-notifikationer på iPhone
- Kræver Firebase Cloud Messaging (FCM) + opdateret service worker
- Påmindelser med en dato og ansvarlig sender push til den rigtige telefon
- iOS kræver at appen er installeret som PWA på hjemmeskærmen (allerede gjort)

### 4. Auto-forslag til info-links
- Aftalt: appen søger automatisk et link op når man tilføjer et emne
- Kræver et API-kald (f.eks. søgning på plantebasen.dk eller haveselskabet.dk)
- Brugeren kan rette/tilføje bagefter

### 5. Rediger og slet påmindelser og historik
- Man kan i dag kun tilføje — ikke redigere en eksisterende påmindelse
- Historik-noter kan heller ikke rettes eller slettes
- Simpel ✏️-knap per post

---

## Ting der ikke er husket / skal tages stilling til

- **PIN-glemsel** — der er ingen måde at nulstille PIN på hvis den glemmes. Løsning nu: slet localStorage i Safari-indstillinger. Afventer Firebase Auth.
- **Hæk mod nabo** — zonen hedder stadig "Hæk mod nabo" — ret til naborens rigtige navn direkte i appen (✏️-knap)
- **Altankasse 1** er registreret som tom — er det stadig tilfældet?
- **Ingen backup** — data ligger kun i browseren (localStorage). Inden Firebase: eksporter ikke muligt. En enkelt browser-nulstilling sletter alt. Brug appen med omtanke.
- **`scripts/`-mappen** deployes til Netlify men er ufarlig (ingen eksekverbare scripts i browseren)
- **Ikonerne** er simple geometriske blade — kan laves pænere når resten er på plads
- **Synkronisering virker ikke endnu** — Steen og Linda ser hver deres version af appen. Det løses med Firebase (punkt 1 ovenfor)
- **Søgefunktion** — med 27 zoner kan det blive relevant at søge på tværs. Ikke implementeret endnu.

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
│   └── generate-icons.py ← genererer PNG-ikoner
├── CLAUDE.md           ← projektinstruktioner til Claude
└── handoff.md          ← dette dokument
```

**Dev-miljø:** Kør `kode` → vælg `minhave` → server starter automatisk på `http://localhost:8766`, Safari åbner til højre.

**Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID Claude inden push.

**localStorage-nøgle:** `minhave-v3` (bump til v4 hvis seed-data skal nulstilles)
