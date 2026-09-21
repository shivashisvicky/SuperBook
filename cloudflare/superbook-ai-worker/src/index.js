// SuperBook animation path: narrative-driven T2V, no R2 asset handoff.
const TEXT_MODEL = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
const IMAGE_MODEL = '@cf/black-forest-labs/flux-1-schnell';
const MOTION_MODEL = '@cf/black-forest-labs/flux-2-klein-4b';
const VIDEO_MODEL = 'alibaba/hh1.1-t2v';
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
  'sceneSummary is the reader-facing narrative summary, not a caption. Write 2-3 concise sentences (about 35-70 words) that explain what is happening in the passage, the immediate context leading into this moment, and why the moment matters. Preserve the literary facts and do not invent events. Do not collapse it into a single sentence.',
  'Do not invent named characters, major objects, locations, or actions that contradict the passage.',
  'Prefer concrete visual details from the passage. Infer only harmless visual details needed for composition.',
  'The imagePrompt must describe one coherent cinematic frame, not a collage.',
  'Describe people with period-appropriate clothing and consistent physical appearance.',
  'The motion field must describe restrained, physically plausible movement for a short 3-6 second literary scene.',
  'The camera movement should be subtle and scene-specific, not a generic zoom.',
  'Avoid text, captions, speech bubbles, logos, watermarks, modern objects, duplicate people, extra limbs, and distorted anatomy.',
  'Return only the requested JSON object.',
].join(' ');

