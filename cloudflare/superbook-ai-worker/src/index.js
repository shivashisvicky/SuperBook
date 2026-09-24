// SuperBook scene path: AI direction + generated keyframe + local Flutter stage. T2V remains explicit/disabled by default.
// Live smoke-test harness: deployment must pass the API contract before UI verification.
const TEXT_MODEL = '@cf/meta/llama-3.3-70b-instruct-fp8-fast';
const IMAGE_MODEL = '@cf/black-forest-labs/flux-1-schnell';
const MOTION_MODEL = '@cf/black-forest-labs/flux-2-klein-4b';
const HF_VIDEO_SPACE = 'https://rahul7star-wan22-t2v-a14b.hf.space';
const HF_VIDEO_API = 'generate_video';
const MAX_PASSAGE = 3600;

const sceneSchema = {
  type: 'object',
  properties: {
    schemaVersion: { type: 'string' },
    sceneSummary: { type: 'string' },
    visualStyle: { type: 'string' },
    characters: {
      type: 'array',
      maxItems: 2,
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          description: { type: 'string' },
          action: { type: 'string' },
          emotion: { type: 'string' },
          position: { type: 'string' },
          runtimeAnimation: {
            type: 'string',
            enum: ['idle', 'talk', 'listen', 'gesture', 'reach', 'walk', 'react'],
          },
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
    props: { type: 'array', maxItems: 3, items: { type: 'string' } },
    actions: { type: 'array', maxItems: 3, items: { type: 'string' } },
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
  'sceneSummary is the reader-facing narrative summary. Write 1-2 concise sentences, about 25-45 words, explaining the immediate literary moment and why it matters. Preserve facts and do not invent events.',
  'Do not invent named characters, major objects, locations, or actions that contradict the passage.',
  'Prefer concrete visual details from the passage. Infer only harmless visual details needed for composition.',
  'The imagePrompt must describe one coherent cinematic frame, not a collage.',
  'Describe people with period-appropriate clothing and consistent physical appearance.',
  'Each character must receive exactly one runtimeAnimation directive: idle, talk, listen, gesture, reach, walk, or react. This is an instruction to the character animation runtime, not prose. Choose the directive from the character\'s actual behavior in this passage. Do not use idle for a character who is speaking, gesturing, reaching, walking, or visibly reacting.',
  'The motion field must describe restrained, physically plausible movement for a short 3-6 second literary scene.',
  'The camera movement should be subtle and scene-specific, not a generic zoom.',
  'Avoid text, captions, speech bubbles, logos, watermarks, modern objects, duplicate people, extra limbs, and distorted anatomy.',
  'Return ONLY one compact JSON object. Keep every string concise. Use at most 2 characters, 3 props, 3 actions, and short descriptions. Do not use markdown fences.',
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
    'Create a short cinematic living-book scene from the supplied literary passage.',
    'Preserve the exact narrative facts. Do not summarize the story into a generic trailer.',
    'Visual style: grounded cinematic literary realism, period-appropriate, coherent characters and environment.',
    'Scene: ' + plan.sceneSummary,
    'Visual description: ' + plan.imagePrompt,
    'Environment: ' + plan.environment.location + ', ' + plan.environment.time + '. ' + plan.environment.description,
    'Characters: ' + plan.characters.map((character) => character.description + ', ' + character.action + ', ' + character.emotion).join('; '),
    'Meaningful motion: ' + plan.motion,
    'Actions: ' + plan.actions.join('; '),
    'Camera: ' + plan.camera.movement + ', ' + plan.camera.shot + ', ' + plan.camera.angle + '.',
    'Lighting: ' + plan.lighting,
    'Keep motion physically plausible and continuous. Preserve faces, clothing, architecture and object identity.',
    'No text, captions, logos, watermarks, scene changes, duplicate people, extra limbs, frozen frames, or abstract morphing.',
  ].join(' ').slice(0, 5000);
}

function fallbackScenePlan(input) {
  const passage = trimPassage(input && input.passage);
  const title = String(input && input.title || 'Story moment').trim().slice(0, 160);
  const author = String(input && input.author || '').trim().slice(0, 120);
  const sceneText = passage || title;
  const summary = sceneText.length > 900
    ? sceneText.slice(0, 897) + '...'
    : sceneText;

  return {
    schemaVersion: 'free-t2v-1',
    sceneSummary: summary,
    visualStyle: 'cinematic literary realism',
    characters: [],
    environment: {
      location: title,
      time: 'as described in the passage',
      description: author
        ? 'A faithful visualisation of the literary passage from ' + author + '.'
        : 'A faithful visualisation of the supplied literary passage.',
    },
    props: [],
    actions: ['subtle natural movement faithful to the passage'],
    camera: {
      shot: 'medium-wide cinematic shot',
      angle: 'eye level',
      movement: 'slow motivated camera movement',
    },
    lighting: 'natural cinematic lighting faithful to the passage',
    motion: 'subtle continuous environmental movement and restrained character movement only where implied by the text',
    imagePrompt: sceneText,
  };
}

async function callHuggingFaceVideo(plan, origin, requestUrl) {
  const prompt = videoPrompt(plan);
  const negativePrompt = [
    'static image, frozen frame, flicker, morphing, warped face, distorted hands, extra limbs, duplicate people,',
    'new characters, scene change, text, captions, logo, watermark, low quality, blurry, deformed anatomy',
  ].join(' ');

  // 6 steps keeps an anonymous ZeroGPU call below its daily anonymous allowance
  // while still producing a real Wan2.2 motion clip.
  const payload = {
    data: [
      prompt,
      negativePrompt,
      480,
      832,
      25,
      3.5,
      2.5,
      6,
      42,
      true,
    ],
  };

  const startResponse = await fetch(
    HF_VIDEO_SPACE + '/gradio_api/call/' + HF_VIDEO_API,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    },
  );

  if (!startResponse.ok) {
    const detail = await startResponse.text();
    throw new Error('Hugging Face video queue rejected the request: HTTP ' + startResponse.status + ' ' + detail.slice(0, 500));
  }

  const started = await startResponse.json();
  const eventId = started && started.event_id;
  if (typeof eventId !== 'string' || eventId.length === 0) {
    throw new Error('Hugging Face video queue returned no event id.');
  }

  const resultResponse = await fetch(
    HF_VIDEO_SPACE + '/gradio_api/call/' + HF_VIDEO_API + '/' + encodeURIComponent(eventId),
    {
      headers: { Accept: 'text/event-stream' },
    },
  );

  if (!resultResponse.ok) {
    const detail = await resultResponse.text();
    throw new Error('Hugging Face video result stream failed: HTTP ' + resultResponse.status + ' ' + detail.slice(0, 500));
  }

  const streamText = await resultResponse.text();
  let eventType = '';
  let completedData = null;
  for (const line of streamText.split(/\\r?\\n/)) {
    if (line.startsWith('event:')) {
      eventType = line.slice(6).trim();
      continue;
    }
    if (!line.startsWith('data:')) continue;
    const raw = line.slice(5).trim();
    if (!raw) continue;

    if (eventType === 'error') {
      throw new Error('Hugging Face video generation failed: ' + raw.slice(0, 800));
    }

    if (eventType === 'complete') {
      try {
        completedData = JSON.parse(raw);
      } catch (_) {
        throw new Error('Hugging Face returned invalid completion data.');
      }
    }
  }

  if (!Array.isArray(completedData) || completedData.length === 0) {
    throw new Error('Hugging Face video generation completed without a video result.');
  }

  const output = completedData[0];
  let videoUrl = null;
  if (typeof output === 'string') {
    videoUrl = output;
  } else if (output && typeof output === 'object') {
    videoUrl = output.url || output.path || null;
  }

  if (typeof videoUrl !== 'string' || videoUrl.length === 0) {
    throw new Error('Hugging Face video result did not contain a playable file URL.');
  }

  if (videoUrl.startsWith('/')) {
    videoUrl = HF_VIDEO_SPACE + videoUrl;
  }

  const proxyUrl = requestUrl.origin + '/video?url=' + encodeURIComponent(videoUrl);
  return json({
    video: {
      url: proxyUrl,
      durationSeconds: 25 / 16,
      provider: 'huggingface-zerogpu-wan2.2-t2v',
    },
  }, 200, origin);
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
    typeof plan.schemaVersion === 'string' &&
    typeof plan.sceneSummary === 'string' &&
    typeof plan.visualStyle === 'string' &&
    Array.isArray(plan.characters) &&
    plan.characters.length <= 2 &&
    plan.characters.every((character) =>
      character &&
      typeof character.id === 'string' &&
      typeof character.description === 'string' &&
      typeof character.action === 'string' &&
      typeof character.emotion === 'string' &&
      typeof character.position === 'string' &&
      ['idle', 'talk', 'listen', 'gesture', 'reach', 'walk', 'react'].includes(character.runtimeAnimation)
    ) &&
    Array.isArray(plan.props) &&
    plan.props.length <= 3 &&
    plan.props.every((prop) => typeof prop === 'string') &&
    Array.isArray(plan.actions) &&
    plan.actions.length <= 3 &&
    plan.actions.every((action) => typeof action === 'string') &&
    plan.environment &&
    typeof plan.environment.location === 'string' &&
    typeof plan.environment.time === 'string' &&
    typeof plan.environment.description === 'string' &&
    plan.camera &&
    typeof plan.camera.shot === 'string' &&
    typeof plan.camera.angle === 'string' &&
    typeof plan.camera.movement === 'string' &&
    typeof plan.lighting === 'string' &&
    typeof plan.motion === 'string' &&
    typeof plan.imagePrompt === 'string';
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
  // Generate a short sequence of distinct AI-generated acting states. The
  // states are still derived from one canonical scene so identities and
  // composition stay anchored while the acting progresses.
  const actions = plan.actions.filter((action) => typeof action === 'string' && action.trim()).slice(0, 3);
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
        'Character animation instructions: ' + plan.characters.map((character) => character.id + ': ' + character.runtimeAnimation + ' (' + character.action + ', ' + character.emotion + ')').join('; '),
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
    frameDurationSeconds: 1.8,
  }, 200, origin);
}

