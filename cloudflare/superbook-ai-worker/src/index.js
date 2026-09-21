const TEXT_MODEL = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
const IMAGE_MODEL = '@cf/black-forest-labs/flux-1-schnell';
const MAX_PASSAGE = 12000;

const sceneSchema = {
  type: 'object',
  properties: {
    schemaVersion: { type: 'string' },
    sceneSummary: { type: 'string' },
    visualStyle: { type: 'string' },
    characters: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          description: { type: 'string' },
          action: { type: 'string' },
          emotion: { type: 'string' },
          position: { type: 'string' },
        },
        required: ['id', 'description', 'action', 'emotion', 'position'],
      },
    },
    environment: {
      type: 'object',
      properties: {
        location: { type: 'string' },
        time: { type: 'string' },
        description: { type: 'string' },
      },
      required: ['location', 'time', 'description'],
    },
    props: { type: 'array', items: { type: 'string' } },
    actions: { type: 'array', items: { type: 'string' } },
    camera: {
      type: 'object',
      properties: {
        shot: { type: 'string' },
        angle: { type: 'string' },
        movement: { type: 'string' },
      },
      required: ['shot', 'angle', 'movement'],
    },
    lighting: { type: 'string' },
    motion: { type: 'string' },
    imagePrompt: { type: 'string' },
  },
  required: [
    'schemaVersion',
    'sceneSummary',
    'visualStyle',
    'characters',
    'environment',
    'props',
    'actions',
    'camera',
    'lighting',
    'motion',
    'imagePrompt',
  ],
};

const SYSTEM_PROMPT = [
  'You are SuperBook Scene Director.',
  'Read the supplied literary passage and design one faithful cinematic visual moment.',
  'Do not invent named characters, major objects, locations, or actions that contradict the passage.',
  'Prefer concrete visual details from the passage. Infer only harmless visual details needed for composition.',
  'The imagePrompt must describe one coherent cinematic frame, not a collage.',
  'Describe people with period-appropriate clothing and consistent physical appearance.',
  'Avoid text, captions, speech bubbles, logos, watermarks, modern objects, duplicate people, extra limbs, and distorted anatomy.',
  'Return only the requested JSON object.',
].join(' ');

function cors(origin) {
  return {
    'Access-Control-Allow-Origin': origin && origin !== 'null' ? origin : '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  };
}

function json(data, status, origin) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...cors(origin),
    },
  });
}

function trimPassage(value) {
  return String(value || '').replace(/\s+/g, ' ').trim().slice(0, MAX_PASSAGE);
}

function validatePlan(plan) {
  return plan &&
    typeof plan.sceneSummary === 'string' &&
    typeof plan.imagePrompt === 'string' &&
    Array.isArray(plan.characters) &&
    plan.characters.length <= 8 &&
    Array.isArray(plan.props) &&
    plan.props.length <= 20 &&
    Array.isArray(plan.actions) &&
    plan.actions.length <= 12 &&
    plan.environment &&
    typeof plan.environment.location === 'string' &&
    plan.camera &&
    typeof plan.camera.shot === 'string';
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin');

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors(origin) });
    }

    if (request.method !== 'POST') {
      return json({ error: 'POST required.' }, 405, origin);
    }

    let input;
    try {
      input = await request.json();
    } catch (_) {
      return json({ error: 'Request body must be valid JSON.' }, 400, origin);
    }

    const passage = trimPassage(input && input.passage);
    if (!passage) return json({ error: 'passage is required.' }, 400, origin);

    try {
      const context = [
        input && input.title ? 'Book: ' + String(input.title) : '',
        input && input.author ? 'Author: ' + String(input.author) : '',
        input && input.chapterId ? 'Chapter: ' + String(input.chapterId) : '',
        '',
        'PASSAGE:',
        passage,
      ].filter(Boolean).join('\n');

      const reasoning = await env.AI.run(TEXT_MODEL, {
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: context },
        ],
        response_format: {
          type: 'json_schema',
          json_schema: sceneSchema,
        },
        temperature: 0.25,
        max_tokens: 1800,
      });

      const plan = reasoning && reasoning.response;
      if (!validatePlan(plan)) {
        return json({ error: 'AI returned an invalid scene plan.' }, 502, origin);
      }

      const image = await env.AI.run(IMAGE_MODEL, {
        prompt: plan.imagePrompt.slice(0, 2048),
        steps: 4,
      });

      if (!image || !image.image) {
        return json({ error: 'Image model returned no image.' }, 502, origin);
      }

      return json({
        schemaVersion: '1',
        scenePlan: plan,
        image: {
          mimeType: 'image/jpeg',
          base64: image.image,
        },
      }, 200, origin);
    } catch (error) {
      console.error('SuperBook scene generation failed', error);
      return json({
        error: 'Scene generation failed.',
        detail: error instanceof Error ? error.message : String(error),
      }, 502, origin);
    }
  },
};
