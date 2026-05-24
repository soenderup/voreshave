const https = require('https');

function httpsPost(options, body) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: data }));
        });
        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

exports.handler = async function (event) {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { name, latinName, plantType, note } = JSON.parse(event.body || '{}');

    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
        return { statusCode: 200, body: JSON.stringify({ info: 'API-nøgle mangler – kontakt administrator.' }) };
    }

    const plantDesc = [
        latinName ? `Latinsk navn: ${latinName}` : null,
        name      ? `Navn: ${name}` : null,
        plantType ? `Type: ${plantType}` : null,
        note      ? `Brugerens egne noter: ${note}` : null,
    ].filter(Boolean).join('\n');

    const missingInfo = !latinName
        ? '\n\nOBS: Intet latinsk navn er angivet. Nævn at svaret er baseret på det almene navn og kan variere, og angiv hvad der ville gøre svaret mere præcist.'
        : '';

    const prompt = `Du er en dansk haveekspert. Skriv 3-5 sætninger på dansk om følgende plante til brug i en have-app. Vær konkret og nyttig: pasning, vanding, beskæring, særlige hensyn for dansk klima, typiske problemer eller tips. Brug brugerens egne noter hvis de giver relevant kontekst.${missingInfo}

Plante:
${plantDesc}

Svar KUN med den faktuelle tekst direkte – ingen indledning som "Her er information om..." eller "Selvfølgelig!".`;

    const requestBody = JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 500,
        messages: [{ role: 'user', content: prompt }],
    });

    try {
        const result = await httpsPost({
            hostname: 'api.anthropic.com',
            path: '/v1/messages',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': apiKey,
                'anthropic-version': '2023-06-01',
                'Content-Length': Buffer.byteLength(requestBody),
            },
        }, requestBody);

        if (result.status !== 200) {
            console.error('Anthropic API fejl:', result.status, result.body);
            return { statusCode: 200, body: JSON.stringify({ info: `Kunne ikke hente planteinfo (fejl ${result.status}) – prøv igen ved at redigere elementet.` }) };
        }

        const data = JSON.parse(result.body);
        const info = data.content?.[0]?.text || 'Ingen information tilgængelig.';

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ info }),
        };
    } catch (e) {
        console.error('plant-info function fejl:', e);
        return { statusCode: 200, body: JSON.stringify({ info: 'Teknisk fejl – prøv igen senere.' }) };
    }
};
