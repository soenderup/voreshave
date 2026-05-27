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

    const { imageBase64, hint, correction } = JSON.parse(event.body || '{}');
    const apiKey = process.env.ANTHROPIC_API_KEY;

    if (!apiKey || !imageBase64) {
        return { statusCode: 200, body: JSON.stringify({ notRecognized: true }) };
    }

    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const mediaType = imageBase64.startsWith('data:image/png') ? 'image/png' : 'image/jpeg';
    const hintText = hint ? `\n\nBrugerens note: "${hint}"` : '';
    const correctionText = correction ? `\n\nBrugerens kommentar til dit forrige svar: "${correction}"` : '';
    const correctionResponseField = correction ? `\n  "correctionResponse": "1-2 sætninger på hverdagsdansk der direkte adresserer brugerens kommentar og forklarer hvorfor du nu foreslår denne plante",` : '';

    const prompt = `Du er dansk planteekspert. Identificer planten på billedet.${hintText}${correctionText}

Returner KUN et JSON-objekt uden forklaring:
{${correctionResponseField}
  "name": "dansk plantenavn",
  "latinName": "latinsk navn eller null",
  "type": "én af: Stauder, Blomst, Løgplante, Grøntsag, Frugt, Træ, Busk, Hæk, Klatrer, Græs, Etårig, Andet",
  "confidence": 0.0-1.0,
  "description": "2-3 sætninger om planten på naturligt hverdagsdansk",
  "water": "dry",
  "light": "full",
  "perennial": true
}

water-værdier: "dry" (tørketålende), "normal" (normal vanding), "moist" (fugtighedskrævende)
light-værdier: "full" (fuld sol), "full-partial" (sol til halvskygge), "partial" (halvskygge), "partial-shade" (halvskygge til skygge), "shade" (skygge)
perennial: true hvis flerårig, false hvis etårig/toårig

Hvis billedet ikke viser en plante eller er for utydeligt til at identificere: { "notRecognized": true }`;

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
        console.error('identify-plant fejl:', e);
        return { statusCode: 200, body: JSON.stringify({ notRecognized: true }) };
    }
};
