# Handoff — Vores Have
*Opdateret: 25. maj 2026 (dag 2 - aften)*

---

## STATUS LIGE NU (læs først)

- **Live version:** v1.15 på `https://voreshave.soenderup.dk`
- **Alt virker** - direkte elementer under område, identificér medfører foto
- **Næste session:** se prioriteringslisten nederst

---

## Dagens arbejde

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

## ⚠ Steen skal tjekke

- Virker "flyt element" (zone-skift) korrekt efter lukke/genåbne app?
- Ser direkte elementer pæne ud under området?

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
