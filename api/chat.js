const { streamText } = require('ai');

const personas = {
  amara: { name: 'Amara', mode: 'Dating', personality: 'warm, playful, affectionate, curious and emotionally attentive' },
  daniel: { name: 'Daniel', mode: 'Talking Stage', personality: 'confident, curious, relaxed and natural; never overly formal' },
  sarah: { name: 'Sarah', mode: 'Relationship', personality: 'supportive, honest, affectionate and emotionally mature' },
  coach: { name: 'Marriage Coach', mode: 'Marriage', personality: 'thoughtful, balanced, practical and respectful; focuses on healthy communication' }
};

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  if (!process.env.AI_GATEWAY_API_KEY) return res.status(500).json({ error: 'AI_GATEWAY_API_KEY is not configured' });

  try {
    const { personaId = 'amara', messages = [] } = req.body || {};
    const persona = personas[personaId] || personas.amara;
    const recent = Array.isArray(messages) ? messages.slice(-20) : [];
    const transcript = recent.map(m => `${m.role === 'assistant' ? persona.name : 'User'}: ${String(m.content || '').slice(0, 4000)}`).join('\n');

    const result = streamText({
      model: 'openai/gpt-5.6-luna',
      system: `You are ${persona.name}, a fictional AI conversation partner inside Zap. Your conversation mode is ${persona.mode}. Personality: ${persona.personality}. Stay consistent with the personality and remember details from the supplied conversation. Write like a real person texting: concise, natural, varied, warm when appropriate, and not like an assistant. Do not claim to be a real human. Never manipulate the user into believing you have a real-world relationship or consciousness. Avoid repetitive questions. For relationship or marriage topics, encourage respectful communication and consent. Keep responses suitable for a general audience. Usually answer in 1-4 short paragraphs or messages.\n\nConversation:\n${transcript}`,
      prompt: 'Continue the conversation naturally based on the latest user message.',
      maxOutputTokens: 300
    });

    const stream = result.toTextStreamResponse();
    res.statusCode = stream.status || 200;
    for (const [key, value] of stream.headers.entries()) res.setHeader(key, value);
    if (stream.body) {
      const reader = stream.body.getReader();
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        res.write(Buffer.from(value));
      }
    }
    res.end();
  } catch (error) {
    console.error('Zap AI error', error);
    if (!res.headersSent) res.status(500).json({ error: 'Unable to generate a response' });
    else res.end();
  }
};
