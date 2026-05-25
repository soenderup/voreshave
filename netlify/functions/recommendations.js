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

    const { plants, zones, reminders } = JSON.parse(event.body || '{}');
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
        return { statusCode: 200, body: JSON.stringify({ items: [] }) };
    }

    const plantLines = (plants || []).map(p =>
        `- ID:${p.id} | ${p.name}${p.latinName ? ` (${p.latinName})` : ''} | Type: ${p.type || 'ukendt'}`
    ).join('\n');

    const zoneLines = (zones || []).map(z =>
        `- ID:${z.id} | ${z.name} | Type: ${z.type}`
    ).join('\n');

    const reminderLines = (reminders || []).map(r =>
        `- EntityID:${r.entityId} | ${r.text} | Dato: ${r.date}`
    ).join('\n');

    const prompt = `Du er en dansk haveekspert. Nedenfor er en liste over planter og haveelementer. Giv konkrete, månedsvise plejehandlinger for det kommende år baseret på dansk klima.

PLANTER:
${plantLines || '(ingen)'}

HAVEELEMENTER (hæk, græs, træer som zoner):
${zoneLines || '(ingen)'}

EKSISTERENDE PÅMINDELSER (undgå dubletter):
${reminderLines || '(ingen)'}

Returner KUN et JSON-array uden forklaring eller markdown. Hvert objekt skal have præcis disse felter:
- entityType: "plant" eller "zone"
- entityId: ID fra listen ovenfor
- entityName: navn på planten/elementet
- months: array af månedsnumre (1-12) hvor handlingen skal udføres
- text: kort, konkret handlingsbeskrivelse på dansk (maks 60 tegn)
- repeat: altid "yearly"

Medtag KUN handlinger der ikke allerede er dækket af eksisterende påmindelser. Maks 3 anbefalinger pr. element.`;

    const requestBody = JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 2000,
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
            return { statusCode: 200, body: JSON.stringify({ items: [] }) };
        }

        const data = JSON.parse(result.body);
        const raw = data.content?.[0]?.text || '[]';

        // Udtræk JSON selv om Claude tilføjer tekst omkring
        const match = raw.match(/\[[\s\S]*\]/);
        const items = match ? JSON.parse(match[0]) : [];

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ items }),
        };
    } catch (e) {
        console.error('recommendations function fejl:', e);
        return { statusCode: 200, body: JSON.stringify({ items: [] }) };
    }
};
