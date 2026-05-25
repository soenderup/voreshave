# Handoff — Vores Have
*Opdateret: 25. maj 2026 (dag 2 - nat)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.14 på `https://voreshave.soenderup.dk`
- **Alt virker** - planteidentifikation via foto fungerer
- **Næste session:** se prioriteringslisten nederst

---

## Dagens arbejde

### Planteidentifikation via foto (v1.13 → v1.14)

**Hvad vi byggede:**
- Ny 📸 **Identificer**-knap i bunden mellem Haven og Kalender
- Vælg foto fra biblioteket ELLER tag nyt billede (begge muligheder på iPhone)
- Valgfrit tekstfelt: skriv et par ord der kan hjælpe AI'en
- Billede resizes til maks 800px på klienten inden afsendelse (holder det under Netlify-limit)
- Ny Netlify function `identify-plant.js` med **claude-sonnet-4-6** (vision)
- Returnerer: navn, latinsk navn, type, confidence (0-1), beskrivelse
- Confidence vises som: ✓ Høj / ~ Middel / ⚠ Lav
- **"+ Opret element i haven"**-knap (kun canEdit) → pre-udfyldt form med zonevælger
- Prøv igen-knap nulstiller hele flowet

**PLANT_TYPES udvidet:**
- Tilføjet: Blomst, Hæk, Græs
- Fuld liste: Stauder, Blomst, Løgplante, Grøntsag, Frugt, Træ, Busk, Hæk, Klatrer, Græs, Etårig, Andet

**Problemer vi løste:**
- `capture="environment"` tvang kameraet direkte → fjernet, giver nu iOS-valgmenu

---

## 💡 Idé noteret: single-user offline-version

Hvis nogen vil have en kopi til sig selv (kun én iPhone, ingen cloud):
- Erstat Firestore `saveDB`/`loadDB` med localStorage/IndexedDB
- Fotos i IndexedDB direkte (mønsteret er allerede der)
- Fjern Firebase SDK, PIN-system og brugerroller
- Netlify-funktioner (AI) skal stadig hostes med egen Anthropic API-nøgle
- Hage: data forsvinder ved app-sletning/telefonskift - ingen backup
- Estimat: ~1 dags arbejde

---

## ⚠ Steen skal tjekke

- Virker identifikation som forventet på iPhone?
- Er confidence-vurderingen brugbar?
- Er zonevælgeren i "Opret element"-formularen overskuelig?

---

## Teknisk overblik

```
voreshave/
├── index.html              ← hele appen (v1.14)
├── manifest.json           ← PWA-manifest
├── sw.js                   ← Service worker (cache: vores-have-v7)
├── netlify.toml            ← Netlify config (Node 18, secrets-scanner slået fra)
├── netlify/functions/
│   ├── plant-info.js       ← Claude Haiku - genererer "Viden om" tekst
│   ├── recommendations.js  ← Claude Haiku - per-plante anbefalinger
│   └── identify-plant.js   ← Claude Sonnet 4.6 - planteidentifikation via foto
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

### 1. Firestore sikkerhedsregler (deadline ~24. juni 2026)
Firestore kører i "test mode" - alle kan læse/skrive. Kræver Firebase Authentication.

### 2. Firebase Authentication
- Erstatter PIN-systemet på sigt
- Email/password for Steen og Linda

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