async function generateVideo(env, plan, imageBase64, origin, requestUrl) {
  if (!validatePlan(plan)) {
    return json({ error: 'A valid scenePlan is required.' }, 400, origin);
  }

  try {
    return await callHuggingFaceVideo(plan, origin, requestUrl);
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    console.error('SuperBook free video generation failed', { detail });
    return json({
      error: 'Free cinematic video generation failed.',
      detail,
      provider: 'huggingface-zerogpu-wan2.2-t2v',
    }, 502, origin);
  }
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

    if (request.method === 'POST' && requestUrl.pathname === '/puppet-sheet') {
      let input;
      try {
        input = await request.json();
      } catch (_) {
        return json({ error: 'Request body must be valid JSON.' }, 400, origin);
      }

      const character = String(input && input.character || '').trim().slice(0, 900);
      if (!character) {
        return json({ error: 'character is required.' }, 400, origin);
      }

      const prompt = [
        'Create a production-quality 2D hand-drawn literary storybook animation asset sheet.',
        'One single human character only: ' + character + '.',
        'This is an animation source sheet, not a finished scene.',
        'Use a clean solid chroma-blue background with no texture.',
        'Arrange clearly separated, non-overlapping character parts with generous spacing:',
        'full head, torso, upper and lower arms, hands, upper and lower legs, feet, and one neutral full-body reference.',
        'Keep the exact same character identity, face, hair, clothing, proportions and illustration style across every part.',
        'Use natural anatomy, detailed ink outlines, painterly cel shading, expressive but restrained literary-cartoon design.',
        'Make every part large enough to crop cleanly and suitable for 2D puppet articulation.',
        'No text, labels, watermark, UI, duplicate characters, extra limbs, collage panels, or photorealism.',
      ].join(' ');

      try {
        const generated = await env.AI.run('@cf/bytedance/stable-diffusion-xl-lightning', {
          prompt: prompt.slice(0, 2048),
          width: 1024,
          height: 1024,
          num_steps: 4,
        });

        const image = Array.isArray(generated) ? generated[0] : generated;
        if (!image) {
          return json({ error: 'Puppet sheet model returned no image.' }, 502, origin);
        }

        let base64 = image.image || image;
        if (typeof base64 !== 'string') {
          return json({ error: 'Puppet sheet model returned an unsupported image payload.' }, 502, origin);
        }

        return json({
          schemaVersion: '1',
          mimeType: 'image/png',
          base64,
          assetType: 'animation-ready-character-sheet',
          sourceModel: '@cf/bytedance/stable-diffusion-xl-lightning',
        }, 200, origin);
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        const code = error && typeof error === 'object' ? error.code : undefined;
        const status = error && typeof error === 'object' ? error.status : undefined;
        console.error('SuperBook puppet sheet generation failed', { detail, code, status });
        return json({
          error: 'Puppet sheet generation failed.',
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
      const imageBase64 = input && input.imageBase64;
      if (!validatePlan(plan)) {
        return json({ error: 'A valid scenePlan is required.' }, 400, origin);
      }

      try {
        return await generateVideo(env, plan, imageBase64, origin, requestUrl);
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

    if (request.method === 'GET' && requestUrl.pathname === '/health') {
      return json({
        ok: true,
        service: 'superbook-ai-scene',
        textModel: TEXT_MODEL,
        imageModel: IMAGE_MODEL,
        sceneSchemaVersion: '2',
      }, 200, origin);
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
      const plan = fallbackScenePlan(input);
      console.log('[SuperBook][scene] using free narrative scene plan');
      return json({
        schemaVersion: 'free-t2v-1',
        scenePlan: plan,
        image: null,
      }, 200, origin);

    }
  },
};
