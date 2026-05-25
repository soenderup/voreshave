# Handoff — Vores Have
*Opdateret: 25. maj 2026 (dag 2 - aften)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.10 på `https://voreshave.soenderup.dk`
- **Alt virker** - anbefalinger-bugget er fundet og fikset i aften
- **Næste session:** ny funktion til planteidentifikation (se nederst)

---

## Aftenens arbejde - anbefalinger-bug FIKSET

**Årsag:** Netlify-funktionens `max_tokens: 2000` var for lavt. Med 30 planter i prompten genererede Claude mere JSON-output end der kunne være i 2000 tokens. JSON-arrayet blev afkortet (4381 tegn ind), og `JSON.parse` fejlede med "Unexpected end of JSON input". Funktionen slugte fejlen og returnerede `{items: []}` - derfor "Tjek for nye gør ingenting".

**Diagnose:** Tilføjede midlertidig `console.log`-debugging gennem hele flowet + `_debug`-felt i Netlify-funktionen der returnerede stage (api-error / no-json-match / json-parse-fail / ok) + stop_reason. På live så vi straks:
```
stage: "json-parse-fail", stopReason: "max_tokens", error: "Unexpected end of JSON input"
```

**Fix:** Hævet `max_tokens` til 8000 i `netlify/functions/recommendations.js`. Claude Haiku 4.5 understøtter op til 8192 output tokens.

**Bonus-forbedringer (beholdt):**
- Null-safe payload-konstruktion i klienten (`db.plants || []` osv.)
- Granulær try/catch omkring JSON.parse i Netlify-funktionen
- Bedre error-logging i Netlify console (uden at lække debug til klient)

**Commits i aften:**
- `800427b` debug: tilføj midlertidig logging til anbefalinger
- `5df8128` debug: returner _debug-info fra recommendations-funktion
- `4a6965b` fix: hæv max_tokens fra 2000 til 8000 i anbefalinger
- `6ced1c4` chore: fjern debug-logs fra anbefalinger

---

## ⚠ Steen skal tjekke i næste session

**Virker anbefalingerne som ønsket?**
- Er rådene relevante for danske haver i de rigtige måneder?
- Er der dubletter med eksisterende påmindelser?
- Er teksten kort og handlingsorienteret nok (maks 60 tegn-grænsen overholdt)?
- Er der nok / for mange anbefalinger pr. element?

Hvis ja → så er anbefalinger-funktionen helt færdig.
Hvis nej → juster prompt i `netlify/functions/recommendations.js`.

---

## 🆕 Idé til ny funktion - planteidentifikation

**Koncept:** "Identificer denne plante/busk/træ" - tag billede → AI identificerer → opret element direkte derfra.

**Skitse:**
1. Ny knap fx på forsiden eller i zone-visningen: 📸 "Identificer plante"
2. Brugeren tager/uploader billede
3. Billedet sendes til Claude (Haiku eller Sonnet med vision)
4. Claude returnerer: navn (dansk), latinsk navn, type (Stauder/Busk/Træ etc.), kort beskrivelse, confidence
5. Brugeren ser forslaget med billede + info
6. Hvis korrekt: ét tryk for at oprette element (med billede, navn, latinsk navn, type pre-udfyldt) - skal kunne vælge zone
7. Hvis forkert: kassér / prøv igen

**Tekniske overvejelser:**
- Ny Netlify function: `netlify/functions/identify-plant.js`
- Brug Claude Sonnet 4.6 (`claude-sonnet-4-6`) for bedre vision - Haiku kan også lave vision men er mindre præcis på arter
- Billede sendes base64-encoded (eller via Anthropic Files API ved store billeder)
- Returner struktureret JSON med felter: `name`, `latinName`, `type`, `confidence` (0-1), `description`, `notRecognized` (boolean)
- Confidence-threshold: hvis < 0.6, vis "Usikker - tjek selv" advarsel
- Pris: vision-kald koster mere end tekst - overvej caching eller brugsstatistik

**UI-flow forslag:**
- Modal/sheet med billede øverst + identifikations-resultat under
- Knapper: "Opret som element" / "Prøv igen med nyt billede" / "Annullér"
- Ved "Opret": dropdown til zone-valg + redigerbare felter (forudfyldt)

**Permissions:** Antagelig kun `canEdit()` (Steen) - kan diskuteres om Linda også skal kunne det.

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

### 1. Steen tjekker anbefalinger giver mening
Se sektion ovenfor.

### 2. Ny funktion: planteidentifikation via foto
Se idé-sektion ovenfor.

### 3. Firestore sikkerhedsregler (deadline ~24. juni 2026)
Firestore kører i "test mode" - alle kan læse/skrive. Kræver Firebase Authentication.

### 4. Firebase Authentication
- Erstatter PIN-systemet på sigt
- Email/password for Steen og Linda

### 5. Rediger/slet påmindelser fra zone/plante-visning
Kun muligt fra kalenderen i dag.

### 6. Push-notifikationer på iPhone
Kræver Firebase Cloud Messaging + opdateret service worker.

### 7. Søgefunktion
Med mange zoner kan det blive relevant.

---

## Ting der skal huskes

- **Firestore test mode udløber ~24. juni 2026** - husk sikkerhedsregler!
- **Firebase plan:** Blaze (Pay-as-you-go)
- **Viden om + Anbefalinger:** Koster øre pr. opslag via Anthropic API (Claude Haiku)
- **Dev-miljø:** `kode` → vælg `minhave` → server på `http://localhost:8766`
- **Lokal server understøtter IKKE POST** - Netlify-funktioner kan kun testes på live (eller via `netlify dev` der ikke er sat op endnu)
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
