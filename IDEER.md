# Ideer — Vores Have

---

## "Hvad fejler den?" — AI-plantediagnose

**Idé:** Tag et foto af en syg eller stresset plante, og få AI til at analysere hvad der er galt.

**Flow:**
1. Bruger trykker "Hvad fejler den?" (knap på element-siden eller hamburgermenu)
2. Kamera åbner — tag foto af planten (symptomer, blade, stængel)
3. Foto sendes til en ny Netlify-funktion `diagnose-plant.js`
4. Claude Sonnet (vision) analyserer billedet og returnerer:
   - Mulig diagnose (sygdom, skadedyr, næringsstofmangel, vandstress etc.)
   - Beskrivelse af symptomerne den ser
   - Anbefalet behandling / næste skridt
5. Resultatet vises på skærmen — kan evt. gemmes som note eller historik-entry

**Teknisk:**
- Samme mønster som `identify-plant.js` (base64-billede → Claude vision)
- Prompt skal inkludere plantenavnet hvis kaldt fra en konkret plante-side
- Model: Claude Sonnet 4.6 (samme som identificering — kræver vision)
- Placering: knap på element-siden (info-tab) og/eller i hamburgermenu

**Overvejelser:**
- Koster øre pr. opslag (samme størrelsesorden som identificering)
- Diagnosen er vejledende — tilføj disclaimer
- Evt. mulighed for at gemme diagnosen som historik-entry med dato

---
