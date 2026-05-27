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
    if (event.httpMethod !== 'POST') return { statusCode: 405, body: 'Method Not Allowed' };

    const { imageBase64, plantName, latinName, hint } = JSON.parse(event.body || '{}');
    const apiKey = process.env.ANTHROPIC_API_KEY;

    if (!apiKey || !imageBase64) {
        return { statusCode: 200, body: JSON.stringify({ notRecognized: true }) };
    }

    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const mediaType = imageBase64.startsWith('data:image/png') ? 'image/png' : 'image/jpeg';

    const plantInfo = plantName ? `Planten hedder "${plantName}"${latinName ? ` (${latinName})` : ''}.` : '';
    const hintInfo = hint ? `\n\nBrugeren tilføjer denne kontekst: "${hint}"` : '';

    const prompt = `Du er dansk havekonsulent og plantepatolog. ${plantInfo} Analyser billedet og diagnosticer hvad der er galt med planten.${hintInfo}

Returner KUN et JSON-objekt uden forklaring:
{
  "diagnosis": "kort navn på problemet (f.eks. 'Bladlus', 'Meldug', 'Jernmangel', 'Vandstress')",
  "symptoms": "beskriv hvad du ser på billedet i 1-2 sætninger på naturligt hverdagsdansk",
  "treatment": "konkret behandling i 2-3 sætninger på hverdagsdansk",
  "disclaimer": "Diagnosen er vejledende — kontakt et havecenter ved tvivl."
}

Hvis billedet ikke viser en plante eller problemet er utydeligt: { "notRecognized": true }`;

    const requestBody = JSON.stringify({
        model: 'claude-sonnet-4-6',
        max_tokens: 400,
        messages: [{
            role: 'user',
            content: [
                { type: 'image', source: { type: 'base64', media_type: mediaType, data: base64Data } },
                { type: 'text', text: prompt }
            ]
        }],
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
            return { statusCode: 200, body: JSON.stringify({ notRecognized: true }) };
        }

        const data = JSON.parse(result.body);
        const raw = data.content?.[0]?.text || '';
        const match = raw.match(/\{[\s\S]*\}/);
        if (!match) return { statusCode: 200, body: JSON.stringify({ notRecognized: true }) };

        let parsed;
        try { parsed = JSON.parse(match[0]); }
        catch (e) { return { statusCode: 200, body: JSON.stringify({ notRecognized: true }) }; }

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(parsed),
        };
    } catch (e) {
        console.error('diagnose-plant fejl:', e);
        return { statusCode: 200, body: JSON.stringify({ notRecognized: true }) };
    }
};
