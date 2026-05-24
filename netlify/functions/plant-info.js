exports.handler = async function (event) {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { name, latinName, plantType, note } = JSON.parse(event.body || '{}');

    const plantDesc = [
        latinName ? `Latinsk navn: ${latinName}` : null,
        name      ? `Navn: ${name}` : null,
        plantType ? `Type: ${plantType}` : null,
        note      ? `Brugerens egne noter: ${note}` : null,
    ].filter(Boolean).join('\n');

    const missingInfo = !latinName
        ? '\n\nOBS: Intet latinsk navn er angivet. Skriv at informationen er baseret på det almene navn og derfor kan være upræcis, og nævn at præcist latinsk navn ville give bedre svar.'
        : '';

    const prompt = `Du er en dansk haveekspert. Skriv 3-5 sætninger på dansk om følgende plante til brug i en have-app. Vær konkret og nyttig: pasning, vanding, beskæring, særlige hensyn for dansk klima, typiske problemer eller tips. Brug brugerens egne noter hvis de giver relevant kontekst.${missingInfo}

Plante:
${plantDesc}

Svar KUN med den faktuelle tekst direkte – ingen indledning som "Her er information om..." eller "Selvfølgelig!".`;

    const response = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': process.env.ANTHROPIC_API_KEY,
            'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
            model: 'claude-haiku-4-5-20251001',
            max_tokens: 500,
            messages: [{ role: 'user', content: prompt }],
        }),
    });

    if (!response.ok) {
        return {
            statusCode: 200,
            body: JSON.stringify({ info: 'Kunne ikke hente planteinfo lige nu – prøv igen ved at redigere elementet.' }),
        };
    }

    const data = await response.json();
    const info = data.content?.[0]?.text || 'Ingen information tilgængelig.';

    return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ info }),
    };
};
