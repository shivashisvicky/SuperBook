# SuperBook Local Python Video Engine

This is the local Python backend experiment for SuperBook.

It uses the open Wan2.1 VACE 1.3B model through Diffusers:

- input: one SuperBook scene image
- input: semantic motion instruction
- output: MP4
- HTTP endpoint: `POST /video`
- health endpoint: `GET /health`

## Why Python?

The animation model itself is Python/PyTorch. Flutter does not need to run the model. SuperBook can call a Python service and receive the generated MP4.

## Hardware

A GPU is still required for practical generation. Python does not remove the GPU requirement. The current model is deliberately the smaller VACE 1.3B path so the same backend can be tested on consumer/free GPU environments.

The Wan project documents VACE 1.3B as a 480P video model and provides a Diffusers image+prompt example. For SuperBook we target 480P first because stability matters more than resolution during the proof.

## Run locally

```bash
cd poc/python_video_engine
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8787
```

Then:

```
GET  http://localhost:8787/health
POST http://localhost:8787/video
```

## Important

This does not replace the SuperBook Flutter app yet. It is intentionally isolated so a bad video backend cannot regress the reader.

The next proof uses the same Python engine on a free Kaggle GPU, because Kaggle currently provides free GPU notebook sessions with a weekly accelerator quota. Once the engine produces a good SuperBook clip, the HTTP contract can be connected to the Experience Player.
