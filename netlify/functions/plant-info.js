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
        ? '\n\nOBS: Intet latinsk navn angivet. Nævn i info-teksten at svaret er baseret på almennavnet og kan variere.'
        : '';

    const prompt = `Du er en dansk haveekspert. Returner KUN et JSON-objekt om følgende plante (ingen forklaring, ingen markdown):
{
  "info": "3-5 konkrete sætninger på hverdagsdansk om pasning, vanding, beskæring, dansk klima og særlige hensyn${missingInfo}",
  "water": "dry",
  "light": "full",
  "perennial": true
}

Mulige water-værdier: "dry" (tørketålende), "normal" (normal vanding), "moist" (fugtighedskrævende – hold jord fugtig)
Mulige light-værdier: "full" (fuld sol, 6+ timer), "full-partial" (sol til halvskygge), "partial" (halvskygge, 3-6 timer), "partial-shade" (halvskygge til skygge), "shade" (skygge, under 3 timer)
perennial: true hvis flerårig, false hvis etårig/toårig

Plante:
${plantDesc}`;

    const requestBody = JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 600,
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
            return { statusCode: 200, body: JSON.stringify({ info: `Kunne ikke hente planteinfo (fejl ${result.status}) – prøv igen.` }) };
        }

        const data = JSON.parse(result.body);
        const raw = data.content?.[0]?.text || '';
        const match = raw.match(/\{[\s\S]*\}/);
        if (!match) {
            return { statusCode: 200, body: JSON.stringify({ info: raw || 'Ingen information tilgængelig.' }) };
        }

        let parsed;
        try { parsed = JSON.parse(match[0]); }
        catch (e) {
            return { statusCode: 200, body: JSON.stringify({ info: raw || 'Ingen information tilgængelig.' }) };
        }

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(parsed),
        };
    } catch (e) {
        console.error('plant-info function fejl:', e);
        return { statusCode: 200, body: JSON.stringify({ info: 'Teknisk fejl – prøv igen senere.' }) };
    }
};
