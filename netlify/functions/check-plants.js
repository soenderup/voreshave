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

    const { plants } = JSON.parse(event.body || '{}');
    const apiKey = process.env.ANTHROPIC_API_KEY;

    if (!apiKey || !plants || plants.length === 0) {
        return { statusCode: 200, body: JSON.stringify({ issues: [] }) };
    }

    const plantList = plants.map((p, i) => {
        const zoneInfo = p.zoneType ? `, zone-type: "${p.zoneType}"` : '';
        const latin = p.latinName ? ` (${p.latinName})` : '';
        return `${i + 1}. "${p.name}"${latin} — type: "${p.type}"${zoneInfo}`;
    }).join('\n');

    const prompt = `Du er dansk haveekspert. Gennemgå denne liste af planter og vurdér om nogen har forkert planteType registreret.

Eksempler på fejlregistreringer:
- En jordbær registreret som "Træ" (jordbær er "Frugt")
- En rosmarin registreret som "Blomst" (rosmarin er "Busk")
- En tulipan registreret som "Stauder" (tulipaner er "Løgplante")
- En tomat registreret som "Frugt" (tomat er "Grøntsag" i havesammenhæng)

Gyldige typer: Stauder, Blomst, Løgplante, Grøntsag, Frugt, Træ, Busk, Hæk, Klatrer, Græs, Etårig, Andet

Planter at vurdere:
${plantList}

Returner KUN et JSON-array med de planter der sandsynligvis har FORKERT type — kun dem du er ret sikker på er fejlregistreret. Vær konservativ: hellere for få end for mange. Ingen tekst udenfor JSON:
[
  {
    "index": 1,
    "name": "plantenavn som angivet",
    "currentType": "den registrerede type",
    "suggestedType": "korrekt type eller null hvis du er usikker",
    "reason": "1 kort sætning på dansk om hvorfor det ser forkert ud"
  }
]

Hvis ingen ser fejlagtige ud, returner: []`;

    const requestBody = JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 1000,
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
            return { statusCode: 500, body: JSON.stringify({ error: 'API fejl ' + result.status }) };
        }

        const data = JSON.parse(result.body);
        const raw = data.content?.[0]?.text || '';
        const match = raw.match(/\[[\s\S]*\]/);
        if (!match) return { statusCode: 200, body: JSON.stringify({ issues: [] }) };

        let parsed;
        try { parsed = JSON.parse(match[0]); }
        catch (e) { return { statusCode: 200, body: JSON.stringify({ issues: [] }) }; }

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ issues: Array.isArray(parsed) ? parsed : [] }),
        };
    } catch (e) {
        console.error('check-plants fejl:', e);
        return { statusCode: 500, body: JSON.stringify({ error: e.message }) };
    }
};