function cors(origin) {
  return {
    'Access-Control-Allow-Origin': origin && origin !== 'null' ? origin : '*',
    'Access-Control-Allow-Headers': 'Content-Type, Range',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
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

function videoPrompt(plan) {
  return [
    'Animate the story moment described below as a restrained 3-6 second cinematic sequence.',
    'Story summary: ' + plan.sceneSummary,
    'Visual style: ' + plan.visualStyle,
    'Environment: ' + plan.environment.location + ', ' + plan.environment.time + '. ' + plan.environment.description,
    'Characters: ' + plan.characters.map((character) => character.description + ', ' + character.action + ', ' + character.emotion).join('; '),
    'Do not introduce new characters, major objects, or events beyond the literary moment.',
    'Meaningful motion: ' + plan.motion,
    'Character actions: ' + plan.actions.join('; '),
    'Camera: ' + plan.camera.movement + ', ' + plan.camera.shot + ', ' + plan.camera.angle + '.',
    'Lighting: ' + plan.lighting,
    'Natural movement only. Avoid warping faces, hands, clothing, furniture, or architecture.',
    'No text, captions, logos, watermarks, or scene changes.',
  ].join(' ');
}

function parseScenePlan(reasoning) {
  const candidate = reasoning && reasoning.response !== undefined
    ? reasoning.response
    : reasoning;

  if (candidate && typeof candidate === 'object' && !Array.isArray(candidate)) {
    return candidate;
  }

  if (typeof candidate !== 'string') return null;

  const text = candidate
    .replace(/^\s*\`\`\`(?:json)?\s*/i, '')
    .replace(/\s*\`\`\`\s*$/i, '')
    .trim();

  try {
    return JSON.parse(text);
  } catch (_) {
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      return JSON.parse(text.slice(start, end + 1));
    } catch (_) {
      return null;
    }
  }
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

async function generateMotionFrames(env, plan, imageBase64, origin) {
  if (typeof imageBase64 !== 'string' || imageBase64.length === 0) {
    return json({ error: 'A reference scene image is required.' }, 400, origin);
  }

  let sourceBytes;
  try {
    const binary = atob(imageBase64);
    sourceBytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
  } catch (_) {
    return json({ error: 'Reference scene image is not valid base64.' }, 400, origin);
  }

  const sourceBlob = new Blob([sourceBytes], { type: 'image/png' });
  // Two distinct AI-generated acting states are enough for the current
  // motion-comic presentation. Generate them concurrently so one scene
  // does not wait for three serial inference calls.
  const actions = plan.actions.filter((action) => typeof action === 'string' && action.trim()).slice(0, 2);
  const beats = actions.length > 0
    ? actions
    : plan.characters.slice(0, 2).map((character) => character.action).filter(Boolean);

  if (beats.length === 0) {
    beats.push(plan.motion || 'subtle natural movement');
  }

  const frames = await Promise.all(beats.map(async (beat) => {
    const form = new FormData();
    form.append('input_image_0', sourceBlob, 'scene.png');
    form.append(
      'prompt',
      [
        'Create the next illustrated story frame from the reference image.',
        'Preserve the same room, period, characters, clothing, faces, composition, lighting, and visual style.',
        'Change only the physical acting needed for this narrative beat.',
        'Do not add characters, remove characters, change location, or invent a new event.',
        'Keep identities and architecture consistent with the reference.',
        'Narrative beat: ' + beat,
        'Character actions: ' + plan.characters.map((character) => character.id + ': ' + character.action + ', ' + character.emotion).join('; '),
        'Visual style: ' + plan.visualStyle,
        'No text, captions, logos, watermarks, or collage panels.',
      ].join(' ').slice(0, 2048),
    );
    form.append('width', '1024');
    form.append('height', '768');

    const serialized = new Response(form);
    const multipartBody = serialized.body;
    const contentType = serialized.headers.get('content-type');

    const generated = await env.AI.run(MOTION_MODEL, {
      multipart: {
        body: multipartBody,
        contentType,
      },
    });

    if (!generated || typeof generated.image !== 'string' || generated.image.length === 0) {
      throw new Error('Motion frame model returned no image.');
    }

    return {
      mimeType: 'image/jpeg',
      base64: generated.image,
      beat,
    };
  }));

  return json({
    frames,
    frameDurationSeconds: 2.4,
  }, 200, origin);
}

async function generateVideo(env, plan, origin, requestUrl) {
  const video = await env.AI.run(VIDEO_MODEL, {
    prompt: [
      videoPrompt(plan),
      'This is a short living illustration, not a new plot event.',
      'Keep movement subtle and localized to the described actions.',
    ].join(' ').slice(0, 2500),
    duration: 4,
    resolution: '720P',
    ratio: '16:9',
    watermark: false,
  });

  let videoUrl = video && video.video
    ? video.video
    : video && video.result && video.result.video;

  if (typeof videoUrl !== 'string' || videoUrl.length === 0) {
    throw new Error('Video model returned no video URL.');
  }

  videoUrl = requestUrl.origin + '/video?url=' + encodeURIComponent(videoUrl);

  return json({
    video: {
      url: videoUrl,
      durationSeconds: 4,
    },
  }, 200, origin);
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin');

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors(origin) });
    }

    const requestUrl = new URL(request.url);

    if (request.method === 'GET' && requestUrl.pathname === '/video') {
      const target = requestUrl.searchParams.get('url');
      if (!target) return json({ error: 'url is required.' }, 400, origin);

      let targetUrl;
      try {
        targetUrl = new URL(target);
      } catch (_) {
        return json({ error: 'Invalid video URL.' }, 400, origin);
      }

      if (targetUrl.protocol !== 'https:') {
        return json({ error: 'Video URL must use HTTPS.' }, 400, origin);
      }

      try {
        const range = request.headers.get('Range');
        const upstream = await fetch(targetUrl.toString(), {
          headers: range ? { Range: range } : {},
        });

        const headers = new Headers();
        const contentType = upstream.headers.get('Content-Type');
        const contentLength = upstream.headers.get('Content-Length');
        const contentRange = upstream.headers.get('Content-Range');
        const acceptRanges = upstream.headers.get('Accept-Ranges');

        if (contentType) headers.set('Content-Type', contentType);
        if (contentLength) headers.set('Content-Length', contentLength);
        if (contentRange) headers.set('Content-Range', contentRange);
        if (acceptRanges) headers.set('Accept-Ranges', acceptRanges);
        headers.set('Cache-Control', 'public, max-age=300');
        Object.entries(cors(origin)).forEach(([key, value]) => headers.set(key, value));

        return new Response(upstream.body, {
          status: upstream.status,
          headers,
        });
      } catch (error) {
        return json({
          error: 'Video proxy failed.',
          detail: error instanceof Error ? error.message : String(error),
        }, 502, origin);
      }
    }

    if (request.method === 'POST' && requestUrl.pathname === '/motion') {
      let input;
      try {
        input = await request.json();
      } catch (_) {
        return json({ error: 'Request body must be valid JSON.' }, 400, origin);
      }

      const plan = input && input.scenePlan;
      const imageBase64 = input && input.imageBase64;
      if (!validatePlan(plan)) {
        return json({ error: 'A valid scenePlan is required.' }, 400, origin);
      }

      try {
        return await generateMotionFrames(env, plan, imageBase64, origin);
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        const code = error && typeof error === 'object' ? error.code : undefined;
        const status = error && typeof error === 'object' ? error.status : undefined;
        console.error('SuperBook motion frame generation failed', { detail, code, status });
        return json({
          error: 'Motion frame generation failed.',
          detail,
          code: code ?? null,
          upstreamStatus: status ?? null,
        }, 502, origin);
      }
    }

    if (request.method === 'POST' && requestUrl.pathname === '/video') {
      let input;
      try {
        input = await request.json();
      } catch (_) {
        return json({ error: 'Request body must be valid JSON.' }, 400, origin);
      }

      const plan = input && input.scenePlan;
      if (!validatePlan(plan)) {
        return json({ error: 'A valid scenePlan is required.' }, 400, origin);
      }

      try {
        return await generateVideo(env, plan, origin, requestUrl);
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        const code = error && typeof error === 'object' ? error.code : undefined;
        const status = error && typeof error === 'object' ? error.status : undefined;
        console.error('SuperBook scene animation failed', { detail, code, status });
        return json({
          error: 'Video generation failed.',
          detail,
          code: code ?? null,
          upstreamStatus: status ?? null,
        }, 502, origin);
      }
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

      const plan = parseScenePlan(reasoning);
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
        schemaVersion: '2',
        scenePlan: plan,
        image: {
          mimeType: 'image/jpeg',