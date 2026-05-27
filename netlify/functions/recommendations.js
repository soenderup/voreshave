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

const REPLACEMENTS = [
    [/dødblom\w*/gi, 'fjern visne blomster'],
    [/deadhead\w*/gi, 'fjern visne blomster'],
    [/pinch\s*out/gi, 'knib skuddene'],
    [/mulch\w*/gi, 'dæk med kompost'],
];

function cleanText(text) {
    return REPLACEMENTS.reduce((t, [p, r]) => t.replace(p, r), text);
}

exports.handler = async function (event) {
    if (event.httpMethod !== 'POST') return { statusCode: 405, body: 'Method Not Allowed' };

    const { plant } = JSON.parse(event.body || '{}');
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey || !plant) return { statusCode: 200, body: JSON.stringify({ items: [] }) };

    const prompt = `Du er dansk haveekspert. Giv 3-4 konkrete plejehandlinger for denne plante baseret på dansk klima og årstider.

Plante: ${plant.name}${plant.latinName ? ` (${plant.latinName})` : ''}${plant.type ? ` — type: ${plant.type}` : ''}

Skriv på naturligt hverdagsdansk i hele sætninger så en almindelig haveejer forstår det. Forklar gerne kort hvorfor. Eksempel: "Klip planterne ned til ca. 10 cm efter første frost — det styrker rødderne til næste år". Undgå engelske fagtermer som "deadhead", "mulch", "pinch out" — brug i stedet "fjern visne blomster", "dæk med kompost", "knib toppen af".

Returner KUN et JSON-array uden forklaring. Format: [{"text":"...","months":[månedsnumre 1-12]}]`;

    const requestBody = JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 400,
        messages: [{ role: 'user', content: prompt }],
    });

    const apiOptions = {
        hostname: 'api.anthropic.com',
        path: '/v1/messages',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Length': Buffer.byteLength(requestBody),
        },
    };
    const sleep = ms => new Promise(r => setTimeout(r, ms));

    try {
        let result = await httpsPost(apiOptions, requestBody);

        if (result.status === 529 || result.status === 503) {
            await sleep(1000);
            result = await httpsPost(apiOptions, requestBody);
        }

        if (result.status !== 200) {
            console.error('Anthropic API fejl:', result.status, result.body);
            return { statusCode: 200, body: JSON.stringify({ items: [] }) };
        }

        const data = JSON.parse(result.body);
        const raw = data.content?.[0]?.text || '';
        const match = raw.match(/\[[\s\S]*\]/);
        if (!match) return { statusCode: 200, body: JSON.stringify({ items: [] }) };

        let items;
        try {
            items = JSON.parse(match[0]);
        } catch (e) {
            console.error('JSON parse fejl:', e.message);
            return { statusCode: 200, body: JSON.stringify({ items: [] }) };
        }

        items = items.map(item => ({ ...item, text: cleanText(item.text) }));

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ items }),
        };
    } catch (e) {
        console.error('recommendations fejl:', e);
        return { statusCode: 200, body: JSON.stringify({ items: [] }) };
    }
};
