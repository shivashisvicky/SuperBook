# SuperBook Local Python Video Engine

This is the zero-cost local video fallback for SuperBook.

It uses the Wan2.1 VACE 1.3B model through Diffusers:

- input: one SuperBook scene image
- input: semantic motion instruction derived from the AiScenePlan
- output: real generated MP4
- HTTP endpoint: POST /video
- health endpoint: GET /health
- generated MP4 endpoint: GET /video/{filename}

This is not a still-image slideshow and it does not use the old puppet/stick-figure renderer.

## Architecture

```text
Scene image + ScenePlan
        |
        +--> Cloudflare I2V
        |       |
        |       +--> success -> MP4 -> Experience Player
        |
        +--> local Wan VACE fallback
                |
                +--> MP4 -> Experience Player
```

The Flutter app uses SUPERBOOK_VIDEO_PROVIDER=auto by default. When a local endpoint is configured, auto tries Cloudflare first and falls back to the local Wan engine if the Cloudflare video call fails.

Use SUPERBOOK_VIDEO_PROVIDER=local to test the local engine directly.

## Hardware

A practical CUDA GPU is required for the current Wan2.1 VACE 1.3B backend. The local server does not magically provide GPU compute.

The model is deliberately the smaller VACE 1.3B path so it is suitable for a local proof on a consumer/free GPU environment.

## Run the local engine

From the repository root:

```bash
cd poc/python_video_engine
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8787
```

Check it from the same machine:

```text
http://127.0.0.1:8787/health
```

For an iPhone on the same Wi-Fi, use the computer's LAN address, for example:

```text
http://192.168.1.20:8787/health
```

The server enables CORS for local development.

## Run SuperBook against the local engine

The simplest local test is to run Flutter Web on the same computer:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define=SUPERBOOK_AI_SCENE_ENDPOINT=https://superbook-ai-scene.shivashisvicky112.workers.dev \
  --dart-define=SUPERBOOK_VIDEO_PROVIDER=local \
  --dart-define=SUPERBOOK_LOCAL_VIDEO_ENDPOINT=http://192.168.1.20:8787
```

Replace 192.168.1.20 with the computer's LAN address.

Then open the Flutter Web server from the iPhone using the computer's LAN address:

```text
http://192.168.1.20:8080/SuperBook/test/
```

For a same-machine browser test, 127.0.0.1:8787 can be used for the video endpoint.

## Important limitation

This fallback replaces video generation, not the Cloudflare Scene Director.

The first scene still needs a valid AiScenePlan and scene image. Once a scene image exists, the local Wan provider can generate the actual MP4 without Cloudflare video generation.

The existing Flutter scene cache remains the immediate reuse path for an already-generated scene.

This keeps the local backend isolated from the reader and leaves main untouched.
