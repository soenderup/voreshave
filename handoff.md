# Handoff — Vores Have
*Opdateret: 25. maj 2026 (dag 2 - sen aften)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.12 på `https://voreshave.soenderup.dk`
- **Alt virker** - anbefalinger per plante fungerer
- **Næste session:** planteidentifikation via foto (se nederst)

---

## Dagens arbejde

### Anbefalinger redesignet (v1.10 → v1.12)

**Hvad vi byggede:**
- Fjernet central "Anbefalinger"-fane i bunden
- På hvert element (plante/zone) → Påmindelser-fanen → knap: **"💡 Søg anbefalinger"**
- Åbner sheet med 3-4 beskrivende forslag på naturligt dansk
- Hvert forslag viser tekst + måneder + **"+ Tilføj til kalender"**-knap
- **"↺ Søg igen"** for nye forslag til samme plante
- Rediger-knap (✏️) på alle eksisterende påmindelser

**Netlify-funktion (`recommendations.js`) omskrevet:**
- Tager én plante ad gangen (ikke alle på én gang)
- `max_tokens: 400` → færdig på under 3 sek (ingen timeout)
- Prompt på naturligt dansk med eksempler på godt/dårligt sprog
- Post-processing erstatter "dødblom" → "fjern visne blomster" osv.

**Problemer vi løste undervejs:**
- 504 timeout: global fetch med alle planter tog >10 sek (Netlify gratis-plan: 10 sek max)
- Ugyldig `timeout = 26` i netlify.toml blokerede deploy - fjernet
- Cache-bump (VERSION + sw.js CACHE) glemtes flere gange - nu husket

---

## ⚠ Steen skal tjekke

- Virker "💡 Søg anbefalinger" som forventet?
- Er teksten beskrivende nok? Er sproget naturligt?
- Fungerer "✏️ rediger"-knap på påmindelser?

---

## 🆕 Næste funktion - planteidentifikation via foto

**Koncept:** Tag billede → AI identificerer plante → opret element direkte

**Skitse:**
1. Knap fx på zone-siden: 📸 "Identificer plante"
2. Brugeren tager/uploader billede
3. Billedet sendes til Claude Sonnet 4.6 (vision)
4. Claude returnerer: dansk navn, latinsk navn, type, beskrivelse, confidence
5. Brugeren ser forslaget + billede
6. Ét tryk → opret element med data pre-udfyldt (vælg zone)
7. Hvis forkert → kassér / prøv igen

**Teknisk:**
- Ny Netlify function: `netlify/functions/identify-plant.js`
- Model: `claude-sonnet-4-6` (bedre vision end Haiku)
- Billede sendes base64-encoded
- Returner: `{ name, latinName, type, confidence, description, notRecognized }`
- Confidence < 0.6 → vis "Usikker - tjek selv"
- Permissions: kun `canEdit()` (Steen)

---

## Teknisk overblik

```
voreshave/
├── index.html              ← hele appen (v1.12)
├── manifest.json           ← PWA-manifest
├── sw.js                   ← Service worker (cache: vores-have-v5)
├── netlify.toml            ← Netlify config (Node 18, secrets-scanner slået fra)
├── netlify/functions/
│   ├── plant-info.js       ← Claude Haiku - genererer "Viden om" tekst
│   └── recommendations.js  ← Claude Haiku - per-plante anbefalinger
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

---

## Hvad mangler — prioriteret

### 1. Ny funktion: planteidentifikation via foto
Se idé-sektion ovenfor.

### 2. Firestore sikkerhedsregler (deadline ~24. juni 2026)
Firestore kører i "test mode" - alle kan læse/skrive. Kræver Firebase Authentication.

### 3. Firebase Authentication
- Erstatter PIN-systemet på sigt
- Email/password for Steen og Linda

### 4. Push-notifikationer på iPhone
Kræver Firebase Cloud Messaging + opdateret service worker.

### 5. Søgefunktion
Med mange zoner kan det blive relevant.

---

## Ting der skal huskes

- **Firestore test mode udløber ~24. juni 2026** - husk sikkerhedsregler!
- **Firebase plan:** Blaze (Pay-as-you-go)
- **Viden om + Anbefalinger:** Koster øre pr. opslag via Anthropic API (Claude Haiku)
- **Dev-miljø:** `kode` → vælg `minhave` → server på `http://localhost:8766`
- **Lokal server understøtter IKKE POST** - Netlify-funktioner testes kun på live
- **Deploy:** `git push` → GitHub → Netlify auto-deploy. Spørg ALTID inden push
- **Cache:** Bump `sw.js` CACHE-konstant + VERSION i `index.html` ved HVER ændring der går live
- **Netlify gratis-plan:** 10 sekunders timeout på functions - hold kald små

---

## Brugeropsætning

| Bruger | Adgang | PIN |
|--------|--------|-----|
| Steen  | Fuld (canEdit) | Sat |
| Linda  | Log + anbefalinger (canLog) | Sat |
| Gæst   | Læse kun | Sat |

Linda installerer appen: åbn `voreshave.soenderup.dk` i Safari → del-knap → "Føj til hjemmeskærm"
